package com.personalos.mobile.ui.features

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import com.personalos.mobile.data.models.PosCvBlockOverrides
import com.personalos.mobile.data.models.PosCvSkillGroup
import com.personalos.mobile.data.models.PosCvTemplate
import com.personalos.mobile.data.models.PosCvValidateResult
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

private data class CvSectionMeta(val type: String, val title: String, val eyebrow: String)

private val cvSectionOrder = listOf(
    CvSectionMeta("summary", "Profile", "Headline & summary"),
    CvSectionMeta("contact", "Contact", "Reach you"),
    CvSectionMeta("skills", "Skills & stack", "Primary focus"),
    CvSectionMeta("achievements", "Highlights", "Key wins"),
    CvSectionMeta("education", "Education", "Degrees & schools"),
    CvSectionMeta("certificates", "Certificates", "Credentials"),
    CvSectionMeta("experience", "Experience", "Roles"),
    CvSectionMeta("project", "Projects", "Featured work"),
)

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
    var forkNotice by remember { mutableStateOf<String?>(null) }
    var showCreateDialog by remember { mutableStateOf(false) }
    var newTemplateName by remember { mutableStateOf("") }
    var refiningBlockId by remember { mutableStateOf<String?>(null) }
    var refiningBlockType by remember { mutableStateOf<String?>(null) }
    var refineDraft by remember { mutableStateOf("") }
    var refineInstruction by remember { mutableStateOf("") }
    var contactEmailDraft by remember { mutableStateOf("") }
    var contactPhoneDraft by remember { mutableStateOf("") }
    var contactLocationDraft by remember { mutableStateOf("") }
    var contactLinkedInDraft by remember { mutableStateOf("") }
    var contactGitHubDraft by remember { mutableStateOf("") }
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
            forkNotice = null
            runCatching { repository.getCvTemplate(id) }
                .onSuccess { loaded ->
                    var tpl = loaded
                    if (tpl.blocks.isEmpty()) {
                        tpl = runCatching { repository.syncCvSystemTemplates() }
                            .getOrNull()
                            ?.let { synced ->
                                templates = synced
                                synced.firstOrNull { it.id == id } ?: synced.firstOrNull { it.isDefault }
                            }
                            ?: tpl
                        if (tpl.blocks.isEmpty()) {
                            val blocks = runCatching { repository.fetchCv() }
                                .getOrNull()
                                ?.let { CvDocumentBlocks.build(it.document) }
                                .orEmpty()
                            if (blocks.isNotEmpty()) tpl = tpl.copy(blocks = blocks)
                        }
                    }
                    template = tpl
                    selectedId = id
                    loading = false
                    runValidate(tpl)
                }
                .onFailure { e -> error = e.message; loading = false }
        }
    }

    suspend fun fetchTemplatesWithBootstrap(): List<PosCvTemplate> {
        var list = repository.listCvTemplates()
        if (list.all { it.blocks.isEmpty() }) {
            list = runCatching { repository.syncCvSystemTemplates() }.getOrDefault(list)
        }
        if (list.all { it.blocks.isEmpty() }) {
            val bootstrapped = runCatching { repository.fetchCv() }
                .getOrNull()
                ?.let { CvDocumentBlocks.bootstrapDefaultTemplate(it) }
            if (bootstrapped != null) list = listOf(bootstrapped)
        }
        return list
    }

    fun reloadTemplates(selectId: String? = selectedId) {
        scope.launch {
            loading = true
            runCatching { fetchTemplatesWithBootstrap() }
                .onSuccess { list ->
                    templates = list
                    val pick = selectId
                        ?: initialTemplateId
                        ?: list.firstOrNull { it.isDefault }?.id
                        ?: list.firstOrNull()?.id
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
        val isContact = refiningBlockType == "contact"
        AlertDialog(
            onDismissRequest = { if (!refining) refiningBlockId = null },
            title = { Text(if (isContact) "Edit contact" else "AI refine block") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (isContact) {
                        OutlinedTextField(contactEmailDraft, { contactEmailDraft = it }, Modifier.fillMaxWidth(), label = { Text("Email") })
                        OutlinedTextField(contactPhoneDraft, { contactPhoneDraft = it }, Modifier.fillMaxWidth(), label = { Text("Phone") })
                        OutlinedTextField(contactLocationDraft, { contactLocationDraft = it }, Modifier.fillMaxWidth(), label = { Text("Location") })
                        OutlinedTextField(contactLinkedInDraft, { contactLinkedInDraft = it }, Modifier.fillMaxWidth(), label = { Text("LinkedIn") })
                        OutlinedTextField(contactGitHubDraft, { contactGitHubDraft = it }, Modifier.fillMaxWidth(), label = { Text("GitHub") })
                    } else {
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
                }
            },
            confirmButton = {
                TextButton(
                    enabled = !refining,
                    onClick = {
                        if (isContact) {
                            val overrides = PosCvBlockOverrides(
                                email = contactEmailDraft.trim(),
                                phone = contactPhoneDraft.trim(),
                                location = contactLocationDraft.trim(),
                                linkedin = contactLinkedInDraft.trim(),
                                github = contactGitHubDraft.trim(),
                            )
                            val content = listOfNotNull(
                                overrides.email?.takeIf { it.isNotBlank() },
                                overrides.phone?.takeIf { it.isNotBlank() },
                                overrides.location?.takeIf { it.isNotBlank() },
                                overrides.linkedin?.takeIf { it.isNotBlank() },
                                overrides.github?.takeIf { it.isNotBlank() },
                            ).joinToString(" · ")
                            template = template?.let { tpl ->
                                tpl.copy(blocks = tpl.blocks.map { b ->
                                    if (b.id == blockId) b.copy(content = content, overrides = overrides, pendingRaw = null) else b
                                })
                            }
                            refiningBlockId = null
                        } else {
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
                PosCvBottomBar(
                    saveTitle = if (tpl.isSystem) "Save as My CV" else "Save",
                    isSystem = tpl.isSystem,
                    isExporting = false,
                    onSave = {
                        scope.launch {
                            saveError = null
                            val wasSystem = tpl.isSystem
                            runCatching { repository.saveCvTemplate(tpl) }
                                .onSuccess {
                                    template = it
                                    selectedId = it.id
                                    if (wasSystem) {
                                        forkNotice = "Saved as “${it.name}”. System template unchanged."
                                        reloadTemplates(it.id)
                                    } else {
                                        runValidate(it)
                                    }
                                }
                                .onFailure { saveError = it.message }
                        }
                    },
                    onValidate = { runValidate(tpl) },
                    onPdf = {
                        scope.launch {
                            runCatching { context.openPdf(repository.downloadCvPdf(tpl.id)) }
                        }
                    },
                    onShare = {
                        scope.launch {
                            runCatching {
                                val url = repository.shareCv().url
                                context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                            }
                        }
                    },
                )
            }
        },
    ) {
        when {
            loading && template == null -> PosLoadingView()
            error != null -> PosEmptyState("Could not load CV templates", error.orEmpty(), "Retry") { reloadTemplates() }
            else -> {
                Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    HeroHeader(template?.name)
                    TemplatePicker(templates, selectedId, onSelect = { loadTemplate(it) }, onCreate = { showCreateDialog = true })
                    validate?.let { v -> ValidateBanner(v, template) }
                    forkNotice?.let { notice ->
                        PosCard {
                            Text(notice, style = posLabel(), fontWeight = FontWeight.SemiBold, color = PosTheme.PrimaryDark)
                        }
                    }
                    saveError?.let {
                        PosCard {
                            Text(it, color = PosTheme.Error, style = posDisplay(12f))
                        }
                    }
                    template?.let { tpl ->
                        ConstraintsCard(tpl)
                        if (tpl.blocks.isEmpty()) {
                            PosEmptyState(
                                "No blocks yet",
                                "Pull to refresh or pick ★ Professional CV (1 page) after the server seeds your CV.",
                                "Retry",
                            ) { reloadTemplates(tpl.id) }
                        } else {
                            TemplateSections(
                                tpl = tpl,
                                onTemplateChange = { template = it },
                                onEditBlock = { block ->
                                    refiningBlockType = block.type
                                    if (block.type == "contact") {
                                        contactEmailDraft = block.overrides?.email.orEmpty()
                                        contactPhoneDraft = block.overrides?.phone.orEmpty()
                                        contactLocationDraft = block.overrides?.location.orEmpty()
                                        contactLinkedInDraft = block.overrides?.linkedin.orEmpty()
                                        contactGitHubDraft = block.overrides?.github.orEmpty()
                                    } else {
                                        refineDraft = block.content.orEmpty()
                                        refineInstruction = ""
                                    }
                                    refiningBlockId = block.id
                                },
                            )
                        }
                    }
                    if (template == null && !loading) {
                        PosEmptyState(
                            "No CV template yet",
                            "Create a template or wait for the server to seed your default CV.",
                            "Create template",
                        ) { showCreateDialog = true }
                    }
                }
            }
        }
    }
}

@Composable
private fun HeroHeader(templateName: String?) {
    PosCard {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("CV Transfer", style = posLabel(), fontWeight = FontWeight.SemiBold, color = PosTheme.PrimaryDark)
            Text(templateName ?: "Your resume workspace", style = posDisplay(22f))
            Text(
                "System templates stay as recommendations. Edits save as your own copy with length checks.",
                color = PosTheme.Muted,
            )
        }
    }
}

@Composable
private fun TemplatePicker(
    templates: List<PosCvTemplate>,
    selectedId: String?,
    onSelect: (String) -> Unit,
    onCreate: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        PosSectionHeader(title = "Templates", eyebrow = "Default · AI · yours")
        Row(
            Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            templates.forEach { t ->
                FilterChip(
                    selected = t.id == selectedId,
                    onClick = { onSelect(t.id) },
                    label = { Text(if (t.isSystem) "★ ${t.name}" else t.name) },
                )
            }
            FilterChip(
                selected = false,
                onClick = onCreate,
                label = { Text("New") },
                leadingIcon = { androidx.compose.material3.Icon(Icons.Default.Add, contentDescription = null) },
            )
        }
    }
}

@Composable
private fun ConstraintsCard(tpl: PosCvTemplate) {
    PosCard {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    tpl.layoutId.replace('_', ' '),
                    style = posLabel(),
                    fontWeight = FontWeight.SemiBold,
                    color = PosTheme.Muted,
                )
                Text("${tpl.blocks.count { it.enabled }} active blocks", style = posDisplay(12f))
            }
            if (tpl.isSystem) {
                Text(
                    "System",
                    style = posLabel(),
                    fontWeight = FontWeight.Bold,
                    color = PosTheme.PrimaryDark,
                    modifier = Modifier
                        .background(PosTheme.PrimaryDark.copy(alpha = 0.12f))
                        .padding(horizontal = 8.dp, vertical = 4.dp),
                )
            }
        }
    }
}

