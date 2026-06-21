import SwiftUI

struct POSLearningLessonView: View {
    @EnvironmentObject private var session: SessionManager
    let entityId: String
    let onOpenModule: (String, String) -> Void
    let onClose: () -> Void

    @State private var lesson: POSLearningLesson?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var practiceResult: POSLearningCoachResult?
    @State private var practiceLabel = ""
    @State private var isPracticing = false
    @State private var practiceError: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    POSLoadingView(label: "Loading lesson…")
                } else if let loadError {
                    POSEmptyState(
                        systemImage: "exclamationmark.triangle",
                        title: "Could not load lesson",
                        message: loadError,
                        actionTitle: "Retry",
                        action: { Task { await load() } }
                    )
                } else if let lesson {
                    lessonBody(lesson)
                }
            }
            .background(POSTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { onClose() }
                }
                ToolbarItem(placement: .principal) {
                    Text(lesson?.title ?? "Lesson")
                        .font(.headline)
                        .lineLimit(1)
                }
            }
        }
        .task(id: entityId) { await load() }
    }

    @ViewBuilder
    private func lessonBody(_ lesson: POSLearningLesson) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(lesson)
                overviewCard(lesson)
                if lesson.isDSA, let when = lesson.whenToUse, !when.isEmpty {
                    lessonCard("When to use", icon: "lightbulb.fill", body: when)
                }
                if let signals = lesson.recognitionSignals, !signals.isEmpty {
                    bulletCard("Recognition signals", icon: "eye.fill", items: signals)
                }
                if let strategy = lesson.practiceStrategy, !strategy.isEmpty {
                    lessonCard("Practice strategy", icon: "map.fill", body: strategy)
                }
                if let template = lesson.codeTemplate, !template.isEmpty {
                    codeCard(template)
                }
                if let problems = lesson.problems, !problems.isEmpty {
                    problemsCard(problems, benchmarks: lesson.benchmarks)
                }
                if let modules = lesson.modules, !modules.isEmpty {
                    modulesSection(modules)
                }
                practiceSection(lesson)
                if let practiceResult {
                    practiceResultCard(practiceResult, label: practiceLabel)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    private func header(_ lesson: POSLearningLesson) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if lesson.patternOrder > 0 {
                    Text("#\(lesson.patternOrder)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(POSTheme.primaryDark)
                        .frame(width: 32, height: 32)
                        .background(POSTheme.primary.opacity(0.12))
                        .clipShape(Circle())
                }
                Label(lesson.isDSA ? "DSA Pattern" : lesson.track.capitalized, systemImage: lesson.isDSA ? "function" : "text.book.closed")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                Spacer()
                if lesson.curriculumWeek > 0 {
                    Text("Week \(lesson.curriculumWeek)")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(POSTheme.focus.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            if let phase = lesson.phase, !phase.isEmpty {
                Text("\(phase.capitalized) · \(lesson.weeks ?? "10-week program")")
                    .font(.caption)
                    .foregroundStyle(POSTheme.muted)
            }
        }
    }

    private func overviewCard(_ lesson: POSLearningLesson) -> some View {
        POSCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Overview", systemImage: "book.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                Text(lesson.content)
                    .font(.body)
                    .foregroundStyle(POSTheme.ink)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func lessonCard(_ title: String, icon: String, body: String) -> some View {
        POSCard {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(POSTheme.ink)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func bulletCard(_ title: String, icon: String, items: [String]) -> some View {
        POSCard {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•").foregroundStyle(POSTheme.primaryDark)
                        Text(item).font(.subheadline).foregroundStyle(POSTheme.ink)
                    }
                }
            }
        }
    }

    private func codeCard(_ template: String) -> some View {
        POSCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Code template", systemImage: "chevron.left.forwardslash.chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                Text(template)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(POSTheme.ink)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(POSTheme.border.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func problemsCard(_ problems: [String], benchmarks: POSDSABenchmarks?) -> some View {
        POSCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Curated problems", systemImage: "list.number")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                if let benchmarks {
                    Text("Targets: Easy \(benchmarks.easyMinutes)m · Medium \(benchmarks.mediumMinutes)m · Hard \(benchmarks.hardMinutes)m")
                        .font(.caption2)
                        .foregroundStyle(POSTheme.muted)
                }
                FlowLayout(spacing: 8) {
                    ForEach(problems, id: \.self) { prob in
                        Text(prob)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(POSTheme.primary.opacity(0.1))
                            .foregroundStyle(POSTheme.primaryDark)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func modulesSection(_ modules: [POSLessonModule]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            POSSectionHeader(title: "Modules", eyebrow: "\(modules.count) lessons")
            ForEach(modules) { mod in
                Button {
                    onOpenModule(mod.id, mod.title)
                } label: {
                    HStack(spacing: 12) {
                        if mod.patternOrder > 0 {
                            Text("\(mod.patternOrder)")
                                .font(.caption.weight(.bold))
                                .frame(width: 28, height: 28)
                                .background(POSTheme.primary.opacity(0.12))
                                .clipShape(Circle())
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mod.title).font(.subheadline.weight(.medium))
                            if let sub = mod.subtitle {
                                Text(sub).font(.caption).foregroundStyle(POSTheme.muted).lineLimit(2)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(POSTheme.muted)
                    }
                    .padding(12)
                    .background(POSTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: POSTheme.cardRadius))
                    .overlay(RoundedRectangle(cornerRadius: POSTheme.cardRadius).stroke(POSTheme.border, lineWidth: 1))
                }
                .buttonStyle(POSPressButtonStyle())
            }
        }
    }

    private func practiceSection(_ lesson: POSLearningLesson) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            POSSectionHeader(title: "Quick practice", eyebrow: "Metro-friendly · long-term spaced reps")
            if isPracticing {
                POSLoadingView(label: "Running drill…")
            }
            if let practiceError {
                Text(practiceError).font(.caption).foregroundStyle(.red)
            }
            ForEach(lesson.practiceModes) { mode in
                Button {
                    Task { await runPractice(lesson: lesson, mode: mode) }
                } label: {
                    POSCard {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.title).font(.subheadline.weight(.semibold))
                                Text(mode.subtitle).font(.caption).foregroundStyle(POSTheme.muted)
                            }
                            Spacer()
                            Text("\(mode.durationMinutes)m")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(POSTheme.focus.opacity(0.15))
                                .clipShape(Capsule())
                            Image(systemName: mode.async ? "sparkles" : "bolt.fill")
                                .foregroundStyle(POSTheme.primaryDark)
                        }
                    }
                }
                .buttonStyle(POSPressButtonStyle())
                .disabled(isPracticing)
            }
        }
    }

    private func practiceResultCard(_ result: POSLearningCoachResult, label: String) -> some View {
        POSCard {
            VStack(alignment: .leading, spacing: 12) {
                Label(label, systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.success)
                if !result.summary.isEmpty {
                    Text(result.summary).font(.subheadline)
                }
                if !result.practiceQuestions.isEmpty {
                    Text("Practice").font(.caption.weight(.semibold)).foregroundStyle(POSTheme.muted)
                    ForEach(result.practiceQuestions.filter { !$0.isEmpty }, id: \.self) { q in
                        Text("• \(q)").font(.subheadline)
                    }
                }
                if !result.tips.isEmpty {
                    ForEach(result.tips.filter { !$0.isEmpty }, id: \.self) { tip in
                        Text("Tip: \(tip)").font(.caption).foregroundStyle(POSTheme.primaryDark)
                    }
                }
            }
        }
    }

    private func load() async {
        guard !Task.isCancelled else { return }
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            lesson = try await session.api.fetchLearningLesson(id: entityId)
        } catch {
            guard !POSLoadTask.isBenignCancellation(error) else { return }
            loadError = error.localizedDescription
        }
    }

    private func runPractice(lesson: POSLearningLesson, mode: POSPracticeMode) async {
        isPracticing = true
        practiceError = nil
        practiceResult = nil
        practiceLabel = mode.title
        defer { isPracticing = false }
        let track = lesson.track.isEmpty ? POSLearningTrack.dsa.rawValue : lesson.track
        do {
            if mode.async {
                let queued = try await session.api.coachLearningAsync(
                    entityID: lesson.entityID,
                    topic: lesson.title,
                    track: track,
                    focus: mode.focus
                )
                let done = try await session.api.pollStudyJob(id: queued.id)
                practiceResult = done.result
            } else {
                practiceResult = try await session.api.coachLearning(
                    entityID: lesson.entityID,
                    topic: lesson.title,
                    track: track,
                    focus: mode.focus
                )
            }
            POSHaptics.light()
        } catch {
            guard !POSLoadTask.isBenignCancellation(error) else { return }
            practiceError = error.localizedDescription
        }
    }
}

/// Simple horizontal flow for problem chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
