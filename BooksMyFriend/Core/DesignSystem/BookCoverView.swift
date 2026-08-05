//
//  BookCoverView.swift
//  BooksMyFriend
//
//  Covers are drawn rather than downloaded: the catalog ships no artwork, and
//  a generated cover keeps grids visually consistent, works offline, renders
//  instantly, and adapts to Dynamic Type. Each book's `coverSeed` picks a
//  stable layout, so a title always looks the same everywhere in the app.
//

import SwiftUI

struct BookCoverView: View {
    let book: Book
    var width: CGFloat = Metrics.cardWidth
    var showsShadow: Bool = true

    private var height: CGFloat { width / Metrics.coverAspect }

    /// Five layouts, chosen by seed. Enough variety that a grid never looks
    /// templated, few enough that each one can be tuned properly.
    private var variant: Int { book.coverSeed % 5 }

    /// Hue-shifted from the genre tint so two books in the same genre still
    /// read as different objects on a shelf.
    private var baseColor: Color { book.genre.tint }

    var body: some View {
        ZStack {
            background
            motif
            textBlock
            spine
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: Radius.cover, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.cover, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 0.75)
        )
        .applyIf(showsShadow) { $0.coverShadow() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(book.title) by \(book.author)")
    }

    // MARK: - Layers

    private var background: some View {
        LinearGradient(
            colors: [
                baseColor.opacity(0.95),
                baseColor.mix(with: .black, by: 0.35),
            ],
            startPoint: variant % 2 == 0 ? .topLeading : .top,
            endPoint: variant % 2 == 0 ? .bottomTrailing : .bottom
        )
        .overlay(
            // Paper grain: a faint radial lift stops flat gradients looking
            // like a placeholder rectangle.
            RadialGradient(
                colors: [.white.opacity(0.22), .clear],
                center: .init(x: 0.3, y: 0.15),
                startRadius: 0,
                endRadius: width * 1.2
            )
        )
    }

    @ViewBuilder
    private var motif: some View {
        switch variant {
        case 0:
            // Concentric arcs sweeping off the top-right corner.
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .strokeBorder(.white.opacity(0.18 - Double(index) * 0.04), lineWidth: width * 0.03)
                        .frame(width: width * (0.75 + CGFloat(index) * 0.42))
                        .offset(x: width * 0.32, y: -height * 0.28)
                }
            }
        case 1:
            // Horizon band.
            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(.white.opacity(0.16))
                    .frame(height: height * 0.16)
                Rectangle()
                    .fill(.black.opacity(0.18))
                    .frame(height: height * 0.26)
            }
        case 2:
            // Diagonal ribbon.
            Rectangle()
                .fill(.white.opacity(0.14))
                .frame(width: width * 1.6, height: height * 0.14)
                .rotationEffect(.degrees(-32))
                .offset(y: height * 0.2)
        case 3:
            // Rule grid — quiet, works well for non-fiction.
            VStack(spacing: height * 0.055) {
                ForEach(0..<7, id: \.self) { index in
                    Rectangle()
                        .fill(.white.opacity(index == 2 ? 0.3 : 0.09))
                        .frame(height: 1)
                }
            }
            .padding(.horizontal, width * 0.14)
            .offset(y: height * 0.26)
        default:
            // Large glyph, heavily faded — a genre watermark.
            Image(systemName: book.genre.symbol)
                .font(.system(size: width * 0.72, weight: .light))
                .foregroundStyle(.white.opacity(0.12))
                .offset(x: width * 0.18, y: height * 0.22)
        }
    }

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: width * 0.045) {
            Text(book.author.uppercased())
                .font(.system(size: max(6, width * 0.062), weight: .semibold))
                .tracking(width * 0.008)
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(1)

            Text(book.title)
                .font(.system(size: max(11, width * 0.125), weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .lineLimit(4)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(.white.opacity(0.6))
                .frame(width: width * 0.22, height: 1.5)
                .padding(.top, width * 0.01)

            Spacer(minLength: 0)
        }
        .padding(width * 0.11)
        .frame(width: width, height: height, alignment: .topLeading)
        .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
    }

    /// The dark inner edge that reads as a bound spine.
    private var spine: some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [.black.opacity(0.28), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width * 0.07)
            Spacer()
        }
    }
}

// MARK: - Progress-aware cover

/// A cover with the reader's progress drawn along the bottom edge. Used
/// anywhere a book in progress appears.
struct ProgressCoverView: View {
    let book: Book
    let progress: Double
    var width: CGFloat = Metrics.cardWidth

    var body: some View {
        BookCoverView(book: book, width: width)
            .overlay(alignment: .bottom) {
                if progress > 0 {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(.black.opacity(0.35))
                        GeometryReader { proxy in
                            Rectangle()
                                .fill(Palette.accent)
                                .frame(width: proxy.size.width * progress)
                        }
                    }
                    .frame(height: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .padding(.horizontal, 6)
                    .padding(.bottom, 6)
                }
            }
    }
}

#Preview("Cover variants") {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ForEach(Catalog.books.prefix(6)) { book in
                BookCoverView(book: book, width: 140)
            }
        }
        .padding(30)
    }
    .background(Palette.background)
}
