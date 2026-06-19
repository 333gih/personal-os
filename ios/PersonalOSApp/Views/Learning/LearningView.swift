import SwiftUI

struct LearningView: View {
    @EnvironmentObject private var session: SessionManager
    let onOpen: WebOpenHandler

    @State private var items: [POSEntity] = []
    @State private var isLoading = true

    private let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private var courses: [POSEntity] { items.filter { $0.type.contains("course") } }
    private var certs: [POSEntity] { items.filter { $0.type.contains("certificate") } }
    private var skills: [POSEntity] { items.filter { $0.type.contains("skill") } }
    private var topics: [POSEntity] { items.filter { $0.type.contains("topic") } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                optimizerHeader
                scheduleCard
                currentLearningSection
                masteryCurve
                milestonesSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .task(id: session.accessToken) { await load() }
        .refreshable { await load() }
    }

    private var optimizerHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Optimizer").font(.posDisplay(20))
                Text("Work & Study Sync").font(.subheadline).foregroundStyle(POSTheme.muted)
            }
            Spacer()
            Button("OPTIMIZE") { onOpen(.path("/learning", title: "Learning")) }
                .font(.posLabel(10))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(POSTheme.primaryDark)
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
    }

    private var scheduleCard: some View {
        POSCard {
            if items.isEmpty && !isLoading {
                POSEmptyState(systemImage: "calendar", title: "No schedule yet", message: "Add courses to build your timeline.")
            } else if isLoading {
                POSLoadingView()
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(items.prefix(3).enumerated()), id: \.element.id) { index, item in
                        HStack(alignment: .top, spacing: 12) {
                            Circle().stroke(POSTheme.primaryDark, lineWidth: 2).frame(width: 14, height: 14).padding(.top, 4)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Block \(index + 1)").font(.caption).foregroundStyle(POSTheme.muted)
                                Button(item.title) { onOpen(.entity(item.id, title: item.title)) }
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(POSTheme.foreground)
                                Text(item.type.replacingOccurrences(of: "_", with: " ").uppercased())
                                    .font(.posLabel(9))
                                    .foregroundStyle(POSTheme.muted)
                                if index == 1 {
                                    Text("Auto-optimized reminder available")
                                        .font(.caption)
                                        .padding(8)
                                        .background(POSTheme.successBg)
                                        .foregroundStyle(POSTheme.success)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var currentLearningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Current Learning")
            HStack(spacing: 12) {
                POSMetricCard(label: "Courses", value: "\(courses.count)", hint: courses.isEmpty ? "Add a course" : "Active", systemImage: "graduationcap.fill", accent: POSTheme.primaryDark)
                POSMetricCard(label: "Streak", value: items.isEmpty ? "—" : "\(min(items.count, 30)) days", hint: skills.first?.title ?? "Track daily study", systemImage: "bolt.fill", accent: POSTheme.success)
            }
            if let course = courses.first {
                Button { onOpen(.entity(course.id, title: course.title)) } label: {
                    HStack(spacing: 12) {
                        Text("C1")
                            .font(.headline)
                            .foregroundStyle(POSTheme.success)
                            .frame(width: 48, height: 48)
                            .background(POSTheme.successBg)
                            .clipShape(Circle())
                        VStack(alignment: .leading) {
                            Text(course.title).font(.headline)
                            Text(course.content).font(.caption).foregroundStyle(POSTheme.muted).lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(POSTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: POSTheme.cardRadius))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var masteryCurve: some View {
        let level = items.count >= 10 ? "EXPERT" : items.count >= 3 ? "GROWING" : "STARTER"
        let today = Calendar.current.component(.weekday, from: Date())
        let chartIndex = today == 1 ? 6 : today - 2

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Mastery Curve").font(.posDisplay(18)).foregroundStyle(.white)
                    Text("Learning activity index").font(.caption).foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Text(level).font(.posLabel(9)).padding(.horizontal, 8).padding(.vertical, 4).background(POSTheme.primary).clipShape(Capsule())
            }
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(weekdays.indices, id: \.self) { i in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(i == chartIndex ? POSTheme.primary : Color.white.opacity(0.2))
                            .frame(height: CGFloat(24 + ((i + items.count) % 5) * 10))
                        Text(weekdays[i]).font(.system(size: 9)).foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
        }
        .padding(20)
        .background(Color(white: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: POSTheme.cardRadius))
    }

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Future Milestones")
            let milestones = certs + topics
            if milestones.isEmpty && !isLoading {
                POSEmptyState(systemImage: "rosette", title: "No milestones yet", message: "Add certificates and topics.")
            } else {
                ForEach(milestones.prefix(5)) { item in
                    Button { onOpen(.entity(item.id, title: item.title)) } label: {
                        POSListRow(
                            title: item.title,
                            subtitle: item.type.replacingOccurrences(of: "_", with: " ").capitalized,
                            systemImage: item.type.contains("certificate") ? "rosette" : "book.fill",
                            iconTint: POSTheme.primaryDark
                        )
                    }
                    .buttonStyle(.plain)
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
