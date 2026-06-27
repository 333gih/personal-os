package com.personalos.mobile.ui.work

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.personalos.mobile.data.models.PosCvBlockOverrides
import com.personalos.mobile.data.models.PosCvTemplate
import com.personalos.mobile.data.models.PosCvValidateResult
import com.personalos.mobile.data.models.PosEntity
import com.personalos.mobile.data.repository.PersonalOSRepository
import com.personalos.mobile.ui.components.PosCard
import com.personalos.mobile.ui.components.PosEmptyState
import com.personalos.mobile.ui.components.PosLoadingView
import com.personalos.mobile.ui.components.PosPrimaryButton
import com.personalos.mobile.ui.components.PosSectionHeader
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay
import com.personalos.mobile.ui.theme.posLabel
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddToCvSheet(
    entity: PosEntity,
    repository: PersonalOSRepository,
    onDismiss: () -> Unit,
    onAdded: (PosCvTemplate, PosCvValidateResult?) -> Unit,
) {
    val parsed = remember(entity.content) { parseTechLine(entity.content) }
    var templates by remember { mutableStateOf<List<PosCvTemplate>>(emptyList()) }
    var selectedTemplateId by remember { mutableStateOf<String?>(null) }
    var blockType by remember {
        mutableStateOf(
            if (entity.type.contains("role") || entity.type.contains("employer")) "experience" else "project",
        )
    }
    var stackText by remember { mutableStateOf(parsed.stack.joinToString(", ")) }
    var skillsText by remember { mutableStateOf("") }
    var periodText by remember { mutableStateOf(entityPeriod(entity)) }
    var loading by remember { mutableStateOf(true) }
    var submitting by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var lengthAlert by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    val selectedTemplate = templates.firstOrNull { it.id == selectedTemplateId }

    LaunchedEffect(Unit) {
        runCatching { repository.listCvTemplates() }
            .onSuccess {
                templates = it
                selectedTemplateId = it.firstOrNull { tpl -> tpl.isDefault }?.id ?: it.firstOrNull()?.id
                loading = false
            }
            .onFailure { err -> error = err.message; loading = false }
    }

    lengthAlert?.let { message ->
        AlertDialog(
            onDismissRequest = { lengthAlert = null },
            title = { Text("CV length") },
            text = { Text(message) },
            confirmButton = { TextButton(onClick = { lengthAlert = null }) { Text("OK") } },
        )
    }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState) {
        Column(
            Modifier
                .padding(horizontal = 16.dp)
                .padding(bottom = 28.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text("Add to CV", style = posDisplay(18f))
            when {
                loading -> PosLoadingView()
                error != null -> PosEmptyState("Could not load templates", error.orEmpty(), "Retry") {
                    loading = true
                    scope.launch {
                        runCatching { repository.listCvTemplates() }
                            .onSuccess {
                                templates = it
                                selectedTemplateId = it.firstOrNull { tpl -> tpl.isDefault }?.id ?: it.firstOrNull()?.id
                                error = null
                                loading = false
                            }
                            .onFailure { err -> error = err.message; loading = false }
                    }
                }
                templates.isEmpty() -> PosEmptyState(
                    "No CV templates",
                    "Open CV Transfer once while online to seed your default template.",
                    "Close",
                    onAction = onDismiss,
                )
                else -> {
                    PosCard {
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Text("Work item", style = posLabel(), fontWeight = FontWeight.SemiBold, color = PosTheme.PrimaryDark)
                            Text(cleanCvTitle(entity.title), style = posDisplay(18f))
                            if (parsed.body.isNotBlank()) {
                                Text(parsed.body, color = PosTheme.Muted, maxLines = 6)
                            }
                            if (entity.tagList.isNotEmpty()) {
                                Text(entity.tagList.take(6).joinToString(" · "), style = posLabel(), color = PosTheme.PrimaryDark)
                            }
                        }
                    }
                    PosSectionHeader(title = "Target template", eyebrow = "System or your copy")
                    Row(
                        Modifier.horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        templates.forEach { tpl ->
                            FilterChip(
                                selected = tpl.id == selectedTemplateId,
                                onClick = { selectedTemplateId = tpl.id },
                                label = { Text(if (tpl.isSystem) "★ ${tpl.name}" else tpl.name) },
                            )
                        }
                    }
                    PosSectionHeader(title = "Section", eyebrow = "Where this block lands")
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        listOf("project" to "Project", "experience" to "Experience").forEach { (type, label) ->
                            FilterChip(
                                selected = blockType == type,
                                onClick = { blockType = type },
                                label = { Text(label) },
                            )
                        }
                    }
                    PosCard {
                        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            OutlinedTextField(
                                periodText,
                                { periodText = it },
                                Modifier.fillMaxWidth(),
                                label = { Text("Period") },
                                placeholder = { Text("2025 — Present") },
                            )
                            OutlinedTextField(
                                stackText,
                                { stackText = it },
                                Modifier.fillMaxWidth(),
                                label = { Text("Highlight stack (optional)") },
                                placeholder = { Text("Java, Spring Boot, Kafka") },
                            )
                            OutlinedTextField(
                                skillsText,
                                { skillsText = it },
                                Modifier.fillMaxWidth(),
                                label = { Text("Extra skills for this block (optional)") },
                                placeholder = { Text("JUnit, Docker, Redis") },
                            )
                            Text(
                                "Title and description come from the work item. Skills are free-form tags for this block.",
                                style = posLabel(),
                                color = PosTheme.Muted,
                            )
                        }
                    }
                    selectedTemplate?.let { tpl ->
                        PosCard {
                            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                Text("Template limits", style = posLabel(), fontWeight = FontWeight.SemiBold, color = PosTheme.Muted)
                                Text(
                                    "${tpl.constraints.maxPages} page max · ${tpl.constraints.maxExperience} roles · ${tpl.constraints.maxProjects} projects",
                                    style = posLabel(),
                                )
                                if (tpl.isSystem) {
                                    Text(
                                        "Adding to a system template creates your editable copy automatically.",
                                        style = posLabel(),
                                        color = PosTheme.PrimaryDark,
                                    )
                                }
                            }
                        }
                    }
                    PosPrimaryButton(if (submitting) "Adding…" else "Add block") {
                        val templateId = selectedTemplateId ?: return@PosPrimaryButton
                        submitting = true
                        scope.launch {
                            val overrides = PosCvBlockOverrides(
                                title = cleanCvTitle(entity.title),
                                company = entity.metadata?.company,
                                period = periodText.trim().takeIf { it.isNotEmpty() },
                                highlightStack = splitCsv(stackText).takeIf { it.isNotEmpty() },
                                skillItems = splitCsv(skillsText).takeIf { it.isNotEmpty() },
                            )
                            runCatching {
                                repository.addCvBlockFromEntity(templateId, entity.id, blockType, overrides)
                            }.onSuccess { tpl ->
                                val validation = runCatching {
                                    repository.validateCvTemplate(tpl.id, tpl)
                                }.getOrNull()
                                if (validation != null && !validation.valid) {
                                    lengthAlert = validation.overflows?.joinToString("\n")
                                }
                                onAdded(tpl, validation)
                                onDismiss()
                            }.onFailure { err -> error = err.message }
                            submitting = false
                        }
                    }
                }
            }
        }
    }
}
