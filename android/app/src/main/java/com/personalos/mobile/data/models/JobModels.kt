package com.personalos.mobile.data.models

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class PosJobOpportunity(
    val id: String,
    val title: String,
    val company: String? = null,
    val location: String? = null,
    val url: String = "",
    val status: String = "open",
    @Json(name = "match_score") val matchScore: Float = 0f,
    @Json(name = "match_reason") val matchReason: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosJobListResponse(val jobs: List<PosJobOpportunity> = emptyList())

@JsonClass(generateAdapter = true)
data class PosJobStatusRequest(val status: String)

@JsonClass(generateAdapter = true)
data class PosJobScanSources(
    val remotive: Int = 0,
    val remoteok: Int = 0,
    val github: Int = 0,
    val itviec: Int = 0,
    val topcv: Int = 0,
)

@JsonClass(generateAdapter = true)
data class PosJobScanResult(
    val found: Int = 0,
    val matched: Int = 0,
    val stored: Int = 0,
    val updated: Int = 0,
    @Json(name = "min_score") val minScore: Float? = null,
    val sources: PosJobScanSources? = null,
)

@JsonClass(generateAdapter = true)
data class PosJobScanStatusResponse(
    val status: String,
    val result: PosJobScanResult? = null,
    val error: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosJobSearchPreferences(
    @Json(name = "focus_skills") val focusSkills: List<String> = listOf("Java", "Spring Boot"),
    @Json(name = "years_experience") val yearsExperience: Float = 3.5f,
    @Json(name = "target_role") val targetRole: String = "Software Engineer",
    @Json(name = "work_location_types") val workLocationTypes: List<String> = listOf("remote", "hybrid"),
    @Json(name = "employment_types") val employmentTypes: List<String> = listOf("full_time"),
    @Json(name = "daily_scan_enabled") val dailyScanEnabled: Boolean = true,
    @Json(name = "push_enabled") val pushEnabled: Boolean = true,
    val timezone: String = "Asia/Ho_Chi_Minh",
    @Json(name = "last_scan_at") val lastScanAt: String? = null,
    @Json(name = "available_skills") val availableSkills: List<String>? = null,
)

fun PosJobScanResult.summaryText(): String {
    val pct = ((minScore ?: 0.35f) * 100).toInt()
    val base = "Scanned $found · $matched matched ≥$pct% · $stored new"
    val vn = sources?.let { s ->
        buildList {
            if (s.itviec > 0) add("ITviec ${s.itviec}")
            if (s.topcv > 0) add("TopCV ${s.topcv}")
        }.takeIf { it.isNotEmpty() }?.joinToString(" · ")
    }
    return if (vn != null) "$base ($vn)" else base
}

@JsonClass(generateAdapter = true)
data class PosWorkAddResult(
    @Json(name = "entity_id") val entityId: String,
    val type: String,
    val title: String,
    val content: String = "",
)

@JsonClass(generateAdapter = true)
data class PosStartupAddResult(
    @Json(name = "entity_id") val entityId: String,
    val type: String,
    val title: String,
    val content: String = "",
)

@JsonClass(generateAdapter = true)
data class PosWorkImportResult(
    @Json(name = "entity_id") val entityId: String,
    val title: String,
)
