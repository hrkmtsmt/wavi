import Foundation

/// Text objects (iw, i", i( …), f / t, % and paragraph motions.
nonisolated extension VimText {
    // MARK: f, t, F, T

    /// Where f / t / F / T lands on the current line, or nil when the character isn't there.
    func findCharacter(_ character: String, from cursor: Int, forward: Bool, till: Bool, count: Int) -> Int? {
        let content = lineContent(at: cursor)
        var position = cursor
        var found = 0
        while found < count {
            position = forward ? next(position) : (position > content.location ? previous(position) : -1)
            guard position >= content.location, position < NSMaxRange(content) else { return nil }
            if self.character(at: position) == character { found += 1 }
        }
        guard till else { return position }
        let stop = forward ? previous(position) : next(position)
        return stop == cursor && count == 1 ? nil : stop
    }

    // MARK: %

    private static let pairs: [(open: unichar, close: unichar)] = [(0x28, 0x29), (0x5B, 0x5D), (0x7B, 0x7D)]

    /// %: the bracket matching the first bracket at or after the cursor on its line.
    func matchingBracket(from cursor: Int) -> Int? {
        let content = lineContent(at: cursor)
        var position = cursor
        while position < NSMaxRange(content) {
            let unit = string.character(at: position)
            if let pair = Self.pairs.first(where: { $0.open == unit }) {
                return scan(from: position, forward: true, open: pair.open, close: pair.close)
            }
            if let pair = Self.pairs.first(where: { $0.close == unit }) {
                return scan(from: position, forward: false, open: pair.open, close: pair.close)
            }
            position += 1
        }
        return nil
    }

    /// From a bracket, walks to the one that balances it, counting nested pairs on the way.
    private func scan(from start: Int, forward: Bool, open: unichar, close: unichar) -> Int? {
        var depth = 0
        var position = start
        while position >= 0, position < length {
            let unit = string.character(at: position)
            if unit == (forward ? open : close) { depth += 1 }
            if unit == (forward ? close : open) {
                depth -= 1
                if depth == 0 { return position }
            }
            position += forward ? 1 : -1
        }
        return nil
    }

    // MARK: { }

    func isEmptyLine(at index: Int) -> Bool { lineContent(at: index).length == 0 }

    /// } and {: the next or previous empty line, or the end or start of the text.
    func paragraphBoundary(from cursor: Int, forward: Bool) -> Int {
        var position = line(at: cursor).location
        // Leave the empty lines the cursor is on first.
        while isEmptyLine(at: position), let step = lineStep(from: position, forward: forward) { position = step }
        while let step = lineStep(from: position, forward: forward) {
            position = step
            if isEmptyLine(at: position) { return position }
        }
        return forward ? lastCursorPosition(onLineAt: lastLineStart) : 0
    }

    private func lineStep(from position: Int, forward: Bool) -> Int? {
        if forward {
            let next = NSMaxRange(line(at: position))
            return next < length && line(at: position).location < lastLineStart ? next : nil
        }
        let start = line(at: position).location
        return start > 0 ? line(at: start - 1).location : nil
    }

    // MARK: Text objects

    /// The range of a text object at the cursor: `kind` is the key after i / a (w, W, ", ', `, (, ), b, [, ], {, }, B).
    func textObject(_ kind: String, inner: Bool, at cursor: Int) -> NSRange? {
        switch kind {
        case "w", "W": return wordObject(at: cursor, inner: inner, bigWord: kind == "W")
        case "\"", "'", "`": return quoteObject(kind, at: cursor, inner: inner)
        case "(", ")", "b": return bracketObject(open: 0x28, close: 0x29, at: cursor, inner: inner)
        case "[", "]": return bracketObject(open: 0x5B, close: 0x5D, at: cursor, inner: inner)
        case "{", "}", "B": return bracketObject(open: 0x7B, close: 0x7D, at: cursor, inner: inner)
        default: return nil
        }
    }

    /// iw / aw: the run of word, punctuation or blank characters under the cursor; aw adds the blanks after it (or before, at the end of a line).
    private func wordObject(at cursor: Int, inner: Bool, bigWord: Bool) -> NSRange? {
        let content = lineContent(at: cursor)
        guard cursor < NSMaxRange(content) else { return nil }
        let kind = characterClass(at: cursor, bigWord: bigWord)
        var start = cursor
        while start > content.location, characterClass(at: previous(start), bigWord: bigWord) == kind { start = previous(start) }
        var end = next(cursor)
        while end < NSMaxRange(content), characterClass(at: end, bigWord: bigWord) == kind { end = next(end) }
        guard !inner else { return NSRange(location: start, length: end - start) }
        if kind == .blank {
            // a blank run takes the word after it.
            let following = end < NSMaxRange(content) ? characterClass(at: end, bigWord: bigWord) : .blank
            while end < NSMaxRange(content), characterClass(at: end, bigWord: bigWord) == following { end = next(end) }
            return NSRange(location: start, length: end - start)
        }
        let trailing = end
        while end < NSMaxRange(content), isBlank(at: end) { end = next(end) }
        if end == trailing {
            while start > content.location, isBlank(at: previous(start)) { start = previous(start) }
        }
        return NSRange(location: start, length: end - start)
    }

    /// i" / a": the quoted text around the cursor on its line, or the next quoted text after it.
    private func quoteObject(_ quote: String, at cursor: Int, inner: Bool) -> NSRange? {
        let content = lineContent(at: cursor)
        var quotes: [Int] = []
        var position = content.location
        while position < NSMaxRange(content) {
            if character(at: position) == quote { quotes.append(position) }
            position = next(position)
        }
        var pairs: [(Int, Int)] = []
        var index = 0
        while index + 1 < quotes.count {
            pairs.append((quotes[index], quotes[index + 1]))
            index += 2
        }
        guard let (open, close) = pairs.first(where: { $0.0 <= cursor && cursor <= $0.1 }) ?? pairs.first(where: { $0.0 > cursor }) else {
            return nil
        }
        return inner ? NSRange(location: open + 1, length: close - open - 1) : NSRange(location: open, length: close - open + 1)
    }

    /// i( / a(: the brackets around the cursor, across lines, counting nested pairs. A bracket under the cursor counts as part of its pair.
    private func bracketObject(open: unichar, close: unichar, at cursor: Int, inner: Bool) -> NSRange? {
        guard cursor < length else { return nil }
        var start: Int?
        if string.character(at: cursor) == open {
            start = cursor
        } else {
            var depth = 0
            var position = cursor - 1
            while position >= 0 {
                let unit = string.character(at: position)
                if unit == close { depth += 1 }
                if unit == open {
                    if depth == 0 {
                        start = position
                        break
                    }
                    depth -= 1
                }
                position -= 1
            }
        }
        guard let start, let end = scan(from: start, forward: true, open: open, close: close) else { return nil }
        return inner ? NSRange(location: start + 1, length: end - start - 1) : NSRange(location: start, length: end - start + 1)
    }
}
