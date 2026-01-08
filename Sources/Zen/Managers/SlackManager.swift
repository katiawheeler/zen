import Foundation
import AppKit

class SlackManager: ObservableObject {
    static let shared = SlackManager()

    @Published var isAuthenticated: Bool = false
    @Published var userName: String?
    @Published var teamName: String?

    private var token: String? {
        get { UserDefaults.standard.string(forKey: "slack_user_token") }
        set {
            if let val = newValue {
                UserDefaults.standard.set(val, forKey: "slack_user_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "slack_user_token")
            }
        }
    }

    private var cookie: String? {
        get { UserDefaults.standard.string(forKey: "slack_user_cookie") }
        set {
            if let val = newValue {
                UserDefaults.standard.set(val, forKey: "slack_user_cookie")
            } else {
                UserDefaults.standard.removeObject(forKey: "slack_user_cookie")
            }
        }
    }

    init() {
        if let storedToken = token {
            print("🔌 [Slack] Found stored token, validating...")
            validateToken(token: storedToken)
        }
    }

    // MARK: - Manual Token Auth

    /// Set credentials extracted from browser DevTools
    func setCredentials(token: String, cookie: String) {
        self.token = token
        self.cookie = cookie.isEmpty ? nil : cookie
        print("🔑 [Slack] Credentials set, validating...")
        validateToken(token: token)
    }

    func validateToken(token: String, completion: ((Bool) -> Void)? = nil) {
        guard let url = URL(string: "https://slack.com/api/auth.test") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                print("❌ [Slack] Validation failed: \(error?.localizedDescription ?? "Unknown")")
                completion?(false)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let ok = json["ok"] as? Bool, ok == true {

                    let user = json["user"] as? String
                    let team = json["team"] as? String

                    DispatchQueue.main.async {
                        self?.token = token
                        self?.isAuthenticated = true
                        self?.userName = user
                        self?.teamName = team
                        print("✅ [Slack] Authenticated as \(user ?? "Unknown") on \(team ?? "Unknown")")
                    }
                    completion?(true)
                } else {
                    print("❌ [Slack] Invalid token response")
                    DispatchQueue.main.async {
                        self?.isAuthenticated = false
                    }
                    completion?(false)
                }
            } catch {
                completion?(false)
            }
        }.resume()
    }

    func signOut() {
        token = nil
        cookie = nil
        isAuthenticated = false
        userName = nil
        teamName = nil
        print("👋 [Slack] Signed out")
    }

    // MARK: - Slack API Methods

    func updateStatus(text: String, emoji: String, durationInMinutes: Int? = nil) {
        guard let currentToken = token else { return }
        guard let url = URL(string: "https://slack.com/api/users.profile.set") else { return }

        var profile: [String: Any] = [
            "status_text": text,
            "status_emoji": emoji
        ]

        if let duration = durationInMinutes {
            let expiration = Int(Date().addingTimeInterval(TimeInterval(duration * 60)).timeIntervalSince1970)
            profile["status_expiration"] = expiration
        } else {
            profile["status_expiration"] = 0
        }

        let body: [String: Any] = ["profile": profile]
        sendRequest(url: url, body: body, token: currentToken)
    }

    func setSnooze(minutes: Int) {
        guard let currentToken = token else { return }

        if minutes > 0 {
            guard let url = URL(string: "https://slack.com/api/dnd.setSnooze") else { return }
            let body: [String: Any] = ["num_minutes": minutes]
            sendRequest(url: url, body: body, token: currentToken)
        } else {
            guard let url = URL(string: "https://slack.com/api/dnd.endSnooze") else { return }
            sendRequest(url: url, body: [:], token: currentToken)
        }
    }

    private func sendRequest(url: URL, body: [String: Any], token: String) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ [Slack] API Error: \(error.localizedDescription)")
                    return
                }
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    print("📬 [Slack] Response: \(str)")
                }
            }.resume()
        } catch {
            print("❌ [Slack] Failed to serialize request body")
        }
    }
}
