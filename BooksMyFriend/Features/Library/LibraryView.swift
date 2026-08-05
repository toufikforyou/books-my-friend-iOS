//
//  LibraryView.swift
//  BooksMyFriend
//

import SwiftUI

struct LibraryView: View {
    @Environment(AppState.self) private var appState
    @Environment(LibraryStore.self) private var library

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case reading = "Reading"
        case wantToRead = "Saved"
        case finished = "Finished"
        case downloaded = "Offline"

        var id: String { rawValue }

        var symbol: String {
            switch self {
            case .all: "square.stack"
            case .reading: "book.fill"
            case .wantToRead: "bookmark.fill"
            case .finished: "checkmark.seal.fill"
            case .downloaded: "arrow.down.circle.fill"
            }
        }
    }

    enum SortMode: String, CaseIterable, Identifiable {
        case recent = "Recently opened"
        case added = "Date added"
        case title = "Title"
        case author = "Author"
        case progress = "Progress"

        var id: String { rawValue }
    }

    @State private var filter: Filter = .all
    @State private var sort: SortMode = .recent
    @State private var isGrid = true
    @State private var searchText = ""

    var body: some View {
        Group {
            // Grid mode is a scroll view; list mode is a real `List` so rows
            // get native swipe actions rather than a hand-rolled imitation.
            if isGrid || entries.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        filterBar

                        if entries.isEmpty {
                            emptyState
                        } else {
                            countRow
                            gridContent
                        }

                        Color.clear.frame(height: Spacing.xl)
                    }
                    .padding(.top, Spacing.sm)
                }
                .scrollIndicators(.hidden)
            } else {
                listContent
            }
        }
        .background(Palette.background)
        .navigationTitle("Library")
        .searchable(text: $searchText, prompt: "Find in your library")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort by", selection: $sort) {
                        ForEach(SortMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Divider()
                    Picker("Layout", selection: $isGrid) {
                        Label("Grid", systemImage: "square.grid.2x2").tag(true)
                        Label("List", systemImage: "list.bullet").tag(false)
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                }
                .accessibilityLabel("Sort and layout")
            }
        }
    }

    // MARK: - Content

    private var filterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.sm) {
                ForEach(Filter.allCases) { option in
                    FilterChip(
                        title: "\(option.rawValue) \(count(for: option))",
                        symbol: option.symbol,
                        isSelected: filter == option
                    ) {
                        withAnimation(.snappy(duration: 0.25)) { filter = option }
                    }
                }
            }
            .pageHorizontalPadding()
        }
        .scrollIndicators(.hidden)
    }

    private var countRow: some View {
        HStack {
            Text("\(entries.count) book\(entries.count == 1 ? "" : "s")")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.textTertiary)
            Spacer()
            Text(sort.rawValue)
                .font(.system(size: 13))
                .foregroundStyle(Palette.textTertiary)
        }
        .pageHorizontalPadding()
    }

    private var gridContent: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 104, maximum: 150), spacing: Spacing.lg)],
            alignment: .leading,
            spacing: Spacing.xl
        ) {
            ForEach(entries, id: \.item.bookID) { entry in
                LibraryGridCell(book: entry.book, item: entry.item)
            }
        }
        .pageHorizontalPadding()
    }

    private var listContent: some View {
        List {
            Section {
                ForEach(entries, id: \.item.bookID) { entry in
                    LibraryListRow(book: entry.book, item: entry.item)
                        .listRowInsets(EdgeInsets(top: 0, leading: Spacing.page, bottom: 0, trailing: Spacing.page))
                        .listRowBackground(Palette.background)
                }
            } header: {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    filterBar
                        .listRowInsets(EdgeInsets())
                    countRow
                }
                .padding(.bottom, Spacing.sm)
                .textCase(nil)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 1)
    }

    private var emptyState: some View {
        EmptyStateView(
            symbol: emptySymbol,
            title: emptyTitle,
            message: emptyMessage,
            actionTitle: "Browse the catalog"
        ) {
            appState.selectedTab = .discover
        }
    }

    // MARK: - Data

    private struct Entry {
        let item: LibraryItem
        let book: Book
    }

    private var entries: [Entry] {
        var result = library.items.compactMap { item -> Entry? in
            guard let book = Catalog.book(id: item.bookID) else { return nil }
            return Entry(item: item, book: book)
        }

        result = result.filter { entry in
            switch filter {
            case .all: true
            case .reading: entry.item.status == .reading
            case .wantToRead: entry.item.status == .wantToRead
            case .finished: entry.item.status == .finished
            case .downloaded: entry.item.isDownloaded
            }
        }

        let needle = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !needle.isEmpty {
            result = result.filter { $0.book.searchHaystack.contains(needle) }
        }

        return result.sorted { lhs, rhs in
            switch sort {
            case .recent:
                (lhs.item.lastOpenedAt ?? lhs.item.addedAt) > (rhs.item.lastOpenedAt ?? rhs.item.addedAt)
            case .added:
                lhs.item.addedAt > rhs.item.addedAt
            case .title:
                lhs.book.title.localizedCaseInsensitiveCompare(rhs.book.title) == .orderedAscending
            case .author:
                lhs.book.author.localizedCaseInsensitiveCompare(rhs.book.author) == .orderedAscending
            case .progress:
                lhs.item.progress > rhs.item.progress
            }
        }
    }

    private func count(for option: Filter) -> String {
        let value = switch option {
        case .all: library.items.count
        case .reading: library.items(status: .reading).count
        case .wantToRead: library.items(status: .wantToRead).count
        case .finished: library.items(status: .finished).count
        case .downloaded: library.items.filter(\.isDownloaded).count
        }
        return value == 0 ? "" : "\(value)"
    }

    private var emptySymbol: String {
        searchText.isEmpty ? filter.symbol : "magnifyingglass"
    }

    private var emptyTitle: String {
        if !searchText.isEmpty { return "No matches" }
        return switch filter {
        case .all: "Your library is empty"
        case .reading: "Nothing in progress"
        case .wantToRead: "Nothing saved yet"
        case .finished: "No finished books"
        case .downloaded: "Nothing downloaded"
        }
    }

    private var emptyMessage: String {
        if !searchText.isEmpty { return "No book in your library matches “\(searchText)”." }
        return switch filter {
        case .all: "Books you add, download or start reading will collect here."
        case .reading: "Open any book and it will show up here with your progress."
        case .wantToRead: "Tap the bookmark on a book to save it for later."
        case .finished: "Finish a book and it will be filed here with your rating."
        case .downloaded: "Download a book to read it without a connection."
        }
    }
}

