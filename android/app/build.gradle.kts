import com.android.build.api.dsl.ApplicationProductFlavor
import java.io.File
import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
}

fun loadEnvFile(envFile: File): Map<String, String> {
    if (!envFile.exists()) {
        error("Missing env file: ${envFile.absolutePath}\nAdd env/dev.env and env/prod.env at android/ root.")
    }
    return envFile.readLines()
        .map { it.trim() }
        .filter { it.isNotEmpty() && !it.startsWith("#") }
        .associate { line ->
            val eq = line.indexOf('=')
            require(eq > 0) { "Invalid env line (expected KEY=value): $line" }
            line.substring(0, eq).trim() to line.substring(eq + 1).trim()
        }
}

fun buildConfigStringLiteral(raw: String): String =
    "\"${raw.replace("\\", "\\\\").replace("\"", "\\\"")}\""

fun org.gradle.api.Project.prop(key: String): String? {
    (findProperty(key) as String?)?.trim()?.takeIf { it.isNotEmpty() }?.let { return it }
    val lp = rootProject.file("local.properties")
    if (!lp.exists()) return null
    val p = Properties()
    lp.inputStream().use { p.load(it) }
    return p.getProperty(key)?.trim()?.takeIf { it.isNotEmpty() }
}

val releaseKeystoreFile: File? =
    project.prop("POS_RELEASE_STORE_FILE")
        ?.let { rootProject.file(it) }
        ?.takeIf { it.isFile }

fun ApplicationProductFlavor.injectFromEnv(env: Map<String, String>, flavorName: String) {
    fun envVal(key: String): String =
        project.prop(key)?.trim()?.takeIf { it.isNotEmpty() }
            ?: env[key]?.trim()?.takeIf { it.isNotEmpty() }
            ?: error("$key is required in env for flavor '$flavorName' (optional override: android/local.properties)")

    buildConfigField("String", "ENVIRONMENT_NAME", buildConfigStringLiteral(envVal("ENVIRONMENT_NAME")))
    buildConfigField("String", "PERSONAL_OS_FE_URL", buildConfigStringLiteral(envVal("PERSONAL_OS_FE_URL")))
    buildConfigField("String", "FASH_AUTH_BASE_URL", buildConfigStringLiteral(envVal("FASH_AUTH_BASE_URL")))
    buildConfigField(
        "String",
        "FASH_AUTH_FCM_REGISTER_PATH",
        buildConfigStringLiteral(envVal("FASH_AUTH_FCM_REGISTER_PATH")),
    )
}

android {
    namespace = "com.personalos.mobile"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.personalos.mobile"
        minSdk = 26
        targetSdk = 35
        versionCode = 19
        versionName = "1.0.18"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        buildConfigField("String", "HTTP_USER_AGENT", buildConfigStringLiteral("PersonalOS-Android/1.0"))
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    flavorDimensions += "environment"
    val devEnv = loadEnvFile(rootProject.file("env/dev.env"))
    val prodEnv = loadEnvFile(rootProject.file("env/prod.env"))

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            injectFromEnv(devEnv, "dev")
        }
        create("prod") {
            dimension = "environment"
            injectFromEnv(prodEnv, "prod")
        }
    }

    signingConfigs {
        if (releaseKeystoreFile != null) {
            create("release") {
                storeFile = releaseKeystoreFile
                storePassword = project.prop("POS_RELEASE_STORE_PASSWORD").orEmpty()
                keyAlias = project.prop("POS_RELEASE_KEY_ALIAS") ?: "upload"
                keyPassword = project.prop("POS_RELEASE_KEY_PASSWORD").orEmpty()
            }
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            ndk {
                debugSymbolLevel = "FULL"
            }
            signingConfig = if (releaseKeystoreFile != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.material.icons.extended)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.lifecycle.viewmodel.ktx)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.okhttp)
    implementation(libs.okhttp.logging)
    implementation(libs.moshi)
    implementation(libs.moshi.kotlin)
    implementation(libs.androidx.security.crypto)
    implementation(libs.androidx.browser)
    implementation(libs.kotlinx.coroutines.android)
    debugImplementation(libs.androidx.compose.ui.tooling)
    debugImplementation(libs.androidx.compose.ui.test.manifest)
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
}
