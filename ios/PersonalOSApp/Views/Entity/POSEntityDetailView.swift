import SwiftUI

enum POSEntityDetailSection: String, CaseIterable, Hashable {
    case overview = "Overview"
    case architecture = "Design"
    case related = "Related"
}

struct POSEntityDetailView: View {
    @EnvironmentObject private var session: SessionManager
    let entityId: String
    var initialSection: POSEntityDetailSection = .overview
    let onOpenEntity: (String, String) -> Void
    let onClose: () -> Void

    @State private var detail: POSEntityDetailResponse?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var section: POSEntityDetailSection = .overview

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    POSLoadingView(label: "Loading detail…")
                } else if let loadError {
                    POSEmptyState(
                        systemImage: "exclamationmark.triangle",
                        title: "Could not load",
                        message: loadError,
                        actionTitle: "Retry",
                        action: { Task { await load() } }
                    )
                } else if let detail {
                    detailBody(detail)
                }
            }
            .background(POSTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { onClose() }
                }
                ToolbarItem(placement: .principal) {
                    Text(detail?.entity.title ?? "Detail")
                        .font(.headline)
                        .lineLimit(1)
                }
            }
        }
        .task(id: entityId) {
            section = initialSection
            await load()
        }
    }

    @ViewBuilder
    private func detailBody(_ detail: POSEntityDetailResponse) -> some View {
        let entity = detail.entity
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero(entity)
                if hasArchitecture(entity) {
                    sectionPicker
                }
                switch section {
                case .overview:
                    overviewSection(entity)
                case .architecture:
                    architectureSection(entity)
                case .related:
                    relatedSection(detail)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    private func hero(_ entity: POSEntity) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Label(entity.typeLabel, systemImage: entity.typeIcon)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(POSTheme.primary.opacity(0.1))
                    .foregroundStyle(POSTheme.primaryDark)
                    .clipShape(Capsule())
                if entity.isActiveWork {
                    Text("Active")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(POSTheme.successBg)
                        .foregroundStyle(POSTheme.success)
                        .clipShape(Capsule())
                }
                Spacer()
            }
            Text(entity.title)
                .font(.posDisplay(26))
            if let subtitle = entity.detailSubtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(POSTheme.muted)
            }
            if !entity.tagList.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(entity.tagList, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(POSTheme.border.opacity(0.4))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var sectionPicker: some View {
        HStack(spacing: 8) {
            ForEach(availableSections, id: \.self) { tab in
                POSChip(title: tab.rawValue, isSelected: section == tab) {
                    section = tab
                }
            }
        }
    }

    private var availableSections: [POSEntityDetailSection] {
        var tabs: [POSEntityDetailSection] = [.overview]
        if let entity = detail?.entity, hasArchitecture(entity) {
            tabs.append(.architecture)
        }
        if let relations = detail?.relations, !relations.isEmpty {
            tabs.append(.related)
        }
        return tabs
    }

    private func overviewSection(_ entity: POSEntity) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if hasArchitecture(entity) {
                POSCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("System preview", systemImage: "square.grid.2x2")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(POSTheme.primaryDark)
                        POSArchitectureDiagram(
                            layers: entity.architectureLayers,
                            imageURL: entity.designImageURL(),
                            style: .compact
                        )
                        POSActionButton(title: "Open full diagram", icon: "arrow.up.right", style: .secondary) {
                            section = .architecture
                        }
                    }
                }
            }
            POSCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Details", systemImage: "doc.text")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(POSTheme.primaryDark)
                    Text(entity.content)
                        .font(.body)
                        .foregroundStyle(POSTheme.ink)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            metadataGrid(entity)
        }
    }

    @ViewBuilder
    private func metadataGrid(_ entity: POSEntity) -> some View {
        let rows = entity.metadataRows
        if !rows.isEmpty {
            POSCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Metadata", systemImage: "list.bullet.rectangle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(POSTheme.primaryDark)
                    ForEach(rows, id: \.label) { row in
                        HStack(alignment: .top) {
                            Text(row.label)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(POSTheme.muted)
                                .frame(width: 88, alignment: .leading)
                            Text(row.value)
                                .font(.subheadline)
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }

    private func architectureSection(_ entity: POSEntity) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            POSCard {
                POSArchitectureDiagram(
                    layers: entity.architectureLayers,
                    imageURL: entity.designImageURL(),
                    style: .full
                )
            }
            if !entity.content.isEmpty {
                POSCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Context")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(POSTheme.muted)
                        Text(entity.content)
                            .font(.subheadline)
                            .foregroundStyle(POSTheme.ink)
                            .lineSpacing(4)
                    }
                }
            }
        }
    }

    private func relatedSection(_ detail: POSEntityDetailResponse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(detail.relations) { relation in
                Button {
                    onOpenEntity(relation.relatedEntity.id, relation.relatedEntity.title)
                } label: {
                    POSListRow(
                        title: relation.relatedEntity.title,
                        subtitle: relation.relationLabel,
                        badge: relation.relatedEntity.typeLabel,
                        systemImage: relation.relatedEntity.typeIcon,
                        iconTint: POSTheme.primaryDark
                    )
                }
                .buttonStyle(POSPressButtonStyle())
            }
        }
    }

    private func hasArchitecture(_ entity: POSEntity) -> Bool {
        !entity.architectureLayers.isEmpty || entity.designImageURL() != nil
    }

    private func load() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            detail = try await session.api.entityDetail(id: entityId)
        } catch {
            loadError = error.localizedDescription
        }
    }
}
