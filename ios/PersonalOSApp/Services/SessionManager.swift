import Foundation
import Combine

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var accessToken: String?
    @Published private(set) var user: POSUser?
    @Published private(set) var isAuthenticated = false

    private static let accessRefreshLead: TimeInterval = 5 * 60
    private static let refreshSkew: TimeInterval = 60
    private static let legacyTokenKey = "com.personalos.access_token"

    private var storedSession: StoredAuthSession?
    private var refreshTask: Task<String?, Never>?

    let api = APIClient()

    init() {
        api.session = self
        storedSession = AuthKeychain.load()
        if storedSession == nil, let legacy = UserDefaults.standard.string(forKey: Self.legacyTokenKey), !legacy.isEmpty {
            // Legacy installs only saved access token — user must sign in once for refresh bundle.
            accessToken = legacy
            isAuthenticated = !JWTHelpers.isExpired(legacy)
        } else if let session = storedSession, isRefreshTokenValid(session) {
            accessToken = session.accessToken
            isAuthenticated = true
        } else {
            clearLocalSession()
        }
    }

    func bootstrap() async {
        guard isAuthenticated else { return }
        if storedSession != nil {
            _ = await validAccessToken()
        }
        await refreshUser()
    }

    func saveHandoff(_ handoff: POSMobileAuthHandoff) {
        let now = Date()
        var accessExpiry = now.addingTimeInterval(TimeInterval(max(60, handoff.expiresIn)))
        if let jwtExp = JWTHelpers.expirationDate(for: handoff.accessToken) {
            accessExpiry = jwtExp
        }
        var refreshExpiry = now.addingTimeInterval(TimeInterval(max(3600, handoff.refreshExpiresIn)))
        if let jwtRefreshExp = JWTHelpers.expirationDate(for: handoff.refreshToken) {
            refreshExpiry = jwtRefreshExp
        }

        let session = StoredAuthSession(
            accessToken: handoff.accessToken,
            refreshToken: handoff.refreshToken,
            expiresAt: accessExpiry,
            refreshExpiresAt: refreshExpiry,
            applicationId: handoff.applicationId
        )
        persist(session)
        UserDefaults.standard.removeObject(forKey: Self.legacyTokenKey)
        Task { await refreshUser() }
    }

    /// Returns a usable access token, refreshing proactively when near expiry.
    func validAccessToken() async -> String? {
        guard var session = storedSession else {
            if let token = accessToken, !JWTHelpers.isExpired(token) {
                return token
            }
            signOut()
            return nil
        }

        if !isRefreshTokenValid(session) {
            signOut()
            return nil
        }

        if !shouldRefreshAccessToken(session), !JWTHelpers.isExpired(session.accessToken) {
            accessToken = session.accessToken
            return session.accessToken
        }

        return await refreshAccessToken(force: false)
    }

    /// Refresh tokens; signs out only when refresh token is rejected.
    @discardableResult
    func refreshAccessToken(force: Bool) async -> String? {
        if let refreshTask {
            return await refreshTask.value
        }

        let task = Task<String?, Never> { [weak self] in
            guard let self else { return nil }
            defer { self.refreshTask = nil }
            return await self.performRefresh(force: force)
        }
        refreshTask = task
        return await task.value
    }

    func signOut() {
        clearLocalSession()
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

    private func performRefresh(force: Bool) async -> String? {
        guard var session = storedSession else { return accessToken }

        if !isRefreshTokenValid(session) {
            signOut()
            return nil
        }

        if !force, !shouldRefreshAccessToken(session), !JWTHelpers.isExpired(session.accessToken) {
            accessToken = session.accessToken
            return session.accessToken
        }

        do {
            let refreshed = try await refreshTokens(refreshToken: session.refreshToken)
            let now = Date()
            var accessExpiry = now.addingTimeInterval(TimeInterval(max(60, refreshed.expiresIn)))
            if let jwtExp = JWTHelpers.expirationDate(for: refreshed.accessToken) {
                accessExpiry = jwtExp
            }
            var refreshExpiry = now.addingTimeInterval(TimeInterval(max(3600, refreshed.refreshExpiresIn)))
            if let jwtRefreshExp = JWTHelpers.expirationDate(for: refreshed.refreshToken) {
                refreshExpiry = jwtRefreshExp
            }

            session = StoredAuthSession(
                accessToken: refreshed.accessToken,
                refreshToken: refreshed.refreshToken,
                expiresAt: accessExpiry,
                refreshExpiresAt: refreshExpiry,
                applicationId: session.applicationId
            )
            persist(session)
            return session.accessToken
        } catch let error as APIError {
            if case .unauthorized = error {
                signOut()
                return nil
            }
            if case .http(let code, _) = error, code == 401 || code == 403 {
                signOut()
                return nil
            }
            if !JWTHelpers.isExpired(session.accessToken) {
                accessToken = session.accessToken
                return session.accessToken
            }
            return nil
        } catch {
            if !JWTHelpers.isExpired(session.accessToken) {
                accessToken = session.accessToken
                return session.accessToken
            }
            return nil
        }
    }

    private func refreshTokens(refreshToken: String) async throws -> POSMobileTokenRefreshResponse {
        let url = PersonalOSAppConfig.frontendPath("/api/auth/mobile/refresh")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.http(-1, "Invalid response")
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw APIError.unauthorized
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Refresh failed"
            throw APIError.http(http.statusCode, message)
        }
        return try JSONDecoder().decode(POSMobileTokenRefreshResponse.self, from: data)
    }

    private func persist(_ session: StoredAuthSession) {
        storedSession = session
        accessToken = session.accessToken
        isAuthenticated = isRefreshTokenValid(session)
        AuthKeychain.save(session)
    }

    private func clearLocalSession() {
        storedSession = nil
        accessToken = nil
        user = nil
        isAuthenticated = false
        refreshTask?.cancel()
        refreshTask = nil
        AuthKeychain.clear()
        UserDefaults.standard.removeObject(forKey: Self.legacyTokenKey)
    }

    private func isRefreshTokenValid(_ session: StoredAuthSession) -> Bool {
        Date().addingTimeInterval(Self.refreshSkew) < session.refreshExpiresAt
    }

    private func shouldRefreshAccessToken(_ session: StoredAuthSession) -> Bool {
        Date().addingTimeInterval(Self.accessRefreshLead) >= session.expiresAt
            || JWTHelpers.isExpired(session.accessToken)
    }
}
