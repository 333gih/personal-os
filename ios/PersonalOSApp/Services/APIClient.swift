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

    func authorizedRequest(path: String, method: String = "GET", body: Data? = nil, contentType: String = "application/json") async throws -> Data {
        guard let session else { throw APIError.unauthorized }

        guard let token = await session.validAccessToken() else {
            throw APIError.unauthorized
        }

        let first = try await performRequest(
            path: path,
            method: method,
            body: body,
            contentType: contentType,
            token: token
        )

        if first.status != 401 {
            guard (200 ... 299).contains(first.status) else {
                throw APIError.http(first.status, first.message)
            }
            return first.data
        }

        guard let refreshed = await session.refreshAccessToken(force: true) else {
            throw APIError.unauthorized
        }

        let retry = try await performRequest(
            path: path,
            method: method,
            body: body,
            contentType: contentType,
            token: refreshed
        )

        if retry.status == 401 {
            session.signOut()
            throw APIError.unauthorized
        }

        guard (200 ... 299).contains(retry.status) else {
            throw APIError.http(retry.status, retry.message)
        }
        return retry.data
    }

    private struct HTTPResult {
        let data: Data
        let status: Int
        let message: String
    }

    private func performRequest(path: String, method: String, body: Data?, contentType: String, token: String) async throws -> HTTPResult {
        let url = PersonalOSAppConfig.apiBaseURL.appending(path: path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.http(-1, "Invalid response")
        }

        let message = Self.friendlyHTTPMessage(status: http.statusCode, body: data)
        if http.statusCode == 503, message.localizedCaseInsensitiveContains("ring-balancer") {
            throw APIError.http(http.statusCode, "API gateway unavailable. Update app or redeploy frontend.")
        }

        return HTTPResult(data: data, status: http.statusCode, message: message)
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

    func suggestCVSkills() async throws -> POSCVSuggestSkillsResponse {
        let data = try await authorizedRequest(path: "cv/suggest-skills", method: "POST", body: Data("{}".utf8))
        return try decoder.decode(POSCVSuggestSkillsResponse.self, from: data)
    }

    func addCVSkill(category: String, skill: String) async throws -> POSCVAddSkillResponse {
        let payload = try JSONEncoder().encode(POSCVAddSkillRequest(category: category, skill: skill))
        let data = try await authorizedRequest(path: "cv/skills/add", method: "POST", body: payload)
        return try decoder.decode(POSCVAddSkillResponse.self, from: data)
    }

    func fetchJobs(status: String = "open") async throws -> [POSJobOpportunity] {
        let path = "jobs?status=\(status.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? status)"
        let data = try await authorizedRequest(path: path)
        let resp = try decoder.decode(POSJobListResponse.self, from: data)
        return resp.jobs
    }

    func scanJobs() async throws -> POSJobScanResponse {
        _ = try await authorizedRequest(path: "jobs/scan", method: "POST", body: Data("{}".utf8))

        for attempt in 0 ..< 90 {
            if attempt > 0 {
                try await Task.sleep(nanoseconds: 2_000_000_000)
            }
            let status = try await fetchJobScanStatus()
            switch status.status {
            case "completed":
                if let result = status.result {
                    return result
                }
                throw APIError.http(500, "Scan finished without results.")
            case "failed":
                throw APIError.http(500, status.error ?? "Job scan failed on server.")
            case "running":
                continue
            default:
                throw APIError.http(500, "Unexpected scan status: \(status.status)")
            }
        }
        throw APIError.http(408, "Scan is still running — pull to refresh in a minute.")
    }

    func fetchJobScanStatus() async throws -> POSJobScanStatusResponse {
        let data = try await authorizedRequest(path: "jobs/scan/status")
        return try decoder.decode(POSJobScanStatusResponse.self, from: data)
    }

    func updateJobStatus(id: String, status: String) async throws {
        let payload = try JSONEncoder().encode(POSJobStatusRequest(status: status))
        _ = try await authorizedRequest(path: "jobs/\(id)/status", method: "PATCH", body: payload)
    }

    func fetchJobPreferences() async throws -> POSJobSearchPreferences {
        let data = try await authorizedRequest(path: "jobs/preferences")
        return try decoder.decode(POSJobSearchPreferences.self, from: data)
    }

    func saveJobPreferences(_ prefs: POSJobSearchPreferences) async throws -> POSJobSearchPreferences {
        let payload = try JSONEncoder().encode(prefs)
        let data = try await authorizedRequest(path: "jobs/preferences", method: "PUT", body: payload)
        return try decoder.decode(POSJobSearchPreferences.self, from: data)
    }

    func addWorkEntry(kind: String, rawText: String, titleHint: String = "") async throws -> POSWorkAddResult {
        struct Body: Encodable {
            let kind: String
            let rawText: String
            let titleHint: String
            enum CodingKeys: String, CodingKey {
                case kind
                case rawText = "raw_text"
                case titleHint = "title_hint"
            }
        }
        let payload = try JSONEncoder().encode(Body(kind: kind, rawText: rawText, titleHint: titleHint))
        let data = try await authorizedRequest(path: "work/add", method: "POST", body: payload)
        return try decoder.decode(POSWorkAddResult.self, from: data)
    }

    func addStartupEntry(kind: String, rawText: String, titleHint: String = "") async throws -> POSStartupAddResult {
        struct Body: Encodable {
            let kind: String
            let rawText: String
            let titleHint: String
            enum CodingKeys: String, CodingKey {
                case kind
                case rawText = "raw_text"
                case titleHint = "title_hint"
            }
        }
        let payload = try JSONEncoder().encode(Body(kind: kind, rawText: rawText, titleHint: titleHint))
        let data = try await authorizedRequest(path: "startup/add", method: "POST", body: payload)
        return try decoder.decode(POSStartupAddResult.self, from: data)
    }

    func importWorkProject(title: String, company: String, markdown: String, diagram: Data?) async throws -> POSWorkImportResult {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        func appendField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append(value.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        appendField("title", title)
        appendField("company", company)
        appendField("markdown", markdown)
        if let diagram, !diagram.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"diagram\"; filename=\"diagram.png\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
            body.append(diagram)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        let data = try await authorizedRequest(
            path: "work/import",
            method: "POST",
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
        return try decoder.decode(POSWorkImportResult.self, from: data)
    }

    private static func friendlyHTTPMessage(status: Int, body: Data) -> String {
        let raw = String(data: body, encoding: .utf8) ?? "Unknown error"
        if raw.contains("<!DOCTYPE html") || raw.contains("<html") {
            if status == 502 {
                return "Gateway timeout (502). Job scan runs in the background — update the app and redeploy API if this persists."
            }
            if status == 504 {
                return "Server timed out (504). Try Scan again in a moment."
            }
            return "Server error (\(status)). Check API and frontend deployment."
        }
        if raw.count > 280 {
            return String(raw.prefix(280)) + "…"
        }
        return raw
    }
}
