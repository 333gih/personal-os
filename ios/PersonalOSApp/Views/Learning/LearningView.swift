import SwiftUI

struct LearningView: View {
    @EnvironmentObject private var session: SessionManager
    let nav: POSNavigationActions

    @State private var items: [POSEntity] = []
    @State private var isLoading = true
    @State private var selectedTrack: POSLearningTrack = .dsa
    @State private var todayPlan: POSTodayStudyPlan?
    @State private var isLoadingToday = true
    @State private var showScheduleSettings = false
    @State private var loadError: String?

    private var dsaCourse: POSEntity? {
        items.first { $0.type.contains("course") && ($0.tagList.contains("dsa") || $0.metadata?.track == "dsa") }
    }

    private var dsaPatterns: [POSEntity] {
        items.filter {
            $0.type.contains("topic")
                && ($0.tagList.contains("dsa") || $0.metadata?.track == "dsa")
                && ($0.metadata?.patternOrder ?? 0) > 0
        }
        .sorted { ($0.metadata?.patternOrder ?? 999) < ($1.metadata?.patternOrder ?? 999) }
    }

    private var englishCourses: [POSEntity] {
        items.filter { $0.type.contains("course") && ($0.tagList.contains("english") || $0.metadata?.track == "english") }
    }

    private var englishModules: [POSEntity] {
        items.filter { $0.type.contains("topic") && ($0.tagList.contains("english") || $0.metadata?.track == "english") }
    }

