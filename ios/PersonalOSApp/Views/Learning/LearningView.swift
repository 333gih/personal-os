import SwiftUI

struct LearningView: View {
    @EnvironmentObject private var session: SessionManager
    let nav: POSNavigationActions

    @State private var items: [POSEntity] = []
    @State private var isLoading = true

    private let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private var courses: [POSEntity] { items.filter { $0.type.contains("course") } }
    private var certs: [POSEntity] { items.filter { $0.type.contains("certificate") } }
    private var skills: [POSEntity] { items.filter { $0.type.contains("skill") } }
    private var topics: [POSEntity] { items.filter { $0.type.contains("topic") } }

    var body: some View {
        POSScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Study desk")
                            .font(.posDisplay(28))
                        Text("Courses, streaks, and the next milestone on your desk.")
                            .font(.subheadline)
                            .foregroundStyle(POSTheme.muted)
                    }

                    optimizerHeader
                    scheduleCard
                    currentLearningSection
                    rhythmCard
                    milestonesSection
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

    private var optimizerHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("This week")
                    .font(.posDisplay(18))
                Text("Keep study blocks close to work notes.")
                    .font(.caption)
                    .foregroundStyle(POSTheme.muted)
            }
            Spacer()
            Button {
                nav.onOpen(.path("/learning", title: "Learning"))
            } label: {
                Text("Open planner")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(POSTheme.ink)
                    .foregroundStyle(POSTheme.background)
                    .clipShape(Capsule())
            }
            .buttonStyle(POSPressButtonStyle())
        }
    }

    private var scheduleCard: some View {
        POSCard {
            if items.isEmpty && !isLoading {
                POSEmptyState(
                    systemImage: "calendar",
                    title: "No study blocks yet",
                    message: "Add a course or topic and your week will take shape here.",
                    actionTitle: "Log study",
                    action: nav.captureNote
                )
            } else if isLoading {
                POSLoadingView()
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(items.prefix(3).enumerated()), id: \.element.id) { index, item in
                        Button { nav.onOpen(.entity(item.id, title: item.title)) } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .stroke(POSTheme.primaryDark, lineWidth: 2)
                                    .frame(width: 12, height: 12)
                                    .padding(.top, 5)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Session \(index + 1)")
                                        .font(.caption)
                                        .foregroundStyle(POSTheme.muted)
                                    Text(item.title)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(POSTheme.ink)
                                    Text(POSFormatting.humanType(item.type))
                                        .font(.caption)
                                        .foregroundStyle(POSTheme.muted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(POSTheme.muted)
                            }
                        }
                        .buttonStyle(POSPressButtonStyle())
                    }
                }
            }
        }
    }

    private var currentLearningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "On the desk now")
            HStack(spacing: 12) {
                POSMetricCard(
                    label: "Courses",
                    value: "\(courses.count)",
                    hint: courses.isEmpty ? "Add one" : "In progress",
                    systemImage: "graduationcap",
                    accent: POSTheme.primaryDark,
                    action: { nav.onOpen(.path("/learning", title: "Learning")) }
                )
                POSMetricCard(
                    label: "Streak",
                    value: items.isEmpty ? "—" : "\(min(items.count, 30))d",
                    hint: skills.first?.title ?? "Keep showing up",
                    systemImage: "flame.fill",
                    accent: POSTheme.focus,
                    action: { nav.onSwitchTab(.home) }
                )
            }
            if let course = courses.first {
                Button { nav.onOpen(.entity(course.id, title: course.title)) } label: {
                    HStack(spacing: 12) {
                        Text("C1")
                            .font(.headline)
                            .foregroundStyle(POSTheme.focus)
                            .frame(width: 46, height: 46)
                            .background(POSTheme.successBg)
                            .clipShape(Circle())
                        VStack(alignment: .leading) {
                            Text(course.title).font(.headline)
                            Text(course.content).font(.caption).foregroundStyle(POSTheme.muted).lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(POSTheme.muted)
                    }
                    .padding(14)
                    .background(POSTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: POSTheme.cardRadius))
                    .overlay(RoundedRectangle(cornerRadius: POSTheme.cardRadius).stroke(POSTheme.border, lineWidth: 1))
                }
                .buttonStyle(POSPressButtonStyle())
            }
        }
    }

    private var rhythmCard: some View {
        let level = items.count >= 10 ? "Steady" : items.count >= 3 ? "Building" : "Starting"
        let today = Calendar.current.component(.weekday, from: Date())
        let chartIndex = today == 1 ? 6 : today - 2

        return POSCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Weekly rhythm")
                            .font(.posDisplay(18))
                        Text("A quiet view of study momentum")
                            .font(.caption)
                            .foregroundStyle(POSTheme.muted)
                    }
                    Spacer()
                    Text(level)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(POSTheme.border.opacity(0.5))
                        .clipShape(Capsule())
                }
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(weekdays.indices, id: \.self) { i in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(i == chartIndex ? POSTheme.primaryDark : POSTheme.border.opacity(0.8))
                                .frame(height: CGFloat(18 + ((i + items.count) % 5) * 8))
                            Text(weekdays[i])
                                .font(.system(size: 9))
                                .foregroundStyle(POSTheme.muted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 88)
            }
        }
    }

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Milestones ahead", actionTitle: "Add") {
                nav.captureNote()
            }
            let milestones = certs + topics
            if milestones.isEmpty && !isLoading {
                POSEmptyState(
                    systemImage: "flag",
                    title: "No milestones pinned",
                    message: "Certificates and topics with dates will show up here.",
                    actionTitle: "Add milestone",
                    action: nav.captureNote
                )
            } else {
                ForEach(milestones.prefix(5)) { item in
                    Button { nav.onOpen(.entity(item.id, title: item.title)) } label: {
                        POSListRow(
                            title: item.title,
                            subtitle: POSFormatting.humanType(item.type),
                            systemImage: item.type.contains("certificate") ? "rosette" : "book",
                            iconTint: POSTheme.primaryDark
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
            items = try await session.api.listEntities(domain: "learning").items
        } catch {
            items = []
        }
    }
}
