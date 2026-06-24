# Auth and security
-keep class com.personalos.mobile.data.auth.** { *; }
-keep class com.personalos.mobile.network.** { *; }

# Moshi models
-keep class com.personalos.mobile.data.models.** { *; }
-keepclassmembers class com.personalos.mobile.data.models.** { *; }

# EncryptedSharedPreferences / Tink
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**
-dontwarn com.google.errorprone.annotations.**

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**

# WebView JS bridge
-keepclassmembers class com.personalos.mobile.ui.auth.LoginWebScreen$PosAuthBridge {
    @android.webkit.JavascriptInterface <methods>;
}
