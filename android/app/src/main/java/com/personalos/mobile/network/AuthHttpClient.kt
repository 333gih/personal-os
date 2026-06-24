package com.personalos.mobile.network

import com.personalos.mobile.config.AppEnvironment
import com.personalos.mobile.data.auth.LogoutTokenBody
import com.personalos.mobile.data.auth.MobileTokenRefreshResponse
import com.personalos.mobile.data.auth.RefreshTokenBody
import com.squareup.moshi.Moshi
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.concurrent.TimeUnit

class AuthHttpClient(moshi: Moshi) {
    private val refreshAdapter = moshi.adapter(MobileTokenRefreshResponse::class.java)
    private val refreshBodyAdapter = moshi.adapter(RefreshTokenBody::class.java)
    private val logoutBodyAdapter = moshi.adapter(LogoutTokenBody::class.java)

    private val client = OkHttpClient.Builder()
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(20, TimeUnit.SECONDS)
        .writeTimeout(20, TimeUnit.SECONDS)
        .build()

    @Throws(UnauthorizedException::class)
    fun refresh(refreshToken: String): MobileTokenRefreshResponse {
        val body = refreshBodyAdapter.toJson(RefreshTokenBody(refreshToken))
            .toRequestBody(JSON)
        val request = Request.Builder()
            .url(AppEnvironment.authMobileRefreshUrl())
            .post(body)
            .header("Accept", "application/json")
            .header("Content-Type", "application/json")
            .header("User-Agent", AppEnvironment.httpUserAgent)
            .build()
        client.newCall(request).execute().use { response ->
            if (response.code == 401 || response.code == 403) throw UnauthorizedException()
            if (!response.isSuccessful) {
                throw HttpException(response.code, response.body?.string().orEmpty())
            }
            val raw = response.body?.string().orEmpty()
            return refreshAdapter.fromJson(raw)
                ?: throw HttpException(response.code, "Invalid refresh response")
        }
    }

    fun logout(refreshToken: String) {
        val body = logoutBodyAdapter.toJson(LogoutTokenBody(refreshToken))
            .toRequestBody(JSON)
        val request = Request.Builder()
            .url(AppEnvironment.authMobileLogoutUrl())
            .post(body)
            .header("Accept", "application/json")
            .header("Content-Type", "application/json")
            .header("User-Agent", AppEnvironment.httpUserAgent)
            .build()
        client.newCall(request).execute().close()
    }

    class UnauthorizedException : Exception()
    class HttpException(val code: Int, message: String) : Exception(message)

    companion object {
        private val JSON = "application/json".toMediaType()
    }
}
