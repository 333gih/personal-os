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
    @State private var editSummary: String = ""
    @State private var editHeadline: String = ""

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
        }
    }

    private var headerSection: some View {
        POSCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Ideal CV", systemImage: "doc.richtext")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                TextField("Headline", text: $editHeadline)
                    .font(.posDisplay(18))
                    .onChange(of: editHeadline) { _, v in updateDocument { $0.headline = v } }
                TextField("Professional summary", text: $editSummary, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(3...8)
                    .onChange(of: editSummary) { _, v in updateDocument { $0.summary = v } }
                if let source = cv?.source {
                    Text(source == "ideal" ? "Pre-built ideal resume — edit, export, or share." : "Assembled from career entries.")
                        .font(.caption)
                        .foregroundStyle(POSTheme.muted)
                }
            }
        }
    }

    private var previewSection: some View {
        Group {
            if let doc = cv?.document {
                VStack(alignment: .leading, spacing: 12) {
                    POSSectionHeader(title: "Preview", eyebrow: "On resume")
                    if let skills = doc.skills, !skills.isEmpty {
                        POSCard {
                            Text("Skills").font(.caption.weight(.semibold))
                            FlowLayout(spacing: 6) {
                                ForEach(skills, id: \.self) { skill in
                                    Text(skill)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(POSTheme.border.opacity(0.35))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    if let exp = doc.experience, !exp.isEmpty {
                        bulletCard(title: "Experience", items: exp)
                    }
                    if let projects = doc.projects, !projects.isEmpty {
                        bulletCard(title: "Projects", items: projects)
                    }
                }
            }
        }
    }

    private func updateDocument(_ mutate: (inout POSCVDocument) -> Void) {
        guard var doc = cv?.document else { return }
        mutate(&doc)
        cv = POSAssembledCV(documentID: cv?.documentID, document: doc, source: cv?.source ?? "ideal")
    }

    private func bulletCard(title: String, items: [POSCVBullet]) -> some View {
        POSCard {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(POSTheme.primaryDark)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(items, id: \.stableID) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title).font(.subheadline.weight(.medium))
                        if let company = item.company {
                            Text(company).font(.caption).foregroundStyle(POSTheme.muted)
                        }
                        Text(item.content).font(.caption).foregroundStyle(POSTheme.ink.opacity(0.85)).lineLimit(3)
                    }
                }
            }
        }
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
        } catch {
            loadError = error.localizedDescription
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
            loadError = error.localizedDescription
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