@Composable
private fun TemplateSections(
    tpl: PosCvTemplate,
    onTemplateChange: (PosCvTemplate) -> Unit,
    onEditBlock: (PosCvBlock) -> Unit,
) {
    val grouped = tpl.blocks.sortedBy { it.order }.groupBy { it.type }
    cvSectionOrder.forEach { meta ->
        val blocks = grouped[meta.type].orEmpty()
        if (blocks.isNotEmpty()) {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                PosSectionHeader(title = meta.title, eyebrow = meta.eyebrow)
                blocks.forEach { block ->
                    val sorted = tpl.blocks.sortedBy { it.order }
                    val globalIndex = sorted.indexOfFirst { it.id == block.id }
                    CvBlockCard(
                        block = block,
                        onToggle = { enabled ->
                            onTemplateChange(
                                tpl.copy(blocks = tpl.blocks.map {
                                    if (it.id == block.id) it.copy(enabled = enabled) else it
                                }),
                            )
                        },
                        onEdit = { onEditBlock(block) },
                        onMoveUp = if (globalIndex > 0) {
                            {
                                val list = sorted.toMutableList()
                                val i = list.indexOfFirst { it.id == block.id }
                                if (i > 0) {
                                    val a = list[i - 1].order
                                    list[i - 1] = list[i - 1].copy(order = list[i].order)
                                    list[i] = list[i].copy(order = a)
                                    onTemplateChange(tpl.copy(blocks = list))
                                }
                            }
                        } else null,
                        onMoveDown = if (globalIndex >= 0 && globalIndex < sorted.lastIndex) {
                            {
                                val list = sorted.toMutableList()
                                val i = list.indexOfFirst { it.id == block.id }
                                if (i >= 0 && i < list.lastIndex) {
                                    val a = list[i + 1].order
                                    list[i + 1] = list[i + 1].copy(order = list[i].order)
                                    list[i] = list[i].copy(order = a)
                                    onTemplateChange(tpl.copy(blocks = list))
                                }
                            }
                        } else null,
                    )
                }
            }
        }
    }
}

