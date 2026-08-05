//
//  LibraryModels.swift
//  BooksMyFriend
//
//  SwiftData models: everything the reader creates. Catalog identifiers are
//  stored as plain strings so the persisted store never depends on the shape
//  of the (remote, replaceable) catalog.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Shelf status

enum ShelfStatus: String, Codable, CaseIterable, Identifiable {
    case reading = "Reading"
    case wantToRead = "Want to Read"
    case finished = "Finished"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .reading: "book.fill"
        case .wantToRead: "bookmark.fill"
        case .finished: "checkmark.seal.fill"
        }
    }

    var tint: Color {
        switch self {
        case .reading: Palette.accent
        case .wantToRead: Palette.plum
        case .finished: Palette.sapphire
        }
    }
}

// MARK: - Library item

@Model
final class LibraryItem {
    /// Catalog book identifier. Unique so "add to library" is idempotent.
    @Attribute(.unique) var bookID: String
    var statusRaw: String
    var addedAt: Date
    var lastOpenedAt: Date?
    var isDownloaded: Bool
    var isFavorite: Bool
    /// 0...1 through the whole book.
    var progress: Double
    /// Where to resume: chapter index and page within that chapter.
    var chapterIndex: Int
    var pageIndex: Int
    /// Accumulated reading time in seconds, used for stats.
    var secondsRead: Int
    var finishedAt: Date?
    var personalRating: Int

    init(
        bookID: String,
        status: ShelfStatus = .wantToRead,
        addedAt: Date = .now,
        isDownloaded: Bool = false
    ) {
        self.bookID = bookID
        self.statusRaw = status.rawValue
        self.addedAt = addedAt
        self.lastOpenedAt = nil
        self.isDownloaded = isDownloaded
        self.isFavorite = false
        self.progress = 0
        self.chapterIndex = 0
        self.pageIndex = 0
        self.secondsRead = 0
        self.finishedAt = nil
        self.personalRating = 0
    }

    var status: ShelfStatus {
        get { ShelfStatus(rawValue: statusRaw) ?? .wantToRead }
        set { statusRaw = newValue.rawValue }
    }

    var progressPercent: Int { Int((progress * 100).rounded()) }
}

// MARK: - Highlight

enum HighlightColor: String, Codable, CaseIterable, Identifiable {
    case yellow, green, blue, pink, purple

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .yellow: Color(light: 0xFDE68A, dark: 0x78621B)
        case .green: Color(light: 0xBBF7D0, dark: 0x14532D)
        case .blue: Color(light: 0xBFDBFE, dark: 0x1E3A8A)
        case .pink: Color(light: 0xFBCFE8, dark: 0x831843)
        case .purple: Color(light: 0xDDD6FE, dark: 0x4C1D95)
        }
    }

    /// Saturated version for dots and chips, where the wash is too pale.
    var accent: Color {
        switch self {
        case .yellow: Color(light: 0xD97706, dark: 0xFBBF24)
        case .green: Color(light: 0x059669, dark: 0x34D399)
        case .blue: Color(light: 0x2563EB, dark: 0x60A5FA)
        case .pink: Color(light: 0xDB2777, dark: 0xF472B6)
        case .purple: Color(light: 0x7C3AED, dark: 0xA78BFA)
        }
    }
}

@Model
final class Highlight {
    var id: UUID
    var bookID: String
    var chapterIndex: Int
    /// Character range within the chapter body.
    var rangeLocation: Int
    var rangeLength: Int
    var text: String
    var note: String
    var colorRaw: String
    var createdAt: Date

    init(
        bookID: String,
        chapterIndex: Int,
        range: NSRange,
        text: String,
        color: HighlightColor = .yellow,
        note: String = ""
    ) {
        self.id = UUID()
        self.bookID = bookID
        self.chapterIndex = chapterIndex
        self.rangeLocation = range.location
        self.rangeLength = range.length
        self.text = text
        self.note = note
        self.colorRaw = color.rawValue
        self.createdAt = .now
    }

    var range: NSRange { NSRange(location: rangeLocation, length: rangeLength) }

    var color: HighlightColor {
        get { HighlightColor(rawValue: colorRaw) ?? .yellow }
        set { colorRaw = newValue.rawValue }
    }
}

// MARK: - Bookmark

@Model
final class Bookmark {
    var id: UUID
    var bookID: String
    var chapterIndex: Int
    var pageIndex: Int
    var chapterTitle: String
    var excerpt: String
    var createdAt: Date

    init(bookID: String, chapterIndex: Int, pageIndex: Int, chapterTitle: String, excerpt: String) {
        self.id = UUID()
        self.bookID = bookID
        self.chapterIndex = chapterIndex
        self.pageIndex = pageIndex
        self.chapterTitle = chapterTitle
        self.excerpt = excerpt
        self.createdAt = .now
    }
}

// MARK: - Reading session

/// One contiguous stretch of reading. Stats are derived from these rather than
/// from a running counter, so the streak survives a reinstall of the catalog.
@Model
final class ReadingSession {
    var id: UUID
    var bookID: String
    var startedAt: Date
    var seconds: Int
    var pagesRead: Int

    init(bookID: String, startedAt: Date = .now, seconds: Int = 0, pagesRead: Int = 0) {
        self.id = UUID()
        self.bookID = bookID
        self.startedAt = startedAt
        self.seconds = seconds
        self.pagesRead = pagesRead
    }

    var day: Date { Calendar.current.startOfDay(for: startedAt) }
}
