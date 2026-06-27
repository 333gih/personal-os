package com.personalos.mobile.ui.features

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.FilterChip
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.FileUpload
import androidx.compose.material.icons.filled.PersonSearch
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.Work
import com.personalos.mobile.data.models.PosCvContact
import com.personalos.mobile.data.models.PosCvDocument
import com.personalos.mobile.data.models.PosCvSuggestedSkill
import com.personalos.mobile.data.models.PosEntity
import com.personalos.mobile.data.models.PosJobSearchPreferences
import com.personalos.mobile.data.models.PosJobTab
import com.personalos.mobile.data.models.PosLearningTrack
import com.personalos.mobile.data.models.PosPracticeMode
import com.personalos.mobile.data.repository.PersonalOSRepository
import com.personalos.mobile.ui.components.PosCard
import com.personalos.mobile.ui.components.PosEmptyState
import com.personalos.mobile.ui.components.PosListRow
import com.personalos.mobile.ui.components.PosLoadingView
import com.personalos.mobile.ui.components.PosMetricCard
import androidx.compose.ui.text.font.FontWeight
import com.personalos.mobile.ui.components.PosActionButton
import com.personalos.mobile.ui.components.PosActionStyle
import com.personalos.mobile.ui.components.PosHubMenuRow
import com.personalos.mobile.ui.components.PosPrimaryButton
import com.personalos.mobile.ui.components.PosSectionHeader
import com.personalos.mobile.ui.navigation.AppNavigator
import com.personalos.mobile.ui.navigation.EntityRoute
import com.personalos.mobile.ui.navigation.WebRoute
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay
import kotlinx.coroutines.launch

