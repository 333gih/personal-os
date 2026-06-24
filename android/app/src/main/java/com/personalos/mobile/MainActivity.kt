package com.personalos.mobile

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.MenuBook
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Work
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.personalos.mobile.data.auth.SessionManager
import com.personalos.mobile.data.models.PosLearningTrack
import com.personalos.mobile.data.models.PosTab
import com.personalos.mobile.ui.auth.LoginWebScreen
import com.personalos.mobile.ui.entity.EntityDetailScreen
import com.personalos.mobile.ui.entity.EntityDetailViewModel
import com.personalos.mobile.ui.features.CvHubScreen
import com.personalos.mobile.ui.features.InterviewPrepScreen
import com.personalos.mobile.ui.features.JobScoutScreen
import com.personalos.mobile.ui.features.LearningLessonScreen
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
import com.personalos.mobile.ui.navigation.LearningLessonRoute
import com.personalos.mobile.ui.navigation.WebRoute
import com.personalos.mobile.ui.search.SearchScreen
import com.personalos.mobile.ui.search.SearchViewModel
import com.personalos.mobile.ui.theme.PersonalOSTheme
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.web.EmbeddedWebScreen
import com.personalos.mobile.ui.work.WorkScreen
import com.personalos.mobile.ui.work.WorkViewModel
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val app = application as PersonalOSApplication
        val sessionManager = app.sessionManager
        val repository = app.repository

        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                sessionManager.refreshSessionIfNeeded(force = false)
            }
        }

        sessionManager.bootstrap {
            lifecycleScope.launch {
                runCatching { repository.me() }.onSuccess { sessionManager.setUser(it) }
            }
        }

        setContent {
            PersonalOSTheme {
                PersonalOSRoot(app, sessionManager, repository)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PersonalOSRoot(
    app: PersonalOSApplication,
    sessionManager: SessionManager,
    repository: com.personalos.mobile.data.repository.PersonalOSRepository,
) {
    val isAuthenticated by sessionManager.isAuthenticated.collectAsStateWithLifecycle()
    var bootstrapping by remember { mutableStateOf(true) }
    var loginError by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(isAuthenticated) {
        if (isAuthenticated) bootstrapping = false
    }
    LaunchedEffect(Unit) {
        kotlinx.coroutines.delay(400)
        bootstrapping = false
    }

    when {
        bootstrapping && sessionManager.isAuthenticated.value -> {
            Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
                CircularProgressIndicator(modifier = Modifier.padding(24.dp), color = PosTheme.PrimaryDark)
                Text("Restoring session…")
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MainShell(
    sessionManager: SessionManager,
    repository: com.personalos.mobile.data.repository.PersonalOSRepository,
) {
    var tab by remember { mutableStateOf(PosTab.HOME) }
    var webRoute by remember { mutableStateOf<WebRoute?>(null) }
    var entityRoute by remember { mutableStateOf<EntityRoute?>(null) }
    var lessonRoute by remember { mutableStateOf<LearningLessonRoute?>(null) }
    var showCv by remember { mutableStateOf(false) }
    var showJobs by remember { mutableStateOf(false) }
    var showWorkImport by remember { mutableStateOf(false) }
    var showWorkAdd by remember { mutableStateOf(false) }
    var showWorkHub by remember { mutableStateOf(false) }
    var showStartup by remember { mutableStateOf(false) }
    var showStartupAdd by remember { mutableStateOf(false) }
    var showLearningHub by remember { mutableStateOf(false) }
    var showLearningAdd by remember { mutableStateOf<PosLearningTrack?>(null) }
    var showInterview by remember { mutableStateOf(false) }

    val nav = remember {
        AppNavigator(
            onSwitchTab = { tab = it },
            onOpenWeb = { webRoute = it },
            onOpenEntity = { entityRoute = it },
            onOpenCv = { showCv = true },
            onOpenJobScout = { showJobs = true },
            onOpenWorkImport = { showWorkImport = true },
            onOpenWorkAdd = { showWorkAdd = true },
            onOpenWorkHub = { showWorkHub = true },
            onOpenStartup = { showStartup = true },
            onOpenStartupAdd = { showStartupAdd = true },
            onOpenLearningHub = { showLearningHub = true },
            onOpenLearningAdd = { showLearningAdd = it },
            onOpenLearningCoach = { _, _, _ -> showLearningHub = false },
            onOpenLearningLesson = { id, title -> lessonRoute = LearningLessonRoute(id, title) },
            onOpenLearningSchedule = { webRoute = WebRoute.path("/learning", "Schedule") },
            onOpenNotificationLog = { webRoute = WebRoute.path("/learning", "Notifications") },
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

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(tab.title) },
                actions = {
                    Text(sessionManager.userInitials(), modifier = Modifier.padding(end = 16.dp))
                },
            )
        },
        bottomBar = {
            NavigationBar {
                PosTab.entries.forEach { item ->
                    NavigationBarItem(
                        selected = tab == item,
                        onClick = { tab = item },
                        icon = {
                            Icon(
                                when (item) {
                                    PosTab.HOME -> Icons.Default.Home
                                    PosTab.WORK -> Icons.Default.Work
                                    PosTab.LEARNING -> Icons.Default.MenuBook
                                    PosTab.SEARCH -> Icons.Default.Search
                                    PosTab.MORE -> Icons.Default.MoreHoriz
                                },
                                contentDescription = item.title,
                            )
                        },
                        label = { Text(item.title) },
                    )
                }
            }
        },
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            when (tab) {
                PosTab.HOME -> HomeScreen(homeVm, sessionManager, nav)
                PosTab.WORK -> WorkScreen(workVm, nav)
                PosTab.LEARNING -> LearningScreen(learningVm, nav)
                PosTab.SEARCH -> SearchScreen(searchVm, nav)
                PosTab.MORE -> MoreScreen(sessionManager, nav)
            }
        }
    }

    webRoute?.let { route ->
        FullScreenOverlay(onClose = { webRoute = null }) { EmbeddedWebScreen(route) }
    }
    entityRoute?.let { route ->
        FullScreenOverlay(onClose = { entityRoute = null }) {
            val vm: EntityDetailViewModel = viewModel(
                key = route.id,
                factory = simpleFactory { EntityDetailViewModel(repository, route.id) },
            )
            EntityDetailScreen(vm, route.title, nav) { entityRoute = null }
        }
    }
    lessonRoute?.let { route ->
        FullScreenOverlay(onClose = { lessonRoute = null }) {
            LearningLessonScreen(repository, route.id, route.title) { lessonRoute = null }
        }
    }
    if (showCv) FullScreenOverlay({ showCv = false }) { CvHubScreen(repository) { showCv = false } }
    if (showJobs) FullScreenOverlay({ showJobs = false }) { JobScoutScreen(repository) { showJobs = false } }
    if (showWorkImport) FullScreenOverlay({ showWorkImport = false }) { WorkImportScreen(repository, nav) { showWorkImport = false } }
    if (showWorkAdd) FullScreenOverlay({ showWorkAdd = false }) {
        TextAddScreen("Add work entry", { showWorkAdd = false }, { kind, raw ->
            runCatching { repository.addWorkEntry(kind, raw) }.map { it.entityId to it.title }
        }, nav)
    }
    if (showStartupAdd) FullScreenOverlay({ showStartupAdd = false }) {
        TextAddScreen("Add startup entry", { showStartupAdd = false }, { kind, raw ->
            runCatching { repository.addStartupEntry(kind, raw) }.map { it.entityId to it.title }
        }, nav)
    }
    showLearningAdd?.let { track ->
        FullScreenOverlay({ showLearningAdd = null }) {
            TextAddScreen("Add ${track.label}", { showLearningAdd = null }, { kind, raw ->
                runCatching { repository.addLearningEntry(kind, track.apiValue, raw) }.map { it.entityId to it.title }
            }, nav)
        }
    }
    if (showInterview) FullScreenOverlay({ showInterview = false }) { InterviewPrepScreen(repository) { showInterview = false } }
    if (showStartup) FullScreenOverlay({ showStartup = false }) { StartupScreen(repository, nav) { showStartup = false } }
    if (showWorkHub) FullScreenOverlay({ showWorkHub = false }) { WorkHubSheet(nav) { showWorkHub = false } }
    if (showLearningHub) FullScreenOverlay({ showLearningHub = false }) { LearningHubSheet(nav) { showLearningHub = false } }
}

@Composable
private fun FullScreenOverlay(onClose: () -> Unit, content: @Composable () -> Unit) {
    Column(Modifier.fillMaxSize()) {
        Row(Modifier.fillMaxWidth().padding(8.dp), verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onClose) { Text("←") }
        }
        content()
    }
}

private fun <T : androidx.lifecycle.ViewModel> simpleFactory(create: () -> T) =
    object : androidx.lifecycle.ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <VM : androidx.lifecycle.ViewModel> create(modelClass: Class<VM>): VM = create() as VM
    }
