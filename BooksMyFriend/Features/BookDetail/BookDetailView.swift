//
//  BookDetailView.swift
//  BooksMyFriend
//

import SwiftUI

struct BookDetailView: View {
    let book: Book

    @Environment(AppState.self) private var appState
    @Environment(LibraryStore.self) private var library
    @Environment(\.dismiss) private var dismiss

    private let repository: BookRepository = LocalBookRepository()

    @State private var synopsisExpanded = false
    @State private var showingShelfPicker = false
    @State private var showingAllReviews = false
    @State private var showingRatingSheet = false
    @State private var personalRating = 0
    /// The sticky bar only earns its space once the main action has scrolled
    /// away — showing both at once just covers the synopsis.
    @State private var showsFloatingBar = false

    private var item: LibraryItem? { library.item(for: book.id) }
    private var progress: Double { item?.progress ?? 0 }
    private var similar: [Book] { repository.similar(to: book, limit: 8) }
    private var moreByAuthor: [Book] { repository.byAuthor(book.author, excluding: book.id) }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                hero
                actions
                statsStrip
                synopsis
                tags
                chapters
                reviewsSection

                if !moreByAuthor.isEmpty {
                    carousel(title: "More by \(book.author)", books: moreByAuthor)
                }
                if !similar.isEmpty {
                    carousel(title: "Readers also enjoyed", books: similar)
                }

                publisherInfo

