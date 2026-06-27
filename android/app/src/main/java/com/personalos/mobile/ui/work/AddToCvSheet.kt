package com.personalos.mobile.ui.work

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.personalos.mobile.data.models.PosCvBlockOverrides
import com.personalos.mobile.data.models.PosCvTemplate
import com.personalos.mobile.data.models.PosEntity
import com.personalos.mobile.data.repository.PersonalOSRepository
import com.personalos.mobile.ui.components.PosLoadingView
import com.personalos.mobile.ui.components.PosPrimaryButton
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddToCvSheet(
    entity: PosEntity,
    repository: PersonalOSRepository,
    onDismiss: () -> Unit,
    onAdded: (PosCvTemplate) -> Unit,
) {
    var templates by remember { mutableStateOf<List<PosCvTemplate>>(emptyList()) }
    var selectedTemplateId by remember { mutableStateOf<String?>(null) }
    var blockType by remember {
        mutableStateOf(
            if (entity.type.contains("role") || entity.type.contains("employer")) "experience" else "project",
        )
    }
    var stackText by remember { mutableStateOf("") }
    var loading by remember { mutableStateOf(true) }
    var submitting by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    LaunchedEffect(Unit) {
        runCatching { repository.listCvTemplates() }
            .onSuccess {
                templates = it
                selectedTemplateId = it.firstOrNull()?.id
                loading = false
            }
            .onFailure { error = it.message; loading = false }
    }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState) {
        Column(
            Modifier
                .padding(horizontal = 20.dp)
                .padding(bottom = 28.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text("Add to CV", style = posDisplay(18f))
            Text(entity.title, color = PosTheme.Muted, style = posDisplay(12f))
            when {
                loading -> PosLoadingView()
                error != null -> Text(error.orEmpty(), color = PosTheme.Error)
                else -> {
                    Text("Template", style = posDisplay(12f), color = PosTheme.PrimaryDark)
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        templates.forEach { tpl ->
                            FilterChip(
                                selected = tpl.id == selectedTemplateId,
                                onClick = { selectedTemplateId = tpl.id },
                                label = { Text(tpl.name) },
                            )
                        }
                    }
                    Text("Section", style = posDisplay(12f), color = PosTheme.PrimaryDark)
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        listOf("project", "experience").forEach { type ->
                            FilterChip(
                                selected = blockType == type,
                                onClick = { blockType = type },
                                label = { Text(type) },
                            )
                        }
                    }
                    OutlinedTextField(
                        stackText,
                        { stackText = it },
                        Modifier.fillMaxWidth(),
                        label = { Text("Highlight stack (comma-separated)") },
                    )
                    PosPrimaryButton(if (submitting) "Adding…" else "Add block") {
                        val templateId = selectedTemplateId ?: return@PosPrimaryButton
                        submitting = true
                        scope.launch {
                            val stack = stackText.split(",").map { it.trim() }.filter { it.isNotEmpty() }
                            val overrides = PosCvBlockOverrides(
                                title = entity.title,
                                company = entity.metadata?.company,
                                highlightStack = stack.takeIf { it.isNotEmpty() },
                            )
                            runCatching {
                                repository.addCvBlockFromEntity(templateId, entity.id, blockType, overrides)
                            }.onSuccess {
                                onAdded(it)
                                onDismiss()
                            }.onFailure { err -> error = err.message }
                            submitting = false
                        }
                        Unit
                    }
                }
            }
        }
    }
}
