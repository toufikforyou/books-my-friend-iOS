//
//  LibraryStore.swift
//  BooksMyFriend
//
//  All SwiftData writes funnel through here. Views observe it rather than
//  calling `modelContext` directly, which keeps mutation logic (status
//  transitions, progress roll-up, session accounting) in one testable place.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class LibraryStore {
    /// Internal rather than private so first-launch seeding can insert
    /// historical rows that bypass the live-reading guards below.
    let context: ModelContext

    /// Mirrors of the persisted state. Kept in memory so list views can filter
    /// and sort without issuing a fetch per row.
    private(set) var items: [LibraryItem] = []
    private(set) var highlights: [Highlight] = []
    private(set) var bookmarks: [Bookmark] = []
    private(set) var sessions: [ReadingSession] = []

    init(context: ModelContext) {
        self.context = context
        reload()
    }

    // MARK: - Loading

    func reload() {
        items = (try? context.fetch(FetchDescriptor<LibraryItem>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        ))) ?? []
        highlights = (try? context.fetch(FetchDescriptor<Highlight>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        ))) ?? []
        bookmarks = (try? context.fetch(FetchDescriptor<Bookmark>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        ))) ?? []
        sessions = (try? context.fetch(FetchDescriptor<ReadingSession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        ))) ?? []
    }

    private func save() {
        do {
            try context.save()
        } catch {
            // A failed local save should never take the app down; surfacing it
            // in the console is enough for a store this size.
            print("LibraryStore save failed: \(error)")
        }
        reload()
    }

    // MARK: - Queries

    func item(for bookID: String) -> LibraryItem? {
        items.first { $0.bookID == bookID }
    }

    func isInLibrary(_ bookID: String) -> Bool {
        item(for: bookID) != nil
    }

    func status(for bookID: String) -> ShelfStatus? {
        item(for: bookID)?.status
    }

    func progress(for bookID: String) -> Double {
        item(for: bookID)?.progress ?? 0
    }

    func items(status: ShelfStatus) -> [LibraryItem] {
        items.filter { $0.status == status }
    }

    /// Books with progress, most recently opened first — drives "Continue Reading".
    var continueReading: [LibraryItem] {
        items
            .filter { $0.status == .reading && $0.progress > 0 }
            .sorted { ($0.lastOpenedAt ?? $0.addedAt) > ($1.lastOpenedAt ?? $1.addedAt) }
    }

    func highlights(for bookID: String) -> [Highlight] {
        highlights.filter { $0.bookID == bookID }
    }

    func highlights(for bookID: String, chapterIndex: Int) -> [Highlight] {
        highlights.filter { $0.bookID == bookID && $0.chapterIndex == chapterIndex }
    }

    func bookmarks(for bookID: String) -> [Bookmark] {
        bookmarks.filter { $0.bookID == bookID }
    }

    func bookmark(for bookID: String, chapterIndex: Int, pageIndex: Int) -> Bookmark? {
        bookmarks.first {
            $0.bookID == bookID && $0.chapterIndex == chapterIndex && $0.pageIndex == pageIndex
        }
    }

    // MARK: - Library mutations

    @discardableResult
    func add(_ book: Book, status: ShelfStatus = .wantToRead) -> LibraryItem {
        if let existing = item(for: book.id) {
            existing.status = status
            save()
            return existing
        }
        let item = LibraryItem(bookID: book.id, status: status)
        context.insert(item)
        save()
        return item
    }

    func remove(bookID: String) {
        guard let item = item(for: bookID) else { return }
        context.delete(item)
        // Reading artefacts belong to the item conceptually; drop them together
        // so a re-add starts clean rather than resurrecting stale ranges.
        highlights(for: bookID).forEach(context.delete)
        bookmarks(for: bookID).forEach(context.delete)
        save()
    }

    func setStatus(_ status: ShelfStatus, for bookID: String) {
        guard let item = item(for: bookID) else { return }
        item.status = status
        if status == .finished {
            item.progress = 1
            item.finishedAt = .now
        } else if status == .wantToRead {
            item.finishedAt = nil
        }
        save()
    }

    func toggleFavorite(bookID: String) {
        guard let item = item(for: bookID) else { return }
        item.isFavorite.toggle()
        save()
    }

    func toggleDownload(bookID: String) {
        guard let item = item(for: bookID) else { return }
        item.isDownloaded.toggle()
        save()
    }

    func rate(_ rating: Int, bookID: String) {
        guard let item = item(for: bookID) else { return }
        item.personalRating = rating
        save()
    }

    // MARK: - Reading progress

    /// Called when the reader opens a book. Adds it to the library implicitly —
    /// a reader who is reading a book expects to find it on their shelf.
    @discardableResult
    func beginReading(_ book: Book) -> LibraryItem {
        let item = self.item(for: book.id) ?? add(book, status: .reading)
        if item.status == .wantToRead { item.status = .reading }
        item.lastOpenedAt = .now
        save()
        return item
    }

    func updateProgress(bookID: String, chapterIndex: Int, pageIndex: Int, fraction: Double) {
        guard let item = item(for: bookID) else { return }
        item.chapterIndex = chapterIndex
        item.pageIndex = pageIndex
        // Never walk progress backwards on a re-read of an earlier page — the
        // furthest point reached is the more useful number for a progress bar.
        item.progress = max(item.progress, min(1, fraction))
        item.lastOpenedAt = .now
        if item.progress >= 0.995, item.status != .finished {
            item.status = .finished
            item.finishedAt = .now
        }
        save()
    }

    func recordSession(bookID: String, seconds: Int, pages: Int) {
        guard seconds > 5 else { return }  // ignore incidental opens
        let session = ReadingSession(bookID: bookID, seconds: seconds, pagesRead: pages)
        context.insert(session)
        item(for: bookID)?.secondsRead += seconds
        save()
    }

    // MARK: - Highlights & bookmarks

    func addHighlight(
        bookID: String,
        chapterIndex: Int,
        range: NSRange,
        text: String,
        color: HighlightColor
    ) {
        let highlight = Highlight(
            bookID: bookID,
            chapterIndex: chapterIndex,
            range: range,
            text: text,
            color: color
        )
        context.insert(highlight)
        save()
    }

    func update(highlight: Highlight, color: HighlightColor? = nil, note: String? = nil) {
        if let color { highlight.color = color }
        if let note { highlight.note = note }
        save()
    }

    func delete(highlight: Highlight) {
        context.delete(highlight)
        save()
    }

    func toggleBookmark(book: Book, chapterIndex: Int, pageIndex: Int, excerpt: String) {
        if let existing = bookmark(for: book.id, chapterIndex: chapterIndex, pageIndex: pageIndex) {
            context.delete(existing)
        } else {
            let chapterTitle = book.chapters.indices.contains(chapterIndex)
                ? book.chapters[chapterIndex].title
                : "Chapter \(chapterIndex + 1)"
            context.insert(
                Bookmark(
                    bookID: book.id,
                    chapterIndex: chapterIndex,
                    pageIndex: pageIndex,
                    chapterTitle: chapterTitle,
                    excerpt: excerpt
                )
            )
        }
        save()
    }

    func delete(bookmark: Bookmark) {
        context.delete(bookmark)
        save()
    }

    // MARK: - Statistics

    var booksFinished: Int {
        items.filter { $0.status == .finished }.count
    }

    var booksFinishedThisYear: Int {
        let year = Calendar.current.component(.year, from: .now)
        return items.filter {
            guard let finishedAt = $0.finishedAt else { return false }
            return Calendar.current.component(.year, from: finishedAt) == year
        }.count
    }

    var totalMinutesRead: Int {
        sessions.reduce(0) { $0 + $1.seconds } / 60
    }

    var minutesReadToday: Int {
        let today = Calendar.current.startOfDay(for: .now)
        return sessions.filter { $0.day == today }.reduce(0) { $0 + $1.seconds } / 60
    }

    /// Minutes read per day for the last `days` days, oldest first.
    func dailyMinutes(days: Int = 7) -> [(date: Date, minutes: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<days).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let seconds = sessions.filter { $0.day == date }.reduce(0) { $0 + $1.seconds }
            return (date, seconds / 60)
        }
    }

    /// Consecutive days ending today (or yesterday) with any reading recorded.
    var streak: Int {
        let calendar = Calendar.current
        let daysWithReading = Set(sessions.map(\.day))
        guard !daysWithReading.isEmpty else { return 0 }

        var cursor = calendar.startOfDay(for: .now)
        // A streak shouldn't break just because today isn't over yet.
        if !daysWithReading.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
                  daysWithReading.contains(yesterday) else { return 0 }
            cursor = yesterday
        }

        var count = 0
        while daysWithReading.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }
}
