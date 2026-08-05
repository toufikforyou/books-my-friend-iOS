//
//  OnboardingView.swift
//  BooksMyFriend
//
//  Three panes and a genre picker. Kept short on purpose — the last step does
//  real work (it personalises Discover), so it earns its place.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var page = 0
    @State private var selectedGenres: Set<Genre> = []

    private let panes: [OnboardingPane] = [
        .init(
            symbol: "books.vertical.fill",
            title: "A library that fits\nin your pocket",
            message: "Thousands of titles across every genre — literary fiction, deep non-fiction, and everything in between.",
            tint: Palette.accent
        ),
        .init(
            symbol: "highlighter",
            title: "Read the way\nyou think",
            message: "Highlight in five colours, add notes, drop bookmarks, and pick up exactly where you left off on every page.",
            tint: Palette.sapphire
        ),
        .init(
            symbol: "flame.fill",
            title: "Build a habit\nthat sticks",
            message: "Track your streak, set a yearly goal, and watch the minutes add up. Reading is a practice, not a race.",
            tint: Palette.plum
        ),
    ]

    private var isGenreStep: Bool { page == panes.count }
    private var totalSteps: Int { panes.count + 1 }

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            backdrop

            VStack(spacing: 0) {
                header

                TabView(selection: $page) {
                    ForEach(Array(panes.enumerated()), id: \.offset) { index, pane in
                        OnboardingPaneView(pane: pane).tag(index)
                    }
                    genrePicker.tag(panes.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                footer
            }
        }
    }

    // MARK: - Pieces

    /// A soft colour wash that shifts with the current pane.
    private var backdrop: some View {
        let tint = isGenreStep ? Palette.accent : panes[page].tint
        return RadialGradient(
            colors: [tint.opacity(0.22), .clear],
            center: .top,
            startRadius: 0,
            endRadius: 520
        )
        .ignoresSafeArea()
        .animation(.smooth(duration: 0.6), value: page)
    }

    private var header: some View {
        HStack {
            HStack(spacing: 7) {
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.accent)
                Text("Books My Friend")
                    .font(AppFont.serif(17, .semibold))
                    .foregroundStyle(Palette.textPrimary)
            }

            Spacer()

            if !isGenreStep {
                Button("Skip") { finish() }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .pageHorizontalPadding()
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.lg)
    }

    private var genrePicker: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.sm) {
                Text("What do you love\nto read?")
                    .font(AppFont.serif(30, .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Palette.textPrimary)
                Text("Pick at least three. We'll shape your Discover feed around them.")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.sm)

            ScrollView {
                FlowStack(spacing: Spacing.sm) {
                    ForEach(Genre.allCases) { genre in
                        FilterChip(
                            title: genre.rawValue,
                            symbol: genre.symbol,
                            isSelected: selectedGenres.contains(genre),
                            tint: genre.tint
                        ) {
                            if selectedGenres.contains(genre) {
                                selectedGenres.remove(genre)
                            } else {
                                selectedGenres.insert(genre)
                            }
                        }
                    }
                }
                .pageHorizontalPadding()
                .padding(.vertical, Spacing.sm)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var footer: some View {
        VStack(spacing: Spacing.lg) {
            PageDots(count: totalSteps, index: page)

            Button(isGenreStep ? "Start reading" : "Continue") {
                advance()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isGenreStep && selectedGenres.count < 3)
            .opacity(isGenreStep && selectedGenres.count < 3 ? 0.45 : 1)
            .animation(.snappy, value: selectedGenres.count)

            if isGenreStep {
                Text(selectedGenres.count < 3
                     ? "\(3 - selectedGenres.count) more to go"
                     : "\(selectedGenres.count) selected")
                .font(.system(size: 13))
                .foregroundStyle(Palette.textTertiary)
                .contentTransition(.numericText())
            }
        }
        .pageHorizontalPadding()
        .padding(.bottom, Spacing.xl)
        .frame(height: 150, alignment: .top)
    }

    // MARK: - Actions

    private func advance() {
        Haptics.tap()
        if isGenreStep {
            finish()
        } else {
            withAnimation(.smooth(duration: 0.35)) { page += 1 }
        }
    }

    private func finish() {
        Haptics.success()
        appState.preferredGenres = selectedGenres
        appState.hasCompletedOnboarding = true
    }
}

// MARK: - Pane

private struct OnboardingPane {
    let symbol: String
    let title: String
    let message: String
    let tint: Color
}

private struct OnboardingPaneView: View {
    let pane: OnboardingPane
    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(pane.tint.opacity(0.14))
                    .frame(width: 168, height: 168)
                Circle()
                    .strokeBorder(pane.tint.opacity(0.28), lineWidth: 1)
                    .frame(width: 210, height: 210)
                Image(systemName: pane.symbol)
                    .font(.system(size: 62, weight: .light))
                    .foregroundStyle(pane.tint)
                    .symbolEffect(.bounce, value: appeared)
            }
            .scaleEffect(appeared ? 1 : 0.86)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: Spacing.md) {
                Text(pane.title)
                    .font(AppFont.serif(31, .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Palette.textPrimary)
                Text(pane.message)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Palette.textSecondary)
                    .lineSpacing(3)
            }
            .padding(.horizontal, Spacing.xl)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)

            Spacer(minLength: 0)
        }
        .onAppear {
            withAnimation(.smooth(duration: 0.55).delay(0.08)) { appeared = true }
        }
    }
}

// MARK: - Page dots

struct PageDots: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { dot in
                Capsule()
                    .fill(dot == index ? Palette.accent : Palette.textTertiary.opacity(0.3))
                    .frame(width: dot == index ? 22 : 7, height: 7)
            }
        }
        .animation(.snappy(duration: 0.3), value: index)
        .accessibilityHidden(true)
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
