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
data class PosJobScanResult(
    val found: Int = 0,
    val matched: Int = 0,
    val stored: Int = 0,
    val updated: Int = 0,
    @Json(name = "min_score") val minScore: Float? = null,
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
    @Json(name = "available_skills") val availableSkills: List<String>? = null,
)

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