@Composable
fun CvHubScreen(repository: PersonalOSRepository, onClose: () -> Unit) {
    var loading by remember { mutableStateOf(true) }
    var doc by remember { mutableStateOf<PosCvDocument?>(null) }
    var source by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }
    var refineInstruction by remember { mutableStateOf("") }
    var refineReply by remember { mutableStateOf<String?>(null) }
    var selectedSection by remember { mutableStateOf("summary") }
    var primaryStack by remember { mutableStateOf("") }
    var suggestions by remember { mutableStateOf<List<PosCvSuggestedSkill>>(emptyList()) }
    var loadingSuggestions by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    fun reload() {
        scope.launch {
            loading = true
            runCatching { repository.fetchCv() }
                .onSuccess {
                    doc = it.document
                    source = it.source
                    primaryStack = it.document.primaryStack?.joinToString(" · ").orEmpty()
                    loading = false
                    loadSuggestions(repository, scope) { loadingSuggestions = it.first; suggestions = it.second; primaryStack = it.third.ifBlank { primaryStack } }
                }
                .onFailure { error = it.message; loading = false }
        }
    }

    LaunchedEffect(Unit) { reload() }

    FeatureScaffold(
        bottomBar = {
            if (doc != null) {
                PosFeatureBottomBar {
                    PosActionButton("Save", style = PosActionStyle.Primary, modifier = Modifier.weight(1f)) {
                        scope.launch { doc?.let { repository.saveCv(it) } }
                    }
                    PosActionButton("PDF", style = PosActionStyle.Secondary, modifier = Modifier.weight(1f)) {
                        scope.launch { runCatching { context.openPdf(repository.downloadCvPdf()) } }
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
            loading -> PosLoadingView()
            error != null -> PosEmptyState("Could not load CV", error.orEmpty(), "Retry") { reload() }
            doc != null -> {
                val d = doc!!
                PosCard {
                    Text("Ideal CV", color = PosTheme.PrimaryDark, style = posDisplay(12f))
                    OutlinedTextField(d.headline, { doc = d.copy(headline = it) }, Modifier.fillMaxWidth(), label = { Text("Headline") })
                    OutlinedTextField(d.summary, { doc = d.copy(summary = it) }, Modifier.fillMaxWidth(), label = { Text("Summary") }, minLines = 3)
                    val contact = d.contact ?: PosCvContact()
                    OutlinedTextField(contact.email.orEmpty(), { doc = d.copy(contact = contact.copy(email = it)) }, Modifier.fillMaxWidth(), label = { Text("Email") })
                    OutlinedTextField(contact.phone.orEmpty(), { doc = d.copy(contact = contact.copy(phone = it)) }, Modifier.fillMaxWidth(), label = { Text("Phone") })
                    OutlinedTextField(contact.location.orEmpty(), { doc = d.copy(contact = contact.copy(location = it)) }, Modifier.fillMaxWidth(), label = { Text("Location") })
                    OutlinedTextField(contact.linkedin.orEmpty(), { doc = d.copy(contact = contact.copy(linkedin = it)) }, Modifier.fillMaxWidth(), label = { Text("LinkedIn") })
                    OutlinedTextField(contact.github.orEmpty(), { doc = d.copy(contact = contact.copy(github = it)) }, Modifier.fillMaxWidth(), label = { Text("GitHub") })
                    if (source.isNotBlank()) Text(if (source == "ideal") "Pre-built ideal resume" else "Assembled from career entries", color = PosTheme.Muted, style = posDisplay(11f))
                }
                d.experience?.takeIf { it.isNotEmpty() }?.let { bullets ->
                    PosCard {
                        Text("Experience", color = PosTheme.PrimaryDark, style = posDisplay(12f))
                        bullets.forEachIndexed { index, bullet ->
                            OutlinedTextField(bullet.content, { value ->
                                val updated = bullets.toMutableList()
                                updated[index] = bullet.copy(content = value)
                                doc = d.copy(experience = updated)
                            }, Modifier.fillMaxWidth(), label = { Text(bullet.title) }, minLines = 2)
                        }
                    }
                }
                d.projects?.takeIf { it.isNotEmpty() }?.let { bullets ->
                    PosCard {
                        Text("Projects", color = PosTheme.PrimaryDark, style = posDisplay(12f))
                        bullets.forEachIndexed { index, bullet ->
                            OutlinedTextField(bullet.content, { value ->
                                val updated = bullets.toMutableList()
                                updated[index] = bullet.copy(content = value)
                                doc = d.copy(projects = updated)
                            }, Modifier.fillMaxWidth(), label = { Text(bullet.title) }, minLines = 2)
                        }
                    }
                }
                d.education?.takeIf { it.isNotEmpty() }?.let { items ->
                    PosCard {
                        Text("Education", color = PosTheme.PrimaryDark, style = posDisplay(12f))
                        items.forEach { edu ->
                            Text("${edu.school} · ${edu.degree.orEmpty()}", fontWeight = FontWeight.Medium)
                            edu.content?.let { Text(it, color = PosTheme.Muted, style = posDisplay(11f)) }
                        }
                    }
                }
                d.achievements?.takeIf { it.isNotEmpty() }?.let { items ->
                    PosCard {
                        Text("Achievements", color = PosTheme.PrimaryDark, style = posDisplay(12f))
                        items.forEach { Text("• ${it.content}") }
                    }
                }
                d.certificates?.takeIf { it.isNotEmpty() }?.let { items ->
                    PosCard {
                        Text("Certificates", color = PosTheme.PrimaryDark, style = posDisplay(12f))
                        items.forEach { cert -> Text("${cert.title} · ${cert.issuer.orEmpty()}") }
                    }
                }
                PosCard {
                    Text("AI CV coach", color = PosTheme.PrimaryDark, style = posDisplay(12f))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        listOf("summary", "experience", "projects").forEach { sec ->
                            FilterChip(selected = selectedSection == sec, onClick = { selectedSection = sec }, label = { Text(sec) })
                        }
                    }
                    OutlinedTextField(refineInstruction, { refineInstruction = it }, Modifier.fillMaxWidth(), label = { Text("Refine instruction") }, minLines = 2)
                    PosPrimaryButton("Refine with AI") {
                        scope.launch {
                            val content = when (selectedSection) {
                                "experience" -> (d.experience ?: emptyList()).joinToString("\n") { "${it.title}: ${it.content}" }
                                "projects" -> (d.projects ?: emptyList()).joinToString("\n") { "${it.title}: ${it.content}" }
                                else -> d.summary
                            }
                            runCatching { repository.refineCv(refineInstruction, selectedSection, content) }
                                .onSuccess {
                                    refineReply = it.reply
                                    if (selectedSection == "summary" && !it.refinedContent.isNullOrBlank()) {
                                        doc = d.copy(summary = it.refinedContent)
                                    }
                                }
                        }
                        Unit
                    }
                    refineReply?.let { Text(it, style = posDisplay(12f)) }
                }
                if (primaryStack.isNotBlank()) {
                    PosCard {
                        Text("Primary stack (Job Scout)", style = posDisplay(12f), color = PosTheme.PrimaryDark)
                        Text(primaryStack)
                    }
                }
                PosCard {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("AI skill suggestions", style = posDisplay(12f), color = PosTheme.PrimaryDark)
                        PosPrimaryButton(if (loadingSuggestions) "…" else "Refresh") {
                            loadSuggestions(repository, scope) { loadingSuggestions = it.first; suggestions = it.second; primaryStack = it.third.ifBlank { primaryStack } }
                            Unit
                        }
                    }
                    if (suggestions.isEmpty()) {
                        Text("Refresh to get AI suggestions from your experience.", color = PosTheme.Muted, style = posDisplay(11f))
                    } else {
                        PosChipFlow(suggestions.map { "${it.skill} (${it.category})" }) { label ->
                            val item = suggestions.firstOrNull { "${it.skill} (${it.category})" == label } ?: return@PosChipFlow
                            scope.launch {
                                runCatching { repository.addCvSkill(item.category, item.skill) }
                                    .onSuccess { doc = it.document; suggestions = suggestions.filterNot { s -> s.category == item.category && s.skill == item.skill } }
                            }
                        }
                    }
                }
                d.skillGroups?.forEach { group ->
                    PosCard {
                        Text(group.category, style = posDisplay(12f), color = PosTheme.PrimaryDark)
                        Text(group.items.joinToString(", "))
                    }
                }
            }
        }
    }
}

