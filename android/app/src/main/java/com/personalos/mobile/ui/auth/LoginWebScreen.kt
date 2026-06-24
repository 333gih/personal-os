package com.personalos.mobile.ui.auth

import android.annotation.SuppressLint
import android.webkit.CookieManager
import android.webkit.JavascriptInterface
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import com.personalos.mobile.config.AppEnvironment
import com.personalos.mobile.data.auth.MobileAuthHandoff
import com.personalos.mobile.data.auth.SessionManager
import com.squareup.moshi.Moshi

@SuppressLint("SetJavaScriptEnabled")
@Composable
fun LoginWebScreen(sessionManager: SessionManager, moshi: Moshi, onError: (String) -> Unit) {
    val handoffAdapter = moshi.adapter(MobileAuthHandoff::class.java)
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
                    override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean = false

                    override fun onPageFinished(view: WebView?, url: String?) {
                        super.onPageFinished(view, url)
                        val path = url.orEmpty()
                        if (path.contains("/dashboard") || path.contains("/inbox") ||
                            path.endsWith("/") && !path.contains("/login")
                        ) {
                            evaluateJavascript(HANDOFF_SCRIPT, null)
                        }
                    }
                }
                loadUrl(AppEnvironment.loginUrl())
            }
        },
    )
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
