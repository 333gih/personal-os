package com.personalos.mobile.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posCaps
import com.personalos.mobile.ui.theme.posLabel
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.graphicsLayer
import com.personalos.mobile.ui.theme.posDisplay

@Composable
fun PosScreen(content: @Composable ColumnScope.() -> Unit) {
    Box(Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        listOf(PosTheme.Background, PosTheme.Card, PosTheme.Background),
                    ),
                ),
        ) {
            Canvas(Modifier.fillMaxSize()) {
                val step = 28.dp.toPx()
                var y = step
                while (y < size.height) {
                    drawLine(
                        PosTheme.PaperLine.copy(alpha = 0.35f),
                        Offset(0f, y),
                        Offset(size.width, y),
                        strokeWidth = 1f,
                    )
                    y += step
                }
            }
        }
        Column(Modifier.fillMaxSize(), content = content)
    }
}

@Composable
fun PosCard(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(PosTheme.CardRadius))
            .background(PosTheme.Card)
            .padding(16.dp),
        content = content,
    )
}

@Composable
fun PosSectionHeader(
    title: String,
    eyebrow: String? = null,
    action: String? = null,
    onAction: (() -> Unit)? = null,
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.Bottom,
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            eyebrow?.let {
                Text(it, style = MaterialTheme.typography.labelSmall, color = PosTheme.Muted, fontWeight = FontWeight.Medium)
            }
            Text(title, style = posDisplay(20f), color = PosTheme.Ink)
        }
        if (action != null && onAction != null) {
            Button(onClick = onAction, colors = ButtonDefaults.textButtonColors(contentColor = PosTheme.PrimaryDark)) {
                Text(action, style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

@Composable
fun PosNoteDivider() {
    Row(
        Modifier.fillMaxWidth().padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(Modifier.weight(1f).height(1.dp).background(PosTheme.Border))
        Icon(Icons.Default.Book, contentDescription = null, tint = PosTheme.Primary.copy(alpha = 0.7f), modifier = Modifier.size(14.dp))
        Box(Modifier.weight(1f).height(1.dp).background(PosTheme.Border))
    }
}

@Composable
fun PosFloatingCaptureButton(onClick: () -> Unit, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .size(54.dp)
            .shadow(8.dp, CircleShape)
            .clip(CircleShape)
            .background(PosTheme.Ink)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Icon(Icons.Default.Edit, contentDescription = "Capture", tint = Color.White)
    }
}

@Composable
fun PosActionTile(
    title: String,
    icon: ImageVector,
    filled: Boolean,
    onClick: () -> Unit,
) {
    Column(
        modifier = Modifier
            .size(width = 118.dp, height = 96.dp)
            .clip(RoundedCornerShape(PosTheme.CardRadius))
            .background(if (filled) PosTheme.Ink else PosTheme.Card)
            .border(1.dp, if (filled) Color.Transparent else PosTheme.Border.copy(0.8f), RoundedCornerShape(PosTheme.CardRadius))
            .clickable(onClick = onClick)
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(icon, contentDescription = null, tint = if (filled) PosTheme.Background else PosTheme.Ink)
        Text(title, fontWeight = FontWeight.SemiBold, color = if (filled) PosTheme.Background else PosTheme.Ink)
    }
}

@Composable
fun PosQuickActionRow(
    onNewNote: () -> Unit,
    onStudy: () -> Unit,
    onReading: () -> Unit,
    onSearch: () -> Unit,
) {
    Row(
        Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        PosActionTile("New note", Icons.Default.Edit, filled = true, onClick = onNewNote)
        PosActionTile("Study log", Icons.AutoMirrored.Filled.MenuBook, filled = false, onClick = onStudy)
        PosActionTile("Reading", Icons.Default.Book, filled = false, onClick = onReading)
        PosActionTile("Search", Icons.Default.Search, filled = false, onClick = onSearch)
    }
}

@Composable
fun PosFocusCard(
    learning: Int,
    work: Int,
    progress: Int,
    onClick: () -> Unit,
) {
    val total = learning + work
    PosCard(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("Today's focus", color = PosTheme.Focus, style = posDisplay(12f), fontWeight = FontWeight.SemiBold)
            Text(
                if (total > 0) "$total entries" else "Start a note",
                style = posDisplay(34f),
                color = PosTheme.Ink,
            )
            Text(
                if (total > 0) "You have been building across learning and work."
                else "Capture one thought in Inbox to begin tracking.",
                color = PosTheme.Muted,
            )
            LinearProgressIndicator(
                progress = { (if (total > 0) maxOf(progress, 10) else 0) / 100f },
                modifier = Modifier.fillMaxWidth().height(6.dp).clip(CircleShape),
                color = PosTheme.Focus,
                trackColor = PosTheme.Border.copy(0.7f),
            )
        }
    }
}

@Composable
fun PosShelfHighlightCard(
    domain: String,
    title: String,
    content: String,
    onClick: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(PosTheme.CardRadius))
            .background(PosTheme.Card)
            .border(1.dp, PosTheme.Border, RoundedCornerShape(PosTheme.CardRadius))
            .clickable(onClick = onClick)
            .padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text(domain, style = MaterialTheme.typography.labelSmall, color = PosTheme.Muted, fontWeight = FontWeight.Medium)
        Text(title, style = posDisplay(22f), color = PosTheme.Ink)
        Text(content, color = PosTheme.Muted, maxLines = 3)
        Text("Open entry", color = PosTheme.PrimaryDark, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.labelLarge)
    }
}

@Composable
fun PosLoadingView(label: String = "Loading…") {
    Box(Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
            CircularProgressIndicator(color = PosTheme.PrimaryDark)
            Text(label, color = PosTheme.Muted)
        }
    }
}

