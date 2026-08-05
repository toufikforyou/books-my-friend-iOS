//
//  Book.swift
//  BooksMyFriend
//
//  Catalog-side value types. These describe what a book *is*; anything about
//  what the reader has done with it lives in the SwiftData models instead.
//

import SwiftUI

// MARK: - Genre

enum Genre: String, CaseIterable, Identifiable, Codable, Hashable {
    case fiction = "Fiction"
    case mystery = "Mystery"
    case sciFi = "Sci-Fi"
    case fantasy = "Fantasy"
    case romance = "Romance"
    case horror = "Horror"
    case history = "History"
    case philosophy = "Philosophy"
    case business = "Business"
    case selfHelp = "Self-Help"
    case science = "Science"
    case poetry = "Poetry"
    case biography = "Biography"
    case adventure = "Adventure"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .fiction: "books.vertical.fill"
        case .mystery: "magnifyingglass.circle.fill"
        case .sciFi: "sparkles"
        case .fantasy: "wand.and.stars"
        case .romance: "heart.fill"
        case .horror: "moon.fill"
        case .history: "building.columns.fill"
        case .philosophy: "brain.head.profile"
        case .business: "chart.line.uptrend.xyaxis"
        case .selfHelp: "figure.mind.and.body"
        case .science: "atom"
        case .poetry: "feather.fill"
        case .biography: "person.crop.square.filled.and.at.rectangle.fill"
        case .adventure: "map.fill"
        }
    }

    /// Each genre owns a colour pair so category tiles, chips and generated
    /// covers all agree without a lookup table per feature.
    var tint: Color {
        switch self {
        case .fiction: Color(light: 0x1D4ED8, dark: 0x60A5FA)
        case .mystery: Color(light: 0x334155, dark: 0x94A3B8)
        case .sciFi: Color(light: 0x0E7490, dark: 0x22D3EE)
        case .fantasy: Color(light: 0x7E22CE, dark: 0xC084FC)
        case .romance: Color(light: 0xBE185D, dark: 0xF472B6)
        case .horror: Color(light: 0x1F2937, dark: 0x6B7280)
        case .history: Color(light: 0x92400E, dark: 0xD97706)
        case .philosophy: Color(light: 0x4338CA, dark: 0x818CF8)
        case .business: Color(light: 0x047857, dark: 0x34D399)
        case .selfHelp: Color(light: 0xC2410C, dark: 0xFB923C)
        case .science: Color(light: 0x0369A1, dark: 0x38BDF8)
        case .poetry: Color(light: 0x9D174D, dark: 0xF9A8D4)
        case .biography: Color(light: 0x6D28D9, dark: 0xA78BFA)
        case .adventure: Color(light: 0x15803D, dark: 0x4ADE80)
        }
    }
}

// MARK: - Chapter

struct Chapter: Identifiable, Hashable {
    let id: String
    let number: Int
    let title: String
    /// Plain body text. Paragraphs are separated by a blank line.
    let body: String

    var wordCount: Int {
        body.split(whereSeparator: \.isWhitespace).count
    }
}

// MARK: - Review

struct Review: Identifiable, Hashable {
    let id: String
    let author: String
    let avatarSeed: Int
    let rating: Int
    let date: Date
    let title: String
    let body: String
    var helpfulCount: Int
}

// MARK: - Book

struct Book: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let author: String
    let narrator: String?
    let genre: Genre
    let secondaryGenres: [Genre]
    let synopsis: String
    let publishedYear: Int
    let publisher: String
    let language: String
    let pageCount: Int
    let rating: Double
    let ratingCount: Int
    let readerCount: Int
    let price: Decimal?
    let isPremium: Bool
    let tags: [String]
    let chapters: [Chapter]
    let reviews: [Review]
    /// Deterministic seed for the generated cover artwork.
    let coverSeed: Int

    var isFree: Bool { price == nil }

    /// Store prices are quoted in USD. Formatting in the device locale renders
    /// them as "9.99 US$" outside the US, which reads like a conversion rather
    /// than a price, so the currency's own locale is used instead.
    var priceLabel: String {
        guard let price else { return "Free" }
        return price.formatted(.currency(code: "USD").locale(Locale(identifier: "en_US")))
    }

    /// Reading time for the published edition, taken from the page count at a
    /// typical 250 words per page and 235 words per minute.
    ///
    /// Deliberately *not* derived from `chapters`, which hold sample text
    /// rather than the full work — measuring those would tell the reader a
    /// 384-page novel takes twenty minutes.
    var estimatedMinutes: Int {
        max(1, Int((Double(pageCount) * 250 / 235).rounded()))
    }

    /// A chapter's share of the total, weighted by its length.
    func estimatedMinutes(for chapter: Chapter) -> Int {
        let totalWords = chapters.reduce(0) { $0 + $1.wordCount }
        guard totalWords > 0 else { return 1 }
        return max(1, Int(Double(estimatedMinutes) * Double(chapter.wordCount) / Double(totalWords)))
    }

    var allGenres: [Genre] {
        [genre] + secondaryGenres
    }

    /// Everything a search query is matched against.
    var searchHaystack: String {
        ([title, subtitle ?? "", author, genre.rawValue] + tags)
            .joined(separator: " ")
            .lowercased()
    }

    static func == (lhs: Book, rhs: Book) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Curated shelf

/// A titled row on Discover. The catalog owns the curation so the UI stays dumb.
struct Shelf: Identifiable {
    enum Style {
        /// Wide editorial cards, one and a bit visible at a time.
        case hero
        /// Standard portrait covers.
        case standard
        /// Numbered chart entries.
        case ranked
        /// Compact horizontal rows, three stacked per column.
        case compact
    }

    let id: String
    let title: String
    let subtitle: String?
    let style: Style
    let bookIDs: [String]
}
