import SwiftUI

struct WorkView: View {
    @EnvironmentObject private var session: SessionManager
    let onOpen: WebOpenHandler

    @State private var items: [POSEntity] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var projects: [POSEntity] {
        items.filter { $0.type.contains("project") || $0.type.contains("feature") }
    }

    private var skills: [POSEntity] {
        items.filter { $0.type.contains("technology") }
    }

    private var history: [POSEntity] {
        items.filter { $0.type.contains("lesson") || $0.type.contains("decision") || $0.type.contains("project") }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                timelineSection
                aiSyncCard
                experiencesSection
                cvRepositorySection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 88)
        }
        .task(id: session.accessToken) { await load() }
        .refreshable { await load() }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Timeline", actionTitle: "2018 — Present") {}
            if isLoading {
                POSLoadingView()
            } else if items.isEmpty {
                Text("Add work items to build your timeline.")
                    .font(.subheadline)
                    .foregroundStyle(POSTheme.muted)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        ForEach(Array(items.prefix(6).enumerated()), id: \.element.id) { index, item in
                            VStack(spacing: 8) {
                                Text(item.title)
                                    .font(.caption2)
                                    .foregroundStyle(POSTheme.muted)
                                    .lineLimit(1)
                                    .frame(width: 72)
                                Circle()
                                    .fill(index == 0 ? POSTheme.primaryDark : POSTheme.border)
                                    .frame(width: 10, height: 10)
                            }
                        }
                    }
                }
                Divider()
            }
        }
    }

    @ViewBuilder
    private var aiSyncCard: some View {
        if let latest = items.first {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("AI SYNC ACTIVE", systemImage: "sparkles")
                        .font(.posLabel(10))
                    Spacer()
                    Image(systemName: "icloud.fill")
                }
                .foregroundStyle(.white.opacity(0.9))
                Text("Your CV was updated recently")
                    .font(.posDisplay(20))
                    .foregroundStyle(.white)
                Text("Based on “\(latest.title)” and \(items.count) work items.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                Button("REVIEW CHANGES") { onOpen(.entity(latest.id, title: latest.title)) }
                    .font(.posLabel(10))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.white)
                    .foregroundStyle(POSTheme.primaryDark)
                    .clipShape(Capsule())
            }
            .padding(20)
            .background(POSTheme.primaryDark)
            .clipShape(RoundedRectangle(cornerRadius: POSTheme.cardRadius, style: .continuous))
        } else if !isLoading {
            POSEmptyState(systemImage: "briefcase.fill", title: "Start your career path", message: "Add projects and skills to build your CV.")
        }
    }

    private var experiencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Active Experiences", actionTitle: "View all") {
                onOpen(.path("/work", title: "Work"))
            }
            if projects.isEmpty && !isLoading {
                POSEmptyState(systemImage: "cube.fill", title: "No active projects", message: "Create a work project to track roles.")
            } else {
                ForEach(Array(projects.prefix(4).enumerated()), id: \.element.id) { index, item in
                    Button { onOpen(.entity(item.id, title: item.title)) } label: {
                        POSCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.title).font(.headline)
                                        Text(item.type.replacingOccurrences(of: "_", with: " ").capitalized)
                                            .font(.caption)
                                            .foregroundStyle(POSTheme.muted)
                                    }
                                    Spacer()
                                    Text(index == 0 ? "PRIMARY" : "SIDE")
                                        .font(.posLabel(9))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(index == 0 ? POSTheme.successBg : POSTheme.border.opacity(0.5))
                                        .foregroundStyle(index == 0 ? POSTheme.success : POSTheme.muted)
                                        .clipShape(Capsule())
                                }
                                HStack {
                                    ForEach(item.tagList.prefix(3), id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption2)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(POSTheme.border.opacity(0.4))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var cvRepositorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "CV Repository", eyebrow: "Auto-prioritized")
            POSCard {
                Label("WORK HISTORY", systemImage: "briefcase.fill")
                    .font(.posLabel(10))
                    .foregroundStyle(POSTheme.primaryDark)
                if history.isEmpty {
                    Text("No history entries yet.").font(.subheadline).foregroundStyle(POSTheme.muted).padding(.top, 8)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(history.prefix(4)) { item in
                            Button { onOpen(.entity(item.id, title: item.title)) } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title).font(.medium)
                                    Text(item.content).font(.caption).foregroundStyle(POSTheme.muted).lineLimit(2)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.leading, 12)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(POSTheme.primaryDark).frame(width: 2)
                    }
                    .padding(.top, 8)
                }
            }
            HStack(spacing: 12) {
                POSCard {
                    Label("SKILLS", systemImage: "target")
                        .font(.posLabel(9))
                    if skills.isEmpty {
                        Text("Add technology entities.").font(.caption).foregroundStyle(POSTheme.muted)
                    } else {
                        ForEach(skills.prefix(3)) { s in
                            Text(s.title).font(.subheadline)
                        }
                    }
                }
                POSCard {
                    Label("PROJECTS", systemImage: "doc.fill")
                        .font(.posLabel(9))
                    if let p = projects.first {
                        RoundedRectangle(cornerRadius: 12).fill(POSTheme.border).frame(height: 56)
                        Text(p.title).font(.subheadline.weight(.medium))
                    } else {
                        Text("No projects yet.").font(.caption).foregroundStyle(POSTheme.muted)
                    }
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await session.api.listEntities(domain: "work")
            items = response.items
        } catch {
            errorMessage = error.localizedDescription
            items = []
        }
    }
}
