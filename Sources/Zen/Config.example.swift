import Foundation

/// OAuth configuration template
/// Copy this file to Config.swift and add your credentials
/// DO NOT commit Config.swift to version control
enum Config {
    // MARK: - Google Calendar
    // Get credentials from: https://console.cloud.google.com/apis/credentials
    // Create OAuth 2.0 Client ID for iOS app
    static let googleClientId = "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
    static let googleRedirectUri = "com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID:/oauth2callback"
    static let googleCallbackScheme = "com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID"

    // MARK: - Outlook Calendar
    // Get credentials from: https://portal.azure.com → App registrations
    // Create new registration, set redirect URI to: msauth.com.zen.app://auth
    // Required API permissions (delegated): Calendars.Read, User.Read, offline_access
    static let outlookClientId = "YOUR_AZURE_CLIENT_ID"
    static let outlookRedirectUri = "msauth.com.zen.app://auth"
    static let outlookCallbackScheme = "msauth.com.zen.app"
}
