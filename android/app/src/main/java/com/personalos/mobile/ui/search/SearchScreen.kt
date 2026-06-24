package com.personalos.mobile.ui.search

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.FilterChip
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.personalos.mobile.ui.components.PosListRow
import com.personalos.mobile.ui.components.PosLoadingView
import com.personalos.mobile.ui.components.PosPrimaryButton
import com.personalos.mobile.ui.components.PosScreen
import com.personalos.mobile.ui.navigation.AppNavigator
import com.personalos.mobile.ui.navigation.EntityRoute
import com.personalos.mobile.ui.theme.posDisplay

@Composable
fun SearchScreen(viewModel: SearchViewModel, nav: AppNavigator) {
    val state by viewModel.state.collectAsState()
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
                listOf("hybrid", "semantic", "keyword").forEach { mode ->
                    FilterChip(selected = state.mode == mode, onClick = { viewModel.setMode(mode) }, label = { Text(mode) })
                }
            }
            PosPrimaryButton("Search", onClick = viewModel::search)
            if (state.loading) PosLoadingView()
            state.recent.forEach { recent ->
                PosListRow(recent, "Recent") {
                    viewModel.setQuery(recent)
                    viewModel.search()
                }
            }
            state.hits.forEach { hit ->
                PosListRow(hit.title, hit.snippet.ifBlank { hit.domain }) {
                    nav.onOpenEntity(EntityRoute(hit.id, hit.title))
                }
            }
            state.error?.let { Text(it) }
        }
    }
}
