//
//  ReaderView.swift
//  BooksMyFriend
//

import SwiftUI

struct ReaderView: View {
    let book: Book

    @Environment(AppState.self) private var appState
    @Environment(LibraryStore.self) private var library
    @Environment(ReaderSettings.self) private var settings

    // Pagination
    @State private var pagination: BookPagination?
    @State private var pageSize: CGSize = .zero
    @State private var isPaginating = true

    // Position — the global page index is the single source of truth while
    // reading; chapter/page are derived from it.
    @State private var currentPage: Int?
    @State private var didRestorePosition = false

    // Chrome
    @State private var showsChrome = true
    @State private var showingSettings = false
    @State private var showingContents = false
    @State private var showingNotes = false
    @State private var selectedHighlight: Highlight?
    @State private var scrubberValue: Double = 0
    @State private var isScrubbing = false

    // Session accounting
    @State private var sessionStart = Date.now
    @State private var pagesThisSession = 0

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()

            if settings.scrollMode {
                scrollReader
            } else {
                pagedReader
            }

            if showsChrome {
                chrome.transition(.opacity.animation(.easeInOut(duration: 0.22)))
            }
        }
        .statusBarHidden(!showsChrome)
        .preferredColorScheme(settings.theme.colorScheme)
        .persistentSystemOverlays(showsChrome ? .automatic : .hidden)
        // Screen dimming is applied as an overlay rather than by changing the
        // device brightness, which would outlive the reading session.
        .overlay {
            Color.black
                .opacity((1 - settings.brightness) * 0.65)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .sheet(isPresented: $showingSettings) {
            ReaderSettingsSheet()
                .presentationDetents([.height(470)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingContents) {
            ReaderContentsSheet(
                book: book,
                pagination: pagination,
                currentChapter: position.chapter
            ) { chapter in
                jump(toChapter: chapter)
            }
        }
        .sheet(isPresented: $showingNotes) {
            BookNotesSheet(book: book) { chapter, page in
                jump(toChapter: chapter, page: page)
            }
        }
        .sheet(item: $selectedHighlight) { highlight in
            HighlightEditorSheet(highlight: highlight)
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
        }
        .task(id: paginationKey) { await repaginate() }
        .onAppear {
            library.beginReading(book)
            sessionStart = .now
            UIApplication.shared.isIdleTimerDisabled = settings.keepScreenAwake
        }
        .onDisappear {
            endSession()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: currentPage) { oldValue, newValue in
            guard oldValue != nil, newValue != nil else { return }
            pagesThisSession += 1
            persistPosition()
            if !isScrubbing { Haptics.pageTurn() }
        }
    }

    // MARK: - Derived state

    private var position: (chapter: Int, page: Int) {
        guard let pagination, let currentPage else { return (0, 0) }
        return pagination.position(forGlobalPage: currentPage)
    }

    private var progress: Double {
        guard let pagination, pagination.totalPages > 1, let currentPage else { return 0 }
        return Double(currentPage) / Double(pagination.totalPages - 1)
    }

    /// Any change to this re-runs pagination.
    private var paginationKey: String {
        "\(book.id)-\(settings.layoutSignature)-\(Int(pageSize.width))x\(Int(pageSize.height))"
    }

    // MARK: - Paged reading

    private var pagedReader: some View {
        GeometryReader { proxy in
            let size = textSize(in: proxy)

            Group {
                if let pagination, !pagination.isEmpty, !isPaginating {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 0) {
                            ForEach(0..<pagination.totalPages, id: \.self) { globalPage in
                                pageContent(globalPage: globalPage, pagination: pagination, size: size)
                                    .frame(width: proxy.size.width)
                                    .id(globalPage)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $currentPage)
                    .scrollIndicators(.hidden)
                } else {
                    LoadingView(message: "Laying out \(book.title)…")
                        .foregroundStyle(settings.theme.secondaryText)
                }
            }
            .onAppear { pageSize = size }
            .onChange(of: size) { _, newValue in pageSize = newValue }
        }
    }

    private func pageContent(globalPage: Int, pagination: BookPagination, size: CGSize) -> some View {
        let location = pagination.position(forGlobalPage: globalPage)
        let chapter = book.chapters[min(location.chapter, book.chapters.count - 1)]
        let range = pagination.range(chapter: location.chapter, page: location.page)

        return VStack(alignment: .leading, spacing: 0) {
            pageHeader(chapterTitle: chapter.title)

            if let range, let text = pageText(chapter: chapter, range: range) {
                PageTextView(
                    attributed: text,
                    pageOffset: range.location,
                    highlights: library.highlights(for: book.id, chapterIndex: location.chapter),
                    theme: settings.theme,
                    size: size,
                    onTap: handleTap,
                    onHighlight: { chapterRange, selected, color in
                        library.addHighlight(
                            bookID: book.id,
                            chapterIndex: location.chapter,
                            range: chapterRange,
                            text: selected,
                            color: color
                        )
                        Haptics.success()
                    },
                    onTapHighlight: { selectedHighlight = $0 }
                )
                .frame(width: size.width, height: size.height, alignment: .topLeading)
            }

            Spacer(minLength: 0)

            pageFooter(
                chapterPage: location.page + 1,
                chapterPages: pagination.pageCount(chapter: location.chapter),
                globalPage: globalPage + 1,
                totalPages: pagination.totalPages
            )
        }
        .padding(.horizontal, settings.margin)
        .padding(.top, 54)
        .padding(.bottom, 34)
    }

    private func pageHeader(chapterTitle: String) -> some View {
        Text(chapterTitle.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(1.1)
            .foregroundStyle(settings.theme.secondaryText)
            .lineLimit(1)
            .padding(.bottom, Spacing.lg)
    }

    private func pageFooter(chapterPage: Int, chapterPages: Int, globalPage: Int, totalPages: Int) -> some View {
        HStack {
            Text("\(chapterPage) of \(chapterPages) in chapter")
            Spacer()
            Text("\(globalPage) / \(totalPages)")
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(settings.theme.secondaryText)
        .monospacedDigit()
        .padding(.top, Spacing.md)
    }

    // MARK: - Scroll reading

    private var scrollReader: some View {
        ScrollViewReader { scroller in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.xxl) {
                    ForEach(Array(book.chapters.enumerated()), id: \.element.id) { index, chapter in
                        VStack(alignment: .leading, spacing: Spacing.lg) {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Chapter \(chapter.number)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .tracking(1.1)
                                    .foregroundStyle(settings.theme.accent)
                                Text(chapter.title)
                                    .font(AppFont.serif(26, .bold))
                                    .foregroundStyle(settings.theme.text)
                            }
                            .padding(.top, index == 0 ? 70 : 0)

                            Text(chapter.body)
                                .font(Font(settings.font.uiFont(size: settings.fontSize)))
                                .foregroundStyle(settings.theme.text)
                                .lineSpacing(settings.fontSize * (settings.lineSpacing - 1))
                                .multilineTextAlignment(.leading)
                                .textSelection(.enabled)
                        }
                        .id(index)
                        .padding(.horizontal, settings.margin)
                    }

                    Color.clear.frame(height: 120)
                }
            }
            .scrollIndicators(.hidden)
            .onTapGesture {
                withAnimation { showsChrome.toggle() }
            }
            .onAppear {
                // Landing mid-book should still open at the right chapter.
                if let currentPage, let pagination {
                    scroller.scrollTo(pagination.position(forGlobalPage: currentPage).chapter, anchor: .top)
                }
            }
        }
    }

    // MARK: - Chrome

    private var chrome: some View {
        VStack(spacing: 0) {
            topBar
            Spacer()
            bottomBar
        }
    }

    private var topBar: some View {
        HStack(spacing: Spacing.lg) {
            Button {
                endSession()
                appState.closeReader()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
            }
            .accessibilityLabel("Close reader")

            VStack(spacing: 1) {
                Text(book.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text(book.author)
                    .font(.system(size: 11))
                    .opacity(0.6)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            Button {
                toggleBookmark()
            } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isBookmarked ? settings.theme.accent : settings.theme.text)
                    .contentTransition(.symbolEffect(.replace))
            }
            .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Bookmark this page")

            Menu {
                Button { showingContents = true } label: {
                    Label("Contents", systemImage: "list.bullet")
                }
                Button { showingNotes = true } label: {
                    Label("Notes & Bookmarks", systemImage: "highlighter")
                }
                Button { showingSettings = true } label: {
                    Label("Display Options", systemImage: "textformat.size")
                }
                Divider()
                Toggle(isOn: scrollModeBinding) {
                    Label("Continuous Scroll", systemImage: "arrow.up.and.down")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 16, weight: .semibold))
            }
            .accessibilityLabel("More")
        }
        .foregroundStyle(settings.theme.text)
        .padding(.horizontal, Spacing.page)
        .padding(.vertical, Spacing.md)
        .background(.ultraThinMaterial)
    }

    private var bottomBar: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.lg) {
                Button { showingContents = true } label: {
                    Image(systemName: "list.bullet")
                }
                .accessibilityLabel("Contents")

                Slider(
                    value: scrubberBinding,
                    in: 0...Double(max(1, (pagination?.totalPages ?? 1) - 1)),
                    step: 1,
                    onEditingChanged: { editing in
                        isScrubbing = editing
                        if !editing { commitScrub() }
                    }
                )
                .tint(settings.theme.accent)

                Button { showingSettings = true } label: {
                    Image(systemName: "textformat.size")
                }
                .accessibilityLabel("Display options")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(settings.theme.text)

            HStack {
                Text(chapterLabel)
                Spacer()
                Text(remainingLabel)
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(settings.theme.secondaryText)
            .monospacedDigit()
        }
        .padding(.horizontal, Spacing.page)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
        .background(.ultraThinMaterial)
    }

    private var chapterLabel: String {
        guard book.chapters.indices.contains(position.chapter) else { return "" }
        let chapter = book.chapters[position.chapter]
        return "Ch. \(chapter.number) · \(chapter.title)"
    }

    private var remainingLabel: String {
        guard let pagination else { return "" }
        let left = pagination.pagesLeftInChapter(chapter: position.chapter, page: position.page)
        guard left > 0 else { return "\(Int(progress * 100))% · end of chapter" }
        return "\(Int(progress * 100))% · \(left) page\(left == 1 ? "" : "s") left"
    }

    // MARK: - Bindings

    private var scrubberBinding: Binding<Double> {
        Binding(
            get: { isScrubbing ? scrubberValue : Double(currentPage ?? 0) },
            set: { scrubberValue = $0 }
        )
    }

    private var scrollModeBinding: Binding<Bool> {
        Binding(
            get: { settings.scrollMode },
            set: { settings.scrollMode = $0 }
        )
    }

    // MARK: - Actions

    private func handleTap(_ zone: PageTapZone) {
        switch zone {
        case .previous: turn(by: -1)
        case .next: turn(by: 1)
        case .toggleChrome: withAnimation { showsChrome.toggle() }
        }
    }

    private func turn(by delta: Int) {
        guard let pagination, let currentPage else { return }
        let target = currentPage + delta
        guard target >= 0, target < pagination.totalPages else {
            Haptics.warning()
            return
        }
        withAnimation(.smooth(duration: 0.28)) { self.currentPage = target }
    }

    private func commitScrub() {
        withAnimation(.smooth(duration: 0.3)) { currentPage = Int(scrubberValue) }
        Haptics.tap()
    }

    private func jump(toChapter chapter: Int, page: Int = 0) {
        guard let pagination else { return }
        let target = pagination.globalPage(chapter: chapter, page: page)
        showingContents = false
        showingNotes = false
        withAnimation(.smooth(duration: 0.3)) { currentPage = target }
    }

    private var isBookmarked: Bool {
        library.bookmark(for: book.id, chapterIndex: position.chapter, pageIndex: position.page) != nil
    }

    private func toggleBookmark() {
        let excerpt = currentPageExcerpt()
        library.toggleBookmark(
            book: book,
            chapterIndex: position.chapter,
            pageIndex: position.page,
            excerpt: excerpt
        )
        Haptics.success()
    }

    /// First ~90 characters of the current page, used as the bookmark preview.
    private func currentPageExcerpt() -> String {
        guard let pagination,
              let range = pagination.range(chapter: position.chapter, page: position.page),
              book.chapters.indices.contains(position.chapter) else { return "" }

        let body = book.chapters[position.chapter].body as NSString
        let safe = NSIntersectionRange(range, NSRange(location: 0, length: body.length))
        guard safe.length > 0 else { return "" }

        let text = body.substring(with: safe)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        return String(text.prefix(90)) + (text.count > 90 ? "…" : "")
    }

    // MARK: - Pagination

    private func textSize(in proxy: GeometryProxy) -> CGSize {
        CGSize(
            width: max(1, proxy.size.width - settings.margin * 2),
            // Reserve the running head and folio drawn above and below.
            height: max(1, proxy.size.height - 54 - 34 - 30 - 26)
        )
    }

    private func repaginate() async {
        guard pageSize.width > 1, pageSize.height > 1 else { return }
        isPaginating = true

        let bodies = book.chapters.map(\.body)
        let attributes = settings.bodyAttributes()
        let size = pageSize

        // CoreText layout for a 600-page book is too slow for the main thread.
        let chapters = await Task.detached(priority: .userInitiated) {
            Paginator.paginateBook(chapters: bodies, attributes: attributes, size: size)
        }.value

        let result = BookPagination(chapters: chapters)
        pagination = result

        if !didRestorePosition {
            // First layout: honour wherever the reader left off.
            let start = appState.readingStartPosition
                ?? (library.item(for: book.id).map { ($0.chapterIndex, $0.pageIndex) } ?? (0, 0))
            currentPage = result.globalPage(
                chapter: min(start.chapter, max(0, result.chapters.count - 1)),
                page: start.page
            )
            didRestorePosition = true
        } else if let item = library.item(for: book.id) {
            // Re-layout after a font change: hold position by progress, since
            // the old page number no longer means anything.
            currentPage = Int(item.progress * Double(max(0, result.totalPages - 1)))
        }

        isPaginating = false
    }

    private func persistPosition() {
        guard let pagination, let currentPage else { return }
        let location = pagination.position(forGlobalPage: currentPage)
        library.updateProgress(
            bookID: book.id,
            chapterIndex: location.chapter,
            pageIndex: location.page,
            fraction: progress
        )
    }

    private func endSession() {
        let seconds = Int(Date.now.timeIntervalSince(sessionStart))
        library.recordSession(bookID: book.id, seconds: seconds, pages: pagesThisSession)
        pagesThisSession = 0
        sessionStart = .now
    }

    /// Builds the styled text for a single page.
    private func pageText(chapter: Chapter, range: NSRange) -> NSAttributedString? {
        let body = chapter.body as NSString
        let safe = NSIntersectionRange(range, NSRange(location: 0, length: body.length))
        guard safe.length > 0 else { return nil }
        return NSAttributedString(
            string: body.substring(with: safe),
            attributes: settings.bodyAttributes()
        )
    }
}
