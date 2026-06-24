package com.personalos.mobile.ui.more

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.personalos.mobile.data.auth.SessionManager
import com.personalos.mobile.ui.components.PosCard
import com.personalos.mobile.ui.components.PosListRow
import com.personalos.mobile.ui.components.PosPrimaryButton
import com.personalos.mobile.ui.components.PosScreen
import com.personalos.mobile.ui.navigation.AppNavigator
import com.personalos.mobile.ui.navigation.WebRoute
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay

@Composable
fun MoreScreen(sessionManager: SessionManager, nav: AppNavigator) {
    val user by sessionManager.user.collectAsState()
    PosScreen {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            PosCard {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(user?.name ?: "Signed in", style = posDisplay(20f))
                    Text(user?.email.orEmpty(), color = PosTheme.Muted)
                }
            }
            section("Capture") {
                PosListRow("Inbox", "Quick capture") { nav.onOpenWeb(WebRoute.path("/inbox", "Inbox")) }
            }
            section("Explore") {
                PosListRow("CV Hub", "Native editor") { nav.onOpenCv() }
                PosListRow("Job Scout", "Scan & apply") { nav.onOpenJobScout() }
                PosListRow("Startup", "Portfolio board") { nav.onOpenStartup() }
                PosListRow("Reading log", "Story Tracker sync") { nav.onOpenWeb(WebRoute.path("/entertainment", "Reading Log")) }
            }
            section("Account") {
                PosListRow("Settings", "Profile & preferences") { nav.onOpenWeb(WebRoute.path("/settings", "Settings")) }
            }
            PosPrimaryButton("Sign out") { sessionManager.signOut() }
        }
    }
}

@Composable
private fun section(title: String, content: @Composable () -> Unit) {
    Text(title.uppercase(), style = posDisplay(12f), color = PosTheme.Muted)
    PosCard { Column { content() } }
}
