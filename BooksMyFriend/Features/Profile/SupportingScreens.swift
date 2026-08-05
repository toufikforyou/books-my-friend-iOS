//
//  SupportingScreens.swift
//  BooksMyFriend
//
//  Screens reachable from Profile: highlights across all books, reading
//  statistics, and settings.
//

import SwiftUI

// MARK: - All highlights

struct HighlightsView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(AppState.self) private var appState

    @State private var searchText = ""
    @State private var colorFilter: HighlightColor?

    private var grouped: [(book: Book, highlights: [Highlight])] {
        let needle = searchText.trimmingCharacters(in: .whitespaces).lowercased()

        let filtered = library.highlights.filter { highlight in
            if let colorFilter, highlight.color != colorFilter { return false }
            guard !needle.isEmpty else { return true }
            return highlight.text.lowercased().contains(needle)
                || highlight.note.lowercased().contains(needle)
        }

        return Dictionary(grouping: filtered, by: \.bookID)
            .compactMap { bookID, highlights in
                guard let book = Catalog.book(id: bookID) else { return nil }
                return (book, highlights.sorted { $0.createdAt > $1.createdAt })
            }
            .sorted { $0.highlights.count > $1.highlights.count }
    }

    var body: some View {
        Group {
            if library.highlights.isEmpty {
                EmptyStateView(
                    symbol: "highlighter",
                    title: "No highlights yet",
                    message: "Select a passage while reading and pick a colour. Everything you mark collects here."
                )
            } else {
                List {
                    Section {
                        ScrollView(.horizontal) {
                            HStack(spacing: Spacing.sm) {
                                FilterChip(title: "All", isSelected: colorFilter == nil) {
                                    colorFilter = nil
                                }
                                ForEach(HighlightColor.allCases) { color in
                                    FilterChip(
                                        title: color.rawValue.capitalized,
                                        isSelected: colorFilter == color,
                                        tint: color.accent
                                    ) {
                                        colorFilter = colorFilter == color ? nil : color
                                    }
                                }
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                        .scrollIndicators(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: Spacing.page, bottom: Spacing.sm, trailing: 0))
                        .listRowBackground(Palette.background)
                    }

                    ForEach(grouped, id: \.book.id) { group in
                        Section {
                            ForEach(group.highlights) { highlight in
                                HighlightRow(highlight: highlight, book: group.book)
                                    .listRowBackground(Palette.background)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            library.delete(highlight: highlight)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        } header: {
                            Button {
                                appState.push(.book(group.book.id))
                            } label: {
                                HStack(spacing: Spacing.sm) {
                                    BookCoverView(book: group.book, width: 26, showsShadow: false)
                                    Text(group.book.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Palette.textPrimary)
                                    Text("\(group.highlights.count)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Palette.textTertiary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(Palette.textTertiary)
                                }
                                .textCase(nil)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search your highlights")
            }
        }
        .background(Palette.background)
        .navigationTitle("Highlights")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Reading statistics

struct ReadingStatsView: View {
    @Environment(LibraryStore.self) private var library

    private var days: [(date: Date, minutes: Int)] { library.dailyMinutes(days: 30) }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: Spacing.md),
                              GridItem(.flexible(), spacing: Spacing.md)],
                    spacing: Spacing.md
                ) {
                    StatTile(value: library.totalMinutesRead.durationLabel, label: "Lifetime reading", symbol: "clock.fill", tint: Palette.accent)
                    StatTile(value: "\(library.streak)", label: "Current streak", symbol: "flame.fill", tint: Palette.rose)
                    StatTile(value: "\(library.booksFinished)", label: "Books finished", symbol: "checkmark.seal.fill", tint: Palette.sapphire)
                    StatTile(value: "\(averageMinutes)", label: "Avg. min/day", symbol: "chart.bar.fill", tint: Palette.plum)
                }
                .pageHorizontalPadding()

                monthChart
                shelfBreakdown
                genreBreakdown

                Color.clear.frame(height: Spacing.xl)
            }
            .padding(.top, Spacing.md)
        }
        .scrollIndicators(.hidden)
        .background(Palette.background)
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var averageMinutes: Int {
        let active = days.filter { $0.minutes > 0 }
        guard !active.isEmpty else { return 0 }
        return active.reduce(0) { $0 + $1.minutes } / active.count
    }

    private var monthChart: some View {
        let peak = max(1, days.map(\.minutes).max() ?? 1)

        return VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Last 30 days")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(days, id: \.date) { entry in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(entry.minutes > 0 ? Palette.accent.opacity(0.35 + 0.65 * Double(entry.minutes) / Double(peak)) : Palette.surfaceSunken)
                        .frame(height: max(4, 110 * CGFloat(entry.minutes) / CGFloat(peak)))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 118, alignment: .bottom)

            HStack {
                Text("30 days ago")
                Spacer()
                Text("Today")
            }
            .font(.system(size: 10))
            .foregroundStyle(Palette.textTertiary)
        }
        .padding(Spacing.lg)
        .cardBackground()
        .pageHorizontalPadding()
    }

    private var shelfBreakdown: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Your shelves")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)

            ForEach(ShelfStatus.allCases) { status in
                let count = library.items(status: status).count
                let fraction = library.items.isEmpty ? 0 : Double(count) / Double(library.items.count)

                HStack(spacing: Spacing.md) {
                    Image(systemName: status.symbol)
                        .font(.system(size: 12))
                        .foregroundStyle(status.tint)
                        .frame(width: 20)

                    Text(status.rawValue)
                        .font(.system(size: 14))
                        .foregroundStyle(Palette.textPrimary)
                        .frame(width: 96, alignment: .leading)

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Palette.surfaceSunken)
                            Capsule()
                                .fill(status.tint)
                                .frame(width: max(4, proxy.size.width * fraction))
                        }
                    }
                    .frame(height: 8)

                    Text("\(count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.textSecondary)
                        .frame(width: 24, alignment: .trailing)
                }
            }
        }
        .padding(Spacing.lg)
        .cardBackground()
        .pageHorizontalPadding()
    }

    private var genreBreakdown: some View {
        let counts = Dictionary(grouping: library.items.compactMap { Catalog.book(id: $0.bookID)?.genre }, by: { $0 })
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
            .prefix(5)

        return VStack(alignment: .leading, spacing: Spacing.md) {
            Text("What you read most")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)

            if counts.isEmpty {
                Text("Add a few books to see your genre mix.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textTertiary)
            } else {
                let peak = counts.first?.value ?? 1
                ForEach(Array(counts), id: \.key) { genre, count in
                    HStack(spacing: Spacing.md) {
                        Image(systemName: genre.symbol)
                            .font(.system(size: 12))
                            .foregroundStyle(genre.tint)
                            .frame(width: 20)
                        Text(genre.rawValue)
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.textPrimary)
                            .frame(width: 96, alignment: .leading)
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Palette.surfaceSunken)
                                Capsule()
                                    .fill(genre.tint)
                                    .frame(width: max(4, proxy.size.width * Double(count) / Double(peak)))
                            }
                        }
                        .frame(height: 8)
                        Text("\(count)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Palette.textSecondary)
                            .frame(width: 24, alignment: .trailing)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .cardBackground()
        .pageHorizontalPadding()
    }
}

