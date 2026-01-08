import AppIntents
import Foundation

/// An App Intent that allows users to set a Focus Mode via Shortcuts, Siri, or Spotlight.
struct SetFocusModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Focus Mode"
    static var description = IntentDescription("Activates a specific Focus Mode on your Mac and syncs with Slack.")

    @Parameter(title: "Focus Mode")
    var focusMode: FocusModeEntity

    @Parameter(title: "Update Slack Status", default: true)
    var updateSlack: Bool

    @Parameter(title: "Snooze Slack Notifications", default: true)
    var snoozeSlack: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Set \(\.$focusMode) focus mode") {
            \.$updateSlack
            \.$snoozeSlack
        }
    }

    func perform() async throws -> some IntentResult {
        // Trigger the system Focus Mode via shortcuts CLI
        let shortcutName = "Set \(focusMode.name) Focus"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", shortcutName]

        try process.run()
        process.waitUntilExit()

        // Update Slack if requested
        if updateSlack {
            let emoji = focusMode.slackEmoji
            let statusText = focusMode.slackStatus
            SlackManager.shared.updateStatus(text: statusText, emoji: emoji)
        }

        if snoozeSlack {
            SlackManager.shared.setSnooze(minutes: 60)
        }

        return .result()
    }
}

/// Entity representing available Focus Modes
struct FocusModeEntity: AppEntity {
    var id: String
    var name: String
    var slackEmoji: String
    var slackStatus: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Focus Mode"
    static var defaultQuery = FocusModeQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static let work = FocusModeEntity(id: "work", name: "Work", slackEmoji: ":laptop:", slackStatus: "Focusing on work")
    static let deepWork = FocusModeEntity(id: "deep_work", name: "Deep Work", slackEmoji: ":construction:", slackStatus: "In deep focus - slow to respond")
    static let personal = FocusModeEntity(id: "personal", name: "Personal", slackEmoji: ":house:", slackStatus: "Away from keyboard")
    static let meeting = FocusModeEntity(id: "meeting", name: "Meeting", slackEmoji: ":calendar:", slackStatus: "In a meeting")

    static let allModes: [FocusModeEntity] = [.work, .deepWork, .personal, .meeting]
}

struct FocusModeQuery: EntityQuery {
    func entities(for identifiers: [FocusModeEntity.ID]) async throws -> [FocusModeEntity] {
        FocusModeEntity.allModes.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [FocusModeEntity] {
        FocusModeEntity.allModes
    }

    func defaultResult() async -> FocusModeEntity? {
        .work
    }
}
