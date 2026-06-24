package com.personalos.mobile.ui.features

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
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
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.personalos.mobile.data.models.PosCvDocument
import com.personalos.mobile.data.models.PosJobTab
import com.personalos.mobile.data.models.PosLearningTrack
import com.personalos.mobile.data.repository.PersonalOSRepository
import com.personalos.mobile.ui.components.PosEmptyState
import com.personalos.mobile.ui.components.PosListRow
import com.personalos.mobile.ui.components.PosLoadingView
import com.personalos.mobile.ui.components.PosPrimaryButton
import com.personalos.mobile.ui.navigation.AppNavigator
import com.personalos.mobile.ui.navigation.EntityRoute
import com.personalos.mobile.ui.theme.posDisplay
import kotlinx.coroutines.launch

@Composable
fun CvHubScreen(repository: PersonalOSRepository, onClose: () -> Unit) {
    var loading by remember { mutableStateOf(true) }
    var doc by remember { mutableStateOf<PosCvDocument?>(null) }
    var error by remember { mutableStateOf<String?>(null) }
    var refineInstruction by remember { mutableStateOf("") }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    LaunchedEffect(Unit) {
        runCatching { repository.fetchCv().document }
            .onSuccess { doc = it; loading = false }
            .onFailure { error = it.message; loading = false }
    }

    FeatureScaffold("CV Hub", onClose) {
        when {
            loading -> PosLoadingView()
            error != null -> PosEmptyState("Error", error.orEmpty(), "Close", onClose)
            doc != null -> {
                val d = doc!!
                OutlinedTextField(d.headline, { doc = d.copy(headline = it) }, Modifier.fillMaxWidth(), label = { Text("Headline") })
                OutlinedTextField(d.summary, { doc = d.copy(summary = it) }, Modifier.fillMaxWidth(), label = { Text("Summary") }, minLines = 4)
                OutlinedTextField(refineInstruction, { refineInstruction = it }, Modifier.fillMaxWidth(), label = { Text("AI refine instruction") })
                PosPrimaryButton("Refine summary") {
                    scope.launch {
                        runCatching { repository.refineCv(refineInstruction, "summary", d.summary) }
                            .onSuccess { doc = d.copy(summary = it.refinedContent ?: d.summary) }
                    }
                    Unit
                }
                PosPrimaryButton("Save") {
                    scope.launch { doc?.let { repository.saveCv(it) } }
                    Unit
                }
                PosPrimaryButton("Export PDF") {
                    scope.launch {
                        runCatching {
                            val bytes = repository.downloadCvPdf()
                            context.openPdf(bytes)
                        }
                    }
                    Unit
                }
                PosPrimaryButton("Share link") {
                    scope.launch {
                        runCatching {
                            val url = repository.shareCv().shareUrl
                            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                        }
                    }
                    Unit
                }
            }
        }
    }
}

@Composable
fun JobScoutScreen(repository: PersonalOSRepository, onClose: () -> Unit) {
    var tab by remember { mutableStateOf(PosJobTab.OPEN) }
    var jobs by remember { mutableStateOf(emptyList<com.personalos.mobile.data.models.PosJobOpportunity>()) }
    var loading by remember { mutableStateOf(true) }
    var scanning by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    fun reload() {
        scope.launch {
            loading = true
            runCatching { repository.fetchJobs(if (tab == PosJobTab.OPEN) "open" else "applied") }
                .onSuccess { jobs = it; loading = false }
                .onFailure { loading = false }
        }
    }

    LaunchedEffect(tab) { reload() }

    FeatureScaffold("Job Scout", onClose) {
        FilterChip(selected = tab == PosJobTab.OPEN, onClick = { tab = PosJobTab.OPEN }, label = { Text("Open") })
        FilterChip(selected = tab == PosJobTab.APPLIED, onClick = { tab = PosJobTab.APPLIED }, label = { Text("Applied") })
        PosPrimaryButton(if (scanning) "Scanning…" else "Scan jobs") {
            scanning = true
            scope.launch {
                runCatching { repository.scanJobs() }.onSuccess { reload() }
                scanning = false
            }
            Unit
        }
        if (loading) PosLoadingView() else jobs.forEach { job ->
            PosListRow(job.title, "${job.company} · ${job.location}") {
                if (job.url.isNotBlank()) context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(job.url)))
            }
            if (tab == PosJobTab.OPEN) {
                PosPrimaryButton("Mark applied") {
                    scope.launch { repository.updateJobStatus(job.id, "applied"); reload() }
                    Unit
                }
            }
        }
    }
}

