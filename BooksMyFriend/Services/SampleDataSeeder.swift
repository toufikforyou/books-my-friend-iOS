//
//  SampleDataSeeder.swift
//  BooksMyFriend
//
//  Seeds a plausible reading history on first launch so Continue Reading,
//  the library shelves and the stats screen have something real to show.
//  Runs once; after that the reader's own activity takes over.
//

import Foundation
import SwiftData

@MainActor
enum SampleDataSeeder {
    private static let flagKey = "seed.v1.completed"

    static func seedIfNeeded(into store: LibraryStore) {
        guard !UserDefaults.standard.bool(forKey: flagKey) else { return }
        guard store.items.isEmpty else {
            UserDefaults.standard.set(true, forKey: flagKey)
            return
        }

        seedShelves(store)
        seedSessions(store)

        UserDefaults.standard.set(true, forKey: flagKey)
    }

    private static func seedShelves(_ store: LibraryStore) {
        // In progress.
        addReading(store, id: "b-lighthouse", progress: 0.42, chapter: 4, page: 3, daysAgo: 0, minutes: 210)
        addReading(store, id: "b-quietmachines", progress: 0.18, chapter: 1, page: 2, daysAgo: 1, minutes: 64)
        addReading(store, id: "b-orbitals", progress: 0.71, chapter: 6, page: 1, daysAgo: 3, minutes: 340)

        // Finished.
        addFinished(store, id: "b-nightferry", daysAgo: 12, rating: 5, minutes: 420)
        addFinished(store, id: "b-stillness", daysAgo: 34, rating: 4, minutes: 190)
        addFinished(store, id: "b-nineteendoors", daysAgo: 58, rating: 4, minutes: 380)

        // Saved for later.
        for id in ["b-signalfire", "b-carbon", "b-ironbridge", "b-emberwood", "b-saltandhoney"] {
            guard let book = Catalog.book(id: id) else { continue }
            store.add(book, status: .wantToRead)
        }

        store.item(for: "b-orbitals")?.isDownloaded = true
        store.item(for: "b-lighthouse")?.isDownloaded = true
        store.item(for: "b-lighthouse")?.isFavorite = true
        store.reload()
    }

    private static func addReading(
        _ store: LibraryStore,
        id: String,
        progress: Double,
        chapter: Int,
        page: Int,
        daysAgo: Int,
        minutes: Int
    ) {
        guard let book = Catalog.book(id: id) else { return }
        let item = store.add(book, status: .reading)
        item.progress = progress
        item.chapterIndex = chapter
        item.pageIndex = page
        item.secondsRead = minutes * 60
        item.lastOpenedAt = .now.addingTimeInterval(-Double(daysAgo) * 86_400)
    }

    private static func addFinished(
        _ store: LibraryStore,
        id: String,
        daysAgo: Int,
        rating: Int,
        minutes: Int
    ) {
        guard let book = Catalog.book(id: id) else { return }
        let item = store.add(book, status: .finished)
        item.progress = 1
        item.personalRating = rating
        item.secondsRead = minutes * 60
        item.finishedAt = .now.addingTimeInterval(-Double(daysAgo) * 86_400)
        item.lastOpenedAt = item.finishedAt
    }

    /// A believable eight-day history with one rest day, so the streak and the
    /// weekly chart both have shape instead of a flat line.
    private static func seedSessions(_ store: LibraryStore) {
        let pattern: [(daysAgo: Int, minutes: Int, bookID: String)] = [
            (0, 22, "b-lighthouse"),
            (1, 35, "b-lighthouse"),
            (1, 12, "b-quietmachines"),
            (2, 48, "b-orbitals"),
            (3, 26, "b-orbitals"),
            (4, 0, "b-lighthouse"),      // rest day — filtered out below
            (5, 41, "b-lighthouse"),
            (6, 18, "b-quietmachines"),
            (7, 55, "b-orbitals"),
        ]

        for entry in pattern where entry.minutes > 0 {
            let session = ReadingSession(
                bookID: entry.bookID,
                startedAt: .now.addingTimeInterval(-Double(entry.daysAgo) * 86_400),
                seconds: entry.minutes * 60,
                pagesRead: entry.minutes / 2
            )
            store.context.insert(session)
        }
        store.reload()
    }
}
