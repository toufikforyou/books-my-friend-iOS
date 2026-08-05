//
//  Components.swift
//  BooksMyFriend
//
//  Shared building blocks. Anything that appears on more than one screen lives
//  here so spacing and weight stay consistent across the app.
//

import SwiftUI

// MARK: - Star rating

struct StarRatingView: View {
    let rating: Double
    var size: CGFloat = 12
    var showsValue: Bool = false
    var count: Int? = nil

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: symbol(for: index))
                    .font(.system(size: size))
                    .foregroundStyle(Palette.star)
            }
            if showsValue {
                Text(rating.oneDecimal)
                    .font(.system(size: size + 1, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.leading, 2)
            }
            if let count {
                Text("(\(count.compactCount))")
                    .font(.system(size: size))
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rated \(rating.oneDecimal) out of 5")
    }

    private func symbol(for index: Int) -> String {
        let value = rating - Double(index)
        if value >= 0.75 { return "star.fill" }
        if value >= 0.25 { return "star.leadinghalf.filled" }
        return "star"
    }
}

/// Tappable variant used when the reader rates a book themselves.
struct StarInputView: View {
    @Binding var rating: Int
    var size: CGFloat = 28

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    Haptics.select()
                    rating = rating == value ? 0 : value
                } label: {
                    Image(systemName: value <= rating ? "star.fill" : "star")
                        .font(.system(size: size))
                        .foregroundStyle(value <= rating ? Palette.star : Palette.textTertiary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(value) star\(value == 1 ? "" : "s")")
            }
        }
    }
}

// MARK: - Chips

struct TagChip: View {
    let title: String
    var symbol: String? = nil
    var tint: Color = Palette.textSecondary
    var filled: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: 10, weight: .semibold))
            }
            Text(title)
        }
        .font(.chipLabel)
        .foregroundStyle(filled ? .white : tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(filled ? tint : tint.opacity(0.12))
        )
    }
}

struct FilterChip: View {
    let title: String
    var symbol: String? = nil
    let isSelected: Bool
    var tint: Color = Palette.accent
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.select()
            action()
        } label: {
            HStack(spacing: 5) {
                if let symbol {
                    Image(systemName: symbol).font(.system(size: 11, weight: .semibold))
                }
                Text(title)
            }
            .font(.chipLabel)
            .foregroundStyle(isSelected ? .white : Palette.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background {
                Capsule()
                    .fill(isSelected ? tint : Palette.surface)
                    .overlay(
                        Capsule().strokeBorder(
                            isSelected ? .clear : Palette.separator,
                            lineWidth: 1
                        )
                    )
            }
        }
        .buttonStyle(.plain)
        .animation(.snappy(duration: 0.2), value: isSelected)
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Palette.accent
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .applyIf(fullWidth) { $0.frame(maxWidth: .infinity) }
            .applyIf(!fullWidth) { $0.padding(.horizontal, 24) }
            .background(tint, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Palette.textPrimary)
            .padding(.vertical, 15)
            .applyIf(fullWidth) { $0.frame(maxWidth: .infinity) }
            .applyIf(!fullWidth) { $0.padding(.horizontal, 24) }
            .background {
                Capsule()
                    .fill(Palette.surfaceSunken)
                    .overlay(Capsule().strokeBorder(Palette.separator, lineWidth: 1))
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

/// Circular glyph button used in toolbars and over artwork.
struct CircleIconButton: View {
    let symbol: String
    var tint: Color = Palette.textPrimary
    var background: Color = Palette.surface
    var size: CGFloat = 38
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(background, in: Circle())
                .overlay(Circle().strokeBorder(Palette.separator.opacity(0.6), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.sectionTitle)
                    .foregroundStyle(Palette.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.textTertiary)
                }
            }
            Spacer(minLength: Spacing.sm)
            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 2) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Progress ring

struct ProgressRing: View {
    let progress: Double
    var size: CGFloat = 44
    var lineWidth: CGFloat = 4
    var tint: Color = Palette.accent
    var showsLabel: Bool = true

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.smooth(duration: 0.5), value: progress)
            if showsLabel {
                Text("\(Int(progress * 100))")
                    .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.textPrimary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(progress * 100)) percent complete")
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Palette.accentSoft)
                    .frame(width: 92, height: 92)
                Image(systemName: symbol)
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(Palette.accent)
            }

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(AppFont.serif(20, .semibold))
                    .foregroundStyle(Palette.textPrimary)
                Text(message)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                    .padding(.top, Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.huge)
    }
}

// MARK: - Stat tile

struct StatTile: View {
    let value: String
    let label: String
    let symbol: String
    var tint: Color = Palette.accent

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            Text(value)
                .font(AppFont.rounded(24, .bold))
                .foregroundStyle(Palette.textPrimary)
                .contentTransition(.numericText())

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Palette.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .cardBackground(Radius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Loading shimmer

/// Placeholder used while pagination runs. Deliberately plain — a shimmering
/// skeleton would draw attention to a wait that is normally under a second.
struct LoadingView: View {
    let message: String

    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Palette.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
