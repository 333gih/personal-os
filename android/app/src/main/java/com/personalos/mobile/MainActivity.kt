package com.personalos.mobile

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import com.personalos.mobile.ui.shell.PosAppHeader
import com.personalos.mobile.ui.modules.ModuleSettingsScreen
import com.personalos.mobile.ui.modules.ModulesViewModel
import com.personalos.mobile.ui.shell.PosDynamicBottomTabBar
import com.personalos.mobile.ui.shell.PosModalBottomSheet
import com.personalos.mobile.ui.shell.PosOverlayScaffold
import com.personalos.mobile.data.models.PosLearningTrack
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.personalos.mobile.data.auth.SessionManager
import com.personalos.mobile.data.models.PosEntitySection
import com.personalos.mobile.data.models.PosNavTab
import com.personalos.mobile.data.models.PosTab
import com.personalos.mobile.ui.auth.LoginWebScreen
import com.personalos.mobile.ui.entity.EntityDetailScreen
import com.personalos.mobile.ui.entity.EntityDetailViewModel
import com.personalos.mobile.ui.features.CvHubScreen
import com.personalos.mobile.ui.features.InterviewPrepScreen
import com.personalos.mobile.ui.features.JobScoutScreen
import com.personalos.mobile.ui.features.LearningCoachScreen
import com.personalos.mobile.ui.features.LearningLessonScreen
import com.personalos.mobile.ui.features.LearningScheduleScreen
import com.personalos.mobile.ui.features.NotificationLogScreen
import com.personalos.mobile.ui.features.StartupHubSheet
import com.personalos.mobile.ui.features.StartupScreen
import com.personalos.mobile.ui.features.TextAddScreen
import com.personalos.mobile.ui.features.WorkHubSheet
import com.personalos.mobile.ui.features.WorkImportScreen
import com.personalos.mobile.ui.home.HomeScreen
import com.personalos.mobile.ui.home.HomeViewModel
import com.personalos.mobile.ui.learning.LearningHubSheet
import com.personalos.mobile.ui.learning.LearningScreen
import com.personalos.mobile.ui.learning.LearningViewModel
import com.personalos.mobile.ui.more.MoreScreen
import com.personalos.mobile.ui.navigation.AppNavigator
import com.personalos.mobile.ui.navigation.EntityRoute
import com.personalos.mobile.ui.navigation.LearningCoachRoute
import com.personalos.mobile.ui.navigation.LearningLessonRoute
import com.personalos.mobile.ui.work.WorkAddScreen
import com.personalos.mobile.ui.navigation.WebRoute
import com.personalos.mobile.ui.search.SearchScreen
import com.personalos.mobile.ui.search.SearchViewModel
import com.personalos.mobile.ui.theme.PersonalOSTheme
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.web.EmbeddedWebScreen
import com.personalos.mobile.ui.work.WorkScreen
import com.personalos.mobile.ui.work.WorkViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val app = application as PersonalOSApplication
        val sessionManager = app.sessionManager
        val repository = app.repository

        sessionManager.bootstrap {
            runCatching { repository.me() }.onSuccess { sessionManager.setUser(it) }
        }

        setContent {
            PersonalOSTheme {
                PersonalOSRoot(app, sessionManager, repository)
            }
        }
    }
}

