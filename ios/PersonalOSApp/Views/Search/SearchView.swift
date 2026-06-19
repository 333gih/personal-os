import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var session: SessionManager
    let onOpen: WebOpenHandler

    @State private var query = ""
    @State private var mode = "hybrid"
    @State private var results: [POSSearchHit] = []
    @State private var resultCount = 0
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var recent: [String] = []
    @State private var errorMessage: String?

    private let recentKey = "com.personalos.recent_searches"

    var body: some View {
        VStack(spacing: 0) {
            searchHeader
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !hasSearched {
                        recentSection
                        if recent.isEmpty {
                            POSEmptyState(systemImage: "magnifyingglass", title: "Search your knowledge", message: "Find courses, projects, and documents.")
                        }
                    } else {
                        resultsSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .onAppear { loadRecent() }
    }

    private var searchHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(POSTheme.muted)
                TextField("Search people, projects, documents…", text: $query)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .onSubmit { runSearch() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(POSTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(POSTheme.border, lineWidth: 1))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    POSChip(title: "Hybrid", isSelected: mode == "hybrid") { mode = "hybrid" }
                    POSChip(title: "Fulltext", isSelected: mode == "fulltext") { mode = "fulltext" }
                    POSChip(title: "Semantic", isSelected: mode == "semantic") { mode = "semantic" }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(POSTheme.background)
    }

    private var recentSection: some View {
        Group {
            if !recent.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    POSSectionHeader(title: "Recent Searches", actionTitle: "Clear all", action: clearRecent)
                    ForEach(recent, id: \.self) { item in
                        Button {
                            query = item
                            runSearch()
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text(item)
                                Spacer()
                            }
                            .padding(14)
                            .background(POSTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(title: "Top Results", eyebrow: isSearching ? "Searching…" : "\(resultCount) results")
            if isSearching {
                POSLoadingView(label: "Searching…")
            } else if let errorMessage {
                POSEmptyState(systemImage: "exclamationmark.triangle", title: "Search failed", message: errorMessage)
            } else if results.isEmpty {
                POSEmptyState(systemImage: "magnifyingglass", title: "No matches", message: "Try another keyword or mode.")
            } else {
                ForEach(results) { hit in
                    Button { onOpen(.entity(hit.entity.id, title: hit.entity.title)) } label: {
                        if hit.entity.type.contains("project") || hit.entity.domain == "startup" {
                            projectCard(hit)
                        } else {
                            POSListRow(
                                title: hit.entity.title,
                                subtitle: hit.matchType,
                                badge: hit.entity.domain.uppercased(),
                                systemImage: "person.fill"
                            )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func projectCard(_ hit: POSSearchHit) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [POSTheme.border, POSTheme.muted.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 120)
                Text(hit.entity.domain.uppercased())
                    .font(.posLabel(9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(12)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(hit.entity.title).font(.posDisplay(18))
                Text(hit.entity.content).font(.caption).foregroundStyle(POSTheme.muted).lineLimit(2)
            }
            .padding(14)
        }
        .background(POSTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: POSTheme.cardRadius))
    }

    private func runSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        saveRecent(trimmed)
        hasSearched = true
        isSearching = true
        errorMessage = nil
        Task {
            do {
                let response = try await session.api.search(query: trimmed, mode: mode)
                results = response.results
                resultCount = response.count
            } catch {
                errorMessage = error.localizedDescription
                results = []
                resultCount = 0
            }
            isSearching = false
        }
    }

    private func loadRecent() {
        recent = UserDefaults.standard.stringArray(forKey: recentKey) ?? []
    }

    private func saveRecent(_ term: String) {
        var list = recent.filter { $0 != term }
        list.insert(term, at: 0)
        list = Array(list.prefix(8))
        recent = list
        UserDefaults.standard.set(list, forKey: recentKey)
    }

    private func clearRecent() {
        recent = []
        UserDefaults.standard.removeObject(forKey: recentKey)
    }
}
