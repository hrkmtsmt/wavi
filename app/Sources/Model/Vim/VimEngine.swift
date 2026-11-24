import Foundation

/// Vim's modes, as far as Wavi has them.
nonisolated enum VimMode: Equatable {
    case normal
    case insert
    case visual
    case visualLine

    /// What the status bar shows. These are Vim's own names, so they stay in English in both languages.
    var label: String {
        switch self {
        case .normal: "NORMAL"
        case .insert: "INSERT"
        case .visual: "VISUAL"
        case .visualLine: "V-LINE"
        }
    }

    var isVisual: Bool { self == .visual || self == .visualLine }
}

/// One key press, reduced to what the engine reads.
nonisolated struct VimKey: Equatable {
    var text: String
    var control = false

    static let escape = VimKey("\u{1b}")

    init(_ text: String, control: Bool = false) {
        self.text = text
        self.control = control
    }
}

/// A change to the text: replace `range` (in the text as it is before this edit) with `replacement`.
nonisolated struct VimEdit: Equatable {
    var range: NSRange
    var replacement: String
}

/// What the text view should do after a key: apply the edits in order, then select `selection`.
nonisolated struct VimOutcome: Equatable {
    enum History: Equatable {
        case undo
        case redo
    }

    var edits: [VimEdit] = []
    var selection: NSRange?
    /// Text to put on the clipboard (y, d, c, x).
    var yanked: String?
    var history: History?
    /// The key isn't a Vim command here (insert mode); let the text view handle it as typing.
    var passThrough = false

    static let passThrough = VimOutcome(passThrough: true)

    static func cursor(_ location: Int) -> VimOutcome {
        VimOutcome(selection: NSRange(location: location, length: 0))
    }
}

