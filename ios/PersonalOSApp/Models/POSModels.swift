import Foundation

struct POSUser: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
}

struct POSEntity: Codable, Identifiable {
    let id: String
    let type: String
    let title: String
    let content: String
    let status: String
    let domain: String
    let createdAt: String
    let updatedAt: String
    let tags: POSTagsValue?

    enum CodingKeys: String, CodingKey {
        case id, type, title, content, status, domain, tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var tagList: [String] {
        tags?.values ?? []
    }
}

enum POSTagsValue: Codable {
    case array([String])
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let arr = try? container.decode([String].self) {
            self = .array(arr)
        } else if let str = try? container.decode(String.self) {
            self = .string(str)
        } else {
            self = .array([])
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .array(let arr): try container.encode(arr)
        case .string(let str): try container.encode(str)
        }
    }

    var values: [String] {
        switch self {
        case .array(let arr): return arr
        case .string(let str):
            if str.hasPrefix("[") {
                return (try? JSONDecoder().decode([String].self, from: Data(str.utf8))) ?? []
            }
            return str.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
    }
}

struct POSReminder: Codable, Identifiable {
    let id: String
    let entityId: String?
    let title: String
    let dueAt: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, title, status
        case entityId = "entity_id"
        case dueAt = "due_at"
    }
}

struct POSDashboard: Codable {
    let domainCounts: [String: Int]
    let recent: [POSEntity]
    let upcomingReminders: [POSReminder]
    let inboxCount: Int

    enum CodingKeys: String, CodingKey {
        case recent
        case domainCounts = "domain_counts"
        case upcomingReminders = "upcoming_reminders"
        case inboxCount = "inbox_count"
    }
}

struct POSEntityListResponse: Codable {
    let items: [POSEntity]
    let total: Int
}

struct POSSearchHit: Codable, Identifiable {
    var id: String { entity.id }
    let entity: POSEntity
    let score: Double
    let matchType: String

    enum CodingKeys: String, CodingKey {
        case entity, score
        case matchType = "match_type"
    }
}

struct POSSearchResponse: Codable {
    let results: [POSSearchHit]
    let count: Int
}

enum POSTab: Int, CaseIterable, Identifiable {
    case home, work, learning, search, more

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .work: return "Work"
        case .learning: return "Learning"
        case .search: return "Search"
        case .more: return "More"
        }
    }

    var headerTitle: String {
        switch self {
        case .home: return "Personal OS"
        case .work: return "Career Path"
        case .learning: return "Personal OS"
        case .search: return "Personal OS"
        case .more: return "Personal OS"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .learning: return "graduationcap.fill"
        case .search: return "magnifyingglass"
        case .more: return "line.3.horizontal"
        }
    }
}