// MARK: - Grid cell

struct LibraryGridCell: View {
    let book: Book
    let item: LibraryItem

    @Environment(AppState.self) private var appState
    @Environment(LibraryStore.self) private var library

    var body: some View {
        Button {
            appState.openBook(book)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ProgressCoverView(book: book, progress: item.progress, width: 112)
                    .overlay(alignment: .topTrailing) {
                        HStack(spacing: 3) {
                            if item.isFavorite {
                                badge("heart.fill", Palette.rose)
                            }
                            if item.isDownloaded {
                                badge("arrow.down", Palette.sapphire)
                            }
                        }
                        .padding(6)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title)
                        .font(.cardTitle)
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(book.author)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.textTertiary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: item.status.symbol)
                            .font(.system(size: 9))
                        Text(statusLabel)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(item.status.tint)
                    .padding(.top, 1)
                }
                .frame(width: 112, alignment: .leading)
            }
        }
        .buttonStyle(PressableCardStyle())
        .contextMenu { BookContextMenu(book: book) }
    }

    private var statusLabel: String {
        switch item.status {
        case .reading: "\(item.progressPercent)%"
        case .wantToRead: "Saved"
        case .finished: item.personalRating > 0 ? "\(item.personalRating)★" : "Finished"
        }
    }

    private func badge(_ symbol: String, _ tint: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(tint, in: Circle())
    }
}

// MARK: - List row

struct LibraryListRow: View {
    let book: Book
    let item: LibraryItem

    @Environment(LibraryStore.self) private var library
    @Environment(AppState.self) private var appState

    var body: some View {
        BookListRow(
            book: book,
            progress: item.progress,
            trailingBadge: AnyView(
                VStack(spacing: Spacing.sm) {
                    if item.status == .reading, item.progress > 0 {
                        ProgressRing(progress: item.progress, size: 40, lineWidth: 3.5)
                    } else {
                        Image(systemName: item.status.symbol)
                            .font(.system(size: 15))
                            .foregroundStyle(item.status.tint)
                            .frame(width: 40, height: 40)
                            .background(item.status.tint.opacity(0.12), in: Circle())
                    }
                    if item.isDownloaded {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.sapphire)
                    }
                }
            )
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                library.remove(bookID: book.id)
                Haptics.warning()
            } label: {
                Label("Remove", systemImage: "trash")
            }

            Button {
                library.toggleDownload(bookID: book.id)
            } label: {
                Label(item.isDownloaded ? "Remove" : "Download",
                      systemImage: item.isDownloaded ? "arrow.down.circle.fill" : "arrow.down.circle")
            }
            .tint(Palette.sapphire)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                appState.read(book, chapter: item.chapterIndex, page: item.pageIndex)
            } label: {
                Label("Read", systemImage: "book.fill")
            }
            .tint(Palette.accent)

            Button {
                library.toggleFavorite(bookID: book.id)
            } label: {
                Label("Favorite", systemImage: item.isFavorite ? "heart.slash" : "heart")
            }
            .tint(Palette.rose)
        }
    }
}