/// Turns key presses into edits and cursor moves. Holds only Vim's own state (mode, count, half-typed commands); the text and the clipboard are passed in, so it can be tested without a text view.
/// The state is only changed by the engine itself; its extensions live in VimEngine+Operators.swift and VimEngine+Visual.swift.
nonisolated struct VimEngine {
    var mode: VimMode = .normal
    var count: Int?
    var pendingOperator: String?
    var operatorCount: Int?
    var pendingPrefix: String?
    /// The column j and k try to keep, so moving through a short line doesn't lose it.
    var desiredColumn: Int?
    var visualAnchor = 0
    var visualCursor = 0

    /// Indentation added by >> and >.
    static let indent = "    "

    mutating func reset() {
        mode = .normal
        clearPending()
    }

    mutating func handle(_ key: VimKey, text: String, selection: NSRange, clipboard: String?) -> VimOutcome {
        let text = VimText(text)
        switch mode {
        case .insert:
            guard key == .escape else { return .passThrough }
            mode = .normal
            let cursor = selection.location
            let lineStart = text.lineContent(at: cursor).location
            return .cursor(cursor > lineStart ? text.previous(cursor) : cursor)
        case .normal:
            return normal(key, text: text, cursor: text.normalCursor(selection.location), clipboard: clipboard)
        case .visual, .visualLine:
            return visual(key, text: text)
        }
    }

    mutating func clearPending() {
        count = nil
        pendingOperator = nil
        operatorCount = nil
        pendingPrefix = nil
    }

    /// Reads a digit into the count. 0 only counts after another digit; on its own it is the motion "line start".
    mutating func takeDigit(_ key: VimKey) -> Bool {
        guard !key.control, key.text.count == 1, let digit = Int(key.text), digit > 0 || count != nil else { return false }
        count = (count ?? 0) * 10 + digit
        return true
    }

    // MARK: - Normal mode

    private mutating func normal(_ key: VimKey, text: VimText, cursor: Int, clipboard: String?) -> VimOutcome {
        if key == .escape {
            clearPending()
            return .cursor(cursor)
        }
        if pendingPrefix == nil, takeDigit(key) { return VimOutcome() }
        if let prefix = pendingPrefix {
            return finishPrefix(prefix, key: key, text: text, cursor: cursor, clipboard: clipboard)
        }
        if key.control {
            defer { clearPending() }
            return key.text == "r" ? VimOutcome(history: .redo) : VimOutcome()
        }
        if let motion = Motion(key: key.text, count: count) {
            return motionOrOperator(motion, text: text, cursor: cursor)
        }
        if let pending = pendingOperator {
            // The operator typed twice (dd, cc, yy, >>, <<) works on whole lines.
            defer { clearPending() }
            guard key.text == pending else { return VimOutcome() }
            let range = wholeLines(from: cursor, count: (operatorCount ?? 1) * (count ?? 1), in: text)
            return apply(pending, to: range, linewise: true, text: text, cursor: cursor)
        }
        if ["d", "c", "y", ">", "<"].contains(key.text) {
            pendingOperator = key.text
            operatorCount = count
            count = nil
            return VimOutcome()
        }
        if ["g", "r"].contains(key.text) {
            pendingPrefix = key.text
            return VimOutcome()
        }
        defer { count = nil }
        return command(key.text, times: count ?? 1, text: text, cursor: cursor, clipboard: clipboard)
    }

    private mutating func finishPrefix(_ prefix: String, key: VimKey, text: VimText, cursor: Int, clipboard: String?) -> VimOutcome {
        pendingPrefix = nil
        switch prefix {
        case "r":
            defer { clearPending() }
            return replaceCharacters(with: key.text, times: count ?? 1, text: text, cursor: cursor)
        case "g" where key.text == "g":
            return motionOrOperator(.lineNumber(count.map { $0 - 1 } ?? 0), text: text, cursor: cursor)
        default:
            clearPending()
            return VimOutcome()
        }
    }

    /// The commands that act at once, without a motion.
    private mutating func command(_ key: String, times: Int, text: VimText, cursor: Int, clipboard: String?) -> VimOutcome {
        switch key {
        case "i", "a", "I", "A", "o", "O":
            return insert(key, text: text, cursor: cursor)
        case "x", "X", "~":
            return characters(key, times: times, text: text, cursor: cursor)
        case "D", "C":
            let end = NSMaxRange(text.lineContent(at: cursor))
            return apply(
                key == "D" ? "d" : "c", to: NSRange(location: cursor, length: end - cursor), linewise: false, text: text, cursor: cursor)
        case "Y":
            return apply("y", to: wholeLines(from: cursor, count: times, in: text), linewise: true, text: text, cursor: cursor)
        case "p", "P":
            return paste(clipboard, before: key == "P", times: times, text: text, cursor: cursor)
        case "J":
            return join(lines: max(times, 2) - 1, text: text, cursor: cursor)
        case "u":
            return VimOutcome(history: .undo)
        case "v", "V":
            mode = key == "v" ? .visual : .visualLine
            visualAnchor = cursor
            visualCursor = cursor
            return VimOutcome(selection: visualSelection(text))
        default:
            return VimOutcome()
        }
    }

    private mutating func insert(_ key: String, text: VimText, cursor: Int) -> VimOutcome {
        mode = .insert
        let content = text.lineContent(at: cursor)
        switch key {
        case "a": return .cursor(content.length == 0 ? cursor : text.next(cursor))
        case "I": return .cursor(text.firstNonBlank(onLineAt: cursor))
        case "A": return .cursor(NSMaxRange(content))
        case "o":
            let end = NSMaxRange(content)
            return VimOutcome(
                edits: [VimEdit(range: NSRange(location: end, length: 0), replacement: "\n")],
                selection: NSRange(location: end + 1, length: 0))
        case "O":
            return VimOutcome(
                edits: [VimEdit(range: NSRange(location: content.location, length: 0), replacement: "\n")],
                selection: NSRange(location: content.location, length: 0))
        default: return .cursor(cursor)
        }
    }

    /// x, X and ~ on `times` characters of the current line.
    private mutating func characters(_ key: String, times: Int, text: VimText, cursor: Int) -> VimOutcome {
        let content = text.lineContent(at: cursor)
        if key == "X" {
            var from = cursor
            for _ in 0..<times where from > content.location { from = text.previous(from) }
            guard from < cursor else { return VimOutcome() }
            return apply("d", to: NSRange(location: from, length: cursor - from), linewise: false, text: text, cursor: from)
        }
        guard cursor < NSMaxRange(content) else { return VimOutcome() }
        var end = cursor
        for _ in 0..<times where end < NSMaxRange(content) { end = text.next(end) }
        let range = NSRange(location: cursor, length: end - cursor)
        if key == "x" { return apply("d", to: range, linewise: false, text: text, cursor: cursor) }
        let toggled = Self.toggleCase(text.string.substring(with: range))
        return VimOutcome(
            edits: [VimEdit(range: range, replacement: toggled)], selection: NSRange(location: text.clampedToLine(end), length: 0))
    }

    /// `count` whole lines from the cursor's, line breaks included.
    func wholeLines(from cursor: Int, count: Int, in text: VimText) -> NSRange {
        let start = text.line(at: cursor).location
        let end = NSMaxRange(text.line(at: text.lineStart(number: text.lineNumber(at: cursor) + count - 1)))
        return NSRange(location: start, length: end - start)
    }

    private mutating func motionOrOperator(_ motion: Motion, text: VimText, cursor: Int) -> VimOutcome {
        defer { clearPending() }
        if let pending = pendingOperator {
            var motion = motion
            // cw changes to the end of the word, like ce: the space after it stays.
            if pending == "c", case .wordStart(let big, let n) = motion, cursor < text.length,
                ![.blank, .newline].contains(text.characterClass(at: cursor, bigWord: big))
            {
                motion = .wordEnd(big, n)
            }
            var target = cursor
            for _ in 0..<(operatorCount ?? 1) { target = motion.target(from: target, in: text, desiredColumn: nil) }
            return apply(pending, motion: motion, from: cursor, to: target, text: text)
        }
        let target = motion.target(from: cursor, in: text, desiredColumn: desiredColumn)
        desiredColumn = motion.keepsColumn ? desiredColumn ?? text.column(of: cursor) : nil
        let landing = motion.isLinewise && !motion.keepsColumn ? text.firstNonBlank(onLineAt: target) : text.clampedToLine(target)
        return .cursor(landing)
    }

    static func toggleCase(_ text: String) -> String {
        text.map { character -> String in
            let string = String(character)
            return string == string.uppercased() ? string.lowercased() : string.uppercased()
        }.joined()
    }
}
