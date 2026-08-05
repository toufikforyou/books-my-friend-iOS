// Renders the Books My Friend app icon.
//
// The mark: an open book in ivory over a jewel gradient that runs emerald to
// sapphire — the app's two brand colours — with an emerald ribbon falling past
// the lower edge. The ribbon sits over the blue end of the gradient so it stays
// legible, and the silhouette still reads at 40pt on a home screen.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size: CGFloat = 1024

struct Palette {
    let top: CGColor
    let bottom: CGColor
    let page: CGColor
    let pageShade: CGColor
    let rule: CGColor
    let ribbon: CGColor
    let ribbonShade: CGColor
    let highlight: CGFloat
}

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

let light = Palette(
    top: rgb(0x0E9070), bottom: rgb(0x123C86),
    page: rgb(0xFBFDFC), pageShade: rgb(0xDCE7E3),
    rule: rgb(0x05715A, 0.26),
    ribbon: rgb(0x10B981), ribbonShade: rgb(0x0A8560),
    highlight: 0.18
)

let dark = Palette(
    top: rgb(0x064E3B), bottom: rgb(0x061E42),
    page: rgb(0xE6EEEB), pageShade: rgb(0xBECCC7),
    rule: rgb(0x05715A, 0.34),
    ribbon: rgb(0x34D399), ribbonShade: rgb(0x1E9B75),
    highlight: 0.10
)

let tinted = Palette(
    top: rgb(0x2A2A2A), bottom: rgb(0x0A0A0A),
    page: rgb(0xF2F2F2), pageShade: rgb(0xC4C4C4),
    rule: rgb(0x808080, 0.35),
    ribbon: rgb(0x9A9A9A), ribbonShade: rgb(0x6E6E6E),
    highlight: 0.08
)

