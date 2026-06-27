package com.personalos.mobile.ui.work

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.personalos.mobile.data.models.PosEntity
import com.personalos.mobile.data.models.PosEntitySection
import com.personalos.mobile.ui.components.PosActionButton
import com.personalos.mobile.ui.components.PosActionStyle
import com.personalos.mobile.ui.components.PosCard
import com.personalos.mobile.ui.components.PosEmptyState
import com.personalos.mobile.ui.components.PosFloatingCaptureButton
import com.personalos.mobile.ui.components.PosListRow
import com.personalos.mobile.ui.components.PosLoadingView
import com.personalos.mobile.ui.components.PosScreen
import com.personalos.mobile.ui.components.PosSectionHeader
import com.personalos.mobile.ui.navigation.AppNavigator
import com.personalos.mobile.ui.navigation.EntityRoute
import com.personalos.mobile.ui.navigation.WebRoute
import com.personalos.mobile.ui.theme.PosTheme
import com.personalos.mobile.ui.theme.posDisplay
import com.personalos.mobile.ui.theme.posLabel
import com.personalos.mobile.util.periodLabel

@Composable
fun WorkScreen(viewModel: WorkViewModel, nav: AppNavigator, reloadKey: Int = 0) {
    val state by viewModel.state.collectAsState()
    androidx.compose.runtime.LaunchedEffect(reloadKey) { viewModel.load() }

    val items = state.entities
    val profile = items.firstOrNull { it.metadata?.kind == "profile" }
    val roles = items.filter { it.type.contains("work_role") }
    val projects = items.filter { it.type.contains("work_project") && it.metadata?.kind != "profile" }
    val activeProjects = projects.filter { it.isActiveWork }
    val designDocs = items.filter { it.type.contains("design_doc") }
    val insights = items.filter { it.type.contains("lesson") || it.type.contains("decision") }
    val cvInResume = items.filter { it.type.contains("cv_entry") && it.metadata?.cvStatus == "in_cv" }
    val cvRecommended = items.filter { it.type.contains("cv_entry") && it.metadata?.cvStatus == "recommended_add" }
    val interviewTopics = items.filter { it.type.contains("interview") }

    Box(Modifier.fillMaxSize()) {
        PosScreen {
            Column(
                Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp, vertical = 16.dp)
                    .padding(bottom = 72.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp),
            ) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                    IconButton(onClick = nav.onOpenWorkHub) {
                        Icon(Icons.Default.Menu, contentDescription = "Work menu", tint = PosTheme.PrimaryDark)
                    }
                }
                ProfileHero(profile, items.size)
                when {
                    state.loading -> PosLoadingView()
                    state.error != null -> PosEmptyState(
                        "Could not load career data",
                        state.error.orEmpty(),
                        "Retry",
                        onAction = { viewModel.load() },
                    )
                    else -> {
                        TimelineSection(roles, nav)
                        activeProjects.firstOrNull()?.let { FocusCard(it, nav) }
                        ProjectsSection(projects, nav)
                        if (designDocs.isNotEmpty()) DesignSection(designDocs, nav)
                        InterviewSection(interviewTopics, state.loading, nav)
                        CareerToolsSection(nav)
                        if (cvInResume.isNotEmpty() || cvRecommended.isNotEmpty()) {
                            CvExperienceSection(cvInResume, cvRecommended, nav)
                        }
                        CvShelfSection(insights, nav)
                    }
                }
            }
        }
        PosFloatingCaptureButton(
            onClick = nav.onOpenWorkHub,
            modifier = Modifier.align(Alignment.BottomStart).padding(start = 16.dp, bottom = 12.dp),
        )
    }
}

@Composable
private fun ProfileHero(profile: PosEntity?, entryCount: Int) {
    PosCard {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("Career path", style = posLabel(), fontWeight = FontWeight.SemiBold, color = PosTheme.PrimaryDark)
            Text(
                profile?.title?.replace(" — Career Profile", "").orEmpty().ifBlank { "Your work history" },
                style = posDisplay(22f),
                maxLines = 2,
            )
            Text(
                profile?.content?.ifBlank { "Track roles, projects, and decisions." } ?: "Track roles, projects, and decisions.",
                color = PosTheme.Muted,
                maxLines = 4,
            )
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.AccessTime, contentDescription = null, tint = PosTheme.Muted, modifier = Modifier.size(14.dp))
                Text(
                    profile?.metadata?.workHours?.replace("-", " — ")?.ifBlank { "08:00 — 17:00 ICT" } ?: "08:00 — 17:00 ICT",
                    style = posLabel(),
                    color = PosTheme.Muted,
                )
                Text("$entryCount entries", style = posLabel(), color = PosTheme.Muted)
            }
        }
    }
}

