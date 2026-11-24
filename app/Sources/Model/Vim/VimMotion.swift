import Foundation

/// The cursor motions, with how operators treat them.
nonisolated enum Motion {
    case left(Int)
    case right(Int)
    case down(Int)
    case up(Int)
    case wordStart(Bool, Int)
    case wordEnd(Bool, Int)
    case wordBack(Bool, Int)
    case lineStart
    case firstNonBlank
    case lineEnd(Int)
    /// 0-based; G without a count goes to the last line.
    case lineNumber(Int)
    case lastLine
    /// f, t, F, T: a character on the current line.
    case findCharacter(CharacterSearch, Int)
    /// %: the matching bracket.
    case matchingBracket
    /// } and {.
    case paragraph(forward: Bool, Int)

    init?(key: String, count: Int?) {
        let n = count ?? 1
        switch key {
        case "h": self = .left(n)
        case "l": self = .right(n)
        case "j": self = .down(n)
        case "k": self = .up(n)
        case "w", "W": self = .wordStart(key == "W", n)
        case "e", "E": self = .wordEnd(key == "E", n)
        case "b", "B": self = .wordBack(key == "B", n)
        case "0": self = .lineStart
        case "^": self = .firstNonBlank
        case "$": self = .lineEnd(n)
        case "G": self = count.map { .lineNumber($0 - 1) } ?? .lastLine
        case "%": self = .matchingBracket
        case "}", "{": self = .paragraph(forward: key == "}", n)
        default: return nil
        }
    }

    var isLinewise: Bool {
        switch self {
        case .down, .up, .lineNumber, .lastLine: true
        default: false
        }
    }

    var keepsColumn: Bool {
        switch self {
        case .down, .up: true
        default: false
        }
    }

    /// Whether an operator includes the character the motion lands on (e, $, f, t, %).
    var isInclusive: Bool {
        switch self {
        case .wordEnd, .lineEnd, .matchingBracket: true
        case .findCharacter(let search, _): search.forward
        default: false
        }
    }

    /// Motions that may find nothing (f, t, %). Then they don't move, and an operator does nothing.
    var canFail: Bool {
        switch self {
        case .findCharacter, .matchingBracket: true
        default: false
        }
    }

    func target(from cursor: Int, in text: VimText, desiredColumn: Int?) -> Int {
        switch self {
        case .left(let n):
            let start = text.lineContent(at: cursor).location
            return repeated(n, from: cursor) { $0 > start ? text.previous($0) : $0 }
        case .right(let n):
            let last = text.lastCursorPosition(onLineAt: cursor)
            return repeated(n, from: cursor) { $0 < last ? text.next($0) : $0 }
        case .down(let n), .up(let n):
            let line = text.lineNumber(at: cursor)
            let isDown = if case .down = self { true } else { false }
            let targetLine = isDown ? min(line + n, text.lineNumber(at: text.lastLineStart)) : max(line - n, 0)
            return text.position(column: desiredColumn ?? text.column(of: cursor), onLineAt: text.lineStart(number: targetLine))
        case .wordStart(let big, let n):
            return repeated(n, from: cursor) { text.nextWordStart(from: $0, bigWord: big) }
        case .wordEnd(let big, let n):
            return repeated(n, from: cursor) { text.wordEnd(from: $0, bigWord: big) }
        case .wordBack(let big, let n):
            return repeated(n, from: cursor) { text.previousWordStart(from: $0, bigWord: big) }
        case .lineStart:
            return text.lineContent(at: cursor).location
        case .firstNonBlank:
            return text.firstNonBlank(onLineAt: cursor)
        case .lineEnd(let n):
            return text.lastCursorPosition(onLineAt: text.lineStart(number: text.lineNumber(at: cursor) + n - 1))
        case .lineNumber(let number):
            return text.lineStart(number: max(number, 0))
        case .lastLine:
            return text.lastLineStart
        case .findCharacter(let search, let n):
            return text.findCharacter(search.character, from: cursor, forward: search.forward, till: search.till, count: n) ?? cursor
        case .matchingBracket:
            return text.matchingBracket(from: cursor) ?? cursor
        case .paragraph(let forward, let n):
            return repeated(n, from: cursor) { text.paragraphBoundary(from: $0, forward: forward) }
        }
    }

    private func repeated(_ times: Int, from start: Int, step: (Int) -> Int) -> Int {
        var position = start
        for _ in 0..<times { position = step(position) }
        return position
    }
}

/// The character search of f / t / F / T, kept so ; and , can repeat it.
nonisolated struct CharacterSearch: Equatable {
    var character: String
    var forward: Bool
    var till: Bool

    /// , searches the other way.
    var reversed: CharacterSearch { CharacterSearch(character: character, forward: !forward, till: till) }

    init(character: String, forward: Bool, till: Bool) {
        self.character = character
        self.forward = forward
        self.till = till
    }

    /// The search a prefix key starts: f, t, F or T.
    init?(prefix: String, character: String) {
        guard ["f", "t", "F", "T"].contains(prefix) else { return nil }
        self.init(character: character, forward: prefix == "f" || prefix == "t", till: prefix == "t" || prefix == "T")
    }
}
