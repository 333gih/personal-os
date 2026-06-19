import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: SessionManager
    let nav: POSNavigationActions

    @State private var dashboard: POSDashboard?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        POSScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    POSJournalDateStamp(name: session.firstName())

                    if isLoading {
                        POSLoadingView(label: "Opening your journal…")
                    } else if let errorMessage {
                        POSEmptyState(
                            systemImage: "wifi.exclamationmark",
                            title: "Could not refresh",
                            message: errorMessage,
                            actionTitle: "Try again",
                            action: { Task { await load() } }
                        )
                    } else if let dashboard {
                        focusCard(dashboard)
                        metricsRow(dashboard)
                        quickActions
                        POSNoteDivider()
                        readingSection(dashboard)
                        POSNoteDivider()
                        upNextSection(dashboard)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            POSFloatingCaptureButton(action: nav.captureNote)
                .padding(.trailing, 18)
                .padding(.bottom, 12)
        }
        .task(id: session.accessToken) { await load() }
        .refreshable { await load() }
    }

    private func focusCard(_ data: POSDashboard) -> some View {
        let total = data.domainCounts.values.reduce(0, +)
        let learning = data.domainCounts["learning"] ?? 0
        let work = data.domainCounts["work"] ?? 0
        let pct = total > 0 ? min(100, 28 + learning * 8 + work * 4) : 0

        return Button {
            nav.onSwitchTab(.learning)
        } label: {
            POSCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Today's focus", systemImage: "leaf.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(POSTheme.focus)
                    Text(total > 0 ? "\(learning + work) entries" : "Start a note")
                        .font(.posDisplay(34))
                        .foregroundStyle(POSTheme.ink)
                    Text(total > 0 ? "You have been building across learning and work." : "Capture one thought in Inbox to begin tracking.")
                        .font(.subheadline)
                        .foregroundStyle(POSTheme.muted)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(POSTheme.border.opacity(0.7))
                            Capsule()
                                .fill(POSTheme.focus)
                                .frame(width: geo.size.width * CGFloat(max(pct, total > 0 ? 10 : 0)) / 100)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .buttonStyle(POSPressButtonStyle())
    }

    private func metricsRow(_ data: POSDashboard) -> some View {
        HStack(spacing: 12) {
            POSMetricCard(
                label: "Inbox",
                value: "\(data.inboxCount)",
                hint: data.inboxCount > 0 ? "Waiting to sort" : "All caught up",
                systemImage: "tray.fill",
                accent: POSTheme.primaryDark,
                action: { nav.onOpen(.path("/inbox", title: "Inbox")) }
            )
            POSMetricCard(
                label: "Library",
                value: "\(data.domainCounts.values.reduce(0, +))",
                hint: "Notes & projects",
                systemImage: "books.vertical.fill",
                accent: POSTheme.focus,
                action: { nav.onSwitchTab(.search) }
            )
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Quick capture", actionTitle: "Inbox") {
                nav.onOpen(.path("/inbox", title: "Inbox"))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    actionTile("New note", icon: "square.and.pencil", filled: true, action: nav.captureNote)
                    actionTile("Study log", icon: "book.closed.fill", filled: false) {
                        nav.onSwitchTab(.learning)
                    }
                    actionTile("Reading", icon: "text.book.closed.fill", filled: false, action: nav.openStorySync)
                    actionTile("Search", icon: "magnifyingglass", filled: false) {
                        nav.onSwitchTab(.search)
                    }
                }
            }
        }
    }

    private func actionTile(_ title: String, icon: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon).font(.title3)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(filled ? POSTheme.background : POSTheme.ink)
            .frame(width: 118, height: 96, alignment: .leading)
            .padding(14)
            .background(filled ? POSTheme.ink : POSTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: POSTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: POSTheme.cardRadius, style: .continuous)
                    .stroke(POSTheme.border.opacity(filled ? 0 : 0.8), lineWidth: 1)
            )
        }
        .buttonStyle(POSPressButtonStyle())
    }

    private func readingSection(_ data: POSDashboard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "From your shelf", eyebrow: "Recently touched", actionTitle: "Reading log") {
                nav.openStorySync()
            }
            if let recent = data.recent.first {
                Button { nav.onOpen(.entity(recent.id, title: recent.title)) } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(POSFormatting.domainLabel(recent.domain))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(POSTheme.muted)
                        Text(recent.title)
                            .font(.posDisplay(22))
                            .foregroundStyle(POSTheme.ink)
                            .multilineTextAlignment(.leading)
                        Text(recent.content)
                            .font(.subheadline)
                            .foregroundStyle(POSTheme.muted)
                            .lineLimit(3)
                        Text("Open entry")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(POSTheme.primaryDark)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(POSTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: POSTheme.cardRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: POSTheme.cardRadius, style: .continuous)
                            .stroke(POSTheme.border, lineWidth: 1)
                    )
                }
                .buttonStyle(POSPressButtonStyle())
            } else {
                POSEmptyState(
                    systemImage: "books.vertical",
                    title: "Nothing on the shelf yet",
                    message: "Your latest note or reading entry will land here.",
                    actionTitle: "Capture a note",
                    action: nav.captureNote
                )
            }
        }
    }

    private func upNextSection(_ data: POSDashboard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Up next")
            if data.upcomingReminders.isEmpty {
                POSEmptyState(
                    systemImage: "clock",
                    title: "A clear afternoon",
                    message: "Add a reminder to any entry and it will appear here.",
                    actionTitle: "Open inbox",
                    action: { nav.onOpen(.path("/inbox", title: "Inbox")) }
                )
            } else {
                ForEach(data.upcomingReminders.prefix(5)) { reminder in
                    Button {
                        if let eid = reminder.entityId {
                            nav.onOpen(.entity(eid, title: reminder.title))
                        } else {
                            nav.onOpen(.path("/inbox", title: "Reminders"))
                        }
                    } label: {
                        POSListRow(
                            title: reminder.title,
                            subtitle: POSFormatting.friendlyDue(reminder.dueAt),
                            badge: reminder.status,
                            systemImage: "clock.badge",
                            iconTint: POSTheme.focus
                        )
                    }
                    .buttonStyle(POSPressButtonStyle())
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
