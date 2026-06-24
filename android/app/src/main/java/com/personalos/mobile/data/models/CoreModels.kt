package com.personalos.mobile.data.models

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class PosUser(
    val id: String,
    val email: String,
    val name: String,
)

@JsonClass(generateAdapter = true)
data class PosArchitectureLayer(
    val layer: String,
    val nodes: List<String> = emptyList(),
)

@JsonClass(generateAdapter = true)
data class PosWorkMetadata(
    val kind: String? = null,
    val company: String? = null,
    val role: String? = null,
    @Json(name = "start_date") val startDate: String? = null,
    @Json(name = "end_date") val endDate: String? = null,
    val status: String? = null,
    val location: String? = null,
    val track: String? = null,
    val phase: String? = null,
    @Json(name = "architecture_layers") val architectureLayers: List<PosArchitectureLayer>? = null,
    @Json(name = "pattern_order") val patternOrder: Int? = null,
    @Json(name = "pattern_slug") val patternSlug: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosEntity(
    val id: String,
    val type: String,
    val title: String,
    val content: String = "",
    val status: String = "active",
    val domain: String = "work",
    @Json(name = "created_at") val createdAt: String = "",
    @Json(name = "updated_at") val updatedAt: String = "",
    val tags: List<String>? = null,
    val metadata: PosWorkMetadata? = null,
) {
    val tagList: List<String> get() = tags ?: emptyList()
    val isActiveWork: Boolean
        get() = metadata?.status == "active" || (metadata?.status == null && status == "active")
}

@JsonClass(generateAdapter = true)
data class PosEntityListResponse(val entities: List<PosEntity> = emptyList())

@JsonClass(generateAdapter = true)
data class PosReminder(
    val id: String,
    val title: String,
    val due: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosDashboard(
    @Json(name = "inbox_count") val inboxCount: Int = 0,
    @Json(name = "domain_counts") val domainCounts: Map<String, Int> = emptyMap(),
    val reminders: List<PosReminder> = emptyList(),
    @Json(name = "recent_entities") val recentEntities: List<PosEntity> = emptyList(),
)

@JsonClass(generateAdapter = true)
data class PosSearchHit(
    val id: String,
    val title: String,
    val domain: String = "",
    val snippet: String = "",
    val score: Double? = null,
)

@JsonClass(generateAdapter = true)
data class PosSearchResponse(val hits: List<PosSearchHit> = emptyList())

@JsonClass(generateAdapter = true)
data class PosRelationItem(
    val id: String,
    val title: String,
    val type: String = "",
    val domain: String = "",
)

@JsonClass(generateAdapter = true)
data class PosEntityDetailResponse(
    val entity: PosEntity,
    val relations: List<PosRelationItem> = emptyList(),
)

enum class PosTab(val title: String) {
    HOME("Home"),
    WORK("Work"),
    LEARNING("Learning"),
    SEARCH("Search"),
    MORE("More"),
}

enum class PosLearningTrack(val apiValue: String, val label: String) {
    DSA("dsa", "DSA"),
    ENGLISH("english", "English"),
}

enum class PosEntitySection { OVERVIEW, ARCHITECTURE, RELATED }

enum class PosJobTab { OPEN, APPLIED }
