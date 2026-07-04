import Foundation

struct POSModulesResponse: Decodable {
    let catalog: [POSModuleCatalogEntry]
    let prefs: [POSModulePref]
    let nav: POSNavManifest
    let rules: POSModuleRules
}

struct POSModuleCatalogEntry: Decodable, Identifiable {
    let id: String
    let label: String
    let description: String
    let icon: String
    let tier: String
    let domain: String?
    let defaultEnabled: Bool
    let required: Bool
    let dependsOn: [String]?
    let navHref: String?
    let aiPersona: String?
    let integrationSlots: [String]?

    enum CodingKeys: String, CodingKey {
        case id, label, description, icon, tier, domain, required
        case defaultEnabled = "default_enabled"
        case dependsOn = "depends_on"
        case navHref = "nav_href"
        case aiPersona = "ai_persona"
        case integrationSlots = "integration_slots"
    }
}

struct POSModulePref: Decodable, Identifiable {
    var id: String { moduleId }
    let moduleId: String
    let enabled: Bool
    let pinOrder: Int?
    let config: [String: POSJSONValue]?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case moduleId = "module_id"
        case enabled
        case pinOrder = "pin_order"
        case config
        case updatedAt = "updated_at"
    }
}

struct POSNavManifest: Decodable {
    let tabs: [String]
    let drawer: [String]
}

struct POSModuleRules: Decodable {
    let required: [String]
    let minEnabledDomains: Int
    let maxEnabledDomains: Int
    let maxPinnedTabs: Int

    enum CodingKeys: String, CodingKey {
        case required
        case minEnabledDomains = "min_enabled_domains"
        case maxEnabledDomains = "max_enabled_domains"
        case maxPinnedTabs = "max_pinned_tabs"
    }
}

struct POSModuleUpdateRequest: Encodable {
    let prefs: [POSModuleUpdatePref]
}

struct POSModuleUpdatePref: Encodable {
    let moduleId: String
    let enabled: Bool?
    let pinOrder: Int?
    let config: [String: Bool]?

    enum CodingKeys: String, CodingKey {
        case moduleId = "module_id"
        case enabled
        case pinOrder = "pin_order"
        case config
    }
}

enum POSJSONValue: Decodable, Encodable {
    case bool(Bool)
    case string(String)
    case number(Double)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let n = try? container.decode(Double.self) {
            self = .number(n)
        } else {
            self = .bool(false)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let b): try container.encode(b)
        case .string(let s): try container.encode(s)
        case .number(let n): try container.encode(n)
        }
    }
}

enum POSTabID: String, CaseIterable {
    case dashboard, work, learning, search, more
    case startup, entertainment, goals, inbox, settings, journal

    var title: String {
        switch self {
        case .dashboard: return "Home"
        case .work: return "Work"
        case .learning: return "Learning"
        case .search: return "Search"
        case .more: return "More"
        case .startup: return "Startup"
        case .entertainment: return "Reading"
        case .goals: return "Goals"
        case .inbox: return "Inbox"
        case .settings: return "Settings"
        case .journal: return "Journal"
        }
    }

    var headerTitle: String {
        switch self {
        case .work: return "Career Path"
        case .startup: return "Startup Ecosystem"
        default: return "Personal OS"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "house.fill"
        case .work: return "briefcase.fill"
        case .learning: return "graduationcap.fill"
        case .search: return "magnifyingglass"
        case .more: return "line.3.horizontal"
        case .startup: return "rocket.fill"
        case .entertainment: return "gamecontroller.fill"
        case .goals: return "target"
        case .inbox: return "tray.full"
        case .settings: return "gearshape.fill"
        case .journal: return "book.fill"
        }
    }

    static func from(_ raw: String) -> POSTabID? {
        POSTabID(rawValue: raw)
    }
}