    var body: some View {
        POSScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if selectedTrack == .dsa {
                        POSDSADailyFocusCard(
                            focus: todayPlan?.dsa,
                            onOpenPattern: {
                                if let id = todayPlan?.dsa?.patternEntityID {
                                    nav.openLearningLesson(id: id, title: todayPlan?.dsa?.patternTitle ?? "Pattern")
                                }
                            },
                            onCoach: {
                                nav.openLearningCoach(
                                    track: .dsa,
                                    entityID: todayPlan?.dsa?.patternEntityID,
                                    topic: todayPlan?.dsa?.patternTitle ?? ""
                                )
                            }
                        )
                    }
                    POSTodayStudySection(
                        plan: todayPlan,
                        isLoading: isLoadingToday,
                        onOpenBlock: { block in
                            if let entityID = block.entityID {
                                nav.openLearningLesson(id: entityID, title: block.title)
                            } else {
                                let track: POSLearningTrack = block.track == "english" ? .english : .dsa
                                nav.openLearningCoach(track: track, topic: block.title)
                            }
                        },
                        onEditSchedule: { showScheduleSettings = true }
                    )
                    trackPicker
                    if let loadError {
                        Text(loadError)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.vertical, 4)
                    }
                    metricsRow
                    if selectedTrack == .dsa {
                        dsaRoadmapSection
                        dsaPatternsSection
                    } else {
                        englishCoursesSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                Button { nav.openLearningHub() } label: {
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
        .task(id: session.user?.id) { await load() }
        .refreshable { await load() }
        .sheet(isPresented: $showScheduleSettings) {
            POSLearningScheduleSettingsView()
                .environmentObject(session)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Study desk")
                    .font(.posDisplay(28))
                Text("DSA mastery + TOEIC hardcore — optimized for metro & bus commutes.")
                    .font(.subheadline)
                    .foregroundStyle(POSTheme.muted)
            }
            Spacer()
            Button { nav.openLearningHub() } label: {
                Label("Menu", systemImage: "line.3.horizontal.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
            }
            .buttonStyle(POSPressButtonStyle())
        }
    }

    private var trackPicker: some View {
        Picker("Track", selection: $selectedTrack) {
            ForEach(POSLearningTrack.allCases) { track in
                Label(track.title, systemImage: track.icon).tag(track)
            }
        }
        .pickerStyle(.segmented)
    }

    private var metricsRow: some View {
        HStack(spacing: 12) {
            POSMetricCard(
                label: selectedTrack == .dsa ? "Patterns" : "Courses",
                value: isLoading ? "—" : "\(selectedTrack == .dsa ? dsaPatterns.count : englishCourses.count)",
                hint: selectedTrack == .dsa ? "20-pattern roadmap" : "Structured modules",
                systemImage: selectedTrack.icon,
                accent: POSTheme.primaryDark,
                action: { nav.openLearningCoach(track: selectedTrack) }
            )
            POSMetricCard(
                label: "AI Coach",
                value: "✦",
                hint: "Practice drill",
                systemImage: "sparkles",
                accent: POSTheme.focus,
                action: { nav.openLearningCoach(track: selectedTrack) }
            )
        }
    }

    @ViewBuilder
    private var dsaRoadmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "DSA Mastery System", eyebrow: "10-week · 150+ problems")
            if isLoading {
                POSLoadingView()
            } else if let course = dsaCourse {
                Button { nav.openLearningLesson(id: course.id, title: course.title) } label: {
                    POSCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(course.title).font(.headline)
                            Text(course.content).font(.caption).foregroundStyle(POSTheme.muted).lineLimit(3)
                            HStack {
                                Label("Mid → Senior", systemImage: "arrow.up.right")
                                Spacer()
                                Button {
                                    nav.openLearningCoach(track: .dsa, entityID: course.id, topic: course.title)
                                } label: {
                                    Label("Coach", systemImage: "sparkles").font(.caption.weight(.semibold))
                                }
                                .buttonStyle(.plain)
                            }
                            .font(.caption)
                            .foregroundStyle(POSTheme.primaryDark)
                        }
                    }
                }
                .buttonStyle(POSPressButtonStyle())
            } else {
                emptySeedState(track: .dsa)
            }
        }
    }

    @ViewBuilder
    private var dsaPatternsSection: some View {
        if !dsaPatterns.isEmpty {
            ForEach(["foundation", "intermediate", "advanced", "expert"], id: \.self) { phase in
                let group = dsaPatterns.filter { ($0.metadata?.phase ?? "").lowercased() == phase }
                if !group.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        POSSectionHeader(title: phaseLabel(phase), eyebrow: "Weeks \(phaseWeeks(phase))")
                        ForEach(group) { pattern in
                            patternRow(pattern)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var englishCoursesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "English / TOEIC", eyebrow: "Hardcore vocab · grammar · listening · reading")
            if isLoading {
                POSLoadingView()
            } else if englishCourses.isEmpty {
                emptySeedState(track: .english)
            } else {
                ForEach(englishCourses) { course in
                    VStack(alignment: .leading, spacing: 8) {
                        Button { nav.openLearningLesson(id: course.id, title: course.title) } label: {
                            POSCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(course.title).font(.subheadline.weight(.semibold))
                                    Text(course.content).font(.caption).foregroundStyle(POSTheme.muted).lineLimit(2)
                                }
                            }
                        }
                        .buttonStyle(POSPressButtonStyle())

                        let modules = englishModules.filter { $0.metadata?.courseSlug == course.metadata?.courseSlug }
                        ForEach(modules) { mod in
                            Button { nav.openLearningLesson(id: mod.id, title: mod.title) } label: {
                                POSListRow(
                                    title: mod.title,
                                    subtitle: mod.content,
                                    systemImage: "text.book.closed",
                                    iconTint: POSTheme.focus
                                )
                            }
                            .buttonStyle(POSPressButtonStyle())
                        }
                    }
                }
            }
        }
    }

    private func patternRow(_ pattern: POSEntity) -> some View {
        Button {
            nav.openLearningLesson(id: pattern.id, title: pattern.title)
        } label: {
            HStack(spacing: 12) {
                Text("\(pattern.metadata?.patternOrder ?? 0)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(POSTheme.primaryDark)
                    .frame(width: 28, height: 28)
                    .background(POSTheme.primary.opacity(0.12))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(pattern.title).font(.subheadline.weight(.medium)).lineLimit(1)
                    if let when = pattern.metadata?.whenToUse, !when.isEmpty {
                        Text(when).font(.caption2).foregroundStyle(POSTheme.muted).lineLimit(2)
                    } else {
                        Text(pattern.content).font(.caption).foregroundStyle(POSTheme.muted).lineLimit(2)
                    }
                    if let probs = pattern.metadata?.problems, !probs.isEmpty {
                        Text(probs.prefix(4).joined(separator: " · "))
                            .font(.caption2)
                            .foregroundStyle(POSTheme.primaryDark.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                Spacer()
                Button {
                    nav.openLearningCoach(track: .dsa, entityID: pattern.id, topic: pattern.title)
                } label: {
                    Image(systemName: "sparkles").font(.caption).foregroundStyle(POSTheme.focus)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(POSTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: POSTheme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: POSTheme.cardRadius).stroke(POSTheme.border, lineWidth: 1))
        }
        .buttonStyle(POSPressButtonStyle())
    }

    private func emptySeedState(track: POSLearningTrack) -> some View {
        POSEmptyState(
            systemImage: track.icon,
            title: "Curriculum not seeded",
            message: "Pull to refresh after signing in. If empty, open Profile once then retry.",
            actionTitle: "Add entry",
            action: { nav.openLearningAdd(track: track) }
        )
    }

    private func phaseLabel(_ phase: String) -> String {
        switch phase {
        case "foundation": return "Foundation"
        case "intermediate": return "Intermediate"
        case "advanced": return "Advanced"
        case "expert": return "Expert"
        default: return phase.capitalized
        }
    }

    private func phaseWeeks(_ phase: String) -> String {
        switch phase {
        case "foundation": return "1–2"
        case "intermediate": return "3–5"
        case "advanced": return "6–8"
        case "expert": return "8–10"
        default: return "—"
        }
    }

    private func load() async {
        guard !Task.isCancelled else { return }
        isLoading = true
        isLoadingToday = true
        loadError = nil
        defer {
            isLoading = false
            isLoadingToday = false
        }
        do {
            async let entitiesResponse = session.api.listEntities(domain: "learning")
            async let planResponse = session.api.fetchLearningToday()
            let (entities, plan) = try await (entitiesResponse, planResponse)
            guard !Task.isCancelled else { return }
            items = entities.items
            todayPlan = plan
            Task { await POSLocalNotificationScheduler.shared.schedule(plan: plan) }
            if items.isEmpty {
                loadError = "No learning data yet — pull to refresh (server syncs on login)."
            }
        } catch {
            guard !POSLoadTask.isBenignCancellation(error) else { return }
            items = []
            todayPlan = nil
            loadError = error.localizedDescription
        }
    }
}
