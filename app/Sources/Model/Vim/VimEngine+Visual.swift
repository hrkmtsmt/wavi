import Foundation

/// v and V: a selection from where visual mode started (the anchor) to the cursor, which the motions move.
nonisolated extension VimEngine {
    func visualSelection(_ text: VimText) -> NSRange {
        let start = min(visualAnchor, visualCursor)
        let end = max(visualAnchor, visualCursor)
        if mode == .visualLine {
            let from = text.line(at: start).location
            return NSRange(location: from, length: NSMaxRange(text.line(at: end)) - from)
        }
        return NSRange(location: start, length: max(min(text.next(end), text.length) - start, 0))
    }

    mutating func visual(_ key: VimKey, text: VimText) -> VimOutcome {
        if key == .escape || (key.text == "v" && mode == .visual) || (key.text == "V" && mode == .visualLine) {
            mode = .normal
            clearPending()
            return .cursor(text.clampedToLine(visualCursor))
        }
        if key.text == "v" || key.text == "V" {
            mode = key.text == "v" ? .visual : .visualLine
            return VimOutcome(selection: visualSelection(text))
        }
        if pendingPrefix == nil, takeDigit(key) { return VimOutcome() }
        if pendingPrefix == "g" || key.text == "g" {
            return visualG(key, text: text)
        }
        if let motion = Motion(key: key.text, count: count) {
            count = nil
            visualCursor = text.clampedToLine(motion.target(from: visualCursor, in: text, desiredColumn: nil))
            return VimOutcome(selection: visualSelection(text))
        }
        count = nil
        return visualOperator(key.text, text: text)
    }

    private mutating func visualG(_ key: VimKey, text: VimText) -> VimOutcome {
        guard pendingPrefix == "g" else {
            pendingPrefix = "g"
            return VimOutcome()
        }
        pendingPrefix = nil
        if key.text == "g" {
            visualCursor = Motion.lineNumber(count.map { $0 - 1 } ?? 0).target(from: visualCursor, in: text, desiredColumn: nil)
        }
        count = nil
        return VimOutcome(selection: visualSelection(text))
    }

    private mutating func visualOperator(_ key: String, text: VimText) -> VimOutcome {
        let selection = visualSelection(text)
        switch key {
        case "d", "x", "c", "y", ">", "<":
            let linewise = mode == .visualLine
            mode = .normal
            guard selection.length > 0 else { return VimOutcome() }
            return apply(key == "x" ? "d" : key, to: selection, linewise: linewise, text: text, cursor: selection.location)
        case "~":
            mode = .normal
            let toggled = Self.toggleCase(text.string.substring(with: selection))
            return VimOutcome(
                edits: [VimEdit(range: selection, replacement: toggled)], selection: NSRange(location: selection.location, length: 0))
        default:
            return VimOutcome(selection: selection)
        }
    }
}