@Composable
fun WorkImportScreen(repository: PersonalOSRepository, nav: AppNavigator, onClose: () -> Unit) {
    var title by remember { mutableStateOf("") }
    var company by remember { mutableStateOf("") }
    var markdown by remember { mutableStateOf("") }
    var message by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    FeatureScaffold("Import project", onClose) {
        OutlinedTextField(title, { title = it }, Modifier.fillMaxWidth(), label = { Text("Title") })
        OutlinedTextField(company, { company = it }, Modifier.fillMaxWidth(), label = { Text("Company") })
        OutlinedTextField(markdown, { markdown = it }, Modifier.fillMaxWidth(), label = { Text("Markdown") }, minLines = 8)
        PosPrimaryButton("Import") {
            scope.launch {
                runCatching { repository.importWorkProject(title, company, markdown, null) }
                    .onSuccess {
                        message = "Imported ${it.title}"
                        nav.onOpenEntity(EntityRoute(it.entityId, it.title))
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
    onSubmit: suspend (String, String) -> Result<Pair<String, String>>,
    nav: AppNavigator,
) {
    var kind by remember { mutableStateOf("note") }
    var raw by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    FeatureScaffold(title, onClose) {
        OutlinedTextField(kind, { kind = it }, Modifier.fillMaxWidth(), label = { Text("Kind") })
        OutlinedTextField(raw, { raw = it }, Modifier.fillMaxWidth(), label = { Text("Content") }, minLines = 6)
        PosPrimaryButton("Add") {
            scope.launch {
                onSubmit(kind, raw)
                    .onSuccess { (id, t) -> nav.onOpenEntity(EntityRoute(id, t)); onClose() }
                    .onFailure { error = it.message }
            }
            Unit
        }
        error?.let { Text(it) }
    }
}

@Composable
fun LearningLessonScreen(repository: PersonalOSRepository, entityId: String, title: String, onClose: () -> Unit) {
    var loading by remember { mutableStateOf(true) }
    var theory by remember { mutableStateOf("") }
    var practice by remember { mutableStateOf("") }
    LaunchedEffect(entityId) {
        runCatching { repository.fetchLearningLesson(entityId) }
            .onSuccess { theory = it.theory; practice = it.quickPractice; loading = false }
            .onFailure { loading = false }
    }
    FeatureScaffold(title, onClose) {
        if (loading) PosLoadingView() else {
            Text("Theory", style = posDisplay(16f))
            Text(theory)
            Text("Quick practice", style = posDisplay(16f))
            Text(practice)
        }
    }
}

@Composable
fun InterviewPrepScreen(repository: PersonalOSRepository, onClose: () -> Unit) {
    var topic by remember { mutableStateOf("Java Spring Boot") }
    var result by remember { mutableStateOf<com.personalos.mobile.data.models.PosInterviewDrillResult?>(null) }
    var loading by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    FeatureScaffold("Interview prep", onClose) {
        OutlinedTextField(topic, { topic = it }, Modifier.fillMaxWidth(), label = { Text("Topic / stack") })
        PosPrimaryButton("Generate drill") {
            loading = true
            scope.launch {
                runCatching { repository.interviewDrill(null, topic, topic, "mid-level") }
                    .onSuccess { result = it; loading = false }
                    .onFailure { loading = false }
            }
            Unit
        }
        if (loading) PosLoadingView()
        result?.warmupQuestions?.forEach { Text("• $it") }
        result?.deepQuestions?.forEach { Text("• $it") }
    }
}

@Composable
fun StartupScreen(repository: PersonalOSRepository, nav: AppNavigator, onClose: () -> Unit) {
    var entities by remember { mutableStateOf(emptyList<com.personalos.mobile.data.models.PosEntity>()) }
    LaunchedEffect(Unit) {
        runCatching { repository.listEntities("startup") }.onSuccess { entities = it.entities }
    }
    FeatureScaffold("Startup", onClose) {
        entities.forEach { e ->
            PosListRow(e.title, e.metadata?.phase) { nav.onOpenEntity(EntityRoute(e.id, e.title)) }
        }
        PosPrimaryButton("Add startup entry") { nav.onOpenStartupAdd() }
    }
}

@Composable
fun WorkHubSheet(nav: AppNavigator, onDismiss: () -> Unit) {
    Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Work hub", style = posDisplay(20f))
        PosPrimaryButton("Add entry") { nav.onOpenWorkAdd(); onDismiss() }
        PosPrimaryButton("Import project") { nav.onOpenWorkImport(); onDismiss() }
        PosPrimaryButton("CV Hub") { nav.onOpenCv(); onDismiss() }
        PosPrimaryButton("Job Scout") { nav.onOpenJobScout(); onDismiss() }
        PosPrimaryButton("Interview prep") { nav.onOpenInterviewPrep(); onDismiss() }
    }
}

@Composable
private fun FeatureScaffold(title: String, onClose: () -> Unit, content: @Composable ColumnScope.() -> Unit) {
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(title, style = posDisplay(22f))
        PosPrimaryButton("Close", onClick = onClose)
        content()
    }
}
private fun android.content.Context.openPdf(bytes: ByteArray) {
    val file = java.io.File(cacheDir, "cv-export.pdf")
    file.writeBytes(bytes)
    val uri = androidx.core.content.FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
    startActivity(Intent(Intent.ACTION_VIEW).setDataAndType(uri, "application/pdf").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
}
