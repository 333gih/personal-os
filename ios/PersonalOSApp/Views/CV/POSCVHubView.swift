import SwiftUI
import UIKit

struct POSCVHubView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var cv: POSAssembledCV?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var isSaving = false
    @State private var isExporting = false
    @State private var chatInstruction = ""
    @State private var chatReply: String?
    @State private var selectedSection = "summary"
    @State private var showShareSheet = false
    @State private var sharePDFData: Data?
    @State private var alertMessage: String?
    @State private var editSummary: String = ""
    @State private var editHeadline: String = ""
    @State private var editSkillsText: String = ""
    @State private var suggestedSkills: [POSCVSuggestedSkill] = []
    @State private var primaryStackLabel: String = ""
    @State private var isLoadingSuggestions = false

    var body: some View {
        NavigationStack {
            POSScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if isLoading {
                            POSLoadingView()
                        } else if let loadError {
                            POSEmptyState(
                                systemImage: "doc.text",
                                title: "Could not load CV",
                                message: loadError,
                                actionTitle: "Retry",
                                action: { Task { await load() } }
                            )
                        } else if cv != nil {
                            headerSection
                            aiCoachSection
                            previewSection
                            actionsSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("CV Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving { ProgressView() } else { Text("Save") }
                    }
                    .disabled(isSaving || cv == nil)
                }
            }
            .task { await load() }
            .sheet(isPresented: $showShareSheet) {
                if let sharePDFData {
                    POSActivityShareSheet(items: [sharePDFData, "My CV.pdf"])
                }
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

    private var headerSection: some View {
        POSCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Ideal CV", systemImage: "doc.richtext")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                TextField("Headline (Name — Role)", text: $editHeadline)
                    .font(.posDisplay(18))
                    .onChange(of: editHeadline) { v in updateDocument { $0.headline = v } }
                TextField("Professional summary", text: $editSummary, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(3...8)
                    .onChange(of: editSummary) { v in updateDocument { $0.summary = v } }
                contactFields
                if let source = cv?.source {
                    Text(source == "ideal" ? "Pre-built ideal resume — edit sections below, export, or share." : "Assembled from career entries.")
                        .font(.caption)
                        .foregroundStyle(POSTheme.muted)
                }
            }
        }
    }

    private var contactFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Contact").font(.caption.weight(.semibold)).foregroundStyle(POSTheme.muted)
            TextField("Email", text: bindingContact(\.email))
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            TextField("Phone", text: bindingContact(\.phone))
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
            TextField("Location", text: bindingContact(\.location))
            TextField("LinkedIn URL", text: bindingContact(\.linkedin))
                .textContentType(.URL)
                .keyboardType(.URL)
                .autocapitalization(.none)
            TextField("GitHub URL", text: bindingContact(\.github))
                .textContentType(.URL)
                .keyboardType(.URL)
                .autocapitalization(.none)
        }
    }

    private var skillGroupsSection: some View {
        POSCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Skills (by category)").font(.caption.weight(.semibold))
                let groups = cv?.document.skillGroups ?? []
                if groups.isEmpty {
                    TextField("Comma-separated skills", text: $editSkillsText, axis: .vertical)
                        .font(.subheadline)
                        .lineLimit(2...6)
                        .onChange(of: editSkillsText) { v in
                            let skills = v.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                            updateDocument { $0.skills = skills.isEmpty ? nil : skills }
                        }
                } else {
                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.category).font(.caption.weight(.semibold)).foregroundStyle(POSTheme.primaryDark)
                            Text(group.items.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(POSTheme.ink)
                        }
                        if group.id != groups.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var suggestedSkillsSection: some View {
        POSCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("AI skill suggestions", systemImage: "plus.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(POSTheme.primaryDark)
                    Spacer()
                    Button {
                        Task { await loadSuggestions() }
                    } label: {
                        if isLoadingSuggestions {
                            ProgressView()
                        } else {
                            Text("Refresh")
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .disabled(isLoadingSuggestions)
                }
                Text("Tap a skill to add it directly into your CV.")
                    .font(.caption2)
                    .foregroundStyle(POSTheme.muted)
                if suggestedSkills.isEmpty {
                    Text("Refresh to get AI suggestions based on your experience.")
                        .font(.caption)
                        .foregroundStyle(POSTheme.muted)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(suggestedSkills) { item in
                            Button {
                                Task { await addSuggestedSkill(item) }
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("+ \(item.skill)")
                                        .font(.caption.weight(.semibold))
                                    Text(item.category)
                                        .font(.caption2)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(POSTheme.border.opacity(0.35))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func bindingContact(_ keyPath: WritableKeyPath<POSCVContact, String?>) -> Binding<String> {
        Binding(
            get: { cv?.document.contact?[keyPath: keyPath] ?? "" },
            set: { newValue in
                updateDocument { doc in
                    var contact = doc.contact ?? POSCVContact()
                    contact[keyPath: keyPath] = newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newValue
                    doc.contact = contact
                }
            }
        )
    }

    private var previewSection: some View {
        Group {
            if cv?.document != nil {
                VStack(alignment: .leading, spacing: 12) {
                    POSSectionHeader(title: "Edit sections", eyebrow: "Resume body")

                    if !primaryStackLabel.isEmpty {
                        POSCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Primary stack (Job Scout)").font(.caption.weight(.semibold))
                                Text(primaryStackLabel)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(POSTheme.primaryDark)
                                Text("Jobs matching this stack score highest — detected from your CV, not hardcoded.")
                                    .font(.caption2)
                                    .foregroundStyle(POSTheme.muted)
                            }
                        }
                    }

                    skillGroupsSection
                    suggestedSkillsSection

                    if let education = cv?.document.education, !education.isEmpty {
                        POSCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Education").font(.caption.weight(.semibold))
                                ForEach(education) { item in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.school).font(.subheadline.weight(.medium))
                                        if let degree = item.degree, !degree.isEmpty {
                                            Text(degree).font(.caption)
                                        }
                                        if let period = item.period, !period.isEmpty {
                                            Text(period).font(.caption2).foregroundStyle(POSTheme.muted)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if let achievements = cv?.document.achievements, !achievements.isEmpty {
                        POSCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Achievements").font(.caption.weight(.semibold))
                                ForEach(Array(achievements.enumerated()), id: \.element.id) { index, item in
                                    TextField("Achievement", text: bindingAchievement(index: index), axis: .vertical)
                                        .font(.caption)
                                        .lineLimit(2...6)
                                }
                            }
                        }
                    }

                    if let certificates = cv?.document.certificates, !certificates.isEmpty {
                        POSCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Certificates").font(.caption.weight(.semibold))
                                ForEach(Array(certificates.enumerated()), id: \.element.id) { index, item in
                                    VStack(alignment: .leading, spacing: 4) {
                                        TextField("Title", text: bindingCertificate(index: index, keyPath: \.title))
                                            .font(.subheadline.weight(.medium))
                                        TextField("Issuer", text: bindingOptionalCertificate(index: index, keyPath: \.issuer))
                                            .font(.caption)
                                        TextField("Period", text: bindingOptionalCertificate(index: index, keyPath: \.period))
                                            .font(.caption2)
                                    }
                                    if index < certificates.count - 1 { Divider() }
                                }
                            }
                        }
                    }

                    editableBulletSection(title: "Experience", keyPath: \.experience)
                    editableBulletSection(title: "Projects", keyPath: \.projects)
                }
            }
        }
    }

    private func editableBulletSection(title: String, keyPath: WritableKeyPath<POSCVDocument, [POSCVBullet]?>) -> some View {
        POSCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(POSTheme.primaryDark)
                let items = cv?.document[keyPath: keyPath] ?? []
                ForEach(Array(items.enumerated()), id: \.element.stableID) { index, item in
                    editableBulletRow(title: title, index: index, item: item, keyPath: keyPath)
                    if index < items.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private func editableBulletRow(title: String, index: Int, item: POSCVBullet, keyPath: WritableKeyPath<POSCVDocument, [POSCVBullet]?>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Title / role", text: bindingBullet(index: index, keyPath: keyPath, itemKeyPath: \.title))
                .font(.subheadline.weight(.medium))
            TextField("Company", text: bindingOptionalBullet(index: index, keyPath: keyPath, itemKeyPath: \.company))
                .font(.caption)
            TextField("Period (e.g. 2024 — Present)", text: bindingOptionalBullet(index: index, keyPath: keyPath, itemKeyPath: \.period))
                .font(.caption)
            TextField("Details (one bullet per line)", text: bindingBullet(index: index, keyPath: keyPath, itemKeyPath: \.content), axis: .vertical)
                .font(.caption)
                .lineLimit(3...10)
        }
    }

    private func bindingBullet(index: Int, keyPath: WritableKeyPath<POSCVDocument, [POSCVBullet]?>, itemKeyPath: WritableKeyPath<POSCVBullet, String>) -> Binding<String> {
        Binding(
            get: { cv?.document[keyPath: keyPath]?[safe: index]?[keyPath: itemKeyPath] ?? "" },
            set: { newValue in
                updateDocument { doc in
                    guard var items = doc[keyPath: keyPath], index < items.count else { return }
                    items[index][keyPath: itemKeyPath] = newValue
                    doc[keyPath: keyPath] = items
                }
            }
        )
    }

    private func bindingOptionalBullet(index: Int, keyPath: WritableKeyPath<POSCVDocument, [POSCVBullet]?>, itemKeyPath: WritableKeyPath<POSCVBullet, String?>) -> Binding<String> {
        Binding(
            get: { cv?.document[keyPath: keyPath]?[safe: index]?[keyPath: itemKeyPath] ?? "" },
            set: { newValue in
                updateDocument { doc in
                    guard var items = doc[keyPath: keyPath], index < items.count else { return }
                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    items[index][keyPath: itemKeyPath] = trimmed.isEmpty ? nil : trimmed
                    doc[keyPath: keyPath] = items
                }
            }
        )
    }

    private func bindingAchievement(index: Int) -> Binding<String> {
        Binding(
            get: { cv?.document.achievements?[safe: index]?.content ?? "" },
            set: { newValue in
                updateDocument { doc in
                    guard var items = doc.achievements, index < items.count else { return }
                    items[index].content = newValue
                    doc.achievements = items
                }
            }
        )
    }

    private func bindingCertificate(index: Int, keyPath: WritableKeyPath<POSCVCertificate, String>) -> Binding<String> {
        Binding(
            get: { cv?.document.certificates?[safe: index]?[keyPath: keyPath] ?? "" },
            set: { newValue in
                updateDocument { doc in
                    guard var items = doc.certificates, index < items.count else { return }
                    items[index][keyPath: keyPath] = newValue
                    doc.certificates = items
                }
            }
        )
    }

    private func bindingOptionalCertificate(index: Int, keyPath: WritableKeyPath<POSCVCertificate, String?>) -> Binding<String> {
        Binding(
            get: { cv?.document.certificates?[safe: index]?[keyPath: keyPath] ?? "" },
            set: { newValue in
                updateDocument { doc in
                    guard var items = doc.certificates, index < items.count else { return }
                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    items[index][keyPath: keyPath] = trimmed.isEmpty ? nil : trimmed
                    doc.certificates = items
                }
            }
        )
    }

    private func updateDocument(_ mutate: (inout POSCVDocument) -> Void) {
        guard var doc = cv?.document else { return }
        mutate(&doc)
        cv = POSAssembledCV(documentID: cv?.documentID, document: doc, source: cv?.source ?? "ideal")
    }

    private var aiCoachSection: some View {
        POSCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("AI CV coach", systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                Picker("Section", selection: $selectedSection) {
                    Text("Summary").tag("summary")
                    Text("Experience").tag("experience")
                    Text("Projects").tag("projects")
                }
                .pickerStyle(.segmented)
                TextField("Ask AI to improve wording, shorten, or tailor for a role…", text: $chatInstruction, axis: .vertical)
                    .lineLimit(2...4)
                    .font(.subheadline)
                POSActionButton(title: "Refine with AI", icon: "wand.and.stars", style: .secondary) {
                    Task { await refine() }
                }
                if let chatReply {
                    Text(chatReply)
                        .font(.caption)
                        .foregroundStyle(POSTheme.ink)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(POSTheme.border.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 10) {
            POSActionButton(title: "Download PDF", icon: "arrow.down.doc", style: .primary) {
                Task { await downloadPDF() }
            }
            POSActionButton(title: "Share PDF", icon: "square.and.arrow.up", style: .secondary) {
                Task { await sharePDF() }
            }
            POSActionButton(title: "Upload to cloud (SeaweedFS)", icon: "icloud.and.arrow.up", style: .secondary) {
                Task { await uploadShareLink() }
            }
        }
        .disabled(isExporting)
    }

    private func load() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            cv = try await session.api.fetchCV()
            editHeadline = cv?.document.headline ?? ""
            editSummary = cv?.document.summary ?? ""
            editSkillsText = (cv?.document.skills ?? []).joined(separator: ", ")
            if let stack = cv?.document.primaryStack, !stack.isEmpty {
                primaryStackLabel = stack.joined(separator: " · ")
            } else if let groups = cv?.document.skillGroups, let first = groups.first?.items.prefix(3) {
                primaryStackLabel = first.joined(separator: " · ")
            }
            await loadSuggestions()
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func loadSuggestions() async {
        isLoadingSuggestions = true
        defer { isLoadingSuggestions = false }
        do {
            let resp = try await session.api.suggestCVSkills()
            suggestedSkills = resp.suggestions
            if let stack = resp.primaryStack, !stack.isEmpty {
                primaryStackLabel = stack.joined(separator: " · ")
            }
        } catch {
            // Suggestions are optional — keep UI usable without AI.
        }
    }

    private func addSuggestedSkill(_ item: POSCVSuggestedSkill) async {
        do {
            let resp = try await session.api.addCVSkill(category: item.category, skill: item.skill)
            cv = POSAssembledCV(documentID: cv?.documentID, document: resp.document, source: cv?.source ?? "ideal")
            suggestedSkills.removeAll { $0.id == item.id }
            POSHaptics.light()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func save() async {
        guard var doc = cv?.document else { return }
        doc.headline = editHeadline
        doc.summary = editSummary
        isSaving = true
        defer { isSaving = false }
        do {
            let saved = try await session.api.saveCV(document: doc)
            cv = saved
            POSHaptics.light()
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func refine() async {
        guard let doc = cv?.document else { return }
        guard !chatInstruction.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let content: String
        switch selectedSection {
        case "experience":
            content = (doc.experience ?? []).map { "\($0.title): \($0.content)" }.joined(separator: "\n")
        case "projects":
            content = (doc.projects ?? []).map { "\($0.title): \($0.content)" }.joined(separator: "\n")
        default:
            content = doc.summary
        }
        do {
            let resp = try await session.api.refineCV(instruction: chatInstruction, section: selectedSection, content: content)
            chatReply = resp.reply
            if selectedSection == "summary", let refined = resp.refinedContent, !refined.isEmpty {
                editSummary = refined
                updateDocument { $0.summary = refined }
            }
            chatInstruction = ""
            POSHaptics.light()
        } catch {
            chatReply = error.localizedDescription
        }
    }

    private func downloadPDF() async {
        isExporting = true
        defer { isExporting = false }
        do {
            let data = try await session.api.downloadCVPDF()
            sharePDFData = data
            showShareSheet = true
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func sharePDF() async {
        await downloadPDF()
    }

    private func uploadShareLink() async {
        isExporting = true
        defer { isExporting = false }
        do {
            let resp = try await session.api.shareCV()
            if let url = URL(string: resp.url) {
                let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let root = scene.windows.first?.rootViewController {
                    root.present(av, animated: true)
                }
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

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
