//
//  DiscoverView.swift
//  BooksMyFriend
//
//  The home screen: a greeting, whatever the reader has in progress, then
//  curated shelves — with the reader's onboarding genres pulled to the top.
//

import SwiftUI

struct DiscoverView: View {
    @Environment(AppState.self) private var appState
    @Environment(LibraryStore.self) private var library

    private let repository: BookRepository = LocalBookRepository()
    @State private var quoteIndex = Int.random(in: 0..<Catalog.quotes.count)

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xxl) {
                greeting

                if !library.continueReading.isEmpty {
                    continueReadingSection
                }

                ForEach(orderedShelves) { shelf in
                    shelfSection(shelf)
                }

                browseByGenre
                quoteCard

                Color.clear.frame(height: Spacing.xl)
            }
            .padding(.top, Spacing.sm)
        }
        .scrollIndicators(.hidden)
        .background(Palette.background)
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appState.selectedTab = .profile
                } label: {
                    Image(systemName: "person.crop.circle")
                }
                .accessibilityLabel("Your profile")
            }
        }
    }

    // MARK: - Sections

    private var greeting: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(timeOfDayGreeting)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.textTertiary)

            Text("What will you read today?")
                .font(.displayTitle)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if library.streak > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.accent)
                    Text("\(library.streak)-day streak")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                    if library.minutesReadToday > 0 {
                        Text("· \(library.minutesReadToday) min today")
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.textTertiary)
                    }
                }
                .padding(.top, Spacing.xs)
            }
        }
        .pageHorizontalPadding()
    }

    private var continueReadingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Continue Reading", subtitle: "Pick up where you left off")
                .pageHorizontalPadding()

            ScrollView(.horizontal) {
                HStack(spacing: Spacing.md) {
                    ForEach(library.continueReading.prefix(6), id: \.bookID) { item in
                        if let book = repository.book(id: item.bookID) {
                            ContinueReadingCard(book: book, item: item)
                        }
                    }
                }
                .pageHorizontalPadding()
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
        }
    }

    @ViewBuilder
    private func shelfSection(_ shelf: Shelf) -> some View {
        let books = shelf.bookIDs.compactMap { repository.book(id: $0) }

        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(
                title: shelf.title,
                subtitle: shelf.subtitle,
                actionTitle: "See all"
            ) {
                appState.push(.shelf(shelf.id))
            }
            .pageHorizontalPadding()

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: shelf.style == .ranked ? Spacing.sm : Spacing.md) {
                    switch shelf.style {
                    case .hero:
                        ForEach(books) { HeroBookCard(book: $0) }
                    case .standard:
                        ForEach(books) { BookCard(book: $0) }
                    case .ranked:
                        ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                            RankedBookCard(book: book, rank: index + 1)
                        }
                    case .compact:
                        // Three per column, scrolling sideways — fits six titles
                        // in the space one row of covers would take.
                        ForEach(columns(of: books, size: 3), id: \.first?.id) { column in
                            VStack(spacing: Spacing.lg) {
                                ForEach(column) { CompactBookRow(book: $0) }
                            }
                        }
                    }
                }
                .pageHorizontalPadding()
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
        }
    }

    private var browseByGenre: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Browse by Genre", subtitle: "\(Genre.allCases.count) categories")
                .pageHorizontalPadding()

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: Spacing.md),
                          GridItem(.flexible(), spacing: Spacing.md)],
                spacing: Spacing.md
            ) {
                ForEach(Genre.allCases) { genre in
                    GenreTile(genre: genre) { appState.push(.genre(genre)) }
                }
            }
            .pageHorizontalPadding()
        }
    }

    private var quoteCard: some View {
        let quote = Catalog.quotes[quoteIndex % Catalog.quotes.count]

        return VStack(alignment: .leading, spacing: Spacing.md) {
            Image(systemName: "quote.opening")
                .font(.system(size: 22))
                .foregroundStyle(Palette.accent.opacity(0.5))

            Text(quote.text)
                .font(AppFont.serif(19, .medium))
                .foregroundStyle(Palette.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Text("— \(quote.source)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                .fill(Palette.accentSoft)
        )
        .pageHorizontalPadding()
        .onTapGesture {
            withAnimation(.smooth) { quoteIndex += 1 }
            Haptics.tap()
        }
        .accessibilityHint("Tap for another quote")
    }

    // MARK: - Helpers

    /// Shelves matching the reader's chosen genres float to the top, so the
    /// onboarding step visibly changes the feed.
    private var orderedShelves: [Shelf] {
        let preferred = appState.preferredGenres
        guard !preferred.isEmpty else { return Catalog.shelves }

        return Catalog.shelves.enumerated()
            .sorted { lhs, rhs in
                let lhsScore = affinity(lhs.element, preferred)
                let rhsScore = affinity(rhs.element, preferred)
                // Keep the spotlight first regardless; it is the editorial slot.
                if lhs.element.style == .hero { return true }
                if rhs.element.style == .hero { return false }
                if lhsScore != rhsScore { return lhsScore > rhsScore }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    private func affinity(_ shelf: Shelf, _ preferred: Set<Genre>) -> Int {
        shelf.bookIDs
            .compactMap { repository.book(id: $0) }
            .reduce(0) { $0 + (preferred.isDisjoint(with: Set($1.allGenres)) ? 0 : 1) }
    }

    private func columns(of books: [Book], size: Int) -> [[Book]] {
        stride(from: 0, to: books.count, by: size).map {
            Array(books[$0..<min($0 + size, books.count)])
        }
    }

    private var timeOfDayGreeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        case 17..<22: "Good evening"
        default: "Late night reading"
        }
    }
}

// MARK: - Continue reading card

struct ContinueReadingCard: View {
    let book: Book
    let item: LibraryItem

    @Environment(AppState.self) private var appState

    private var chapterTitle: String {
        book.chapters.indices.contains(item.chapterIndex)
            ? book.chapters[item.chapterIndex].title
            : "Chapter \(item.chapterIndex + 1)"
    }

    /// Rough remaining time from the fraction still unread.
    private var minutesLeft: Int {
        max(1, Int(Double(book.estimatedMinutes) * (1 - item.progress)))
    }

    var body: some View {
        Button {
            appState.read(book, chapter: item.chapterIndex, page: item.pageIndex)
        } label: {
            HStack(spacing: Spacing.md) {
                BookCoverView(book: book, width: 68)

                VStack(alignment: .leading, spacing: 5) {
                    Text(book.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)

                    Text(chapterTitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.textTertiary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    HStack(spacing: Spacing.sm) {
                        ProgressView(value: item.progress)
                            .progressViewStyle(.linear)
                            .tint(Palette.accent)
                        Text("\(item.progressPercent)%")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.accent)
                            .monospacedDigit()
                    }

                    Text("\(minutesLeft.durationLabel) left")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Palette.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Palette.accent)
            }
            .padding(Spacing.md)
            .frame(width: 300, height: 128)
            .cardBackground()
        }
        .buttonStyle(PressableCardStyle())
        .contextMenu { BookContextMenu(book: book) }
        .accessibilityLabel("Continue \(book.title), \(item.progressPercent) percent complete")
    }
}

// MARK: - Genre tile

struct GenreTile: View {
    let genre: Genre
    let action: () -> Void

    private var bookCount: Int {
        Catalog.books.filter { $0.allGenres.contains(genre) }.count
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: genre.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(genre.tint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text(genre.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                    Text("\(bookCount) books")
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardBackground(Radius.md)
        }
        .buttonStyle(PressableCardStyle(scale: 0.97))
    }
}

#Preview {
    NavigationStack {
        DiscoverView()
    }
    .environment(AppState())
    .environment(ReaderSettings())
}