@Composable
private fun TimelineSection(roles: List<PosEntity>, nav: AppNavigator) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        PosSectionHeader(title = "Employment timeline", action = "Full history", onAction = { nav.onOpenWeb(WebRoute.path("/work", "Work")) })
        if (roles.isEmpty()) {
            PosEmptyState("No roles yet", "Run career seed or add work roles.", "Add note", onAction = nav.captureNote)
        } else {
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                roles.forEach { role ->
                    Column(
                        Modifier.clickable { nav.onOpenEntity(EntityRoute(role.id, role.title)) },
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Text(role.metadata?.company ?: role.title, style = posLabel(), maxLines = 2, modifier = Modifier.size(width = 80.dp, height = 36.dp))
                        Text(role.metadata?.periodLabel().orEmpty(), style = posDisplay(10f), color = PosTheme.Muted, maxLines = 1)
                        Box(
                            Modifier
                                .size(10.dp)
                                .clip(CircleShape)
                                .background(if (role.isActiveWork) PosTheme.PrimaryDark else PosTheme.Border),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun FocusCard(project: PosEntity, nav: AppNavigator) {
    PosCard {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("In focus now", style = posLabel(), fontWeight = FontWeight.SemiBold, color = PosTheme.PrimaryDark)
            Text(project.title, style = posDisplay(18f), maxLines = 2)
            Text(project.content, color = PosTheme.Muted, maxLines = 3)
            PosActionButton("Open project", style = PosActionStyle.Secondary) {
                nav.onOpenEntity(EntityRoute(project.id, project.title))
            }
        }
    }
}

@Composable
private fun ProjectsSection(projects: List<PosEntity>, nav: AppNavigator) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        PosSectionHeader(title = "Projects", action = "${projects.size} total") {
            nav.onOpenWeb(WebRoute.path("/work", "Work"))
        }
        if (projects.isEmpty()) {
            PosEmptyState("No projects", "Capture a project to track impact.", "Capture", onAction = nav.captureNote)
        } else {
            projects.take(5).forEachIndexed { index, item ->
                WorkProjectCard(
                    item = item,
                    isPrimary = index == 0,
                    onOpen = { nav.onOpenEntity(EntityRoute(item.id, item.title)) },
                    onArchitecture = { nav.onOpenEntity(EntityRoute(item.id, item.title, PosEntitySection.ARCHITECTURE)) },
                )
            }
        }
    }
}

@Composable
private fun DesignSection(docs: List<PosEntity>, nav: AppNavigator) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        PosSectionHeader(title = "System design", action = "Architecture")
        docs.take(3).forEach { doc ->
            PosCard(modifier = Modifier.clickable { nav.onOpenEntity(EntityRoute(doc.id, doc.title)) }) {
                Text(doc.title, fontWeight = FontWeight.SemiBold)
                Text(doc.content, style = posLabel(), color = PosTheme.Muted, maxLines = 2)
            }
        }
    }
}

@Composable
private fun InterviewSection(topics: List<PosEntity>, loading: Boolean, nav: AppNavigator) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        PosSectionHeader(title = "Interview prep", eyebrow = "Notebook for interview")
        if (topics.isEmpty() && !loading) {
            PosEmptyState("No interview topics", "Seed migration 020 or open Work menu → Interview prep.", "Open prep") {
                nav.onOpenInterviewPrep()
            }
        } else {
            topics.take(5).forEach { topic ->
                PosListRow(topic.title, topic.content) { nav.onOpenEntity(EntityRoute(topic.id, topic.title)) }
            }
            PosActionButton("AI interview drill", style = PosActionStyle.Secondary, onClick = nav.onOpenInterviewPrep)
        }
    }
}

@Composable
private fun CareerToolsSection(nav: AppNavigator) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        PosSectionHeader(title = "Career tools", eyebrow = "CV & opportunities")
        PosActionButton("Work menu", style = PosActionStyle.Primary, onClick = nav.onOpenWorkHub)
        PosActionButton("Add entry (AI normalize)", style = PosActionStyle.Secondary, onClick = nav.onOpenWorkAdd)
        PosActionButton("Job Scout", style = PosActionStyle.Secondary, onClick = nav.onOpenJobScout)
    }
}

@Composable
private fun CvExperienceSection(inResume: List<PosEntity>, recommended: List<PosEntity>, nav: AppNavigator) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        PosSectionHeader(title = "CV experience", eyebrow = "On resume vs recommended")
        PosActionButton("Open CV Transfer", style = PosActionStyle.Secondary, onClick = nav.onOpenCv)
        if (inResume.isNotEmpty()) {
            PosCard {
                Text("Already in CV", style = posLabel(), fontWeight = FontWeight.SemiBold, color = PosTheme.Success)
                inResume.take(5).forEach { entry ->
                    Column(Modifier.padding(top = 6.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(entry.title.replace("CV: ", ""), fontWeight = FontWeight.Medium)
                        Text(entry.content, style = posLabel(), color = PosTheme.Muted, maxLines = 2)
                    }
                }
            }
        }
        if (recommended.isNotEmpty()) {
            PosCard {
                Text("Should add to CV", style = posLabel(), fontWeight = FontWeight.SemiBold, color = PosTheme.PrimaryDark)
                recommended.take(4).forEach { entry ->
                    Column(
                        Modifier
                            .padding(top = 6.dp)
                            .clickable { nav.onOpenEntity(EntityRoute(entry.id, entry.title)) },
                        verticalArrangement = Arrangement.spacedBy(4.dp),
                    ) {
                        Text(entry.title.replace("Add to CV: ", ""), fontWeight = FontWeight.Medium)
                        Text(entry.content, style = posLabel(), color = PosTheme.Muted, maxLines = 2)
                    }
                }
            }
        }
    }
}

@Composable
private fun CvShelfSection(insights: List<PosEntity>, nav: AppNavigator) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        PosSectionHeader(title = "CV shelf", eyebrow = "Decisions & stack")
        PosCard {
            Text("Highlights", style = posLabel(), fontWeight = FontWeight.SemiBold, color = PosTheme.PrimaryDark)
            if (insights.isEmpty()) {
                Text("No decisions or lessons yet.", color = PosTheme.Muted, modifier = Modifier.padding(top = 8.dp))
            } else {
                Column(Modifier.padding(top = 8.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    insights.take(5).forEach { item ->
                        Column(
                            Modifier.clickable { nav.onOpenEntity(EntityRoute(item.id, item.title)) },
                            verticalArrangement = Arrangement.spacedBy(4.dp),
                        ) {
                            Text(item.title, fontWeight = FontWeight.Medium)
                            Text(item.content, style = posLabel(), color = PosTheme.Muted, maxLines = 2)
                        }
                    }
                }
            }
        }
    }
}
