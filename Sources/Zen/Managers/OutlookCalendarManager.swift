import Foundation

/// Outlook calendar entry matching the structure used by Google
struct OutlookCalendarEntry: Identifiable, Codable {
    let id: String
    let name: String
    let isDefaultCalendar: Bool?
    var isSelected: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, name, isDefaultCalendar
    }
}

class OutlookCalendarManager: ObservableObject {
    static let shared = OutlookCalendarManager()

    @Published var upcomingEvents: [CalendarEvent] = []
    @Published var availableCalendars: [OutlookCalendarEntry] = []

    private var selectedCalendarIds: Set<String> {
        get {
            let array = UserDefaults.standard.stringArray(forKey: "outlook_selected_calendar_ids") ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: "outlook_selected_calendar_ids")
        }
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

    func toggleCalendar(_ calendar: OutlookCalendarEntry) {
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
        guard let accessToken = OutlookAuthManager.shared.accessToken else { return }

        guard let url = URL(string: "https://graph.microsoft.com/v1.0/me/calendars") else { return }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                print("🔒 [Outlook Calendar] 401 Unauthorized. Attempting token refresh...")
                OutlookAuthManager.shared.refreshAccessToken { success in
                    if success {
                        self.fetchCalendarList() // Retry
                    } else {
                        print("❌ [Outlook Calendar] Refresh failed. Signing out.")
                        OutlookAuthManager.shared.signOut()
                    }
                }
                return
            }

            if let data = data {
                do {
                    let result = try JSONDecoder().decode(OutlookCalendarListResponse.self, from: data)
                    DispatchQueue.main.async {
                        // If no calendars have EVER been selected, select them all once.
                        let hasPerformedInitialSelect = UserDefaults.standard.bool(forKey: "outlook_has_performed_initial_calendar_select")

                        if !hasPerformedInitialSelect {
                            let allIds = result.value.map { $0.id }
                            self.selectedCalendarIds = Set(allIds)
                            UserDefaults.standard.set(true, forKey: "outlook_has_performed_initial_calendar_select")
                        }

                        self.availableCalendars = result.value.map { entry in
                            var modifiedEntry = entry
                            modifiedEntry.isSelected = self.selectedCalendarIds.contains(entry.id)
                            return modifiedEntry
                        }

                        self.fetchEvents()
                    }
                } catch {
                    if let rawString = String(data: data, encoding: .utf8) {
                        print("❌ Outlook Calendar List Decode Error: \(error)")
                        print("📡 Raw Response: \(rawString)")

                        if rawString.contains("InvalidAuthenticationToken") {
                            print("🔒 Token definitively invalid. Signing out...")
                            DispatchQueue.main.async {
                                OutlookAuthManager.shared.signOut()
                            }
                        }
                    }
                }
            }
        }.resume()
    }

    func fetchEvents() {
        guard let accessToken = OutlookAuthManager.shared.accessToken else { return }

        let idsToFetch = Array(selectedCalendarIds)

        // If nothing is selected, clear everything immediately
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

            // Microsoft Graph API uses $filter for date filtering
            let urlString = "https://graph.microsoft.com/v1.0/me/calendars/\(id)/events?$filter=start/dateTime ge '\(now)'&$orderby=start/dateTime&$top=10"

            guard let url = URL(string: urlString) else {
                group.leave()
                continue
            }

            var request = URLRequest(url: url)
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            URLSession.shared.dataTask(with: request) { data, response, _ in
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                    print("🔒 [Outlook Events] 401 Unauthorized. Refreshing...")
                    OutlookAuthManager.shared.refreshAccessToken { _ in }
                    group.leave()
                    return
                }

                if let data = data {
                    do {
                        let result = try JSONDecoder().decode(OutlookEventsResponse.self, from: data)
                        // Convert Outlook events to the shared CalendarEvent format
                        let converted = result.value.map { self.convertToCalendarEvent($0) }
                        allEvents.append(contentsOf: converted)
                    } catch {
                        if let rawString = String(data: data, encoding: .utf8) {
                            print("❌ Outlook Events Decode Error: \(error)")
                            print("📡 Raw Response: \(rawString.prefix(500))")
                        }
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

    /// Convert Microsoft Graph event format to shared CalendarEvent format
    private func convertToCalendarEvent(_ outlookEvent: OutlookEvent) -> CalendarEvent {
        // Microsoft returns dateTime without timezone offset, need to handle this
        let startDateTime = formatMicrosoftDateTime(outlookEvent.start.dateTime, timeZone: outlookEvent.start.timeZone)
        let endDateTime = formatMicrosoftDateTime(outlookEvent.end.dateTime, timeZone: outlookEvent.end.timeZone)

        return CalendarEvent(
            id: outlookEvent.id,
            summary: outlookEvent.subject,
            start: CalendarEvent.EventTime(dateTime: startDateTime, date: nil),
            end: CalendarEvent.EventTime(dateTime: endDateTime, date: nil)
        )
    }

    /// Format Microsoft dateTime to ISO8601 format
    private func formatMicrosoftDateTime(_ dateTime: String, timeZone: String?) -> String {
        // Microsoft returns: "2024-01-15T10:00:00.0000000"
        // We need: "2024-01-15T10:00:00Z" or with timezone offset

        // Simple approach: strip fractional seconds and assume UTC if timezone is UTC
        var cleaned = dateTime
        if let dotIndex = dateTime.firstIndex(of: ".") {
            cleaned = String(dateTime[..<dotIndex])
        }

        // If timezone is UTC, append Z
        if timeZone == "UTC" || timeZone == "Etc/UTC" {
            return cleaned + "Z"
        }

        // For other timezones, we'd need proper conversion
        // For now, treat as local time and append Z (simplified)
        return cleaned + "Z"
    }
}

// MARK: - Microsoft Graph API Response Types

struct OutlookCalendarListResponse: Codable {
    let value: [OutlookCalendarEntry]
}

struct OutlookEventsResponse: Codable {
    let value: [OutlookEvent]
}

struct OutlookEvent: Codable {
    let id: String
    let subject: String
    let start: OutlookDateTime
    let end: OutlookDateTime
    let isAllDay: Bool?
}

struct OutlookDateTime: Codable {
    let dateTime: String
    let timeZone: String?
}
