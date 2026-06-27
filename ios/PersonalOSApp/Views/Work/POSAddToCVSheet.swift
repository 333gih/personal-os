import SwiftUI

struct POSAddToCVSheet: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    let entity: POSEntity
    let onAdded: (POSCVTemplate, POSCVValidateResult?) -> Void

    @State private var templates: [POSCVTemplate] = []
    @State private var selectedTemplateID: String?
    @State private var blockType: String
    @State private var stackText = ""
    @State private var skillsText = ""
    @State private var periodText = ""
    @State private var isLoading = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var lengthAlert: String?

    init(entity: POSEntity, onAdded: @escaping (POSCVTemplate, POSCVValidateResult?) -> Void) {
        self.entity = entity
        self.onAdded = onAdded
        if entity.type.contains("role") || entity.type.contains("employer") {
            _blockType = State(initialValue: "experience")
        } else {
            _blockType = State(initialValue: "project")
        }
        let parsed = Self.parseTechLine(entity.content)
        _stackText = State(initialValue: parsed.stack.joined(separator: ", "))
        _periodText = State(initialValue: entity.metadata?.periodLabel() ?? "")
    }

    var body: some View {
        NavigationStack {
            POSScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if isLoading {
                            POSLoadingView()
                        } else if let errorMessage {
                            POSEmptyState(
                                systemImage: "exclamationmark.triangle",
                                title: "Could not load templates",
                                message: errorMessage,
                                actionTitle: "Retry",
                                action: { Task { await loadTemplates() } }
                            )
                        } else if templates.isEmpty {
                            POSEmptyState(
                                systemImage: "doc.badge.plus",
                                title: "No CV templates",
                                message: "Open CV Transfer once while online to seed your default template.",
                                actionTitle: "Close",
                                action: { dismiss() }
                            )
                        } else {
                            sourceCard
                            templateSection
                            sectionTypePicker
                            fieldsCard
                            if let selected = selectedTemplate {
                                limitsHint(selected)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add to CV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "…" : "Add") {
                        Task { await submit() }
                    }
                    .disabled(isSubmitting || selectedTemplateID == nil || templates.isEmpty)
                }
            }
            .task { await loadTemplates() }
            .alert("CV length", isPresented: Binding(
                get: { lengthAlert != nil },
                set: { if !$0 { lengthAlert = nil } }
            )) {
                Button("OK", role: .cancel) { lengthAlert = nil }
            } message: {
                Text(lengthAlert ?? "")
            }
        }
    }

    private var selectedTemplate: POSCVTemplate? {
        templates.first { $0.id == selectedTemplateID }
    }

    private var sourceCard: some View {
        POSCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Work item")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                Text(cleanTitle(entity.title))
                    .font(.posDisplay(18))
                if !entity.content.isEmpty {
                    Text(Self.stripTechLine(entity.content))
                        .font(.subheadline)
                        .foregroundStyle(POSTheme.muted)
                        .lineLimit(6)
                }
                if !entity.tagList.isEmpty {
                    Text(entity.tagList.prefix(6).joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(POSTheme.primaryDark)
                }
            }
        }
    }

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            POSSectionHeader(title: "Target template", eyebrow: "System or your copy")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(templates) { tpl in
                        POSChip(
                            title: tpl.isSystem == true ? "★ \(tpl.name)" : tpl.name,
                            isSelected: selectedTemplateID == tpl.id
                        ) {
                            selectedTemplateID = tpl.id
                        }
                    }
                }
            }
        }
    }

    private var sectionTypePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            POSSectionHeader(title: "Section", eyebrow: "Where this block lands")
            HStack(spacing: 8) {
                POSChip(title: "Project", isSelected: blockType == "project") { blockType = "project" }
                POSChip(title: "Experience", isSelected: blockType == "experience") { blockType = "experience" }
            }
        }
    }

    private var fieldsCard: some View {
        POSCard {
            VStack(alignment: .leading, spacing: 12) {
                fieldLabel("Period")
                TextField("2025 — Present", text: $periodText)
                    .textFieldStyle(.roundedBorder)
                fieldLabel("Highlight stack (optional)")
                TextField("Java, Spring Boot, Kafka", text: $stackText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                fieldLabel("Extra skills for this block (optional)")
                TextField("JUnit, Docker, Redis", text: $skillsText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Text("Title and description come from the work item. Skills are free-form tags for this block.")
                    .font(.caption2)
                    .foregroundStyle(POSTheme.muted)
            }
        }
    }

    private func limitsHint(_ tpl: POSCVTemplate) -> some View {
        POSCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("Template limits")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.muted)
                Text("\(tpl.constraints.maxPages) page max · \(tpl.constraints.maxExperience) roles · \(tpl.constraints.maxProjects) projects")
                    .font(.caption)
                if tpl.isSystem == true {
                    Text("Adding to a system template creates your editable copy automatically.")
                        .font(.caption2)
                        .foregroundStyle(POSTheme.primaryDark)
                }
            }
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(POSTheme.primaryDark)
    }

    @MainActor
    private func loadTemplates() async {
        isLoading = true
        errorMessage = nil
        do {
            templates = try await session.api.listCVTemplates()
            selectedTemplateID = templates.first(where: { $0.isDefault })?.id ?? templates.first?.id
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    @MainActor
    private func submit() async {
        guard let templateID = selectedTemplateID else { return }
        isSubmitting = true
        errorMessage = nil
        let stack = splitCSV(stackText)
        let skillItems = splitCSV(skillsText)
        let period = periodText.trimmingCharacters(in: .whitespacesAndNewlines)
        let overrides = POSCVBlockOverrides(
            title: cleanTitle(entity.title),
            company: entity.metadata?.company,
            period: period.isEmpty ? nil : period,
            highlightStack: stack.isEmpty ? nil : stack,
            skillItems: skillItems.isEmpty ? nil : skillItems
        )
        do {
            let tpl = try await session.api.addCVBlockFromEntity(
                templateID: templateID,
                entityID: entity.id,
                blockType: blockType,
                overrides: overrides
            )
            let validation = try? await session.api.validateCVTemplate(id: tpl.id, template: tpl)
            if let validation, !validation.valid {
                lengthAlert = (validation.overflows ?? []).joined(separator: "\n")
            }
            onAdded(tpl, validation)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    private func cleanTitle(_ title: String) -> String {
        title
            .replacingOccurrences(of: "CV: ", with: "")
            .replacingOccurrences(of: "Add to CV: ", with: "")
    }

    private func splitCSV(_ text: String) -> [String] {
        text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private static func parseTechLine(_ content: String) -> (stack: [String], body: String) {
        guard let range = content.range(of: #"(?i)Tech:\s*(.+)"#, options: .regularExpression) else {
            return ([], content)
        }
        let line = String(content[range])
        let techPart = line.replacingOccurrences(of: #"^(?i)Tech:\s*"#, with: "", options: .regularExpression)
        let stack = techPart.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return (stack, stripTechLine(content))
    }

    private static func stripTechLine(_ content: String) -> String {
        content.replacingOccurrences(of: #"(?m)^\s*Tech:.*$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
