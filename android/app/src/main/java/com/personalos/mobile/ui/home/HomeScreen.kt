package com.personalos.mobile.ui.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.personalos.mobile.data.auth.SessionManager
import com.personalos.mobile.data.models.PosDashboard
import com.personalos.mobile.data.models.PosTab
import com.personalos.mobile.ui.components.PosEmptyState
import com.personalos.mobile.ui.components.PosFloatingCaptureButton
import com.personalos.mobile.ui.components.PosFocusCard
import com.personalos.mobile.ui.components.PosJournalDateStamp
import com.personalos.mobile.ui.components.PosListRow
import com.personalos.mobile.ui.components.PosLoadingView
import com.personalos.mobile.ui.components.PosMetricCard
import com.personalos.mobile.ui.components.PosNoteDivider
import com.personalos.mobile.ui.components.PosQuickActionRow
import com.personalos.mobile.ui.components.PosScreen
import com.personalos.mobile.ui.components.PosSectionHeader
import com.personalos.mobile.ui.components.PosShelfHighlightCard
import com.personalos.mobile.ui.navigation.AppNavigator
import com.personalos.mobile.ui.navigation.EntityRoute
import com.personalos.mobile.ui.navigation.WebRoute
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.util.PosFormatting

@Composable
fun HomeScreen(
    viewModel: HomeViewModel,
    sessionManager: SessionManager,
    nav: AppNavigator,
) {
    val state by viewModel.state.collectAsState()
    LaunchedEffect(Unit) { viewModel.load() }

    Box(Modifier.fillMaxSize()) {
        PosScreen {
            Column(
                Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp, vertical = 16.dp)
                    .padding(bottom = 72.dp),
                verticalArrangement = Arrangement.spacedBy(22.dp),
            ) {
                PosJournalDateStamp(sessionManager.firstName())
                when {
                    state.loading && state.dashboard == null -> PosLoadingView("Opening your journal…")
                    state.error != null && state.dashboard == null -> PosEmptyState(
                        title = "Could not refresh",
                        message = state.error.orEmpty(),
                        actionTitle = "Try again",
                        onAction = { viewModel.load() },
                    )
                    state.dashboard != null -> HomeContent(state.dashboard!!, nav, onRefresh = { viewModel.load(refresh = true) })
                }
            }
        }
        PosFloatingCaptureButton(
            onClick = nav.captureNote,
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(end = 18.dp, bottom = 12.dp),
        )
    }
}

@Composable
private fun HomeContent(
    data: PosDashboard,
    nav: AppNavigator,
    onRefresh: () -> Unit,
) {
    val total = data.domainCounts.values.sum()
    val learning = data.domainCounts["learning"] ?: 0
    val work = data.domainCounts["work"] ?: 0
    val pct = if (total > 0) minOf(100, 28 + learning * 8 + work * 4) else 0

    PosFocusCard(
        learning = learning,
        work = work,
        progress = pct,
        onClick = { nav.onSwitchTab(PosTab.LEARNING) },
    )

    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        PosMetricCard(
            "Inbox",
            "${data.inboxCount}",
            if (data.inboxCount > 0) "Waiting to sort" else "All caught up",
            Modifier.weight(1f),
        ) {
            nav.onOpenWeb(WebRoute.path("/inbox", "Inbox"))
        }
        PosMetricCard("Library", "$total", "Notes & projects", Modifier.weight(1f)) {
            nav.onSwitchTab(PosTab.SEARCH)
        }
    }

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        PosSectionHeader(
            title = "Quick capture",
            action = "Inbox",
            onAction = { nav.onOpenWeb(WebRoute.path("/inbox", "Inbox")) },
        )
        PosQuickActionRow(
            onNewNote = nav.captureNote,
            onStudy = { nav.onSwitchTab(PosTab.LEARNING) },
            onReading = { nav.onOpenWeb(WebRoute.path("/entertainment", "Reading Log")) },
            onSearch = { nav.onSwitchTab(PosTab.SEARCH) },
        )
    }

    PosNoteDivider()

    ShelfSection(data, nav)

    PosNoteDivider()

    UpNextSection(data, nav, onRefresh)
}

@Composable
private fun ShelfSection(data: PosDashboard, nav: AppNavigator) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        PosSectionHeader(
            title = "From your shelf",
            eyebrow = "Recently touched",
            action = "Reading log",
            onAction = { nav.onOpenWeb(WebRoute.path("/entertainment", "Reading Log")) },
        )
        data.recent.firstOrNull()?.let { recent ->
            PosShelfHighlightCard(
                domain = PosFormatting.domainLabel(recent.domain),
                title = recent.title,
                content = recent.content,
                onClick = { nav.onOpenEntity(EntityRoute(recent.id, recent.title)) },
            )
        } ?: PosEmptyState(
            title = "Nothing on the shelf yet",
            message = "Your latest note or reading entry will land here.",
            actionTitle = "Capture a note",
            onAction = nav.captureNote,
        )
    }
}

@Composable
private fun UpNextSection(data: PosDashboard, nav: AppNavigator, onRefresh: () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        PosSectionHeader(title = "Up next", action = "Refresh", onAction = onRefresh)
        if (data.upcomingReminders.isEmpty()) {
            PosEmptyState(
                title = "A clear afternoon",
                message = "Add a reminder to any entry and it will appear here.",
                actionTitle = "Open inbox",
                onAction = { nav.onOpenWeb(WebRoute.path("/inbox", "Inbox")) },
            )
        } else {
            data.upcomingReminders.take(5).forEach { reminder ->
                PosListRow(
                    title = reminder.title,
                    subtitle = PosFormatting.friendlyDue(reminder.dueAt),
                    badge = reminder.status.takeIf { it.isNotBlank() },
                    icon = Icons.Default.AccessTime,
                    iconTint = PosTheme.Focus,
                    onClick = {
                        val entityId = reminder.entityId?.takeIf { it.isNotBlank() }
                        if (entityId != null) {
                            nav.onOpenEntity(EntityRoute(entityId, reminder.title))
                        } else {
                            nav.onOpenWeb(WebRoute.path("/inbox", "Reminders"))
                        }
                    },
                )
            }
        }
    }
}
