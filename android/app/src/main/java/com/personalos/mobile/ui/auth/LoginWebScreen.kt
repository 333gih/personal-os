package com.personalos.mobile.ui.auth

import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.webkit.CookieManager
import android.webkit.JavascriptInterface
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.key
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.personalos.mobile.config.AppEnvironment
import com.personalos.mobile.data.auth.MobileAuthHandoff
import com.personalos.mobile.data.auth.SessionManager
import com.personalos.mobile.ui.components.PosEmptyState
import com.personalos.mobile.ui.components.PosLoadingView
import com.personalos.mobile.ui.components.PosScreen
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay
import com.personalos.mobile.ui.theme.posLabel
import com.squareup.moshi.Moshi

@SuppressLint("SetJavaScriptEnabled")
@Composable
fun LoginWebScreen(sessionManager: SessionManager, moshi: Moshi, onError: (String) -> Unit) {
    val handoffAdapter = moshi.adapter(MobileAuthHandoff::class.java)
    val loginUrl = remember { AppEnvironment.loginUrl() }
    var loading by remember { mutableStateOf(true) }
    var loadError by remember { mutableStateOf<String?>(null) }
    var reloadKey by remember { mutableIntStateOf(0) }

    PosScreen {
        Box(Modifier.fillMaxSize()) {
            if (loadError != null) {
                Column(
                    Modifier
                        .fillMaxSize()
                        .padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    PosEmptyState(
                        title = "Could not reach login",
                        message = buildString {
                            append(loadError)
                            append("\n\n")
                            append(loginUrl)
                            append("\n\n")
                            append(
                                "If you run the frontend locally, set in android/local.properties:\n" +
                                    "PERSONAL_OS_FE_URL=http://10.0.2.2:3000/dashboard\n" +
                                    "then rebuild devDebug.",
                            )
                        },
                        actionTitle = "Retry",
                        onAction = {
                            loadError = null
                            loading = true
                            reloadKey++
                        },
                    )
                }
            } else {
                key(reloadKey) {
                    AndroidView(
                        modifier = Modifier.fillMaxSize(),
                        factory = { context ->
                        CookieManager.getInstance().setAcceptCookie(true)
                        WebView(context).apply {
                            settings.javaScriptEnabled = true
                            settings.domStorageEnabled = true
                            settings.userAgentString = settings.userAgentString + " PersonalOS-Android/1.0"
                            CookieManager.getInstance().setAcceptThirdPartyCookies(this, true)
                            addJavascriptInterface(
                                object {
                                    @JavascriptInterface
                                    fun onHandoff(json: String) {
                                        if (json.isBlank()) {
                                            post { onError("Login handoff failed") }
                                            return
                                        }
                                        runCatching { handoffAdapter.fromJson(json) }
                                            .onSuccess { handoff ->
                                                handoff?.let { post { sessionManager.saveHandoff(it) } }
                                            }
                                            .onFailure { post { onError("Invalid handoff response") } }
                                    }
                                },
                                "PosAuthBridge",
                            )
                            webViewClient = object : WebViewClient() {
                                override fun shouldOverrideUrlLoading(
                                    view: WebView?,
                                    request: WebResourceRequest?,
                                ): Boolean = false

                                override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                                    loading = true
                                }

                                override fun onPageFinished(view: WebView?, url: String?) {
                                    super.onPageFinished(view, url)
                                    loading = false
                                    val path = url.orEmpty()
                                    if (path.contains("/dashboard") || path.contains("/inbox") ||
                                        path.endsWith("/") && !path.contains("/login")
                                    ) {
                                        evaluateJavascript(HANDOFF_SCRIPT, null)
                                    }
                                }

                                override fun onReceivedError(
                                    view: WebView?,
                                    request: WebResourceRequest?,
                                    error: WebResourceError?,
                                ) {
                                    if (request?.isForMainFrame != true) return
                                    loading = false
                                    val code = error?.errorCode ?: -1
                                    val detail = error?.description?.toString().orEmpty()
                                    loadError = when {
                                        detail.contains("ERR_NAME_NOT_RESOLVED", true) ->
                                            "DNS could not resolve the server (ERR_NAME_NOT_RESOLVED). Check emulator internet or use a local frontend URL."
                                        detail.contains("ERR_CONNECTION_REFUSED", true) ->
                                            "Connection refused — is the frontend running on your machine?"
                                        detail.isNotBlank() -> detail
                                        else -> "Network error ($code)"
                                    }
                                }
                            }
                            loadUrl(loginUrl)
                        }
                    },
                    )
                }
            }
            if (loading && loadError == null) {
                Column(
                    Modifier
                        .fillMaxSize()
                        .padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text("Personal OS", style = posDisplay(24f), modifier = Modifier.padding(bottom = 16.dp))
                    PosLoadingView("Signing in…")
                    Text("Secure web login", color = PosTheme.Muted, modifier = Modifier.padding(top = 8.dp))
                    Text(loginUrl, color = PosTheme.Muted, style = posLabel(), textAlign = TextAlign.Center, modifier = Modifier.padding(top = 12.dp))
                }
            }
        }
    }
}

private const val HANDOFF_SCRIPT = """
fetch('/api/auth/mobile/handoff', { credentials: 'include' })
  .then(r => r.json())
  .then(d => {
    if (!d.access_token || !d.refresh_token) {
      PosAuthBridge.onHandoff('');
      return;
    }
    PosAuthBridge.onHandoff(JSON.stringify(d));
  })
  .catch(() => PosAuthBridge.onHandoff(''));
"""
