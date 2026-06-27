package com.personalos.mobile.ui.work

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.personalos.mobile.data.models.PosArchitectureLayer
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay
import com.personalos.mobile.ui.theme.posLabel

enum class PosArchitectureStyle { Compact, Full }

private val layerColors = listOf(
    Color(0xFFB03345),
    Color(0xFF3B668C),
    Color(0xFF47856B),
    Color(0xFF8C619E),
    Color(0xFFB87A38),
)

@Composable
fun PosArchitectureDiagram(
    layers: List<PosArchitectureLayer>,
    imageUrl: String?,
    style: PosArchitectureStyle = PosArchitectureStyle.Full,
    modifier: Modifier = Modifier,
) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(10.dp)) {
        when {
            layers.isNotEmpty() -> layers.forEachIndexed { index, layer ->
                ArchitectureLayerBand(layer, layerColors[index % layerColors.size], style == PosArchitectureStyle.Compact)
                if (index < layers.lastIndex) {
                    Icon(Icons.Default.ArrowDownward, contentDescription = null, tint = PosTheme.Muted, modifier = Modifier.align(Alignment.CenterHorizontally))
                }
            }
            !imageUrl.isNullOrBlank() -> {
                Text("Reference diagram", style = posLabel(), fontWeight = FontWeight.SemiBold, color = PosTheme.PrimaryDark)
                Text(imageUrl, style = posDisplay(11f), color = PosTheme.Muted)
            }
            else -> Text("No architecture diagram yet.", color = PosTheme.Muted)
        }
    }
}

@Composable
private fun ArchitectureLayerBand(layer: PosArchitectureLayer, accent: Color, compact: Boolean) {
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(accent.copy(alpha = 0.06f))
            .border(1.dp, accent.copy(alpha = 0.18f), RoundedCornerShape(14.dp))
            .padding(if (compact) 10.dp else 14.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(8.dp).clip(CircleShape).background(accent.copy(alpha = 0.85f)))
                Text(layer.layer.uppercase(), style = posLabel(), fontWeight = FontWeight.Bold, color = accent)
            }
            Text("${layer.nodes.size} nodes", style = posLabel(), color = PosTheme.Muted)
        }
        Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            layer.nodes.forEachIndexed { i, node ->
                Text(
                    node,
                    modifier = Modifier
                        .clip(RoundedCornerShape(8.dp))
                        .background(PosTheme.Background.copy(alpha = 0.85f))
                        .border(1.dp, accent.copy(alpha = 0.2f), RoundedCornerShape(8.dp))
                        .padding(horizontal = 10.dp, vertical = 6.dp),
                    style = posDisplay(if (compact) 10f else 11f),
                    color = PosTheme.Ink,
                )
                if (i < layer.nodes.lastIndex) {
                    Icon(Icons.Default.ArrowForward, contentDescription = null, tint = PosTheme.Muted.copy(0.55f), modifier = Modifier.size(14.dp).align(Alignment.CenterVertically))
                }
            }
        }
    }
}
