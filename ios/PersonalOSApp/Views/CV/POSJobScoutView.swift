import SafariServices
import SwiftUI

struct POSJobSafariView: UIViewControllerRepresentable {
    let url: URL
    let onFinish: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.delegate = context.coordinator
        vc.preferredControlTintColor = UIColor(POSTheme.primaryDark)
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onFinish()
        }
    }
}

struct POSJobScoutView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var tab: POSJobTab = .open
    @State private var openJobs: [POSJobOpportunity] = []
    @State private var appliedJobs: [POSJobOpportunity] = []
    @State private var isLoading = true
    @State private var isScanning = false
    @State private var errorMessage: String?
    @State private var scanSummary: String?
    @State private var applyJob: POSJobOpportunity?
    @State private var confirmApplyJob: POSJobOpportunity?

    private var visibleJobs: [POSJobOpportunity] {
        tab == .open ? openJobs : appliedJobs
    }

    var body: some View {
        NavigationStack {
            POSScreen {
                Group {
                    if isLoading {
                        POSLoadingView()
                    } else if let errorMessage, visibleJobs.isEmpty && tab == .open {
                        POSEmptyState(
                            systemImage: "briefcase",
                            title: "No matches yet",
                            message: errorMessage,
                            actionTitle: "Scan now",
                            action: { Task { await scan() } }
                        )
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                headerCopy
                                if let scanSummary {
                                    Text(scanSummary)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(POSTheme.success)
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
                            HStack(spacing: 6) {
                                ProgressView()
                                Text("Scanning…")
                            }
                        } else {
                            Text("Scan")
                        }
                    }
                    .disabled(isScanning)
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
                Button("Not yet", role: .cancel) {
                    confirmApplyJob = nil
                }
            } message: {
                if let job = confirmApplyJob {
                    Text("Mark \"\(job.title)\" as applied so it moves to your Applied list.")
                }
            }
        }
    }

    private var headerCopy: some View {
        Text("AI matches jobs from Remotive + RemoteOK (≥50% fit to your CV). Tap Apply to open the listing in Safari, then mark done when finished.")
            .font(.caption)
            .foregroundStyle(POSTheme.muted)
            .padding(.horizontal, 16)
    }

    private var tabPicker: some View {
        Picker("Jobs", selection: $tab) {
            ForEach(POSJobTab.allCases, id: \.self) { t in
                Text(t.rawValue).tag(t)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .onChange(of: tab) { _ in
            Task { await load() }
        }
    }

    @ViewBuilder
    private var emptyTabState: some View {
        POSEmptyState(
            systemImage: tab == .open ? "sparkles" : "checkmark.seal",
            title: tab == .open ? "No jobs ≥50% match" : "No applied jobs",
            message: tab == .open
                ? "Tap Scan to crawl listings and run AI matching against your CV skills."
                : "Jobs you mark as applied after submitting will appear here.",
            actionTitle: tab == .open ? "Scan now" : nil,
            action: tab == .open ? { Task { await scan() } } : nil
        )
        .padding(.top, 8)
    }

    private func jobCard(_ job: POSJobOpportunity) -> some View {
        POSCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(job.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(POSTheme.ink)
                    Spacer()
                    Text("\(Int(job.matchScore * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(POSTheme.primaryDark)
                }
                if let company = job.company, !company.isEmpty {
                    Text(company)
                        .font(.caption)
                        .foregroundStyle(POSTheme.muted)
                }
                if let location = job.location, !location.isEmpty {
                    Text(location)
                        .font(.caption2)
                        .foregroundStyle(POSTheme.muted)
                }
                if let reason = job.matchReason, !reason.isEmpty {
                    Text(reason)
                        .font(.caption2)
                        .foregroundStyle(POSTheme.ink.opacity(0.85))
                }
                HStack(spacing: 8) {
                    Label(sourceLabel(job.source), systemImage: sourceIcon(job.source))
                        .font(.caption2)
                        .foregroundStyle(POSTheme.muted)
                    Spacer()
                    if tab == .open {
                        Button("Dismiss") {
                            Task { await updateStatus(job, status: "dismissed") }
                        }
                        .font(.caption)
                        .foregroundStyle(POSTheme.muted)
                        Button("Apply") {
                            applyJob = job
                        }
                        .font(.caption.weight(.semibold))
                        .buttonStyle(.borderedProminent)
                        .tint(POSTheme.primaryDark)
                    } else {
                        Button("Reopen") {
                            Task { await updateStatus(job, status: "open") }
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func sourceLabel(_ source: String) -> String {
        switch source {
        case "remoteok": return "RemoteOK"
        case "remotive": return "Remotive"
        case "github": return "GitHub"
        default: return source.capitalized
        }
    }

    private func sourceIcon(_ source: String) -> String {
        switch source {
        case "github": return "chevron.left.forwardslash.chevron.right"
        default: return "globe"
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let open = session.api.fetchJobs(status: "open")
            async let applied = session.api.fetchJobs(status: "applied")
            openJobs = try await open
            appliedJobs = try await applied
            if openJobs.isEmpty && tab == .open {
                errorMessage = "No listings at 50%+ match yet. Tap Scan — needs OPENROUTER_API_KEY on server for AI scoring."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scan() async {
        isScanning = true
        scanSummary = nil
        errorMessage = nil
        defer { isScanning = false }
        do {
            let result = try await session.api.scanJobs()
            let pct = Int((result.minScore ?? 0.5) * 100)
            scanSummary = "Scanned \(result.found) listings · \(result.matched) matched ≥\(pct)% · \(result.stored) new"
            await load()
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
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
