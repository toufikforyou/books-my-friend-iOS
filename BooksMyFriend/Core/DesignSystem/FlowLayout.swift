//
//  FlowLayout.swift
//  BooksMyFriend
//
//  Wrapping horizontal layout for chips and tags. A `Layout` rather than a
//  stack of `HStack`s so it reflows correctly at every Dynamic Type size and
//  on rotation without any width guessing at the call site.
//

import SwiftUI

/// View wrapper around `FlowLayout`.
///
/// A trailing closure written directly after a `Layout` type name binds to its
/// initializer, not to `callAsFunction`, so the layout is applied to a value
/// held in a local instead.
struct FlowStack<Content: View>: View {
    var spacing: CGFloat = Spacing.sm
    var lineSpacing: CGFloat = Spacing.sm
    var alignment: HorizontalAlignment = .leading
    @ViewBuilder var content: Content

    var body: some View {
        let layout = FlowLayout(spacing: spacing, lineSpacing: lineSpacing, alignment: alignment)
        layout { content }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = Spacing.sm
    var lineSpacing: CGFloat = Spacing.sm
    var alignment: HorizontalAlignment = .leading

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = arrange(subviews: subviews, maxWidth: maxWidth)

        let height = rows.reduce(into: CGFloat.zero) { total, row in
            total += row.height
        } + lineSpacing * CGFloat(max(0, rows.count - 1))

        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: min(maxWidth, max(width, 0)), height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = arrange(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY

        for row in rows {
            var x: CGFloat = switch alignment {
            case .center: bounds.minX + (bounds.width - row.width) / 2
            case .trailing: bounds.maxX - row.width
            default: bounds.minX
            }

            for element in row.elements {
                subviews[element.index].place(
                    at: CGPoint(x: x, y: y + (row.height - element.size.height) / 2),
                    proposal: ProposedViewSize(element.size)
                )
                x += element.size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    // MARK: - Row building

    private struct Element {
        let index: Int
        let size: CGSize
    }

    private struct Row {
        var elements: [Element] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.elements.isEmpty ? size.width : current.width + spacing + size.width

            if needed > maxWidth, !current.elements.isEmpty {
                rows.append(current)
                current = Row()
                current.elements = [Element(index: index, size: size)]
                current.width = size.width
                current.height = size.height
            } else {
                current.elements.append(Element(index: index, size: size))
                current.width = needed
                current.height = max(current.height, size.height)
            }
        }

        if !current.elements.isEmpty { rows.append(current) }
        return rows
    }
}
