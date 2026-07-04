import Foundation

@MainActor
final class ModulesStore: ObservableObject {
    static let cacheKey = "pos.modules.cache"

    @Published private(set) var catalog: [POSModuleCatalogEntry] = []
    @Published private(set) var prefs: [POSModulePref] = []
    @Published private(set) var tabIds: [String] = ["dashboard", "work", "learning", "search"]
    @Published private(set) var drawerIds: [String] = ["startup", "entertainment", "goals", "inbox", "settings"]
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private weak var session: SessionManager?

    func attach(session: SessionManager) {
        self.session = session
        loadCache()
    }

    func refresh(force: Bool = false) async {
        guard let session else { return }
        if !force, !catalog.isEmpty { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let client = APIClient()
            client.session = session
            let data = try await client.authorizedRequest(path: "modules")
            let response = try JSONDecoder().decode(POSModulesResponse.self, from: data)
            apply(response)
            UserDefaults.standard.set(data, forKey: Self.cacheKey)
        } catch {
            if catalog.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }

    func update(modules: [(id: String, enabled: Bool?, pinOrder: Int?)]) async throws {
        guard let session else { return }
        let payload = POSModuleUpdateRequest(prefs: modules.map {
            POSModuleUpdatePref(moduleId: $0.id, enabled: $0.enabled, pinOrder: $0.pinOrder, config: nil)
        })
        let body = try JSONEncoder().encode(payload)
        let client = APIClient()
        client.session = session
        let data = try await client.authorizedRequest(path: "modules", method: "PUT", body: body)
        let response = try JSONDecoder().decode(POSModulesResponse.self, from: data)
        apply(response)
        UserDefaults.standard.set(data, forKey: Self.cacheKey)
    }

    func isEnabled(_ moduleId: String) -> Bool {
        prefs.first(where: { $0.moduleId == moduleId })?.enabled ?? true
    }

    func domainModules() -> [POSModuleCatalogEntry] {
        catalog.filter { $0.tier == "domain" }
    }

    var bottomTabIds: [String] {
        var ids = tabIds
        if !drawerIds.isEmpty, !ids.contains("more") {
            ids.append("more")
        }
        return ids
    }

    private func apply(_ response: POSModulesResponse) {
        catalog = response.catalog
        prefs = response.prefs
        tabIds = response.nav.tabs
        drawerIds = response.nav.drawer
    }

    private func loadCache() {
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey) else { return }
        if let response = try? JSONDecoder().decode(POSModulesResponse.self, from: data) {
            apply(response)
        }
    }
}