private fun loadSuggestions(
    repository: PersonalOSRepository,
    scope: kotlinx.coroutines.CoroutineScope,
    onResult: (Triple<Boolean, List<PosCvSuggestedSkill>, String>) -> Unit,
) {
    scope.launch {
        onResult(Triple(true, emptyList(), ""))
        runCatching { repository.suggestCvSkills() }
            .onSuccess {
                onResult(Triple(false, it.suggestions, it.primaryStack?.joinToString(" · ").orEmpty()))
            }
            .onFailure { onResult(Triple(false, emptyList(), "")) }
    }
}

@Composable
fun JobScoutScreen(repository: PersonalOSRepository, onClose: () -> Unit) {
    var tab by remember { mutableStateOf(PosJobTab.OPEN) }
    var openJobs by remember { mutableStateOf(emptyList<com.personalos.mobile.data.models.PosJobOpportunity>()) }
    var appliedJobs by remember { mutableStateOf(emptyList<com.personalos.mobile.data.models.PosJobOpportunity>()) }
    var prefs by remember { mutableStateOf(PosJobSearchPreferences()) }
    var customSkill by remember { mutableStateOf("") }
    var loading by remember { mutableStateOf(true) }
    var scanning by remember { mutableStateOf(false) }
    var savingPrefs by remember { mutableStateOf(false) }
    var showPrefs by remember { mutableStateOf(false) }
    var scanSummary by remember { mutableStateOf<String?>(null) }
    var error by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val visible = if (tab == PosJobTab.OPEN) openJobs else appliedJobs

    fun reloadJobs() {
        scope.launch {
            runCatching {
                repository.fetchJobs("open") to repository.fetchJobs("applied")
            }.onSuccess { (open, applied) ->
                openJobs = open
                appliedJobs = applied
            }
        }
    }

    LaunchedEffect(Unit) {
        runCatching { repository.fetchJobPreferences() }
            .onSuccess { prefs = it }
        reloadJobs()
        loading = false
    }

    FeatureScaffold {
        if (loading) PosLoadingView() else {
            PosCard {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("Job search preferences", color = PosTheme.PrimaryDark, style = posDisplay(12f))
                    PosPrimaryButton(if (showPrefs) "Hide" else "Show") { showPrefs = !showPrefs }
                }
                if (showPrefs) {
                    OutlinedTextField(prefs.targetRole, { prefs = prefs.copy(targetRole = it) }, Modifier.fillMaxWidth(), label = { Text("Target role") })
                    Text("Years: ${"%.1f".format(prefs.yearsExperience)}")
                    Row {
                        PosPrimaryButton("-") { if (prefs.yearsExperience > 0f) prefs = prefs.copy(yearsExperience = prefs.yearsExperience - 0.5f) }
                        PosPrimaryButton("+") { if (prefs.yearsExperience < 25f) prefs = prefs.copy(yearsExperience = prefs.yearsExperience + 0.5f) }
                    }
                    val skillPool = ((prefs.availableSkills ?: emptyList()) + prefs.focusSkills).distinctBy { it.lowercase() }.sorted()
                    Text("Main focus (stack)", style = posDisplay(12f))
                    PosChipFlow(skillPool, prefs.focusSkills.toSet()) { skill ->
                        val selected = prefs.focusSkills.any { it.equals(skill, ignoreCase = true) }
                        prefs = if (selected) prefs.copy(focusSkills = prefs.focusSkills.filterNot { it.equals(skill, ignoreCase = true) })
                        else prefs.copy(focusSkills = prefs.focusSkills + skill)
                    }
                    Row {
                        OutlinedTextField(customSkill, { customSkill = it }, Modifier.weight(1f), label = { Text("Custom skill") })
                        PosPrimaryButton("Add") {
                            val s = customSkill.trim()
                            if (s.isNotEmpty()) {
                                val avail = (prefs.availableSkills ?: emptyList()).toMutableList()
                                if (avail.none { it.equals(s, ignoreCase = true) }) avail.add(s)
                                val focus = prefs.focusSkills.toMutableList()
                                if (focus.none { it.equals(s, ignoreCase = true) }) focus.add(s)
                                prefs = prefs.copy(availableSkills = avail, focusSkills = focus)
                                customSkill = ""
                            }
                        }
                    }
                    Text("Work location", style = posDisplay(12f))
                    PosChipFlow(listOf("remote", "hybrid", "onsite", "anywhere"), prefs.workLocationTypes.toSet()) { loc ->
                        val on = prefs.workLocationTypes.contains(loc)
                        prefs = prefs.copy(workLocationTypes = if (on) prefs.workLocationTypes - loc else prefs.workLocationTypes + loc)
                    }
                    PosPrimaryButton(if (savingPrefs) "Saving…" else "Save preferences") {
                        savingPrefs = true
                        scope.launch {
                            runCatching { repository.saveJobPreferences(prefs) }.onSuccess { prefs = it }
                            savingPrefs = false
                        }
                        Unit
                    }
                } else {
                    Text("${prefs.targetRole} · ${"%.1f".format(prefs.yearsExperience)} yrs · ${prefs.focusSkills.joinToString(" · ")}")
                }
            }
            scanSummary?.let { Text(it, color = PosTheme.Success, style = posDisplay(12f)) }
            error?.let { Text(it, color = PosTheme.Error) }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(selected = tab == PosJobTab.OPEN, onClick = { tab = PosJobTab.OPEN }, label = { Text("Open") })
                FilterChip(selected = tab == PosJobTab.APPLIED, onClick = { tab = PosJobTab.APPLIED }, label = { Text("Applied") })
            }
            PosPrimaryButton(if (scanning) "Scanning…" else "Scan jobs") {
                scanning = true
                scope.launch {
                    runCatching {
                        repository.saveJobPreferences(prefs)
                        repository.scanJobs()
                    }.onSuccess { result ->
                        val pct = ((result.minScore ?: 0.35f) * 100).toInt()
                        scanSummary = "Scanned ${result.found} · ${result.matched} matched ≥$pct% · ${result.stored} new"
                        reloadJobs()
                    }.onFailure { error = it.message }
                    scanning = false
                }
                Unit
            }
            if (visible.isEmpty()) {
                PosEmptyState(
                    if (tab == PosJobTab.OPEN) "No matching jobs yet" else "No applied jobs",
                    if (tab == PosJobTab.OPEN) "Save preferences, then Scan." else "Jobs you mark applied appear here.",
                    if (tab == PosJobTab.OPEN) "Scan now" else null,
                    onAction = if (tab == PosJobTab.OPEN) {
                        { scanning = true; scope.launch { runCatching { repository.scanJobs() }.onSuccess { reloadJobs() }; scanning = false }; Unit }
                    } else null,
                )
            } else visible.forEach { job ->
                PosCard {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text(job.title, style = posDisplay(14f))
                        Text("${(job.matchScore * 100).toInt()}%", color = PosTheme.PrimaryDark, style = posDisplay(12f))
                    }
                    job.company?.let { Text(it, color = PosTheme.Muted, style = posDisplay(12f)) }
                    job.location?.let { Text(it, color = PosTheme.Muted, style = posDisplay(11f)) }
                    job.matchReason?.let { Text(it, style = posDisplay(11f)) }
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        if (tab == PosJobTab.OPEN) {
                            PosPrimaryButton("Apply") {
                                if (job.url.isNotBlank()) context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(job.url)))
                            }
                            PosPrimaryButton("Mark applied") {
                                scope.launch { repository.updateJobStatus(job.id, "applied"); reloadJobs() }
                                Unit
                            }
                            PosPrimaryButton("Dismiss") {
                                scope.launch { repository.updateJobStatus(job.id, "dismissed"); reloadJobs() }
                                Unit
                            }
                        } else {
                            PosPrimaryButton("Reopen") {
                                scope.launch { repository.updateJobStatus(job.id, "open"); reloadJobs() }
                                Unit
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun WorkImportScreen(
    repository: PersonalOSRepository,
    nav: AppNavigator,
    onClose: () -> Unit,
    onImported: () -> Unit = {},
) {
    var title by remember { mutableStateOf("") }
    var company by remember { mutableStateOf("") }
    var markdown by remember { mutableStateOf("") }
    var message by remember { mutableStateOf<String?>(null) }
    var diagramUri by remember { mutableStateOf<android.net.Uri?>(null) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val pickDiagram = androidx.activity.compose.rememberLauncherForActivityResult(
        androidx.activity.result.contract.ActivityResultContracts.PickVisualMedia(),
    ) { uri -> diagramUri = uri }

    FeatureScaffold {
        PosCard {
            Text("Import a work project with optional architecture diagram.", color = PosTheme.Muted, style = posDisplay(11f))
        }
        OutlinedTextField(title, { title = it }, Modifier.fillMaxWidth(), label = { Text("Title") })
        OutlinedTextField(company, { company = it }, Modifier.fillMaxWidth(), label = { Text("Company") })
        OutlinedTextField(markdown, { markdown = it }, Modifier.fillMaxWidth(), label = { Text("Markdown") }, minLines = 8)
        PosPrimaryButton(if (diagramUri == null) "Attach diagram" else "Diagram attached") {
            pickDiagram.launch(androidx.activity.result.PickVisualMediaRequest(androidx.activity.result.contract.ActivityResultContracts.PickVisualMedia.ImageOnly))
        }
        diagramUri?.let { Text("Diagram selected", color = PosTheme.Success, style = posDisplay(11f)) }
        PosPrimaryButton("Import") {
            scope.launch {
                val diagramFile = diagramUri?.let { uri ->
                    val stream = context.contentResolver.openInputStream(uri) ?: return@let null
                    java.io.File(context.cacheDir, "import-diagram.png").apply {
                        stream.use { input -> outputStream().use { output -> input.copyTo(output) } }
                    }
                }
                runCatching { repository.importWorkProject(title, company, markdown, diagramFile) }
                    .onSuccess {
                        message = "Imported ${it.title}"
                        onImported()
                        nav.onOpenEntity(
                            EntityRoute(it.entityId, it.title, com.personalos.mobile.data.models.PosEntitySection.ARCHITECTURE),
                        )
                        onClose()
                    }
                    .onFailure { message = it.message }
            }
            Unit
        }
        message?.let { Text(it) }
    }
}

@Composable
fun TextAddScreen(
    title: String,
    onClose: () -> Unit,
    onSubmit: suspend (String, String, String) -> Result<Pair<String, String>>,
    nav: AppNavigator,
    kinds: List<Pair<String, String>> = listOf("note" to "Note"),
    titleHintEnabled: Boolean = false,
    onCreated: () -> Unit = {},
) {
    var kind by remember { mutableStateOf(kinds.first().first) }
    var titleHint by remember { mutableStateOf("") }
    var raw by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    FeatureScaffold {
        if (kinds.size > 1) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                kinds.forEach { (value, label) ->
                    FilterChip(selected = kind == value, onClick = { kind = value }, label = { Text(label) })
                }
            }
        }
        if (titleHintEnabled) {
            OutlinedTextField(titleHint, { titleHint = it }, Modifier.fillMaxWidth(), label = { Text("Title hint") })
        }
        OutlinedTextField(raw, { raw = it }, Modifier.fillMaxWidth(), label = { Text("Content") }, minLines = 6)
        PosPrimaryButton("Add & normalize") {
            scope.launch {
                onSubmit(kind, raw, titleHint)
                    .onSuccess { (id, t) ->
                        onCreated()
                        nav.onOpenEntity(EntityRoute(id, t))
                        onClose()
                    }
                    .onFailure { error = it.message }
            }
            Unit
        }
        error?.let { Text(it, color = PosTheme.Error) }
    }
}

@Composable
fun LearningLessonScreen(
    repository: PersonalOSRepository,
    entityId: String,
    title: String,
    nav: AppNavigator,
    onClose: () -> Unit,
) {
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }
    var lesson by remember { mutableStateOf<com.personalos.mobile.data.models.PosLearningLesson?>(null) }
    var practicing by remember { mutableStateOf(false) }
    var practiceError by remember { mutableStateOf<String?>(null) }
    var practiceResult by remember { mutableStateOf<com.personalos.mobile.data.models.PosLearningCoachResult?>(null) }
    var practiceLabel by remember { mutableStateOf("") }
    val scope = rememberCoroutineScope()

    LaunchedEffect(entityId) {
        loading = true
        error = null
        runCatching { repository.fetchLearningLesson(entityId) }
            .onSuccess { lesson = it; loading = false }
            .onFailure {
                runCatching { repository.entityDetail(entityId) }
                    .onSuccess { detail ->
                        lesson = detail.entity.toLessonFallback()
                        loading = false
                    }
                    .onFailure { e -> error = e.message; loading = false }
            }
    }

    FeatureScaffold {
        when {
            loading -> PosLoadingView("Loading lesson…")
            error != null -> PosEmptyState("Could not load lesson", error.orEmpty(), "Close", onAction = onClose)
            lesson != null -> {
                val l = lesson!!
                if (l.patternOrder > 0) Text("#${l.patternOrder} · ${l.track.uppercase()}", color = PosTheme.PrimaryDark, style = posDisplay(12f))
                PosCard {
                    Text("Overview", color = PosTheme.PrimaryDark, style = posDisplay(12f))
                    Text(l.content.ifBlank { "No content yet." })
                }
                l.whenToUse?.takeIf { it.isNotBlank() }?.let {
                    PosCard { Text("When to use", color = PosTheme.PrimaryDark, style = posDisplay(12f)); Text(it) }
                }
                if (l.recognitionSignals.isNotEmpty()) {
                    PosCard {
                        Text("Recognition signals", color = PosTheme.PrimaryDark, style = posDisplay(12f))
                        l.recognitionSignals.forEach { sig -> Text("• $sig") }
                    }
                }
                l.practiceStrategy?.takeIf { it.isNotBlank() }?.let {
                    PosCard { Text("Practice strategy", color = PosTheme.PrimaryDark, style = posDisplay(12f)); Text(it) }
                }
                l.codeTemplate?.takeIf { it.isNotBlank() }?.let {
                    PosCard { Text("Code template", color = PosTheme.PrimaryDark, style = posDisplay(12f)); PosMonoBlock(it) }
                }
                if (l.problems.isNotEmpty()) {
                    PosCard {
                        l.benchmarks?.let { b ->
                            Text("Targets: Easy ${b.easyMinutes}m · Medium ${b.mediumMinutes}m · Hard ${b.hardMinutes}m", color = PosTheme.Muted, style = posDisplay(11f))
                        }
                        PosChipFlow(l.problems)
                    }
                }
                if (l.modules.isNotEmpty()) {
                    Text("Modules · ${l.modules.size} lessons", style = posDisplay(16f))
                    l.modules.forEach { mod ->
                        PosListRow(mod.title, mod.subtitle) {
                            nav.onOpenLearningLesson(mod.id, mod.title)
                        }
                    }
                }
                Text("Quick practice", style = posDisplay(16f))
                if (practicing) PosLoadingView("Running drill…")
                practiceError?.let { Text(it, color = PosTheme.Error) }
                l.practiceModes.forEach { mode ->
                    PosCard {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Column(Modifier.weight(1f)) {
                                Text(mode.title, style = posDisplay(14f))
                                Text(mode.subtitle, color = PosTheme.Muted, style = posDisplay(11f))
                            }
                            Text("${mode.durationMinutes}m", color = PosTheme.Focus, style = posDisplay(11f))
                        }
                        PosPrimaryButton(if (mode.isAsync) "Run AI drill" else "Run drill") {
                            runPractice(repository, scope, l, mode) { practicing = it.first; practiceError = it.second; practiceResult = it.third; practiceLabel = it.fourth }
                            Unit
                        }
                    }
                }
                practiceResult?.let { result ->
                    PosCard {
                        Text(practiceLabel, color = PosTheme.Success, style = posDisplay(12f))
                        if (result.summary.isNotBlank()) Text(result.summary)
                        result.practiceQuestions.filter { it.isNotBlank() }.forEach { Text("• $it") }
                        result.tips.filter { it.isNotBlank() }.forEach { Text("Tip: $it", color = PosTheme.PrimaryDark, style = posDisplay(11f)) }
                    }
                }
            }
        }
    }
}

