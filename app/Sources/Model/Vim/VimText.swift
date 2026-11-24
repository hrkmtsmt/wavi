import Foundation

/// Read-only helpers over the text in UTF-16 offsets, the same units NSTextView uses for ranges.
nonisolated struct VimText {
    let string: NSString

    init(_ text: String) { string = text as NSString }

    var length: Int { string.length }

    // MARK: Characters

    /// The offset of the character after the one at `index` (emoji and other multi-unit characters are one step).
    func next(_ index: Int) -> Int {
        guard index < length else { return length }
        return NSMaxRange(string.rangeOfComposedCharacterSequence(at: index))
    }

    /// The offset of the character before `index`.
    func previous(_ index: Int) -> Int {
        guard index > 0 else { return 0 }
        return string.rangeOfComposedCharacterSequence(at: index - 1).location
    }

    func character(at index: Int) -> String {
        guard index < length else { return "" }
        return string.substring(with: string.rangeOfComposedCharacterSequence(at: index))
    }

    func isNewline(at index: Int) -> Bool {
        guard index < length else { return false }
        let unit = string.character(at: index)
        return unit == 0x0A || unit == 0x0D
    }

    // MARK: Lines

    /// The whole line around `index`, its line break included.
    func line(at index: Int) -> NSRange {
        string.lineRange(for: NSRange(location: min(index, length), length: 0))
    }

    /// The line around `index` without its line break.
    func lineContent(at index: Int) -> NSRange {
        var start = 0
        var contentsEnd = 0
        string.getLineStart(&start, end: nil, contentsEnd: &contentsEnd, for: NSRange(location: min(index, length), length: 0))
        return NSRange(location: start, length: contentsEnd - start)
    }

    /// Where the cursor may sit on the line in normal mode: on its last character, or at its start if it is empty.
    func lastCursorPosition(onLineAt index: Int) -> Int {
        let content = lineContent(at: index)
        return content.length == 0 ? content.location : previous(NSMaxRange(content))
    }

    func clampedToLine(_ index: Int) -> Int {
        let content = lineContent(at: index)
        return min(max(index, content.location), lastCursorPosition(onLineAt: index))
    }

    func firstNonBlank(onLineAt index: Int) -> Int {
        let content = lineContent(at: index)
        var position = content.location
        while position < NSMaxRange(content), isBlank(at: position) { position = next(position) }
        return position < NSMaxRange(content) ? position : lastCursorPosition(onLineAt: index)
    }

    func lineNumber(at index: Int) -> Int {
        var number = 0
        var position = 0
        let target = line(at: index).location
        while position < target {
            position = NSMaxRange(line(at: position))
            number += 1
        }
        return number
    }

    /// The start of line `number` (0-based), or of the last line when the text has fewer.
    func lineStart(number: Int) -> Int {
        var position = 0
        var current = 0
        while current < number {
            let end = NSMaxRange(line(at: position))
            if end >= length { break }
            position = end
            current += 1
        }
        return position
    }

    /// The start of the last line. A final line break ends the last line; it doesn't start an empty one, as in Vim.
    var lastLineStart: Int {
        guard length > 0, isNewline(at: length - 1) else { return line(at: length).location }
        return line(at: length - 1).location
    }

    /// Moves a cursor that sits after the final line break back onto the last line, where Vim keeps it.
    func normalCursor(_ index: Int) -> Int {
        let index = min(index, length)
        guard index == length, length > 0, isNewline(at: length - 1) else { return index }
        return lastLineStart
    }

    /// The column of `index` in characters from the start of its line.
    func column(of index: Int) -> Int {
        var position = lineContent(at: index).location
        var column = 0
        while position < index {
            position = next(position)
            column += 1
        }
        return column
    }

    /// The offset of `column` on the line starting at `lineStart`, or the last cursor position if the line is shorter.
    func position(column: Int, onLineAt lineStart: Int) -> Int {
        let content = lineContent(at: lineStart)
        var position = content.location
        var remaining = column
        while remaining > 0, position < lastCursorPosition(onLineAt: lineStart) {
            position = next(position)
            remaining -= 1
        }
        return min(position, max(content.location, lastCursorPosition(onLineAt: lineStart)))
    }

    // MARK: Words

    enum CharacterClass { case blank, newline, word, punctuation }

    func isBlank(at index: Int) -> Bool {
        let unit = string.character(at: index)
        return unit == 0x20 || unit == 0x09 || unit == 0x3000
    }

    /// `bigWord` treats every non-blank run as one word, like W, B and E.
    func characterClass(at index: Int, bigWord: Bool) -> CharacterClass {
        if isNewline(at: index) { return .newline }
        if isBlank(at: index) { return .blank }
        if bigWord { return .word }
        let scalar = character(at: index).unicodeScalars.first
        guard let scalar else { return .blank }
        if CharacterSet.alphanumerics.contains(scalar) || scalar == "_" { return .word }
        return CharacterSet.punctuationCharacters.union(.symbols).contains(scalar) ? .punctuation : .word
    }

    /// w / W: the start of the next word. An empty line counts as a word.
    func nextWordStart(from index: Int, bigWord: Bool) -> Int {
        guard index < length else { return length }
        let start = characterClass(at: index, bigWord: bigWord)
        var position = index
        if start == .word || start == .punctuation {
            while position < length, characterClass(at: position, bigWord: bigWord) == start { position = next(position) }
        }
        while position < length {
            let kind = characterClass(at: position, bigWord: bigWord)
            if kind == .newline {
                let following = next(position)
                if following < length, isNewline(at: following) { return following }
                position = following
                continue
            }
            if kind != .blank { return position }
            position = next(position)
        }
        return length
    }

    /// e / E: the end of the current or next word.
    func wordEnd(from index: Int, bigWord: Bool) -> Int {
        var position = next(index)
        while position < length, [.blank, .newline].contains(characterClass(at: position, bigWord: bigWord)) {
            position = next(position)
        }
        guard position < length else { return max(previous(length), 0) }
        let kind = characterClass(at: position, bigWord: bigWord)
        while next(position) < length, characterClass(at: next(position), bigWord: bigWord) == kind {
            position = next(position)
        }
        return position
    }

    /// b / B: the start of the current or previous word.
    func previousWordStart(from index: Int, bigWord: Bool) -> Int {
        var position = previous(index)
        while position > 0, [.blank, .newline].contains(characterClass(at: position, bigWord: bigWord)) {
            if isNewline(at: position), position > 0, isNewline(at: previous(position)) { return position }
            position = previous(position)
        }
        guard position > 0 || index > 0 else { return 0 }
        let kind = characterClass(at: position, bigWord: bigWord)
        while position > 0, characterClass(at: previous(position), bigWord: bigWord) == kind {
            position = previous(position)
        }
        return position
    }
}
