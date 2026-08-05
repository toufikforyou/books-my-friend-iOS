//
//  RootTabView.swift
//  BooksMyFriend
//

import SwiftUI

struct RootTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        TabView(selection: tabSelection) {
            Tab(AppTab.discover.title, systemImage: AppTab.discover.symbol, value: AppTab.discover) {
                NavigationStack(path: $state.discoverPath) {
                    DiscoverView()
                        .withAppRoutes()
                }
            }

            Tab(AppTab.search.title, systemImage: AppTab.search.symbol, value: AppTab.search, role: .search) {
                NavigationStack(path: $state.searchPath) {
                    SearchView()
                        .withAppRoutes()
                }
            }

            Tab(AppTab.library.title, systemImage: AppTab.library.symbol, value: AppTab.library) {
                NavigationStack(path: $state.libraryPath) {
                    LibraryView()
                        .withAppRoutes()
                }
            }

            Tab(AppTab.profile.title, systemImage: AppTab.profile.symbol, value: AppTab.profile) {
                NavigationStack(path: $state.profilePath) {
                    ProfileView()
                        .withAppRoutes()
                }
            }
        }
        .fullScreenCover(item: $state.readingBook) { book in
            ReaderView(book: book)
        }
    }

    /// Intercepts selection so re-tapping the current tab pops that tab's
    /// stack to its root, matching how first-party apps behave.
    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { appState.selectedTab },
            set: { newValue in
                if newValue == appState.selectedTab {
                    appState.popToRoot(newValue)
                } else {
                    Haptics.select()
                }
                appState.selectedTab = newValue
            }
        )
    }
}

// MARK: - Shared route table

private struct AppRoutes: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .book(let id):
                    if let book = Catalog.book(id: id) {
                        BookDetailView(book: book)
                    } else {
                        ContentUnavailableView("Book unavailable", systemImage: "book.closed")
                    }
                case .genre(let genre):
                    GenreDetailView(genre: genre)
                case .author(let name):
                    AuthorDetailView(author: name)
                case .shelf(let id):
                    if let shelf = Catalog.shelves.first(where: { $0.id == id }) {
                        ShelfDetailView(shelf: shelf)
                    } else {
                        ContentUnavailableView("Collection unavailable", systemImage: "square.stack")
                    }
                case .allHighlights:
                    HighlightsView()
                case .readingStats:
                    ReadingStatsView()
                case .settings:
                    SettingsView()
                }
            }
    }
}

extension View {
    /// Applied once per tab so any screen can push any route.
    func withAppRoutes() -> some View {
        modifier(AppRoutes())
    }
}
