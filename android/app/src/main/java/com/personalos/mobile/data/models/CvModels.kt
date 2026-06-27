package com.personalos.mobile.data.models

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class PosCvContact(
    val email: String? = null,
    val phone: String? = null,
    val location: String? = null,
    val linkedin: String? = null,
    val github: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosCvSkillGroup(
    val category: String,
    val items: List<String> = emptyList(),
)

@JsonClass(generateAdapter = true)
data class PosCvEducation(
    val school: String,
    val degree: String? = null,
    val period: String? = null,
    val content: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosCvAchievement(val content: String)

@JsonClass(generateAdapter = true)
data class PosCvCertificate(
    val title: String,
    val issuer: String? = null,
    val period: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosCvBullet(
    val id: String? = null,
    val title: String,
    val content: String,
    val company: String? = null,
    val period: String? = null,
    val section: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosCvDocument(
    val variant: String? = null,
    val headline: String,
    val summary: String,
    val contact: PosCvContact? = null,
    val skills: List<String>? = null,
    @Json(name = "skill_groups") val skillGroups: List<PosCvSkillGroup>? = null,
    @Json(name = "primary_stack") val primaryStack: List<String>? = null,
    val education: List<PosCvEducation>? = null,
    val achievements: List<PosCvAchievement>? = null,
    val certificates: List<PosCvCertificate>? = null,
    val experience: List<PosCvBullet>? = null,
    val projects: List<PosCvBullet>? = null,
)

@JsonClass(generateAdapter = true)
data class PosAssembledCv(
    @Json(name = "document_id") val documentId: String? = null,
    val document: PosCvDocument,
    val source: String = "",
)

@JsonClass(generateAdapter = true)
data class PosCvSaveRequest(val document: PosCvDocument)

@JsonClass(generateAdapter = true)
data class PosCvRefineRequest(
    val instruction: String,
    val section: String,
    val content: String,
)

@JsonClass(generateAdapter = true)
data class PosCvRefineResponse(
    val reply: String,
    @Json(name = "refined_content") val refinedContent: String? = null,
    val section: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosCvShareResponse(
    val url: String,
    @Json(name = "expires_in") val expiresIn: String? = null,
    val filename: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosCvSuggestedSkill(
    val category: String,
    val skill: String,
    val reason: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosCvSuggestSkillsResponse(
    @Json(name = "primary_stack") val primaryStack: List<String>? = null,
    val suggestions: List<PosCvSuggestedSkill> = emptyList(),
)

@JsonClass(generateAdapter = true)
data class PosCvAddSkillRequest(val category: String, val skill: String)

@JsonClass(generateAdapter = true)
data class PosCvAddSkillResponse(val document: PosCvDocument)
