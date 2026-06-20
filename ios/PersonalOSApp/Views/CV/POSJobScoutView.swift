import SwiftUI

struct POSJobScoutView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var jobs: [POSJobOpportunity] = []
    @State private var isLoading = true
    @State private var isScanning = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            POSScreen {
                Group {
                    if isLoading {
                        POSLoadingView()
                    } else if let errorMessage, jobs.isEmpty {
                        POSEmptyState(
                            systemImage: "briefcase",
                            title: "No jobs yet",
                            message: errorMessage,
                            actionTitle: "Scan now",
                            action: { Task { await scan() } }
                        )
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Matched from your CV skills via Remotive + GitHub (help wanted). Daily auto-scan on server; tap Scan for fresh results.")
                                    .font(.caption)
                                    .foregroundStyle(POSTheme.muted)
                                    .padding(.horizontal, 16)

                                ForEach(jobs) { job in
                                    jobCard(job)
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
                        if isScanning { ProgressView() } else { Text("Scan") }
                    }
                    .disabled(isScanning)
                }
            }
            .task { await load() }
        }
    }

    private func jobCard(_ job: POSJobOpportunity) -> some View {
        POSCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
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
                if let reason = job.matchReason, !reason.isEmpty {
                    Text(reason)
                        .font(.caption2)
                        .foregroundStyle(POSTheme.ink.opacity(0.85))
                }
                HStack(spacing: 8) {
                    Label(job.source.capitalized, systemImage: job.source == "github" ? "chevron.left.forwardslash.chevron.right" : "globe")
                        .font(.caption2)
                        .foregroundStyle(POSTheme.muted)
                    Spacer()
                    Button("Apply") {
                        if let url = URL(string: job.url) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .tint(POSTheme.primaryDark)
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
            jobs = try await session.api.fetchJobs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scan() async {
        isScanning = true
        defer { isScanning = false }
        do {
            _ = try await session.api.scanJobs()
            await load()
            POSHaptics.light()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
