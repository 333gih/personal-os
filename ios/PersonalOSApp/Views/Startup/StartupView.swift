import SwiftUI

struct StartupView: View {
    @EnvironmentObject private var session: SessionManager
    let nav: POSNavigationActions

    @State private var items: [POSEntity] = []
    @State private var reminders: [POSReminder] = []
    @State private var isLoading = true

    private var fashItems: [POSEntity] {
        items.filter { $0.tagList.contains(where: { $0.lowercased() == "fash" }) || $0.title.lowercased().contains("fash") }
    }

    private var ideas: [POSEntity] { items.filter { $0.type.contains("idea") } }
    private var features: [POSEntity] { items.filter { $0.type.contains("feature") } }
    private var recent: [POSEntity] { items.sorted { $0.updatedAt > $1.updatedAt } }

    var body: some View {
        POSScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Spacer()
                        Button { nav.openStartupHub() } label: {
                            Label("Menu", systemImage: "line.3.horizontal.circle.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(POSTheme.primaryDark)
                        }
                        .buttonStyle(POSPressButtonStyle())
                    }
                    HStack(spacing: 12) {
                        POSMetricCard(
                            label: "Portfolio",
                            value: items.isEmpty ? "—" : "\(items.count)",
                            hint: "Startup entities",
                            systemImage: "chart.line.uptrend.xyaxis",
                            accent: POSTheme.focus,
                            action: { nav.onOpen(.path("/startup", title: "Startup")) }
                        )
                        POSMetricCard(
                            label: "Fash",
                            value: fashItems.isEmpty ? "—" : "\(fashItems.count)",
                            hint: "From fash monorepo",
                            systemImage: "bag.fill",
                            action: { nav.openStartupHub() }
                        )
                    }
                    fashSection
                    portfolioSection
                    featuresSection
                    networkSection
                    scheduleSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                Button { nav.openStartupHub() } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 54))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, POSTheme.ink)
                        .shadow(color: POSTheme.ink.opacity(0.25), radius: 10, y: 4)
                }
                .buttonStyle(POSPressButtonStyle(scale: 0.94))
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.bottom, 4)
        }
        .task(id: session.accessToken) { await load() }
    }

    @ViewBuilder
    private var fashSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Fash ecosystem", eyebrow: "D:/Project/fash")
            if isLoading {
                POSLoadingView()
            } else if fashItems.isEmpty {
                POSEmptyState(
                    systemImage: "bag",
                    title: "Fash not seeded yet",
                    message: "Run migration 019 on server or add entries via Startup menu.",
                    actionTitle: "Add entry",
                    action: { nav.openStartupAdd() }
                )
            } else {
                ForEach(fashItems.prefix(4)) { item in
                    Button { nav.onOpen(.entity(item.id, title: item.title)) } label: {
                        POSCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.title).font(.subheadline.weight(.semibold))
                                Text(POSFormatting.humanType(item.type))
                                    .font(.caption2)
                                    .foregroundStyle(POSTheme.muted)
                                Text(item.content).font(.caption).foregroundStyle(POSTheme.muted).lineLimit(3)
                            }
                        }
                    }
                    .buttonStyle(POSPressButtonStyle())
                }
            }
        }
    }

    private var portfolioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Ideas", actionTitle: "View all") {
                nav.onOpen(.path("/startup", title: "Startup"))
            }
            if !isLoading && items.isEmpty {
                POSEmptyState(
                    systemImage: "lightbulb",
                    title: "No startup notes",
                    message: "Add Fash features, KPIs, or competitors.",
                    actionTitle: "Startup menu",
                    action: { nav.openStartupHub() }
                )
            } else {
                ForEach((ideas.isEmpty ? items : ideas).prefix(3)) { item in
                    Button { nav.onOpen(.entity(item.id, title: item.title)) } label: {
                        POSCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.title).font(.headline)
                                Text(POSFormatting.humanType(item.type)).font(.caption).foregroundStyle(POSTheme.muted)
                                Text(item.content).font(.caption).foregroundStyle(POSTheme.muted).lineLimit(2)
                            }
                        }
                    }
                    .buttonStyle(POSPressButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private var featuresSection: some View {
        if !features.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                POSSectionHeader(title: "Features & KPIs")
                ForEach(features.prefix(4)) { item in
                    Button { nav.onOpen(.entity(item.id, title: item.title)) } label: {
                        POSListRow(
                            title: item.title,
                            subtitle: POSFormatting.humanType(item.type),
                            systemImage: "sparkles",
                            iconTint: POSTheme.primaryDark
                        )
                    }
                    .buttonStyle(POSPressButtonStyle())
                }
            }
        }
    }

    private var networkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Recent movement")
            if recent.isEmpty && !isLoading {
                Text("Edits to startup notes will appear here.").font(.subheadline).foregroundStyle(POSTheme.muted)
            } else {
                ForEach(recent.prefix(3)) { item in
                    Button { nav.onOpen(.entity(item.id, title: item.title)) } label: {
                        POSListRow(
                            title: item.title,
                            subtitle: POSFormatting.relativeDate(item.updatedAt),
                            systemImage: "arrow.triangle.2.circlepath",
                            iconTint: POSTheme.primary
                        )
                    }
                    .buttonStyle(POSPressButtonStyle())
                }
            }
        }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "On the calendar")
            if reminders.isEmpty {
                POSEmptyState(
                    systemImage: "calendar",
                    title: "No events pinned",
                    message: "Attach reminders to startup entries.",
                    actionTitle: "Open board",
                    action: { nav.onOpen(.path("/startup", title: "Startup")) }
                )
            } else {
                ForEach(reminders.prefix(4)) { r in
                    Button {
                        if let eid = r.entityId { nav.onOpen(.entity(eid, title: r.title)) }
                    } label: {
                        POSListRow(title: r.title, subtitle: POSFormatting.friendlyDue(r.dueAt), systemImage: "calendar")
                    }
                    .buttonStyle(POSPressButtonStyle())
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let entities = session.api.listEntities(domain: "startup")
            async let dash = session.api.dashboard()
            let (e, d) = try await (entities, dash)
            items = e.items
            reminders = d.upcomingReminders
        } catch {
            items = []
            reminders = []
        }
    }
}
