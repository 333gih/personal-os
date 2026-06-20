import Foundation

struct POSWorkImportResult: Codable {
    let projectId: String
    let designDocId: String?
    let technologyIds: [String]
    let featureIds: [String]
    let designImageURL: String?
    let cvSkillsAdded: [String]
    let project: POSEntity

    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case designDocId = "design_doc_id"
        case technologyIds = "technology_ids"
        case featureIds = "feature_ids"
        case designImageURL = "design_image_url"
        case cvSkillsAdded = "cv_skills_added"
        case project
    }
}
