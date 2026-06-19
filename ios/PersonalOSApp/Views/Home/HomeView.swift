import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: SessionManager
    let onOpen: WebOpenHandler

    @State private var dashboard: POSDashboard?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.firstName())
                        .font(.posDisplay(32))
                    Text("Your personal knowledge at a glance")
                        .font(.subheadline)
                        .foregroundStyle(POSTheme.muted)
                }

                if isLoading {
                    POSLoadingView(label: "Loading dashboard…")
                } else if let errorMessage {
                    POSEmptyState(systemImage: "wifi.exclamationmark", title: "Could not load", message: errorMessage)
                } else if let dashboard {
                    deepFocusCard(dashboard)
                    metricsRow(dashboard)
                    quickActions
                    curationSection(dashboard)
                    upNextSection(dashboard)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .task(id: session.accessToken) { await load() }
        .refreshable { await load() }
    }

    private func deepFocusCard(_ data: POSDashboard) -> some View {
        let learning = data.domainCounts["learning"] ?? 0
        let total = data.domainCounts.values.reduce(0, +)
        let pct = total > 0 ? min(100, Int(Double(learning) / Double(max(total, 1)) * 100) + 35) : 0

        return POSCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("DEEP FOCUS", systemImage: "bolt.fill")
                    .font(.posLabel(10))
                    .tracking(1.2)
                    .foregroundStyle(POSTheme.success)
                Text(total > 0 ? "\(learning) tracked" : "—")
                    .font(.posDisplay(36))
                Text(total > 0 ? "\(pct)% of daily goal achieved" : "Log study to track focus")
                    .font(.subheadline)
                    .foregroundStyle(POSTheme.muted)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(POSTheme.border)
                        Capsule()
                            .fill(POSTheme.success)
                            .frame(width: geo.size.width * CGFloat(max(pct, total > 0 ? 8 : 0)) / 100)
                    }
                }
                .frame(height: 8)
            }
        }
    }

    private func metricsRow(_ data: POSDashboard) -> some View {
        HStack(spacing: 12) {
            POSMetricCard(
                label: "Tasks",
                value: "\(data.inboxCount)",
                hint: data.inboxCount > 0 ? "In inbox" : "Inbox clear",
                systemImage: "checklist",
                accent: POSTheme.primaryDark
            )
            POSMetricCard(
                label: "Knowledge",
                value: data.domainCounts.values.reduce(0, +) > 0 ? "Active" : "Empty",
                hint: "\(data.domainCounts.values.reduce(0, +)) items",
                systemImage: "chart.line.uptrend.xyaxis",
                accent: POSTheme.success
            )
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Quick Actions", actionTitle: "Manage") {
                onOpen(.path("/inbox", title: "Inbox"))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    quickAction(title: "ADD TASK", icon: "plus.circle.fill", filled: true) {
                        onOpen(.path("/inbox", title: "Inbox"))
                    }
                    quickAction(title: "LOG STUDY", icon: "book.fill", filled: false) {
                        onOpen(.path("/learning", title: "Learning"))
                    }
                    quickAction(title: "SEARCH", icon: "lightbulb.fill", filled: false) {
                        onOpen(.path("/search", title: "Search"))
                    }
                }
            }
        }
    }

    private func quickAction(title: String, icon: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.posLabel(10))
            }
            .foregroundStyle(filled ? .white : POSTheme.foreground)
            .frame(width: 112, height: 112)
            .background(filled ? POSTheme.primaryDark : POSTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: POSTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: POSTheme.cardRadius, style: .continuous)
                    .stroke(POSTheme.border.opacity(filled ? 0 : 0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func curationSection(_ data: POSDashboard) -> some View {
        Group {
            if let recent = data.recent.first {
                VStack(alignment: .leading, spacing: 12) {
                    POSSectionHeader(title: "Weekly Curation", eyebrow: "Featured")
                    Button { onOpen(.entity(recent.id, title: recent.title)) } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FROM YOUR LIBRARY")
                                .font(.posLabel(10))
                                .foregroundStyle(.white.opacity(0.7))
                            Text(recent.title)
                                .font(.posDisplay(22))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.leading)
                            Text(recent.content)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(2)
                            Text("OPEN ITEM")
                                .font(.posLabel(10))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.white)
                                .foregroundStyle(POSTheme.foreground)
                                .clipShape(Capsule())
                                .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            LinearGradient(colors: [Color(white: 0.25), Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: POSTheme.cardRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                POSEmptyState(
                    systemImage: "sparkles",
                    title: "No featured content",
                    message: "Capture notes in Inbox or Learning."
                )
            }
        }
    }

    private func upNextSection(_ data: POSDashboard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Up Next")
            if data.upcomingReminders.isEmpty {
                POSEmptyState(systemImage: "brain.head.profile", title: "Nothing scheduled", message: "Add reminders to see them here.")
            } else {
                ForEach(data.upcomingReminders.prefix(5)) { reminder in
                    Button {
                        if let eid = reminder.entityId {
                            onOpen(.entity(eid, title: reminder.title))
                        }
                    } label: {
                        POSListRow(
                            title: reminder.title,
                            subtitle: reminder.dueAt,
                            badge: reminder.status,
                            systemImage: "brain.head.profile",
                            iconTint: POSTheme.success
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            dashboard = try await session.api.dashboard()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
