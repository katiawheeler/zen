import Foundation
import AuthenticationServices
import CryptoKit

/// Manages Microsoft OAuth authentication flow for Outlook Calendar
class OutlookAuthManager: NSObject, ObservableObject {
    static let shared = OutlookAuthManager()

    @Published var isAuthenticated = false
    @Published var userEmail: String?
    @Published var accessToken: String?
    @Published var refreshToken: String?

    private let clientId = Config.outlookClientId
    private let redirectUri = Config.outlookRedirectUri
    private let callbackScheme = Config.outlookCallbackScheme
    private let scopes = "Calendars.Read User.Read offline_access"

    // PKCE values (generated per auth request)
    private var codeVerifier: String?

    private var authSession: ASWebAuthenticationSession?

    func startOAuthFlow() {
        // Generate PKCE code verifier and challenge
        let verifier = generateCodeVerifier()
        codeVerifier = verifier
        let challenge = generateCodeChallenge(from: verifier)

        let authUrlString = """
        https://login.microsoftonline.com/common/oauth2/v2.0/authorize?\
        client_id=\(clientId)&\
        redirect_uri=\(redirectUri)&\
        response_type=code&\
        scope=\(scopes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? scopes)&\
        code_challenge=\(challenge)&\
        code_challenge_method=S256&\
        prompt=select_account
        """

        guard let authUrl = URL(string: authUrlString) else {
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
        guard let url = URL(string: "https://login.microsoftonline.com/common/oauth2/v2.0/token"),
              let verifier = codeVerifier else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "client_id=\(clientId)",
            "code=\(code)",
            "redirect_uri=\(redirectUri)",
            "grant_type=authorization_code",
            "code_verifier=\(verifier)",
            "scope=\(scopes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? scopes)"
        ].joined(separator: "&")

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

                        // Store tokens (in production, use Keychain)
                        UserDefaults.standard.set(accessToken, forKey: "outlook_access_token")
                        if let refreshToken = refreshToken {
                            UserDefaults.standard.set(refreshToken, forKey: "outlook_refresh_token")
                        }
                    }
                } else if let error = (try JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String {
                    print("Token exchange error: \(error)")
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

        guard let url = URL(string: "https://login.microsoftonline.com/common/oauth2/v2.0/token") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "client_id=\(clientId)",
            "refresh_token=\(refreshToken)",
            "grant_type=refresh_token",
            "scope=\(scopes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? scopes)"
        ].joined(separator: "&")

        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data else {
                completion(false)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let accessToken = json["access_token"] as? String {
                    let newRefreshToken = json["refresh_token"] as? String

                    DispatchQueue.main.async {
                        self?.accessToken = accessToken
                        UserDefaults.standard.set(accessToken, forKey: "outlook_access_token")

                        // Microsoft may issue a new refresh token
                        if let newRefreshToken = newRefreshToken {
                            self?.refreshToken = newRefreshToken
                            UserDefaults.standard.set(newRefreshToken, forKey: "outlook_refresh_token")
                        }
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
              let url = URL(string: "https://graph.microsoft.com/v1.0/me") else { return }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

            // Microsoft Graph returns mail or userPrincipalName
            let email = json["mail"] as? String ?? json["userPrincipalName"] as? String

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
        codeVerifier = nil
        UserDefaults.standard.removeObject(forKey: "outlook_access_token")
        UserDefaults.standard.removeObject(forKey: "outlook_refresh_token")
    }

    func restoreSession() {
        let savedAccessToken = UserDefaults.standard.string(forKey: "outlook_access_token")
        let savedRefreshToken = UserDefaults.standard.string(forKey: "outlook_refresh_token")

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

    // MARK: - PKCE Helpers

    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

extension OutlookAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared.windows.first ?? ASPresentationAnchor()
    }
}