@Composable
private fun ValidateBanner(result: PosCvValidateResult, template: PosCvTemplate?) {
    val nearOverflow = !result.valid && result.pageCount <= result.maxPages + 1
    val bg = when {
        result.valid -> PosTheme.SuccessBg
        nearOverflow -> PosTheme.Border.copy(0.35f)
        else -> PosTheme.Error.copy(0.12f)
    }
    val color = when {
        result.valid -> PosTheme.Success
        nearOverflow -> PosTheme.PrimaryDark
        else -> PosTheme.Error
    }
    PosCard(modifier = Modifier.background(bg)) {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                if (result.valid) "Fits ${result.maxPages} page(s) · ${result.pageCount} page PDF"
                else "Overflow · ${result.pageCount}/${result.maxPages} pages",
                color = color,
                fontWeight = FontWeight.SemiBold,
                style = posDisplay(12f),
            )
            template?.let {
                Text(
                    "Limits: ${it.constraints.maxPages} page · max ${it.constraints.maxExperience} roles · max ${it.constraints.maxProjects} projects",
                    style = posLabel(),
                    color = PosTheme.Muted,
                )
            }
            result.overflows?.forEach { Text("• $it", color = color, style = posDisplay(11f)) }
            result.suggestions?.forEach { Text("→ $it", color = PosTheme.Muted, style = posDisplay(11f)) }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun CvBlockCard(
    block: PosCvBlock,
    onToggle: (Boolean) -> Unit,
    onEdit: () -> Unit,
    onMoveUp: (() -> Unit)?,
    onMoveDown: (() -> Unit)?,
) {
    val title = when (block.type) {
        "contact" -> "Contact"
        "summary" -> "Profile"
        else -> block.overrides?.title?.takeIf { it.isNotBlank() }
            ?: block.type.replaceFirstChar { it.uppercase() }
    }
    PosCard {
        Column(
            modifier = Modifier.fillMaxWidth().then(
                if (block.enabled) Modifier else Modifier.background(PosTheme.Border.copy(alpha = 0.08f)),
            ),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.Top) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(title, fontWeight = FontWeight.SemiBold, style = posDisplay(13f))
                    block.overrides?.period?.takeIf { it.isNotBlank() }?.let {
                        Text(it, color = PosTheme.Muted, style = posDisplay(11f))
                    }
                }
                Switch(checked = block.enabled, onCheckedChange = onToggle)
            }
            block.overrides?.company?.takeIf { it.isNotBlank() }?.let {
                Text(it, color = PosTheme.Muted, style = posDisplay(11f))
            }
            when {
                block.type == "skills" && !block.skillGroups.isNullOrEmpty() -> {
                    block.overrides?.skillItems?.takeIf { it.isNotEmpty() }?.let { focus ->
                        Text("Primary focus", style = posLabel(), fontWeight = FontWeight.SemiBold, color = PosTheme.PrimaryDark)
                        SkillChips(focus)
                    }
                    block.skillGroups.orEmpty().forEach { group -> SkillGroupBlock(group) }
                }
                block.type == "contact" -> ContactBlockBody(block)
                !block.content.isNullOrBlank() -> {
                    Text(
                        block.content.orEmpty(),
                        maxLines = if (block.type == "summary") 8 else 5,
                        style = posDisplay(11f),
                    )
                }
            }
            block.overrides?.highlightStack?.takeIf { it.isNotEmpty() }?.let {
                SkillChips(it)
            }
            block.overrides?.skillItems?.takeIf { it.isNotEmpty() && block.type != "skills" }?.let {
                SkillChips(it)
            }
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                PosPrimaryButton(if (block.type == "contact") "Edit" else "Refine", modifier = Modifier.weight(1f), onClick = onEdit)
                onMoveUp?.let {
                    IconButton(onClick = it) {
                        Icon(Icons.Default.ArrowUpward, contentDescription = "Move up", tint = PosTheme.Ink)
                    }
                }
                onMoveDown?.let {
                    IconButton(onClick = it) {
                        Icon(Icons.Default.ArrowDownward, contentDescription = "Move down", tint = PosTheme.Ink)
                    }
                }
            }
        }
    }
}

