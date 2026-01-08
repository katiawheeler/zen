import Foundation
import AuthenticationServices

/// Manages Google OAuth authentication flow
class GoogleAuthManager: NSObject, ObservableObject {
    static let shared = GoogleAuthManager()

    @Published var isAuthenticated = false
    @Published var userEmail: String?
    @Published var accessToken: String?
    @Published var refreshToken: String?

    private let clientId = Config.googleClientId
    private let redirectUri = Config.googleRedirectUri
    private let callbackScheme = Config.googleCallbackScheme
    private let scopes = "https://www.googleapis.com/auth/calendar.readonly"

    private var authSession: ASWebAuthenticationSession?

    func startOAuthFlow() {
        let authUrlString = """
        https://accounts.google.com/o/oauth2/v2/auth?\
        client_id=\(clientId)&\
        redirect_uri=\(redirectUri)&\
        response_type=code&\
        scope=\(scopes)&\
        access_type=offline&\
        prompt=consent
        """

        guard let authUrl = URL(string: authUrlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            print("Invalid auth URL")
            return
        }

        authSession = ASWebAuthenticationSession(
            url: authUrl,
            callbackURLScheme: callbackScheme
        ) { [weak self] callbackURL, error in
            if let error = error {
                print("OAuth error: \(error.localizedDescription)")
                return
            }

            guard let callbackURL = callbackURL,
                  let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "code" })?.value else {
                print("No authorization code received")
                return
            }

            self?.exchangeCodeForToken(code: code)
        }

        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = false
        authSession?.start()
    }

    private func exchangeCodeForToken(code: String) {
        guard let url = URL(string: "https://oauth2.googleapis.com/token") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = """
        code=\(code)&\
        client_id=\(clientId)&\
        redirect_uri=\(redirectUri)&\
        grant_type=authorization_code
        """
        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data else { return }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let accessToken = json["access_token"] as? String {
                    let refreshToken = json["refresh_token"] as? String

                    DispatchQueue.main.async {
                        self?.accessToken = accessToken
                        self?.refreshToken = refreshToken
                        self?.isAuthenticated = true
                        self?.fetchUserInfo()

                        // Store tokens securely in Keychain
                        KeychainManager.save(key: "google_access_token", value: accessToken)
                        if let refreshToken = refreshToken {
                            KeychainManager.save(key: "google_refresh_token", value: refreshToken)
                        }
                    }
                }
            } catch {
                print("Token exchange error: \(error)")
            }
        }.resume()
    }

    func refreshAccessToken(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = refreshToken else {
            print("No refresh token available")
            completion(false)
            return
        }

        guard let url = URL(string: "https://oauth2.googleapis.com/token") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = """
        refresh_token=\(refreshToken)&\
        client_id=\(clientId)&\
        grant_type=refresh_token
        """
        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data else {
                completion(false)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let accessToken = json["access_token"] as? String {
                    DispatchQueue.main.async {
                        self?.accessToken = accessToken
                        KeychainManager.save(key: "google_access_token", value: accessToken)
                        completion(true)
                    }
                } else {
                    completion(false)
                }
            } catch {
                print("Token refresh error: \(error)")
                completion(false)
            }
        }.resume()
    }

    private func fetchUserInfo() {
        guard let token = accessToken,
              let url = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo") else { return }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let email = json["email"] as? String else { return }

            DispatchQueue.main.async {
                self?.userEmail = email
            }
        }.resume()
    }

    func signOut() {
        accessToken = nil
        refreshToken = nil
        userEmail = nil
        isAuthenticated = false
        KeychainManager.delete(key: "google_access_token")
        KeychainManager.delete(key: "google_refresh_token")
    }

    func restoreSession() {
        // Try Keychain first
        var savedAccessToken = KeychainManager.get(key: "google_access_token")
        var savedRefreshToken = KeychainManager.get(key: "google_refresh_token")

        // Migrate from UserDefaults if needed (for existing users)
        if savedAccessToken == nil && savedRefreshToken == nil {
            if let legacyAccess = UserDefaults.standard.string(forKey: "google_access_token") {
                savedAccessToken = legacyAccess
                KeychainManager.save(key: "google_access_token", value: legacyAccess)
                UserDefaults.standard.removeObject(forKey: "google_access_token")
            }
            if let legacyRefresh = UserDefaults.standard.string(forKey: "google_refresh_token") {
                savedRefreshToken = legacyRefresh
                KeychainManager.save(key: "google_refresh_token", value: legacyRefresh)
                UserDefaults.standard.removeObject(forKey: "google_refresh_token")
            }
        }

        if savedAccessToken != nil || savedRefreshToken != nil {
            accessToken = savedAccessToken
            refreshToken = savedRefreshToken
            isAuthenticated = true
            fetchUserInfo()

            // Proactively refresh if we have a refresh token
            if refreshToken != nil {
                refreshAccessToken { _ in }
            }
        }
    }
}

extension GoogleAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared.windows.first ?? ASPresentationAnchor()
    }
}
