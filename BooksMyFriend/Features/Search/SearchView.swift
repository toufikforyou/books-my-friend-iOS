//
//  SearchView.swift
//  BooksMyFriend
//
//  Search doubles as the browse surface: with no query it shows trending terms,
//  recent searches and the full genre grid; with one it shows filtered results.
//

import SwiftUI

struct SearchView: View {
    @Environment(AppState.self) private var appState

    private let repository: BookRepository = LocalBookRepository()

    @State private var query = BookQuery()
    @State private var searchText = ""
    @State private var showingFilters = false

    private let trending = ["Space opera", "Slow burn", "Thriller", "Focus", "Poetry", "New release"]

    private var results: [Book] {
        var effective = query
        effective.text = searchText
        return repository.search(effective)
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty || query.hasActiveFilters
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xl) {
                if isSearching {
                    resultsSection
                } else {
                    browseSection
                }
            }
            .padding(.vertical, Spacing.md)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .background(Palette.background)
        .navigationTitle("Search")
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Title, author, or topic"
        )
        .searchSuggestions {
            // Only suggest while typing something short — once results are on
            // screen the suggestions are just noise.
            if !searchText.isEmpty && results.count > 3 {
                ForEach(suggestions, id: \.self) { suggestion in
                    Text(suggestion).searchCompletion(suggestion)
                }
            }
        }
        .onSubmit(of: .search) {
            appState.recordSearch(searchText)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingFilters = true
                } label: {
                    Image(systemName: query.activeFilterCount > 0
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("Filters")
            }
        }
        .sheet(isPresented: $showingFilters) {
            SearchFiltersSheet(query: $query)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(results.isEmpty
                     ? "No matches"
                     : "\(results.count) result\(results.count == 1 ? "" : "s")")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.textSecondary)

                Spacer()

                Menu {
                    Picker("Sort", selection: $query.sort) {
                        ForEach(SortOption.allCases) { option in
                            Label(option.rawValue, systemImage: option.symbol).tag(option)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: query.sort.symbol).font(.system(size: 11))
                        Text(query.sort.rawValue).font(.system(size: 13, weight: .semibold))
                        Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(Palette.accent)
                }
            }
            .pageHorizontalPadding()

            if query.activeFilterCount > 0 {
                activeFilterRow
            }

            if results.isEmpty {
                EmptyStateView(
                    symbol: "text.magnifyingglass",
                    title: "Nothing found",
                    message: "Try a different spelling, or loosen your filters.",
                    actionTitle: query.hasActiveFilters ? "Clear filters" : nil,
                    action: query.hasActiveFilters ? { query = BookQuery() } : nil
                )
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(results) { book in
                        BookListRow(book: book)
                            .pageHorizontalPadding()
                        Divider()
                            .padding(.leading, Spacing.page + 62 + Spacing.md)
                    }
                }
            }
        }
    }

    private var activeFilterRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.sm) {
                ForEach(Array(query.genres).sorted { $0.rawValue < $1.rawValue }) { genre in
                    FilterChip(title: genre.rawValue, symbol: "xmark", isSelected: true, tint: genre.tint) {
                        query.genres.remove(genre)
                    }
                }
                if query.freeOnly {
                    FilterChip(title: "Free only", symbol: "xmark", isSelected: true, tint: Palette.sapphire) {
                        query.freeOnly = false
                    }
                }
                if query.minimumRating > 0 {
                    FilterChip(title: "\(query.minimumRating.oneDecimal)+ stars", symbol: "xmark",
                               isSelected: true, tint: Palette.star) {
                        query.minimumRating = 0
                    }
                }
                Button("Clear all") { query = BookQuery() }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.textTertiary)
                    .padding(.leading, Spacing.xs)
            }
            .pageHorizontalPadding()
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Browse

    private var browseSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            if !appState.recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("Recent")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.textPrimary)
                        Spacer()
                        Button("Clear") { appState.clearSearchHistory() }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Palette.textTertiary)
                    }

                    ForEach(appState.recentSearches, id: \.self) { term in
                        Button {
                            searchText = term
                        } label: {
                            HStack(spacing: Spacing.md) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Palette.textTertiary)
                                Text(term)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Palette.textPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Palette.textTertiary)
                            }
                            .padding(.vertical, 7)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .pageHorizontalPadding()
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Trending searches")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)

                FlowStack(spacing: Spacing.sm) {
                    ForEach(trending, id: \.self) { term in
                        FilterChip(title: term, symbol: "arrow.up.right", isSelected: false) {
                            searchText = term
                        }
                    }
                }
            }
            .pageHorizontalPadding()

            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("All genres")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .pageHorizontalPadding()

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: Spacing.md),
                              GridItem(.flexible(), spacing: Spacing.md)],
                    spacing: Spacing.md
                ) {
                    ForEach(Genre.allCases) { genre in
                        GenreTile(genre: genre) { appState.push(.genre(genre)) }
                    }
                }
                .pageHorizontalPadding()
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Popular authors")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .pageHorizontalPadding()

                ScrollView(.horizontal) {
                    HStack(spacing: Spacing.md) {
                        ForEach(Catalog.authors, id: \.self) { author in
                            AuthorChip(author: author) { appState.push(.author(author)) }
                        }
                    }
                    .pageHorizontalPadding()
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    /// Title and author completions for whatever has been typed so far.
    private var suggestions: [String] {
        let needle = searchText.lowercased()
        let titles = results.prefix(4).map(\.title)
        let authors = Set(results.prefix(8).map(\.author))
            .filter { $0.lowercased().contains(needle) }
        return Array(Set(titles).union(authors)).sorted().prefix(5).map { $0 }
    }
}

