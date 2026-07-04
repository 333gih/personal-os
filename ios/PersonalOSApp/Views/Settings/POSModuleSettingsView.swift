import SwiftUI

struct POSModuleSettingsView: View {
    @EnvironmentObject private var modules: ModulesStore
    @Environment(\.dismiss) private var dismiss
    @State private var draftEnabled: [String: Bool] = [:]
    @State private var saving = false
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Choose which modules appear in your app. Core modules (Inbox, Search) always stay on.")
                        .font(.subheadline)
                        .foregroundStyle(POSTheme.muted)
                }
                Section("Domain modules") {
                    ForEach(modules.domainModules()) { entry in
                        if entry.required {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.label).font(.headline)
                                    Text(entry.description).font(.caption).foregroundStyle(POSTheme.muted)
                                }
                                Spacer()
                                Text("Required").font(.caption).foregroundStyle(POSTheme.muted)
                            }
                        } else {
                            Toggle(isOn: binding(for: entry.id, default: entry.defaultEnabled)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.label).font(.headline)
                                    Text(entry.description).font(.caption).foregroundStyle(POSTheme.muted)
                                }
                            }
                        }
                    }
                }
                if let saveError {
                    Section {
                        Text(saveError).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Modules")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(saving)
                }
            }
            .onAppear {
                for pref in modules.prefs {
                    draftEnabled[pref.moduleId] = pref.enabled
                }
            }
        }
    }

    private func binding(for id: String, default defaultValue: Bool) -> Binding<Bool> {
        Binding(
            get: { draftEnabled[id] ?? defaultValue },
            set: { draftEnabled[id] = $0 }
        )
    }

    private func save() async {
        saving = true
        saveError = nil
        defer { saving = false }
        let updates = modules.domainModules().map { entry -> (id: String, enabled: Bool?, pinOrder: Int?) in
            (entry.id, draftEnabled[entry.id], nil)
        }
        do {
            try await modules.update(modules: updates)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
