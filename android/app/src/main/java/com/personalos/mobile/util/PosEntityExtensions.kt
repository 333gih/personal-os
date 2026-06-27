package com.personalos.mobile.util

import com.personalos.mobile.config.AppEnvironment
import com.personalos.mobile.data.models.PosEntity
import com.personalos.mobile.data.models.PosWorkMetadata

val PosEntity.architectureLayers get() = metadata?.architectureLayers.orEmpty()

fun PosEntity.designImageUrl(): String? {
    val path = metadata?.heroImage ?: return null
    if (path.startsWith("http")) return path
    return AppEnvironment.frontendUrl(path)
}

val PosWorkMetadata.heroImage: String?
    get() = when {
        !image.isNullOrBlank() -> image
        else -> designImages?.firstOrNull()
    }

fun PosWorkMetadata.periodLabel(): String {
    val start = startDate?.let { PosFormatting.monthYear(it) }.orEmpty()
    val end = when {
        !endDate.isNullOrBlank() -> PosFormatting.monthYear(endDate)
        status == "active" -> "Present"
        else -> ""
    }
    return when {
        start.isNotEmpty() && end.isNotEmpty() -> "$start — $end"
        start.isNotEmpty() -> "$start — Present"
        else -> end
    }
}

val PosEntity.typeLabel: String get() = PosFormatting.humanType(type)

val PosEntity.detailSubtitle: String?
    get() {
        val parts = listOfNotNull(metadata?.company, metadata?.role, metadata?.periodLabel())
            .filter { it.isNotBlank() }
        return parts.takeIf { it.isNotEmpty() }?.joinToString(" · ")
    }

data class PosMetadataRow(val label: String, val value: String)

val PosEntity.metadataRows: List<PosMetadataRow>
    get() {
        val m = metadata ?: return emptyList()
        val rows = mutableListOf<PosMetadataRow>()
        m.company?.takeIf { it.isNotBlank() }?.let { rows += PosMetadataRow("Company", it) }
        m.role?.takeIf { it.isNotBlank() }?.let { rows += PosMetadataRow("Role", it) }
        m.periodLabel().takeIf { it.isNotBlank() }?.let { rows += PosMetadataRow("Period", it) }
        m.location?.takeIf { it.isNotBlank() }?.let { rows += PosMetadataRow("Location", it) }
        m.level?.takeIf { it.isNotBlank() }?.let { rows += PosMetadataRow("Level", it.replaceFirstChar { c -> c.titlecase() }) }
        m.track?.takeIf { it.isNotBlank() }?.let { rows += PosMetadataRow("Track", it) }
        m.phase?.takeIf { it.isNotBlank() }?.let { rows += PosMetadataRow("Phase", it) }
        m.cvStatus?.takeIf { it.isNotBlank() }?.let { status ->
            rows += PosMetadataRow("CV", if (status == "in_cv") "On resume" else "Recommended add")
        }
        m.workHours?.takeIf { it.isNotBlank() }?.let { rows += PosMetadataRow("Hours", it.replace("-", " – ")) }
        return rows
    }

fun PosEntity.hasArchitecture(): Boolean =
    architectureLayers.isNotEmpty() || designImageUrl() != null
