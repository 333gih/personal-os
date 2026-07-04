package com.personalos.mobile.data.models

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class PosModulesResponse(
    val catalog: List<PosModuleCatalogEntry> = emptyList(),
    val prefs: List<PosModulePref> = emptyList(),
    val nav: PosNavManifest = PosNavManifest(),
    val rules: PosModuleRules = PosModuleRules(),
)

@JsonClass(generateAdapter = true)
data class PosModuleCatalogEntry(
    val id: String,
    val label: String,
    val description: String,
    val icon: String,
    val tier: String,
    val domain: String? = null,
    @Json(name = "default_enabled") val defaultEnabled: Boolean = true,
    val required: Boolean = false,
    @Json(name = "depends_on") val dependsOn: List<String>? = null,
    @Json(name = "nav_href") val navHref: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosModulePref(
    @Json(name = "module_id") val moduleId: String,
    val enabled: Boolean,
    @Json(name = "pin_order") val pinOrder: Int? = null,
)

@JsonClass(generateAdapter = true)
data class PosNavManifest(
    val tabs: List<String> = listOf("dashboard", "work", "learning", "search"),
    val drawer: List<String> = emptyList(),
)

@JsonClass(generateAdapter = true)
data class PosModuleRules(
    val required: List<String> = emptyList(),
    @Json(name = "min_enabled_domains") val minEnabledDomains: Int = 1,
    @Json(name = "max_enabled_domains") val maxEnabledDomains: Int = 6,
    @Json(name = "max_pinned_tabs") val maxPinnedTabs: Int = 3,
)

@JsonClass(generateAdapter = true)
data class PosModuleUpdateRequest(
    val prefs: List<PosModuleUpdatePref>,
)

@JsonClass(generateAdapter = true)
data class PosModuleUpdatePref(
    @Json(name = "module_id") val moduleId: String,
    val enabled: Boolean? = null,
    @Json(name = "pin_order") val pinOrder: Int? = null,
)

enum class PosNavTab(val id: String, val title: String) {
    DASHBOARD("dashboard", "Home"),
    WORK("work", "Work"),
    LEARNING("learning", "Learning"),
    SEARCH("search", "Search"),
    MORE("more", "More"),
    STARTUP("startup", "Startup"),
    ENTERTAINMENT("entertainment", "Reading"),
    GOALS("goals", "Goals"),
    INBOX("inbox", "Inbox"),
    ;

    companion object {
        fun from(id: String): PosNavTab? = entries.find { it.id == id }
    }
}
