package com.personalos.mobile.data.auth

import android.util.Log
import com.personalos.mobile.network.AuthHttpClient
import com.personalos.mobile.util.JwtHelpers
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull

class SessionManager(
    private val sessionStore: AuthSessionStore,
    private val authHttp: AuthHttpClient,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val refreshMutex = Mutex()
    private var refreshDeferred: Deferred<String?>? = null
    private var proactiveRefreshJob: Job? = null

    private var storedSession: StoredAuthSession? = sessionStore.load()

    private val _accessToken = MutableStateFlow<String?>(storedSession?.accessToken)
    val accessToken: StateFlow<String?> = _accessToken.asStateFlow()

    private val _user = MutableStateFlow<com.personalos.mobile.data.models.PosUser?>(null)
    val user: StateFlow<com.personalos.mobile.data.models.PosUser?> = _user.asStateFlow()

    private val _isAuthenticated = MutableStateFlow(initAuthenticated())
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()

    private val _bootstrapReady = MutableStateFlow(shouldSkipBootstrapRefresh())
    val bootstrapReady: StateFlow<Boolean> = _bootstrapReady.asStateFlow()

    @Volatile
    private var bootstrapStarted = false

    private fun initAuthenticated(): Boolean {
        val session = storedSession ?: return false
        return JwtHelpers.isRefreshTokenValid(session)
    }

    /** No stored session — show login immediately without waiting for network. */
    private fun shouldSkipBootstrapRefresh(): Boolean {
        val session = storedSession ?: return true
        return !JwtHelpers.isRefreshTokenValid(session)
    }

    fun bootstrap(onReady: suspend () -> Unit = {}) {
        if (bootstrapStarted) {
            scope.launch {
                waitForBootstrapReady()
                if (_isAuthenticated.value) onReady()
            }
            return
        }
        bootstrapStarted = true

        scope.launch {
            try {
                if (_isAuthenticated.value) {
                    awaitSessionRefresh(force = false)
                    if (_isAuthenticated.value) {
                        scheduleProactiveRefresh()
                    }
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, "bootstrap refresh failed", e)
                applyCachedTokenFallback()
            } finally {
                _bootstrapReady.value = true
            }
            if (_isAuthenticated.value) {
                onReady()
            }
        }
    }

    private suspend fun waitForBootstrapReady() {
        if (_bootstrapReady.value) return
        withTimeoutOrNull(BOOTSTRAP_UI_TIMEOUT_MS) {
            while (!_bootstrapReady.value) {
                delay(50)
            }
        }
        if (!_bootstrapReady.value) {
            Log.w(TAG, "bootstrap wait timed out — unblocking UI")
            _bootstrapReady.value = true
        }
    }

    fun refreshSessionIfNeeded(force: Boolean = false) {
        scope.launch {
            runCatching { awaitSessionRefresh(force) }
                .onFailure { e ->
                    if (e !is CancellationException) {
                        Log.w(TAG, "refreshSessionIfNeeded failed", e)
                    }
                }
        }
    }

    /** Re-run session restore after UI timeout (mirrors iOS re-bootstrap on retry). */
    fun retryBootstrap(onReady: suspend () -> Unit = {}) {
        _bootstrapReady.value = false
        scope.launch {
            try {
                if (_isAuthenticated.value) {
                    awaitSessionRefresh(force = true)
                    if (_isAuthenticated.value) {
                        scheduleProactiveRefresh()
                    }
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, "retryBootstrap failed", e)
                applyCachedTokenFallback()
            } finally {
                _bootstrapReady.value = true
            }
            if (_isAuthenticated.value) {
                onReady()
            }
        }
    }

    private suspend fun awaitSessionRefresh(force: Boolean) {
        val session = storedSession
        if (session == null) {
            if (_isAuthenticated.value) signOut()
            return
        }
        if (!JwtHelpers.isRefreshTokenValid(session)) {
            signOut()
            return
        }
        val needsRefresh = force ||
            JwtHelpers.shouldRefreshAccess(session) ||
            JwtHelpers.isExpired(session.accessToken)
        if (needsRefresh) {
            withTimeoutOrNull(REFRESH_TIMEOUT_MS) {
                refreshAccessToken(force = force || JwtHelpers.isExpired(session.accessToken))
            } ?: run {
                Log.w(TAG, "refresh timed out during bootstrap")
                applyCachedTokenFallback()
            }
        }
    }

    private fun applyCachedTokenFallback() {
        val session = storedSession ?: return
        if (JwtHelpers.isRefreshTokenValid(session) && !JwtHelpers.isExpired(session.accessToken)) {
            _accessToken.value = session.accessToken
            _isAuthenticated.value = true
            return
        }
        if (!JwtHelpers.isRefreshTokenValid(session)) {
            signOut()
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
        _bootstrapReady.value = true
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
        awaitInFlightRefresh()
        val current = storedSession ?: return null
        if (!JwtHelpers.shouldRefreshAccess(current) && !JwtHelpers.isExpired(current.accessToken)) {
            _accessToken.value = current.accessToken
            return current.accessToken
        }
        return refreshAccessToken(force = false)
    }

    suspend fun refreshAccessToken(force: Boolean): String? {
        refreshMutex.withLock { refreshDeferred?.takeIf { it.isActive } }?.let { existing ->
            return withTimeoutOrNull(REFRESH_TIMEOUT_MS) { existing.await() } ?: fallbackToken()
        }

        val deferred = refreshMutex.withLock {
            refreshDeferred?.takeIf { it.isActive }?.let { return@withLock it }
            scope.async(Dispatchers.IO) {
                performRefresh(force)
            }.also { refreshDeferred = it }
        }

        return try {
            withTimeoutOrNull(REFRESH_TIMEOUT_MS) { deferred.await() } ?: fallbackToken()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, "refreshAccessToken failed", e)
            fallbackToken()
        } finally {
            refreshMutex.withLock {
                if (refreshDeferred === deferred) {
                    refreshDeferred = null
                }
            }
        }
    }

    private fun fallbackToken(): String? {
        applyCachedTokenFallback()
        return storedSession?.accessToken
    }

    private suspend fun awaitInFlightRefresh() {
        val active = refreshMutex.withLock { refreshDeferred?.takeIf { it.isActive } } ?: return
        withTimeoutOrNull(REFRESH_TIMEOUT_MS) { active.await() }
    }

    fun signOut() {
        val refresh = storedSession?.refreshToken
        proactiveRefreshJob?.cancel()
        clearSessionState()
        cancelRefreshJob()
        _bootstrapReady.value = true
        if (!refresh.isNullOrBlank()) {
            scope.launch(Dispatchers.IO) {
                runCatching { authHttp.logout(refresh) }
            }
        }
    }

    private fun signOutFromRefresh() {
        val refresh = storedSession?.refreshToken
        proactiveRefreshJob?.cancel()
        clearSessionState()
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

    private suspend fun performRefresh(force: Boolean): String? = withContext(Dispatchers.IO) {
        val session = storedSession ?: return@withContext null
        if (!JwtHelpers.isRefreshTokenValid(session)) {
            signOutFromRefresh()
            return@withContext null
        }
        if (!force && !JwtHelpers.shouldRefreshAccess(session) && !JwtHelpers.isExpired(session.accessToken)) {
            _accessToken.value = session.accessToken
            return@withContext session.accessToken
        }
        try {
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
            signOutFromRefresh()
            null
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, "performRefresh network error", e)
            if (!JwtHelpers.isExpired(session.accessToken)) {
                _accessToken.value = session.accessToken
                session.accessToken
            } else {
                null
            }
        }
    }

    private fun cancelRefreshJob() {
        refreshDeferred?.cancel()
        refreshDeferred = null
    }

    private fun clearSessionState() {
        storedSession = null
        _accessToken.value = null
        _user.value = null
        _isAuthenticated.value = false
        sessionStore.clear()
    }

    private fun persist(session: StoredAuthSession) {
        storedSession = session
        _accessToken.value = session.accessToken
        _isAuthenticated.value = JwtHelpers.isRefreshTokenValid(session)
        sessionStore.save(session)
    }

    companion object {
        private const val TAG = "SessionManager"
        private const val REFRESH_TIMEOUT_MS = 12_000L
        private const val BOOTSTRAP_UI_TIMEOUT_MS = 15_000L
    }
}