// MARK: - Settings

struct SettingsView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(AppState.self) private var appState
    @Environment(ReaderSettings.self) private var settings

    @AppStorage("profile.name") private var name = "Reader"
    @AppStorage("settings.notifications") private var notifications = true
    @AppStorage("settings.downloadOverCellular") private var cellularDownloads = false
    @AppStorage("settings.autoDownload") private var autoDownload = true

    @State private var showingResetConfirmation = false

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("Profile") {
                LabeledContent("Name") {
                    TextField("Your name", text: $name)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.words)
                }
            }

            Section("Reading preferences") {
                Picker("Theme", selection: $settings.theme) {
                    ForEach(ReaderTheme.allCases) { Text($0.title).tag($0) }
                }
                Picker("Typeface", selection: $settings.font) {
                    ForEach(ReaderFont.allCases) { Text($0.title).tag($0) }
                }
                Toggle("Continuous scroll", isOn: $settings.scrollMode)
                Toggle("Keep screen awake", isOn: $settings.keepScreenAwake)
            }

            Section("Downloads") {
                Toggle("Download over cellular", isOn: $cellularDownloads)
                Toggle("Auto-download saved books", isOn: $autoDownload)
                LabeledContent("Downloaded", value: "\(library.items.filter(\.isDownloaded).count) books")
            }

            Section("Notifications") {
                Toggle("Daily reading reminder", isOn: $notifications)
                if notifications {
                    Text("We'll nudge you if you haven't read by 8pm.")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.textTertiary)
                }
            }

            Section("Your genres") {
                NavigationLink {
                    GenrePreferencesView()
                } label: {
                    LabeledContent("Preferred genres",
                                   value: appState.preferredGenres.isEmpty
                                   ? "None" : "\(appState.preferredGenres.count) selected")
                }
            }

            Section("About") {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Books in catalog", value: "\(Catalog.books.count)")
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    LabeledContent("Privacy Policy") {
                        Image(systemName: "arrow.up.right.square")
                    }
                }
            }

            Section {
                Button("Reset reading data", role: .destructive) {
                    showingResetConfirmation = true
                }
            } footer: {
                Text("Removes every book from your library along with all highlights, bookmarks and reading history. This cannot be undone.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Palette.accent)
        .confirmationDialog(
            "Reset all reading data?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset everything", role: .destructive) {
                for item in library.items {
                    library.remove(bookID: item.bookID)
                }
                Haptics.warning()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your library, highlights, bookmarks and statistics will be permanently deleted.")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Genre preferences

struct GenrePreferencesView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Discover puts collections matching these genres near the top.")
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.textSecondary)

                FlowStack(spacing: Spacing.sm) {
                    ForEach(Genre.allCases) { genre in
                        FilterChip(
                            title: genre.rawValue,
                            symbol: genre.symbol,
                            isSelected: appState.preferredGenres.contains(genre),
                            tint: genre.tint
                        ) {
                            if appState.preferredGenres.contains(genre) {
                                appState.preferredGenres.remove(genre)
                            } else {
                                appState.preferredGenres.insert(genre)
                            }
                        }
                    }
                }
            }
            .pageHorizontalPadding()
            .padding(.vertical, Spacing.lg)
        }
        .background(Palette.background)
        .navigationTitle("Preferred genres")
        .navigationBarTitleDisplayMode(.inline)
    }
}