// MARK: - Author chip

struct AuthorChip: View {
    let author: String
    let action: () -> Void

    private var initials: String {
        author.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
    }

    /// Deterministic hue so an author's badge colour is stable across screens.
    private var tint: Color {
        Genre.allCases[abs(author.hashValue) % Genre.allCases.count].tint
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                Text(initials)
                    .font(AppFont.rounded(20, .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 62, height: 62)
                    .background(
                        LinearGradient(colors: [tint, tint.mix(with: .black, by: 0.28)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Circle()
                    )

                Text(author)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 78)
            }
        }
        .buttonStyle(PressableCardStyle())
    }
}

// MARK: - Filters sheet

struct SearchFiltersSheet: View {
    @Binding var query: BookQuery
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Genres") {
                    FlowStack(spacing: Spacing.sm) {
                        ForEach(Genre.allCases) { genre in
                            FilterChip(
                                title: genre.rawValue,
                                isSelected: query.genres.contains(genre),
                                tint: genre.tint
                            ) {
                                if query.genres.contains(genre) {
                                    query.genres.remove(genre)
                                } else {
                                    query.genres.insert(genre)
                                }
                            }
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }

                Section("Availability") {
                    Toggle("Free to read only", isOn: $query.freeOnly)
                        .tint(Palette.accent)
                }

                Section {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("Minimum rating")
                            Spacer()
                            Text(query.minimumRating == 0 ? "Any" : "\(query.minimumRating.oneDecimal)+")
                                .foregroundStyle(Palette.accent)
                                .fontWeight(.semibold)
                                .contentTransition(.numericText())
                        }
                        Slider(value: $query.minimumRating, in: 0...5, step: 0.5)
                            .tint(Palette.accent)
                    }
                } header: {
                    Text("Rating")
                }

                Section("Sort by") {
                    Picker("Sort", selection: $query.sort) {
                        ForEach(SortOption.allCases) { option in
                            Label(option.rawValue, systemImage: option.symbol).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") { query = BookQuery() }
                        .disabled(!query.hasActiveFilters)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}
