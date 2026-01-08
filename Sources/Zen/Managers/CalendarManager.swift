import Foundation

struct CalendarEvent: Identifiable, Codable {
    let id: String
    let summary: String
    let start: EventTime
    let end: EventTime

    struct EventTime: Codable {
        let dateTime: String?
        let date: String?
    }
}

struct CalendarListEntry: Identifiable, Codable {
    let id: String
    let summary: String
    let primary: Bool?
    var isSelected: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, summary, primary
    }
}

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()

    @Published var upcomingEvents: [CalendarEvent] = []
    @Published var availableCalendars: [CalendarListEntry] = []

    private var selectedCalendarIds: Set<String> {
        get {
            let array = UserDefaults.standard.stringArray(forKey: "selected_calendar_ids") ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: "selected_calendar_ids")
        }
    }

    private var isFirstSync: Bool {
        get { !UserDefaults.standard.bool(forKey: "has_synced_before") }
        set { UserDefaults.standard.set(newValue, forKey: "has_synced_before") }
    }

    var relevantEvents: [CalendarEvent] {
        guard let first = upcomingEvents.first else { return [] }

        let formatter = ISO8601DateFormatter()
        let firstStart = formatter.date(from: first.start.dateTime ?? first.start.date ?? "") ?? Date.distantFuture
        let firstEnd = formatter.date(from: first.end.dateTime ?? first.end.date ?? "") ?? Date.distantFuture

        // Include the first event, plus any that start before the first one ends
        // or start within 15 minutes of the first one starting (for back-to-back/overlap)
        return upcomingEvents.filter { event in
            guard let start = formatter.date(from: event.start.dateTime ?? event.start.date ?? "") else { return false }

            let isFirst = event.id == first.id
            let overlapsWithFirst = start < firstEnd
            let startsSoonAfterFirst = start.timeIntervalSince(firstStart) < 900 // 15 mins

            return isFirst || overlapsWithFirst || startsSoonAfterFirst
        }
    }

    func formatEvent(_ event: CalendarEvent) -> String {
        let timeString = formatEventTime(event)
        return "\(event.summary) @ \(timeString)"
    }

    func formatEventTime(_ event: CalendarEvent) -> String {
        let formatter = ISO8601DateFormatter()

        if let dateTimeString = event.start.dateTime, let date = formatter.date(from: dateTimeString) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            return timeFormatter.string(from: date)
        } else if let _ = event.start.date {
            return "All Day"
        } else {
            return ""
        }
    }

    var nextMeetingText: String {
        relevantEvents.first.map { formatEvent($0) } ?? "No upcoming meetings"
    }

    init() {
        setupRefreshTimer()
    }

    private func setupRefreshTimer() {
        // Sync every 10 minutes
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            self?.fetchEvents()
        }
    }

    func toggleCalendar(_ calendar: CalendarListEntry) {
        var currentIds = selectedCalendarIds
        if currentIds.contains(calendar.id) {
            currentIds.remove(calendar.id)
        } else {
            currentIds.insert(calendar.id)
        }
        selectedCalendarIds = currentIds

        // Update local availableCalendars immediately so UI is responsive
        if let index = availableCalendars.firstIndex(where: { $0.id == calendar.id }) {
            availableCalendars[index].isSelected = currentIds.contains(calendar.id)
        }

        // Refresh events immediately
        fetchEvents()
    }

    func fetchCalendarList() {
        guard let accessToken = GoogleAuthManager.shared.accessToken else { return }

        let url = URL(string: "https://www.googleapis.com/calendar/v3/users/me/calendarList")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                print("🔒 [Calendar] 401 Unauthorized. Attempting token refresh...")
                GoogleAuthManager.shared.refreshAccessToken { success in
                    if success {
                        self.fetchCalendarList() // Retry
                    } else {
                        print("❌ [Calendar] Refresh failed. Signing out.")
                        GoogleAuthManager.shared.signOut()
                    }
                }
                return
            }

            if let data = data {
                do {
                    let result = try JSONDecoder().decode(CalendarListResponse.self, from: data)
                    DispatchQueue.main.async {
                        // If no calendars have EVER been selected, select them all once.
                        let hasPerformedInitialSelect = UserDefaults.standard.bool(forKey: "has_performed_initial_calendar_select")

                        if !hasPerformedInitialSelect {
                            let allIds = result.items.map { $0.id }
                            self.selectedCalendarIds = Set(allIds)
                            UserDefaults.standard.set(true, forKey: "has_performed_initial_calendar_select")
                        }

                        self.availableCalendars = result.items.map { entry in
                            var modifiedEntry = entry
                            modifiedEntry.isSelected = self.selectedCalendarIds.contains(entry.id)
                            return modifiedEntry
                        }

                        self.fetchEvents()
                    }
                } catch {
                    // Log the raw response if decoding fails to see if it's an API error
                    if let rawString = String(data: data, encoding: .utf8) {
                        print("❌ Calendar List Decode Error: \(error)")
                        print("📡 Raw Response: \(rawString)")

                        // Only sign out if it's definitively an auth error that we can't fix
                        if rawString.contains("UNAUTHENTICATED") || rawString.contains("Invalid Credentials") {
                            print("🔒 Token definitively invalid. Signing out...")
                            DispatchQueue.main.async {
                                GoogleAuthManager.shared.signOut()
                            }
                        }
                    }
                }
            }
        }.resume()
    }

    func fetchEvents() {
        guard let accessToken = GoogleAuthManager.shared.accessToken else { return }

        let idsToFetch = Array(selectedCalendarIds)

        // Fix ghosting: If nothing is selected, clear everything immediately
        if idsToFetch.isEmpty {
            DispatchQueue.main.async {
                self.upcomingEvents = []
            }
            return
        }

        let now = ISO8601DateFormatter().string(from: Date())
        var allEvents: [CalendarEvent] = []
        let group = DispatchGroup()

        for id in idsToFetch {
            group.enter()
            let urlString = "https://www.googleapis.com/calendar/v3/calendars/\(id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")/events?timeMin=\(now)&maxResults=10&singleEvents=true&orderBy=startTime"

            guard let url = URL(string: urlString) else {
                group.leave()
                continue
            }

            var request = URLRequest(url: url)
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, response, _ in
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                    print("🔒 [Calendar Events] 401 Unauthorized. Refreshing...")
                    GoogleAuthManager.shared.refreshAccessToken { success in
                        if success {
                            // We don't retry immediately here to avoid complex group management,
                            // but the next sync cycle or a manual trigger will pick it up.
                            // Better: call a method that doesn't use groups for a single retry if needed.
                        }
                    }
                    group.leave()
                    return
                }

                if let data = data {
                    if let result = try? JSONDecoder().decode(CalendarResponse.self, from: data) {
                        allEvents.append(contentsOf: result.items)
                    }
                }
                group.leave()
            }.resume()
        }

        group.notify(queue: .main) {
            self.upcomingEvents = allEvents.sorted(by: {
                let date1 = ISO8601DateFormatter().date(from: $0.start.dateTime ?? $0.start.date ?? "") ?? Date.distantFuture
                let date2 = ISO8601DateFormatter().date(from: $1.start.dateTime ?? $1.start.date ?? "") ?? Date.distantFuture

                if date1 == date2 {
                    if $0.summary == $1.summary {
                        return $0.id < $1.id
                    }
                    return $0.summary < $1.summary
                }
                return date1 < date2
            })
        }
    }
}

struct CalendarListResponse: Codable {
    let items: [CalendarListEntry]
}

struct CalendarResponse: Codable {
    let items: [CalendarEvent]
}
