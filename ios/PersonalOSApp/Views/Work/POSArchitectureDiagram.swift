import SwiftUI

struct POSArchitectureDiagram: View {
    let layers: [POSArchitectureLayer]
    var imageURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure:
                        layerStack
                    default:
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 120)
                    }
                }
            } else if !layers.isEmpty {
                layerStack
            }
        }
    }

    private var layerStack: some View {
        VStack(spacing: 8) {
            ForEach(layers) { item in
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.layer.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(POSTheme.primaryDark)
                    POSArchitectureFlowRow(nodes: item.nodes)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(POSTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(POSTheme.border.opacity(0.6), lineWidth: 1)
                )
            }
        }
    }
}

private struct POSArchitectureFlowRow: View {
    let nodes: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(nodes, id: \.self) { node in
                    Text(node)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(POSTheme.border.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}

struct POSProjectArchitectureSheet: View {
    let project: POSEntity
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(project.content)
                        .font(.subheadline)
                        .foregroundStyle(POSTheme.muted)
                    POSArchitectureDiagram(
                        layers: project.architectureLayers,
                        imageURL: project.designImageURL()
                    )
                }
                .padding(16)
            }
            .background(POSTheme.background)
            .navigationTitle(project.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
