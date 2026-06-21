import SwiftUI

struct POSLearningHubMenu: View {
    @Environment(\.dismiss) private var dismiss
    let onAddEntry: () -> Void
    let onCoach: () -> Void
    let onOpenBoard: () -> Void
    let onCapture: () -> Void

    var body: some View {
        NavigationStack {
            POSScreen {
                ScrollView {
                    VStack(spacing: 10) {
                        Text("DSA mastery + English courses — AI normalizes notes and generates practice drills.")
                            .font(.caption)
                            .foregroundStyle(POSTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        menuRow("Add study entry (AI)", icon: "plus.circle.fill", subtitle: "Course, pattern, vocabulary note") {
                            dismiss(); onAddEntry()
                        }
                        menuRow("AI study coach", icon: "sparkles", subtitle: "Practice questions & tips for a topic") {
                            dismiss(); onCoach()
                        }
                        menuRow("Open learning board", icon: "books.vertical.fill", subtitle: "Full list in web planner") {
                            dismiss(); onOpenBoard()
                        }
                        menuRow("Quick capture", icon: "square.and.pencil", subtitle: "Send raw note to inbox") {
                            dismiss(); onCapture()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Learning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }

    private func menuRow(_ title: String, icon: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            POSCard {
                HStack(spacing: 14) {
                    Image(systemName: icon).font(.title3).foregroundStyle(POSTheme.primaryDark).frame(width: 32)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(POSTheme.ink)
                        Text(subtitle).font(.caption).foregroundStyle(POSTheme.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(POSTheme.muted)
                }
            }
        }
        .buttonStyle(POSPressButtonStyle())
    }
}

struct POSLearningAddView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    let track: POSLearningTrack
    let onCreated: (String, String) -> Void

    @State private var kind = "topic"
    @State private var titleHint = ""
    @State private var rawText = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let kinds: [(String, String)] = [
        ("course", "Course"), ("topic", "Topic / Module"), ("skill", "Skill"), ("note", "Note")
    ]

    var body: some View {
        NavigationStack {
            POSScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Describe what you're studying — AI formats it for your \(track.title) shelf.")
                            .font(.caption).foregroundStyle(POSTheme.muted)
                        Picker("Type", selection: $kind) {
                            ForEach(kinds, id: \.0) { value, label in Text(label).tag(value) }
                        }
                        .pickerStyle(.segmented)
                        TextField("Title hint", text: $titleHint).textFieldStyle(.roundedBorder)
                        TextField("Notes…", text: $rawText, axis: .vertical).lineLimit(5...12)
                        if let errorMessage { Text(errorMessage).font(.caption).foregroundStyle(.red) }
                        POSActionButton(title: isSaving ? "Saving…" : "Add & normalize", icon: "sparkles", style: .primary) {
                            Task { await submit() }
                        }
                        .disabled(isSaving || rawText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add Study")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }

    private func submit() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            let result = try await session.api.addLearningEntry(kind: kind, track: track.rawValue, rawText: rawText, titleHint: titleHint)
            POSHaptics.medium()
            onCreated(result.entityID, result.title)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct POSLearningCoachView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    let track: POSLearningTrack
    var entityID: String?
    var initialTopic: String = ""

    @State private var focus = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var result: POSLearningCoachResult?

    var body: some View {
        NavigationStack {
            POSScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI generates practice questions and study tips based on your curriculum.")
                            .font(.caption).foregroundStyle(POSTheme.muted)
                        TextField("Focus (optional)", text: $focus).textFieldStyle(.roundedBorder)
                        POSActionButton(title: isLoading ? "Thinking…" : "Generate drill", icon: "wand.and.stars", style: .primary) {
                            Task { await run() }
                        }
                        .disabled(isLoading)
                        if let errorMessage { Text(errorMessage).font(.caption).foregroundStyle(.red) }
                        if let result {
                            coachSection("Summary", items: [result.summary])
                            coachSection("Practice questions", items: result.practiceQuestions)
                            coachSection("Tips", items: result.tips)
                            coachSection("Next steps", items: result.nextSteps)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Study Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .task {
                if entityID != nil || !initialTopic.isEmpty {
                    await run()
                }
            }
        }
    }

    private func coachSection(_ title: String, items: [String]) -> some View {
        POSCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(POSTheme.primaryDark)
                ForEach(items.filter { !$0.isEmpty }, id: \.self) { item in
                    Text("• \(item)").font(.subheadline).foregroundStyle(POSTheme.ink)
                }
            }
        }
    }

    private func run() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            result = try await session.api.coachLearning(
                entityID: entityID,
                topic: initialTopic,
                track: track.rawValue,
                focus: focus
            )
            POSHaptics.light()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct POSInterviewPrepView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var topics: [POSEntity] = []
    @State private var isLoadingTopics = true
    @State private var stack = "Java, Spring Boot, PostgreSQL, Kafka, Redis"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var drill: POSInterviewDrillResult?

    var body: some View {
        NavigationStack {
            POSScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notebook for interview — AI drills from GeeksforGeeks, Baeldung, and your stack.")
                            .font(.caption).foregroundStyle(POSTheme.muted)

                        if isLoadingTopics {
                            POSLoadingView()
                        } else if topics.isEmpty {
                            POSEmptyState(
                                systemImage: "person.fill.questionmark",
                                title: "No interview topics",
                                message: "Run migration 020 on server to seed interview notebook.",
                                actionTitle: "Close",
                                action: { dismiss() }
                            )
                        } else {
                            ForEach(topics) { topic in
                                Button {
                                    drill = nil
                                    Task { await runDrill(for: topic) }
                                } label: {
                                    POSListRow(
                                        title: topic.title,
                                        subtitle: topic.metadata?.referenceUrls?.first ?? "Tap for AI drill",
                                        systemImage: "person.fill.questionmark",
                                        iconTint: POSTheme.primaryDark
                                    )
                                }
                                .buttonStyle(POSPressButtonStyle())
                            }
                        }

                        if isLoading { POSLoadingView(label: "Building interview drill…") }
                        if let errorMessage { Text(errorMessage).font(.caption).foregroundStyle(.red) }

                        if let drill {
                            drillBlock("Warm-up", items: drill.warmupQuestions)
                            drillBlock("Deep dive", items: drill.deepQuestions)
                            drillBlock("Answer outline", items: drill.modelAnswersOutline)
                            drillBlock("Follow-up probes", items: drill.followUpProbes)
                            if !drill.studyLinks.isEmpty {
                                drillBlock("Extra study", items: drill.studyLinks)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Interview Prep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .task { await loadTopics() }
        }
    }

    private func drillBlock(_ title: String, items: [String]) -> some View {
        POSCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(POSTheme.primaryDark)
                ForEach(items.filter { !$0.isEmpty }, id: \.self) { item in
                    Text("• \(item)").font(.subheadline)
                }
            }
        }
    }

    private func runDrill(for topic: POSEntity) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            drill = try await session.api.interviewDrill(entityID: topic.id, topic: topic.title, stack: stack)
            POSHaptics.light()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadTopics() async {
        isLoadingTopics = true
        defer { isLoadingTopics = false }
        do {
            let items = try await session.api.listEntities(domain: "work").items
            topics = items.filter { $0.type.contains("interview") }
        } catch {
            topics = []
        }
    }
}
