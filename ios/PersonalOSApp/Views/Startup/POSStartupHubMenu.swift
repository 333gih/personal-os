import SwiftUI

struct POSStartupHubMenu: View {
    @Environment(\.dismiss) private var dismiss
    let onAddEntry: () -> Void
    let onOpenBoard: () -> Void
    let onCapture: () -> Void

    var body: some View {
        NavigationStack {
            POSScreen {
                ScrollView {
                    VStack(spacing: 10) {
                        Text("Manage Fash and other startup ideas — AI normalizes notes into portfolio entities.")
                            .font(.caption)
                            .foregroundStyle(POSTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        menuRow("Add startup entry (AI)", icon: "plus.circle.fill", subtitle: "Idea, feature, KPI, competitor") {
                            dismiss(); onAddEntry()
                        }
                        menuRow("Open startup board", icon: "building.2.fill", subtitle: "Full list in web board") {
                            dismiss(); onOpenBoard()
                        }
                        menuRow("Quick capture", icon: "square.and.pencil", subtitle: "Send raw note to inbox") {
                            dismiss(); onCapture()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Startup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func menuRow(_ title: String, icon: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            POSCard {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(POSTheme.primaryDark)
                        .frame(width: 32)
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

struct POSStartupAddView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    let onCreated: (String, String) -> Void

    @State private var kind = "idea"
    @State private var titleHint = ""
    @State private var rawText = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let kinds: [(String, String)] = [
        ("idea", "Idea"), ("feature", "Feature"), ("kpi", "KPI"),
        ("competitor", "Competitor"), ("pain_point", "Pain point"), ("business_model", "Business model")
    ]

    var body: some View {
        NavigationStack {
            POSScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Describe your startup note — AI formats it for the Fash portfolio shelf.")
                            .font(.caption)
                            .foregroundStyle(POSTheme.muted)
                        Picker("Type", selection: $kind) {
                            ForEach(kinds, id: \.0) { value, label in
                                Text(label).tag(value)
                            }
                        }
                        .pickerStyle(.segmented)
                        TextField("Title hint", text: $titleHint).textFieldStyle(.roundedBorder)
                        TextField("Notes…", text: $rawText, axis: .vertical).lineLimit(5...12)
                        if let errorMessage {
                            Text(errorMessage).font(.caption).foregroundStyle(.red)
                        }
                        POSActionButton(title: isSaving ? "Saving…" : "Add & normalize", icon: "sparkles", style: .primary) {
                            Task { await submit() }
                        }
                        .disabled(isSaving || rawText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add Startup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private func submit() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            let result = try await session.api.addStartupEntry(kind: kind, rawText: rawText, titleHint: titleHint)
            POSHaptics.medium()
            onCreated(result.entityID, result.title)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
