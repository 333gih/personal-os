import PhotosUI
import SwiftUI

struct POSWorkImportView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    var onImported: ((String, String) -> Void)?

    @State private var title = ""
    @State private var company = ""
    @State private var markdown = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var diagramData: Data?
    @State private var diagramPreview: UIImage?

    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var result: POSWorkImportResult?

    var body: some View {
        NavigationStack {
            POSScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        introCard
                        formFields
                        photoSection
                        if let result {
                            resultCard(result)
                        }
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 4)
                        }
                        importButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Import project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var introCard: some View {
        POSCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("AI system design intake", systemImage: "square.and.arrow.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                Text("Upload an architecture diagram and/or paste markdown notes. AI normalizes layers, stack, features, and skills into your Work domain.")
                    .font(.subheadline)
                    .foregroundStyle(POSTheme.muted)
            }
        }
    }

    private var formFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Project name (optional hint)", text: $title)
                .textFieldStyle(.roundedBorder)
            TextField("Company (optional)", text: $company)
                .textFieldStyle(.roundedBorder)
            VStack(alignment: .leading, spacing: 6) {
                Text("Markdown / notes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.muted)
                TextEditor(text: $markdown)
                    .frame(minHeight: 140)
                    .padding(8)
                    .background(POSTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(POSTheme.border, lineWidth: 1)
                    )
            }
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("System design image")
                .font(.caption.weight(.semibold))
                .foregroundStyle(POSTheme.muted)
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                POSCard {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text(diagramPreview == nil ? "Choose diagram" : "Change diagram")
                        Spacer()
                        if diagramPreview != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(POSTheme.success)
                        }
                    }
                    .font(.subheadline.weight(.medium))
                }
            }
            .onChange(of: selectedPhoto) { item in
                Task { await loadPhoto(item) }
            }
            if let diagramPreview {
                Image(uiImage: diagramPreview)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func resultCard(_ result: POSWorkImportResult) -> some View {
        POSCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Imported", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.success)
                Text(result.project.title)
                    .font(.headline)
                if !result.cvSkillsAdded.isEmpty {
                    Text("CV skills added: \(result.cvSkillsAdded.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(POSTheme.muted)
                }
                if !result.technologyIds.isEmpty {
                    Text("\(result.technologyIds.count) technologies linked")
                        .font(.caption)
                        .foregroundStyle(POSTheme.muted)
                }
                POSActionButton(title: "Open project", icon: "arrow.up.right", style: .primary) {
                    onImported?(result.projectId, result.project.title)
                    dismiss()
                }
            }
        }
    }

    private var importButton: some View {
        POSActionButton(
            title: isImporting ? "Analyzing…" : "Import with AI",
            icon: "sparkles",
            style: .primary
        ) {
            Task { await importProject() }
        }
        .disabled(isImporting || (markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && diagramData == nil))
        .opacity(isImporting ? 0.7 : 1)
        .overlay {
            if isImporting { ProgressView().tint(.white) }
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else {
            diagramData = nil
            diagramPreview = nil
            return
        }
        if let data = try? await item.loadTransferable(type: Data.self) {
            diagramData = data
            diagramPreview = UIImage(data: data)
        }
    }

    private func importProject() async {
        isImporting = true
        errorMessage = nil
        result = nil
        defer { isImporting = false }
        do {
            let out = try await session.api.importWorkProject(
                title: title,
                company: company,
                markdown: markdown,
                diagram: diagramData
            )
            result = out
            POSHaptics.medium()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
