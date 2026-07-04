package com.personalos.mobile.ui.more

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Article
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Extension
import androidx.compose.material.icons.filled.Inbox
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Work
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.personalos.mobile.data.auth.SessionManager
import com.personalos.mobile.data.models.PosNavTab
import com.personalos.mobile.ui.components.PosActionButton
import com.personalos.mobile.ui.components.PosActionStyle
import com.personalos.mobile.ui.components.PosMoreMenuRow
import com.personalos.mobile.ui.components.PosScreen
import com.personalos.mobile.ui.modules.ModulesViewModel
import com.personalos.mobile.ui.navigation.AppNavigator
import com.personalos.mobile.ui.navigation.WebRoute
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posCaps
import com.personalos.mobile.ui.theme.posDisplay

@Composable
fun MoreScreen(
    sessionManager: SessionManager,
    nav: AppNavigator,
    modulesVm: ModulesViewModel,
    onOpenModuleSettings: () -> Unit,
    onSelectTab: (String) -> Unit,
) {
    val user by sessionManager.user.collectAsState()
    val modules by modulesVm.state.collectAsState()
    PosScreen {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
            ) {
                Box(
                    Modifier
                        .size(64.dp)
                        .clip(CircleShape)
                        .background(PosTheme.Primary.copy(0.12f)),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(sessionManager.userInitials(), style = posDisplay(22f), fontWeight = FontWeight.SemiBold, color = PosTheme.PrimaryDark)
                }
                Text(user?.name ?: "Signed in", style = posDisplay(20f))
                Text(user?.email.orEmpty(), color = PosTheme.Muted)
            }
            modules.nav.drawer.filter { it !in listOf("inbox", "settings") && modulesVm.isEnabled(it) }.forEach { moduleId ->
                val entry = modules.catalog.find { it.id == moduleId }
                val tab = PosNavTab.from(moduleId)
                PosMoreMenuRow(
                    entry?.label ?: tab?.title ?: moduleId,
                    entry?.description ?: "",
                    iconFor(moduleId),
                    iconTint = PosTheme.Focus,
                ) { onSelectTab(moduleId) }
            }
            section("Capture") {
                PosMoreMenuRow("Inbox", "Quick capture", Icons.Default.Inbox, iconTint = PosTheme.PrimaryDark) {
                    nav.onOpenWeb(WebRoute.path("/inbox", "Inbox"))
                }
            }
            section("Tools") {
                if (modulesVm.isEnabled("work")) {
                    PosMoreMenuRow("CV Transfer", "Native editor", Icons.Default.Description) { nav.onOpenCv() }
                    PosMoreMenuRow("Job Scout", "Scan & apply", Icons.Default.Work) { nav.onOpenJobScout() }
                }
            }
            section("Account") {
                PosMoreMenuRow("Module settings", "Enable or disable modules", Icons.Default.Extension, iconTint = PosTheme.PrimaryDark) {
                    onOpenModuleSettings()
                }
                PosMoreMenuRow("Settings", "Profile & preferences", Icons.Default.Settings) {
                    nav.onOpenWeb(WebRoute.path("/settings", "Settings"))
                }
            }
            PosActionButton(text = "Sign out", style = PosActionStyle.Secondary, onClick = { sessionManager.signOut() })
        }
    }
}

private fun iconFor(moduleId: String): ImageVector = when (moduleId) {
    "startup" -> Icons.Default.Business
    "entertainment" -> Icons.Default.Article
    "goals" -> Icons.Default.Star
    else -> Icons.Default.Extension
}

@Composable
private fun section(title: String, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(title, style = posCaps(), color = PosTheme.Muted)
        content()
    }
}
