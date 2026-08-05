//
//  Paginator.swift
//  BooksMyFriend
//
//  Splits a chapter into fixed-size pages using CoreText, which is what lets
//  the reader behave like a book rather than a scroll view: stable page counts,
//  resumable positions, and "12 pages left in this chapter".
//

import CoreText
import Foundation
import UIKit

struct PaginatedChapter {
    let chapterIndex: Int
    /// Character ranges into the chapter body, one per page.
    let pageRanges: [NSRange]

    var pageCount: Int { pageRanges.count }
}

enum Paginator {

    /// Breaks `text` into pages that fit `size`.
    ///
    /// Uses `CTFrameGetVisibleStringRange`, so the split points are the ones
    /// TextKit would choose for the same attributes — the renderer therefore
    /// draws exactly one page's worth with no clipped final line.
    static func paginate(_ text: NSAttributedString, size: CGSize) -> [NSRange] {
        guard text.length > 0, size.width > 1, size.height > 1 else { return [] }

        let framesetter = CTFramesetterCreateWithAttributedString(text)
        let path = CGPath(rect: CGRect(origin: .zero, size: size), transform: nil)

        var ranges: [NSRange] = []
        var location = 0

        while location < text.length {
            let frame = CTFramesetterCreateFrame(
                framesetter,
                CFRange(location: location, length: 0),
                path,
                nil
            )
            let visible = CTFrameGetVisibleStringRange(frame)

            // A zero-length page means nothing fits (e.g. the box is shorter
            // than one line). Bail rather than loop forever.
            guard visible.length > 0 else { break }

            ranges.append(NSRange(location: location, length: visible.length))
            location += visible.length
        }

        // Anything left over (possible when the guard above fires) becomes a
        // final page so no text is silently dropped.
        if location < text.length, !ranges.isEmpty {
            ranges.append(NSRange(location: location, length: text.length - location))
        }

        return ranges.isEmpty ? [NSRange(location: 0, length: text.length)] : ranges
    }

    /// Paginates every chapter of a book. Pure and `nonisolated`, so it can run
    /// off the main actor for long books.
    static func paginateBook(
        chapters: [String],
        attributes: [NSAttributedString.Key: Any],
        size: CGSize
    ) -> [PaginatedChapter] {
        chapters.enumerated().map { index, body in
            PaginatedChapter(
                chapterIndex: index,
                pageRanges: paginate(NSAttributedString(string: body, attributes: attributes), size: size)
            )
        }
    }
}

// MARK: - Book-level pagination result

/// Flattened pagination for a whole book, with the arithmetic the reader needs
/// (global page numbers, progress, pages remaining) precomputed.
struct BookPagination {
    let chapters: [PaginatedChapter]

    var totalPages: Int {
        chapters.reduce(0) { $0 + $1.pageCount }
    }

    func pageCount(chapter: Int) -> Int {
        chapters.indices.contains(chapter) ? chapters[chapter].pageCount : 0
    }

    func range(chapter: Int, page: Int) -> NSRange? {
        guard chapters.indices.contains(chapter),
              chapters[chapter].pageRanges.indices.contains(page) else { return nil }
        return chapters[chapter].pageRanges[page]
    }

    /// Zero-based page index across the entire book.
    func globalPage(chapter: Int, page: Int) -> Int {
        guard chapters.indices.contains(chapter) else { return 0 }
        let preceding = chapters[..<chapter].reduce(0) { $0 + $1.pageCount }
        return preceding + page
    }

    func position(forGlobalPage target: Int) -> (chapter: Int, page: Int) {
        var remaining = max(0, target)
        for chapter in chapters {
            if remaining < chapter.pageCount {
                return (chapter.chapterIndex, remaining)
            }
            remaining -= chapter.pageCount
        }
        guard let last = chapters.last else { return (0, 0) }
        return (last.chapterIndex, max(0, last.pageCount - 1))
    }

    func progress(chapter: Int, page: Int) -> Double {
        guard totalPages > 1 else { return 0 }
        return Double(globalPage(chapter: chapter, page: page)) / Double(totalPages - 1)
    }

    func pagesLeftInChapter(chapter: Int, page: Int) -> Int {
        max(0, pageCount(chapter: chapter) - page - 1)
    }

    var isEmpty: Bool { chapters.isEmpty || totalPages == 0 }
}