                Color.clear.frame(height: 90)  // room for the floating bar
            }
        }
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            // Roughly the point where the Start Reading button leaves the screen.
            geometry.contentOffset.y > 430
        } action: { _, isScrolledPast in
            withAnimation(.smooth(duration: 0.25)) { showsFloatingBar = isScrolledPast }
        }
        .background(Palette.background)
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .bottom) {
            if showsFloatingBar {
                floatingBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    BookContextMenu(book: book)
                    Divider()
                    Button {
                        showingRatingSheet = true
                    } label: {
                        Label("Rate this book", systemImage: "star")
                    }
                    ShareLink(item: shareText) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingShelfPicker) {
            ShelfPickerSheet(book: book)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingRatingSheet) {
            RatingSheet(book: book, rating: $personalRating)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAllReviews) {
            AllReviewsView(book: book)
        }
        .onAppear { personalRating = item?.personalRating ?? 0 }
    }

    // MARK: - Hero

    private var hero: some View {
        GeometryReader { proxy in
            // Classic stretchy header: the artwork grows as the scroll view is
            // pulled down rather than leaving a gap.
            let offset = proxy.frame(in: .global).minY
            let extra = max(0, offset)

            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [book.genre.tint.opacity(0.55), Palette.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 380 + extra)
                .offset(y: -extra)
                .blur(radius: 0.5)

                VStack(spacing: Spacing.md) {
                    BookCoverView(book: book, width: 172)
                        .rotation3DEffect(
                            .degrees(min(8, extra * 0.06)),
                            axis: (x: 1, y: 0, z: 0),
                            anchor: .bottom
                        )
                        .scaleEffect(1 + extra * 0.0012, anchor: .bottom)

                    VStack(spacing: Spacing.xs) {
                        Text(book.title)
                            .font(AppFont.serif(25, .bold))
                            .foregroundStyle(Palette.textPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        if let subtitle = book.subtitle {
                            Text(subtitle)
                                .font(.system(size: 14))
                                .foregroundStyle(Palette.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            appState.push(.author(book.author))
                        } label: {
                            Text(book.author)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Palette.accent)
                                .underline(pattern: .dot)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                    }
                    .pageHorizontalPadding()
                }
                .padding(.bottom, Spacing.sm)
                .padding(.top, 70)
            }
            .frame(width: proxy.size.width)
        }
        .frame(height: 396)
    }

    // MARK: - Actions

    private var actions: some View {
        HStack(spacing: Spacing.md) {
            Button {
                appState.read(book, chapter: item?.chapterIndex, page: item?.pageIndex)
            } label: {
                Label(progress > 0 ? "Continue · \(Int(progress * 100))%" : "Start Reading",
                      systemImage: "book.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            CircleIconButton(
                symbol: item == nil ? "plus" : "checkmark",
                tint: item == nil ? Palette.textPrimary : .white,
                background: item == nil ? Palette.surface : Palette.sapphire,
                size: 50
            ) {
                if item == nil {
                    library.add(book, status: .wantToRead)
                    Haptics.success()
                } else {
                    showingShelfPicker = true
                }
            }
            .accessibilityLabel(item == nil ? "Add to library" : "Change shelf")

            CircleIconButton(
                symbol: item?.isDownloaded == true ? "arrow.down.circle.fill" : "arrow.down.circle",
                tint: item?.isDownloaded == true ? Palette.sapphire : Palette.textPrimary,
                size: 50
            ) {
                if item == nil { library.add(book, status: .wantToRead) }
                library.toggleDownload(bookID: book.id)
                Haptics.success()
            }
            .accessibilityLabel(item?.isDownloaded == true ? "Downloaded" : "Download")
        }
        .pageHorizontalPadding()
    }

    private var statsStrip: some View {
        HStack(spacing: 0) {
            statCell(value: book.rating.oneDecimal, label: "\(book.ratingCount.compactCount) ratings", symbol: "star.fill", tint: Palette.star)
            divider
            statCell(value: "\(book.pageCount)", label: "pages", symbol: "doc.text", tint: Palette.textSecondary)
            divider
            statCell(value: book.estimatedMinutes.durationLabel, label: "reading time", symbol: "clock", tint: Palette.textSecondary)
            divider
            statCell(value: book.isFree ? "Free" : book.priceLabel, label: book.isFree ? "to read" : "one-time", symbol: "tag", tint: book.isFree ? Palette.sapphire : Palette.accent)
        }
        .padding(.vertical, Spacing.md)
        .cardBackground()
        .pageHorizontalPadding()
    }

    private var divider: some View {
        Rectangle()
            .fill(Palette.separator)
            .frame(width: 1, height: 34)
    }

    private func statCell(value: String, label: String, symbol: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: symbol).font(.system(size: 10)).foregroundStyle(tint)
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Palette.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Synopsis

    private var synopsis: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "About this book")

            Text(book.synopsis)
                .font(.system(size: 15))
                .foregroundStyle(Palette.textSecondary)
                .lineSpacing(5)
                .lineLimit(synopsisExpanded ? nil : 4)
                .fixedSize(horizontal: false, vertical: true)

            Button(synopsisExpanded ? "Show less" : "Read more") {
                withAnimation(.smooth(duration: 0.3)) { synopsisExpanded.toggle() }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Palette.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pageHorizontalPadding()
    }

    private var tags: some View {
        FlowStack(spacing: Spacing.sm) {
            ForEach(book.allGenres) { genre in
                Button { appState.push(.genre(genre)) } label: {
                    TagChip(title: genre.rawValue, symbol: genre.symbol, tint: genre.tint)
                }
                .buttonStyle(.plain)
            }
            ForEach(book.tags, id: \.self) { tag in
                TagChip(title: tag, tint: Palette.textTertiary)
            }
        }
        .pageHorizontalPadding()
    }

    // MARK: - Chapters

    private var chapters: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(
                title: "Contents",
                subtitle: "\(book.chapters.count) chapters · \(book.estimatedMinutes.durationLabel)"
            )
            .pageHorizontalPadding()

            VStack(spacing: 0) {
                ForEach(Array(book.chapters.enumerated()), id: \.element.id) { index, chapter in
                    Button {
                        appState.read(book, chapter: index, page: 0)
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Text("\(chapter.number)")
                                .font(AppFont.rounded(13, .bold))
                                .foregroundStyle(isRead(index) ? .white : Palette.textTertiary)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle().fill(isRead(index) ? Palette.sapphire : Palette.surfaceSunken)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(chapter.title)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Palette.textPrimary)
                                    .lineLimit(1)
                                Text("\(book.estimatedMinutes(for: chapter)) min read")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Palette.textTertiary)
                            }

                            Spacer()

                            if index == item?.chapterIndex, progress > 0 {
                                TagChip(title: "Current", tint: Palette.accent, filled: true)
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Palette.textTertiary)
                        }
                        .padding(.vertical, Spacing.md)
                        .pageHorizontalPadding()
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableCardStyle(scale: 0.99))

                    if index < book.chapters.count - 1 {
                        Divider().padding(.leading, Spacing.page + 28 + Spacing.md)
                    }
                }
            }
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .strokeBorder(Palette.separator, lineWidth: 0.5)
            )
            .pageHorizontalPadding()
        }
    }

    private func isRead(_ index: Int) -> Bool {
        guard let item else { return false }
        return item.status == .finished || index < item.chapterIndex
    }

    // MARK: - Reviews

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Ratings & Reviews", actionTitle: "See all") {
                showingAllReviews = true
            }
            .pageHorizontalPadding()

            RatingBreakdownView(book: book)
                .pageHorizontalPadding()

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    ForEach(book.reviews.prefix(4)) { review in
                        ReviewCard(review: review)
                    }
                }
                .pageHorizontalPadding()
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)

            Button {
                showingRatingSheet = true
            } label: {
                Label(personalRating > 0 ? "You rated this \(personalRating) stars" : "Write a review",
                      systemImage: personalRating > 0 ? "star.fill" : "square.and.pencil")
            }
            .buttonStyle(SecondaryButtonStyle())
            .pageHorizontalPadding()
        }
    }

    // MARK: - Carousels & footer

    private func carousel(title: String, books: [Book]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: title).pageHorizontalPadding()

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    ForEach(books) { BookCard(book: $0) }
                }
                .pageHorizontalPadding()
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
        }
    }

    private var publisherInfo: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Details")

            infoRow("Publisher", book.publisher)
            infoRow("Published", "\(book.publishedYear)")
            infoRow("Language", book.language)
            infoRow("Length", "\(book.pageCount) pages")
            infoRow("Genre", book.allGenres.map(\.rawValue).joined(separator: ", "))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pageHorizontalPadding()
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Palette.textTertiary)
                .frame(width: 92, alignment: .leading)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 5)
    }

    /// Compact bar that stays available no matter how far the reader scrolls.
    private var floatingBar: some View {
        HStack(spacing: Spacing.md) {
            BookCoverView(book: book, width: 34, showsShadow: false)

            VStack(alignment: .leading, spacing: 1) {
                Text(book.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                Text(progress > 0 ? "\(Int(progress * 100))% complete" : book.priceLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textTertiary)
            }

            Spacer(minLength: Spacing.sm)

            Button {
                appState.read(book, chapter: item?.chapterIndex, page: item?.pageIndex)
            } label: {
                Text(progress > 0 ? "Continue" : "Read")
            }
            .buttonStyle(PrimaryButtonStyle(fullWidth: false))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.separator, lineWidth: 0.5))
        .softShadow(radius: 18, y: 6, opacity: 0.16)
        .padding(.horizontal, Spacing.page)
        .padding(.bottom, Spacing.sm)
    }

    private var shareText: String {
        "\(book.title) by \(book.author) — reading it on Books My Friend"
    }
}

