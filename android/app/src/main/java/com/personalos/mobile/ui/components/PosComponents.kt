package com.personalos.mobile.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay

@Composable
fun PosScreen(content: @Composable ColumnScope.() -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(PosTheme.Background, PosTheme.Card, PosTheme.Background),
                ),
            ),
        content = content,
    )
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
fun PosSectionHeader(title: String, action: String? = null, onAction: (() -> Unit)? = null) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(title, style = MaterialTheme.typography.titleMedium, color = PosTheme.Ink)
        if (action != null && onAction != null) {
            Button(onClick = onAction, colors = ButtonDefaults.textButtonColors(contentColor = PosTheme.PrimaryDark)) {
                Text(action)
            }
        }
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
    onAction: (() -> Unit)? = null,
) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(title, style = posDisplay(20f), color = PosTheme.Ink)
        Text(message, color = PosTheme.Muted)
        if (actionTitle != null && onAction != null) {
            Button(onClick = onAction, colors = ButtonDefaults.buttonColors(containerColor = PosTheme.PrimaryDark)) {
                Text(actionTitle)
            }
        }
    }
}

@Composable
fun PosMetricCard(
    label: String,
    value: String,
    hint: String,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    PosCard(modifier = modifier) {
        Button(onClick = onClick, colors = ButtonDefaults.textButtonColors(contentColor = PosTheme.Ink)) {
            Column(Modifier.fillMaxWidth()) {
                Text(label.uppercase(), style = MaterialTheme.typography.labelSmall, color = PosTheme.Muted)
                Text(value, style = posDisplay(24f), color = PosTheme.PrimaryDark)
                Text(hint, color = PosTheme.Muted, fontWeight = FontWeight.Medium)
            }
        }
    }
}

@Composable
fun PosListRow(title: String, subtitle: String? = null, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        colors = ButtonDefaults.textButtonColors(contentColor = PosTheme.Ink),
    ) {
        Column(Modifier.fillMaxWidth()) {
            Text(title, fontWeight = FontWeight.SemiBold)
            subtitle?.let { Text(it, color = PosTheme.Muted) }
        }
    }
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
    ) { Text(text) }
}
