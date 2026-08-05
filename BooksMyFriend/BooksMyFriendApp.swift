//
//  BooksMyFriendApp.swift
//  BooksMyFriend
//
//  Created by MD TOUFIK HASAN on 5/8/26.
//

import SwiftData
import SwiftUI

@main
struct BooksMyFriendApp: App {
    /// The app's single container, resolved up front (rather than via the
    /// `.modelContainer(for:)` modifier) so `LibraryStore` can be built from
    /// the same context and injected as an observable.
    private let container: ModelContainer
    @State private var library: LibraryStore
    @State private var appState = AppState()
    @State private var readerSettings = ReaderSettings()

    init() {
        let container = PersistenceController.shared
        self.container = container

        let store = LibraryStore(context: container.mainContext)
        // Under test the app is only a host; seeding it would fight whatever
        // state the test is trying to set up.
        if !PersistenceController.isRunningTests {
            SampleDataSeeder.seedIfNeeded(into: store)
        }
        _library = State(initialValue: store)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(library)
                .environment(readerSettings)
                .modelContainer(container)
                .tint(Palette.accent)
        }
    }
}
