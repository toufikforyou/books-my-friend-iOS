//
//  PageTextView.swift
//  BooksMyFriend
//
//  Renders one paginated page. Backed by UITextView rather than SwiftUI `Text`
//  for three reasons the reader depends on: layout identical to the CoreText
//  pagination pass, real text selection, and a custom selection menu for
//  highlighting.
//

import SwiftUI
import UIKit

/// What a tap on the page means, decided by where it landed.
enum PageTapZone {
    case previous, next, toggleChrome
}

struct PageTextView: UIViewRepresentable {
    /// Text for this page, already styled.
    let attributed: NSAttributedString
    /// Where this page starts inside the chapter, so selection ranges can be
    /// translated back to chapter coordinates.
    let pageOffset: Int
    /// Highlights overlapping this page, in chapter coordinates.
    let highlights: [Highlight]
    let theme: ReaderTheme
    /// The exact box the paginator measured against. The text container is
    /// pinned to it, because a non-scrolling UITextView otherwise lays out
    /// against an unbounded width and never wraps.
    let size: CGSize
    var isSelectable: Bool = true

    var onTap: (PageTapZone) -> Void
    var onHighlight: (NSRange, String, HighlightColor) -> Void
    var onTapHighlight: (Highlight) -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.isSelectable = isSelectable
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        // The paginator measured against a plain rectangle, so the text
        // container must not add insets of its own or lines will differ.
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.delegate = context.coordinator
        textView.linkTextAttributes = [:]
        textView.adjustsFontForContentSizeCategory = false

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.cancelsTouchesInView = false
        // UITextView installs its own tap recognizer for selection, which
        // otherwise swallows every tap that lands on a glyph — i.e. most of a
        // full page. Recognizing simultaneously keeps both behaviours.
        tap.delegate = context.coordinator
        textView.addGestureRecognizer(tap)
        context.coordinator.textView = textView

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        textView.isSelectable = isSelectable

        // Pin the layout box before setting text, so the first layout pass
        // already wraps at the paginated width.
        if textView.bounds.size != size {
            textView.frame = CGRect(origin: .zero, size: size)
        }
        textView.textContainer.size = size

        textView.attributedText = decorated()
        textView.tintColor = UIColor(theme.accent)
    }

    /// Report the paginated size rather than the text view's fitting size —
    /// every page occupies the same box whether it is full or half empty.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        size
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Highlight decoration

    /// Applies stored highlights to the page's text as background colour.
    private func decorated() -> NSAttributedString {
        guard !highlights.isEmpty else { return attributed }

        let mutable = NSMutableAttributedString(attributedString: attributed)
        let pageRange = NSRange(location: pageOffset, length: attributed.length)

        for highlight in highlights {
            let intersection = NSIntersectionRange(pageRange, highlight.range)
            guard intersection.length > 0 else { continue }

            // Translate from chapter coordinates into page coordinates.
            let local = NSRange(
                location: intersection.location - pageOffset,
                length: intersection.length
            )
            guard local.location >= 0, local.upperBound <= mutable.length else { continue }

            mutable.addAttribute(
                .backgroundColor,
                value: UIColor(highlight.color.color),
                range: local
            )
            if !highlight.note.isEmpty {
                // A note is signalled with an underline so annotated passages
                // are distinguishable from plain highlights at a glance.
                mutable.addAttributes(
                    [.underlineStyle: NSUnderlineStyle.single.rawValue,
                     .underlineColor: UIColor(highlight.color.accent)],
                    range: local
                )
            }
        }
        return mutable
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        var parent: PageTextView
        weak var textView: UITextView?

        init(parent: PageTextView) {
            self.parent = parent
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            true
        }

        /// Wait for long presses to fail before treating a touch as a tap.
        ///
        /// Without this, the touch-up that ends a selection long-press also
        /// satisfies the tap recognizer, which would immediately clear the
        /// selection the reader just made and dismiss the highlight menu.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRequireFailureOf other: UIGestureRecognizer
        ) -> Bool {
            other is UILongPressGestureRecognizer
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view else { return }

            // A tap that dismisses an active selection should do only that.
            if let textView, textView.selectedRange.length > 0 {
                textView.selectedTextRange = nil
                return
            }

            // A tap that lands on an existing highlight opens it instead of
            // paging, which is what a reader reaching for their own note wants.
            let point = recognizer.location(in: view)
            if let textView, let highlight = highlight(at: point, in: textView) {
                parent.onTapHighlight(highlight)
                return
            }

            let width = view.bounds.width
            let x = point.x
            if x < width * 0.28 {
                parent.onTap(.previous)
            } else if x > width * 0.72 {
                parent.onTap(.next)
            } else {
                parent.onTap(.toggleChrome)
            }
        }

        private func highlight(at point: CGPoint, in textView: UITextView) -> Highlight? {
            guard let position = textView.closestPosition(to: point) else { return nil }
            let offset = textView.offset(from: textView.beginningOfDocument, to: position)
            let chapterOffset = offset + parent.pageOffset
            return parent.highlights.first {
                NSLocationInRange(chapterOffset, $0.range)
            }
        }

        /// Replaces the system selection menu with highlight colours.
        func textView(
            _ textView: UITextView,
            editMenuForTextIn range: NSRange,
            suggestedActions: [UIMenuElement]
        ) -> UIMenu? {
            guard range.length > 0 else { return nil }

            let text = (textView.text as NSString).substring(with: range)
            let chapterRange = NSRange(location: range.location + parent.pageOffset, length: range.length)

            let colorActions = HighlightColor.allCases.map { color in
                UIAction(
                    title: color.rawValue.capitalized,
                    image: UIImage(systemName: "circle.fill")?
                        .withTintColor(UIColor(color.accent), renderingMode: .alwaysOriginal)
                ) { [weak self] _ in
                    self?.parent.onHighlight(chapterRange, text, color)
                    textView.selectedTextRange = nil
                }
            }

            let highlightMenu = UIMenu(
                title: "Highlight",
                image: UIImage(systemName: "highlighter"),
                children: colorActions
            )

            return UIMenu(children: [highlightMenu] + suggestedActions)
        }
    }
}