@Composable
private fun PersonalOSRoot(
    app: PersonalOSApplication,
    sessionManager: SessionManager,
    repository: com.personalos.mobile.data.repository.PersonalOSRepository,
) {
    val isAuthenticated by sessionManager.isAuthenticated.collectAsStateWithLifecycle()
    val bootstrapReady by sessionManager.bootstrapReady.collectAsStateWithLifecycle()
    var loginError by remember { mutableStateOf<String?>(null) }
    var bootstrapTimedOut by remember { mutableStateOf(false) }

    LaunchedEffect(bootstrapReady) {
        if (bootstrapReady) {
            bootstrapTimedOut = false
            return@LaunchedEffect
        }
        kotlinx.coroutines.delay(15_000)
        if (!sessionManager.bootstrapReady.value) {
            bootstrapTimedOut = true
        }
    }

    when {
        isAuthenticated && !bootstrapReady && !bootstrapTimedOut -> {
            Column(Modifier.fillMaxSize().statusBarsPadding(), horizontalAlignment = Alignment.CenterHorizontally) {
                CircularProgressIndicator(modifier = Modifier.padding(24.dp), color = PosTheme.PrimaryDark)
                Text("Restoring session…")
            }
        }
        isAuthenticated && !bootstrapReady && bootstrapTimedOut -> {
            Column(
                Modifier.fillMaxSize().statusBarsPadding().padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text("Session restore is taking too long.")
                IconButton(onClick = {
                    bootstrapTimedOut = false
                    sessionManager.retryBootstrap {
                        runCatching { repository.me() }.onSuccess { sessionManager.setUser(it) }
                    }
                }) { Text("Retry") }
                IconButton(onClick = {
                    bootstrapTimedOut = false
                    sessionManager.signOut()
                }) { Text("Sign in again") }
            }
        }
        !isAuthenticated -> {
            if (loginError != null) {
                Column(Modifier.padding(24.dp)) {
                    Text(loginError!!)
                    IconButton(onClick = { loginError = null }) { Text("Retry") }
                }
            } else {
                LoginWebScreen(sessionManager, app.moshi) { loginError = it }
            }
        }
        else -> MainShell(sessionManager, repository)
    }
}

