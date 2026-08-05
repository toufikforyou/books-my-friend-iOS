//
//  ProfileView.swift
//  BooksMyFriend
//

import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(LibraryStore.self) private var library

    @AppStorage("profile.name") private var name = "Reader"
    @AppStorage("profile.yearlyGoal") private var yearlyGoal = 24

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                header
                statsGrid
                goalCard
                weeklyChart
                achievements
                shortcuts

                Color.clear.frame(height: Spacing.xl)
            }
            .padding(.top, Spacing.sm)
        }
        .scrollIndicators(.hidden)
        .background(Palette.background)
        .navigationTitle("You")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { appState.push(.settings) } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Palette.accent, Palette.accent.mix(with: .black, by: 0.3)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 86, height: 86)

                Text(name.prefix(1).uppercased())
                    .font(AppFont.rounded(34, .bold))
                    .foregroundStyle(.white)

                if library.streak > 0 {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Palette.rose, in: Circle())
                        .overlay(Circle().strokeBorder(Palette.background, lineWidth: 2.5))
                        .offset(x: 30, y: 30)
                }
            }

            VStack(spacing: 3) {
                Text(name)
                    .font(AppFont.serif(23, .bold))
                    .foregroundStyle(Palette.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textTertiary)
            }
        }
    }

    private var subtitle: String {
        let finished = library.booksFinished
        if finished == 0 { return "Just getting started" }
        if library.streak >= 7 { return "\(finished) books finished · \(library.streak)-day streak" }
        return "\(finished) book\(finished == 1 ? "" : "s") finished"
    }

    // MARK: - Stats

    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: Spacing.md),
                      GridItem(.flexible(), spacing: Spacing.md)],
            spacing: Spacing.md
        ) {
            StatTile(value: "\(library.streak)", label: "Day streak", symbol: "flame.fill", tint: Palette.rose)
            StatTile(value: library.totalMinutesRead.durationLabel, label: "Total read", symbol: "clock.fill", tint: Palette.accent)
            StatTile(value: "\(library.booksFinished)", label: "Books finished", symbol: "checkmark.seal.fill", tint: Palette.sapphire)
            StatTile(value: "\(library.highlights.count)", label: "Highlights", symbol: "highlighter", tint: Palette.plum)
        }
        .pageHorizontalPadding()
    }

    // MARK: - Yearly goal

    private var goalCard: some View {
        let finished = library.booksFinishedThisYear
        let progress = yearlyGoal > 0 ? min(1, Double(finished) / Double(yearlyGoal)) : 0
        let year = Calendar.current.component(.year, from: .now)

        return VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    // Plain interpolation of an Int would render "2,026".
                    Text("\(year, format: .number.grouping(.never)) Reading Goal")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)
                    Text(finished >= yearlyGoal
                         ? "Goal met — \(finished) books read"
                         : "\(finished) of \(yearlyGoal) books")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                ProgressRing(progress: progress, size: 58, lineWidth: 6, tint: Palette.sapphire)
            }

            Stepper(value: $yearlyGoal, in: 1...200) {
                Text("Target: \(yearlyGoal) books")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textTertiary)
            }
            .tint(Palette.accent)

            if finished < yearlyGoal {
                Text(paceMessage(finished: finished))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Palette.accent)
            }
        }
        .padding(Spacing.lg)
        .cardBackground()
        .pageHorizontalPadding()
    }

    /// Compares books-per-day so far with the rate needed to finish on time.
    private func paceMessage(finished: Int) -> String {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: .now) ?? 1
        let daysInYear = calendar.range(of: .day, in: .year, for: .now)?.count ?? 365
        let expected = Double(yearlyGoal) * Double(dayOfYear) / Double(daysInYear)

        if Double(finished) >= expected {
            return "You're ahead of pace — nicely done."
        }
        let behind = Int((expected - Double(finished)).rounded(.up))
        return "\(behind) book\(behind == 1 ? "" : "s") behind pace. Still plenty of year left."
    }

    // MARK: - Weekly chart

    private var weeklyChart: some View {
        let data = library.dailyMinutes(days: 7)
        let peak = max(1, data.map(\.minutes).max() ?? 1)

        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("This week")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                Spacer()
                Text("\(data.reduce(0) { $0 + $1.minutes }) min")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.accent)
            }

            HStack(alignment: .bottom, spacing: Spacing.sm) {
                ForEach(data, id: \.date) { entry in
                    VStack(spacing: 6) {
                        Text(entry.minutes > 0 ? "\(entry.minutes)" : "")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Palette.textTertiary)

                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(entry.minutes > 0 ? Palette.accent : Palette.surfaceSunken)
                            .frame(height: max(6, 96 * CGFloat(entry.minutes) / CGFloat(peak)))

                        Text(dayLabel(entry.date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(
                                Calendar.current.isDateInToday(entry.date)
                                ? Palette.accent : Palette.textTertiary
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 132, alignment: .bottom)
            .animation(.smooth, value: peak)
        }
        .padding(Spacing.lg)
        .cardBackground()
        .pageHorizontalPadding()
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"  // single-letter weekday
        return formatter.string(from: date)
    }

    // MARK: - Achievements

    private var achievements: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Achievements",
                          subtitle: "\(unlocked.count) of \(Achievement.all.count) unlocked")
            .pageHorizontalPadding()

            ScrollView(.horizontal) {
                HStack(spacing: Spacing.md) {
                    ForEach(Achievement.all) { achievement in
                        AchievementBadge(
                            achievement: achievement,
                            isUnlocked: unlocked.contains(achievement.id)
                        )
                    }
                }
                .pageHorizontalPadding()
            }
            .scrollIndicators(.hidden)
        }
    }

    private var unlocked: Set<String> {
        Achievement.unlocked(
            booksFinished: library.booksFinished,
            streak: library.streak,
            minutes: library.totalMinutesRead,
            highlights: library.highlights.count,
            librarySize: library.items.count
        )
    }

    // MARK: - Shortcuts

    private var shortcuts: some View {
        VStack(spacing: 0) {
            shortcutRow("Highlights & Notes", "highlighter", "\(library.highlights.count)") {
                appState.push(.allHighlights)
            }
            Divider().padding(.leading, 58)
            shortcutRow("Reading Statistics", "chart.bar.fill", nil) {
                appState.push(.readingStats)
            }
            Divider().padding(.leading, 58)
            shortcutRow("Settings", "gearshape.fill", nil) {
                appState.push(.settings)
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

    private func shortcutRow(
        _ title: String,
        _ symbol: String,
        _ badge: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: symbol)
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 30, height: 30)
                    .background(Palette.accentSoft, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textPrimary)

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.textTertiary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.textTertiary)
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle(scale: 0.99))
    }
}

