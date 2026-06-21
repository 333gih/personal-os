import Foundation

@MainActor
final class POSFCMRegistrar {
    static let shared = POSFCMRegistrar()

    private init() {}

    /// Registers FCM/APNs token with fash-auth when available (remote push via fash-notification-service).
    func registerPendingToken() async {
        guard let token = UserDefaults.standard.string(forKey: "pos.fcm.token")
            ?? UserDefaults.standard.string(forKey: "pos.apns.device_token"),
              !token.isEmpty else {
            return
        }
        await register(token: token)
    }

    func register(token: String, session: SessionManager? = nil) async {
        let sessionManager = session ?? POSPushSessionBridge.shared.session
        guard let sessionManager,
              let accessToken = await sessionManager.validAccessToken() else {
            UserDefaults.standard.set(token, forKey: "pos.fcm.token")
            return
        }

        let url = PersonalOSAppConfig.fashAuthURL.appending(path: PersonalOSAppConfig.fashFCMRegisterPath)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let body: [String: String] = [
            "fcm_token": token,
            "device_platform": "ios",
            "client_locale": Locale.current.identifier,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
                return
            }
            UserDefaults.standard.set(token, forKey: "pos.fcm.token")
        } catch {
            UserDefaults.standard.set(token, forKey: "pos.fcm.token")
        }
    }
}

/// Weak bridge so AppDelegate can reach SessionManager without circular imports.
@MainActor
final class POSPushSessionBridge {
    static let shared = POSPushSessionBridge()
    weak var session: SessionManager?
}
