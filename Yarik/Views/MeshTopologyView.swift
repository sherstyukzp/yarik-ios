//
// MeshTopologyView.swift
// yarik
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

/// Display model for the mesh topology map: nodes are known mesh peers,
/// edges are gossiped `directNeighbors` claims. Built on the main actor from
/// a `MeshTopologySnapshot` plus the current nickname table.
struct MeshTopologyDisplayModel {
    struct Node: Identifiable, Equatable {
        let id: String
        let label: String
        let isSelf: Bool
    }

    let nodes: [Node]
    /// Pairs of `Node.id`; every id is present in `nodes`.
    let edges: [(String, String)]

    static let empty = MeshTopologyDisplayModel(nodes: [], edges: [])
}

/// Native mesh graph: self in the center, neighbors on a ring.
struct MeshTopologyView: View {
    /// Fetches a fresh model; called on appear, refresh, and a short poll.
    let provider: @MainActor () -> MeshTopologyDisplayModel
    @State private var model: MeshTopologyDisplayModel = .empty

    var body: some View {
        VStack(spacing: 16) {
            if model.nodes.count <= 1 {
                Spacer()
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("topology.empty")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            } else {
                graphCanvas
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 8)
            }

            VStack(spacing: 4) {
                Text(summaryText)
                    .font(.subheadline.weight(.semibold))
                Text("topology.caption")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .navigationTitle(
            String(localized: "yarik.topology.title", defaultValue: "Мережа поруч", comment: "Title of the nearby Bluetooth mesh map")
        )
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    reload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel(Text("topology.refresh"))
            }
        }
        .onAppear(perform: reload)
        .onReceive(Timer.publish(every: 2, on: .main, in: .common).autoconnect()) { _ in
            reload()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(summaryText))
    }

    private func reload() {
        model = provider()
    }

    private var summaryText: String {
        String(
            format: String(
                localized: "topology.summary",
                comment: "Topology map summary: number of peers and links"
            ),
            locale: .current,
            model.nodes.count,
            model.edges.count
        )
    }

    private var graphCanvas: some View {
        Canvas { context, size in
            let positions = Self.layout(nodes: model.nodes, in: size)

            for (fromID, toID) in model.edges {
                guard let from = positions[fromID], let to = positions[toID] else { continue }
                var path = Path()
                path.move(to: from)
                path.addLine(to: to)
                context.stroke(path, with: .color(Color.secondary.opacity(0.45)), lineWidth: 1)
            }

            for node in model.nodes {
                guard let center = positions[node.id] else { continue }
                let radius: CGFloat = node.isSelf ? 7 : 5
                let dot = Path(ellipseIn: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                context.fill(dot, with: .color(node.isSelf ? Color.accentColor : Color.primary))
                if node.isSelf {
                    let ring = Path(ellipseIn: CGRect(
                        x: center.x - radius - 3,
                        y: center.y - radius - 3,
                        width: (radius + 3) * 2,
                        height: (radius + 3) * 2
                    ))
                    context.stroke(ring, with: .color(Color.accentColor.opacity(0.6)), lineWidth: 1)
                }
                context.draw(
                    Text(node.label)
                        .font(.caption2)
                        .foregroundColor(node.isSelf ? Color.accentColor : Color.secondary),
                    at: CGPoint(x: center.x, y: center.y + radius + 4),
                    anchor: .top
                )
            }
        }
        .accessibilityHidden(true)
    }

    /// Circular layout: self in the center, everyone else evenly spaced on a
    /// ring. Deterministic (nodes arrive sorted), so refreshes don't shuffle.
    static func layout(nodes: [MeshTopologyDisplayModel.Node], in size: CGSize) -> [String: CGPoint] {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = max(20, min(size.width, size.height) / 2 - 36)
        var positions: [String: CGPoint] = [:]

        let ringNodes = nodes.filter { !$0.isSelf }
        for node in nodes where node.isSelf {
            positions[node.id] = center
        }
        for (index, node) in ringNodes.enumerated() {
            let angle = (2 * CGFloat.pi * CGFloat(index)) / CGFloat(max(1, ringNodes.count)) - CGFloat.pi / 2
            positions[node.id] = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
        }
        return positions
    }
}

#Preview("Topology") {
    NavigationStack {
        MeshTopologyView(provider: {
            MeshTopologyDisplayModel(
                nodes: [
                    .init(id: "self", label: "me", isSelf: true),
                    .init(id: "a", label: "alice", isSelf: false),
                    .init(id: "b", label: "bob", isSelf: false),
                    .init(id: "c", label: "carol", isSelf: false)
                ],
                edges: [("self", "a"), ("a", "b"), ("self", "c")]
            )
        })
    }
}
