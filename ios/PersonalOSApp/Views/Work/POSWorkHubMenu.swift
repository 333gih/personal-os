import SwiftUI

struct POSWorkHubMenu: View {
    @Environment(\.dismiss) private var dismiss
    let onAddEntry: () -> Void
    let onImport: () -> Void
    let onCV: () -> Void
    let onJobScout: () -> Void
    let onCapture: () -> Void

    var body: some View {
        NavigationStack {
            POSScreen {
                ScrollView {
                    VStack(spacing: 10) {
                        Text("Add and sync your career data — AI normalizes everything to stay professional.")
                            .font(.caption)
                            .foregroundStyle(POSTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 4)

                        menuRow("Add entry (AI)", icon: "plus.circle.fill", subtitle: "Project, skill, role — synced to CV") {
                            dismiss()
                            onAddEntry()
                        }
                        menuRow("Import project", icon: "square.and.arrow.down", subtitle: "Diagram + notes → full project") {
                            dismiss()
                            onImport()
                        }
                        menuRow("CV Transfer", icon: "doc.richtext", subtitle: "Edit resume, export PDF") {
                            dismiss()
                            onCV()
                        }
                        menuRow("Job Scout", icon: "briefcase.fill", subtitle: "Focus stack, years, remote/hybrid") {
                            dismiss()
                            onJobScout()
                        }
                        menuRow("Quick capture", icon: "square.and.pencil", subtitle: "Send note to inbox") {
                            dismiss()
                            onCapture()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Work")
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
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(POSTheme.muted)
                }
            }
        }
        .buttonStyle(POSPressButtonStyle())
    }
}

struct POSWorkAddView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    let onCreated: (String, String) -> Void

    @State private var kind = "project"
    @State private var titleHint = ""
    @State private var rawText = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private let kinds: [(String, String)] = [
        ("project", "Project"),
        ("skill", "Skill / Tech"),
        ("role", "Role"),
        ("feature", "Feature"),
        ("lesson", "Lesson"),
        ("decision", "Decision")
    ]

    var body: some View {
        NavigationStack {
            POSScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Paste rough notes — AI rewrites professionally and syncs skills to your CV.")
                            .font(.caption)
                            .foregroundStyle(POSTheme.muted)

                        Picker("Type", selection: $kind) {
                            ForEach(kinds, id: \.0) { value, label in
                                Text(label).tag(value)
                            }
                        }
                        .pickerStyle(.segmented)

                        TextField("Title hint (optional)", text: $titleHint)
                            .textFieldStyle(.roundedBorder)

                        TextField("Your notes…", text: $rawText, axis: .vertical)
                            .lineLimit(5...12)
                            .font(.subheadline)

                        if let errorMessage {
                            Text(errorMessage).font(.caption).foregroundStyle(.red)
                        }
                        if let successMessage {
                            Text(successMessage).font(.caption).foregroundStyle(POSTheme.success)
                        }

                        POSActionButton(title: isSaving ? "Adding…" : "Add & normalize", icon: "sparkles", style: .primary) {
                            Task { await submit() }
                        }
                        .disabled(isSaving || rawText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add to Work")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func submit() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }
        do {
            let result = try await session.api.addWorkEntry(
                kind: kind,
                rawText: rawText,
                titleHint: titleHint
            )
            var msg = "Added \"\(result.title)\""
            if let skills = result.cvSkillsAdded, !skills.isEmpty {
                msg += " · CV skills: \(skills.joined(separator: ", "))"
            }
            successMessage = msg
            POSHaptics.medium()
            onCreated(result.entityID, result.title)
            try? await Task.sleep(nanoseconds: 800_000_000)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
