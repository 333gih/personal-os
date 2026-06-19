import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case http(Int, String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Session expired. Please sign in again."
        case .http(let code, let msg): return "Server error (\(code)): \(msg)"
        case .decoding(let err): return "Data error: \(err.localizedDescription)"
        }
    }
}

@MainActor
final class APIClient: ObservableObject {
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    weak var session: SessionManager?

    func authorizedRequest(path: String, method: String = "GET", body: Data? = nil) async throws -> Data {
        guard let token = session?.accessToken, !token.isEmpty else {
            throw APIError.unauthorized
        }

        let url = PersonalOSAppConfig.apiBaseURL.appending(path: path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.http(-1, "Invalid response")
        }

        if http.statusCode == 401 {
            session?.signOut()
            throw APIError.unauthorized
        }

        guard (200 ... 299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.http(http.statusCode, message)
        }

        return data
    }

    func me() async throws -> POSUser {
        let data = try await authorizedRequest(path: "auth/me")
        return try decoder.decode(POSUser.self, from: data)
    }

    func dashboard() async throws -> POSDashboard {
        let data = try await authorizedRequest(path: "dashboard")
        return try decoder.decode(POSDashboard.self, from: data)
    }

    func listEntities(domain: String, limit: Int = 50) async throws -> POSEntityListResponse {
        var components = URLComponents(url: PersonalOSAppConfig.apiBaseURL.appending(path: "entities"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "domain", value: domain),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        guard let url = components.url else { throw APIError.http(-1, "Bad URL") }

        guard let token = session?.accessToken else { throw APIError.unauthorized }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw APIError.http((response as? HTTPURLResponse)?.statusCode ?? -1, "entities failed")
        }
        return try decoder.decode(POSEntityListResponse.self, from: data)
    }

    func search(query: String, mode: String = "hybrid") async throws -> POSSearchResponse {
        let payload = try JSONEncoder().encode(["query": query, "mode": mode])
        let data = try await authorizedRequest(path: "search", method: "POST", body: payload)
        return try decoder.decode(POSSearchResponse.self, from: data)
    }
}
