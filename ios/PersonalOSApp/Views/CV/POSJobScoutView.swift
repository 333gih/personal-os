import SafariServices
import SwiftUI

struct POSJobSafariView: UIViewControllerRepresentable {
    let url: URL
    let onFinish: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.delegate = context.coordinator
        vc.preferredControlTintColor = UIColor(POSTheme.primaryDark)
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) { onFinish() }
    }
}

struct POSJobScoutView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var tab: POSJobTab = .open
    @State private var openJobs: [POSJobOpportunity] = []
    @State private var appliedJobs: [POSJobOpportunity] = []
    @State private var prefs = POSJobSearchPreferences.defaultRemote
    @State private var customSkill = ""
    @State private var isLoading = true
    @State private var isScanning = false
    @State private var isSavingPrefs = false
    @State private var errorMessage: String?
    @State private var scanSummary: String?
    @State private var applyJob: POSJobOpportunity?
    @State private var confirmApplyJob: POSJobOpportunity?
    @State private var showPrefs = true

    private var visibleJobs: [POSJobOpportunity] {
        tab == .open ? openJobs : appliedJobs
    }

    private var skillPool: [String] {
        var seen = Set<String>()
        var out: [String] = []
        for s in (prefs.availableSkills ?? []) + prefs.focusSkills {
            let key = s.lowercased()
            if seen.insert(key).inserted { out.append(s) }
        }
        return out.sorted()
    }

    var body: some View {
        NavigationStack {
            POSScreen {
                Group {
                    if isLoading {
                        POSLoadingView()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 14) {
                                preferencesSection
                                if let scanSummary {
                                    Text(scanSummary)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(POSTheme.success)
                                        .padding(.horizontal, 16)
                                }
                                if let errorMessage {
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                        .padding(.horizontal, 16)
                                }
                                tabPicker
                                if visibleJobs.isEmpty {
                                    emptyTabState
                                } else {
                                    ForEach(visibleJobs) { job in
                                        jobCard(job)
                                    }
                                }
                            }
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationTitle("Job Scout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await scan() }
                    } label: {
                        if isScanning {
                            ProgressView()
                        } else {
                            Text("Scan")
                        }
                    }
                    .disabled(isScanning || isSavingPrefs)
                }
            }
            .task { await load() }
            .sheet(item: $applyJob) { job in
                if let url = URL(string: job.url) {
                    POSJobSafariView(url: url) {
                        applyJob = nil
                        confirmApplyJob = job
                    }
                }
            }
            .alert("Finished applying?", isPresented: Binding(
                get: { confirmApplyJob != nil },
                set: { if !$0 { confirmApplyJob = nil } }
            )) {
                Button("Mark applied") {
                    if let job = confirmApplyJob {
                        Task { await markApplied(job) }
                    }
                    confirmApplyJob = nil
                }
                Button("Not yet", role: .cancel) { confirmApplyJob = nil }
            } message: {
                if let job = confirmApplyJob {
                    Text("Mark \"\(job.title)\" as applied?")
                }
            }
        }
    }

    private var preferencesSection: some View {
        POSCard {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    withAnimation { showPrefs.toggle() }
                } label: {
                    HStack {
                        Label("Job search preferences", systemImage: "slider.horizontal.3")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(POSTheme.primaryDark)
                        Spacer()
                        Image(systemName: showPrefs ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(POSTheme.muted)
                    }
                }
                .buttonStyle(.plain)

                if showPrefs {
                    Text("Like LinkedIn — set main focus, experience, and work style before scanning.")
                        .font(.caption2)
                        .foregroundStyle(POSTheme.muted)

                    TextField("Target role (e.g. Software Engineer)", text: $prefs.targetRole)
                        .font(.subheadline)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Text("Years experience")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Stepper(String(format: "%.1f yrs", prefs.yearsExperience), value: $prefs.yearsExperience, in: 0...25, step: 0.5)
                            .font(.caption)
                    }

                    Text("Main focus (stack)").font(.caption.weight(.semibold))
                    FlowLayout(spacing: 8) {
                        ForEach(skillPool, id: \.self) { skill in
                            skillChip(skill)
                        }
                    }
                    HStack {
                        TextField("Add custom skill", text: $customSkill)
                            .font(.caption)
                            .textFieldStyle(.roundedBorder)
                        Button("Add") { addCustomSkill() }
                            .font(.caption.weight(.semibold))
                            .disabled(customSkill.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    Text("Work location").font(.caption.weight(.semibold))
                    toggleRow(options: [
                        ("remote", "Remote"),
                        ("hybrid", "Hybrid"),
                        ("onsite", "On-site"),
                        ("anywhere", "Anywhere")
                    ], selection: $prefs.workLocationTypes)

                    Text("Employment type").font(.caption.weight(.semibold))
                    toggleRow(options: [
                        ("full_time", "Full-time"),
                        ("contract", "Contract"),
                        ("part_time", "Part-time"),
                        ("internship", "Internship")
                    ], selection: $prefs.employmentTypes)

                    Toggle("Daily scan (~7:00 ICT)", isOn: $prefs.dailyScanEnabled)
                        .font(.caption)
                    Toggle("Push alerts for new jobs", isOn: $prefs.pushEnabled)
                        .font(.caption)
                    if let lastScan = prefs.lastScanAt, !lastScan.isEmpty {
                        Text("Last scan: \(lastScan)")
                            .font(.caption2)
                            .foregroundStyle(POSTheme.muted)
                    }

                    POSActionButton(title: isSavingPrefs ? "Saving…" : "Save preferences", icon: "checkmark.circle", style: .primary) {
                        Task { await savePreferences() }
                    }
                    .disabled(isSavingPrefs)
                } else {
                    Text(focusSummary)
                        .font(.caption)
                        .foregroundStyle(POSTheme.ink)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var focusSummary: String {
        let focus = prefs.focusSkills.isEmpty ? "—" : prefs.focusSkills.joined(separator: " · ")
        let loc = prefs.workLocationTypes.map { $0.replacingOccurrences(of: "_", with: " ") }.joined(separator: ", ")
        return "\(prefs.targetRole) · \(String(format: "%.1f", prefs.yearsExperience)) yrs · Focus: \(focus) · \(loc)"
    }

    private func skillChip(_ skill: String) -> some View {
        let selected = prefs.focusSkills.contains(where: { $0.caseInsensitiveCompare(skill) == .orderedSame })
        return Button {
            toggleFocus(skill)
        } label: {
            Text(selected ? "✓ \(skill)" : skill)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selected ? POSTheme.primaryDark.opacity(0.15) : POSTheme.border.opacity(0.35))
                .foregroundStyle(selected ? POSTheme.primaryDark : POSTheme.ink)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(options: [(String, String)], selection: Binding<[String]>) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.0) { value, label in
                let on = selection.wrappedValue.contains(value)
                Button {
                    if on {
                        selection.wrappedValue.removeAll { $0 == value }
                    } else {
                        selection.wrappedValue.append(value)
                    }
                } label: {
                    Text(on ? "✓ \(label)" : label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(on ? POSTheme.primaryDark.opacity(0.15) : POSTheme.border.opacity(0.35))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggleFocus(_ skill: String) {
        if let idx = prefs.focusSkills.firstIndex(where: { $0.caseInsensitiveCompare(skill) == .orderedSame }) {
            prefs.focusSkills.remove(at: idx)
        } else {
            prefs.focusSkills.append(skill)
        }
    }

    private func addCustomSkill() {
        let s = customSkill.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return }
        if prefs.availableSkills == nil { prefs.availableSkills = [] }
        if !(prefs.availableSkills ?? []).contains(where: { $0.caseInsensitiveCompare(s) == .orderedSame }) {
            prefs.availableSkills?.append(s)
        }
        if !prefs.focusSkills.contains(where: { $0.caseInsensitiveCompare(s) == .orderedSame }) {
            prefs.focusSkills.append(s)
        }
        customSkill = ""
    }

    private var tabPicker: some View {
        Picker("Jobs", selection: $tab) {
            ForEach(POSJobTab.allCases, id: \.self) { t in
                Text(t.rawValue).tag(t)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .onChange(of: tab) { _ in Task { await loadJobsOnly() } }
    }

    @ViewBuilder
    private var emptyTabState: some View {
        POSEmptyState(
            systemImage: tab == .open ? "sparkles" : "checkmark.seal",
            title: tab == .open ? "No matching jobs yet" : "No applied jobs",
            message: tab == .open
                ? "Save preferences, then Scan. Jobs matching your main focus score highest."
                : "Jobs you mark applied appear here.",
            actionTitle: tab == .open ? "Scan now" : nil,
            action: tab == .open ? { Task { await scan() } } : nil
        )
        .padding(.top, 8)
    }

    private func jobCard(_ job: POSJobOpportunity) -> some View {
        POSCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(job.title).font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(Int(job.matchScore * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(POSTheme.primaryDark)
                }
                if let company = job.company, !company.isEmpty {
                    Text(company).font(.caption).foregroundStyle(POSTheme.muted)
                }
                if let location = job.location, !location.isEmpty {
                    Text(location).font(.caption2).foregroundStyle(POSTheme.muted)
                }
                if let reason = job.matchReason, !reason.isEmpty {
                    Text(reason).font(.caption2).foregroundStyle(POSTheme.ink.opacity(0.85))
                }
                HStack {
                    Spacer()
                    if tab == .open {
                        Button("Dismiss") { Task { await updateStatus(job, status: "dismissed") } }
                            .font(.caption)
                        Button("Apply") { applyJob = job }
                            .font(.caption.weight(.semibold))
                            .buttonStyle(.borderedProminent)
                            .tint(POSTheme.primaryDark)
                    } else {
                        Button("Reopen") { Task { await updateStatus(job, status: "open") } }
                            .font(.caption)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            prefs = try await session.api.fetchJobPreferences()
            await loadJobsOnly()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadJobsOnly() async {
        do {
            async let open = session.api.fetchJobs(status: "open")
            async let applied = session.api.fetchJobs(status: "applied")
            openJobs = try await open
            appliedJobs = try await applied
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func savePreferences() async {
        isSavingPrefs = true
        defer { isSavingPrefs = false }
        do {
            prefs = try await session.api.saveJobPreferences(prefs)
            POSHaptics.light()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scan() async {
        isScanning = true
        scanSummary = nil
        defer { isScanning = false }
        do {
            _ = try await session.api.saveJobPreferences(prefs)
            let result = try await session.api.scanJobs()
            scanSummary = result.summaryText()
            await loadJobsOnly()
            POSHaptics.light()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func markApplied(_ job: POSJobOpportunity) async {
        await updateStatus(job, status: "applied")
        POSHaptics.medium()
    }

    private func updateStatus(_ job: POSJobOpportunity, status: String) async {
        do {
            try await session.api.updateJobStatus(id: job.id, status: status)
            await loadJobsOnly()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
