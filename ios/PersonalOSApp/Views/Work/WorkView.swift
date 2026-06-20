import SwiftUI

struct WorkView: View {
    @EnvironmentObject private var session: SessionManager
    let nav: POSNavigationActions

    @State private var items: [POSEntity] = []
    @State private var isLoading = true
    @State private var loadError: String?

    private var profile: POSEntity? {
        items.first { $0.metadata?.kind == "profile" }
    }

    private var roles: [POSEntity] {
        items.filter { $0.type.contains("work_role") }
    }

    private var projects: [POSEntity] {
        items.filter { $0.type.contains("work_project") && $0.metadata?.kind != "profile" }
    }

    private var activeProjects: [POSEntity] {
        projects.filter(\.isActiveWork)
    }

    private var skills: [POSEntity] {
        items.filter { $0.type.contains("technology") }
    }

    private var designDocs: [POSEntity] {
        items.filter { $0.type.contains("design_doc") }
    }

    private var insights: [POSEntity] {
        items.filter { $0.type.contains("lesson") || $0.type.contains("decision") }
    }

    private var cvInResume: [POSEntity] {
        items.filter { $0.type.contains("cv_entry") && $0.metadata?.cvStatus == "in_cv" }
    }

    private var cvRecommended: [POSEntity] {
        items.filter { $0.type.contains("cv_entry") && $0.metadata?.cvStatus == "recommended_add" }
    }

