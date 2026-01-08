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
}