@Composable
private fun ContactBlockBody(block: PosCvBlock) {
    val o = block.overrides
    if (o != null) {
        listOf(
            "Email" to o.email,
            "Phone" to o.phone,
            "Location" to o.location,
            "LinkedIn" to o.linkedin,
            "GitHub" to o.github,
        ).forEach { (label, value) ->
            value?.takeIf { it.isNotBlank() }?.let {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("$label:", style = posLabel(), fontWeight = FontWeight.SemiBold, color = PosTheme.Muted)
                    Text(it, style = posDisplay(11f))
                }
            }
        }
    } else if (!block.content.isNullOrBlank()) {
        Text(block.content.orEmpty(), style = posDisplay(11f))
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun SkillGroupBlock(group: PosCvSkillGroup) {
    Text(group.category, style = posLabel(), fontWeight = FontWeight.SemiBold, color = PosTheme.Muted)
    SkillChips(group.items)
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun SkillChips(items: List<String>) {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        items.forEach { item ->
            Text(
                item,
                style = posLabel(),
                fontWeight = FontWeight.Medium,
                modifier = Modifier
                    .background(PosTheme.Border.copy(alpha = 0.35f))
                    .padding(horizontal = 8.dp, vertical = 4.dp),
            )
        }
    }
}

private fun android.content.Context.openPdf(bytes: ByteArray) {
    val file = java.io.File(cacheDir, "cv-export.pdf")
    file.writeBytes(bytes)
    val uri = androidx.core.content.FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
    startActivity(Intent(Intent.ACTION_VIEW).setDataAndType(uri, "application/pdf").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
}
