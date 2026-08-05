//
//  AppState.swift
//  BooksMyFriend
//
//  Navigation state. Each tab keeps its own path so switching tabs preserves
//  where the reader was, and the reader itself is presented from the root so
//  it can be opened from any screen.
//

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case discover, search, library, profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .discover: "Discover"
        case .search: "Search"
        case .library: "Library"
        case .profile: "You"
        }
    }

    var symbol: String {
        switch self {
        case .discover: "sparkles"
        case .search: "magnifyingglass"
        case .library: "books.vertical.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}

/// Destinations reachable by push. Books are addressed by ID rather than by
/// value so a path can be restored without the catalog being loaded first.
enum Route: Hashable {
    case book(String)
    case genre(Genre)
    case author(String)
    case shelf(String)
    case allHighlights
    case readingStats
    case settings
}

@Observable
@MainActor
final class AppState {
    var selectedTab: AppTab = .discover

    /// One path per tab.
    var discoverPath = NavigationPath()
    var searchPath = NavigationPath()
    var libraryPath = NavigationPath()
    var profilePath = NavigationPath()

    /// Non-nil while the reader is open.
    var readingBook: Book?
    /// Set when the reader should jump straight to a position on open.
    var readingStartPosition: (chapter: Int, page: Int)?

    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "onboarding.completed") }
    }

    /// Genres chosen during onboarding; used to personalise Discover.
    var preferredGenres: Set<Genre> {
        didSet {
            UserDefaults.standard.set(preferredGenres.map(\.rawValue), forKey: "onboarding.genres")
        }
    }

    /// Search history, most recent first.
    var recentSearches: [String] {
        didSet { UserDefaults.standard.set(recentSearches, forKey: "search.recent") }
    }

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboarding.completed")
        let stored = UserDefaults.standard.stringArray(forKey: "onboarding.genres") ?? []
        preferredGenres = Set(stored.compactMap(Genre.init(rawValue:)))
        recentSearches = UserDefaults.standard.stringArray(forKey: "search.recent") ?? []
    }

    // MARK: - Navigation

    func push(_ route: Route) {
        switch selectedTab {
        case .discover: discoverPath.append(route)
        case .search: searchPath.append(route)
        case .library: libraryPath.append(route)
        case .profile: profilePath.append(route)
        }
    }

    func openBook(_ book: Book) {
        push(.book(book.id))
    }

    /// Tapping the active tab again pops to its root — standard iOS behaviour.
    func popToRoot(_ tab: AppTab) {
        switch tab {
        case .discover: discoverPath = NavigationPath()
        case .search: searchPath = NavigationPath()
        case .library: libraryPath = NavigationPath()
        case .profile: profilePath = NavigationPath()
        }
    }

    // MARK: - Reader

    func read(_ book: Book, chapter: Int? = nil, page: Int? = nil) {
        if let chapter { readingStartPosition = (chapter, page ?? 0) }
        readingBook = book
    }

    func closeReader() {
        readingBook = nil
        readingStartPosition = nil
    }

    // MARK: - Search history

    func recordSearch(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 1 else { return }
        var updated = recentSearches.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        updated.insert(trimmed, at: 0)
        recentSearches = Array(updated.prefix(8))
    }

    func clearSearchHistory() {
        recentSearches = []
    }
}
