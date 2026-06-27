import SwiftUI

struct POSCVHubView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    var initialTemplateID: String? = nil

    @State private var templates: [POSCVTemplate] = []
    @State private var selectedID: String?
    @State private var template: POSCVTemplate?
    @State private var validate: POSCVValidateResult?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var saveError: String?
    @State private var showCreate = false
    @State private var newTemplateName = ""
    @State private var refiningBlock: POSCVBlock?
    @State private var refineDraft = ""
    @State private var refineInstruction = ""
    @State private var isRefining = false
    @State private var isSaving = false
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var sharePDFData: Data?
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack {
            POSScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if isLoading && template == nil {
                            POSLoadingView()
                        } else if let loadError {
                            POSEmptyState(
                                systemImage: "doc.text",
                                title: "Could not load CV templates",
                                message: loadError,
                                actionTitle: "Retry",
                                action: { Task { await reloadTemplates() } }
                            )
                        } else {
                            templatePicker
                            if let validate { validateBanner(validate) }
                            if let saveError {
                                Text(saveError).font(.caption).foregroundStyle(POSTheme.error)
                            }
                            if let template { templateContent(template) }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("CV Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if template != nil { bottomBar }
            }
            .task { await reloadTemplates() }
            .sheet(isPresented: $showShareSheet) {
                if let sharePDFData {
                    POSActivityShareSheet(items: [sharePDFData, "My CV.pdf"])
                }
            }
            .alert("New template", isPresented: $showCreate) {
                TextField("Name", text: $newTemplateName)
                Button("Create") { Task { await createTemplate() } }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $refiningBlock) { block in
                refineSheet(block)
            }
            .alert("CV Transfer", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button("OK", role: .cancel) { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private var templatePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(templates) { tpl in
                    Button {
                        Task { await loadTemplate(id: tpl.id) }
                    } label: {
                        Text(tpl.name)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedID == tpl.id ? POSTheme.primaryDark : POSTheme.border.opacity(0.35))
                            .foregroundStyle(selectedID == tpl.id ? .white : POSTheme.ink)
                            .clipShape(Capsule())
                    }
                }
                Button { showCreate = true } label: {
                    Label("New", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(POSTheme.border.opacity(0.35))
                        .clipShape(Capsule())
                }
            }
        }
    }

    @ViewBuilder
    private func validateBanner(_ result: POSCVValidateResult) -> some View {
        POSCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(result.valid ? "Fits \(result.maxPages) page(s)" : "Overflow · \(result.pageCount)/\(result.maxPages) pages")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(result.valid ? POSTheme.success : POSTheme.error)
                ForEach(result.overflows ?? [], id: \.self) { Text("• \($0)").font(.caption2) }
                ForEach(result.suggestions ?? [], id: \.self) { Text("→ \($0)").font(.caption2).foregroundStyle(POSTheme.muted) }
            }
        }
    }

    @ViewBuilder
    private func templateContent(_ tpl: POSCVTemplate) -> some View {
        POSCard {
            Text("Layout: \(tpl.layoutID)")
                .font(.caption)
                .foregroundStyle(POSTheme.muted)
            Text("\(tpl.blocks.filter(\.enabled).count) active blocks")
                .font(.caption)
        }
        ForEach(Array(tpl.blocks.sorted { $0.order < $1.order }.enumerated()), id: \.element.id) { index, block in
            blockCard(block, index: index, in: tpl)
        }
    }

    private func blockCard(_ block: POSCVBlock, index: Int, in tpl: POSCVTemplate) -> some View {
        POSCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(block.overrides?.title?.isEmpty == false ? block.overrides!.title! : block.type.capitalized)
                        .font(.subheadline.weight(.semibold))
                    Text(block.type).font(.caption2).foregroundStyle(POSTheme.muted)
                }
                Spacer()
                Toggle("", isOn: bindingEnabled(blockID: block.id))
                    .labelsHidden()
            }
            if let company = block.overrides?.company, !company.isEmpty {
                Text(company).font(.caption).foregroundStyle(POSTheme.muted)
            }
            if let content = block.content, !content.isEmpty {
                Text(content).font(.caption).lineLimit(4)
            }
            if let stack = block.overrides?.highlightStack, !stack.isEmpty {
                Text("Stack: \(stack.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundStyle(POSTheme.primaryDark)
            }
            HStack(spacing: 8) {
                Button("Edit + refine") { refiningBlock = block; refineDraft = block.content ?? "" }
                    .font(.caption.weight(.semibold))
                if index > 0 {
                    Button("Up") { moveBlock(block.id, direction: -1) }.font(.caption)
                }
                if index < tpl.blocks.count - 1 {
                    Button("Down") { moveBlock(block.id, direction: 1) }.font(.caption)
                }
            }
            .padding(.top, 6)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 8) {
            POSActionButton(title: isSaving ? "…" : "Save", style: .primary) {
                Task { await save() }
            }
            POSActionButton(title: "Validate", style: .secondary) {
                guard let template else { return }
                Task { await runValidate(template) }
            }
            POSActionButton(title: isExporting ? "…" : "PDF", style: .secondary) {
                Task { await exportPDF() }
            }
            POSActionButton(title: "Share", style: .secondary) {
                Task { await share() }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(POSTheme.background)
    }

    private func refineSheet(_ block: POSCVBlock) -> some View {
        NavigationStack {
            Form {
                Section("Content") {
                    TextEditor(text: $refineDraft).frame(minHeight: 120)
                }
                Section("Instruction") {
                    TextField("Optional", text: $refineInstruction, axis: .vertical)
                }
            }
            .navigationTitle("AI refine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { refiningBlock = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isRefining ? "…" : "Apply") {
                        Task { await applyRefine(blockID: block.id) }
                    }
                    .disabled(isRefining)
                }
            }
        }
    }

    private func bindingEnabled(blockID: String) -> Binding<Bool> {
        Binding(
            get: { template?.blocks.first { $0.id == blockID }?.enabled ?? true },
            set: { enabled in
                guard var tpl = template else { return }
                tpl.blocks = tpl.blocks.map { $0.id == blockID ? POSCVBlock(
                    id: $0.id, type: $0.type, order: $0.order, enabled: enabled,
                    sourceEntityID: $0.sourceEntityID, content: $0.content, overrides: $0.overrides,
                    aiRefinedAt: $0.aiRefinedAt, pendingRaw: $0.pendingRaw, skillGroups: $0.skillGroups
                ) : $0 }
                template = tpl
            }
        )
    }

    private func moveBlock(_ blockID: String, direction: Int) {
        guard var tpl = template else { return }
        var sorted = tpl.blocks.sorted { $0.order < $1.order }
        guard let i = sorted.firstIndex(where: { $0.id == blockID }) else { return }
        let j = i + direction
        guard sorted.indices.contains(j) else { return }
        let a = sorted[i].order
        sorted[i].order = sorted[j].order
        sorted[j].order = a
        tpl.blocks = sorted
        template = tpl
    }

    @MainActor
    private func reloadTemplates() async {
        isLoading = true
        loadError = nil
        do {
            templates = try await session.api.listCVTemplates()
            let pick = initialTemplateID ?? selectedID ?? templates.first?.id
            if let pick { await loadTemplate(id: pick) }
            isLoading = false
        } catch {
            loadError = error.localizedDescription
            isLoading = false
        }
    }

    @MainActor
    private func loadTemplate(id: String) async {
        isLoading = true
        do {
            template = try await session.api.getCVTemplate(id: id)
            selectedID = id
            isLoading = false
            if let template { await runValidate(template) }
        } catch {
            loadError = error.localizedDescription
            isLoading = false
        }
    }

    @MainActor
    private func runValidate(_ tpl: POSCVTemplate) async {
        validate = try? await session.api.validateCVTemplate(id: tpl.id, template: tpl)
    }

    @MainActor
    private func save() async {
        guard let template else { return }
        isSaving = true
        saveError = nil
        do {
            self.template = try await session.api.saveCVTemplate(template)
            if let tpl = self.template { await runValidate(tpl) }
        } catch {
            saveError = error.localizedDescription
        }
        isSaving = false
    }

    @MainActor
    private func createTemplate() async {
        let name = newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            let created = try await session.api.createCVTemplate(name: name, cloneID: selectedID ?? "")
            newTemplateName = ""
            await reloadTemplates()
            await loadTemplate(id: created.id)
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    @MainActor
    private func applyRefine(blockID: String) async {
        isRefining = true
        defer { isRefining = false }
        do {
            let instruction = refineInstruction.isEmpty
                ? "Professional tone, ATS-friendly, fix grammar, keep facts"
                : refineInstruction
            let res = try await session.api.refineCVBlock(content: refineDraft, instruction: instruction)
            let refined = res.refinedContent?.isEmpty == false ? res.refinedContent! : refineDraft
            template = template.map { tpl in
                var copy = tpl
                copy.blocks = tpl.blocks.map { $0.id == blockID ? POSCVBlock(
                    id: $0.id, type: $0.type, order: $0.order, enabled: $0.enabled,
                    sourceEntityID: $0.sourceEntityID, content: refined, overrides: $0.overrides,
                    aiRefinedAt: $0.aiRefinedAt, pendingRaw: nil, skillGroups: $0.skillGroups
                ) : $0 }
                return copy
            }
            refiningBlock = nil
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    @MainActor
    private func exportPDF() async {
        guard let template else { return }
        isExporting = true
        defer { isExporting = false }
        do {
            sharePDFData = try await session.api.downloadCVPDF(templateID: template.id)
            showShareSheet = true
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    @MainActor
    private func share() async {
        do {
            let resp = try await session.api.shareCV()
            if let url = URL(string: resp.url) {
                await UIApplication.shared.open(url)
            }
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}