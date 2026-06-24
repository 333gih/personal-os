package com.personalos.mobile.ui.learning

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.personalos.mobile.data.models.PosLearningTrack
import com.personalos.mobile.ui.components.PosCard
import com.personalos.mobile.ui.components.PosEmptyState
import com.personalos.mobile.ui.components.PosListRow
import com.personalos.mobile.ui.components.PosLoadingView
import com.personalos.mobile.ui.components.PosPrimaryButton
import com.personalos.mobile.ui.components.PosScreen
import com.personalos.mobile.ui.navigation.AppNavigator
import com.personalos.mobile.ui.navigation.EntityRoute
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay

@Composable
fun LearningScreen(viewModel: LearningViewModel, nav: AppNavigator) {
    val state by viewModel.state.collectAsState()
    LaunchedEffect(Unit) { viewModel.load() }

    PosScreen {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            when {
                state.loading -> PosLoadingView("Loading learning…")
                state.error != null -> PosEmptyState("Error", state.error.orEmpty(), "Retry") { viewModel.load() }
                else -> {
                    state.today?.dsaFocus?.let { focus ->
                        PosCard {
                            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                Text("DSA daily focus", color = PosTheme.Focus, style = posDisplay(12f))
                                Text(focus.title.ifBlank { focus.pattern }, style = posDisplay(20f))
                                focus.entityId?.let { id ->
                                    PosPrimaryButton("Open lesson") {
                                        nav.onOpenLearningLesson(id, focus.title)
                                    }
                                }
                            }
                        }
                    }
                    state.today?.blocks?.take(5)?.forEach { block ->
                        PosListRow(block.title, block.subtitle) {
                            block.entityId?.let { nav.onOpenLearningLesson(it, block.title) }
                        }
                    }
                    Text("Roadmap", style = posDisplay(18f))
                    state.entities.take(20).forEach { entity ->
                        PosListRow(entity.title, entity.metadata?.track ?: entity.domain) {
                            nav.onOpenEntity(EntityRoute(entity.id, entity.title))
                        }
                    }
                    PosPrimaryButton("+ Learning hub") { nav.onOpenLearningHub() }
                }
            }
        }
    }
}

@Composable
fun LearningHubSheet(nav: AppNavigator, onDismiss: () -> Unit) {
    Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Learning hub", style = posDisplay(20f))
        PosPrimaryButton("Add DSA entry") { nav.onOpenLearningAdd(PosLearningTrack.DSA); onDismiss() }
        PosPrimaryButton("Add English entry") { nav.onOpenLearningAdd(PosLearningTrack.ENGLISH); onDismiss() }
        PosPrimaryButton("AI coach") { nav.onOpenLearningCoach(PosLearningTrack.DSA, null, ""); onDismiss() }
        PosPrimaryButton("Schedule") { nav.onOpenLearningSchedule(); onDismiss() }
        PosPrimaryButton("Notification log") { nav.onOpenNotificationLog(); onDismiss() }
        PosPrimaryButton("Web board") { nav.onOpenWeb(com.personalos.mobile.ui.navigation.WebRoute.path("/learning", "Learning")); onDismiss() }
    }
}
