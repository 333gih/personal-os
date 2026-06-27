package com.personalos.mobile.ui.learning

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.personalos.mobile.data.models.PosDsaDailyFocus
import com.personalos.mobile.data.models.PosLearningTrack
import com.personalos.mobile.data.models.PosTodayStudyBlock
import com.personalos.mobile.ui.components.PosCard
import com.personalos.mobile.ui.components.PosEmptyState
import com.personalos.mobile.ui.components.PosListRow
import com.personalos.mobile.ui.components.PosLoadingView
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AutoStories
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.School
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import com.personalos.mobile.ui.components.PosActionButton
import com.personalos.mobile.ui.components.PosActionStyle
import com.personalos.mobile.ui.components.PosChip
import com.personalos.mobile.ui.components.PosFloatingCaptureButton
import com.personalos.mobile.ui.components.PosHubMenuRow
import com.personalos.mobile.ui.components.PosScreen
import com.personalos.mobile.ui.components.PosSectionHeader
import com.personalos.mobile.ui.navigation.AppNavigator
import com.personalos.mobile.ui.navigation.EntityRoute
import com.personalos.mobile.ui.navigation.WebRoute
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay

@Composable
fun LearningScreen(viewModel: LearningViewModel, nav: AppNavigator, reloadKey: Int = 0) {
    val state by viewModel.state.collectAsState()
    var trackFilter by remember { mutableStateOf<PosLearningTrack?>(null) }
    LaunchedEffect(reloadKey) { viewModel.load() }

    val filteredEntities = remember(state.entities, trackFilter) {
        trackFilter?.let { track ->
            state.entities.filter { (it.metadata?.track ?: it.domain).equals(track.apiValue, true) }
        } ?: state.entities
    }

    Box(Modifier.fillMaxSize()) {
        PosScreen {
            Column(
                Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp).padding(bottom = 72.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                when {
                    state.loading -> PosLoadingView("Loading learning…")
                    state.error != null -> PosEmptyState("Error", state.error.orEmpty(), "Retry") { viewModel.load() }
                    else -> {
                        state.today?.dsa?.let { focus -> DsaDailyFocusCard(focus, nav) }
                        state.today?.let { plan -> TodayPlanSection(plan, nav) }
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            PosChip("All", trackFilter == null) { trackFilter = null }
                            PosChip("DSA", trackFilter == PosLearningTrack.DSA) { trackFilter = PosLearningTrack.DSA }
                            PosChip("English", trackFilter == PosLearningTrack.ENGLISH) { trackFilter = PosLearningTrack.ENGLISH }
                        }
                        PosSectionHeader(title = "Roadmap", action = "Hub", onAction = nav.onOpenLearningHub)
                        filteredEntities.take(20).forEach { entity ->
                            PosListRow(entity.title, entity.metadata?.track ?: entity.domain) {
                                nav.onOpenEntity(EntityRoute(entity.id, entity.title))
                            }
                        }
                    }
                }
            }
        }
        PosFloatingCaptureButton(
            onClick = nav.onOpenLearningHub,
            modifier = Modifier.align(Alignment.BottomEnd).padding(end = 16.dp, bottom = 12.dp),
        )
    }
}

@Composable
private fun DsaDailyFocusCard(focus: PosDsaDailyFocus, nav: AppNavigator) {
    PosCard {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(
                "DSA daily program · Week ${focus.programWeek}/10 · Day ${focus.programDay}",
                color = PosTheme.Focus,
                style = posDisplay(11f),
            )
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("#${focus.patternOrder} ${focus.patternTitle}", style = posDisplay(18f))
                if (focus.mockToday) Text("MOCK", color = PosTheme.Focus, style = posDisplay(10f))
            }
            Text(
                "${focus.dayType.replace('_', ' ')} · ${focus.targetProblems} problems · ${focus.cumulativeTarget}+ cumulative",
                color = PosTheme.Muted,
                style = posDisplay(11f),
            )
            focus.tasks.take(3).forEach { task -> Text("• $task", style = posDisplay(12f)) }
            focus.suggestedProblems?.takeIf { it.isNotEmpty() }?.let {
                Text("Suggested: ${it.joinToString(", ")}", color = PosTheme.Muted, style = posDisplay(10f))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                PosActionButton("Pattern theory", style = PosActionStyle.Secondary) {
                    focus.patternEntityId?.let { nav.onOpenLearningLesson(it, focus.patternTitle) }
                }
                PosActionButton("AI drill", style = PosActionStyle.Secondary) {
                    nav.onOpenLearningCoach(PosLearningTrack.DSA, focus.patternEntityId, focus.patternTitle)
                }
            }
        }
    }
}

