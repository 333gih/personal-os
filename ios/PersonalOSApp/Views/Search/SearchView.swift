import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var session: SessionManager
    let nav: POSNavigationActions

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
        POSScreen {
            VStack(spacing: 0) {
                searchHeader
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !hasSearched {
                            recentSection
                            if recent.isEmpty {
                                POSEmptyState(
                                    systemImage: "magnifyingglass",
                                    title: "Search your notebook",
                                    message: "Find people, projects, study notes, and documents across your library.",
                                    actionTitle: "Browse inbox",
                                    action: { nav.onOpen(.path("/inbox", title: "Inbox")) }
                                )
                            }
                        } else {
                            resultsSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .onAppear { loadRecent() }
        .onChange(of: mode) { _ in
            if hasSearched, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                runSearch()
            }
        }
    }

    private var searchHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(POSTheme.muted)
                TextField("Search notes, projects, people…", text: $query)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .onSubmit { runSearch() }
                if !query.isEmpty {
                    Button {
                        query = ""
                        hasSearched = false
                        results = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(POSTheme.muted)
                    }
                    .buttonStyle(POSPressButtonStyle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(POSTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(POSTheme.border, lineWidth: 1))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    POSChip(title: "Hybrid", isSelected: mode == "hybrid") { mode = "hybrid" }
                    POSChip(title: "Full text", isSelected: mode == "fulltext") { mode = "fulltext" }
                    POSChip(title: "Semantic", isSelected: mode == "semantic") { mode = "semantic" }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var recentSection: some View {
        Group {
            if !recent.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    POSSectionHeader(title: "Recent", actionTitle: "Clear") {
                        clearRecent()
                    }
                    ForEach(recent, id: \.self) { item in
                        Button {
                            query = item
                            runSearch()
                        } label: {
                            HStack {
                                Image(systemName: "clock")
                                Text(item)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .font(.caption)
                                    .foregroundStyle(POSTheme.muted)
                            }
                            .padding(14)
                            .background(POSTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(POSTheme.border, lineWidth: 1))
                        }
                        .buttonStyle(POSPressButtonStyle())
                    }
                }
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(
                title: "Results",
                eyebrow: isSearching ? "Searching…" : "\(resultCount) found"
            )
            if isSearching {
                POSLoadingView(label: "Looking through your library…")
            } else if let errorMessage {
                POSEmptyState(
                    systemImage: "exclamationmark.triangle",
                    title: "Search interrupted",
                    message: errorMessage,
                    actionTitle: "Try again",
                    action: runSearch
                )
            } else if results.isEmpty {
                POSEmptyState(
                    systemImage: "doc.text.magnifyingglass",
                    title: "Nothing matched",
                    message: "Try another phrase or switch the search mode.",
                    actionTitle: "Clear search",
                    action: {
                        query = ""
                        hasSearched = false
                    }
                )
            } else {
                ForEach(results) { hit in
                    Button { nav.onOpen(.entity(hit.entity.id, title: hit.entity.title)) } label: {
                        if hit.entity.type.contains("project") || hit.entity.domain == "startup" {
                            projectCard(hit)
                        } else {
                            POSListRow(
                                title: hit.entity.title,
                                subtitle: "\(POSFormatting.domainLabel(hit.entity.domain)) · \(hit.matchType)",
                                badge: POSFormatting.humanType(hit.entity.type),
                                systemImage: icon(for: hit.entity)
                            )
                        }
                    }
                    .buttonStyle(POSPressButtonStyle())
                }
            }
        }
    }

    private func icon(for entity: POSEntity) -> String {
        if entity.domain == "learning" { return "book" }
        if entity.domain == "work" { return "briefcase" }
        if entity.domain == "entertainment" { return "book.closed" }
        return "doc.text"
    }

    private func projectCard(_ hit: POSSearchHit) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 0)
                    .fill(POSTheme.border.opacity(0.55))
                    .frame(height: 108)
                Text(POSFormatting.domainLabel(hit.entity.domain))
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(POSTheme.card)
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
        .overlay(RoundedRectangle(cornerRadius: POSTheme.cardRadius).stroke(POSTheme.border, lineWidth: 1))
    }

    private func runSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        POSHaptics.light()
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
        POSHaptics.selection()
        recent = []
        UserDefaults.standard.removeObject(forKey: recentKey)
    }
}
