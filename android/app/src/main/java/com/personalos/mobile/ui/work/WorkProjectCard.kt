package com.personalos.mobile.ui.work

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowOutward
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.personalos.mobile.data.models.PosEntity
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay
import com.personalos.mobile.util.architectureLayers
import com.personalos.mobile.util.designImageUrl
import com.personalos.mobile.util.hasArchitecture
import com.personalos.mobile.util.periodLabel

@Composable
fun WorkProjectCard(
    item: PosEntity,
    isPrimary: Boolean,
    onOpen: () -> Unit,
    onArchitecture: () -> Unit,
    onAddToCv: (() -> Unit)? = null,
) {
    val hasArch = item.hasArchitecture()
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(PosTheme.CardRadius))
            .background(PosTheme.Card)
            .border(1.dp, PosTheme.Border.copy(0.75f), RoundedCornerShape(PosTheme.CardRadius)),
    ) {
        Column(
            Modifier
                .fillMaxWidth()
                .clickable(onClick = onOpen)
                .padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(item.title, fontWeight = FontWeight.SemiBold, color = PosTheme.Ink, maxLines = 2)
                    Text(projectSubtitle(item), style = posDisplay(11f), color = PosTheme.Muted, maxLines = 2)
                }
                StatusBadge(item.isActiveWork, isPrimary)
                Icon(Icons.Default.ChevronRight, contentDescription = null, tint = PosTheme.Muted.copy(0.7f), modifier = Modifier.size(18.dp))
            }
            if (item.tagList.isNotEmpty()) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    item.tagList.take(4).forEach { tag ->
                        Text(
                            tag,
                            modifier = Modifier
                                .clip(RoundedCornerShape(6.dp))
                                .background(PosTheme.Border.copy(0.35f))
                                .padding(horizontal = 8.dp, vertical = 4.dp),
                            style = posDisplay(10f),
                        )
                    }
                }
            }
            if (hasArch) {
                WorkArchitecturePreview(item)
            }
        }
        if (hasArch) {
            HorizontalDivider(Modifier.padding(horizontal = 14.dp), color = PosTheme.Border)
            Row(
                Modifier
                    .fillMaxWidth()
                    .clickable(onClick = onArchitecture)
                    .padding(horizontal = 14.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Default.GridView, contentDescription = null, tint = PosTheme.PrimaryDark, modifier = Modifier.size(18.dp))
                Text("View architecture", fontWeight = FontWeight.Medium, color = PosTheme.PrimaryDark, modifier = Modifier.weight(1f))
                Icon(Icons.Default.ArrowOutward, contentDescription = null, tint = PosTheme.PrimaryDark, modifier = Modifier.size(16.dp))
            }
        }
        if (onAddToCv != null) {
            HorizontalDivider(Modifier.padding(horizontal = 14.dp), color = PosTheme.Border)
            Row(
                Modifier
                    .fillMaxWidth()
                    .clickable(onClick = onAddToCv)
                    .padding(horizontal = 14.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("Add to CV…", fontWeight = FontWeight.Medium, color = PosTheme.PrimaryDark, modifier = Modifier.weight(1f))
                Icon(Icons.Default.ChevronRight, contentDescription = null, tint = PosTheme.PrimaryDark, modifier = Modifier.size(16.dp))
            }
        }
    }
}

@Composable
private fun StatusBadge(active: Boolean, isPrimary: Boolean) {
    Text(
        if (active) "Active" else "Done",
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(if (isPrimary && active) PosTheme.SuccessBg else PosTheme.Border.copy(0.45f))
            .padding(horizontal = 8.dp, vertical = 4.dp),
        style = posDisplay(10f),
        fontWeight = FontWeight.Bold,
        color = if (isPrimary && active) PosTheme.Success else PosTheme.Muted,
    )
}

private fun projectSubtitle(item: PosEntity): String =
    listOfNotNull(item.metadata?.company, item.metadata?.role, item.metadata?.periodLabel())
        .filter { it.isNotBlank() }
        .joinToString(" · ")

@Composable
private fun WorkArchitecturePreview(entity: PosEntity) {
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .background(PosTheme.Border.copy(0.2f))
            .padding(10.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        val layer = entity.architectureLayers.firstOrNull()
        if (layer != null) {
            Text(layer.layer.uppercase(), style = posDisplay(10f), fontWeight = FontWeight.Bold, color = PosTheme.PrimaryDark.copy(0.85f))
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                layer.nodes.take(5).forEach { node ->
                    Text(
                        node,
                        modifier = Modifier
                            .clip(RoundedCornerShape(6.dp))
                            .background(PosTheme.Background)
                            .border(1.dp, PosTheme.Border.copy(0.5f), RoundedCornerShape(6.dp))
                            .padding(horizontal = 7.dp, vertical = 4.dp),
                        style = posDisplay(10f),
                        maxLines = 1,
                    )
                }
            }
        } else {
            entity.designImageUrl()?.let {
                PosArchitectureDiagram(emptyList(), it, PosArchitectureStyle.Compact)
            }
        }
    }
}
