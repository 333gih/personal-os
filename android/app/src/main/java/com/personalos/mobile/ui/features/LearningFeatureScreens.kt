package com.personalos.mobile.ui.features

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import com.personalos.mobile.data.models.PosLearningSchedule
import com.personalos.mobile.data.models.PosLearningTrack
import com.personalos.mobile.data.models.PosNotificationLogItem
import com.personalos.mobile.data.repository.PersonalOSRepository
import com.personalos.mobile.ui.components.PosCard
import com.personalos.mobile.ui.components.PosEmptyState
import com.personalos.mobile.ui.components.PosLoadingView
import com.personalos.mobile.ui.components.PosPrimaryButton
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay
import kotlinx.coroutines.launch

@Composable
fun LearningCoachScreen(
    repository: PersonalOSRepository,
    track: PosLearningTrack,
    entityId: String?,
    initialTopic: String,
    onClose: () -> Unit,
) {
    var focus by remember { mutableStateOf("") }
    var loading by remember { mutableStateOf(false) }
    var jobStatus by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }
    var result by remember { mutableStateOf<com.personalos.mobile.data.models.PosLearningCoachResult?>(null) }
    val scope = rememberCoroutineScope()

    fun runAsync(autoStart: Boolean = false) {
        if (!autoStart && loading) return
        scope.launch {
            loading = true
            error = null
            jobStatus = "Starting AI coach…"
            runCatching {
                val queued = repository.coachLearningAsync(entityId, initialTopic, track.apiValue, focus)
                jobStatus = "Job ${queued.id.take(8)}… running"
                repository.pollStudyJob(queued.id)
            }.onSuccess {
                result = it.result
                jobStatus = ""
            }.onFailure {
                if (it.message?.contains("still running") == true) {
                    jobStatus = "Still running — check Notification log later."
                } else {
                    error = it.message
                    jobStatus = ""
                }
            }
            loading = false
        }
    }

    LaunchedEffect(entityId, initialTopic) {
        if (entityId != null || initialTopic.isNotBlank()) {
            loading = true
            error = null
            jobStatus = "Starting AI coach…"
            runCatching {
                val queued = repository.coachLearningAsync(entityId, initialTopic, track.apiValue, focus)
                jobStatus = "Job ${queued.id.take(8)}… running"
                repository.pollStudyJob(queued.id)
            }.onSuccess {
                result = it.result
                jobStatus = ""
            }.onFailure {
                if (it.message?.contains("still running") == true) {
                    jobStatus = "Still running — check Notification log later."
                } else {
                    error = it.message
                    jobStatus = ""
                }
            }
            loading = false
        }
    }

    FeatureScaffold("Study Coach", onClose) {
        Text(
            "AI runs in the background — you'll get a notification when the drill is ready.",
            color = PosTheme.Muted,
            style = posDisplay(12f),
        )
        androidx.compose.material3.OutlinedTextField(
            focus,
            { focus = it },
            Modifier.fillMaxWidth(),
            label = { Text("Focus (optional)") },
        )
        PosPrimaryButton(if (loading) "Queued…" else "Start AI coach job") { runAsync() }
        if (jobStatus.isNotBlank()) Text(jobStatus, color = PosTheme.PrimaryDark, style = posDisplay(12f))
        error?.let { Text(it, color = PosTheme.Error) }
        result?.let { coach ->
            CoachSection("Summary", listOfNotNull(coach.summary.takeIf { it.isNotBlank() }))
            CoachSection("Practice questions", coach.practiceQuestions)
            CoachSection("Tips", coach.tips)
            CoachSection("Next steps", coach.nextSteps)
        }
    }
}