private fun runPractice(
    repository: PersonalOSRepository,
    scope: kotlinx.coroutines.CoroutineScope,
    lesson: com.personalos.mobile.data.models.PosLearningLesson,
    mode: PosPracticeMode,
    onUpdate: (Quadruple<Boolean, String?, com.personalos.mobile.data.models.PosLearningCoachResult?, String>) -> Unit,
) {
    scope.launch {
        onUpdate(Quadruple(true, null, null, mode.title))
        val track = lesson.track.ifBlank { "dsa" }
        runCatching {
            if (mode.isAsync) {
                val queued = repository.coachLearningAsync(lesson.entityId, lesson.title, track, mode.focus)
                repository.pollStudyJob(queued.id).result
            } else {
                repository.coachLearning(lesson.entityId, lesson.title, track, mode.focus)
            }
        }.onSuccess { onUpdate(Quadruple(false, null, it, mode.title)) }
            .onFailure { onUpdate(Quadruple(false, it.message, null, mode.title)) }
    }
}

private data class Quadruple<A, B, C, D>(val first: A, val second: B, val third: C, val fourth: D)

private fun PosEntity.toLessonFallback() = com.personalos.mobile.data.models.PosLearningLesson(
    entityId = id,
    title = title,
    content = content,
    type = type,
    track = metadata?.track ?: "dsa",
)

