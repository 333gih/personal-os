import SwiftUI

/// Compact mobile project row — no nested horizontal scroll (prevents layout overflow).
struct WorkProjectCard: View {
    let item: POSEntity
    let isPrimary: Bool
    let onOpen: () -> Void
    let onArchitecture: () -> Void

    private var hasArchitecture: Bool {
        !item.architectureLayers.isEmpty || item.designImageURL() != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)
                                .foregroundStyle(POSTheme.ink)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(projectSubtitle(item))
                                .font(.caption)
                                .foregroundStyle(POSTheme.muted)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 8)
                        statusBadge
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(POSTheme.muted.opacity(0.7))
                    }

                    if !item.tagList.isEmpty {
                        WorkTagWrap(tags: Array(item.tagList.prefix(4)))
                    }

                    if hasArchitecture {
                        WorkArchitecturePreview(entity: item)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(POSPressButtonStyle())

            if hasArchitecture {
                Divider().padding(.horizontal, 14)
                Button(action: onArchitecture) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2")
                        Text("View architecture")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(POSTheme.primaryDark)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(POSPressButtonStyle())
            }
        }
        .background(POSTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: POSTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: POSTheme.cardRadius, style: .continuous)
                .stroke(POSTheme.border.opacity(0.75), lineWidth: 1)
        )
        .shadow(color: POSTheme.paperShadow.opacity(0.06), radius: 8, y: 2)
    }

    private var statusBadge: some View {
        Text(item.isActiveWork ? "Active" : "Done")
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isPrimary && item.isActiveWork ? POSTheme.successBg : POSTheme.border.opacity(0.45))
            .foregroundStyle(isPrimary && item.isActiveWork ? POSTheme.success : POSTheme.muted)
            .clipShape(Capsule())
    }

    private func projectSubtitle(_ item: POSEntity) -> String {
        let parts = [item.metadata?.company, item.metadata?.role, item.metadata?.periodLabel()]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.joined(separator: " · ")
    }
}

/// Wrapping tags — fits screen width, no horizontal scroll.
private struct WorkTagWrap: View {
    let tags: [String]

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(POSTheme.border.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}

/// One-line architecture hint for list cards.
private struct WorkArchitecturePreview: View {
    let entity: POSEntity

    var body: some View {
        if !entity.architectureLayers.isEmpty {
            layerPreview
        } else if let url = entity.designImageURL() {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                case .failure:
                    EmptyView()
                default:
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 80)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(POSTheme.border.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var layerPreview: some View {
        let layers = entity.architectureLayers.prefix(1)
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(layers.enumerated()), id: \.offset) { _, layer in
                Text(layer.layer.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(POSTheme.primaryDark.opacity(0.85))
                FlowLayout(spacing: 6) {
                    ForEach(layer.nodes.prefix(5), id: \.self) { node in
                        HStack(spacing: 4) {
                            Image(systemName: POSArchitectureIcons.symbol(for: node))
                                .font(.system(size: 9))
                            Text(node)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(POSTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(POSTheme.border.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(POSTheme.border.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// Simple flow layout for tags/chips on narrow screens.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = max(proposal.width ?? 320, 1)
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
