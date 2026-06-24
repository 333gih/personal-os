package com.personalos.mobile.util

import android.util.Base64
import org.json.JSONObject

object JwtHelpers {
    private const val SKEW_SECONDS = 45L
    private const val ACCESS_REFRESH_LEAD_MS = 5 * 60 * 1000L
    private const val REFRESH_SKEW_MS = 60 * 1000L

    fun expirationMs(token: String): Long? {
        val payload = decodePayload(token) ?: return null
        val exp = payload.optLong("exp", 0L)
        return if (exp > 0) exp * 1000L else null
    }

    fun isExpired(token: String, skewSeconds: Long = SKEW_SECONDS): Boolean {
        val expMs = expirationMs(token) ?: return true
        return System.currentTimeMillis() + skewSeconds * 1000L >= expMs
    }

    fun shouldRefreshAccess(session: com.personalos.mobile.data.auth.StoredAuthSession): Boolean {
        val now = System.currentTimeMillis()
        return now + ACCESS_REFRESH_LEAD_MS >= session.expiresAtMs || isExpired(session.accessToken)
    }

    fun isRefreshTokenValid(session: com.personalos.mobile.data.auth.StoredAuthSession): Boolean {
        return System.currentTimeMillis() + REFRESH_SKEW_MS < session.refreshExpiresAtMs
    }

    fun sessionExpiry(
        accessToken: String,
        refreshToken: String,
        expiresIn: Int,
        refreshExpiresIn: Int,
    ): Pair<Long, Long> {
        val now = System.currentTimeMillis()
        var accessExpiry = now + maxOf(60, expiresIn) * 1000L
        expirationMs(accessToken)?.let { accessExpiry = it }

        val refreshSeconds = maxOf(300, refreshExpiresIn)
        var refreshExpiry = now + refreshSeconds * 1000L
        expirationMs(refreshToken)?.let { refreshExpiry = it }
        if (refreshExpiry <= now) {
            refreshExpiry = now + 7L * 24 * 3600 * 1000
        }
        return accessExpiry to refreshExpiry
    }

    private fun decodePayload(token: String): JSONObject? {
        val parts = token.split('.')
        if (parts.size < 2) return null
        return try {
            val decoded = Base64.decode(parts[1], Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)
            JSONObject(String(decoded, Charsets.UTF_8))
        } catch (_: Exception) {
            null
        }
    }
}
