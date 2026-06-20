import Foundation

struct POSCVContact: Codable, Hashable {
    var email: String?
    var phone: String?
    var location: String?
    var linkedin: String?
}

struct POSCVBullet: Codable, Identifiable, Hashable {
    var id: String?
    var title: String
    var content: String
    var company: String?
    var period: String?
    var section: String?

    var stableID: String { id ?? "\(title)-\(company ?? "")" }
}

struct POSCVDocument: Codable, Hashable {
    var variant: String?
    var headline: String
    var summary: String
    var contact: POSCVContact?
    var skills: [String]?
    var experience: [POSCVBullet]?
    var projects: [POSCVBullet]?
    var photoURL: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case variant, headline, summary, contact, skills, experience, projects
        case photoURL = "photo_url"
        case updatedAt = "updated_at"
    }
}

struct POSAssembledCV: Codable {
    var documentID: String?
    var document: POSCVDocument
    var source: String

    enum CodingKeys: String, CodingKey {
        case documentID = "document_id"
        case document, source
    }
}

struct POSCVRefineRequest: Encodable {
    let instruction: String
    let section: String
    let content: String
}

struct POSCVRefineResponse: Decodable {
    let reply: String
    let refinedContent: String?
    let section: String?

    enum CodingKeys: String, CodingKey {
        case reply
        case refinedContent = "refined_content"
        case section
    }
}

struct POSCVShareResponse: Decodable {
    let url: String
    let expiresIn: String
    let filename: String

    enum CodingKeys: String, CodingKey {
        case url
        case expiresIn = "expires_in"
        case filename
    }
}

struct POSCVSaveRequest: Encodable {
    let document: POSCVDocument
}

struct POSCVSaveResponse: Decodable {
    let documentID: String?
    let document: POSCVDocument
    let source: String

    enum CodingKeys: String, CodingKey {
        case documentID = "document_id"
        case document, source
    }
}