@Composable
fun InterviewPrepScreen(repository: PersonalOSRepository, onClose: () -> Unit) {
    var topics by remember { mutableStateOf(emptyList<PosEntity>()) }
    var loadingTopics by remember { mutableStateOf(true) }
    var stack by remember { mutableStateOf("Java, Spring Boot, PostgreSQL, Kafka, Redis") }
    var result by remember { mutableStateOf<com.personalos.mobile.data.models.PosInterviewDrillResult?>(null) }
    var loading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        runCatching { repository.listEntities("work") }
            .onSuccess { topics = it.items.filter { e -> e.type.contains("interview", true) } }
        loadingTopics = false
    }

    FeatureScaffold {
        Text("AI drills from your interview notebook and stack.", color = PosTheme.Muted, style = posDisplay(12f))
        OutlinedTextField(stack, { stack = it }, Modifier.fillMaxWidth(), label = { Text("Stack") })
        when {
            loadingTopics -> PosLoadingView()
            topics.isEmpty() -> PosEmptyState("No interview topics", "Seed interview notebook on server.", "Close", onAction = onClose)
            else -> topics.forEach { topic ->
                PosListRow(topic.title, topic.metadata?.role ?: "Tap for AI drill") {
                    loading = true
                    error = null
                    scope.launch {
                        runCatching { repository.interviewDrill(topic.id, topic.title, stack, "mid-level") }
                            .onSuccess { result = it; loading = false }
                            .onFailure { error = it.message; loading = false }
                    }
                }
            }
        }
        if (loading) PosLoadingView("Building drill…")
        error?.let { Text(it, color = PosTheme.Error) }
        result?.let { drill ->
            DrillBlock("Warm-up", drill.warmupQuestions)
            DrillBlock("Deep dive", drill.deepQuestions)
            DrillBlock("Answer outline", drill.modelAnswersOutline)
            DrillBlock("Follow-up probes", drill.followUpProbes)
            DrillBlock("Extra study", drill.studyLinks)
        }
    }
}

