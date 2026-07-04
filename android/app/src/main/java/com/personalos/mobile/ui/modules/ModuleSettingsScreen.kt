package com.personalos.mobile.ui.modules

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.personalos.mobile.ui.components.PosScreen
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay

@Composable
fun ModuleSettingsScreen(
    viewModel: ModulesViewModel,
    onClose: () -> Unit,
) {
    val state by viewModel.state.collectAsState()
    val draft = remember(state.prefs) {
        mutableStateMapOf<String, Boolean>().apply {
            state.prefs.forEach { put(it.moduleId, it.enabled) }
        }
    }

    PosScreen {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text("Modules", style = posDisplay(24f))
            Text(
                "Enable or disable domain modules. Core modules (Inbox, Search) always stay on.",
                color = PosTheme.Muted,
            )
            viewModel.domainModules().forEach { entry ->
                Row(
                    Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(Modifier.weight(1f)) {
                        Text(entry.label, style = posDisplay(16f))
                        Text(entry.description, color = PosTheme.Muted)
                    }
                    if (entry.required) {
                        Text("Required", color = PosTheme.Muted)
                    } else {
                        Switch(
                            checked = draft[entry.id] ?: entry.defaultEnabled,
                            onCheckedChange = { draft[entry.id] = it },
                        )
                    }
                }
            }
            com.personalos.mobile.ui.components.PosActionButton(
                text = "Save",
                onClick = {
                    viewModel.updateModules(draft.map { it.key to it.value })
                    onClose()
                },
            )
            com.personalos.mobile.ui.components.PosActionButton(
                text = "Close",
                style = com.personalos.mobile.ui.components.PosActionStyle.Secondary,
                onClick = onClose,
            )
        }
    }
}
