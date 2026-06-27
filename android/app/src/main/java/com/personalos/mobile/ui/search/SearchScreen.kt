package com.personalos.mobile.ui.search

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.personalos.mobile.ui.components.PosActionButton
import com.personalos.mobile.ui.components.PosActionStyle
import com.personalos.mobile.ui.components.PosCard
import com.personalos.mobile.ui.components.PosChip
import com.personalos.mobile.ui.components.PosEmptyState
import com.personalos.mobile.ui.components.PosLoadingView
import com.personalos.mobile.ui.components.PosScreen
import com.personalos.mobile.ui.navigation.AppNavigator
import com.personalos.mobile.ui.navigation.EntityRoute
import com.personalos.mobile.ui.navigation.WebRoute
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay
import com.personalos.mobile.ui.theme.posLabel
import com.personalos.mobile.util.PosFormatting

@Composable
fun SearchScreen(viewModel: SearchViewModel, nav: AppNavigator) {
    val state by viewModel.state.collectAsState()

    LaunchedEffect(state.query) {
        if (state.query.length >= 2) {
            kotlinx.coroutines.delay(350)
            viewModel.search()
        }
    }

    PosScreen {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            OutlinedTextField(
                value = state.query,
                onValueChange = viewModel::setQuery,
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Search your OS") },
            )
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf("hybrid" to "Hybrid", "semantic" to "Semantic", "keyword" to "Full text").forEach { (mode, label) ->
                    PosChip(label, selected = state.mode == mode) { viewModel.setMode(mode) }
                }
            }
            PosActionButton("Search", style = PosActionStyle.Secondary, onClick = viewModel::search)
            if (state.loading) PosLoadingView()
            state.recent.forEach { recent ->
                PosCard(modifier = Modifier.fillMaxWidth().clickableSafe { viewModel.setQuery(recent); viewModel.search() }) {
                    Text(recent, fontWeight = FontWeight.Medium)
                    Text("Recent query", style = posLabel(), color = PosTheme.Muted)
                }
            }
            if (!state.loading && state.hits.isEmpty() && state.query.isNotBlank()) {
                PosEmptyState(
                    title = "No matches",
                    message = "Try a different mode or capture a note to inbox.",
                    actionTitle = "Open inbox",
                    onAction = { nav.onOpenWeb(WebRoute.path("/inbox", "Inbox")) },
                )
            }
            state.hits.forEach { hit ->
                PosCard(modifier = Modifier.fillMaxWidth().clickableSafe {
                    nav.onOpenEntity(EntityRoute(hit.id, hit.title))
                }) {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text(PosFormatting.domainLabel(hit.domain), style = posLabel(), color = PosTheme.PrimaryDark)
                        if (hit.score > 0) {
                            Text("%.0f".format(hit.score), style = posLabel(), color = PosTheme.Muted)
                        }
                    }
                    Text(hit.title, style = posDisplay(16f), fontWeight = FontWeight.SemiBold)
                    Text(hit.snippet.ifBlank { hit.domain }, color = PosTheme.Muted, maxLines = 3)
                }
            }
            state.error?.let { Text(it, color = PosTheme.Error) }
        }
    }
}

private fun Modifier.clickableSafe(onClick: () -> Unit): Modifier = clickable(onClick = onClick)
