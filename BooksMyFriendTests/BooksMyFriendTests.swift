//
//  BooksMyFriendTests.swift
//  BooksMyFriendTests
//
//  Created by MD TOUFIK HASAN on 5/8/26.
//

import Foundation
import SwiftData
import Testing
import UIKit

@testable import BooksMyFriend

// MARK: - Catalog

struct CatalogTests {

    @Test func everyBookHasContent() {
        #expect(!Catalog.books.isEmpty)

        for book in Catalog.books {
            #expect(!book.chapters.isEmpty, "\(book.title) has no chapters")
            #expect(book.pageCount > 0)
            #expect((0...5).contains(book.rating))

            for chapter in book.chapters {
                #expect(chapter.wordCount > 50, "\(book.title)/\(chapter.title) is too short to paginate")
            }
        }
    }

    @Test func bookIdentifiersAreUnique() {
        let ids = Catalog.books.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func everyShelfReferencesRealBooks() {
        for shelf in Catalog.shelves {
            #expect(!shelf.bookIDs.isEmpty, "\(shelf.title) is empty")
            for id in shelf.bookIDs {
                #expect(Catalog.book(id: id) != nil, "\(shelf.title) references missing book \(id)")
            }
        }
    }

    /// Reading time comes from the page count, not from the bundled sample
    /// text — a 384-page novel must not report twenty minutes.
    @Test func readingTimeReflectsPageCount() throws {
        let book = try #require(Catalog.book(id: "b-lighthouse"))
        #expect(book.estimatedMinutes > 300)

        let chapterTotal = book.chapters.reduce(0) { $0 + book.estimatedMinutes(for: $1) }
        // Rounding per chapter loses a little; it should still land close.
        #expect(abs(chapterTotal - book.estimatedMinutes) < book.chapters.count + 1)
    }

    @Test func proseGenerationIsDeterministic() {
        let first = ProseLibrary.chapterBody(seed: 42, mood: .literary, paragraphs: 8)
        let second = ProseLibrary.chapterBody(seed: 42, mood: .literary, paragraphs: 8)
        let different = ProseLibrary.chapterBody(seed: 43, mood: .literary, paragraphs: 8)

        #expect(first == second, "same seed must produce the same text — highlight ranges depend on it")
        #expect(first != different)
    }
}

// MARK: - Pagination

struct PaginatorTests {
    private let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 17)
    ]

    private func text(_ string: String) -> NSAttributedString {
        NSAttributedString(string: string, attributes: attributes)
    }

    @Test func paginationCoversEveryCharacterExactlyOnce() throws {
        let body = try #require(Catalog.book(id: "b-orbitals")).chapters[0].body
        let pages = Paginator.paginate(text(body), size: CGSize(width: 320, height: 500))

        #expect(pages.count > 1, "a chapter should not fit on one phone page")

        var cursor = 0
        for page in pages {
            #expect(page.location == cursor, "pages must be contiguous")
            #expect(page.length > 0)
            cursor += page.length
        }
        #expect(cursor == (body as NSString).length, "no text may be dropped")
    }

    @Test func smallerPagesProduceMorePages() throws {
        let body = try #require(Catalog.book(id: "b-nightferry")).chapters[0].body

        let large = Paginator.paginate(text(body), size: CGSize(width: 320, height: 700))
        let small = Paginator.paginate(text(body), size: CGSize(width: 320, height: 300))

        #expect(small.count > large.count)
    }

    @Test func degenerateInputsDoNotHang() {
        #expect(Paginator.paginate(text(""), size: CGSize(width: 300, height: 400)).isEmpty)
        #expect(Paginator.paginate(text("Hello"), size: .zero).isEmpty)
    }

    @Test func bookPaginationArithmetic() throws {
        let book = try #require(Catalog.book(id: "b-stillness"))
        let chapters = Paginator.paginateBook(
            chapters: book.chapters.map(\.body),
            attributes: attributes,
            size: CGSize(width: 320, height: 480)
        )
        let pagination = BookPagination(chapters: chapters)

        #expect(pagination.totalPages > 0)
        #expect(pagination.globalPage(chapter: 0, page: 0) == 0)

        // Round-tripping a global page must land back on the same position.
        for target in stride(from: 0, to: pagination.totalPages, by: 3) {
            let position = pagination.position(forGlobalPage: target)
            #expect(pagination.globalPage(chapter: position.chapter, page: position.page) == target)
        }

        // Out-of-range requests clamp instead of trapping.
        let beyond = pagination.position(forGlobalPage: pagination.totalPages + 500)
        #expect(beyond.chapter == chapters.count - 1)

        #expect(pagination.progress(chapter: 0, page: 0) == 0)
        let last = pagination.position(forGlobalPage: pagination.totalPages - 1)
        #expect(pagination.progress(chapter: last.chapter, page: last.page) == 1)
    }
}

