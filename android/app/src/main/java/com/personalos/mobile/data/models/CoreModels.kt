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
    @Json(name = "work_hours") val workHours: String? = null,
    @Json(name = "cv_status") val cvStatus: String? = null,
    val image: String? = null,
    @Json(name = "design_images") val designImages: List<String>? = null,
    val level: String? = null,
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
data class PosEntityListResponse(
    val items: List<PosEntity> = emptyList(),
    val total: Int = 0,
)

@JsonClass(generateAdapter = true)
data class PosReminder(
    val id: String,
    @Json(name = "entity_id") val entityId: String? = null,
    val title: String,
    @Json(name = "due_at") val dueAt: String? = null,
    val status: String = "",
)

@JsonClass(generateAdapter = true)
data class PosDashboard(
    @Json(name = "inbox_count") val inboxCount: Int = 0,
    @Json(name = "domain_counts") val domainCounts: Map<String, Int> = emptyMap(),
    val recent: List<PosEntity> = emptyList(),
    @Json(name = "upcoming_reminders") val upcomingReminders: List<PosReminder> = emptyList(),
)

@JsonClass(generateAdapter = true)
data class PosSearchHit(
    val entity: PosEntity,
    val score: Double = 0.0,
    @Json(name = "match_type") val matchType: String = "",
) {
    val id: String get() = entity.id
    val title: String get() = entity.title
    val snippet: String get() = entity.content.take(160)
    val domain: String get() = entity.domain
}

@JsonClass(generateAdapter = true)
data class PosSearchResponse(val results: List<PosSearchHit> = emptyList())

@JsonClass(generateAdapter = true)
data class PosRelationWithEntity(
    val id: String,
    @Json(name = "relation_type") val relationType: String = "",
    val direction: String = "",
    @Json(name = "related_entity") val relatedEntity: PosEntity,
) {
    val linkedId: String get() = relatedEntity.id
    val linkedTitle: String get() = relatedEntity.title
    val linkedDomain: String get() = relatedEntity.domain
    val subtitle: String get() = listOf(relationType.replace('_', ' '), direction)
        .filter { it.isNotBlank() }
        .joinToString(" · ")
}

@JsonClass(generateAdapter = true)
data class PosEntityDetailResponse(
    val entity: PosEntity,
    val relations: List<PosRelationWithEntity> = emptyList(),
)

enum class PosTab(val title: String) {
    HOME("Home"),
    WORK("Work"),
    LEARNING("Learning"),
    SEARCH("Search"),
    MORE("More"),
    ;

    val headerTitle: String
        get() = when (this) {
            HOME -> "Personal OS"
            WORK -> "Career Path"
            LEARNING -> "Personal OS"
            SEARCH -> "Personal OS"
            MORE -> "More"
        }
}

enum class PosLearningTrack(val apiValue: String, val label: String) {
    DSA("dsa", "DSA"),
    ENGLISH("english", "English"),
}

enum class PosEntitySection { OVERVIEW, ARCHITECTURE, RELATED }

enum class PosJobTab { OPEN, APPLIED }
