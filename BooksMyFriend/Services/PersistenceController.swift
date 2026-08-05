//
//  PersistenceController.swift
//  BooksMyFriend
//
//  Owns the app's single `ModelContainer`.
//
//  SwiftData registers each `@Model` class against the container that first
//  claims it, and traps on a second registration. Since the unit-test bundle
//  is hosted by the app, both would otherwise build their own container in one
//  process — so there is exactly one, created here, and tests take a fresh
//  `ModelContext` from it instead of a second container.
//

import Foundation
import SwiftData

enum PersistenceController {

    static let schema = Schema([
        LibraryItem.self,
        Highlight.self,
        Bookmark.self,
        ReadingSession.self,
    ])

    /// True while the process is hosting an XCTest bundle.
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// The one container. Backed by memory under test so a run never touches
    /// (or inherits) the simulator's real store.
    static let shared: ModelContainer = make(inMemory: isRunningTests)

    private static func make(inMemory: Bool) -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            // A migration failure would otherwise brick launch. Falling back to
            // memory keeps the app usable and makes the problem loud rather
            // than fatal.
            assertionFailure("Persistent store unavailable: \(error)")
            return try! ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            )
        }
    }
}
