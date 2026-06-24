package com.personalos.mobile.ui.web

import android.annotation.SuppressLint
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import com.personalos.mobile.ui.navigation.WebRoute

@SuppressLint("SetJavaScriptEnabled")
@Composable
fun EmbeddedWebScreen(route: WebRoute) {
    AndroidView(
        modifier = Modifier.fillMaxSize(),
        factory = { context ->
            WebView(context).apply {
                settings.javaScriptEnabled = true
                settings.domStorageEnabled = true
                settings.userAgentString = settings.userAgentString + " PersonalOS-Android/1.0"
                val inject = """
                    window.__PERSONAL_OS_ANDROID_APP__=true;
                    document.documentElement.classList.add('personal-os-android');
                    window.__PERSONAL_OS_ANDROID_EMBED__=true;
                    document.documentElement.classList.add('personal-os-android-embed');
                """.trimIndent()
                webViewClient = object : WebViewClient() {
                    override fun onPageFinished(view: WebView?, url: String?) {
                        super.onPageFinished(view, url)
                        evaluateJavascript(inject, null)
                    }
                }
                loadUrl(route.finalUrl)
            }
        },
        update = { it.loadUrl(route.finalUrl) },
    )
}
