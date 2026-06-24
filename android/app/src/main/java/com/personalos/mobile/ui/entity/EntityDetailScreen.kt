package com.personalos.mobile.ui.entity

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.personalos.mobile.ui.components.PosCard
import com.personalos.mobile.ui.components.PosEmptyState
import com.personalos.mobile.ui.components.PosListRow
import com.personalos.mobile.ui.components.PosLoadingView
import com.personalos.mobile.ui.navigation.AppNavigator
import com.personalos.mobile.ui.navigation.EntityRoute
import com.personalos.mobile.ui.theme.posDisplay

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EntityDetailScreen(
    viewModel: EntityDetailViewModel,
    title: String,
    nav: AppNavigator,
    onClose: () -> Unit,
) {
    val state by viewModel.state.collectAsState()
    Column(Modifier.fillMaxSize()) {
        TopAppBar(
            title = { Text(title) },
            navigationIcon = { IconButton(onClick = onClose) { Text("←") } },
        )
        Column(
            Modifier.verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            when {
                state.loading -> PosLoadingView()
                state.error != null -> PosEmptyState("Error", state.error.orEmpty(), "Retry") { viewModel.load() }
                state.entity != null -> {
                    val entity = state.entity!!
                    PosCard {
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Text(entity.title, style = posDisplay(22f))
                            Text("${entity.type} · ${entity.domain}", style = posDisplay(12f))
                            if (entity.content.isNotBlank()) Text(entity.content)
                        }
                    }
                    entity.architectureLayers().forEach { layer ->
                        PosCard {
                            Text(layer.layer, style = posDisplay(14f))
                            Text(layer.nodes.joinToString(", "))
                        }
                    }
                    if (state.relations.isNotEmpty()) {
                        Text("Related", style = posDisplay(16f))
                        state.relations.forEach { rel ->
                            PosListRow(rel.title, rel.domain) {
                                nav.onOpenEntity(EntityRoute(rel.id, rel.title))
                            }
                        }
                    }
                }
            }
        }
    }
}

private fun com.personalos.mobile.data.models.PosEntity.architectureLayers() =
    metadata?.architectureLayers.orEmpty()
