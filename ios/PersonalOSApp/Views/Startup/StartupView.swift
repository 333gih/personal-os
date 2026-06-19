import SwiftUI

struct StartupView: View {
    @EnvironmentObject private var session: SessionManager
    let onOpen: WebOpenHandler

    @State private var items: [POSEntity] = []
    @State private var reminders: [POSReminder] = []
    @State private var isLoading = true

    private var ideas: [POSEntity] { items.filter { $0.type.contains("idea") } }
    private var kpis: [POSEntity] { items.filter { $0.type.contains("kpi") } }
    private var recent: [POSEntity] {
        items.sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    POSMetricCard(label: "Portfolio", value: items.isEmpty ? "—" : "\(items.count)", hint: "Tracked entities", systemImage: "chart.line.uptrend.xyaxis", accent: POSTheme.success)
                    POSMetricCard(label: "Active", value: "\(max(ideas.count, items.count))", hint: "Ideas & companies", systemImage: "building.2.fill")
                }
                portfolioSection
                networkSection
                scheduleSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .task(id: session.accessToken) { await load() }
    }

    private var portfolioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Portfolio Highlights", actionTitle: "View all") {
                onOpen(.path("/startup", title: "Startup"))
            }
            if isLoading {
                POSLoadingView()
            } else if items.isEmpty {
                POSEmptyState(systemImage: "building.2.fill", title: "No portfolio yet", message: "Capture startup ideas and KPIs.")
            } else {
                ForEach(Array((ideas.isEmpty ? items : ideas).prefix(3).enumerated()), id: \.element.id) { index, item in
                    Button { onOpen(.entity(item.id, title: item.title)) } label: {
                        POSCard {
                            HStack {
                                Text(String(item.title.prefix(1)).uppercased())
                                    .font(.headline)
                                    .frame(width: 40, height: 40)
                                    .background(POSTheme.border.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading) {
                                    Text(item.title).font(.headline)
                                    Text(item.type.replacingOccurrences(of: "_", with: " ").capitalized)
                                        .font(.caption)
                                        .foregroundStyle(POSTheme.muted)
                                }
                                Spacer()
                                Text(index == 0 ? "GROWTH" : "STEADY")
                                    .font(.posLabel(9))
                                    .foregroundStyle(index == 0 ? POSTheme.primary : POSTheme.success)
                            }
                            Text(item.content).font(.caption).foregroundStyle(POSTheme.muted).lineLimit(2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var networkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Network Activity")
            if recent.isEmpty && !isLoading {
                POSEmptyState(systemImage: "envelope.fill", title: "No activity", message: "Updates appear when you edit startup entities.")
            } else {
                ForEach(recent.prefix(3)) { item in
                    Button { onOpen(.entity(item.id, title: item.title)) } label: {
                        POSListRow(title: item.title, subtitle: item.updatedAt, systemImage: "person.badge.plus", iconTint: POSTheme.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Startup Schedule")
            if reminders.isEmpty {
                POSEmptyState(systemImage: "clock.fill", title: "No events", message: "Add reminders to startup entities.")
            } else {
                ForEach(reminders.prefix(4)) { r in
                    POSListRow(title: r.title, subtitle: r.dueAt, badge: "EVENT", systemImage: "calendar")
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
