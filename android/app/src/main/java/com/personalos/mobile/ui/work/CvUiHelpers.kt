package com.personalos.mobile.ui.work

import com.personalos.mobile.data.models.PosEntity
import com.personalos.mobile.util.periodLabel

internal data class ParsedTechLine(val stack: List<String>, val body: String)

internal fun cleanCvTitle(title: String): String =
    title.replace("CV: ", "").replace("Add to CV: ", "")

internal fun parseTechLine(content: String): ParsedTechLine {
    val regex = Regex("(?i)(?:^|\\n)\\s*Tech:\\s*(.+?)(?:\\n|$)")
    val match = regex.find(content) ?: return ParsedTechLine(emptyList(), content)
    val stack = match.groupValues[1].split(",")
        .map { it.trim() }
        .filter { it.isNotEmpty() }
    val body = content.replace(regex, "").trim()
    return ParsedTechLine(stack, body)
}

internal fun splitCsv(text: String): List<String> =
    text.split(",").map { it.trim() }.filter { it.isNotEmpty() }

internal fun entityPeriod(entity: PosEntity): String = entity.metadata?.periodLabel().orEmpty()
