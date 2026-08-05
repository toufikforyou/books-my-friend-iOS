//
//  ReaderSettings.swift
//  BooksMyFriend
//

import SwiftUI

// MARK: - Theme

enum ReaderTheme: String, CaseIterable, Identifiable, Codable {
    case paper, sepia, gray, night

    var id: String { rawValue }

    var title: String {
        switch self {
        case .paper: "Paper"
        case .sepia: "Sepia"
        case .gray: "Gray"
        case .night: "Night"
        }
    }

    var background: Color {
        switch self {
        case .paper: Color(hex: 0xFFFFFF)
        case .sepia: Color(hex: 0xF6EEDD)
        case .gray: Color(hex: 0x3A3A3C)
        case .night: Color(hex: 0x0A0A0B)
        }
    }

    var text: Color {
        switch self {
        case .paper: Color(hex: 0x1C1917)
        case .sepia: Color(hex: 0x3F3428)
        case .gray: Color(hex: 0xE8E6E3)
        case .night: Color(hex: 0xC9C6C2)
        }
    }

    var secondaryText: Color {
        text.opacity(0.55)
    }

    var accent: Color {
        switch self {
        case .paper, .sepia: Color(hex: 0x05715A)
        case .gray, .night: Color(hex: 0x34D399)
        }
    }

    var isDark: Bool { self == .gray || self == .night }

    /// The reader forces its own appearance so system dark mode can't wash out
    /// a deliberately light paper theme (or vice versa).
    var colorScheme: ColorScheme { isDark ? .dark : .light }
}

// MARK: - Typeface

enum ReaderFont: String, CaseIterable, Identifiable, Codable {
    case newYork, georgia, palatino, system, avenir, courier

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newYork: "New York"
        case .georgia: "Georgia"
        case .palatino: "Palatino"
        case .system: "San Francisco"
        case .avenir: "Avenir"
        case .courier: "Courier"
        }
    }

    /// Resolved UIFont — the reader lays out with TextKit, so it needs a
    /// concrete font rather than a SwiftUI `Font`.
    func uiFont(size: CGFloat) -> UIFont {
        switch self {
        case .newYork:
            // New York ships with the system as a serif design of SF.
            let descriptor = UIFont.systemFont(ofSize: size).fontDescriptor
                .withDesign(.serif) ?? UIFont.systemFont(ofSize: size).fontDescriptor
            return UIFont(descriptor: descriptor, size: size)
        case .georgia:
            return UIFont(name: "Georgia", size: size) ?? .systemFont(ofSize: size)
        case .palatino:
            return UIFont(name: "Palatino-Roman", size: size)
                ?? UIFont(name: "PalatinoLinotype-Roman", size: size)
                ?? .systemFont(ofSize: size)
        case .system:
            return .systemFont(ofSize: size)
        case .avenir:
            return UIFont(name: "AvenirNext-Regular", size: size) ?? .systemFont(ofSize: size)
        case .courier:
            return UIFont(name: "CourierNewPSMT", size: size) ?? .monospacedSystemFont(ofSize: size, weight: .regular)
        }
    }

    var sampleFont: Font {
        switch self {
        case .newYork: .system(size: 17, design: .serif)
        case .georgia: .custom("Georgia", size: 17)
        case .palatino: .custom("Palatino-Roman", size: 17)
        case .system: .system(size: 17)
        case .avenir: .custom("AvenirNext-Regular", size: 17)
        case .courier: .custom("CourierNewPSMT", size: 17)
        }
    }
}

// MARK: - Settings

@Observable
@MainActor
final class ReaderSettings {
    /// Backed by UserDefaults so preferences survive relaunch without dragging
    /// SwiftData into the render path of every page.
    private enum Key {
        static let theme = "reader.theme"
        static let font = "reader.font"
        static let fontSize = "reader.fontSize"
        static let lineSpacing = "reader.lineSpacing"
        static let margin = "reader.margin"
        static let scrollMode = "reader.scrollMode"
        static let justified = "reader.justified"
        static let brightness = "reader.brightness"
        static let keepAwake = "reader.keepAwake"
    }

