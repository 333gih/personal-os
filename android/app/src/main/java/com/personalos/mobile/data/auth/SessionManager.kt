package com.personalos.mobile.data.auth

import com.personalos.mobile.config.AppEnvironment
import com.personalos.mobile.network.AuthHttpClient
import com.personalos.mobile.util.JwtHelpers
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

class SessionManager(
    private val sessionStore: AuthSessionStore,
    private val authHttp: AuthHttpClient,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val refreshMutex = Mutex()
    private var refreshJob: Job? = null
    private var proactiveRefreshJob: Job? = null

    private var storedSession: StoredAuthSession? = sessionStore.load()

    private val _accessToken = MutableStateFlow<String?>(storedSession?.accessToken)
    val accessToken: StateFlow<String?> = _accessToken.asStateFlow()

    private val _user = MutableStateFlow<com.personalos.mobile.data.models.PosUser?>(null)
    val user: StateFlow<com.personalos.mobile.data.models.PosUser?> = _user.asStateFlow()

    private val _isAuthenticated = MutableStateFlow(initAuthenticated())
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()

    private fun initAuthenticated(): Boolean {
        val session = storedSession ?: return false
        return JwtHelpers.isRefreshTokenValid(session)
    }

    fun bootstrap(onReady: suspend () -> Unit = {}) {
        scope.launch {
            refreshSessionIfNeeded(force = false)
            if (_isAuthenticated.value) {
                scheduleProactiveRefresh()
                onReady()
            }
        }
    }

    fun refreshSessionIfNeeded(force: Boolean = false) {
        scope.launch {
            val session = storedSession
            if (session == null) {
                if (!_isAuthenticated.value) return@launch
                signOut()
                return@launch
            }
            if (!JwtHelpers.isRefreshTokenValid(session)) {
                signOut()
                return@launch
            }
            val needsRefresh = force ||
                JwtHelpers.shouldRefreshAccess(session) ||
                JwtHelpers.isExpired(session.accessToken)
            if (needsRefresh) {
                refreshAccessToken(force = force || JwtHelpers.isExpired(session.accessToken))
            }
        }
    }

    fun saveHandoff(handoff: MobileAuthHandoff) {
        val (accessExpiry, refreshExpiry) = JwtHelpers.sessionExpiry(
            handoff.accessToken,
            handoff.refreshToken,
            handoff.expiresIn,
            handoff.refreshExpiresIn,
        )
        val session = StoredAuthSession(
            accessToken = handoff.accessToken,
            refreshToken = handoff.refreshToken,
            expiresAtMs = accessExpiry,
            refreshExpiresAtMs = refreshExpiry,
            applicationId = handoff.applicationId,
        )
        persist(session)
        scheduleProactiveRefresh()
    }

    suspend fun validAccessToken(): String? {
        val session = storedSession ?: run {
            signOut()
            return null
        }
        if (!JwtHelpers.isRefreshTokenValid(session)) {
            signOut()
            return null
        }
        if (!JwtHelpers.shouldRefreshAccess(session) && !JwtHelpers.isExpired(session.accessToken)) {
            _accessToken.value = session.accessToken
            return session.accessToken
        }
        return refreshAccessToken(force = false)
    }

    suspend fun refreshAccessToken(force: Boolean): String? = refreshMutex.withLock {
        refreshJob?.join()
        val job = scope.launch(Dispatchers.IO) {
            performRefresh(force)
        }
        refreshJob = job
        job.join()
        return storedSession?.accessToken
    }

    fun signOut() {
        val refresh = storedSession?.refreshToken
        proactiveRefreshJob?.cancel()
        clearLocal()
        if (!refresh.isNullOrBlank()) {
            scope.launch(Dispatchers.IO) {
                runCatching { authHttp.logout(refresh) }
            }
        }
    }

    fun setUser(user: com.personalos.mobile.data.models.PosUser?) {
        _user.value = user
    }

    fun userInitials(): String {
        val name = _user.value?.name?.trim().orEmpty()
        if (name.isEmpty()) return "?"
        val parts = name.split(" ").filter { it.isNotBlank() }
        return when {
            parts.size == 1 -> parts[0].take(1).uppercase()
            else -> "${parts.first().take(1)}${parts.last().take(1)}".uppercase()
        }
    }

    fun firstName(): String {
        val name = _user.value?.name?.trim().orEmpty()
        if (name.isEmpty()) return "there"
        return name.split(" ").firstOrNull() ?: name
    }

    fun scheduleProactiveRefresh() {
        proactiveRefreshJob?.cancel()
        val session = storedSession ?: return
        if (!JwtHelpers.isRefreshTokenValid(session)) return
        val delayMs = session.expiresAtMs - 5 * 60 * 1000L - System.currentTimeMillis()
        proactiveRefreshJob = scope.launch {
            if (delayMs > 0) delay(delayMs)
            refreshSessionIfNeeded(force = true)
            scheduleProactiveRefresh()
        }
    }

    private suspend fun performRefresh(force: Boolean): String? {
        val session = storedSession ?: return null
        if (!JwtHelpers.isRefreshTokenValid(session)) {
            signOut()
            return null
        }
        if (!force && !JwtHelpers.shouldRefreshAccess(session) && !JwtHelpers.isExpired(session.accessToken)) {
            _accessToken.value = session.accessToken
            return session.accessToken
        }
        return try {
            val refreshed = authHttp.refresh(session.refreshToken)
            val (accessExpiry, refreshExpiry) = JwtHelpers.sessionExpiry(
                refreshed.accessToken,
                refreshed.refreshToken,
                refreshed.expiresIn,
                refreshed.refreshExpiresIn,
            )
            val updated = StoredAuthSession(
                accessToken = refreshed.accessToken,
                refreshToken = refreshed.refreshToken,
                expiresAtMs = accessExpiry,
                refreshExpiresAtMs = refreshExpiry,
                applicationId = session.applicationId,
            )
            persist(updated)
            scheduleProactiveRefresh()
            updated.accessToken
        } catch (e: AuthHttpClient.UnauthorizedException) {
            signOut()
            null
        } catch (_: Exception) {
            if (!JwtHelpers.isExpired(session.accessToken)) {
                _accessToken.value = session.accessToken
                session.accessToken
            } else {
                null
            }
        }
    }

    private fun persist(session: StoredAuthSession) {
        storedSession = session
        _accessToken.value = session.accessToken
        _isAuthenticated.value = JwtHelpers.isRefreshTokenValid(session)
        sessionStore.save(session)
    }

    private fun clearLocal() {
        storedSession = null
        _accessToken.value = null
        _user.value = null
        _isAuthenticated.value = false
        refreshJob?.cancel()
        refreshJob = null
        sessionStore.clear()
    }
}
