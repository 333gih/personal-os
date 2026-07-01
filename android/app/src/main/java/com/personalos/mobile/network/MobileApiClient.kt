package com.personalos.mobile.network

import com.personalos.mobile.config.AppEnvironment
import com.personalos.mobile.data.auth.SessionManager
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.runBlocking
import okhttp3.Interceptor
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import java.util.concurrent.TimeUnit

class MobileApiClient(
    private val sessionManager: SessionManager,
) {
    private val jsonMedia = "application/json".toMediaType()

    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(120, TimeUnit.SECONDS)
        .writeTimeout(120, TimeUnit.SECONDS)
        .addInterceptor(AuthInterceptor())
        .addInterceptor(RefreshRetryInterceptor())
        .build()

    fun get(path: String): ApiResponse = execute("GET", path, null, null)

    fun post(path: String, json: String): ApiResponse = execute("POST", path, json.toRequestBody(jsonMedia), jsonMedia.toString())

    fun put(path: String, json: String): ApiResponse = execute("PUT", path, json.toRequestBody(jsonMedia), jsonMedia.toString())

    fun patch(path: String, json: String): ApiResponse = execute("PATCH", path, json.toRequestBody(jsonMedia), jsonMedia.toString())

    fun postMultipart(path: String, body: RequestBody, contentType: String): ApiResponse =
        execute("POST", path, body, contentType)

    fun getBytes(path: String): ByteArray {
        val response = authorizedCall("GET", path, null, null)
        response.body?.use { return it.bytes() }
        error("Empty body")
    }

    private fun execute(method: String, path: String, body: RequestBody?, contentType: String?): ApiResponse {
        val response = authorizedCall(method, path, body, contentType)
        val bytes = response.body?.bytes() ?: ByteArray(0)
        val message = bytes.toString(Charsets.UTF_8)
        return ApiResponse(response.code, message, bytes)
    }

    private fun authorizedCall(
        method: String,
        path: String,
        body: RequestBody?,
        contentType: String?,
        retried: Boolean = false,
    ): Response {
        val token = blockingAccessToken() ?: throw ApiException.Unauthorized
        val request = buildRequest(method, path, body, contentType, token)
        val response = client.newCall(request).execute()
        if (response.code != 401 || retried) return response
        response.close()
        val refreshed = blockingRefreshToken(force = true) ?: throw ApiException.Unauthorized
        val retry = buildRequest(method, path, body, contentType, refreshed)
        val retryResponse = client.newCall(retry).execute()
        if (retryResponse.code == 401) {
            sessionManager.signOut()
            throw ApiException.Unauthorized
        }
        return retryResponse
    }

    private fun buildRequest(
        method: String,
        path: String,
        body: RequestBody?,
        contentType: String?,
        token: String,
    ): Request {
        val normalized = path.trimStart('/')
        val url = "${AppEnvironment.mobileApiBaseUrl.trimEnd('/')}/$normalized"
        val builder = Request.Builder()
            .url(url)
            .header("Authorization", "Bearer $token")
            .header("Accept", "application/json")
            .header("User-Agent", AppEnvironment.httpUserAgent)
        if (contentType != null) builder.header("Content-Type", contentType)
        when (method) {
            "GET" -> builder.get()
            "POST" -> builder.post(body ?: "".toRequestBody(jsonMedia))
            "PUT" -> builder.put(body ?: "".toRequestBody(jsonMedia))
            "PATCH" -> builder.patch(body ?: "".toRequestBody(jsonMedia))
            else -> builder.method(method, body)
        }
        return builder.build()
    }

    private fun blockingAccessToken(): String? = runBlocking {
        try {
            sessionManager.validAccessToken()
        } catch (_: CancellationException) {
            null
        }
    }

    private fun blockingRefreshToken(force: Boolean): String? = runBlocking {
        try {
            sessionManager.refreshAccessToken(force)
        } catch (_: CancellationException) {
            null
        }
    }

    private inner class AuthInterceptor : Interceptor {
        override fun intercept(chain: Interceptor.Chain): Response = chain.proceed(chain.request())
    }

    private inner class RefreshRetryInterceptor : Interceptor {
        override fun intercept(chain: Interceptor.Chain): Response = chain.proceed(chain.request())
    }

    data class ApiResponse(val status: Int, val message: String, val data: ByteArray)

    sealed class ApiException : Exception() {
        data object Unauthorized : ApiException()
        data class Http(val code: Int, override val message: String) : ApiException()
    }
}