    var theme: ReaderTheme { didSet { defaults.set(theme.rawValue, forKey: Key.theme) } }
    var font: ReaderFont { didSet { defaults.set(font.rawValue, forKey: Key.font) } }
    var fontSize: CGFloat { didSet { defaults.set(Double(fontSize), forKey: Key.fontSize) } }
    var lineSpacing: CGFloat { didSet { defaults.set(Double(lineSpacing), forKey: Key.lineSpacing) } }
    var margin: CGFloat { didSet { defaults.set(Double(margin), forKey: Key.margin) } }
    var scrollMode: Bool { didSet { defaults.set(scrollMode, forKey: Key.scrollMode) } }
    var justified: Bool { didSet { defaults.set(justified, forKey: Key.justified) } }
    var brightness: Double { didSet { defaults.set(brightness, forKey: Key.brightness) } }
    var keepScreenAwake: Bool {
        didSet {
            defaults.set(keepScreenAwake, forKey: Key.keepAwake)
            UIApplication.shared.isIdleTimerDisabled = keepScreenAwake
        }
    }

    private let defaults = UserDefaults.standard

    static let fontSizeRange: ClosedRange<CGFloat> = 14...30
    static let lineSpacingRange: ClosedRange<CGFloat> = 1.0...2.0
    static let marginRange: ClosedRange<CGFloat> = 16...48

    init() {
        theme = ReaderTheme(rawValue: defaults.string(forKey: Key.theme) ?? "") ?? .paper
        font = ReaderFont(rawValue: defaults.string(forKey: Key.font) ?? "") ?? .newYork
        let storedSize = defaults.double(forKey: Key.fontSize)
        fontSize = storedSize > 0 ? CGFloat(storedSize) : 19
        let storedSpacing = defaults.double(forKey: Key.lineSpacing)
        lineSpacing = storedSpacing > 0 ? CGFloat(storedSpacing) : 1.45
        let storedMargin = defaults.double(forKey: Key.margin)
        margin = storedMargin > 0 ? CGFloat(storedMargin) : 26
        scrollMode = defaults.bool(forKey: Key.scrollMode)
        justified = defaults.object(forKey: Key.justified) as? Bool ?? true
        let storedBrightness = defaults.double(forKey: Key.brightness)
        brightness = storedBrightness > 0 ? storedBrightness : 1.0
        keepScreenAwake = defaults.object(forKey: Key.keepAwake) as? Bool ?? true
    }

    /// Everything that invalidates pagination, in one comparable value. Views
    /// use it as the identity for the paginate task.
    var layoutSignature: String {
        "\(font.rawValue)-\(fontSize)-\(lineSpacing)-\(margin)-\(justified)"
    }

    func resetToDefaults() {
        theme = .paper
        font = .newYork
        fontSize = 19
        lineSpacing = 1.45
        margin = 26
        justified = true
    }

    // MARK: - Text attributes

    /// The single source of truth for how body text is styled. The paginator
    /// and the page renderer must use identical attributes or page boundaries
    /// will not match what is drawn.
    func bodyAttributes() -> [NSAttributedString.Key: Any] {
        let uiFont = font.uiFont(size: fontSize)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = lineSpacing
        paragraph.alignment = justified ? .justified : .natural
        paragraph.paragraphSpacing = fontSize * 0.65
        paragraph.hyphenationFactor = justified ? 1.0 : 0
        // Justified text without hyphenation produces rivers; with it, lines
        // break sensibly at typical phone widths.
        return [
            .font: uiFont,
            .paragraphStyle: paragraph,
            .foregroundColor: UIColor(theme.text),
            .kern: 0.1,
        ]
    }

    func attributedBody(_ text: String) -> NSAttributedString {
        NSAttributedString(string: text, attributes: bodyAttributes())
    }
}
