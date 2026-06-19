import SwiftUI

struct StartupView: View {
    @EnvironmentObject private var session: SessionManager
    let nav: POSNavigationActions

    @State private var items: [POSEntity] = []
    @State private var reminders: [POSReminder] = []
    @State private var isLoading = true

    private var ideas: [POSEntity] { items.filter { $0.type.contains("idea") } }
    private var recent: [POSEntity] {
        items.sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        POSScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        POSMetricCard(
                            label: "Portfolio",
                            value: items.isEmpty ? "—" : "\(items.count)",
                            hint: "Tracked ideas",
                            systemImage: "chart.line.uptrend.xyaxis",
                            accent: POSTheme.focus,
                            action: { nav.onOpen(.path("/startup", title: "Startup")) }
                        )
                        POSMetricCard(
                            label: "Active",
                            value: "\(max(ideas.count, items.count))",
                            hint: "In motion",
                            systemImage: "building.2",
                            action: { nav.onOpen(.path("/startup", title: "Startup")) }
                        )
                    }
                    portfolioSection
                    networkSection
                    scheduleSection
                    POSActionButton(title: "Open full startup board", icon: "arrow.up.right", style: .secondary) {
                        nav.onOpen(.path("/startup", title: "Startup"))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .task(id: session.accessToken) { await load() }
    }

    private var portfolioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Highlights", actionTitle: "View all") {
                nav.onOpen(.path("/startup", title: "Startup"))
            }
            if isLoading {
                POSLoadingView()
            } else if items.isEmpty {
                POSEmptyState(
                    systemImage: "lightbulb",
                    title: "No startup notes",
                    message: "Capture an idea or KPI to start your portfolio shelf.",
                    actionTitle: "Add idea",
                    action: nav.captureNote
                )
            } else {
                ForEach((ideas.isEmpty ? items : ideas).prefix(3)) { item in
                    Button { nav.onOpen(.entity(item.id, title: item.title)) } label: {
                        POSCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.title).font(.headline)
                                Text(POSFormatting.humanType(item.type))
                                    .font(.caption)
                                    .foregroundStyle(POSTheme.muted)
                                Text(item.content)
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

    private var networkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Recent movement")
            if recent.isEmpty && !isLoading {
                Text("Edits to startup notes will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(POSTheme.muted)
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
                    message: "Attach reminders to startup entries to see them here.",
                    actionTitle: "Open startup",
                    action: { nav.onOpen(.path("/startup", title: "Startup")) }
                )
            } else {
                ForEach(reminders.prefix(4)) { r in
                    Button {
                        if let eid = r.entityId {
                            nav.onOpen(.entity(eid, title: r.title))
                        }
                    } label: {
                        POSListRow(
                            title: r.title,
                            subtitle: POSFormatting.friendlyDue(r.dueAt),
                            systemImage: "calendar"
                        )
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