// MARK: - Rating breakdown

struct RatingBreakdownView: View {
    let book: Book

    /// Derives a plausible histogram from the average. Real data would come
    /// from the store; the shape matters more than the exact counts here.
    private var distribution: [Int] {
        let total = book.ratingCount
        let average = book.rating
        let weights: [Double] = (1...5).map { star in
            let distance = abs(Double(star) - average)
            return exp(-distance * distance * 1.6)
        }
        let sum = weights.reduce(0, +)
        return weights.map { Int(Double(total) * $0 / sum) }
    }

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.xl) {
            VStack(spacing: 2) {
                Text(book.rating.oneDecimal)
                    .font(AppFont.rounded(44, .bold))
                    .foregroundStyle(Palette.textPrimary)
                StarRatingView(rating: book.rating, size: 11)
                Text("\(book.ratingCount.compactCount) ratings")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textTertiary)
            }

            VStack(spacing: 4) {
                ForEach((1...5).reversed(), id: \.self) { star in
                    HStack(spacing: Spacing.sm) {
                        Text("\(star)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Palette.textTertiary)
                            .frame(width: 8)

                        GeometryReader { proxy in
                            let maximum = max(1, distribution.max() ?? 1)
                            let fraction = Double(distribution[star - 1]) / Double(maximum)
                            ZStack(alignment: .leading) {
                                Capsule().fill(Palette.surfaceSunken)
                                Capsule()
                                    .fill(Palette.star)
                                    .frame(width: proxy.size.width * fraction)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Spacing.lg)
        .cardBackground()
    }
}

// MARK: - Review card

struct ReviewCard: View {
    let review: Review
    var width: CGFloat? = 280

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(Color(hue: Double(review.avatarSeed) / 360, saturation: 0.45, brightness: 0.7))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Text(review.author.prefix(1))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(review.author)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)
                    Text(review.date.relativeLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.textTertiary)
                }

                Spacer()
            }

            StarRatingView(rating: Double(review.rating), size: 10)

            Text(review.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)

            Text(review.body)
                .font(.system(size: 13))
                .foregroundStyle(Palette.textSecondary)
                .lineSpacing(3)
                .lineLimit(width == nil ? nil : 4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 4) {
                Image(systemName: "hand.thumbsup").font(.system(size: 10))
                Text("\(review.helpfulCount) found this helpful")
                    .font(.system(size: 11))
            }
            .foregroundStyle(Palette.textTertiary)
            .padding(.top, 2)
        }
        .padding(Spacing.md)
        .frame(width: width, alignment: .topLeading)
        .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
        .cardBackground()
    }
}

