package com.personalos.mobile.data.auth

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class StoredAuthSession(
    @Json(name = "access_token") val accessToken: String,
    @Json(name = "refresh_token") val refreshToken: String,
    @Json(name = "expires_at_ms") val expiresAtMs: Long,
    @Json(name = "refresh_expires_at_ms") val refreshExpiresAtMs: Long,
    @Json(name = "application_id") val applicationId: String? = null,
)

@JsonClass(generateAdapter = true)
data class MobileAuthHandoff(
    @Json(name = "access_token") val accessToken: String,
    @Json(name = "refresh_token") val refreshToken: String,
    @Json(name = "token_type") val tokenType: String = "bearer",
    @Json(name = "expires_in") val expiresIn: Int,
    @Json(name = "refresh_expires_in") val refreshExpiresIn: Int,
    val mode: String? = null,
    @Json(name = "application_id") val applicationId: String? = null,
)

@JsonClass(generateAdapter = true)
data class MobileTokenRefreshResponse(
    @Json(name = "access_token") val accessToken: String,
    @Json(name = "refresh_token") val refreshToken: String,
    @Json(name = "token_type") val tokenType: String = "bearer",
    @Json(name = "expires_in") val expiresIn: Int,
    @Json(name = "refresh_expires_in") val refreshExpiresIn: Int,
)

@JsonClass(generateAdapter = true)
data class RefreshTokenBody(
    @Json(name = "refresh_token") val refreshToken: String,
)

@JsonClass(generateAdapter = true)
data class LogoutTokenBody(
    @Json(name = "refresh_token") val refreshToken: String,
)