func draw(_ palette: Palette, to url: URL) {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let ctx = CGContext(
        data: nil, width: Int(size), height: Int(size),
        bitsPerComponent: 8, bytesPerRow: 0, space: space,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { fatalError("no context") }

    // Flip to a top-left origin so the geometry below reads like a design spec.
    ctx.translateBy(x: 0, y: size)
    ctx.scaleBy(x: 1, y: -1)

    // MARK: Background
    let gradient = CGGradient(
        colorsSpace: space,
        colors: [palette.top, palette.bottom] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: 0),
        end: CGPoint(x: size, y: size),
        options: []
    )

    // A soft top-left lift keeps the field from looking like flat plastic.
    let glow = CGGradient(
        colorsSpace: space,
        colors: [CGColor(gray: 1, alpha: palette.highlight), CGColor(gray: 1, alpha: 0)] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawRadialGradient(
        glow,
        startCenter: CGPoint(x: size * 0.3, y: size * 0.18), startRadius: 0,
        endCenter: CGPoint(x: size * 0.3, y: size * 0.18), endRadius: size * 0.78,
        options: []
    )

    // MARK: Geometry
    let cx = size / 2
    let halfWidth: CGFloat = 312
    let spineGap: CGFloat = 9
    let topOuter: CGFloat = 316      // outer corners sit lower than the spine
    let topInner: CGFloat = 356      // where the pages meet the spine
    let bottomOuter: CGFloat = 648
    let bottomInner: CGFloat = 704

    /// One page of the open book. `direction` is -1 for the left leaf.
    func page(_ direction: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let inner = cx + direction * spineGap
        let outer = cx + direction * halfWidth

        path.move(to: CGPoint(x: inner, y: topInner))
        // Top edge: bows upward toward the outer corner.
        path.addQuadCurve(
            to: CGPoint(x: outer, y: topOuter),
            control: CGPoint(x: cx + direction * 150, y: topOuter - 30)
        )
        path.addLine(to: CGPoint(x: outer, y: bottomOuter))
        // Bottom edge: mirrors the top so the leaf looks like paper, not a box.
        path.addQuadCurve(
            to: CGPoint(x: inner, y: bottomInner),
            control: CGPoint(x: cx + direction * 150, y: bottomOuter + 34)
        )
        path.closeSubpath()
        return path
    }

    // Drop shadow under the whole book.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -22), blur: 46,
                  color: CGColor(gray: 0, alpha: 0.30))
    ctx.setFillColor(palette.page)
    ctx.addPath(page(-1))
    ctx.addPath(page(1))
    ctx.fillPath()
    ctx.restoreGState()

    // Re-fill flat on top of the shadowed pass.
    ctx.setFillColor(palette.page)
    ctx.addPath(page(-1))
    ctx.addPath(page(1))
    ctx.fillPath()

    // MARK: Text rules
    // Four short rules per leaf, tapering toward the outer edge. At icon sizes
    // they read as "text" rather than as individual lines.
    ctx.setFillColor(palette.rule)
    for direction in [CGFloat(-1), CGFloat(1)] {
        for index in 0..<4 {
            let y = topInner + 52 + CGFloat(index) * 62
            let inset: CGFloat = 50
            let length = (halfWidth - inset - 36) * (index == 3 ? 0.62 : 1.0)
            let startX = direction < 0
                ? cx - spineGap - inset - length
                : cx + spineGap + inset
            let rect = CGRect(x: startX, y: y, width: length, height: 15)
            ctx.addPath(CGPath(roundedRect: rect, cornerWidth: 7.5, cornerHeight: 7.5, transform: nil))
        }
    }
    ctx.fillPath()

    // MARK: Spine
    // A soft wedge of shade where the leaves meet, so the book reads as open.
    let spine = CGGradient(
        colorsSpace: space,
        colors: [palette.pageShade, CGColor(gray: 0, alpha: 0)] as CFArray,
        locations: [0, 1]
    )!
    for direction in [CGFloat(-1), CGFloat(1)] {
        ctx.saveGState()
        ctx.addPath(page(direction))
        ctx.clip()
        ctx.drawLinearGradient(
            spine,
            start: CGPoint(x: cx + direction * spineGap, y: 0),
            end: CGPoint(x: cx + direction * 86, y: 0),
            options: []
        )
        ctx.restoreGState()
    }

    // MARK: Ribbon
    // Falls from behind the top edge and past the bottom of the book, which is
    // what makes the silhouette distinctive in a grid of square icons.
    let ribbonX = cx + 138
    let ribbonWidth: CGFloat = 70
    let ribbonTop: CGFloat = 330
    let ribbonBottom: CGFloat = 838
    let notch: CGFloat = 52

    let ribbon = CGMutablePath()
    ribbon.move(to: CGPoint(x: ribbonX, y: ribbonTop))
    ribbon.addLine(to: CGPoint(x: ribbonX + ribbonWidth, y: ribbonTop))
    ribbon.addLine(to: CGPoint(x: ribbonX + ribbonWidth, y: ribbonBottom))
    ribbon.addLine(to: CGPoint(x: ribbonX + ribbonWidth / 2, y: ribbonBottom - notch))
    ribbon.addLine(to: CGPoint(x: ribbonX, y: ribbonBottom))
    ribbon.closeSubpath()

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 20,
                  color: CGColor(gray: 0, alpha: 0.28))
    ctx.setFillColor(palette.ribbon)
    ctx.addPath(ribbon)
    ctx.fillPath()
    ctx.restoreGState()

    // Shade the ribbon where it passes over the page, selling the overlap.
    ctx.saveGState()
    ctx.addPath(page(1))
    ctx.clip()
    ctx.setFillColor(palette.ribbonShade)
    ctx.addPath(ribbon)
    ctx.fillPath()
    ctx.restoreGState()

    guard let image = ctx.makeImage(),
          let destination = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil
          ) else { fatalError("no image") }
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
    print("wrote \(url.lastPathComponent)")
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
draw(light, to: outputDirectory.appendingPathComponent("AppIcon-light.png"))
draw(dark, to: outputDirectory.appendingPathComponent("AppIcon-dark.png"))
draw(tinted, to: outputDirectory.appendingPathComponent("AppIcon-tinted.png"))
