package com.personalos.mobile.ui.shell

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Work
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.personalos.mobile.data.models.PosTab
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay

@Composable
fun PosAppHeader(
    title: String,
    initials: String,
    onAvatarTap: () -> Unit,
    onSettingsTap: () -> Unit,
) {
    Row(
        Modifier
            .fillMaxWidth()
            .statusBarsPadding()
            .background(PosTheme.Background.copy(alpha = 0.96f))
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(PosTheme.Primary.copy(alpha = 0.12f))
                .clickable(onClick = onAvatarTap),
            contentAlignment = Alignment.Center,
        ) {
            Text(initials, color = PosTheme.PrimaryDark, fontWeight = FontWeight.SemiBold)
        }
        Spacer(Modifier.weight(1f))
        Text(title, style = posDisplay(17f), color = PosTheme.Ink, maxLines = 1)
        Spacer(Modifier.weight(1f))
        IconButton(onClick = onSettingsTap, modifier = Modifier.size(36.dp)) {
            Icon(Icons.Default.Settings, contentDescription = "Settings", tint = PosTheme.PrimaryDark)
        }
    }
}

@Composable
fun PosBottomTabBar(selected: PosTab, onSelect: (PosTab) -> Unit) {
    Column {
        HorizontalDivider(color = PosTheme.Border)
        Row(
            Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .background(PosTheme.Card)
                .height(PosTheme.TabBarHeight)
                .padding(top = 8.dp, bottom = 8.dp),
        ) {
            PosTab.entries.forEach { tab ->
                val isSelected = tab == selected
                Column(
                    Modifier
                        .weight(1f)
                        .clickable { onSelect(tab) },
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    Icon(
                        tab.icon(),
                        contentDescription = tab.title,
                        tint = if (isSelected) PosTheme.PrimaryDark else PosTheme.Muted,
                        modifier = Modifier.size(22.dp),
                    )
                    Text(
                        tab.title,
                        style = posDisplay(10f, FontWeight.Medium),
                        color = if (isSelected) PosTheme.PrimaryDark else PosTheme.Muted,
                    )
                    Box(
                        Modifier
                            .size(4.dp)
                            .clip(CircleShape)
                            .background(if (isSelected) PosTheme.PrimaryDark else PosTheme.Background),
                    )
                }
            }
        }
    }
}

private fun PosTab.icon(): ImageVector = when (this) {
    PosTab.HOME -> Icons.Default.Home
    PosTab.WORK -> Icons.Default.Work
    PosTab.LEARNING -> Icons.AutoMirrored.Filled.MenuBook
    PosTab.SEARCH -> Icons.Default.Search
    PosTab.MORE -> Icons.Default.MoreHoriz
}

@Composable
fun PosCloseBar(title: String, onClose: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .statusBarsPadding()
            .background(PosTheme.Background)
            .padding(horizontal = 8.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconButton(onClick = onClose) {
            Icon(Icons.Default.Close, contentDescription = "Close", tint = PosTheme.PrimaryDark)
        }
        Text(title, style = posDisplay(17f), color = PosTheme.Ink, maxLines = 1, modifier = Modifier.weight(1f))
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PosModalBottomSheet(
    onDismiss: () -> Unit,
    content: @Composable () -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = PosTheme.Card,
        dragHandle = null,
    ) {
        content()
    }
}

@Composable
fun PosOverlayScaffold(
    title: String,
    onClose: () -> Unit,
    bottomBar: (@Composable () -> Unit)? = null,
    content: @Composable () -> Unit,
) {
    Column(
        Modifier
            .fillMaxSize()
            .background(PosTheme.Background),
    ) {
        PosCloseBar(title, onClose)
        Box(Modifier.weight(1f).fillMaxSize()) { content() }
        bottomBar?.invoke()
    }
}
