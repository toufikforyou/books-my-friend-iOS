//
//  CollectionScreens.swift
//  BooksMyFriend
//
//  The three "list of books" destinations: a genre, an author, and a curated
//  shelf. They share one grid so a book looks the same wherever it is reached.
//

import SwiftUI

// MARK: - Genre

struct GenreDetailView: View {
    let genre: Genre

    private let repository: BookRepository = LocalBookRepository()
    @State private var sort: SortOption = .topRated

    private var books: [Book] {
        var query = BookQuery()
        query.genres = [genre]
        query.sort = sort
        return repository.search(query)
    }

    var body: some View {
        BookCollectionGrid(
            books: books,
            sort: $sort,
            header: {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: genre.symbol)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                LinearGradient(
                                    colors: [genre.tint, genre.tint.mix(with: .black, by: 0.3)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(genre.rawValue)
                                .font(AppFont.serif(26, .bold))
                                .foregroundStyle(Palette.textPrimary)
                            Text("\(books.count) books")
                                .font(.system(size: 13))
                                .foregroundStyle(Palette.textTertiary)
                        }
                    }
                }
            }
        )
        .navigationTitle(genre.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Author

struct AuthorDetailView: View {
    let author: String

    private let repository: BookRepository = LocalBookRepository()
    @State private var sort: SortOption = .newest

    private var books: [Book] {
        let all = repository.byAuthor(author, excluding: nil)
        return switch sort {
        case .topRated: all.sorted { $0.rating > $1.rating }
        case .mostRead: all.sorted { $0.readerCount > $1.readerCount }
        case .titleAZ: all.sorted { $0.title < $1.title }
        case .shortest: all.sorted { $0.pageCount < $1.pageCount }
        default: all
        }
    }

    private var averageRating: Double {
        guard !books.isEmpty else { return 0 }
        return books.reduce(0) { $0 + $1.rating } / Double(books.count)
    }

    private var initials: String {
        author.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }

    private var tint: Color {
        books.first?.genre.tint ?? Palette.accent
    }

    var body: some View {
        BookCollectionGrid(
            books: books,
            sort: $sort,
            header: {
                VStack(spacing: Spacing.md) {
                    Text(initials)
                        .font(AppFont.rounded(28, .bold))
                        .foregroundStyle(.white)
                        .frame(width: 84, height: 84)
                        .background(
                            LinearGradient(colors: [tint, tint.mix(with: .black, by: 0.3)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: Circle()
                        )

                    VStack(spacing: 3) {
                        Text(author)
                            .font(AppFont.serif(24, .bold))
                            .foregroundStyle(Palette.textPrimary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: Spacing.sm) {
                            Text("\(books.count) book\(books.count == 1 ? "" : "s")")
                            Text("·")
                            StarRatingView(rating: averageRating, size: 10, showsValue: true)
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.textTertiary)
                    }

                    if let genres = topGenres, !genres.isEmpty {
                        FlowStack(spacing: Spacing.sm, alignment: .center) {
                            ForEach(genres) { genre in
                                TagChip(title: genre.rawValue, symbol: genre.symbol, tint: genre.tint)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        )
        .navigationTitle(author)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var topGenres: [Genre]? {
        let counts = Dictionary(grouping: books.map(\.genre)) { $0 }.mapValues(\.count)
        return counts.sorted { $0.value > $1.value }.prefix(3).map(\.key)
    }
}

// MARK: - Curated shelf

struct ShelfDetailView: View {
    let shelf: Shelf

    @State private var sort: SortOption = .relevance

    private var books: [Book] {
        let all = shelf.bookIDs.compactMap { Catalog.book(id: $0) }
        return switch sort {
        case .topRated: all.sorted { $0.rating > $1.rating }
        case .mostRead: all.sorted { $0.readerCount > $1.readerCount }
        case .newest: all.sorted { $0.publishedYear > $1.publishedYear }
        case .titleAZ: all.sorted { $0.title < $1.title }
        case .shortest: all.sorted { $0.pageCount < $1.pageCount }
        case .relevance: all  // curated order is the point of a shelf
        }
    }

    var body: some View {
        BookCollectionGrid(
            books: books,
            sort: $sort,
            header: {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(shelf.title)
                        .font(AppFont.serif(28, .bold))
                        .foregroundStyle(Palette.textPrimary)
                    if let subtitle = shelf.subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.textSecondary)
                    }
                    Text("\(books.count) books")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.textTertiary)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        )
        .navigationTitle(shelf.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shared grid

/// One grid, three callers. `header` is generic so each screen supplies its own
/// masthead without duplicating the grid, sort control and empty state.
struct BookCollectionGrid<Header: View>: View {
    let books: [Book]
    @Binding var sort: SortOption
    @ViewBuilder let header: () -> Header

    @Environment(LibraryStore.self) private var library

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header()
                    .pageHorizontalPadding()
                    .padding(.top, Spacing.sm)

                if books.isEmpty {
                    EmptyStateView(
                        symbol: "books.vertical",
                        title: "Nothing here yet",
                        message: "This collection is empty right now. Check back soon."
                    )
                } else {
                    HStack {
                        Text("\(books.count) book\(books.count == 1 ? "" : "s")")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Palette.textTertiary)
                        Spacer()
                        Menu {
                            Picker("Sort", selection: $sort) {
                                ForEach(SortOption.allCases) { option in
                                    Label(option.rawValue, systemImage: option.symbol).tag(option)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: sort.symbol).font(.system(size: 11))
                                Text(sort.rawValue).font(.system(size: 13, weight: .semibold))
                                Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(Palette.accent)
                        }
                    }
                    .pageHorizontalPadding()

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 104, maximum: 150), spacing: Spacing.lg)],
                        alignment: .leading,
                        spacing: Spacing.xl
                    ) {
                        ForEach(books) { book in
                            let progress = library.progress(for: book.id)
                            BookCard(book: book, width: 112, progress: progress > 0 ? progress : nil)
                        }
                    }
                    .pageHorizontalPadding()
                }

                Color.clear.frame(height: Spacing.xl)
            }
        }
        .scrollIndicators(.hidden)
        .background(Palette.background)
    }
}
