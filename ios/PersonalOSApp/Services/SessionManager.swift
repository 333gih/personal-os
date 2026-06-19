import Foundation
import Combine

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var accessToken: String?
    @Published private(set) var user: POSUser?
    @Published var isAuthenticated = false

    private let tokenKey = "com.personalos.access_token"
    let api = APIClient()

    init() {
        api.session = self
        accessToken = UserDefaults.standard.string(forKey: tokenKey)
        isAuthenticated = accessToken?.isEmpty == false
    }

    func saveToken(_ token: String) {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        accessToken = trimmed
        UserDefaults.standard.set(trimmed, forKey: tokenKey)
        isAuthenticated = true
        Task { await refreshUser() }
    }

    func signOut() {
        accessToken = nil
        user = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }

    func refreshUser() async {
        guard isAuthenticated else { return }
        do {
            user = try await api.me()
        } catch {
            if case APIError.unauthorized = error {
                signOut()
            }
        }
    }

    func userInitials() -> String {
        guard let name = user?.name.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return "?"
        }
        let parts = name.split(separator: " ")
        if parts.count == 1 { return String(parts[0].prefix(1)).uppercased() }
        return "\(parts.first!.prefix(1))\(parts.last!.prefix(1))".uppercased()
    }

    func firstName() -> String {
        guard let name = user?.name.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return "there"
        }
        return name.split(separator: " ").first.map(String.init) ?? name
    }
}