// MARK: - Search

struct BookRepositoryTests {
    private let repository = LocalBookRepository()

    @Test func emptyQueryReturnsEverything() {
        #expect(repository.search(BookQuery()).count == Catalog.books.count)
    }

    @Test func titleMatchesOutrankTagMatches() {
        var query = BookQuery()
        query.text = "orbitals"
        let results = repository.search(query)

        #expect(results.first?.id == "b-orbitals")
    }

    @Test func searchMatchesAuthorAndTags() {
        var query = BookQuery()
        query.text = "marguerite"
        #expect(repository.search(query).allSatisfy { $0.author == "Marguerite Hale" })

        query.text = "space opera"
        #expect(!repository.search(query).isEmpty)
    }

    @Test func filtersCompose() {
        var query = BookQuery()
        query.freeOnly = true
        query.minimumRating = 4.5
        query.genres = [.sciFi]

        let results = repository.search(query)
        #expect(!results.isEmpty)
        for book in results {
            #expect(book.isFree)
            #expect(book.rating >= 4.5)
            #expect(book.allGenres.contains(.sciFi))
        }
    }

    @Test func sortOptionsOrderCorrectly() {
        var query = BookQuery()

        query.sort = .topRated
        let byRating = repository.search(query)
        #expect(zip(byRating, byRating.dropFirst()).allSatisfy { $0.rating >= $1.rating })

        query.sort = .newest
        let byYear = repository.search(query)
        #expect(zip(byYear, byYear.dropFirst()).allSatisfy { $0.publishedYear >= $1.publishedYear })

        query.sort = .shortest
        let byLength = repository.search(query)
        #expect(zip(byLength, byLength.dropFirst()).allSatisfy { $0.pageCount <= $1.pageCount })
    }

    @Test func similarBooksExcludeTheSourceAndPreferSameAuthor() throws {
        let book = try #require(repository.book(id: "b-orbitals"))
        let similar = repository.similar(to: book, limit: 6)

        #expect(!similar.contains { $0.id == book.id })
        #expect(similar.contains { $0.id == "b-signalfire" }, "the sequel should rank as similar")
    }

    @Test func nonsenseQueryReturnsNothing() {
        var query = BookQuery()
        query.text = "zzzzqqq"
        #expect(repository.search(query).isEmpty)
    }
}

// MARK: - Library store

/// Serialized: these share one `ModelContainer` and wipe it between tests, so
/// running them concurrently would have them clear each other's fixtures.
@Suite(.serialized)
@MainActor
struct LibraryStoreTests {

    /// A store on a fresh context over the app's shared container, wiped first.
    ///
    /// A second `ModelContainer` for the same models traps at runtime, and the
    /// test host has already built one — so tests share it and get isolation
    /// by clearing the (in-memory, under test) store instead.
    private func makeStore() throws -> LibraryStore {
        let context = ModelContext(PersistenceController.shared)
        try context.delete(model: LibraryItem.self)
        try context.delete(model: Highlight.self)
        try context.delete(model: Bookmark.self)
        try context.delete(model: ReadingSession.self)
        try context.save()
        return LibraryStore(context: context)
    }

    @Test func addingIsIdempotent() throws {
        let store = try makeStore()
        let book = try #require(Catalog.book(id: "b-lighthouse"))

        store.add(book, status: .wantToRead)
        store.add(book, status: .reading)

        #expect(store.items.count == 1)
        #expect(store.status(for: book.id) == .reading)
    }

    @Test func removingAlsoClearsAnnotations() throws {
        let store = try makeStore()
        let book = try #require(Catalog.book(id: "b-lighthouse"))

        store.add(book)
        store.addHighlight(
            bookID: book.id,
            chapterIndex: 0,
            range: NSRange(location: 0, length: 10),
            text: "The lighth",
            color: .yellow
        )
        store.toggleBookmark(book: book, chapterIndex: 0, pageIndex: 1, excerpt: "…")
        #expect(store.highlights.count == 1)
        #expect(store.bookmarks.count == 1)

        store.remove(bookID: book.id)

        #expect(store.items.isEmpty)
        #expect(store.highlights.isEmpty, "orphaned highlights would resurface on re-add")
        #expect(store.bookmarks.isEmpty)
    }

