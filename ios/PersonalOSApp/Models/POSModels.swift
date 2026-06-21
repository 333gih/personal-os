import Foundation

struct POSUser: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
}

struct POSArchitectureLayer: Codable, Identifiable {
    var id: String { layer }
    let layer: String
    let nodes: [String]
}

struct POSEntity: Codable, Identifiable, Hashable {
    static func == (lhs: POSEntity, rhs: POSEntity) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    let id: String
    let type: String
    let title: String
    let content: String
    let status: String
    let domain: String
    let createdAt: String
    let updatedAt: String
    let tags: POSTagsValue?
    let metadata: POSWorkMetadata?

    enum CodingKeys: String, CodingKey {
        case id, type, title, content, status, domain, tags, metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        type = try c.decode(String.self, forKey: .type)
        title = try c.decode(String.self, forKey: .title)
        content = try c.decodeIfPresent(String.self, forKey: .content) ?? ""
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? "active"
        domain = try c.decodeIfPresent(String.self, forKey: .domain) ?? "work"
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
        tags = try? c.decode(POSTagsValue.self, forKey: .tags)
        metadata = try? c.decode(POSWorkMetadata.self, forKey: .metadata)
    }

    var tagList: [String] {
        tags?.values ?? []
    }

    var isActiveWork: Bool {
        metadata?.status == "active" || (metadata?.status == nil && status == "active")
    }

    var architectureLayers: [POSArchitectureLayer] {
        metadata?.architectureLayers ?? []
    }

    func designImageURL() -> URL? {
        guard let path = metadata?.heroImage, !path.isEmpty else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        return PersonalOSAppConfig.frontendPath(path)
    }
}

struct POSWorkMetadata: Codable {
    let kind: String?
    let company: String?
    let role: String?
    let startDate: String?
    let endDate: String?
    let status: String?
    let location: String?
    let priority: String?
    let workHours: String?
    let level: String?
    let image: String?
    let designImages: [String]?
    let architectureLayers: [POSArchitectureLayer]?
    let cvStatus: String?
    let track: String?
    let phase: String?
    let patternOrder: Int?
    let week: String?
    let courseSlug: String?
    let referenceUrls: [String]?
    let whenToUse: String?
    let recognitionSignals: [String]?
    let practiceStrategy: String?
    let codeTemplate: String?
    let problems: [String]?
    let benchmarkEasyMin: Int?
    let benchmarkMediumMin: Int?
    let benchmarkHardMin: Int?
    let patternSlug: String?

    enum CodingKeys: String, CodingKey {
        case kind, company, role, status, location, priority, level, image, track, phase, week
        case startDate = "start_date"
        case endDate = "end_date"
        case workHours = "work_hours"
        case designImages = "design_images"
        case architectureLayers = "architecture_layers"
        case cvStatus = "cv_status"
        case patternOrder = "pattern_order"
        case courseSlug = "course_slug"
        case referenceUrls = "reference_urls"
        case whenToUse = "when_to_use"
        case recognitionSignals = "recognition_signals"
        case practiceStrategy = "practice_strategy"
        case codeTemplate = "code_template"
        case problems
        case benchmarkEasyMin = "benchmark_easy_min"
        case benchmarkMediumMin = "benchmark_medium_min"
        case benchmarkHardMin = "benchmark_hard_min"
        case patternSlug = "pattern_slug"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try? c.decode(String.self, forKey: .kind)
        company = try? c.decode(String.self, forKey: .company)
        role = try? c.decode(String.self, forKey: .role)
        startDate = POSEntity.decodeFlexibleString(c, key: .startDate)
        endDate = POSEntity.decodeFlexibleString(c, key: .endDate)
        status = try? c.decode(String.self, forKey: .status)
        location = try? c.decode(String.self, forKey: .location)
        priority = try? c.decode(String.self, forKey: .priority)
        workHours = try? c.decode(String.self, forKey: .workHours)
        level = try? c.decode(String.self, forKey: .level)
        image = try? c.decode(String.self, forKey: .image)
        designImages = try? c.decode([String].self, forKey: .designImages)
        architectureLayers = try? c.decode([POSArchitectureLayer].self, forKey: .architectureLayers)
        cvStatus = try? c.decode(String.self, forKey: .cvStatus)
        track = try? c.decode(String.self, forKey: .track)
        phase = try? c.decode(String.self, forKey: .phase)
        patternOrder = try? c.decode(Int.self, forKey: .patternOrder)
        week = try? c.decode(String.self, forKey: .week)
        courseSlug = try? c.decode(String.self, forKey: .courseSlug)
        referenceUrls = try? c.decode([String].self, forKey: .referenceUrls)
        whenToUse = try? c.decode(String.self, forKey: .whenToUse)
        recognitionSignals = try? c.decode([String].self, forKey: .recognitionSignals)
        practiceStrategy = try? c.decode(String.self, forKey: .practiceStrategy)
        codeTemplate = try? c.decode(String.self, forKey: .codeTemplate)
        problems = try? c.decode([String].self, forKey: .problems)
        benchmarkEasyMin = try? c.decode(Int.self, forKey: .benchmarkEasyMin)
        benchmarkMediumMin = try? c.decode(Int.self, forKey: .benchmarkMediumMin)
        benchmarkHardMin = try? c.decode(Int.self, forKey: .benchmarkHardMin)
        patternSlug = try? c.decode(String.self, forKey: .patternSlug)
    }

