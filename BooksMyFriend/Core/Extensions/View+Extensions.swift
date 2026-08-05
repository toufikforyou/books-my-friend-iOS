//
//  View+Extensions.swift
//  BooksMyFriend
//

import SwiftUI

extension View {
    func pageHorizontalPadding() -> some View {
        padding(.horizontal, Spacing.page)
    }

    /// Applies a modifier only when `condition` holds. Kept deliberately rare —
    /// branching on view identity can reset animations, so it is only used for
    /// leaf styling.
    @ViewBuilder
    func applyIf<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition { transform(self) } else { self }
    }

    /// Hit area padding without affecting layout, so small glyph buttons still
    /// clear the 44pt minimum target.
    func expandedTapTarget(_ size: CGFloat = 44) -> some View {
        frame(minWidth: size, minHeight: size)
            .contentShape(Rectangle())
    }

    func cardBackground(_ radius: CGFloat = Radius.lg) -> some View {
        background(Palette.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Palette.separator, lineWidth: 0.5)
            )
    }
}

extension Double {
    /// "4.6" rather than "4.599999".
    var oneDecimal: String { String(format: "%.1f", self) }
}

extension Int {
    /// 12_400 → "12.4K". Used for rating counts and reader counts.
    var compactCount: String {
        switch self {
        case 1_000_000...:
            return "\(Double(self / 100_000) / 10)M"
        case 1_000...:
            return "\(Double(self / 100) / 10)K"
        default:
            return "\(self)"
        }
    }

    /// 154 → "2h 34m", 45 → "45m".
    var durationLabel: String {
        let hours = self / 60
        let minutes = self % 60
        if hours == 0 { return "\(minutes)m" }
        if minutes == 0 { return "\(hours)h" }
        return "\(hours)h \(minutes)m"
    }
}

extension Date {
    var relativeLabel: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: .now)
    }
}
