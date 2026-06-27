package com.personalos.mobile.util

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

object PosFormatting {
    fun domainLabel(domain: String): String = when (domain) {
        "work" -> "Work"
        "learning" -> "Learning"
        "startup" -> "Startup"
        "inbox" -> "Inbox"
        "entertainment" -> "Reading"
        else -> domain.replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() }
    }

    fun friendlyDue(iso: String?): String {
        if (iso.isNullOrBlank()) return ""
        val patterns = listOf(
            "yyyy-MM-dd'T'HH:mm:ssX",
            "yyyy-MM-dd'T'HH:mm:ss.SSSX",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        )
        val locale = Locale.US
        for (pattern in patterns) {
            runCatching {
                SimpleDateFormat(pattern, locale).parse(iso)
            }.getOrNull()?.let { date ->
                return SimpleDateFormat("MMM d, yyyy · h:mm a", locale).format(date)
            }
        }
        return iso.take(16).replace('T', ' ')
    }

    fun studyBlockTime(startAt: String?): String {
        if (startAt.isNullOrBlank()) return "--:--"
        val tIndex = startAt.indexOf('T')
        if (tIndex >= 0 && startAt.length >= tIndex + 6) {
            return startAt.substring(tIndex + 1, tIndex + 6)
        }
        if (startAt.length >= 5 && startAt[2] == ':') return startAt.take(5)
        return startAt.takeLast(8).take(5)
    }

    fun relativeDate(iso: String): String {
        val patterns = listOf(
            "yyyy-MM-dd'T'HH:mm:ssX",
            "yyyy-MM-dd'T'HH:mm:ss.SSSX",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
        )
        val locale = Locale.US
        for (pattern in patterns) {
            runCatching {
                SimpleDateFormat(pattern, locale).parse(iso)
            }.getOrNull()?.let { date ->
                val diffMs = date.time - System.currentTimeMillis()
                val absMin = TimeUnit.MILLISECONDS.toMinutes(kotlin.math.abs(diffMs))
                return when {
                    absMin < 1 -> "now"
                    absMin < 60 -> "${absMin}m"
                    absMin < 60 * 24 -> "${absMin / 60}h"
                    else -> "${absMin / (60 * 24)}d"
                }
            }
        }
        return iso
    }

    fun humanType(raw: String): String =
        raw.replace('_', ' ').replaceFirstChar { it.titlecase(Locale.getDefault()) }

    fun monthYear(iso: String): String {
        val prefix = iso.take(10)
        val locale = Locale.US
        runCatching {
            SimpleDateFormat("yyyy-MM-dd", locale).parse(prefix)
        }.getOrNull()?.let { date ->
            return SimpleDateFormat("MMM yyyy", locale).format(date)
        }
        return iso
    }
}
