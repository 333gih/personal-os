import SwiftUI

struct WorkView: View {
    @EnvironmentObject private var session: SessionManager
    let nav: POSNavigationActions

    @State private var items: [POSEntity] = []
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var architectureProject: POSEntity?

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
                VStack(alignment: .leading, spacing: 22) {
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
                    cvExperienceSection
                    cvShelfSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 88)
            }
        }
        .sheet(item: $architectureProject) { project in
            POSProjectArchitectureSheet(project: project)
        }
        .overlay(alignment: .bottom) {
            HStack(spacing: 10) {
                POSActionButton(title: "Search career", icon: "magnifyingglass", style: .secondary) {
                    nav.onOpen(.path("/search?domain=work", title: "Search"))
                }
                POSFloatingCaptureButton(action: nav.captureNote)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
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
                    .font(.posDisplay(24))
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
                    HStack(alignment: .bottom, spacing: 24) {
                        ForEach(roles) { role in
                            Button { nav.onOpen(.entity(role.id, title: role.title)) } label: {
                                VStack(spacing: 8) {
                                    Text(role.metadata?.company ?? role.title)
                                        .font(.caption2.weight(.medium))
                                        .multilineTextAlignment(.center)
                                        .frame(width: 88)
                                    Text(role.metadata?.periodLabel() ?? "")
                                        .font(.caption2)
                                        .foregroundStyle(POSTheme.muted)
                                    Circle()
                                        .fill(role.isActiveWork ? POSTheme.primaryDark : POSTheme.border)
                                        .frame(width: 10, height: 10)
                                }
                            }
                            .buttonStyle(POSPressButtonStyle())
                        }
                    }
                }
                Divider().overlay(POSTheme.border)
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
                    Text(project.title).font(.posDisplay(20))
                    Text(project.content)
                        .font(.subheadline)
                        .foregroundStyle(POSTheme.muted)
                        .lineLimit(3)
                    POSActionButton(title: "Open project", icon: "arrow.up.right", style: .secondary) {
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
                    VStack(spacing: 8) {
                        Button { nav.onOpen(.entity(item.id, title: item.title)) } label: {
                            POSCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.title).font(.headline)
                                            Text(projectSubtitle(item))
                                                .font(.caption)
                                                .foregroundStyle(POSTheme.muted)
                                        }
                                        Spacer()
                                        Text(item.isActiveWork ? "Active" : "Done")
                                            .font(.caption2.weight(.semibold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(index == 0 && item.isActiveWork ? POSTheme.successBg : POSTheme.border.opacity(0.45))
                                            .foregroundStyle(index == 0 && item.isActiveWork ? POSTheme.success : POSTheme.muted)
                                            .clipShape(Capsule())
                                    }
                                    if !item.architectureLayers.isEmpty || item.designImageURL() != nil {
                                        POSArchitectureDiagram(
                                            layers: Array(item.architectureLayers.prefix(2)),
                                            imageURL: nil
                                        )
                                    }
                                    if !item.tagList.isEmpty {
                                        HStack {
                                            ForEach(item.tagList.prefix(3), id: \.self) { tag in
                                                Text(tag)
                                                    .font(.caption2)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(POSTheme.border.opacity(0.35))
                                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .buttonStyle(POSPressButtonStyle())
                        if !item.architectureLayers.isEmpty || item.designImageURL() != nil {
                            POSActionButton(title: "View architecture", icon: "square.grid.2x2", style: .secondary) {
                                architectureProject = item
                            }
                        }
                    }
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
                    Button { nav.onOpen(.entity(doc.id, title: doc.title)) } label: {
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
    private var cvExperienceSection: some View {
        if !cvInResume.isEmpty || !cvRecommended.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                POSSectionHeader(title: "CV experience", eyebrow: "On resume vs recommended")
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

            HStack(spacing: 12) {
                POSCard {
                    Label("Stack", systemImage: "target")
                        .font(.caption.weight(.semibold))
                    ForEach(skills.prefix(4)) { s in
                        HStack {
                            Text(s.title).font(.subheadline)
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
                            Text(r.metadata?.role ?? r.title).font(.subheadline.weight(.medium))
                            Text(r.metadata?.periodLabel() ?? "")
                                .font(.caption2)
                                .foregroundStyle(POSTheme.muted)
                        }
                    }
                }
            }
        }
    }

    private func projectSubtitle(_ item: POSEntity) -> String {
        let parts = [item.metadata?.company, item.metadata?.role, item.metadata?.periodLabel()]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.joined(separator: " · ")
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
