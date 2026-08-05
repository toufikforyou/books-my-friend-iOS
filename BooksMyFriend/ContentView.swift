//
//  ContentView.swift
//  BooksMyFriend
//
//  Created by MD TOUFIK HASAN on 5/8/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                RootTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
            }
        }
        .animation(.smooth(duration: 0.45), value: appState.hasCompletedOnboarding)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .environment(ReaderSettings())
}
