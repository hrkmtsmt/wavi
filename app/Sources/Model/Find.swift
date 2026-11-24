import Foundation
import Observation

/// Plain-text search for the find bar: literal and case-insensitive. Stops at `limit` matches so a large file stays responsive.
nonisolated enum TextSearch {
    static let limit = 1000

    /// Non-overlapping matches of `query` in `text`, in order.
    static func ranges(of query: String, in text: String, limit: Int = limit) -> [NSRange] {
        guard !query.isEmpty else { return [] }
        let string = text as NSString
        var result: [NSRange] = []
        var location = 0
        while location < string.length, result.count < limit {
            let rest = NSRange(location: location, length: string.length - location)
            let found = string.range(of: query, options: [.caseInsensitive, .literal], range: rest)
            guard found.location != NSNotFound, found.length > 0 else { break }
            result.append(found)
            location = NSMaxRange(found)
        }
        return result
    }

    /// The first match starting at or after `location`, wrapping round to the first match.
    static func index(from location: Int, in ranges: [NSRange]) -> Int? {
        guard !ranges.isEmpty else { return nil }
        return ranges.firstIndex { $0.location >= location } ?? 0
    }
}

/// The find bar: whether it is open, what is typed, the matches in the selected tab and which one is current.
@Observable
final class FindState {
    var isVisible = false
    var query = ""
    private(set) var matches: [NSRange] = []
    private(set) var current: Int?
    /// Bumped whenever the editor should select and reveal `currentRange`.
    private(set) var revealRequest = 0
    /// Bumped whenever the find field should take the keyboard focus.
    private(set) var focusRequest = 0
    /// Where the cursor was when the bar opened. Typing searches from here, so each keystroke doesn't push the start past the match the previous one found.
    private(set) var anchor = 0

    var currentRange: NSRange? { current.map { matches[$0] } }
    /// True when the search stopped at `TextSearch.limit`, so there may be more.
    var isTruncated: Bool { matches.count >= TextSearch.limit }

    func open(from location: Int) {
        anchor = location
        isVisible = true
        focusRequest += 1
    }

    func close() {
        isVisible = false
    }

    /// Searches again for the typed text and moves to the first match from `location`, and searches from there from now on.
    func search(in text: String, from location: Int) {
        anchor = location
        search(in: text)
    }

    /// Searches again for the typed text and moves to the first match from the anchor.
    func search(in text: String) {
        let location = anchor
        matches = TextSearch.ranges(of: query, in: text)
        current = TextSearch.index(from: location, in: matches)
        if current != nil { revealRequest += 1 }
    }

    /// Searches again after the text changed, keeping the current position without moving the selection.
    func refresh(in text: String) {
        matches = TextSearch.ranges(of: query, in: text)
        if let index = current { current = matches.isEmpty ? nil : min(index, matches.count - 1) }
    }

    /// Vim's n / N and * / #: searches the text again and goes to the first match after (or the last before) `location`, wrapping round.
    func move(in text: String, from location: Int, backward: Bool) {
        matches = TextSearch.ranges(of: query, in: text)
        guard !matches.isEmpty else {
            current = nil
            return
        }
        if backward {
            current = matches.lastIndex { $0.location < location } ?? matches.count - 1
        } else {
            current = matches.firstIndex { $0.location > location } ?? 0
        }
        revealRequest += 1
    }

    func next() {
        guard !matches.isEmpty else { return }
        current = ((current ?? -1) + 1) % matches.count
        revealRequest += 1
    }

    func previous() {
        guard !matches.isEmpty else { return }
        current = ((current ?? 0) - 1 + matches.count) % matches.count
        revealRequest += 1
    }
}