    var body: some View {
        POSScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    profileHero
                    if let loadError, !isLoading {
                        POSEmptyState(
                            systemImage: "exclamationmark.triangle",
                            title: "Could not load career data",
                            message: loadError,
                            actionTitle: "Retry",
                            action: { Task { await load() } }
                        )
                    }
                    timelineSection
                    focusCard
                    projectsSection
                    designSection
                    careerToolsSection
                    cvExperienceSection
                    cvShelfSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                Spacer()
                POSFloatingCaptureButton(action: nav.captureNote)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 4)
            .background(
                LinearGradient(
                    colors: [POSTheme.background.opacity(0), POSTheme.background.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 56)
                .allowsHitTesting(false)
            )
        }
        .task(id: session.accessToken) { await load() }
        .refreshable { await load() }
    }

    @ViewBuilder
    private var profileHero: some View {
        POSCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Career path")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                Text(profile?.title.replacingOccurrences(of: " — Career Profile", with: "") ?? "Your work history")
                    .font(.posDisplay(22))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(profile?.content ?? "Track roles, projects, and decisions.")
                    .font(.subheadline)
                    .foregroundStyle(POSTheme.muted)
                    .lineLimit(4)
                HStack(spacing: 8) {
                    Label(profile?.metadata?.workHours?.replacingOccurrences(of: "-", with: " — ") ?? "08:00 — 17:00 ICT", systemImage: "clock")
                    Text("\(items.count) entries")
                }
                .font(.caption)
                .foregroundStyle(POSTheme.muted)
            }
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Employment timeline", actionTitle: "Full history") {
                nav.onOpen(.path("/work", title: "Work"))
            }
            if isLoading {
                POSLoadingView()
            } else if roles.isEmpty {
                POSEmptyState(
                    systemImage: "briefcase",
                    title: "No roles yet",
                    message: "Run career seed or add work roles.",
                    actionTitle: "Add note",
                    action: nav.captureNote
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 20) {
                        ForEach(roles) { role in
                            Button {
                                POSHaptics.light()
                                nav.onOpen(.entity(role.id, title: role.title))
                            } label: {
                                VStack(spacing: 8) {
                                    Text(role.metadata?.company ?? role.title)
                                        .font(.caption2.weight(.medium))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .frame(width: 80)
                                    Text(role.metadata?.periodLabel() ?? "")
                                        .font(.caption2)
                                        .foregroundStyle(POSTheme.muted)
                                        .lineLimit(1)
                                    Circle()
                                        .fill(role.isActiveWork ? POSTheme.primaryDark : POSTheme.border)
                                        .frame(width: 10, height: 10)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(POSPressButtonStyle())
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private var focusCard: some View {
        if let project = activeProjects.first {
            POSCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("In focus now", systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(POSTheme.primaryDark)
                    Text(project.title)
                        .font(.posDisplay(18))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(project.content)
                        .font(.subheadline)
                        .foregroundStyle(POSTheme.muted)
                        .lineLimit(3)
                    POSActionButton(title: "Open project", icon: "arrow.up.right", style: .secondary) {
                        POSHaptics.light()
                        nav.onOpen(.entity(project.id, title: project.title))
                    }
                }
            }
        }
    }

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Projects", actionTitle: "\(projects.count) total") {
                nav.onOpen(.path("/work", title: "Work"))
            }
            if projects.isEmpty && !isLoading {
                POSEmptyState(
                    systemImage: "folder",
                    title: "No projects",
                    message: "Capture a project to track impact.",
                    actionTitle: "Capture",
                    action: nav.captureNote
                )
            } else {
                ForEach(Array(projects.prefix(5).enumerated()), id: \.element.id) { index, item in
                    WorkProjectCard(
                        item: item,
                        isPrimary: index == 0,
                        onOpen: {
                            POSHaptics.light()
                            nav.onOpen(.entity(item.id, title: item.title))
                        },
                        onArchitecture: {
                            POSHaptics.light()
                            nav.onOpen(.entity(item.id, title: item.title, section: .architecture))
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    @ViewBuilder
    private var designSection: some View {
        if !designDocs.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                POSSectionHeader(title: "System design", actionTitle: "Architecture")
                ForEach(designDocs.prefix(3)) { doc in
                    Button {
                        POSHaptics.light()
                        nav.onOpen(.entity(doc.id, title: doc.title))
                    } label: {
                        POSCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(doc.title).font(.subheadline.weight(.semibold))
                                Text(doc.content)
                                    .font(.caption)
                                    .foregroundStyle(POSTheme.muted)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .buttonStyle(POSPressButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private var careerToolsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            POSSectionHeader(title: "Career tools", eyebrow: "CV & opportunities")
            POSActionButton(title: "Open CV Transfer", icon: "doc.richtext", style: .primary) {
                nav.openCV()
            }
            POSActionButton(title: "Job Scout — scan matches", icon: "briefcase", style: .secondary) {
                nav.openJobScout()
            }
        }
    }

    @ViewBuilder
    private var cvExperienceSection: some View {
        if !cvInResume.isEmpty || !cvRecommended.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                POSSectionHeader(title: "CV experience", eyebrow: "On resume vs recommended")
                if !cvInResume.isEmpty || !cvRecommended.isEmpty {
                    POSActionButton(title: "Open CV Transfer", icon: "doc.richtext", style: .secondary) {
                        nav.openCV()
                    }
                }
                if !cvInResume.isEmpty {
                    POSCard {
                        Label("Already in CV", systemImage: "checkmark.seal")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(POSTheme.success)
                        ForEach(cvInResume.prefix(5)) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.title.replacingOccurrences(of: "CV: ", with: ""))
                                    .font(.subheadline.weight(.medium))
                                Text(entry.content)
                                    .font(.caption)
                                    .foregroundStyle(POSTheme.muted)
                                    .lineLimit(2)
                            }
                            .padding(.top, 6)
                        }
                    }
                }
                if !cvRecommended.isEmpty {
                    POSCard {
                        Label("Should add to CV", systemImage: "plus.circle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(POSTheme.primaryDark)
                        ForEach(cvRecommended.prefix(4)) { entry in
                            Button { nav.onOpen(.entity(entry.id, title: entry.title)) } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.title.replacingOccurrences(of: "Add to CV: ", with: ""))
                                        .font(.subheadline.weight(.medium))
                                    Text(entry.content)
                                        .font(.caption)
                                        .foregroundStyle(POSTheme.muted)
                                        .lineLimit(2)
                                }
                                .padding(.top, 6)
                            }
                            .buttonStyle(POSPressButtonStyle())
                        }
                    }
                }
            }
        }
    }

    private var cvShelfSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "CV shelf", eyebrow: "Decisions & stack")
            POSCard {
                Label("Highlights", systemImage: "briefcase")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                if insights.isEmpty {
                    Text("No decisions or lessons yet.")
                        .font(.subheadline)
                        .foregroundStyle(POSTheme.muted)
                        .padding(.top, 8)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(insights.prefix(4)) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title).fontWeight(.medium)
                                Text(item.content)
                                    .font(.caption)
                                    .foregroundStyle(POSTheme.muted)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(.leading, 12)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(POSTheme.primaryDark.opacity(0.8)).frame(width: 2)
                    }
                    .padding(.top, 8)
                }
            }

            VStack(spacing: 12) {
                POSCard {
                    Label("Stack", systemImage: "target")
                        .font(.caption.weight(.semibold))
                    ForEach(skills.prefix(4)) { s in
                        HStack {
                            Text(s.title).font(.subheadline).lineLimit(1)
                            Spacer()
                            Text(s.metadata?.level?.capitalized ?? "—")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(POSTheme.primaryDark)
                        }
                    }
                }
                POSCard {
                    Label("Roles", systemImage: "doc")
                        .font(.caption.weight(.semibold))
                    ForEach(roles.prefix(3)) { r in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.metadata?.role ?? r.title)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                            Text(r.metadata?.periodLabel() ?? "")
                                .font(.caption2)
                                .foregroundStyle(POSTheme.muted)
                        }
                    }
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        guard session.isAuthenticated else {
            loadError = "Not signed in."
            items = []
            return
        }
        do {
            let response = try await session.api.listEntities(domain: "work", limit: 120)
            items = response.items
            if response.items.isEmpty {
                loadError = "No work entries yet. Open the app once while signed in as mphuc8671@gmail.com so the server can sync career data."
            }
        } catch {
            items = []
            loadError = error.localizedDescription
        }
    }
}
