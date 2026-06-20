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
}

struct POSJobScanResponse: Decodable {
    let found: Int
    let stored: Int
    let updated: Int
    let scannedAt: String?

    enum CodingKeys: String, CodingKey {
        case found, stored, updated
        case scannedAt = "scanned_at"
    }
}

struct POSJobStatusRequest: Encodable {
    let status: String
}
