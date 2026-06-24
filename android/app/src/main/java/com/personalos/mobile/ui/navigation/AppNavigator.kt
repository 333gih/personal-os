package com.personalos.mobile.ui.navigation

import com.personalos.mobile.config.AppEnvironment
import com.personalos.mobile.data.models.PosEntitySection
import com.personalos.mobile.data.models.PosLearningTrack
import com.personalos.mobile.data.models.PosTab

data class WebRoute(val url: String, val title: String, val embed: Boolean = true) {
    val finalUrl: String
        get() {
            if (!embed || url.contains("embed=1")) return url
            val sep = if (url.contains("?")) "&" else "?"
            return "$url${sep}embed=1"
        }

    companion object {
        fun path(path: String, title: String): WebRoute =
            WebRoute(AppEnvironment.frontendUrl(path), title)

        fun entity(id: String, title: String): WebRoute =
            WebRoute(AppEnvironment.frontendUrl("/entities/$id"), title, embed = false)
    }
}

data class EntityRoute(
    val id: String,
    val title: String,
    val section: PosEntitySection = PosEntitySection.OVERVIEW,
)

data class LearningLessonRoute(val id: String, val title: String)

class AppNavigator(
    val onSwitchTab: (PosTab) -> Unit,
    val onOpenWeb: (WebRoute) -> Unit,
    val onOpenEntity: (EntityRoute) -> Unit,
    val onOpenCv: () -> Unit,
    val onOpenJobScout: () -> Unit,
    val onOpenWorkImport: () -> Unit,
    val onOpenWorkAdd: () -> Unit,
    val onOpenWorkHub: () -> Unit,
    val onOpenStartup: () -> Unit,
    val onOpenStartupAdd: () -> Unit,
    val onOpenLearningHub: () -> Unit,
    val onOpenLearningAdd: (PosLearningTrack) -> Unit,
    val onOpenLearningCoach: (PosLearningTrack, String?, String) -> Unit,
    val onOpenLearningLesson: (String, String) -> Unit,
    val onOpenLearningSchedule: () -> Unit,
    val onOpenNotificationLog: () -> Unit,
    val onOpenInterviewPrep: () -> Unit,
    val captureNote: () -> Unit = { onOpenWeb(WebRoute.path("/inbox", "Inbox")) },
)
