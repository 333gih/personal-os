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
        if let raw = Bundle.main.object(forInfoDictionaryKey: "PERSONAL_OS_API_URL") as? String,
           let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines)),
           !raw.isEmpty {
            return url
        }
        return URL(string: "https://api-personal-os.fashandcurious.com/api/v1")!
    }

    static func frontendPath(_ path: String) -> URL {
        let base = frontendOrigin.hasSuffix("/") ? String(frontendOrigin.dropLast()) : frontendOrigin
        let normalized = path.hasPrefix("/") ? path : "/\(path)"
        return URL(string: base + normalized)!
    }
}
