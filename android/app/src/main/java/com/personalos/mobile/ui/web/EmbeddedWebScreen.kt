package com.personalos.mobile.ui.web

import android.annotation.SuppressLint
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.personalos.mobile.ui.components.PosScreen
import com.personalos.mobile.ui.navigation.WebRoute
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay

@SuppressLint("SetJavaScriptEnabled")
@Composable
fun EmbeddedWebScreen(route: WebRoute) {
    var loading by remember(route.finalUrl) { mutableStateOf(true) }

    PosScreen {
        Column(Modifier.fillMaxSize()) {
            if (loading) {
                LinearProgressIndicator(Modifier.fillMaxWidth(), color = PosTheme.PrimaryDark)
            }
            Text(route.title, style = posDisplay(14f), modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp))
            Box(Modifier.weight(1f)) {
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
                                    loading = false
                                    evaluateJavascript(inject, null)
                                }
                            }
                            loadUrl(route.finalUrl)
                        }
                    },
                    update = { it.loadUrl(route.finalUrl) },
                )
            }
        }
    }
}
