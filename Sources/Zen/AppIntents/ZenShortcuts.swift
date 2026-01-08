import AppIntents

/// Provides pre-built shortcut suggestions that appear in the Shortcuts app
struct ZenShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SetFocusModeIntent(),
            phrases: [
                "Set \(.applicationName) focus to \(\.$focusMode)",
                "Start \(\.$focusMode) mode with \(.applicationName)",
                "Activate \(\.$focusMode) focus in \(.applicationName)"
            ],
            shortTitle: "Set Focus Mode",
            systemImageName: "moon.circle.fill"
        )

        AppShortcut(
            intent: SyncCalendarIntent(),
            phrases: [
                "Sync my calendar with \(.applicationName)",
                "Update \(.applicationName) from calendar"
            ],
            shortTitle: "Sync Calendar",
            systemImageName: "calendar"
        )
    }
}
