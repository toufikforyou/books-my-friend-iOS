//
//  BookCards.swift
//  BooksMyFriend
//
//  The four ways a book is presented in a list. Every one of them pushes the
//  same route, so tapping a book behaves identically wherever it appears.
//

import SwiftUI

// MARK: - Standard portrait card

struct BookCard: View {
    let book: Book
    var width: CGFloat = Metrics.cardWidth
    var showsRating: Bool = true
    var progress: Double? = nil

    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            appState.openBook(book)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let progress {
                    ProgressCoverView(book: book, progress: progress, width: width)
                } else {
                    BookCoverView(book: book, width: width)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title)
                        .font(.cardTitle)
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(book.author)
                        .font(.cardSubtitle)
                        .foregroundStyle(Palette.textTertiary)
                        .lineLimit(1)

                    if showsRating {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Palette.star)
                            Text(book.rating.oneDecimal)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Palette.textSecondary)
                            if book.isFree {
                                Text("· Free")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Palette.sapphire)
                            }
                        }
                        .padding(.top, 1)
                    }
                }
                .frame(width: width, alignment: .leading)
            }
        }
        .buttonStyle(PressableCardStyle())
        .contextMenu { BookContextMenu(book: book) }
    }
}

// MARK: - Hero card

/// Wide editorial card for the top of Discover. Shows the cover beside a
/// summary because at this size the cover alone wastes the space.
struct HeroBookCard: View {
    let book: Book
    var width: CGFloat = Metrics.heroWidth

    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            appState.openBook(book)
        } label: {
            HStack(alignment: .top, spacing: Spacing.md) {
                BookCoverView(book: book, width: 96)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    TagChip(title: book.genre.rawValue, tint: book.genre.tint)
                        .padding(.bottom, 2)

                    Text(book.title)
                        .font(AppFont.serif(17, .semibold))
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(book.author)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.textTertiary)

                    Spacer(minLength: Spacing.xs)

                    Text(book.synopsis)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)

                    StarRatingView(rating: book.rating, size: 10, showsValue: true, count: book.ratingCount)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Spacing.md)
            .frame(width: width, height: 178, alignment: .topLeading)
            .cardBackground()
        }
        .buttonStyle(PressableCardStyle())
        .contextMenu { BookContextMenu(book: book) }
    }
}

// MARK: - Ranked card

struct RankedBookCard: View {
    let book: Book
    let rank: Int

    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            appState.openBook(book)
        } label: {
            HStack(alignment: .bottom, spacing: -14) {
                Text("\(rank)")
                    .font(.system(size: 62, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.textPrimary.opacity(0.12))
                    .frame(width: 46, alignment: .leading)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    BookCoverView(book: book, width: 104)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(book.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Palette.textPrimary)
                            .lineLimit(1)
                        Text(book.author)
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.textTertiary)
                            .lineLimit(1)
                    }
                    .frame(width: 104, alignment: .leading)
                }
            }
        }
        .buttonStyle(PressableCardStyle())
        .contextMenu { BookContextMenu(book: book) }
    }
}

// MARK: - Compact row

struct CompactBookRow: View {
    let book: Book
    var width: CGFloat = 268
    var showsChevron: Bool = false

    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            appState.openBook(book)
        } label: {
            HStack(spacing: Spacing.md) {
                BookCoverView(book: book, width: 46)

                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                    Text(book.author)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.textTertiary)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        Text(book.estimatedMinutes.durationLabel)
                            .font(.system(size: 11, weight: .medium))
                        Text("·").foregroundStyle(Palette.separator)
                        Text("\(book.pageCount) pages")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(Palette.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.textTertiary)
                }
            }
            .applyIf(width > 0) { $0.frame(width: width) }
        }
        .buttonStyle(PressableCardStyle())
        .contextMenu { BookContextMenu(book: book) }
    }
}

// MARK: - List row (full width, used in Library and search results)

struct BookListRow: View {
    let book: Book
    var progress: Double? = nil
    var trailingBadge: AnyView? = nil

    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            appState.openBook(book)
        } label: {
            HStack(alignment: .top, spacing: Spacing.md) {
                if let progress {
                    ProgressCoverView(book: book, progress: progress, width: 62)
                } else {
                    BookCoverView(book: book, width: 62)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(book.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(book.author)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        StarRatingView(rating: book.rating, size: 9)
                        Text(book.rating.oneDecimal)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Palette.textSecondary)
                        Text("·").foregroundStyle(Palette.textTertiary)
                        Text(book.genre.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Palette.textTertiary)
                    }
                    .padding(.top, 1)

                    HStack(spacing: 6) {
                        Text(book.priceLabel)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(book.isFree ? Palette.sapphire : Palette.accent)
                        if let progress, progress > 0 {
                            Text("· \(Int(progress * 100))% read")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Palette.textTertiary)
                        }
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let trailingBadge {
                    trailingBadge
                }
            }
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle(scale: 0.99))
        .contextMenu { BookContextMenu(book: book) }
    }
}

// MARK: - Shared context menu

struct BookContextMenu: View {
    let book: Book
    @Environment(LibraryStore.self) private var library
    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            appState.read(book)
        } label: {
            Label(library.progress(for: book.id) > 0 ? "Continue Reading" : "Start Reading",
                  systemImage: "book.fill")
        }

        if let item = library.item(for: book.id) {
            ForEach(ShelfStatus.allCases) { status in
                Button {
                    library.setStatus(status, for: book.id)
                    Haptics.success()
                } label: {
                    Label(status.rawValue, systemImage: item.status == status ? "checkmark" : status.symbol)
                }
            }

            Button {
                library.toggleDownload(bookID: book.id)
            } label: {
                Label(item.isDownloaded ? "Remove Download" : "Download",
                      systemImage: item.isDownloaded ? "trash" : "arrow.down.circle")
            }

            Divider()

            Button(role: .destructive) {
                library.remove(bookID: book.id)
                Haptics.warning()
            } label: {
                Label("Remove from Library", systemImage: "minus.circle")
            }
        } else {
            Button {
                library.add(book, status: .wantToRead)
                Haptics.success()
            } label: {
                Label("Add to Library", systemImage: "plus.circle")
            }
        }
    }
}

// MARK: - Press feedback

/// Cards get a subtle press scale instead of the default button dimming, which
/// looks wrong on artwork.
struct PressableCardStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}