@Composable
private fun DrillBlock(title: String, items: List<String>) {
    val filtered = items.filter { it.isNotBlank() }
    if (filtered.isEmpty()) return
    PosCard {
        Text(title, color = PosTheme.PrimaryDark, style = posDisplay(12f))
        filtered.forEach { Text("• $it") }
    }
}

@Composable
fun StartupScreen(repository: PersonalOSRepository, nav: AppNavigator, reloadKey: Int = 0, onClose: () -> Unit) {
    var items by remember { mutableStateOf(emptyList<PosEntity>()) }
    var reminders by remember { mutableStateOf(emptyList<com.personalos.mobile.data.models.PosReminder>()) }
    var loading by remember { mutableStateOf(true) }

    LaunchedEffect(reloadKey) {
        loading = true
        runCatching {
            repository.listEntities("startup") to repository.dashboard()
        }.onSuccess { (list, dash) ->
            items = list.items
            reminders = dash.upcomingReminders
            loading = false
        }.onFailure { loading = false }
    }

    FeatureScaffold {
        if (loading) PosLoadingView() else {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                PosMetricCard("Portfolio", if (items.isEmpty()) "—" else "${items.size}", "Startup entities", Modifier.weight(1f)) {
                    nav.onOpenWeb(WebRoute.path("/startup", "Startup"))
                }
                PosMetricCard(
                    "Fash",
                    "${items.count { it.tagList.any { t -> t.equals("fash", true) } || it.title.contains("fash", true) }}",
                    "From fash monorepo",
                    Modifier.weight(1f),
                ) { nav.onOpenStartupHub() }
            }
            val fash = items.filter { it.tagList.any { t -> t.equals("fash", true) } || it.title.contains("fash", true) }
            PosSectionHeader("Fash ecosystem")
            if (fash.isEmpty()) {
                PosEmptyState("Fash not seeded yet", "Add entries via Startup menu.", "Add entry") { nav.onOpenStartupAdd() }
            } else fash.take(4).forEach { e ->
                PosListRow(e.title, e.type) { nav.onOpenEntity(EntityRoute(e.id, e.title)) }
            }
            PosSectionHeader("Ideas")
            val ideas = items.filter { it.type.contains("idea", true) }.ifEmpty { items }
            ideas.take(3).forEach { e ->
                PosListRow(e.title, e.type) { nav.onOpenEntity(EntityRoute(e.id, e.title)) }
            }
            PosSectionHeader("Recent movement")
            items.sortedByDescending { it.updatedAt }.take(3).forEach { e ->
                PosListRow(e.title, e.updatedAt) { nav.onOpenEntity(EntityRoute(e.id, e.title)) }
            }
            if (reminders.isNotEmpty()) {
                PosSectionHeader("On the calendar")
                reminders.take(4).forEach { r ->
                    PosListRow(r.title, r.dueAt) {
                        r.entityId?.let { nav.onOpenEntity(EntityRoute(it, r.title)) }
                    }
                }
            }
            PosPrimaryButton("Startup menu") { nav.onOpenStartupHub() }
        }
    }
}