@Composable
private fun TodayPlanSection(plan: com.personalos.mobile.data.models.PosTodayStudyPlan, nav: AppNavigator) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            PosSectionHeader(
                title = "Today's plan",
                action = "Schedule",
                onAction = { nav.onOpenLearningSchedule() },
            )
            Text(
                "${plan.totalMinutes} min · ${if (plan.isWorkDay) "Work day" else "Weekend"}",
                color = PosTheme.Muted,
                style = posDisplay(11f),
            )
        }
        if (plan.blocks.isEmpty()) {
            Text("No blocks today — adjust your work schedule.", color = PosTheme.Muted, style = posDisplay(12f))
        } else {
            plan.blocks.forEach { block -> StudyBlockRow(block, nav) }
        }
    }
}

@Composable
private fun StudyBlockRow(block: PosTodayStudyBlock, nav: AppNavigator) {
    PosCard {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Column {
                Text(block.startAt?.takeLast(8)?.take(5).orEmpty(), color = PosTheme.PrimaryDark, style = posDisplay(11f))
                Text("${block.durationMinutes}m", color = PosTheme.Muted, style = posDisplay(10f))
            }
            Column(Modifier.weight(1f)) {
                Text(block.track.uppercase(), color = if (block.track == "dsa") PosTheme.PrimaryDark else PosTheme.Focus, style = posDisplay(10f))
                Text(block.title, style = posDisplay(14f))
                Text(block.subtitle, color = PosTheme.Muted, style = posDisplay(11f))
                block.commuteTip?.let { Text(it, color = PosTheme.PrimaryDark, style = posDisplay(10f)) }
            }
        }
        block.entityId?.let { id ->
            PosActionButton("Open block", style = PosActionStyle.Secondary) { nav.onOpenLearningLesson(id, block.title) }
        }
    }
}

@Composable
fun LearningHubSheet(nav: AppNavigator, onDismiss: () -> Unit) {
    Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text("Learning hub", style = posDisplay(20f))
        Text("DSA + TOEIC — daily schedule tuned for metro/bus commutes.", color = PosTheme.Muted, style = posDisplay(12f))
        PosHubMenuRow("Today's schedule", "Blocks tuned for commute windows", Icons.Default.CalendarMonth) { nav.onOpenLearningSchedule(); onDismiss() }
        PosHubMenuRow("Notification log", "Recent study reminders", Icons.Default.Notifications) { nav.onOpenNotificationLog(); onDismiss() }
        PosHubMenuRow("Add DSA entry", "Course, topic, skill, or note", Icons.Default.School) { nav.onOpenLearningAdd(PosLearningTrack.DSA); onDismiss() }
        PosHubMenuRow("Add English entry", "TOEIC track capture", Icons.Default.AutoStories) { nav.onOpenLearningAdd(PosLearningTrack.ENGLISH); onDismiss() }
        PosHubMenuRow("AI study coach", "Drill with context", Icons.Default.Psychology) { nav.onOpenLearningCoach(PosLearningTrack.DSA, null, ""); onDismiss() }
        PosHubMenuRow("Open learning board", "Full web roadmap", Icons.Default.Add) { nav.onOpenWeb(WebRoute.path("/learning", "Learning")); onDismiss() }
        PosActionButton("Quick capture", style = PosActionStyle.Secondary, onClick = { nav.captureNote(); onDismiss() })
    }
}