    @Test func progressNeverWalksBackwards() throws {
        let store = try makeStore()
        let book = try #require(Catalog.book(id: "b-orbitals"))
        store.add(book, status: .reading)

        store.updateProgress(bookID: book.id, chapterIndex: 3, pageIndex: 2, fraction: 0.5)
        store.updateProgress(bookID: book.id, chapterIndex: 1, pageIndex: 0, fraction: 0.2)

        let item = try #require(store.item(for: book.id))
        #expect(item.progress == 0.5, "re-reading an earlier page must not lose the furthest point")
        #expect(item.chapterIndex == 1, "but the resume point does follow the reader")
    }

    @Test func reachingTheEndFilesTheBookAsFinished() throws {
        let store = try makeStore()
        let book = try #require(Catalog.book(id: "b-stillness"))
        store.add(book, status: .reading)

        store.updateProgress(bookID: book.id, chapterIndex: 6, pageIndex: 9, fraction: 1.0)

        let item = try #require(store.item(for: book.id))
        #expect(item.status == .finished)
        #expect(item.finishedAt != nil)
    }

    @Test func bookmarksToggle() throws {
        let store = try makeStore()
        let book = try #require(Catalog.book(id: "b-nightferry"))
        store.add(book)

        store.toggleBookmark(book: book, chapterIndex: 2, pageIndex: 4, excerpt: "Kadıköy")
        #expect(store.bookmark(for: book.id, chapterIndex: 2, pageIndex: 4) != nil)

        store.toggleBookmark(book: book, chapterIndex: 2, pageIndex: 4, excerpt: "Kadıköy")
        #expect(store.bookmark(for: book.id, chapterIndex: 2, pageIndex: 4) == nil)
    }

    @Test func veryShortSessionsAreIgnored() throws {
        let store = try makeStore()
        store.recordSession(bookID: "b-orbitals", seconds: 2, pages: 0)
        #expect(store.sessions.isEmpty, "an accidental open should not count as reading")

        store.recordSession(bookID: "b-orbitals", seconds: 120, pages: 4)
        #expect(store.sessions.count == 1)
    }

    @Test func streakCountsConsecutiveDaysAndToleratesAnUnfinishedToday() throws {
        let calendar = Calendar.current

        // Yesterday and the two days before — but nothing today yet.
        let store = try makeStore()
        for offset in 1...3 {
            let date = calendar.date(byAdding: .day, value: -offset, to: .now)!
            store.context.insert(ReadingSession(bookID: "b-orbitals", startedAt: date, seconds: 600))
        }
        store.reload()
        #expect(store.streak == 3)

        // A gap breaks it.
        let store2 = try makeStore()
        let old = calendar.date(byAdding: .day, value: -5, to: .now)!
        store2.context.insert(ReadingSession(bookID: "b-orbitals", startedAt: old, seconds: 600))
        store2.reload()
        #expect(store2.streak == 0)
    }

    @Test func weeklyMinutesAreBucketedByDay() throws {
        let store = try makeStore()
        let calendar = Calendar.current

        store.context.insert(ReadingSession(bookID: "b-orbitals", startedAt: .now, seconds: 1800))
        let yesterday = calendar.date(byAdding: .day, value: -1, to: .now)!
        store.context.insert(ReadingSession(bookID: "b-orbitals", startedAt: yesterday, seconds: 600))
        store.reload()

        let daily = store.dailyMinutes(days: 7)
        #expect(daily.count == 7)
        #expect(daily.last?.minutes == 30)
        #expect(daily[daily.count - 2].minutes == 10)
        #expect(store.minutesReadToday == 30)
    }
}

// MARK: - Formatting

struct FormattingTests {

    @Test func compactCounts() {
        #expect(942.compactCount == "942")
        #expect(12_400.compactCount == "12.4K")
        #expect(1_500_000.compactCount == "1.5M")
    }

    @Test func durationLabels() {
        #expect(45.durationLabel == "45m")
        #expect(120.durationLabel == "2h")
        #expect(154.durationLabel == "2h 34m")
    }

    @Test func achievementsUnlockOnThreshold() {
        let none = Achievement.unlocked(booksFinished: 0, streak: 0, minutes: 0, highlights: 0, librarySize: 0)
        #expect(none.isEmpty)

        let some = Achievement.unlocked(booksFinished: 5, streak: 7, minutes: 600, highlights: 25, librarySize: 10)
        #expect(some.count == 6, "everything but the 30-day streak")
        #expect(!some.contains("streak-30"))
    }
}
