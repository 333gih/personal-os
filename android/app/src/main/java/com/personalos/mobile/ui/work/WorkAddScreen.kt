package com.personalos.mobile.ui.work

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.personalos.mobile.data.repository.PersonalOSRepository
import com.personalos.mobile.ui.components.PosActionButton
import com.personalos.mobile.ui.components.PosChip
import com.personalos.mobile.ui.components.PosScreen
import com.personalos.mobile.ui.navigation.AppNavigator
import com.personalos.mobile.ui.navigation.EntityRoute
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay
import kotlinx.coroutines.launch

private val workKinds = listOf(
    "project" to "Project",
    "skill" to "Skill / Tech",
    "role" to "Role",
    "feature" to "Feature",
    "lesson" to "Lesson",
    "decision" to "Decision",
)

@Composable
fun WorkAddScreen(
    repository: PersonalOSRepository,
    nav: AppNavigator,
    onClose: () -> Unit,
    onCreated: () -> Unit = {},
) {
    var kind by remember { mutableStateOf(workKinds.first().first) }
    var titleHint by remember { mutableStateOf("") }
    var rawText by remember { mutableStateOf("") }
    var saving by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    PosScreen {
        Column(
            Modifier.verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(
                "Paste rough notes — AI rewrites professionally and syncs skills to your CV.",
                style = posDisplay(11f),
                color = PosTheme.Muted,
            )
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                workKinds.forEach { (value, label) ->
                    PosChip(label, selected = kind == value) { kind = value }
                }
            }
            OutlinedTextField(titleHint, { titleHint = it }, Modifier.fillMaxWidth(), label = { Text("Title hint (optional)") })
            OutlinedTextField(rawText, { rawText = it }, Modifier.fillMaxWidth(), label = { Text("Your notes…") }, minLines = 6)
            error?.let { Text(it, color = PosTheme.Error, style = posDisplay(11f)) }
            PosActionButton(if (saving) "Adding…" else "Add & normalize", onClick = {
                if (rawText.isBlank() || saving) return@PosActionButton
                saving = true
                error = null
                scope.launch {
                    runCatching { repository.addWorkEntry(kind, rawText.trim(), titleHint.trim()) }
                        .onSuccess {
                            onCreated()
                            nav.onOpenEntity(EntityRoute(it.entityId, it.title))
                            onClose()
                        }
                        .onFailure { error = it.message ?: "Could not add entry" }
                    saving = false
                }
            })
        }
    }
}