    func periodLabel() -> String {
        let start = startDate.flatMap { POSFormatting.monthYear($0) } ?? ""
        let end: String
        if let endDate, !endDate.isEmpty {
            end = POSFormatting.monthYear(endDate)
        } else if status == "active" {
            end = "Present"
        } else {
            end = ""
        }
        if !start.isEmpty && !end.isEmpty { return "\(start) — \(end)" }
        if !start.isEmpty { return "\(start) — Present" }
        return end
    }

    var heroImage: String? {
        if let image, !image.isEmpty { return image }
        return designImages?.first
    }
}

extension POSEntity {
    static func decodeFlexibleString(_ c: KeyedDecodingContainer<POSWorkMetadata.CodingKeys>, key: POSWorkMetadata.CodingKeys) -> String? {
        if let s = try? c.decode(String.self, forKey: key) { return s }
        if (try? c.decodeNil(forKey: key)) == true { return nil }
        return nil
    }
}

enum POSTagsValue: Codable {
    case array([String])
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if try container.decodeNil() {
            self = .array([])
            return
        }
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

struct POSEntityDetailResponse: Codable {
    let entity: POSEntity
    let relations: [POSRelationItem]
}

struct POSRelationItem: Codable, Identifiable {
    var id: String { relatedEntity.id }
    let relationType: String
    let direction: String
    let relatedEntity: POSEntity

    enum CodingKeys: String, CodingKey {
        case relationType = "relation_type"
        case direction
        case relatedEntity = "related_entity"
    }

    var relationLabel: String {
        let arrow = direction == "outgoing" ? "→" : "←"
        return "\(relationType.replacingOccurrences(of: "_", with: " ")) \(arrow)"
    }
}

extension POSEntity {
    var typeLabel: String {
        type
            .replacingOccurrences(of: "work_", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    var typeIcon: String {
        if type.contains("project") { return "folder.fill" }
        if type.contains("role") { return "person.crop.rectangle" }
        if type.contains("employer") { return "building.2.fill" }
        if type.contains("feature") { return "puzzlepiece.fill" }
        if type.contains("design") { return "square.grid.2x2" }
        if type.contains("cv_entry") { return "doc.text.fill" }
        if type.contains("technology") { return "cpu" }
        if type.contains("decision") { return "lightbulb.fill" }
        if type.contains("lesson") { return "book.fill" }
        return "doc"
    }

    var detailSubtitle: String? {
        let parts = [metadata?.company, metadata?.role, metadata?.periodLabel()]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var metadataRows: [(label: String, value: String)] {
        var rows: [(String, String)] = []
        if let company = metadata?.company, !company.isEmpty { rows.append(("Company", company)) }
        if let role = metadata?.role, !role.isEmpty { rows.append(("Role", role)) }
        if let period = metadata?.periodLabel(), !period.isEmpty { rows.append(("Period", period)) }
        if let location = metadata?.location, !location.isEmpty { rows.append(("Location", location)) }
        if let level = metadata?.level, !level.isEmpty { rows.append(("Level", level.capitalized)) }
        if let cv = metadata?.cvStatus, !cv.isEmpty {
            rows.append(("CV", cv == "in_cv" ? "On resume" : "Recommended add"))
        }
        if let hours = metadata?.workHours, !hours.isEmpty {
            rows.append(("Hours", hours.replacingOccurrences(of: "-", with: " – ")))
        }
        return rows
    }
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
        case .more: return "More"
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