@Composable
private fun MainShell(
    sessionManager: SessionManager,
    repository: com.personalos.mobile.data.repository.PersonalOSRepository,
) {
    var selectedTab by remember { mutableStateOf("dashboard") }
    var showModuleSettings by remember { mutableStateOf(false) }
    val modulesVm: ModulesViewModel = viewModel(factory = simpleFactory { ModulesViewModel(repository) })
    val bottomTabs = modulesVm.bottomTabIds

    LaunchedEffect(Unit) { modulesVm.refresh(force = true) }
    LaunchedEffect(bottomTabs) {
        if (selectedTab !in bottomTabs) {
            selectedTab = bottomTabs.firstOrNull() ?: "dashboard"
        }
    }
    var webRoute by remember { mutableStateOf<WebRoute?>(null) }
    var entityRoute by remember { mutableStateOf<EntityRoute?>(null) }
    var lessonRoute by remember { mutableStateOf<LearningLessonRoute?>(null) }
    var showCv by remember { mutableStateOf(false) }
    var showJobs by remember { mutableStateOf(false) }
    var showWorkImport by remember { mutableStateOf(false) }
    var showWorkAdd by remember { mutableStateOf(false) }
    var showWorkHub by remember { mutableStateOf(false) }
    var showStartup by remember { mutableStateOf(false) }
    var showStartupHub by remember { mutableStateOf(false) }
    var showStartupAdd by remember { mutableStateOf(false) }
    var showLearningHub by remember { mutableStateOf(false) }
    var showLearningAdd by remember { mutableStateOf<PosLearningTrack?>(null) }
    var showLearningCoach by remember { mutableStateOf<LearningCoachRoute?>(null) }
    var showLearningSchedule by remember { mutableStateOf(false) }
    var showNotificationLog by remember { mutableStateOf(false) }
    var showInterview by remember { mutableStateOf(false) }
    var workReloadKey by remember { mutableStateOf(0) }
    var learningReloadKey by remember { mutableStateOf(0) }
    var startupReloadKey by remember { mutableStateOf(0) }

    val nav = remember(modulesVm) {
        AppNavigator(
            onSwitchTab = { legacy ->
                selectedTab = when (legacy) {
                    PosTab.HOME -> "dashboard"
                    PosTab.WORK -> "work"
                    PosTab.LEARNING -> "learning"
                    PosTab.SEARCH -> "search"
                    PosTab.MORE -> "more"
                }
            },
            onOpenWeb = { webRoute = it },
            onOpenEntity = { entityRoute = it },
            onOpenCv = { showCv = true },
            onOpenJobScout = { showJobs = true },
            onOpenWorkImport = { showWorkImport = true },
            onOpenWorkAdd = { showWorkAdd = true },
            onOpenWorkHub = { showWorkHub = true },
            onOpenStartup = { showStartup = true },
            onOpenStartupHub = { showStartupHub = true },
            onOpenStartupAdd = { showStartupAdd = true },
            onOpenLearningHub = { showLearningHub = true },
            onOpenLearningAdd = { showLearningAdd = it },
            onOpenLearningCoach = { track, entityId, topic ->
                showLearningCoach = LearningCoachRoute(track, entityId, topic)
            },
            onOpenLearningLesson = { id, title -> lessonRoute = LearningLessonRoute(id, title) },
            onOpenLearningSchedule = { showLearningSchedule = true },
            onOpenNotificationLog = { showNotificationLog = true },
            onOpenInterviewPrep = { showInterview = true },
        )
    }

    val homeVm: HomeViewModel = viewModel(factory = simpleFactory { HomeViewModel(repository) })
    val workVm: WorkViewModel = viewModel(factory = simpleFactory { WorkViewModel(repository) })
    val learningVm: LearningViewModel = viewModel(factory = simpleFactory { LearningViewModel(repository) })
    val activity = androidx.compose.ui.platform.LocalContext.current as ComponentActivity
    val searchVm: SearchViewModel = viewModel(factory = simpleFactory {
        SearchViewModel(repository, activity.applicationContext)
    })

    Box(Modifier.fillMaxSize()) {
        Column(Modifier.fillMaxSize()) {
            PosAppHeader(
                title = (PosNavTab.from(selectedTab) ?: PosNavTab.DASHBOARD).let {
                    when (it) {
                        PosNavTab.WORK -> "Career Path"
                        PosNavTab.MORE -> "More"
                        else -> "Personal OS"
                    }
                },
                initials = sessionManager.userInitials(),
                onAvatarTap = { nav.onOpenWeb(WebRoute.path("/settings", "Settings")) },
                onSettingsTap = { selectedTab = if ("more" in bottomTabs) "more" else "dashboard" },
            )
            Box(Modifier.weight(1f)) {
                when (PosNavTab.from(selectedTab)) {
                    PosNavTab.WORK -> if (modulesVm.isEnabled("work")) {
                        WorkScreen(workVm, repository, nav, workReloadKey)
                    } else {
                        Text("Work module is off", Modifier.padding(24.dp))
                    }
                    PosNavTab.LEARNING -> if (modulesVm.isEnabled("learning")) {
                        LearningScreen(learningVm, nav, learningReloadKey)
                    } else {
                        Text("Learning module is off", Modifier.padding(24.dp))
                    }
                    PosNavTab.SEARCH -> SearchScreen(searchVm, nav)
                    PosNavTab.MORE -> MoreScreen(sessionManager, nav, modulesVm, onOpenModuleSettings = { showModuleSettings = true }, onSelectTab = { selectedTab = it })
                    PosNavTab.STARTUP -> EmbeddedWebScreen(WebRoute.path("/startup", "Startup"))
                    PosNavTab.ENTERTAINMENT -> EmbeddedWebScreen(WebRoute.path("/entertainment", "Reading Log"))
                    PosNavTab.GOALS -> EmbeddedWebScreen(WebRoute.path("/entities?domain=goal", "Goals"))
                    PosNavTab.INBOX -> EmbeddedWebScreen(WebRoute.path("/inbox", "Inbox"))
                    else -> HomeScreen(homeVm, sessionManager, nav)
                }
            }
            PosDynamicBottomTabBar(selectedId = selectedTab, tabIds = bottomTabs, onSelect = { selectedTab = it })
        }

        if (showModuleSettings) {
            FullScreenOverlay("Module settings", { showModuleSettings = false }) {
                ModuleSettingsScreen(modulesVm) { showModuleSettings = false }
            }
        }

        webRoute?.let { route ->
            FullScreenOverlay(route.title, onClose = { webRoute = null }) { EmbeddedWebScreen(route) }
        }
        entityRoute?.let { route ->
            FullScreenOverlay(route.title, onClose = { entityRoute = null }) {
                val vm: EntityDetailViewModel = viewModel(
                    key = route.id,
                    factory = simpleFactory { EntityDetailViewModel(repository, route.id) },
                )
                EntityDetailScreen(vm, route.title, route.section, nav) { entityRoute = null }
            }
        }
        lessonRoute?.let { route ->
            FullScreenOverlay(route.title, onClose = { lessonRoute = null }) {
                LearningLessonScreen(repository, route.id, route.title, nav) { lessonRoute = null }
            }
        }
        if (showCv) FullScreenOverlay("CV Transfer", { showCv = false }) { CvHubScreen(repository, onClose = { showCv = false }) }
        if (showJobs) FullScreenOverlay("Job Scout", { showJobs = false }) { JobScoutScreen(repository) { showJobs = false } }
        if (showWorkImport) {
            FullScreenOverlay("Import project", { showWorkImport = false }) {
                WorkImportScreen(repository, nav, onClose = { showWorkImport = false }, onImported = { workReloadKey++ })
            }
        }
        if (showWorkAdd) {
            FullScreenOverlay("Add to Work", { showWorkAdd = false }) {
                WorkAddScreen(repository, nav, onClose = { showWorkAdd = false }, onCreated = { workReloadKey++ })
            }
        }
        if (showStartupAdd) {
            FullScreenOverlay("Add startup entry", { showStartupAdd = false }) {
                TextAddScreen(
                    "Add startup entry",
                    { showStartupAdd = false },
                    { kind, raw, hint ->
                        runCatching { repository.addStartupEntry(kind, raw, hint) }.map { it.entityId to it.title }
                    },
                    nav,
                    kinds = listOf(
                        "idea" to "Idea",
                        "feature" to "Feature",
                        "kpi" to "KPI",
                        "competitor" to "Competitor",
                        "pain_point" to "Pain point",
                        "business_model" to "Business model",
                    ),
                    titleHintEnabled = true,
                    onCreated = { startupReloadKey++ },
                )
            }
        }
        showLearningAdd?.let { track ->
            FullScreenOverlay("Add ${track.label}", { showLearningAdd = null }) {
                TextAddScreen(
                    "Add ${track.label}",
                    { showLearningAdd = null },
                    { kind, raw, hint ->
                        runCatching { repository.addLearningEntry(kind, track.apiValue, raw, hint) }.map { it.entityId to it.title }
                    },
                    nav,
                    kinds = listOf(
                        "course" to "Course",
                        "topic" to "Topic",
                        "skill" to "Skill",
                        "note" to "Note",
                    ),
                    titleHintEnabled = true,
                    onCreated = { learningReloadKey++ },
                )
            }
        }
        if (showInterview) FullScreenOverlay("Interview prep", { showInterview = false }) { InterviewPrepScreen(repository) { showInterview = false } }
        if (showStartup) {
            FullScreenOverlay("Startup", { showStartup = false }) {
                StartupScreen(repository, nav, reloadKey = startupReloadKey) { showStartup = false }
            }
        }
        showLearningCoach?.let { route ->
            FullScreenOverlay("AI coach", { showLearningCoach = null }) {
                LearningCoachScreen(repository, route.track, route.entityId, route.topic) { showLearningCoach = null }
            }
        }
        if (showLearningSchedule) {
            FullScreenOverlay("Study schedule", { showLearningSchedule = false }) {
                LearningScheduleScreen(repository) { showLearningSchedule = false }
            }
        }
        if (showNotificationLog) {
            FullScreenOverlay("Notifications", { showNotificationLog = false }) {
                NotificationLogScreen(repository) { showNotificationLog = false }
            }
        }
        if (showWorkHub) {
            PosModalBottomSheet(onDismiss = { showWorkHub = false }) {
                WorkHubSheet(nav) { showWorkHub = false }
            }
        }
        if (showLearningHub) {
            PosModalBottomSheet(onDismiss = { showLearningHub = false }) {
                LearningHubSheet(nav) { showLearningHub = false }
            }
        }
        if (showStartupHub) {
            PosModalBottomSheet(onDismiss = { showStartupHub = false }) {
                StartupHubSheet(nav) { showStartupHub = false }
            }
        }
    }
}

@Composable
private fun FullScreenOverlay(title: String, onClose: () -> Unit, content: @Composable () -> Unit) {
    Box(
        Modifier
            .fillMaxSize()
            .background(com.personalos.mobile.ui.theme.PosTheme.Background),
    ) {
        PosOverlayScaffold(title = title, onClose = onClose, content = content)
    }
}

private fun <T : androidx.lifecycle.ViewModel> simpleFactory(create: () -> T) =
    object : androidx.lifecycle.ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <VM : androidx.lifecycle.ViewModel> create(modelClass: Class<VM>): VM = create() as VM
    }
