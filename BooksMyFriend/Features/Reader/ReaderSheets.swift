//
//  ReaderSheets.swift
//  BooksMyFriend
//
//  Display options, table of contents, and the notes/bookmarks browser.
//

import SwiftUI

// MARK: - Display options

struct ReaderSettingsSheet: View {
    @Environment(ReaderSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = settings

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                themeRow
                fontRow
                sizeRow
                sliderRow(
                    title: "Line spacing",
                    symbol: "arrow.up.and.down.text.horizontal",
                    value: $settings.lineSpacing,
                    range: ReaderSettings.lineSpacingRange,
                    step: 0.05,
                    label: String(format: "%.2f", Double(settings.lineSpacing))
                )
                sliderRow(
                    title: "Margins",
                    symbol: "rectangle.compress.vertical",
                    value: $settings.margin,
                    range: ReaderSettings.marginRange,
                    step: 2,
                    label: "\(Int(settings.margin))pt"
                )
                sliderRow(
                    title: "Brightness",
                    symbol: "sun.max",
                    value: Binding(
                        get: { CGFloat(settings.brightness) },
                        set: { settings.brightness = Double($0) }
                    ),
                    range: 0.35...1.0,
                    step: 0.05,
                    label: "\(Int(settings.brightness * 100))%"
                )

                VStack(spacing: Spacing.md) {
                    Toggle(isOn: $settings.justified) {
                        Label("Justified text", systemImage: "text.alignleft")
                    }
                    Toggle(isOn: $settings.scrollMode) {
                        Label("Continuous scroll", systemImage: "arrow.up.and.down")
                    }
                    Toggle(isOn: $settings.keepScreenAwake) {
                        Label("Keep screen awake", systemImage: "eye")
                    }
                }
                .tint(Palette.accent)
                .font(.system(size: 15))

                Button("Reset to defaults") {
                    withAnimation(.smooth) { settings.resetToDefaults() }
                    Haptics.tap()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.textTertiary)
                .frame(maxWidth: .infinity)
            }
            .pageHorizontalPadding()
            .padding(.vertical, Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(Palette.background)
    }

    private var themeRow: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            label("Theme", "circle.lefthalf.filled")

