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
            if http.statusCode == 503, message.localizedCaseInsensitiveContains("ring-balancer") {
                throw APIError.http(http.statusCode, "API gateway unavailable. Update app or redeploy frontend.")
            }
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

    func listEntities(domain: String, limit: Int = 120) async throws -> POSEntityListResponse {
        let path = "entities?domain=\(domain.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? domain)&limit=\(limit)"
        let data = try await authorizedRequest(path: path)
        do {
            return try decoder.decode(POSEntityListResponse.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    func entityDetail(id: String) async throws -> POSEntityDetailResponse {
        let data = try await authorizedRequest(path: "entities/\(id)/detail")
        do {
            return try decoder.decode(POSEntityDetailResponse.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    func search(query: String, mode: String = "hybrid") async throws -> POSSearchResponse {
        let payload = try JSONEncoder().encode(["query": query, "mode": mode])
        let data = try await authorizedRequest(path: "search", method: "POST", body: payload)
        return try decoder.decode(POSSearchResponse.self, from: data)
    }

    func fetchCV() async throws -> POSAssembledCV {
        let data = try await authorizedRequest(path: "cv")
        return try decoder.decode(POSAssembledCV.self, from: data)
    }

    func saveCV(document: POSCVDocument) async throws -> POSAssembledCV {
        let payload = try JSONEncoder().encode(POSCVSaveRequest(document: document))
        let data = try await authorizedRequest(path: "cv", method: "PUT", body: payload)
        return try decoder.decode(POSAssembledCV.self, from: data)
    }

    func refineCV(instruction: String, section: String, content: String) async throws -> POSCVRefineResponse {
        let payload = try JSONEncoder().encode(POSCVRefineRequest(instruction: instruction, section: section, content: content))
        let data = try await authorizedRequest(path: "cv/refine", method: "POST", body: payload)
        return try decoder.decode(POSCVRefineResponse.self, from: data)
    }

    func downloadCVPDF() async throws -> Data {
        try await authorizedRequest(path: "cv/export/pdf")
    }

    func shareCV() async throws -> POSCVShareResponse {
        let data = try await authorizedRequest(path: "cv/share", method: "POST", body: Data("{}".utf8))
        return try decoder.decode(POSCVShareResponse.self, from: data)
    }
}
