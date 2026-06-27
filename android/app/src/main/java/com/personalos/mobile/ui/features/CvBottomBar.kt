package com.personalos.mobile.ui.features

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.personalos.mobile.ui.components.PosActionButton
import com.personalos.mobile.ui.components.PosActionStyle
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posLabel

@Composable
fun PosCvBottomBar(
    saveTitle: String,
    isSystem: Boolean,
    isExporting: Boolean,
    onSave: () -> Unit,
    onValidate: () -> Unit,
    onPdf: () -> Unit,
    onShare: () -> Unit,
) {
    Column(
        Modifier
            .fillMaxWidth()
            .background(PosTheme.Card)
            .navigationBarsPadding()
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        if (isSystem) {
            Text(
                "Saving creates “My CV” — system template stays unchanged",
                style = posLabel(),
                color = PosTheme.Muted,
                maxLines = 2,
            )
        }
        PosActionButton(
            text = saveTitle,
            style = PosActionStyle.Primary,
            modifier = Modifier.fillMaxWidth(),
            onClick = onSave,
        )
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            PosCvToolButton(
                text = "Validate",
                icon = Icons.Default.CheckCircle,
                modifier = Modifier.weight(1f),
                onClick = onValidate,
            )
            PosCvToolButton(
                text = if (isExporting) "…" else "PDF",
                icon = Icons.Default.Description,
                modifier = Modifier.weight(1f),
                onClick = onPdf,
            )
            PosCvToolButton(
                text = "Share",
                icon = Icons.Default.Share,
                modifier = Modifier.weight(1f),
                onClick = onShare,
            )
        }
    }
}

@Composable
private fun PosCvToolButton(
    text: String,
    icon: ImageVector,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    Row(
        modifier
            .height(44.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(PosTheme.Card)
            .border(1.dp, PosTheme.Border, RoundedCornerShape(12.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 8.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, contentDescription = null, tint = PosTheme.Ink, modifier = Modifier.size(16.dp))
        Text(
            text,
            color = PosTheme.Ink,
            fontWeight = FontWeight.SemiBold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.padding(start = 4.dp),
        )
    }
}
