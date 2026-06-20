import SwiftUI

enum POSArchitectureStyle {
    case compact
    case full
}

struct POSArchitectureDiagram: View {
    let layers: [POSArchitectureLayer]
    var imageURL: URL?
    var style: POSArchitectureStyle = .full

    @State private var viewMode: DiagramMode = .flow

    private enum DiagramMode: String, CaseIterable {
        case flow = "Flow"
        case stack = "Layers"
        case reference = "Reference"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if style == .full, !layers.isEmpty, imageURL != nil {
                Picker("View", selection: $viewMode) {
                    ForEach(DiagramMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            switch effectiveMode {
            case .reference:
                referenceImage
            case .flow:
                POSArchitectureFlowCanvas(layers: layers, compact: style == .compact)
            case .stack:
                POSArchitectureStackCanvas(layers: layers, compact: style == .compact)
            }
        }
    }

    private var effectiveMode: DiagramMode {
        if style == .compact { return layers.isEmpty ? .reference : .flow }
        if imageURL == nil { return layers.isEmpty ? .flow : viewMode == .reference ? .flow : viewMode }
        if layers.isEmpty { return .reference }
        return viewMode
    }

    @ViewBuilder
    private var referenceImage: some View {
        if let imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                case .failure:
                    POSArchitectureFlowCanvas(layers: layers, compact: style == .compact)
                default:
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 140)
                }
            }
        }
    }
}

// MARK: - Flow canvas (left-to-right pipeline per layer, stacked vertically)

private struct POSArchitectureFlowCanvas: View {
    let layers: [POSArchitectureLayer]
    var compact: Bool

    private let layerColors: [Color] = [
        Color(red: 0.69, green: 0.20, blue: 0.27),
        Color(red: 0.23, green: 0.40, blue: 0.55),
        Color(red: 0.28, green: 0.52, blue: 0.42),
        Color(red: 0.55, green: 0.38, blue: 0.62),
        Color(red: 0.72, green: 0.48, blue: 0.22),
    ]

    var body: some View {
        VStack(spacing: compact ? 6 : 10) {
            ForEach(Array(layers.enumerated()), id: \.element.id) { index, layer in
                VStack(spacing: 6) {
                    layerBand(layer, color: layerColors[index % layerColors.count])
                    if index < layers.count - 1 {
                        Image(systemName: "arrow.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(POSTheme.muted.opacity(0.7))
                    }
                }
            }
        }
    }

    private func layerBand(_ layer: POSArchitectureLayer, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(color.opacity(0.85))
                    .frame(width: 8, height: 8)
                Text(layer.layer)
                    .font(compact ? .caption2.weight(.bold) : .caption.weight(.bold))
                    .foregroundStyle(color)
                    .textCase(.uppercase)
                Spacer()
                Text("\(layer.nodes.count) nodes")
                    .font(.caption2)
                    .foregroundStyle(POSTheme.muted)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(layer.nodes.enumerated()), id: \.offset) { nodeIndex, node in
                        HStack(spacing: 6) {
                            POSArchitectureNodeChip(name: node, accent: color, compact: compact)
                            if nodeIndex < layer.nodes.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(POSTheme.muted.opacity(0.55))
                            }
                        }
                    }
                }
            }
        }
        .padding(compact ? 10 : 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Stack canvas (grid nodes per layer)

private struct POSArchitectureStackCanvas: View {
    let layers: [POSArchitectureLayer]
    var compact: Bool

    var body: some View {
        VStack(spacing: compact ? 8 : 12) {
            ForEach(layers) { layer in
                VStack(alignment: .leading, spacing: 8) {
                    Text(layer.layer.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(POSTheme.primaryDark)
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: compact ? 88 : 100), spacing: 8)],
                        spacing: 8
                    ) {
                        ForEach(layer.nodes, id: \.self) { node in
                            POSArchitectureNodeChip(
                                name: node,
                                accent: POSTheme.primaryDark,
                                compact: compact,
                                vertical: true
                            )
                        }
                    }
                }
                .padding(compact ? 10 : 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(POSTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(POSTheme.border.opacity(0.65), lineWidth: 1)
                )
            }
        }
    }
}

private struct POSArchitectureNodeChip: View {
    let name: String
    var accent: Color = POSTheme.primaryDark
    var compact: Bool = false
    var vertical: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: POSArchitectureIcons.symbol(for: name))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(accent)
            Text(name)
                .font(compact ? .caption2 : .caption)
                .foregroundStyle(POSTheme.ink)
                .lineLimit(vertical ? 3 : 1)
                .multilineTextAlignment(vertical ? .center : .leading)
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 5 : 7)
        .frame(maxWidth: vertical ? .infinity : nil)
        .background(POSTheme.background.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(accent.opacity(0.2), lineWidth: 1)
        )
    }
}

enum POSArchitectureIcons {
    static func symbol(for name: String) -> String {
        let key = name.lowercased()
        if key.contains("aem") || key.contains("cms") { return "doc.richtext" }
        if key.contains("spring") || key.contains("java") { return "leaf.fill" }
        if key.contains("nest") || key.contains("node") { return "server.rack" }
        if key.contains("mongo") || key.contains("postgres") || key.contains("sql") { return "cylinder.fill" }
        if key.contains("redis") || key.contains("cache") { return "bolt.fill" }
        if key.contains("rabbit") || key.contains("kafka") || key.contains("queue") { return "arrow.triangle.branch" }
        if key.contains("gcp") || key.contains("aws") || key.contains("cloud") { return "cloud.fill" }
        if key.contains("search") || key.contains("algolia") || key.contains("elastic") { return "magnifyingglass" }
        if key.contains("api") || key.contains("gateway") { return "point.3.connected.trianglepath.dotted" }
        if key.contains("nft") || key.contains("block") { return "link" }
        if key.contains("iot") || key.contains("device") { return "sensor.tag.radiowaves.forward.fill" }
        if key.contains("web") || key.contains("next") || key.contains("react") { return "globe" }
        if key.contains("ftp") || key.contains("file") { return "folder.fill" }
        return "cube.fill"
    }
}