            HStack(spacing: Spacing.md) {
                ForEach(ReaderTheme.allCases) { theme in
                    Button {
                        Haptics.select()
                        withAnimation(.smooth(duration: 0.25)) { settings.theme = theme }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(theme.background)
                                    .frame(height: 52)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(
                                                settings.theme == theme ? Palette.accent : Palette.separator,
                                                lineWidth: settings.theme == theme ? 2.5 : 1
                                            )
                                    )
                                Text("Aa")
                                    .font(AppFont.serif(19, .medium))
                                    .foregroundStyle(theme.text)
                            }
                            Text(theme.title)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(settings.theme == theme ? Palette.accent : Palette.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(theme.title)
                    .accessibilityAddTraits(settings.theme == theme ? .isSelected : [])
                }
            }
        }
    }

    private var fontRow: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            label("Typeface", "textformat")

            ScrollView(.horizontal) {
                HStack(spacing: Spacing.sm) {
                    ForEach(ReaderFont.allCases) { font in
                        Button {
                            Haptics.select()
                            settings.font = font
                        } label: {
                            VStack(spacing: 2) {
                                Text("Aa").font(font.sampleFont)
                                Text(font.title).font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(settings.font == font ? .white : Palette.textPrimary)
                            .frame(width: 74, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(settings.font == font ? Palette.accent : Palette.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(Palette.separator, lineWidth: settings.font == font ? 0 : 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(font.title)
                        .accessibilityAddTraits(settings.font == font ? .isSelected : [])
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var sizeRow: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            label("Text size", "textformat.size")

            HStack(spacing: Spacing.md) {
                Button {
                    adjustSize(-1)
                } label: {
                    Image(systemName: "textformat.size.smaller")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .disabled(settings.fontSize <= ReaderSettings.fontSizeRange.lowerBound)

                Text("\(Int(settings.fontSize))")
                    .font(AppFont.rounded(17, .bold))
                    .foregroundStyle(Palette.textPrimary)
                    .frame(width: 44)
                    .contentTransition(.numericText())

                Button {
                    adjustSize(1)
                } label: {
                    Image(systemName: "textformat.size.larger")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .disabled(settings.fontSize >= ReaderSettings.fontSizeRange.upperBound)
            }
            .foregroundStyle(Palette.textPrimary)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(Palette.separator, lineWidth: 1)
            )
        }
    }

    private func sliderRow(
        title: String,
        symbol: String,
        value: Binding<CGFloat>,
        range: ClosedRange<CGFloat>,
        step: CGFloat,
        label labelText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                label(title, symbol)
                Spacer()
                Text(labelText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.accent)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
                .tint(Palette.accent)
        }
    }

    private func label(_ title: String, _ symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Palette.textSecondary)
    }

    private func adjustSize(_ delta: CGFloat) {
        Haptics.select()
        withAnimation(.snappy) {
            settings.fontSize = min(
                ReaderSettings.fontSizeRange.upperBound,
                max(ReaderSettings.fontSizeRange.lowerBound, settings.fontSize + delta)
            )
        }
    }
}

// MARK: - Table of contents

struct ReaderContentsSheet: View {
    let book: Book
    let pagination: BookPagination?
    let currentChapter: Int
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(book.chapters.enumerated()), id: \.element.id) { index, chapter in
                    Button {
                        onSelect(index)
                        dismiss()
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Text("\(chapter.number)")
                                .font(AppFont.rounded(13, .bold))
                                .foregroundStyle(index == currentChapter ? .white : Palette.textTertiary)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle().fill(index == currentChapter ? Palette.accent : Palette.surfaceSunken)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(chapter.title)
                                    .font(.system(size: 15, weight: index == currentChapter ? .semibold : .regular))
                                    .foregroundStyle(Palette.textPrimary)
                                Text(pageLabel(for: index, chapter: chapter))
                                    .font(.system(size: 12))
                                    .foregroundStyle(Palette.textTertiary)
                            }

                            Spacer()

                            if index == currentChapter {
                                Image(systemName: "chevron.right.circle.fill")
                                    .foregroundStyle(Palette.accent)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Palette.background)
                }
            }
            .listStyle(.plain)
            .background(Palette.background)
            .navigationTitle("Contents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private func pageLabel(for index: Int, chapter: Chapter) -> String {
        guard let pagination, pagination.pageCount(chapter: index) > 0 else {
            return "\(book.estimatedMinutes(for: chapter)) min"
        }
        return "\(pagination.pageCount(chapter: index)) pages · \(book.estimatedMinutes(for: chapter)) min"
    }
}

// MARK: - Notes & bookmarks

struct BookNotesSheet: View {
    let book: Book
    let onSelect: (Int, Int) -> Void

    @Environment(LibraryStore.self) private var library
    @Environment(\.dismiss) private var dismiss
    @State private var tab = 0

    private var highlights: [Highlight] { library.highlights(for: book.id) }
    private var bookmarks: [Bookmark] { library.bookmarks(for: book.id) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    Text("Highlights (\(highlights.count))").tag(0)
                    Text("Bookmarks (\(bookmarks.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .pageHorizontalPadding()
                .padding(.vertical, Spacing.sm)

                if tab == 0 {
                    highlightList
                } else {
                    bookmarkList
                }
            }
            .background(Palette.background)
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private var highlightList: some View {
        Group {
            if highlights.isEmpty {
                EmptyStateView(
                    symbol: "highlighter",
                    title: "No highlights yet",
                    message: "Select any passage while reading and choose a highlight colour."
                )
                Spacer()
            } else {
                List {
                    ForEach(highlights) { highlight in
                        Button {
                            onSelect(highlight.chapterIndex, 0)
                            dismiss()
                        } label: {
                            HighlightRow(highlight: highlight, book: book)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Palette.background)
                        .swipeActions {
                            Button(role: .destructive) {
                                library.delete(highlight: highlight)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var bookmarkList: some View {
        Group {
            if bookmarks.isEmpty {
                EmptyStateView(
                    symbol: "bookmark",
                    title: "No bookmarks",
                    message: "Tap the bookmark icon while reading to save your place."
                )
                Spacer()
            } else {
                List {
                    ForEach(bookmarks) { bookmark in
                        Button {
                            onSelect(bookmark.chapterIndex, bookmark.pageIndex)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(bookmark.chapterTitle)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Palette.textPrimary)
                                Text(bookmark.excerpt)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Palette.textSecondary)
                                    .lineLimit(2)
                                Text(bookmark.createdAt.relativeLabel)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Palette.textTertiary)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Palette.background)
                        .swipeActions {
                            Button(role: .destructive) {
                                library.delete(bookmark: bookmark)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - Highlight row

struct HighlightRow: View {
    let highlight: Highlight
    var book: Book?

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: 2)
                .fill(highlight.color.accent)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 5) {
                if let book {
                    Text(chapterTitle(in: book))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(highlight.color.accent)
                }

                Text(highlight.text)
                    .font(AppFont.serif(15))
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)

                if !highlight.note.isEmpty {
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "text.bubble.fill").font(.system(size: 10))
                        Text(highlight.note)
                            .font(.system(size: 13))
                            .lineLimit(3)
                    }
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.top, 2)
                }

                Text(highlight.createdAt.relativeLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private func chapterTitle(in book: Book) -> String {
        book.chapters.indices.contains(highlight.chapterIndex)
            ? book.chapters[highlight.chapterIndex].title
            : "Chapter \(highlight.chapterIndex + 1)"
    }
}

// MARK: - Highlight editor

struct HighlightEditorSheet: View {
    let highlight: Highlight

    @Environment(LibraryStore.self) private var library
    @Environment(\.dismiss) private var dismiss
    @State private var note = ""
    @FocusState private var noteFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(highlight.text)
                    .font(AppFont.serif(16))
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(5)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(highlight.color.color, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))

                HStack(spacing: Spacing.md) {
                    ForEach(HighlightColor.allCases) { color in
                        Button {
                            Haptics.select()
                            library.update(highlight: highlight, color: color)
                        } label: {
                            Circle()
                                .fill(color.accent)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Palette.textPrimary,
                                                      lineWidth: highlight.color == color ? 2.5 : 0)
                                        .padding(-4)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(color.rawValue)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Note")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.textSecondary)
                    TextEditor(text: $note)
                        .focused($noteFocused)
                        .font(.system(size: 15))
                        .scrollContentBackground(.hidden)
                        .padding(Spacing.sm)
                        .frame(height: 96)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                .strokeBorder(Palette.separator, lineWidth: 1)
                        )
                }

                Spacer()
            }
            .pageHorizontalPadding()
            .padding(.top, Spacing.lg)
            .background(Palette.background)
            .navigationTitle("Highlight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) {
                        library.delete(highlight: highlight)
                        Haptics.warning()
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        library.update(highlight: highlight, note: note)
                        Haptics.success()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { note = highlight.note }
        }
    }
}
