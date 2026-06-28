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

@JsonClass(generateAdapter = true)
data class PosCvBlockOverrides(
    val title: String? = null,
    val company: String? = null,
    val period: String? = null,
    @Json(name = "highlight_stack") val highlightStack: List<String>? = null,
    @Json(name = "skill_items") val skillItems: List<String>? = null,
    val email: String? = null,
    val phone: String? = null,
    val location: String? = null,
    val linkedin: String? = null,
    val github: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosCvBlock(
    val id: String,
    val type: String,
    val order: Int = 0,
    val enabled: Boolean = true,
    @Json(name = "source_entity_id") val sourceEntityId: String? = null,
    val content: String? = null,
    val overrides: PosCvBlockOverrides? = null,
    @Json(name = "ai_refined_at") val aiRefinedAt: String? = null,
    @Json(name = "pending_raw") val pendingRaw: String? = null,
    @Json(name = "skill_groups") val skillGroups: List<PosCvSkillGroup>? = null,
)

@JsonClass(generateAdapter = true)
data class PosCvConstraints(
    @Json(name = "max_pages") val maxPages: Int = 1,
    @Json(name = "max_experience") val maxExperience: Int = 0,
    @Json(name = "max_projects") val maxProjects: Int = 0,
)

@JsonClass(generateAdapter = true)
data class PosCvTemplate(
    val id: String = "",
    val name: String,
    @Json(name = "layout_id") val layoutId: String = "two_column_one_page_v5",
    @Json(name = "is_default") val isDefault: Boolean = false,
    @Json(name = "is_system") val isSystem: Boolean = false,
    val constraints: PosCvConstraints = PosCvConstraints(),
    val blocks: List<PosCvBlock> = emptyList(),
    @Json(name = "updated_at") val updatedAt: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosCvTemplatesResponse(val templates: List<PosCvTemplate> = emptyList())

@JsonClass(generateAdapter = true)
data class PosCvLayout(
    val id: String,
    val label: String,
    val description: String? = null,
    val constraints: PosCvConstraints? = null,
)

@JsonClass(generateAdapter = true)
data class PosCvLayoutsResponse(val layouts: List<PosCvLayout> = emptyList())

@JsonClass(generateAdapter = true)
data class PosCvValidateResult(
    val valid: Boolean = true,
    @Json(name = "page_count") val pageCount: Int = 0,
    @Json(name = "max_pages") val maxPages: Int = 1,
    val overflows: List<String>? = null,
    val suggestions: List<String>? = null,
)

@JsonClass(generateAdapter = true)
data class PosCvSaveTemplateRequest(
    val template: PosCvTemplate,
    val force: Boolean = false,
)

@JsonClass(generateAdapter = true)
data class PosCvValidateRequest(val template: PosCvTemplate)

@JsonClass(generateAdapter = true)
data class PosCvCreateTemplateRequest(
    val name: String,
    @Json(name = "layout_id") val layoutId: String = "",
    @Json(name = "clone_id") val cloneId: String = "",
)

@JsonClass(generateAdapter = true)
data class PosCvRefineBlockRequest(
    val instruction: String = "",
    val content: String,
)

@JsonClass(generateAdapter = true)
data class PosCvAddBlockFromEntityRequest(
    @Json(name = "entity_id") val entityId: String,
    @Json(name = "block_type") val blockType: String,
    val overrides: PosCvBlockOverrides? = null,
)
