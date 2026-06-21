import SwiftUI

struct LearningView: View {
    @EnvironmentObject private var session: SessionManager
    let nav: POSNavigationActions

    @State private var items: [POSEntity] = []
    @State private var isLoading = true
    @State private var selectedTrack: POSLearningTrack = .dsa

    private var dsaCourse: POSEntity? {
        items.first { $0.type.contains("course") && ($0.tagList.contains("dsa") || $0.metadata?.track == "dsa") }
    }

    private var dsaPatterns: [POSEntity] {
        items.filter { $0.type.contains("topic") && ($0.tagList.contains("dsa") || $0.metadata?.track == "dsa") }
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
                    trackPicker
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
        .task(id: session.accessToken) { await load() }
        .refreshable { await load() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Study desk")
                    .font(.posDisplay(28))
                Text("DSA mastery + English courses — structured for daily practice.")
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
                Button { nav.onOpen(.entity(course.id, title: course.title)) } label: {
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
            POSSectionHeader(title: "English courses", eyebrow: "Interview · Business · IELTS")
            if isLoading {
                POSLoadingView()
            } else if englishCourses.isEmpty {
                emptySeedState(track: .english)
            } else {
                ForEach(englishCourses) { course in
                    VStack(alignment: .leading, spacing: 8) {
                        Button { nav.onOpen(.entity(course.id, title: course.title)) } label: {
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
                            Button { nav.onOpen(.entity(mod.id, title: mod.title)) } label: {
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
            nav.onOpen(.entity(pattern.id, title: pattern.title))
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
                    Text(pattern.content).font(.caption).foregroundStyle(POSTheme.muted).lineLimit(2)
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
            message: "Run migration 020 on server or add entries via Learning menu.",
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
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await session.api.listEntities(domain: "learning").items
        } catch {
            items = []
        }
    }
}
