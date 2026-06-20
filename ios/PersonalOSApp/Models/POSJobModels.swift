import Foundation

struct POSJobOpportunity: Codable, Identifiable, Hashable {
    let id: String
    let source: String
    let title: String
    let company: String?
    let location: String?
    let url: String
    let description: String?
    let matchScore: Float
    let matchReason: String?
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, source, title, company, location, url, description, status
        case matchScore = "match_score"
        case matchReason = "match_reason"
    }
}

struct POSJobListResponse: Decodable {
    let jobs: [POSJobOpportunity]
    let minScore: Float?

    enum CodingKeys: String, CodingKey {
        case jobs
        case minScore = "min_score"
    }
}

struct POSJobScanResponse: Decodable {
    let found: Int
    let matched: Int
    let stored: Int
    let updated: Int
    let minScore: Float?
    let scannedAt: String?

    enum CodingKeys: String, CodingKey {
        case found, matched, stored, updated
        case minScore = "min_score"
        case scannedAt = "scanned_at"
    }
}

struct POSJobScanStatusResponse: Decodable {
    let status: String
    let error: String?
    let result: POSJobScanResponse?
}

struct POSJobStatusRequest: Encodable {
    let status: String
}

enum POSJobTab: String, CaseIterable {
    case open = "Open"
    case applied = "Applied"
}
