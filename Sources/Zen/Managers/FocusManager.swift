import AppIntents
import AppKit
import Combine

class FocusManager: ObservableObject {
    static let shared = FocusManager()

    @Published var isZenModeEnabled: Bool = false

    // Simplified to binary state
    func setZenMode(enabled: Bool) {
        // Update UI state immediately on main thread
        DispatchQueue.main.async {
            self.isZenModeEnabled = enabled
        }

        // We use two separate shortcuts for robust On/Off switching without complex logic inside the shortcut
        let shortcutName = enabled ? "Zen Mode On" : "Zen Mode Off"

        guard shortcutExists(name: shortcutName) else {
            print("⚠️ [FocusManager] Missing Shortcut: '\(shortcutName)'")
            return
        }

        print("🚀 [FocusManager] Executing shortcut: \(shortcutName)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", shortcutName]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            if let errorMessage = String(data: errorData, encoding: .utf8), !errorMessage.isEmpty {
                print("❌ [FocusManager] CLI Error: \(errorMessage.trimmingCharacters(in: .whitespacesAndNewlines))")
            } else {
                print("✅ [FocusManager] Successfully triggered: \(shortcutName)")
            }
        } catch {
            print("❌ [FocusManager] Process Error: \(error.localizedDescription)")
        }
    }

    func shortcutExists(name: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["list"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            // Exact match check preferable? No, list returns one per line. Contains is okay for now.
            // Better: Check lines
            let lines = output.components(separatedBy: .newlines)
            return lines.contains(where: { $0.trimmingCharacters(in: .whitespaces) == name })
        } catch {
            return false
        }
    }

    func syncShortcuts() {
        print("🔄 [FocusManager] Syncing App Shortcuts...")
        ZenShortcuts.updateAppShortcutParameters()

        // Force LaunchServices to re-index
        if let bundlePath = Bundle.main.executablePath {
            let appPath = (bundlePath as NSString).deletingLastPathComponent
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister")
            process.arguments = ["-f", appPath]
            try? process.run()
        }
    }
}

class AutomationManager: ObservableObject {
    static let shared = AutomationManager()

    private var timer: AnyCancellable?
    private var lastKnownState: Bool? // To deduplicate calls
    private var cancellables = Set<AnyCancellable>()

    @Published var isAutomationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAutomationEnabled, forKey: "is_automation_enabled")
            if isAutomationEnabled {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }

    init() {
        self.isAutomationEnabled = UserDefaults.standard.bool(forKey: "is_automation_enabled")
        if isAutomationEnabled {
            startMonitoring()
        }
    }

    func startMonitoring() {
        stopMonitoring() // Ensure no duplicate timers

        print("⚡️ [Automation] Monitoring started")
        // Check constantly every 60 seconds
        timer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkMeetingStatus()
            }

        // Listen to calendar updates immediately
        CalendarManager.shared.$upcomingEvents
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                // Delay slightly to ensure data propogation or just call directly
                self?.checkMeetingStatus()
            }
            .store(in: &cancellables)

        // Also check immediately
        checkMeetingStatus()
    }

    func stopMonitoring() {
        timer?.cancel()
        timer = nil
        cancellables.removeAll()
        print("🛑 [Automation] Monitoring stopped")
    }

    @objc func checkMeetingStatus() {
        guard isAutomationEnabled else { return }

        let now = Date()
        let events = CalendarManager.shared.upcomingEvents
        let formatter = ISO8601DateFormatter()

        // Find if we are currently in ANY meeting
        let currentMeeting = events.first { event in
            guard let startStr = event.start.dateTime,
                  let endStr = event.end.dateTime,
                  let start = formatter.date(from: startStr),
                  let end = formatter.date(from: endStr) else {
                return false
            }
            // Check if now is between start and end (with slight buffer maybe?)
            return now >= start && now < end
        }

        if let meeting = currentMeeting {
            if lastKnownState != true {
                print("🧘 [Automation] In meeting: \(meeting.summary). Triggering Zen Mode.")
                lastKnownState = true

                // Run heavy process on background thread to avoid blocking UI
                DispatchQueue.global(qos: .userInitiated).async {
                    FocusManager.shared.setZenMode(enabled: true)
                }
            }
        } else {
            if lastKnownState != false {
                print("👋 [Automation] No active meeting. Ensuring Zen Mode is OFF.")
                lastKnownState = false

                // Run heavy process on background thread to avoid blocking UI
                DispatchQueue.global(qos: .userInitiated).async {
                    FocusManager.shared.setZenMode(enabled: false)
                }
            }
        }
    }
}