// MARK: - Achievements

struct Achievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let tint: Color

    static let all: [Achievement] = [
        .init(id: "first-book", title: "First Page", detail: "Finish your first book", symbol: "book.closed.fill", tint: Palette.accent),
        .init(id: "streak-7", title: "Seven Days", detail: "Read 7 days in a row", symbol: "flame.fill", tint: Palette.rose),
        .init(id: "streak-30", title: "Devoted", detail: "Read 30 days in a row", symbol: "crown.fill", tint: Palette.amber),
        .init(id: "hours-10", title: "Ten Hours", detail: "Read for 10 hours total", symbol: "clock.fill", tint: Palette.sapphire),
        .init(id: "books-5", title: "Shelf Builder", detail: "Finish 5 books", symbol: "books.vertical.fill", tint: Palette.plum),
        .init(id: "highlights-25", title: "Annotator", detail: "Make 25 highlights", symbol: "highlighter", tint: Palette.amber),
        .init(id: "collector", title: "Collector", detail: "Add 10 books to your library", symbol: "square.stack.3d.up.fill", tint: Palette.sapphire),
    ]

    static func unlocked(
        booksFinished: Int,
        streak: Int,
        minutes: Int,
        highlights: Int,
        librarySize: Int
    ) -> Set<String> {
        var result: Set<String> = []
        if booksFinished >= 1 { result.insert("first-book") }
        if booksFinished >= 5 { result.insert("books-5") }
        if streak >= 7 { result.insert("streak-7") }
        if streak >= 30 { result.insert("streak-30") }
        if minutes >= 600 { result.insert("hours-10") }
        if highlights >= 25 { result.insert("highlights-25") }
        if librarySize >= 10 { result.insert("collector") }
        return result
    }
}

struct AchievementBadge: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.tint.opacity(0.16) : Palette.surfaceSunken)
                    .frame(width: 58, height: 58)
                Image(systemName: isUnlocked ? achievement.symbol : "lock.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(isUnlocked ? achievement.tint : Palette.textTertiary.opacity(0.5))
            }

            VStack(spacing: 1) {
                Text(achievement.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isUnlocked ? Palette.textPrimary : Palette.textTertiary)
                Text(achievement.detail)
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 86)
        }
        .opacity(isUnlocked ? 1 : 0.65)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.title), \(isUnlocked ? "unlocked" : "locked"). \(achievement.detail)")
    }
}
