import SwiftUI

struct POSAddToCVSheet: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    let entity: POSEntity
    let onAdded: (POSCVTemplate) -> Void

    @State private var templates: [POSCVTemplate] = []
    @State private var selectedTemplateID: String?
    @State private var blockType: String
    @State private var stackText = ""
    @State private var isLoading = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    init(entity: POSEntity, onAdded: @escaping (POSCVTemplate) -> Void) {
        self.entity = entity
        self.onAdded = onAdded
        if entity.type.contains("role") || entity.type.contains("employer") {
            _blockType = State(initialValue: "experience")
        } else {
            _blockType = State(initialValue: "project")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(entity.title).font(.subheadline)
                } header: {
                    Text("Work item")
                }
                if isLoading {
                    ProgressView()
                } else if let errorMessage {
                    Text(errorMessage).foregroundStyle(POSTheme.error)
                } else {
                    Section("Template") {
                        Picker("Template", selection: $selectedTemplateID) {
                            ForEach(templates) { tpl in
                                Text(tpl.name).tag(Optional(tpl.id))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    Section("Section") {
                        Picker("Type", selection: $blockType) {
                            Text("Project").tag("project")
                            Text("Experience").tag("experience")
                        }
                        .pickerStyle(.segmented)
                    }
                    Section("Highlight stack") {
                        TextField("Java, Spring Boot, Kafka", text: $stackText, axis: .vertical)
                    }
                }
            }
            .navigationTitle("Add to CV")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "…" : "Add") {
                        Task { await submit() }
                    }
                    .disabled(isSubmitting || selectedTemplateID == nil)
                }
            }
            .task { await loadTemplates() }
        }
    }

    @MainActor
    private func loadTemplates() async {
        do {
            templates = try await session.api.listCVTemplates()
            selectedTemplateID = templates.first?.id
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
        let stack = stackText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let overrides = POSCVBlockOverrides(
            title: entity.title,
            company: entity.metadata?.company,
            period: nil,
            highlightStack: stack.isEmpty ? nil : stack,
            skillItems: nil
        )
        do {
            let tpl = try await session.api.addCVBlockFromEntity(
                templateID: templateID,
                entityID: entity.id,
                blockType: blockType,
                overrides: overrides
            )
            onAdded(tpl)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
