package com.personalos.mobile.ui.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.personalos.mobile.data.auth.SessionManager
import com.personalos.mobile.data.models.PosDashboard
import com.personalos.mobile.data.models.PosTab
import com.personalos.mobile.ui.components.PosCard
import com.personalos.mobile.ui.components.PosEmptyState
import com.personalos.mobile.ui.components.PosJournalDateStamp
import com.personalos.mobile.ui.components.PosListRow
import com.personalos.mobile.ui.components.PosLoadingView
import com.personalos.mobile.ui.components.PosMetricCard
import com.personalos.mobile.ui.components.PosScreen
import com.personalos.mobile.ui.navigation.AppNavigator
import com.personalos.mobile.ui.navigation.WebRoute
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay

@Composable
fun HomeScreen(
    viewModel: HomeViewModel,
    sessionManager: SessionManager,
    nav: AppNavigator,
) {
    val state by viewModel.state.collectAsState()
    LaunchedEffect(Unit) { viewModel.load() }

    PosScreen {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            PosJournalDateStamp(sessionManager.firstName())
            when {
                state.loading -> PosLoadingView("Opening your journal…")
                state.error != null -> PosEmptyState(
                    title = "Could not refresh",
                    message = state.error.orEmpty(),
                    actionTitle = "Try again",
                    onAction = { viewModel.load() },
                )
                state.dashboard != null -> HomeContent(state.dashboard!!, nav)
            }
        }
    }
}

@Composable
private fun HomeContent(data: PosDashboard, nav: AppNavigator) {
    val total = data.domainCounts.values.sum()
    val learning = data.domainCounts["learning"] ?: 0
    val work = data.domainCounts["work"] ?: 0
    val pct = if (total > 0) minOf(100, 28 + learning * 8 + work * 4) else 0

    PosCard {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("TODAY'S FOCUS", color = PosTheme.Focus, style = posDisplay(12f))
            Text(if (total > 0) "${learning + work} entries" else "Start a note", style = posDisplay(30f))
            Text(
                if (total > 0) "Building across learning and work." else "Capture one thought in Inbox to begin.",
                color = PosTheme.Muted,
            )
            LinearProgressIndicator(progress = { pct / 100f }, modifier = Modifier.fillMaxWidth(), color = PosTheme.Focus)
        }
    }

    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        PosMetricCard("Inbox", "${data.inboxCount}", if (data.inboxCount > 0) "Waiting to sort" else "All caught up", Modifier.weight(1f)) {
            nav.onOpenWeb(WebRoute.path("/inbox", "Inbox"))
        }
        PosMetricCard("Library", "$total", "Notes & projects", Modifier.weight(1f)) {
            nav.onSwitchTab(PosTab.WORK)
        }
    }

    Text("Recent", style = posDisplay(18f))
    data.recentEntities.take(6).forEach { entity ->
        PosListRow(entity.title, entity.domain) {
            nav.onOpenEntity(com.personalos.mobile.ui.navigation.EntityRoute(entity.id, entity.title))
        }
    }

    if (data.reminders.isNotEmpty()) {
        Text("Up next", style = posDisplay(18f))
        data.reminders.take(5).forEach { reminder ->
            PosListRow(reminder.title, reminder.due) {}
        }
    }
}
