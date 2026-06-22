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
    private static let defaultRefreshTTL: TimeInterval = 7 * 24 * 3600

    private var storedSession: StoredAuthSession?
    private var refreshTask: Task<String?, Never>?
    private var refreshTimer: Timer?
    private var hasLegacyAccessOnly = false

    let api = APIClient()

    init() {
        api.session = self
        storedSession = AuthKeychain.load()
        if storedSession == nil, let legacy = UserDefaults.standard.string(forKey: Self.legacyTokenKey), !legacy.isEmpty {
            hasLegacyAccessOnly = true
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
        await refreshSessionIfNeeded(force: false)
        if isAuthenticated {
            scheduleProactiveRefresh()
        }
    }

    /// Called on launch, foreground, and before API calls — mirrors web portal refresh-on-401 / renew flow.
    func refreshSessionIfNeeded(force: Bool = false) async {
        if hasLegacyAccessOnly {
            if let token = accessToken, !JWTHelpers.isExpired(token) {
                await refreshUser()
                return
            }
            signOut()
            return
        }

        guard isAuthenticated else { return }
        guard let session = storedSession else {
            if let token = accessToken, !JWTHelpers.isExpired(token) { return }
            signOut()
            return
        }

        if !isRefreshTokenValid(session) {
            signOut()
            return
        }

        let needsRefresh = force
            || shouldRefreshAccessToken(session)
            || JWTHelpers.isExpired(session.accessToken)

        if needsRefresh {
            _ = await refreshAccessToken(force: force || JWTHelpers.isExpired(session.accessToken))
        }

        guard isAuthenticated else { return }
        await refreshUser()
    }

    func saveHandoff(_ handoff: POSMobileAuthHandoff) {
        hasLegacyAccessOnly = false
        let (accessExpiry, refreshExpiry) = Self.sessionExpiry(
            accessToken: handoff.accessToken,
            refreshToken: handoff.refreshToken,
            expiresIn: handoff.expiresIn,
            refreshExpiresIn: handoff.refreshExpiresIn
        )

        let session = StoredAuthSession(
            accessToken: handoff.accessToken,
            refreshToken: handoff.refreshToken,
            expiresAt: accessExpiry,
            refreshExpiresAt: refreshExpiry,
            applicationId: handoff.applicationId
        )
        persist(session)
        UserDefaults.standard.removeObject(forKey: Self.legacyTokenKey)
        scheduleProactiveRefresh()
        Task {
            await refreshUser()
            await POSPushCoordinator.shared.bootstrapAfterLogin(session: self)
        }
    }

    /// Returns a usable access token, refreshing proactively when near expiry.
    func validAccessToken() async -> String? {
        if hasLegacyAccessOnly {
            if let token = accessToken, !JWTHelpers.isExpired(token) {
                return token
            }
            signOut()
            return nil
        }

        guard let session = storedSession else {
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

    /// Refresh tokens; signs out only when refresh token is rejected or expired.
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
        let refreshToken = storedSession?.refreshToken
        refreshTimer?.invalidate()
        refreshTimer = nil
        clearLocalSession()
        if let refreshToken {
            Task { await Self.revokeRefreshToken(refreshToken) }
        }
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

    func scheduleProactiveRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        guard isAuthenticated, let session = storedSession, isRefreshTokenValid(session) else { return }

        let fireDate = session.expiresAt.addingTimeInterval(-Self.accessRefreshLead)
        let delay = fireDate.timeIntervalSinceNow
        if delay <= 0 {
            Task { [weak self] in
                await self?.refreshSessionIfNeeded(force: true)
                self?.scheduleProactiveRefresh()
            }
            return
        }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshSessionIfNeeded(force: true)
                self?.scheduleProactiveRefresh()
            }
        }
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
            let (accessExpiry, refreshExpiry) = Self.sessionExpiry(
                accessToken: refreshed.accessToken,
                refreshToken: refreshed.refreshToken,
                expiresIn: refreshed.expiresIn,
                refreshExpiresIn: refreshed.refreshExpiresIn
            )

            session = StoredAuthSession(
                accessToken: refreshed.accessToken,
                refreshToken: refreshed.refreshToken,
                expiresAt: accessExpiry,
                refreshExpiresAt: refreshExpiry,
                applicationId: session.applicationId
            )
            persist(session)
            scheduleProactiveRefresh()
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

    private static func revokeRefreshToken(_ refreshToken: String) async {
        let url = PersonalOSAppConfig.frontendPath("/api/auth/mobile/logout")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["refresh_token": refreshToken])
        _ = try? await URLSession.shared.data(for: request)
    }

    private static func sessionExpiry(
        accessToken: String,
        refreshToken: String,
        expiresIn: Int,
        refreshExpiresIn: Int
    ) -> (access: Date, refresh: Date) {
        let now = Date()
        var accessExpiry = now.addingTimeInterval(TimeInterval(max(60, expiresIn)))
        if let jwtExp = JWTHelpers.expirationDate(for: accessToken) {
            accessExpiry = jwtExp
        }

        let refreshSeconds = max(300, refreshExpiresIn)
        var refreshExpiry = now.addingTimeInterval(TimeInterval(refreshSeconds > 0 ? refreshSeconds : Int(defaultRefreshTTL)))
        if let jwtRefreshExp = JWTHelpers.expirationDate(for: refreshToken) {
            refreshExpiry = jwtRefreshExp
        }
        return (accessExpiry, refreshExpiry)
    }

    private func persist(_ session: StoredAuthSession) {
        storedSession = session
        accessToken = session.accessToken
        isAuthenticated = isRefreshTokenValid(session)
        AuthKeychain.save(session)
    }

    private func clearLocalSession() {
        hasLegacyAccessOnly = false
        storedSession = nil
        accessToken = nil
        user = nil
        isAuthenticated = false
        refreshTask?.cancel()
        refreshTask = nil
        refreshTimer?.invalidate()
        refreshTimer = nil
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
