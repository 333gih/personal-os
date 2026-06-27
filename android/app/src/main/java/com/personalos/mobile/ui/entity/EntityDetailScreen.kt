package com.personalos.mobile.ui.entity

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.personalos.mobile.data.models.PosRelationWithEntity
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.personalos.mobile.data.models.PosEntitySection
import com.personalos.mobile.ui.components.PosActionButton
import com.personalos.mobile.ui.components.PosActionStyle
import com.personalos.mobile.ui.components.PosCard
import com.personalos.mobile.ui.components.PosChip
import com.personalos.mobile.ui.components.PosEmptyState
import com.personalos.mobile.ui.components.PosListRow
import com.personalos.mobile.ui.components.PosLoadingView
import com.personalos.mobile.ui.components.PosScreen
import com.personalos.mobile.ui.navigation.AppNavigator
import com.personalos.mobile.ui.navigation.EntityRoute
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay
import com.personalos.mobile.ui.theme.posLabel
import com.personalos.mobile.ui.work.PosArchitectureDiagram
import com.personalos.mobile.ui.work.PosArchitectureStyle
import com.personalos.mobile.util.architectureLayers
import com.personalos.mobile.util.designImageUrl
import com.personalos.mobile.util.detailSubtitle
import com.personalos.mobile.util.hasArchitecture
import com.personalos.mobile.util.metadataRows
import com.personalos.mobile.util.typeLabel

@Composable
fun EntityDetailScreen(
    viewModel: EntityDetailViewModel,
    title: String,
    initialSection: PosEntitySection,
    nav: AppNavigator,
    onClose: () -> Unit,
) {
    val state by viewModel.state.collectAsState()
    var section by remember(initialSection) { mutableStateOf(initialSection) }

    LaunchedEffect(state.entity?.id, state.relations.size, initialSection) {
        val entity = state.entity ?: return@LaunchedEffect
        val hasArch = entity.hasArchitecture()
        val hasRelated = state.relations.isNotEmpty()
        section = when {
            initialSection == PosEntitySection.ARCHITECTURE && hasArch -> PosEntitySection.ARCHITECTURE
            initialSection == PosEntitySection.RELATED && hasRelated -> PosEntitySection.RELATED
            else -> PosEntitySection.OVERVIEW
        }
    }

    PosScreen {
        Column(Modifier.fillMaxSize()) {
            when {
                state.loading -> PosLoadingView("Loading detail…")
                state.error != null -> PosEmptyState("Could not load", state.error.orEmpty(), "Retry") { viewModel.load() }
                state.entity != null -> {
                    val entity = state.entity!!
                    val hasArch = entity.hasArchitecture()
                    Column(
                        Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState())
                            .padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(20.dp),
                    ) {
                        Hero(entity)
                        if (hasArch || state.relations.isNotEmpty()) {
                            SectionPicker(section, hasArch, state.relations.isNotEmpty()) { section = it }
                        }
                        when (section) {
                            PosEntitySection.OVERVIEW -> OverviewSection(entity, hasArch) { section = PosEntitySection.ARCHITECTURE }
                            PosEntitySection.ARCHITECTURE -> ArchitectureSection(entity)
                            PosEntitySection.RELATED -> RelatedSection(state.relations, nav)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun Hero(entity: com.personalos.mobile.data.models.PosEntity) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(
                entity.typeLabel,
                modifier = Modifier
                    .clip(RoundedCornerShape(50))
                    .background(PosTheme.Primary.copy(0.1f))
                    .padding(horizontal = 10.dp, vertical = 6.dp),
                style = posLabel(),
                fontWeight = FontWeight.SemiBold,
                color = PosTheme.PrimaryDark,
            )
            if (entity.isActiveWork) {
                Text(
                    "Active",
                    modifier = Modifier
                        .clip(RoundedCornerShape(50))
                        .background(PosTheme.SuccessBg)
                        .padding(horizontal = 8.dp, vertical = 4.dp),
                    style = posDisplay(10f),
                    fontWeight = FontWeight.Bold,
                    color = PosTheme.Success,
                )
            }
        }
        Text(entity.title, style = posDisplay(26f))
        entity.detailSubtitle?.let { Text(it, color = PosTheme.Muted) }
        if (entity.tagList.isNotEmpty()) {
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                entity.tagList.forEach { tag ->
                    Text(
                        tag,
                        modifier = Modifier
                            .clip(RoundedCornerShape(50))
                            .background(PosTheme.Border.copy(0.4f))
                            .padding(horizontal = 8.dp, vertical = 4.dp),
                        style = posDisplay(10f),
                    )
                }
            }
        }
    }
}

@Composable
private fun SectionPicker(
    selected: PosEntitySection,
    hasArch: Boolean,
    hasRelated: Boolean,
    onSelect: (PosEntitySection) -> Unit,
) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        PosChip("Overview", selected == PosEntitySection.OVERVIEW) { onSelect(PosEntitySection.OVERVIEW) }
        if (hasArch) PosChip("Design", selected == PosEntitySection.ARCHITECTURE) { onSelect(PosEntitySection.ARCHITECTURE) }
        if (hasRelated) PosChip("Related", selected == PosEntitySection.RELATED) { onSelect(PosEntitySection.RELATED) }
    }
}

@Composable
private fun OverviewSection(entity: com.personalos.mobile.data.models.PosEntity, hasArch: Boolean, openDiagram: () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        if (hasArch) {
            PosCard {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("System preview", style = posLabel(), fontWeight = FontWeight.SemiBold, color = PosTheme.PrimaryDark)
                    PosArchitectureDiagram(
                        entity.architectureLayers,
                        entity.designImageUrl(),
                        PosArchitectureStyle.Compact,
                    )
                    PosActionButton("Open full diagram", style = PosActionStyle.Secondary, onClick = openDiagram)
                }
            }
        }
        PosCard {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text("Details", style = posLabel(), fontWeight = FontWeight.SemiBold, color = PosTheme.PrimaryDark)
                Text(entity.content.ifBlank { "No content yet." })
            }
        }
        MetadataGrid(entity)
    }
}

@Composable
private fun ArchitectureSection(entity: com.personalos.mobile.data.models.PosEntity) {
    PosCard {
        PosArchitectureDiagram(
            entity.architectureLayers,
            entity.designImageUrl(),
            PosArchitectureStyle.Full,
        )
    }
}

@Composable
private fun MetadataGrid(entity: com.personalos.mobile.data.models.PosEntity) {
    val rows = entity.metadataRows
    if (rows.isEmpty()) return
    PosCard {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("Metadata", style = posLabel(), fontWeight = FontWeight.SemiBold, color = PosTheme.PrimaryDark)
            rows.forEach { row ->
                Row(Modifier.fillMaxWidth()) {
                    Text(row.label, style = posLabel(), color = PosTheme.Muted, modifier = Modifier.weight(0.35f))
                    Text(row.value, modifier = Modifier.weight(0.65f))
                }
            }
        }
    }
}

@Composable
private fun RelatedSection(relations: List<PosRelationWithEntity>, nav: AppNavigator) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        relations.forEach { rel ->
            PosListRow(rel.linkedTitle, rel.subtitle.ifBlank { rel.linkedDomain }) {
                nav.onOpenEntity(EntityRoute(rel.linkedId, rel.linkedTitle))
            }
        }
    }
}