@Composable
fun LearningScheduleScreen(repository: PersonalOSRepository, onClose: () -> Unit) {
    var schedule by remember { mutableStateOf(PosLearningSchedule()) }
    var loading by remember { mutableStateOf(true) }
    var saving by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        runCatching { repository.fetchLearningSchedule() }
            .onSuccess { schedule = it; loading = false }
            .onFailure { error = it.message; loading = false }
    }

    FeatureScaffold("Study schedule", onClose) {
        when {
            loading -> PosLoadingView("Loading schedule…")
            else -> {
                Text("Work hours", style = posDisplay(14f), color = PosTheme.PrimaryDark)
                StepperRow("Start hour", schedule.workStartHour, 5, 12) {
                    schedule = schedule.copy(workStartHour = it)
                }
                StepperRow("End hour", schedule.workEndHour, 14, 22) {
                    schedule = schedule.copy(workEndHour = it)
                }
                Text("Commute (metro / bus)", style = posDisplay(14f), color = PosTheme.PrimaryDark)
                androidx.compose.material3.OutlinedTextField(
                    schedule.morningCommuteTime,
                    { schedule = schedule.copy(morningCommuteTime = it) },
                    Modifier.fillMaxWidth(),
                    label = { Text("Morning") },
                )
                androidx.compose.material3.OutlinedTextField(
                    schedule.eveningCommuteTime,
                    { schedule = schedule.copy(eveningCommuteTime = it) },
                    Modifier.fillMaxWidth(),
                    label = { Text("Evening") },
                )
                StepperRow("DSA on commute (min)", schedule.dsaCommuteMinutes, 5, 60) {
                    schedule = schedule.copy(dsaCommuteMinutes = it)
                }
                StepperRow("English vocab (min)", schedule.englishCommuteMinutes, 5, 45) {
                    schedule = schedule.copy(englishCommuteMinutes = it)
                }
                Text("TOEIC hardcore", style = posDisplay(14f), color = PosTheme.PrimaryDark)
                androidx.compose.material3.OutlinedTextField(
                    schedule.toeicSessionTime,
                    { schedule = schedule.copy(toeicSessionTime = it) },
                    Modifier.fillMaxWidth(),
                    label = { Text("Evening session") },
                )
                StepperRow("Daily deep study (min)", schedule.toeicDailyMinutes, 15, 180) {
                    schedule = schedule.copy(toeicDailyMinutes = it)
                }
                androidx.compose.foundation.layout.Row(
                    Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Text("Push + local reminders")
                    Switch(schedule.pushEnabled, { schedule = schedule.copy(pushEnabled = it) })
                }
                error?.let { Text(it, color = PosTheme.Error) }
                PosPrimaryButton(if (saving) "Saving…" else "Save") {
                    saving = true
                    scope.launch {
                        runCatching { repository.saveLearningSchedule(schedule) }
                            .onSuccess { schedule = it; onClose() }
                            .onFailure { error = it.message }
                        saving = false
                    }
                    Unit
                }
            }
        }
    }
}

@Composable
fun NotificationLogScreen(repository: PersonalOSRepository, onClose: () -> Unit) {
    var items by remember { mutableStateOf<List<PosNotificationLogItem>>(emptyList()) }
    var loading by remember { mutableStateOf(true) }
    val scope = rememberCoroutineScope()

    fun reload() {
        scope.launch {
            loading = true
            runCatching { repository.fetchNotificationLog() }
                .onSuccess { items = it.items; loading = false }
                .onFailure { items = emptyList(); loading = false }
        }
    }

    LaunchedEffect(Unit) { reload() }

    FeatureScaffold("Notification log", onClose) {
        when {
            loading -> PosLoadingView("Loading log…")
            items.isEmpty() -> PosEmptyState(
                "No notifications yet",
                "Study reminders and AI coach alerts will appear here.",
                "Close",
                onAction = onClose,
            )
            else -> items.forEach { item ->
                PosCard {
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        androidx.compose.foundation.layout.Row(
                            Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                        ) {
                            Text(item.title, style = posDisplay(14f))
                            StatusBadge(item.status)
                        }
                        Text(item.body, color = PosTheme.Muted, style = posDisplay(12f))
                        Text(item.createdAt, color = PosTheme.Muted, style = posDisplay(10f))
                    }
                }
            }
        }
        PosPrimaryButton("Refresh") { reload() }
    }
}

@Composable
private fun CoachSection(title: String, items: List<String>) {
    val filtered = items.filter { it.isNotBlank() }
    if (filtered.isEmpty()) return
    PosCard {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(title, style = posDisplay(12f), color = PosTheme.PrimaryDark)
            filtered.forEach { Text("• $it") }
        }
    }
}

@Composable
private fun StatusBadge(status: String) {
    val color = when (status) {
        "sent" -> PosTheme.Success
        "failed" -> PosTheme.Error
        "skipped" -> PosTheme.Focus
        else -> PosTheme.Muted
    }
    Text(
        status,
        color = color,
        style = posDisplay(10f),
        modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
    )
}

@Composable
private fun StepperRow(label: String, value: Int, min: Int, max: Int, onChange: (Int) -> Unit) {
    androidx.compose.foundation.layout.Row(
        Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text("$label: $value")
        androidx.compose.foundation.layout.Row {
            PosPrimaryButton("-") { if (value > min) onChange(value - 1) }
            PosPrimaryButton("+") { if (value < max) onChange(value + 1) }
        }
    }
}

@Composable
internal fun FeatureScaffold(title: String, onClose: () -> Unit, content: @Composable ColumnScope.() -> Unit) {
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(title, style = posDisplay(22f))
        content()
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun PosChipFlow(
    items: List<String>,
    selected: Set<String> = emptySet(),
    onToggle: ((String) -> Unit)? = null,
) {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        items.forEach { item ->
            val isSelected = selected.any { it.equals(item, ignoreCase = true) }
            FilterChip(
                selected = isSelected,
                onClick = { onToggle?.invoke(item) },
                label = { Text(if (isSelected) "✓ $item" else item) },
            )
        }
    }
}

@Composable
internal fun PosMonoBlock(text: String) {
    Text(
        text,
        fontFamily = FontFamily.Monospace,
        style = posDisplay(11f),
        modifier = Modifier
            .fillMaxWidth()
            .padding(12.dp),
    )
}