// MARK: - All reviews

struct AllReviewsView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    RatingBreakdownView(book: book)
                    ForEach(book.reviews) { review in
                        ReviewCard(review: review, width: nil)
                    }
                }
                .pageHorizontalPadding()
                .padding(.vertical, Spacing.lg)
            }
            .background(Palette.background)
            .navigationTitle("Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Shelf picker

struct ShelfPickerSheet: View {
    let book: Book
    @Environment(LibraryStore.self) private var library
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.sm) {
                ForEach(ShelfStatus.allCases) { status in
                    Button {
                        library.setStatus(status, for: book.id)
                        Haptics.success()
                        dismiss()
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: status.symbol)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(status.tint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                            Text(status.rawValue)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Palette.textPrimary)

                            Spacer()

                            if library.status(for: book.id) == status {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Palette.accent)
                            }
                        }
                        .padding(Spacing.md)
                        .cardBackground(Radius.md)
                    }
                    .buttonStyle(PressableCardStyle(scale: 0.98))
                }

                Button(role: .destructive) {
                    library.remove(bookID: book.id)
                    Haptics.warning()
                    dismiss()
                } label: {
                    Label("Remove from Library", systemImage: "trash")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                }
                .padding(.top, Spacing.xs)

                Spacer()
            }
            .pageHorizontalPadding()
            .padding(.top, Spacing.lg)
            .background(Palette.background)
            .navigationTitle("Move to shelf")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Rating sheet

struct RatingSheet: View {
    let book: Book
    @Binding var rating: Int
    @Environment(LibraryStore.self) private var library
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Capsule()
                .fill(Palette.separator)
                .frame(width: 36, height: 4)
                .padding(.top, Spacing.sm)

            Text("How was it?")
                .font(AppFont.serif(22, .semibold))
                .foregroundStyle(Palette.textPrimary)

            Text(book.title)
                .font(.system(size: 14))
                .foregroundStyle(Palette.textTertiary)
                .lineLimit(1)

            StarInputView(rating: $rating)
                .padding(.vertical, Spacing.sm)

            Text(caption)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.accent)
                .animation(.snappy, value: rating)

            Button("Save rating") {
                if library.item(for: book.id) == nil {
                    library.add(book, status: .finished)
                }
                library.rate(rating, bookID: book.id)
                Haptics.success()
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(rating == 0)
            .opacity(rating == 0 ? 0.5 : 1)
            .pageHorizontalPadding()

            Spacer()
        }
        .background(Palette.background)
    }

    private var caption: String {
        switch rating {
        case 1: "Not for me"
        case 2: "It was okay"
        case 3: "Good"
        case 4: "Really good"
        case 5: "Loved it"
        default: "Tap a star"
        }
    }
}
