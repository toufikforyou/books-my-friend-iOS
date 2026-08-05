//
//  BookRepository.swift
//  BooksMyFriend
//
//  The UI never touches `Catalog` directly — it goes through this protocol, so
//  the bundled catalog can be replaced by a network-backed store without any
//  view changes.
//

import Foundation

// MARK: - Query types

enum SortOption: String, CaseIterable, Identifiable {
    case relevance = "Relevance"
    case topRated = "Top Rated"
    case mostRead = "Most Read"
    case newest = "Newest"
    case titleAZ = "Title A–Z"
    case shortest = "Shortest"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .relevance: "sparkle.magnifyingglass"
        case .topRated: "star.fill"
        case .mostRead: "flame.fill"
        case .newest: "clock.badge.checkmark"
        case .titleAZ: "textformat.abc"
        case .shortest: "hourglass"
        }
    }
}

struct BookQuery {
    var text: String = ""
    var genres: Set<Genre> = []
    var freeOnly: Bool = false
    var minimumRating: Double = 0
    var sort: SortOption = .relevance

    var hasActiveFilters: Bool {
        !genres.isEmpty || freeOnly || minimumRating > 0 || sort != .relevance
    }

    var activeFilterCount: Int {
        genres.count + (freeOnly ? 1 : 0) + (minimumRating > 0 ? 1 : 0)
    }
}

// MARK: - Protocol

protocol BookRepository: Sendable {
    func allBooks() -> [Book]
    func book(id: String) -> Book?
    func shelves() -> [Shelf]
    func search(_ query: BookQuery) -> [Book]
    func books(in genre: Genre) -> [Book]
    func similar(to book: Book, limit: Int) -> [Book]
    func byAuthor(_ author: String, excluding bookID: String?) -> [Book]
}

// MARK: - Local implementation

struct LocalBookRepository: BookRepository {

    func allBooks() -> [Book] { Catalog.books }

    func book(id: String) -> Book? { Catalog.book(id: id) }

    func shelves() -> [Shelf] { Catalog.shelves }

    func books(in genre: Genre) -> [Book] {
        Catalog.books
            .filter { $0.allGenres.contains(genre) }
            .sorted { $0.rating > $1.rating }
    }

    func search(_ query: BookQuery) -> [Book] {
        let needle = query.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        var results = Catalog.books.filter { book in
            if query.freeOnly && !book.isFree { return false }
            if book.rating < query.minimumRating { return false }
            if !query.genres.isEmpty && query.genres.isDisjoint(with: Set(book.allGenres)) {
                return false
            }
            guard !needle.isEmpty else { return true }
            return book.searchHaystack.contains(needle)
        }

        results.sort { lhs, rhs in
            switch query.sort {
            case .relevance:
                // With a query, rank exact-ish title matches first; without one,
                // relevance degrades to a popularity blend.
                if !needle.isEmpty {
                    let lhsScore = relevanceScore(lhs, needle: needle)
                    let rhsScore = relevanceScore(rhs, needle: needle)
                    if lhsScore != rhsScore { return lhsScore > rhsScore }
                }
                return popularity(lhs) > popularity(rhs)
            case .topRated:
                if lhs.rating != rhs.rating { return lhs.rating > rhs.rating }
                return lhs.ratingCount > rhs.ratingCount
            case .mostRead:
                return lhs.readerCount > rhs.readerCount
            case .newest:
                if lhs.publishedYear != rhs.publishedYear { return lhs.publishedYear > rhs.publishedYear }
                return lhs.title < rhs.title
            case .titleAZ:
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            case .shortest:
                return lhs.pageCount < rhs.pageCount
            }
        }

        return results
    }

    func similar(to book: Book, limit: Int = 6) -> [Book] {
        let genres = Set(book.allGenres)
        let tags = Set(book.tags)

        var scored: [(book: Book, score: Int)] = []
        for candidate in Catalog.books where candidate.id != book.id {
            var score = genres.intersection(Set(candidate.allGenres)).count * 3
            score += tags.intersection(Set(candidate.tags)).count * 2
            if candidate.author == book.author { score += 4 }
            if score > 0 { scored.append((candidate, score)) }
        }

        scored.sort { lhs, rhs in
            lhs.score == rhs.score ? lhs.book.rating > rhs.book.rating : lhs.score > rhs.score
        }
        return scored.prefix(limit).map(\.book)
    }

    func byAuthor(_ author: String, excluding bookID: String?) -> [Book] {
        Catalog.books
            .filter { $0.author == author && $0.id != bookID }
            .sorted { $0.publishedYear > $1.publishedYear }
    }

    // MARK: - Ranking

    private func relevanceScore(_ book: Book, needle: String) -> Int {
        var score = 0
        let title = book.title.lowercased()
        if title == needle { score += 100 }
        else if title.hasPrefix(needle) { score += 60 }
        else if title.contains(needle) { score += 40 }
        if book.author.lowercased().contains(needle) { score += 30 }
        if book.genre.rawValue.lowercased().contains(needle) { score += 15 }
        if book.tags.contains(where: { $0.lowercased().contains(needle) }) { score += 10 }
        return score
    }

    /// Ratings alone let a 4.9 with 3k reviews outrank a 4.8 with 40k, which is
    /// not what "popular" means to a reader. Weight by volume.
    private func popularity(_ book: Book) -> Double {
        book.rating * log(Double(book.readerCount) + 10)
    }
}
