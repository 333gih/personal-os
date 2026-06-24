package com.personalos.mobile.config

import android.net.Uri
import com.personalos.mobile.BuildConfig

object AppEnvironment {
    val environmentName: String get() = BuildConfig.ENVIRONMENT_NAME
    val httpUserAgent: String get() = BuildConfig.HTTP_USER_AGENT

    private val frontendUri: Uri by lazy { Uri.parse(BuildConfig.PERSONAL_OS_FE_URL.trim()) }

    val frontendOrigin: String
        get() {
            val scheme = frontendUri.scheme ?: "https"
            val host = frontendUri.host ?: return BuildConfig.PERSONAL_OS_FE_URL
            val port = frontendUri.port
            return if (port != -1 && port != 80 && port != 443) {
                "$scheme://$host:$port"
            } else {
                "$scheme://$host"
            }
        }

    val mobileApiBaseUrl: String get() = "$frontendOrigin/api/mobile/v1"

    fun frontendUrl(path: String): String {
        val base = frontendOrigin.trimEnd('/')
        val normalized = if (path.startsWith("/")) path else "/$path"
        return base + normalized
    }

    fun authMobileRefreshUrl(): String = frontendUrl("/api/auth/mobile/refresh")
    fun authMobileLogoutUrl(): String = frontendUrl("/api/auth/mobile/logout")
    fun authMobileHandoffUrl(): String = frontendUrl("/api/auth/mobile/handoff")
    fun loginUrl(): String = frontendUrl("/login")

    val fashAuthBaseUrl: String get() = BuildConfig.FASH_AUTH_BASE_URL.trimEnd('/')
    val fashFcmRegisterUrl: String
        get() {
            val path = BuildConfig.FASH_AUTH_FCM_REGISTER_PATH.trim().trimStart('/')
            return "$fashAuthBaseUrl/$path"
        }
}