@Composable
fun WorkHubSheet(nav: AppNavigator, onDismiss: () -> Unit) {
    Column(
        Modifier
            .padding(horizontal = 20.dp, vertical = 8.dp)
            .padding(bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text("Work hub", style = posDisplay(20f))
        Text("Career tools — add entries, import projects, CV & jobs.", color = PosTheme.Muted, style = posDisplay(12f))
        PosHubMenuRow("Add entry", "AI-normalized work capture", Icons.Default.Add) { nav.onOpenWorkAdd(); onDismiss() }
        PosHubMenuRow("Import project", "Upload architecture diagram", Icons.Default.FileUpload) { nav.onOpenWorkImport(); onDismiss() }
        PosHubMenuRow("CV Transfer", "Edit ideal resume & export", Icons.Default.Description) { nav.onOpenCv(); onDismiss() }
        PosHubMenuRow("Job Scout", "Scan matching opportunities", Icons.Default.PersonSearch) { nav.onOpenJobScout(); onDismiss() }
        PosHubMenuRow("Interview prep", "AI drill & notebook", Icons.Default.Psychology) { nav.onOpenInterviewPrep(); onDismiss() }
        PosHubMenuRow("Open work board", "Full web career view", Icons.Default.Work) { nav.onOpenWeb(WebRoute.path("/work", "Work")); onDismiss() }
    }
}

@Composable
fun StartupHubSheet(nav: AppNavigator, onDismiss: () -> Unit) {
    Column(
        Modifier
            .padding(horizontal = 20.dp, vertical = 8.dp)
            .padding(bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text("Startup", style = posDisplay(20f))
        PosHubMenuRow("Add startup entry (AI)", "Idea, KPI, competitor…", Icons.Default.Add) { nav.onOpenStartupAdd(); onDismiss() }
        PosHubMenuRow("Open startup board", "Full web startup view", Icons.Default.Work) { nav.onOpenWeb(WebRoute.path("/startup", "Startup")); onDismiss() }
        PosActionButton("Quick capture", style = PosActionStyle.Secondary, onClick = { nav.captureNote(); onDismiss() })
    }
}

private fun android.content.Context.openPdf(bytes: ByteArray) {
    val file = java.io.File(cacheDir, "cv-export.pdf")
    file.writeBytes(bytes)
    val uri = androidx.core.content.FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
    startActivity(Intent(Intent.ACTION_VIEW).setDataAndType(uri, "application/pdf").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
}
