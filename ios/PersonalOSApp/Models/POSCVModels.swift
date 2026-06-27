import Foundation

struct POSCVContact: Codable, Hashable {
    var email: String?
    var phone: String?
    var location: String?
    var linkedin: String?
    var github: String?
}

struct POSCVSkillGroup: Codable, Hashable, Identifiable {
    var category: String
    var items: [String]

    var id: String { category }
}

struct POSCVEducation: Codable, Hashable, Identifiable {
    var school: String
    var degree: String?
    var period: String?
    var content: String?

    var id: String { "\(school)-\(period ?? "")" }
}

struct POSCVAchievement: Codable, Hashable, Identifiable {
    var content: String
    var id: String { content }
}

struct POSCVCertificate: Codable, Hashable, Identifiable {
    var title: String
    var issuer: String?
    var period: String?

    var id: String { "\(title)-\(issuer ?? "")" }
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
    var skillGroups: [POSCVSkillGroup]?
    var primaryStack: [String]?
    var yearsExperience: Float?
    var education: [POSCVEducation]?
    var achievements: [POSCVAchievement]?
    var certificates: [POSCVCertificate]?
    var experience: [POSCVBullet]?
    var projects: [POSCVBullet]?
    var photoURL: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case variant, headline, summary, contact, skills, experience, projects, education, achievements, certificates
        case skillGroups = "skill_groups"
        case primaryStack = "primary_stack"
        case yearsExperience = "years_experience"
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

struct POSCVSuggestedSkill: Codable, Identifiable, Hashable {
    var category: String
    var skill: String
    var reason: String?

    var id: String { "\(category)-\(skill)" }
}

struct POSCVSuggestSkillsResponse: Decodable {
    let primaryStack: [String]?
    let suggestions: [POSCVSuggestedSkill]

    enum CodingKeys: String, CodingKey {
        case primaryStack = "primary_stack"
        case suggestions
    }
}

struct POSCVAddSkillRequest: Encodable {
    let category: String
    let skill: String
}

struct POSCVAddSkillResponse: Decodable {
    let added: [String]?
    let document: POSCVDocument
}

struct POSCVBlockOverrides: Codable, Hashable {
    var title: String?
    var company: String?
    var period: String?
    var highlightStack: [String]?
    var skillItems: [String]?

    enum CodingKeys: String, CodingKey {
        case title, company, period
        case highlightStack = "highlight_stack"
        case skillItems = "skill_items"
    }
}

struct POSCVBlock: Codable, Identifiable, Hashable {
    var id: String
    var type: String
    var order: Int
    var enabled: Bool
    var sourceEntityID: String?
    var content: String?
    var overrides: POSCVBlockOverrides?
    var aiRefinedAt: String?
    var pendingRaw: String?
    var skillGroups: [POSCVSkillGroup]?

    enum CodingKeys: String, CodingKey {
        case id, type, order, enabled, content, overrides
        case sourceEntityID = "source_entity_id"
        case aiRefinedAt = "ai_refined_at"
        case pendingRaw = "pending_raw"
        case skillGroups = "skill_groups"
    }
}

struct POSCVConstraints: Codable, Hashable {
    var maxPages: Int
    var maxExperience: Int
    var maxProjects: Int

    enum CodingKeys: String, CodingKey {
        case maxPages = "max_pages"
        case maxExperience = "max_experience"
        case maxProjects = "max_projects"
    }
}

struct POSCVTemplate: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var layoutID: String
    var isDefault: Bool
    var constraints: POSCVConstraints
    var blocks: [POSCVBlock]
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, constraints, blocks
        case layoutID = "layout_id"
        case isDefault = "is_default"
        case updatedAt = "updated_at"
    }
}

struct POSCVTemplatesResponse: Decodable {
    let templates: [POSCVTemplate]
}

struct POSCVValidateResult: Decodable {
    let valid: Bool
    let pageCount: Int
    let maxPages: Int
    let overflows: [String]?
    let suggestions: [String]?

    enum CodingKeys: String, CodingKey {
        case valid, overflows, suggestions
        case pageCount = "page_count"
        case maxPages = "max_pages"
    }
}

struct POSCVSaveTemplateRequest: Encodable {
    let template: POSCVTemplate
    let force: Bool
}

struct POSCVValidateRequest: Encodable {
    let template: POSCVTemplate
}

struct POSCVCreateTemplateRequest: Encodable {
    let name: String
    let layoutID: String
    let cloneID: String

    enum CodingKeys: String, CodingKey {
        case name
        case layoutID = "layout_id"
        case cloneID = "clone_id"
    }
}

struct POSCVRefineBlockRequest: Encodable {
    let instruction: String
    let content: String
}

struct POSCVAddBlockFromEntityRequest: Encodable {
    let entityID: String
    let blockType: String
    let overrides: POSCVBlockOverrides?

    enum CodingKeys: String, CodingKey {
        case overrides
        case entityID = "entity_id"
        case blockType = "block_type"
    }
}
