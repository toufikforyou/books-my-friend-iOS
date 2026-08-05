//
//  Theme.swift
//  BooksMyFriend
//
//  Design tokens: color, type, spacing, radius, elevation.
//

import SwiftUI

// MARK: - Color tokens

extension Color {
    /// Builds a colour that resolves differently in light and dark appearance.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// Namespace for every colour the app is allowed to use.
///
/// The brand runs on two jewel tones — a deep emerald and a sapphire — over
/// cool near-neutrals. Gold appears in exactly one place, on star ratings,
/// which is what keeps it feeling like an accent rather than decoration.
enum Palette {
    /// Emerald — the primary brand colour: calls to action, progress, streaks.
    static let accent = Color(light: 0x05715A, dark: 0x34D399)
    static let accentSoft = Color(light: 0xD6F1E7, dark: 0x0B2B23)

    /// Sapphire — the secondary brand colour: downloads, completion, success.
    static let sapphire = Color(light: 0x1D4ED8, dark: 0x60A5FA)
    static let sapphireSoft = Color(light: 0xDCE8FE, dark: 0x0E1F45)

    static let plum = Color(light: 0x6D28D9, dark: 0xA78BFA)
    static let rose = Color(light: 0xBE123C, dark: 0xFB7185)
    static let amber = Color(light: 0xB45309, dark: 0xFBBF24)

    /// Backgrounds — cool off-white, and a near-black with a green undertone
    /// so dark mode sits under the brand rather than beside it.
    static let background = Color(light: 0xF7F9F8, dark: 0x070B0A)
    static let surface = Color(light: 0xFFFFFF, dark: 0x101614)
    static let surfaceElevated = Color(light: 0xFFFFFF, dark: 0x18201D)
    static let surfaceSunken = Color(light: 0xECF1EF, dark: 0x0C1210)

    /// Text.
    static let textPrimary = Color(light: 0x0F1A17, dark: 0xF3F6F5)
    static let textSecondary = Color(light: 0x4A5754, dark: 0x9FADA9)
    static let textTertiary = Color(light: 0x7C8A86, dark: 0x6E7C78)

    static let separator = Color(light: 0xE0E7E4, dark: 0x222D29)

    /// The one warm colour in the system.
    static let star = Color(light: 0xD79A16, dark: 0xFBBF24)
}

// MARK: - Typography

enum AppFont {
    /// Serif face for anything editorial — titles, book names, reading text.
    /// Falls back gracefully because `.serif` is a system design, not a bundled font.
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension Font {
    /// Large editorial screen title.
    static let displayTitle = AppFont.serif(34, .bold)
    /// Section header above a carousel.
    static let sectionTitle = AppFont.serif(21, .semibold)
    /// Book title inside a card.
    static let cardTitle = Font.system(size: 15, weight: .semibold)
    static let cardSubtitle = Font.system(size: 13, weight: .regular)
    static let metaLabel = Font.system(size: 12, weight: .medium)
    static let chipLabel = Font.system(size: 13, weight: .semibold)
}

// MARK: - Layout

enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let huge: CGFloat = 48

    /// Standard horizontal page inset. Every screen agrees on this number.
    static let page: CGFloat = 20
}

enum Radius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    /// Book covers use a small radius so the "paper" silhouette stays readable.
    static let cover: CGFloat = 10
}

enum Metrics {
    /// Every cover in the app uses the same aspect ratio, which is what makes
    /// mixed grids and carousels line up.
    static let coverAspect: CGFloat = 2.0 / 3.0
    static let cardWidth: CGFloat = 132
    static let heroWidth: CGFloat = 260
}

// MARK: - Elevation

extension View {
    /// Soft, warm shadow. Used sparingly — only covers and floating bars.
    func softShadow(radius: CGFloat = 14, y: CGFloat = 8, opacity: Double = 0.14) -> some View {
        shadow(color: .black.opacity(opacity), radius: radius, x: 0, y: y)
    }

    func coverShadow() -> some View {
        shadow(color: .black.opacity(0.22), radius: 10, x: 0, y: 6)
    }
}
