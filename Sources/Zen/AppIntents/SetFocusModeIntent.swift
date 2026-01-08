import AppIntents
import Foundation

/// An App Intent that allows users to set a Focus Mode via Shortcuts, Siri, or Spotlight.
struct SetFocusModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Focus Mode"
    static var description = IntentDescription("Activates a specific Focus Mode on your Mac.")

    @Parameter(title: "Focus Mode")
    var focusMode: FocusModeEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Set \(\.$focusMode) focus mode")
    }

    func perform() async throws -> some IntentResult {
        // Trigger the system Focus Mode via shortcuts CLI
        let shortcutName = "Set \(focusMode.name) Focus"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", shortcutName]

        try process.run()
        process.waitUntilExit()

        return .result()
    }
}

/// Entity representing available Focus Modes
struct FocusModeEntity: AppEntity {
    var id: String
    var name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Focus Mode"
    static var defaultQuery = FocusModeQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static let work = FocusModeEntity(id: "work", name: "Work")
    static let deepWork = FocusModeEntity(id: "deep_work", name: "Deep Work")
    static let personal = FocusModeEntity(id: "personal", name: "Personal")
    static let meeting = FocusModeEntity(id: "meeting", name: "Meeting")

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
