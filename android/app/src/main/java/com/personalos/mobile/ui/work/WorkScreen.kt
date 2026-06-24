package com.personalos.mobile.ui.work

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
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
import com.personalos.mobile.data.models.PosEntity
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
fun WorkScreen(viewModel: WorkViewModel, nav: AppNavigator) {
    val state by viewModel.state.collectAsState()
    LaunchedEffect(Unit) { viewModel.load() }

    PosScreen {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text("Career Path", style = posDisplay(24f))
            when {
                state.loading -> PosLoadingView()
                state.error != null -> PosEmptyState("Error", state.error.orEmpty(), "Retry") { viewModel.load() }
                else -> {
                    val projects = state.entities.filter { it.type.contains("project", true) || it.isActiveWork }
                    val roles = state.entities.filter { it.metadata?.role != null }
                    if (roles.isNotEmpty()) {
                        Text("Experience", style = posDisplay(18f))
                        roles.forEach { PosEntityRow(it, nav) }
                    }
                    Text("Active projects", style = posDisplay(18f))
                    projects.forEach { PosEntityRow(it, nav) }
                    RowTools(nav)
                }
            }
        }
    }
}

@Composable
private fun PosEntityRow(entity: PosEntity, nav: AppNavigator) {
    PosCard {
        PosListRow(
            entity.title,
            listOfNotNull(entity.metadata?.company, entity.metadata?.role).joinToString(" · ").ifBlank { entity.domain },
        ) {
            nav.onOpenEntity(EntityRoute(entity.id, entity.title))
        }
    }
}

@Composable
private fun RowTools(nav: AppNavigator) {
    PosCard {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("Career tools", style = posDisplay(16f), color = PosTheme.PrimaryDark)
            PosPrimaryButton("CV Hub", Modifier.fillMaxWidth()) { nav.onOpenCv() }
            PosPrimaryButton("Job Scout", Modifier.fillMaxWidth()) { nav.onOpenJobScout() }
            PosPrimaryButton("Import project", Modifier.fillMaxWidth()) { nav.onOpenWorkImport() }
            PosPrimaryButton("Interview prep", Modifier.fillMaxWidth()) { nav.onOpenInterviewPrep() }
            PosPrimaryButton("+ Work hub", Modifier.fillMaxWidth()) { nav.onOpenWorkHub() }
        }
    }
}
