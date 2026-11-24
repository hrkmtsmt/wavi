import Foundation

/// The operators (d, c, y, >, <) and the edits behind r, p, P and J.
nonisolated extension VimEngine {
    /// Turns an operator and a motion into the range it covers.
    mutating func apply(_ op: String, motion: Motion, from cursor: Int, to target: Int, text: VimText) -> VimOutcome {
        if motion.isLinewise {
            let start = text.line(at: min(cursor, target)).location
            let end = NSMaxRange(text.line(at: max(cursor, target)))
            return apply(op, to: NSRange(location: start, length: end - start), linewise: true, text: text, cursor: cursor)
        }
        let start = min(cursor, target, text.length)
        var end = max(cursor, target)
        if motion.isInclusive { end = text.next(end) }
        // dw at the end of a line stops at the line break instead of joining the next line.
        if case .wordStart = motion { end = min(end, max(NSMaxRange(text.lineContent(at: start)), start)) }
        end = min(end, text.length)
        guard end > start else { return VimOutcome() }
        return apply(op, to: NSRange(location: start, length: end - start), linewise: false, text: text, cursor: cursor)
    }

    /// Applies d, c, y, > or < to `range`. Linewise ranges cover whole lines including their line breaks.
    mutating func apply(_ op: String, to range: NSRange, linewise: Bool, text: VimText, cursor: Int) -> VimOutcome {
        var yanked = text.string.substring(with: range)
        if linewise, !yanked.hasSuffix("\n") { yanked += "\n" }
        switch op {
        case "y":
            let landing =
                linewise ? min(cursor, range.location == text.line(at: cursor).location ? cursor : range.location) : range.location
            return VimOutcome(selection: NSRange(location: text.clampedToLine(landing), length: 0), yanked: yanked)
        case "d":
            return delete(range, linewise: linewise, text: text, yanked: yanked)
        case "c":
            mode = .insert
            // cc keeps an empty line to type on.
            let keep = linewise && text.string.substring(with: range).hasSuffix("\n") ? "\n" : ""
            return VimOutcome(
                edits: [VimEdit(range: range, replacement: keep)], selection: NSRange(location: range.location, length: 0), yanked: yanked)
        case ">", "<":
            return shift(lines: range, right: op == ">", text: text)
        default:
            return VimOutcome()
        }
    }

    private func delete(_ range: NSRange, linewise: Bool, text: VimText, yanked: String) -> VimOutcome {
        var deleted = range
        // Deleting the last lines also takes the line break before them, so no empty line is left behind.
        let takesBreakBefore =
            linewise && NSMaxRange(range) == text.length && range.location > 0 && !text.string.substring(with: range).hasSuffix("\n")
        if takesBreakBefore { deleted = NSRange(location: range.location - 1, length: range.length + 1) }
        let after = VimText(text.string.replacingCharacters(in: deleted, with: ""))
        let landing: Int
        if linewise {
            landing = after.firstNonBlank(onLineAt: min(takesBreakBefore ? deleted.location : range.location, after.length))
        } else {
            landing = after.clampedToLine(min(range.location, after.length))
        }
        return VimOutcome(
            edits: [VimEdit(range: deleted, replacement: "")], selection: NSRange(location: landing, length: 0), yanked: yanked)
    }

    /// >> and <<: adds or removes one indent on every non-empty line in `range`.
    private func shift(lines range: NSRange, right: Bool, text: VimText) -> VimOutcome {
        var edits: [VimEdit] = []
        var shiftSoFar = 0
        var position = range.location
        repeat {
            let content = text.lineContent(at: position)
            if right {
                if content.length > 0 {
                    edits.append(VimEdit(range: NSRange(location: content.location + shiftSoFar, length: 0), replacement: Self.indent))
                    shiftSoFar += (Self.indent as NSString).length
                }
            } else {
                let width = leadingIndentWidth(of: content, in: text)
                if width > 0 {
                    edits.append(VimEdit(range: NSRange(location: content.location + shiftSoFar, length: width), replacement: ""))
                    shiftSoFar -= width
                }
            }
            let next = NSMaxRange(text.line(at: position))
            if next <= position { break }
            position = next
        } while position < NSMaxRange(range)
        var after = text.string as String
        for edit in edits { after = (after as NSString).replacingCharacters(in: edit.range, with: edit.replacement) }
        return VimOutcome(edits: edits, selection: NSRange(location: VimText(after).firstNonBlank(onLineAt: range.location), length: 0))
    }

    /// How much << removes: up to one indent of spaces, or one tab.
    private func leadingIndentWidth(of content: NSRange, in text: VimText) -> Int {
        guard content.length > 0 else { return 0 }
        if text.string.character(at: content.location) == 0x09 { return 1 }
        var width = 0
        while width < (Self.indent as NSString).length, content.location + width < NSMaxRange(content),
            text.string.character(at: content.location + width) == 0x20
        {
            width += 1
        }
        return width
    }

    /// r: replaces `times` characters with `replacement`, staying on the line.
    func replaceCharacters(with replacement: String, times: Int, text: VimText, cursor: Int) -> VimOutcome {
        let content = text.lineContent(at: cursor)
        guard replacement.count == 1, replacement != VimKey.escape.text, cursor < NSMaxRange(content) else { return VimOutcome() }
        var end = cursor
        for _ in 0..<times {
            guard end < NSMaxRange(content) else { return VimOutcome() }
            end = text.next(end)
        }
        let range = NSRange(location: cursor, length: end - cursor)
        let landing = cursor + (replacement as NSString).length * (times - 1)
        return VimOutcome(
            edits: [VimEdit(range: range, replacement: String(repeating: replacement, count: times))],
            selection: NSRange(location: landing, length: 0))
    }

    /// p and P. Clipboard text ending in a line break is pasted as whole lines, anything else inside the line.
    func paste(_ clipboard: String?, before: Bool, times: Int, text: VimText, cursor: Int) -> VimOutcome {
        guard let clipboard, !clipboard.isEmpty else { return VimOutcome() }
        let block = String(repeating: clipboard, count: times)
        if clipboard.hasSuffix("\n") {
            let line = text.line(at: cursor)
            if before {
                return VimOutcome(
                    edits: [VimEdit(range: NSRange(location: line.location, length: 0), replacement: block)],
                    selection: NSRange(location: line.location, length: 0))
            }
            if NSMaxRange(line) > NSMaxRange(text.lineContent(at: cursor)) {
                return VimOutcome(
                    edits: [VimEdit(range: NSRange(location: NSMaxRange(line), length: 0), replacement: block)],
                    selection: NSRange(location: NSMaxRange(line), length: 0))
            }
            // The last line has no line break, so the pasted lines go after a new one.
            let inserted = "\n" + String(block.dropLast())
            return VimOutcome(
                edits: [VimEdit(range: NSRange(location: text.length, length: 0), replacement: inserted)],
                selection: NSRange(location: text.length + 1, length: 0))
        }
        let at = before || text.lineContent(at: cursor).length == 0 ? cursor : text.next(cursor)
        let landing = at + (block as NSString).length - 1
        return VimOutcome(
            edits: [VimEdit(range: NSRange(location: at, length: 0), replacement: block)],
            selection: NSRange(location: max(at, landing), length: 0))
    }

    /// J: joins `lines` following lines onto this one with a single space, dropping their leading blanks.
    func join(lines: Int, text: VimText, cursor: Int) -> VimOutcome {
        var edits: [VimEdit] = []
        var string = text.string as String
        var landing = cursor
        for _ in 0..<lines {
            let current = VimText(string)
            let content = current.lineContent(at: landing)
            let breakStart = NSMaxRange(content)
            guard breakStart < current.length else { break }
            let nextLine = current.lineContent(at: NSMaxRange(current.line(at: landing)))
            var nextStart = nextLine.location
            while nextStart < NSMaxRange(nextLine), current.isBlank(at: nextStart) { nextStart = current.next(nextStart) }
            let endsWithBlank = content.length > 0 && current.isBlank(at: current.previous(breakStart))
            let separator = nextStart == NSMaxRange(nextLine) || endsWithBlank || content.length == 0 ? "" : " "
            let edit = VimEdit(range: NSRange(location: breakStart, length: nextStart - breakStart), replacement: separator)
            edits.append(edit)
            string = (string as NSString).replacingCharacters(in: edit.range, with: separator)
            landing = breakStart
        }
        guard !edits.isEmpty else { return VimOutcome() }
        return VimOutcome(edits: edits, selection: NSRange(location: landing, length: 0))
    }
}
