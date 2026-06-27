package com.personalos.mobile.ui.features

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.FilterChip
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.personalos.mobile.data.models.PosCvBlock
import com.personalos.mobile.data.models.PosCvTemplate
import com.personalos.mobile.data.models.PosCvValidateResult
import com.personalos.mobile.data.repository.PersonalOSRepository
import com.personalos.mobile.ui.components.PosActionButton
import com.personalos.mobile.ui.components.PosActionStyle
import com.personalos.mobile.ui.components.PosCard
import com.personalos.mobile.ui.components.PosEmptyState
import com.personalos.mobile.ui.components.PosLoadingView
import com.personalos.mobile.ui.components.PosPrimaryButton
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay
import kotlinx.coroutines.launch

@Composable
fun CvHubScreen(
    repository: PersonalOSRepository,
    onClose: () -> Unit,
    initialTemplateId: String? = null,
) {
    var loading by remember { mutableStateOf(true) }
    var templates by remember { mutableStateOf<List<PosCvTemplate>>(emptyList()) }
    var selectedId by remember { mutableStateOf<String?>(null) }
    var template by remember { mutableStateOf<PosCvTemplate?>(null) }
    var validate by remember { mutableStateOf<PosCvValidateResult?>(null) }
    var error by remember { mutableStateOf<String?>(null) }
    var saveError by remember { mutableStateOf<String?>(null) }
    var showCreateDialog by remember { mutableStateOf(false) }
    var newTemplateName by remember { mutableStateOf("") }
    var refiningBlockId by remember { mutableStateOf<String?>(null) }
    var refineDraft by remember { mutableStateOf("") }
    var refineInstruction by remember { mutableStateOf("") }
    var refining by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    fun runValidate(tpl: PosCvTemplate) {
        scope.launch {
            runCatching { repository.validateCvTemplate(tpl.id, tpl) }
                .onSuccess { validate = it }
        }
    }

    fun loadTemplate(id: String) {
        scope.launch {
            loading = true
            runCatching { repository.getCvTemplate(id) }
                .onSuccess {
                    template = it
                    selectedId = id
                    loading = false
                    runValidate(it)
                }
                .onFailure { e -> error = e.message; loading = false }
        }
    }

    fun reloadTemplates(selectId: String? = selectedId) {
        scope.launch {
            loading = true
            runCatching { repository.listCvTemplates() }
                .onSuccess { list ->
                    templates = list
                    val pick = selectId ?: initialTemplateId ?: list.firstOrNull()?.id
                    if (pick != null) loadTemplate(pick) else loading = false
                }
                .onFailure { e -> error = e.message; loading = false }
        }
    }

    LaunchedEffect(Unit) { reloadTemplates() }

    if (showCreateDialog) {
        AlertDialog(
            onDismissRequest = { showCreateDialog = false },
            title = { Text("New CV template") },
            text = {
                OutlinedTextField(
                    newTemplateName,
                    { newTemplateName = it },
                    Modifier.fillMaxWidth(),
                    label = { Text("Name") },
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    val name = newTemplateName.trim()
                    if (name.isEmpty()) return@TextButton
                    scope.launch {
                        runCatching {
                            repository.createCvTemplate(name, cloneId = selectedId.orEmpty())
                        }.onSuccess {
                            showCreateDialog = false
                            newTemplateName = ""
                            reloadTemplates(it.id)
                        }
                    }
                }) { Text("Create") }
            },
            dismissButton = { TextButton(onClick = { showCreateDialog = false }) { Text("Cancel") } },
        )
    }

    refiningBlockId?.let { blockId ->
        AlertDialog(
            onDismissRequest = { if (!refining) refiningBlockId = null },
            title = { Text("AI refine block") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        refineDraft,
                        { refineDraft = it },
                        Modifier.fillMaxWidth(),
                        label = { Text("Content") },
                        minLines = 4,
                    )
                    OutlinedTextField(
                        refineInstruction,
                        { refineInstruction = it },
                        Modifier.fillMaxWidth(),
                        label = { Text("Instruction (optional)") },
                    )
                }
            },
            confirmButton = {
                TextButton(
                    enabled = !refining,
                    onClick = {
                        refining = true
                        scope.launch {
                            runCatching {
                                repository.refineCvBlock(
                                    refineDraft,
                                    refineInstruction.ifBlank { "Professional tone, ATS-friendly, fix grammar, keep facts" },
                                )
                            }.onSuccess { res ->
                                val refined = res.refinedContent?.takeIf { it.isNotBlank() } ?: refineDraft
                                template = template?.let { tpl ->
                                    tpl.copy(blocks = tpl.blocks.map { b ->
                                        if (b.id == blockId) b.copy(content = refined, pendingRaw = null) else b
                                    })
                                }
                                refiningBlockId = null
                            }
                            refining = false
                        }
                    },
                ) { Text(if (refining) "…" else "Apply") }
            },
            dismissButton = {
                TextButton(onClick = { refiningBlockId = null }) { Text("Cancel") }
            },
        )
    }

    FeatureScaffold(
        bottomBar = {
            template?.let { tpl ->
                PosFeatureBottomBar {
                    PosActionButton("Save", style = PosActionStyle.Primary, modifier = Modifier.weight(1f)) {
                        scope.launch {
                            saveError = null
                            runCatching { repository.saveCvTemplate(tpl) }
                                .onSuccess {
                                    template = it
                                    runValidate(it)
                                }
                                .onFailure { saveError = it.message }
                        }
                    }
                    PosActionButton("Validate", style = PosActionStyle.Secondary, modifier = Modifier.weight(1f)) {
                        runValidate(tpl)
                    }
                    PosActionButton("PDF", style = PosActionStyle.Secondary, modifier = Modifier.weight(1f)) {
                        scope.launch {
                            runCatching { context.openPdf(repository.downloadCvPdf(tpl.id)) }
                        }
                    }
                    PosActionButton("Share", style = PosActionStyle.Secondary, modifier = Modifier.weight(1f)) {
                        scope.launch {
                            runCatching {
                                val url = repository.shareCv().url
                                context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                            }
                        }
                    }
                }
            }
        },
    ) {
        when {
            loading && template == null -> PosLoadingView()
            error != null -> PosEmptyState("Could not load CV templates", error.orEmpty(), "Retry") { reloadTemplates() }
            else -> {
                Column(
                    Modifier
                        .verticalScroll(rememberScrollState())
                        .padding(bottom = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        templates.forEach { t ->
                            FilterChip(
                                selected = t.id == selectedId,
                                onClick = { loadTemplate(t.id) },
                                label = { Text(t.name) },
                            )
                        }
                        FilterChip(
                            selected = false,
                            onClick = { showCreateDialog = true },
                            label = { Text("+") },
                            leadingIcon = { androidx.compose.material3.Icon(Icons.Default.Add, contentDescription = null) },
                        )
                    }

                    validate?.let { v ->
                        ValidateBanner(v)
                    }
                    saveError?.let {
                        PosCard {
                            Text(it, color = PosTheme.Error, style = posDisplay(12f))
                        }
                    }

                    template?.let { tpl ->
                        PosCard {
                            Text("Layout: ${tpl.layoutId}", color = PosTheme.Muted, style = posDisplay(11f))
                            Text("${tpl.blocks.count { it.enabled }} active blocks", style = posDisplay(12f))
                        }
                        tpl.blocks.sortedBy { it.order }.forEachIndexed { index, block ->
                            CvBlockCard(
                                block = block,
                                onToggle = { enabled ->
                                    template = tpl.copy(blocks = tpl.blocks.map {
                                        if (it.id == block.id) it.copy(enabled = enabled) else it
                                    })
                                },
                                onEdit = {
                                    refineDraft = block.content.orEmpty()
                                    refineInstruction = ""
                                    refiningBlockId = block.id
                                },
                                onMoveUp = if (index > 0) {
                                    {
                                        val sorted = tpl.blocks.sortedBy { it.order }.toMutableList()
                                        val i = sorted.indexOfFirst { it.id == block.id }
                                        if (i > 0) {
                                            val a = sorted[i - 1].order
                                            sorted[i - 1] = sorted[i - 1].copy(order = sorted[i].order)
                                            sorted[i] = sorted[i].copy(order = a)
                                            template = tpl.copy(blocks = sorted)
                                        }
                                    }
                                } else null,
                                onMoveDown = if (index < tpl.blocks.size - 1) {
                                    {
                                        val sorted = tpl.blocks.sortedBy { it.order }.toMutableList()
                                        val i = sorted.indexOfFirst { it.id == block.id }
                                        if (i >= 0 && i < sorted.lastIndex) {
                                            val a = sorted[i + 1].order
                                            sorted[i + 1] = sorted[i + 1].copy(order = sorted[i].order)
                                            sorted[i] = sorted[i].copy(order = a)
                                            template = tpl.copy(blocks = sorted)
                                        }
                                    }
                                } else null,
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ValidateBanner(result: PosCvValidateResult) {
    val bg = when {
        result.valid -> PosTheme.SuccessBg
        result.pageCount <= result.maxPages + 1 -> PosTheme.Border.copy(0.35f)
        else -> PosTheme.Error.copy(0.12f)
    }
    val color = when {
        result.valid -> PosTheme.Success
        result.pageCount <= result.maxPages + 1 -> PosTheme.PrimaryDark
        else -> PosTheme.Error
    }
    PosCard(modifier = Modifier.background(bg)) {
        Text(
            if (result.valid) "Fits ${result.maxPages} page(s) · ${result.pageCount} page PDF"
            else "Overflow · ${result.pageCount}/${result.maxPages} pages",
            color = color,
            fontWeight = FontWeight.SemiBold,
            style = posDisplay(12f),
        )
        result.overflows?.forEach { Text("• $it", color = color, style = posDisplay(11f)) }
        result.suggestions?.forEach { Text("→ $it", color = PosTheme.Muted, style = posDisplay(11f)) }
    }
}

@Composable
private fun CvBlockCard(
    block: PosCvBlock,
    onToggle: (Boolean) -> Unit,
    onEdit: () -> Unit,
    onMoveUp: (() -> Unit)?,
    onMoveDown: (() -> Unit)?,
) {
    val title = block.overrides?.title?.takeIf { it.isNotBlank() }
        ?: block.type.replaceFirstChar { it.uppercase() }
    PosCard {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(title, fontWeight = FontWeight.SemiBold, style = posDisplay(13f))
                Text(block.type, color = PosTheme.Muted, style = posDisplay(10f))
            }
            Switch(checked = block.enabled, onCheckedChange = onToggle)
        }
        block.overrides?.company?.takeIf { it.isNotBlank() }?.let {
            Text(it, color = PosTheme.Muted, style = posDisplay(11f))
        }
        block.content?.takeIf { it.isNotBlank() }?.let {
            Text(it, maxLines = 4, style = posDisplay(11f), modifier = Modifier.padding(top = 6.dp))
        }
        block.overrides?.highlightStack?.takeIf { it.isNotEmpty() }?.let {
            Text("Stack: ${it.joinToString(", ")}", color = PosTheme.PrimaryDark, style = posDisplay(10f))
        }
        Row(Modifier.padding(top = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            PosPrimaryButton("Edit + refine") { onEdit() }
            onMoveUp?.let {
                PosActionButton("Up", style = PosActionStyle.Secondary, icon = Icons.Default.ArrowUpward, onClick = it)
            }
            onMoveDown?.let {
                PosActionButton("Down", style = PosActionStyle.Secondary, icon = Icons.Default.ArrowDownward, onClick = it)
            }
        }
    }
}

private fun android.content.Context.openPdf(bytes: ByteArray) {
    val file = java.io.File(cacheDir, "cv-export.pdf")
    file.writeBytes(bytes)
    val uri = androidx.core.content.FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
    startActivity(Intent(Intent.ACTION_VIEW).setDataAndType(uri, "application/pdf").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
}
