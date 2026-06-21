import Foundation

enum PersonalOSAppConfig {
    /// Hosted Personal OS frontend (Next.js). Override via Info.plist `PERSONAL_OS_FE_URL`.
    static var frontendURL: URL {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "PERSONAL_OS_FE_URL") as? String,
           let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines)),
           !raw.isEmpty {
            return url
        }
        return URL(string: "https://personal-os-fe.fashandcurious.com/dashboard")!
    }

    static var frontendOrigin: String {
        guard let host = frontendURL.host else { return frontendURL.absoluteString }
        let scheme = frontendURL.scheme ?? "https"
        if let port = frontendURL.port, port != 80, port != 443 {
            return "\(scheme)://\(host):\(port)"
        }
        return "\(scheme)://\(host)"
    }

    static var apiBaseURL: URL {
        // Route via hosted FE BFF — FE talks to personal-os-api on Docker network, bypasses Kong 503.
        return frontendPath("/api/mobile/v1")
    }

    static func frontendPath(_ path: String) -> URL {
        let base = frontendOrigin.hasSuffix("/") ? String(frontendOrigin.dropLast()) : frontendOrigin
        let normalized = path.hasPrefix("/") ? path : "/\(path)"
        return URL(string: base + normalized)!
    }

    /// fash-auth-service — FCM token registration for remote push.
    static var fashAuthURL: URL {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "FASH_AUTH_BASE_URL") as? String,
           let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines)),
           !raw.isEmpty {
            return url
        }
        return URL(string: "https://api-auth.fashandcurious.com")!
    }

    static var fashFCMRegisterPath: String {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "FASH_AUTH_FCM_REGISTER_PATH") as? String,
           !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.hasPrefix("/") ? String(trimmed.dropFirst()) : trimmed
        }
        return "api/v1/auth/fcm/register"
    }
}