@Composable
fun PosEmptyState(
    title: String,
    message: String,
    actionTitle: String? = null,
    icon: ImageVector = Icons.Default.Book,
    onAction: (() -> Unit)? = null,
) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Box(
            Modifier
                .size(52.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(PosTheme.Border.copy(0.35f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(icon, contentDescription = null, tint = PosTheme.Muted, modifier = Modifier.size(28.dp))
        }
        Text(title, style = posDisplay(18f), color = PosTheme.Ink)
        Text(message, color = PosTheme.Muted)
        if (actionTitle != null && onAction != null) {
            PosActionButton(actionTitle, style = PosActionStyle.Secondary, onClick = onAction)
        }
    }
}

@Composable
fun PosMetricCard(
    label: String,
    value: String,
    hint: String,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    accent: Color = PosTheme.Muted,
    onClick: () -> Unit,
) {
    PosCard(modifier = modifier.clickable(onClick = onClick)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(label, style = posLabel(), color = PosTheme.Muted)
            icon?.let { Icon(it, contentDescription = null, tint = accent, modifier = Modifier.size(20.dp)) }
        }
        Text(value, style = posDisplay(26f), color = PosTheme.Ink)
        Text(hint, style = posLabel(), color = PosTheme.Muted)
    }
}

@Composable
fun PosListRow(
    title: String,
    subtitle: String? = null,
    badge: String? = null,
    icon: ImageVector = Icons.Default.Book,
    iconTint: Color = PosTheme.Muted,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(PosTheme.Card)
            .border(1.dp, PosTheme.Border.copy(0.65f), RoundedCornerShape(16.dp))
            .clickable(onClick = onClick)
            .padding(14.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            Modifier
                .size(44.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(PosTheme.Border.copy(0.45f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(icon, contentDescription = null, tint = iconTint)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            badge?.let {
                Text(it, style = MaterialTheme.typography.labelSmall, color = PosTheme.Muted, fontWeight = FontWeight.Medium)
            }
            Text(title, fontWeight = FontWeight.Medium, color = PosTheme.Ink, maxLines = 2)
            subtitle?.takeIf { it.isNotBlank() }?.let {
                Text(it, style = MaterialTheme.typography.bodySmall, color = PosTheme.Muted, maxLines = 2)
            }
        }
        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = PosTheme.Muted.copy(0.8f), modifier = Modifier.size(18.dp))
    }
}

@Composable
fun PosChip(text: String, selected: Boolean, onClick: () -> Unit) {
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    Text(
        text,
        modifier = Modifier
            .graphicsLayer { scaleX = if (pressed) 0.96f else 1f; scaleY = if (pressed) 0.96f else 1f }
            .clip(RoundedCornerShape(50))
            .background(if (selected) PosTheme.Ink else PosTheme.Card)
            .border(1.dp, if (selected) Color.Transparent else PosTheme.Border, RoundedCornerShape(50))
            .clickable(interactionSource = interaction, indication = null, onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp),
        color = if (selected) PosTheme.Background else PosTheme.Ink,
        fontWeight = FontWeight.Medium,
    )
}

enum class PosActionStyle { Primary, Secondary, Ghost }

@Composable
fun PosActionButton(
    text: String,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    style: PosActionStyle = PosActionStyle.Primary,
    onClick: () -> Unit,
) {
    val bg = when (style) {
        PosActionStyle.Primary -> PosTheme.PrimaryDark
        PosActionStyle.Secondary -> PosTheme.Card
        PosActionStyle.Ghost -> Color.Transparent
    }
    val fg = when (style) {
        PosActionStyle.Primary -> Color.White
        PosActionStyle.Secondary -> PosTheme.Ink
        PosActionStyle.Ghost -> PosTheme.PrimaryDark
    }
    Row(
        modifier
            .clip(RoundedCornerShape(12.dp))
            .background(bg)
            .then(if (style == PosActionStyle.Secondary) Modifier.border(1.dp, PosTheme.Border, RoundedCornerShape(12.dp)) else Modifier)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        icon?.let { Icon(it, contentDescription = null, tint = fg, modifier = Modifier.size(18.dp)) }
        Text(
            text,
            color = fg,
            fontWeight = FontWeight.SemiBold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            softWrap = false,
        )
    }
}

@Composable
fun PosHubMenuRow(
    title: String,
    subtitle: String,
    icon: ImageVector,
    onClick: () -> Unit,
) {
    PosCard(modifier = Modifier.clickable(onClick = onClick)) {
        Row(horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, contentDescription = null, tint = PosTheme.PrimaryDark, modifier = Modifier.size(28.dp))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(title, fontWeight = FontWeight.SemiBold, color = PosTheme.Ink)
                Text(subtitle, style = posLabel(), color = PosTheme.Muted)
            }
            Icon(Icons.Default.ChevronRight, contentDescription = null, tint = PosTheme.Muted)
        }
    }
}

@Composable
fun PosMoreMenuRow(
    title: String,
    subtitle: String? = null,
    icon: ImageVector,
    iconTint: Color = PosTheme.PrimaryDark,
    onClick: () -> Unit,
) {
    PosListRow(title = title, subtitle = subtitle, icon = icon, iconTint = iconTint, onClick = onClick)
}

@Composable
fun PosJournalDateStamp(name: String) {
    Text("Good day, $name", style = posDisplay(22f), color = PosTheme.Ink, modifier = Modifier.padding(bottom = 4.dp))
}

@Composable
fun PosPrimaryButton(text: String, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        modifier = modifier,
        colors = ButtonDefaults.buttonColors(containerColor = PosTheme.PrimaryDark),
    ) { Text(text, maxLines = 1, overflow = TextOverflow.Ellipsis) }
}
