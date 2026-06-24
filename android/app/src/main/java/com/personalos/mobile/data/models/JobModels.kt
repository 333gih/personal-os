package com.personalos.mobile.data.models

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class PosJobOpportunity(
    val id: String,
    val title: String,
    val company: String = "",
    val location: String = "",
    val url: String = "",
    val status: String = "open",
    val score: Double? = null,
    @Json(name = "posted_at") val postedAt: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosJobListResponse(val jobs: List<PosJobOpportunity> = emptyList())

@JsonClass(generateAdapter = true)
data class PosJobStatusRequest(val status: String)

@JsonClass(generateAdapter = true)
data class PosJobScanResult(
    @Json(name = "jobs_found") val jobsFound: Int = 0,
    @Json(name = "jobs_new") val jobsNew: Int = 0,
)

@JsonClass(generateAdapter = true)
data class PosJobScanStatusResponse(
    val status: String,
    val result: PosJobScanResult? = null,
    val error: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosJobSearchPreferences(
    val roles: List<String> = emptyList(),
    val locations: List<String> = emptyList(),
    val keywords: List<String> = emptyList(),
    @Json(name = "min_match_score") val minMatchScore: Double = 0.0,
    @Json(name = "remote_ok") val remoteOk: Boolean = true,
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
