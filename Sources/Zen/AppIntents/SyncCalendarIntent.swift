import AppIntents
import Foundation

/// An App Intent that syncs the user's calendar and updates focus/slack accordingly
struct SyncCalendarIntent: AppIntent {
    static var title: LocalizedStringResource = "Sync Calendar"
    static var description = IntentDescription("Checks your calendar and automatically sets your focus mode based on upcoming events.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // In a real implementation, this would fetch from Google Calendar
        // and determine the appropriate focus mode
        let calendarManager = CalendarManager.shared
        calendarManager.fetchEvents()

        // For now, return a placeholder result
        return .result(value: "Calendar synced successfully")
    }
}
