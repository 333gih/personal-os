import SwiftUI

struct WorkView: View {
    @EnvironmentObject private var session: SessionManager
    let nav: POSNavigationActions

    @State private var items: [POSEntity] = []
    @State private var isLoading = true

    private var projects: [POSEntity] {
        items.filter { $0.type.contains("project") || $0.type.contains("feature") }
    }

    private var skills: [POSEntity] {
        items.filter { $0.type.contains("technology") || $0.type.contains("skill") }
    }

    private var history: [POSEntity] {
        items.filter { $0.type.contains("lesson") || $0.type.contains("decision") || $0.type.contains("project") }
    }

    var body: some View {
        POSScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Career path")
                            .font(.posDisplay(28))
                        Text("A running record of roles, craft, and decisions.")
                            .font(.subheadline)
                            .foregroundStyle(POSTheme.muted)
                    }

                    timelineSection
                    recentUpdateCard
                    experiencesSection
                    cvRepositorySection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 88)
            }
        }
        .overlay(alignment: .bottom) {
            HStack(spacing: 10) {
                POSActionButton(title: "Open full work log", icon: "doc.text", style: .secondary) {
                    nav.onOpen(.path("/work", title: "Work"))
                }
                POSFloatingCaptureButton(action: nav.captureNote)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .task(id: session.accessToken) { await load() }
        .refreshable { await load() }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Timeline", actionTitle: "Full history") {
                nav.onOpen(.path("/work", title: "Work"))
            }
            if isLoading {
                POSLoadingView()
            } else if items.isEmpty {
                POSEmptyState(
                    systemImage: "briefcase",
                    title: "No work notes yet",
                    message: "Log a project or lesson and your path will start to take shape.",
                    actionTitle: "Add work note",
                    action: nav.captureNote
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(Array(items.prefix(8).enumerated()), id: \.element.id) { index, item in
                            Button { nav.onOpen(.entity(item.id, title: item.title)) } label: {
                                VStack(spacing: 8) {
                                    Text(item.title)
                                        .font(.caption2)
                                        .foregroundStyle(POSTheme.muted)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 78)
                                    Circle()
                                        .fill(index == 0 ? POSTheme.primaryDark : POSTheme.border)
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
    private var recentUpdateCard: some View {
        if let latest = items.first {
            POSCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Last updated", systemImage: "clock.arrow.circlepath")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(POSTheme.primaryDark)
                    Text(latest.title)
                        .font(.posDisplay(20))
                    Text("Updated \(POSFormatting.relativeDate(latest.updatedAt)). You now track \(items.count) work entries.")
                        .font(.subheadline)
                        .foregroundStyle(POSTheme.muted)
                    POSActionButton(title: "Review entry", icon: "arrow.up.right", style: .secondary) {
                        nav.onOpen(.entity(latest.id, title: latest.title))
                    }
                }
            }
        }
    }

    private var experiencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Active threads", actionTitle: "See all") {
                nav.onOpen(.path("/work", title: "Work"))
            }
            if projects.isEmpty && !isLoading {
                POSEmptyState(
                    systemImage: "folder",
                    title: "No projects in motion",
                    message: "Mark a role or project as active to keep it close at hand.",
                    actionTitle: "Capture project",
                    action: nav.captureNote
                )
            } else {
                ForEach(Array(projects.prefix(4).enumerated()), id: \.element.id) { index, item in
                    Button { nav.onOpen(.entity(item.id, title: item.title)) } label: {
                        POSCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title).font(.headline)
                                        Text(POSFormatting.humanType(item.type))
                                            .font(.caption)
                                            .foregroundStyle(POSTheme.muted)
                                    }
                                    Spacer()
                                    Text(index == 0 ? "Primary" : "Side")
                                        .font(.caption2.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(index == 0 ? POSTheme.successBg : POSTheme.border.opacity(0.45))
                                        .foregroundStyle(index == 0 ? POSTheme.success : POSTheme.muted)
                                        .clipShape(Capsule())
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
                }
            }
        }
    }

    private var cvRepositorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "CV shelf", eyebrow: "Pulled from your notes")
            Button { nav.onOpen(.path("/work", title: "Work")) } label: {
                POSCard {
                    Label("Work history", systemImage: "briefcase")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(POSTheme.primaryDark)
                    if history.isEmpty {
                        Text("No history entries yet.")
                            .font(.subheadline)
                            .foregroundStyle(POSTheme.muted)
                            .padding(.top, 8)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(history.prefix(4)) { item in
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
            }
            .buttonStyle(POSPressButtonStyle())

            HStack(spacing: 12) {
                Button {
                    if let skill = skills.first {
                        nav.onOpen(.entity(skill.id, title: skill.title))
                    } else {
                        nav.captureNote()
                    }
                } label: {
                    POSCard {
                        Label("Skills", systemImage: "target")
                            .font(.caption.weight(.semibold))
                        if skills.isEmpty {
                            Text("Tap to add").font(.caption).foregroundStyle(POSTheme.muted)
                        } else {
                            ForEach(skills.prefix(3)) { s in
                                Text(s.title).font(.subheadline)
                            }
                        }
                    }
                }
                .buttonStyle(POSPressButtonStyle())

                Button {
                    if let p = projects.first {
                        nav.onOpen(.entity(p.id, title: p.title))
                    } else {
                        nav.captureNote()
                    }
                } label: {
                    POSCard {
                        Label("Projects", systemImage: "doc")
                            .font(.caption.weight(.semibold))
                        if let p = projects.first {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(POSTheme.border.opacity(0.55))
                                .frame(height: 52)
                            Text(p.title).font(.subheadline.weight(.medium)).lineLimit(2)
                        } else {
                            Text("Tap to add").font(.caption).foregroundStyle(POSTheme.muted)
                        }
                    }
                }
                .buttonStyle(POSPressButtonStyle())
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await session.api.listEntities(domain: "work").items
        } catch {
            items = []
        }
    }
}
