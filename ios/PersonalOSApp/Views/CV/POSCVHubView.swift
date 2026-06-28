import SwiftUI
import UIKit

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
    @State private var contactEmailDraft = ""
    @State private var contactPhoneDraft = ""
    @State private var contactLocationDraft = ""
    @State private var contactLinkedInDraft = ""
    @State private var contactGitHubDraft = ""
    @State private var isRefining = false
    @State private var isSaving = false
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var sharePDFData: Data?
    @State private var alertMessage: String?
    @State private var forkNotice: String?

    private let sectionMeta: [(type: String, title: String, eyebrow: String)] = [
        ("summary", "Profile", "Headline & summary"),
        ("contact", "Contact", "Reach you"),
        ("skills", "Skills & stack", "Primary focus"),
        ("achievements", "Highlights", "Key wins"),
        ("education", "Education", "Degrees & schools"),
        ("certificates", "Certificates", "Credentials"),
        ("experience", "Experience", "Roles"),
        ("project", "Projects", "Featured work"),
    ]

    var body: some View {
        NavigationStack {
            POSScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
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
                            heroHeader
                            templatePicker
                            if let validate { validateBanner(validate) }
                            if let forkNotice {
                                POSCard {
                                    Label(forkNotice, systemImage: "doc.on.doc")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(POSTheme.primaryDark)
                                }
                            }
                            if let saveError {
                                Text(saveError).font(.caption).foregroundStyle(POSTheme.error)
                            }
                            if let template {
                                constraintsCard(template)
                                templateSections(template)
                            } else if !isLoading {
                                POSEmptyState(
                                    systemImage: "doc.badge.plus",
                                    title: "No CV template yet",
                                    message: "Create a template or wait for the server to seed your default CV.",
                                    actionTitle: "Create template",
                                    action: { showCreate = true }
                                )
                            }
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

    private var heroHeader: some View {
        POSCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("CV Transfer")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                Text(template?.name ?? "Your resume workspace")
                    .font(.posDisplay(22))
                    .foregroundStyle(POSTheme.ink)
                Text("System templates stay as recommendations. Edits save as your own copy with length checks.")
                    .font(.subheadline)
                    .foregroundStyle(POSTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var templatePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            POSSectionHeader(title: "Templates", eyebrow: "Default · AI · yours")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(templates) { tpl in
                        POSChip(title: chipLabel(tpl), isSelected: selectedID == tpl.id) {
                            Task { await loadTemplate(id: tpl.id) }
                        }
                    }
                    POSChip(title: "+ New", isSelected: false) { showCreate = true }
                }
            }
        }
    }

    private func chipLabel(_ tpl: POSCVTemplate) -> String {
        if tpl.isSystem == true { return "★ \(tpl.name)" }
        return tpl.name
    }

    @ViewBuilder
    private func validateBanner(_ result: POSCVValidateResult) -> some View {
        let nearOverflow = !result.valid && result.pageCount <= result.maxPages + 1
        POSCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(bannerTitle(result))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(bannerColor(result, nearOverflow: nearOverflow))
                if let template {
                    Text("Limits: \(template.constraints.maxPages) page · max \(template.constraints.maxExperience) roles · max \(template.constraints.maxProjects) projects")
                        .font(.caption2)
                        .foregroundStyle(POSTheme.muted)
                }
                ForEach(result.overflows ?? [], id: \.self) { Text("• \($0)").font(.caption2) }
                ForEach(result.suggestions ?? [], id: \.self) { Text("→ \($0)").font(.caption2).foregroundStyle(POSTheme.muted) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
            .background(bannerBackground(result, nearOverflow: nearOverflow).opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func bannerTitle(_ result: POSCVValidateResult) -> String {
        if result.valid {
            return "Fits \(result.maxPages) page(s) · \(result.pageCount) page PDF"
        }
        return "Overflow · \(result.pageCount)/\(result.maxPages) pages"
    }

    private func bannerColor(_ result: POSCVValidateResult, nearOverflow: Bool) -> Color {
        if result.valid { return POSTheme.success }
        if nearOverflow { return POSTheme.primaryDark }
        return POSTheme.error
    }

    private func bannerBackground(_ result: POSCVValidateResult, nearOverflow: Bool) -> Color {
        if result.valid { return POSTheme.success }
        if nearOverflow { return POSTheme.border }
        return POSTheme.error
    }

    private func constraintsCard(_ tpl: POSCVTemplate) -> some View {
        POSCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tpl.layoutID.replacingOccurrences(of: "_", with: " "))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(POSTheme.muted)
                    Text("\(tpl.blocks.filter(\.enabled).count) active blocks")
                        .font(.subheadline.weight(.medium))
                }
                Spacer()
                if tpl.isSystem == true {
                    Text("System")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(POSTheme.primaryDark.opacity(0.12))
                        .foregroundStyle(POSTheme.primaryDark)
                        .clipShape(Capsule())
                }
            }
        }
    }

    @ViewBuilder
    private func templateSections(_ tpl: POSCVTemplate) -> some View {
        let grouped = groupBlocks(tpl.blocks)
        ForEach(sectionMeta, id: \.type) { meta in
            if let blocks = grouped[meta.type], !blocks.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    POSSectionHeader(title: meta.title, eyebrow: meta.eyebrow)
                    ForEach(Array(blocks.enumerated()), id: \.element.id) { index, block in
                        blockCard(block, index: index, in: tpl, sectionBlocks: blocks)
                    }
                }
            }
        }
    }

    private func groupBlocks(_ blocks: [POSCVBlock]) -> [String: [POSCVBlock]] {
        var out: [String: [POSCVBlock]] = [:]
        for block in blocks.sorted(by: { $0.order < $1.order }) {
            out[block.type, default: []].append(block)
        }
        return out
    }

    private func blockCard(_ block: POSCVBlock, index: Int, in tpl: POSCVTemplate, sectionBlocks: [POSCVBlock]) -> some View {
        POSCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(blockTitle(block))
                        .font(.subheadline.weight(.semibold))
                    if let period = block.overrides?.period, !period.isEmpty {
                        Text(period).font(.caption).foregroundStyle(POSTheme.muted)
                    }
                }
                Spacer()
                Toggle("", isOn: bindingEnabled(blockID: block.id))
                    .labelsHidden()
            }
            if let company = block.overrides?.company, !company.isEmpty {
                Text(company).font(.caption).foregroundStyle(POSTheme.muted)
            }
            if block.type == "skills", let groups = block.skillGroups, !groups.isEmpty {
                skillsBlockBody(groups: groups, focus: block.overrides?.skillItems)
            } else if block.type == "contact" {
                contactBlockBody(block)
            } else if let content = block.content, !content.isEmpty {
                Text(content)
                    .font(.caption)
                    .foregroundStyle(POSTheme.ink.opacity(0.9))
                    .lineLimit(block.type == "summary" ? 8 : 5)
                    .padding(.top, 4)
            }
            if let stack = block.overrides?.highlightStack, !stack.isEmpty {
                skillChips(stack)
                    .padding(.top, 6)
            }
            if let extra = block.overrides?.skillItems, !extra.isEmpty, block.type != "skills" {
                skillChips(extra)
                    .padding(.top, 4)
            }
            HStack(spacing: 8) {
                Button {
                    POSHaptics.light()
                    refiningBlock = block
                    if block.type == "contact" {
                        contactEmailDraft = block.overrides?.email ?? ""
                        contactPhoneDraft = block.overrides?.phone ?? ""
                        contactLocationDraft = block.overrides?.location ?? ""
                        contactLinkedInDraft = block.overrides?.linkedin ?? ""
                        contactGitHubDraft = block.overrides?.github ?? ""
                    } else {
                        refineDraft = block.content ?? ""
                    }
                    refineInstruction = ""
                } label: {
                    Text(block.type == "contact" ? "Edit" : "Edit + refine")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(POSTheme.primaryDark)
                }
                .buttonStyle(POSPressButtonStyle())
                if let globalIndex = tpl.blocks.sorted(by: { $0.order < $1.order }).firstIndex(where: { $0.id == block.id }), globalIndex > 0 {
                    Button {
                        POSHaptics.selection()
                        moveBlock(block.id, direction: -1)
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(POSPressButtonStyle())
                }
                if let globalIndex = tpl.blocks.sorted(by: { $0.order < $1.order }).firstIndex(where: { $0.id == block.id }),
                   globalIndex < tpl.blocks.count - 1 {
                    Button {
                        POSHaptics.selection()
                        moveBlock(block.id, direction: 1)
                    } label: {
                        Image(systemName: "arrow.down")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(POSPressButtonStyle())
                }
            }
            .padding(.top, 8)
        }
        .opacity(block.enabled ? 1 : 0.55)
    }

    private func blockTitle(_ block: POSCVBlock) -> String {
        if block.type == "contact" { return "Contact" }
        if block.type == "summary" { return "Profile" }
        if let title = block.overrides?.title, !title.isEmpty { return title }
        return block.type.capitalized
    }

    @ViewBuilder
    private func contactBlockBody(_ block: POSCVBlock) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let email = block.overrides?.email, !email.isEmpty {
                contactLine("Email", email)
            }
            if let phone = block.overrides?.phone, !phone.isEmpty {
                contactLine("Phone", phone)
            }
            if let location = block.overrides?.location, !location.isEmpty {
                contactLine("Location", location)
            }
            if let linkedin = block.overrides?.linkedin, !linkedin.isEmpty {
                contactLine("LinkedIn", linkedin)
            }
            if let github = block.overrides?.github, !github.isEmpty {
                contactLine("GitHub", github)
            }
            if block.overrides == nil, let content = block.content, !content.isEmpty {
                Text(content)
                    .font(.caption)
                    .foregroundStyle(POSTheme.ink.opacity(0.9))
            }
        }
        .padding(.top, 4)
    }

    private func contactLine(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(label + ":")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(POSTheme.muted)
                .frame(width: 58, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(POSTheme.ink.opacity(0.9))
        }
    }

    @ViewBuilder
    private func skillsBlockBody(groups: [POSCVSkillGroup], focus: [String]?) -> some View {
        if let focus, !focus.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Primary focus")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                skillChips(focus)
            }
            .padding(.top, 4)
        }
        ForEach(groups) { group in
            VStack(alignment: .leading, spacing: 6) {
                Text(group.category)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.muted)
                skillChips(group.items)
            }
            .padding(.top, 6)
        }
    }

    private func skillChips(_ items: [String]) -> some View {
        FlowLayout(spacing: 6) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(POSTheme.border.opacity(0.35))
                    .clipShape(Capsule())
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 8) {
            if template?.isSystem == true {
                Text("Saving creates “My CV” — system template stays unchanged")
                    .font(.caption2)
                    .foregroundStyle(POSTheme.muted)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            POSActionButton(title: isSaving ? "…" : saveButtonTitle, style: .primary) {
                Task { await save() }
            }
            HStack(spacing: 8) {
                bottomToolButton(title: "Validate", icon: "checkmark.circle") {
                    guard let template else { return }
                    Task { await runValidate(template) }
                }
                bottomToolButton(title: isExporting ? "…" : "PDF", icon: "doc.richtext") {
                    Task { await exportPDF() }
                }
                bottomToolButton(title: "Share", icon: "square.and.arrow.up") {
                    Task { await share() }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(POSTheme.background)
    }

    private func bottomToolButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            POSHaptics.light()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(POSTheme.card)
            .foregroundStyle(POSTheme.ink)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(POSTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(POSPressButtonStyle())
    }

    private var saveButtonTitle: String {
        template?.isSystem == true ? "Save as My CV" : "Save"
    }

    private func refineSheet(_ block: POSCVBlock) -> some View {
        NavigationStack {
            POSScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if block.type == "contact" {
                            POSCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    contactField("Email", text: $contactEmailDraft)
                                    contactField("Phone", text: $contactPhoneDraft)
                                    contactField("Location", text: $contactLocationDraft)
                                    contactField("LinkedIn", text: $contactLinkedInDraft)
                                    contactField("GitHub", text: $contactGitHubDraft)
                                }
                            }
                        } else {
                            POSCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Content")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(POSTheme.primaryDark)
                                    TextEditor(text: $refineDraft)
                                        .frame(minHeight: 140)
                                        .font(.subheadline)
                                }
                            }
                            POSCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Instruction (optional)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(POSTheme.primaryDark)
                                    TextField("Professional tone, ATS-friendly…", text: $refineInstruction, axis: .vertical)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(block.type == "contact" ? "Edit contact" : "AI refine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { refiningBlock = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isRefining ? "…" : "Apply") {
                        Task {
                            if block.type == "contact" {
                                applyContactEdit(blockID: block.id)
                            } else {
                                await applyRefine(blockID: block.id)
                            }
                        }
                    }
                    .disabled(isRefining)
                }
            }
        }
    }

    private func contactField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(POSTheme.primaryDark)
            TextField(label, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }

    private func buildContactContent(email: String, phone: String, location: String, linkedin: String, github: String) -> String {
        [email, phone, location, linkedin, github]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    private func applyContactEdit(blockID: String) {
        let overrides = POSCVBlockOverrides(
            email: contactEmailDraft.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: contactPhoneDraft.trimmingCharacters(in: .whitespacesAndNewlines),
            location: contactLocationDraft.trimmingCharacters(in: .whitespacesAndNewlines),
            linkedin: contactLinkedInDraft.trimmingCharacters(in: .whitespacesAndNewlines),
            github: contactGitHubDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        let content = buildContactContent(
            email: overrides.email ?? "",
            phone: overrides.phone ?? "",
            location: overrides.location ?? "",
            linkedin: overrides.linkedin ?? "",
            github: overrides.github ?? ""
        )
        template = template.map { tpl in
            var copy = tpl
            copy.blocks = tpl.blocks.map { block in
                guard block.id == blockID else { return block }
                return POSCVBlock(
                    id: block.id, type: block.type, order: block.order, enabled: block.enabled,
                    sourceEntityID: block.sourceEntityID, content: content, overrides: overrides,
                    aiRefinedAt: block.aiRefinedAt, pendingRaw: nil, skillGroups: block.skillGroups
                )
            }
            return copy
        }
        refiningBlock = nil
    }

    private func bindingEnabled(blockID: String) -> Binding<Bool> {
        Binding(
            get: { template?.blocks.first { $0.id == blockID }?.enabled ?? true },
            set: { enabled in
                guard var tpl = template else { return }
                tpl.blocks = tpl.blocks.map { block in
                    guard block.id == blockID else { return block }
                    return POSCVBlock(
                        id: block.id, type: block.type, order: block.order, enabled: enabled,
                        sourceEntityID: block.sourceEntityID, content: block.content, overrides: block.overrides,
                        aiRefinedAt: block.aiRefinedAt, pendingRaw: block.pendingRaw, skillGroups: block.skillGroups
                    )
                }
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
            if templates.allSatisfy({ $0.blocks.isEmpty }) {
                if let synced = try? await session.api.syncCVSystemTemplates() {
                    templates = synced
                }
            }
            if templates.allSatisfy({ $0.blocks.isEmpty }) {
                templates = try await bootstrapTemplatesFromDocument()
            }
            let pick = initialTemplateID ?? selectedID ?? templates.first(where: { $0.isDefault })?.id ?? templates.first?.id
            if let pick {
                await loadTemplate(id: pick)
            } else {
                isLoading = false
            }
        } catch {
            loadError = error.localizedDescription
            isLoading = false
        }
    }

    @MainActor
    private func bootstrapTemplatesFromDocument() async throws -> [POSCVTemplate] {
        let assembled = try await session.api.fetchCV()
        let blocks = POSCVDocumentBlocks.build(from: assembled.document)
        guard !blocks.isEmpty else { return templates }

        var defaultTpl = templates.first(where: { $0.isDefault })
            ?? templates.first
            ?? POSCVTemplate(
                id: assembled.documentID ?? UUID().uuidString,
                name: "Professional CV (1 page)",
                layoutID: "two_column_one_page_v5",
                isDefault: true,
                isSystem: true,
                constraints: POSCVConstraints(maxPages: 1, maxExperience: 4, maxProjects: 8),
                blocks: blocks
            )
        defaultTpl.blocks = blocks
        return [defaultTpl]
    }

    @MainActor
    private func loadTemplate(id: String) async {
        isLoading = true
        forkNotice = nil
        do {
            var loaded = try await session.api.getCVTemplate(id: id)
            if loaded.blocks.isEmpty {
                if let synced = try? await session.api.syncCVSystemTemplates(),
                   let match = synced.first(where: { $0.id == id }) ?? synced.first(where: { $0.isDefault }) {
                    loaded = match
                    templates = synced
                } else {
                    let assembled = try await session.api.fetchCV()
                    loaded.blocks = POSCVDocumentBlocks.build(from: assembled.document)
                }
            }
            template = loaded
            selectedID = id
            isLoading = false
            await runValidate(loaded)
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
        let wasSystem = template.isSystem == true
        do {
            let saved = try await session.api.saveCVTemplate(template)
            self.template = saved
            selectedID = saved.id
            if wasSystem {
                forkNotice = "Saved as “\(saved.name)”. System template unchanged."
                await reloadTemplates()
                await loadTemplate(id: saved.id)
            }
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
                copy.blocks = tpl.blocks.map { block in
                    guard block.id == blockID else { return block }
                    return POSCVBlock(
                        id: block.id, type: block.type, order: block.order, enabled: block.enabled,
                        sourceEntityID: block.sourceEntityID, content: refined, overrides: block.overrides,
                        aiRefinedAt: block.aiRefinedAt, pendingRaw: nil, skillGroups: block.skillGroups
                    )
                }
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

struct POSActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        var controllers: [Any] = []
        for item in items {
            if let data = item as? Data {
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("CV.pdf")
                try? data.write(to: url)
                controllers.append(url)
            } else {
                controllers.append(item)
            }
        }
        return UIActivityViewController(activityItems: controllers, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
