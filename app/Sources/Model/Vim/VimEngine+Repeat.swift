import Foundation

/// `.`: the keys of the last change are kept, from the first key of the command (count included) to the end of any typing in insert mode, and replayed on demand.
/// Changes made in visual mode aren't kept, and neither is text typed through Japanese input (it never reaches the engine).
nonisolated extension VimEngine {
    mutating func record(_ key: VimKey, outcome: VimOutcome, startsCommand: Bool, wasVisual: Bool) {
        if startsCommand {
            recording = []
            recordingChanged = false
        }
        if wasVisual || mode.isVisual {
            recording = []
            recordingChanged = false
            return
        }
        recording.append(key)
        if !outcome.edits.isEmpty || mode == .insert { recordingChanged = true }
        guard mode == .normal, !isPending else { return }
        if recordingChanged { lastChange = recording }
        recording = []
        recordingChanged = false
    }

    /// Replays the last change `times` times on a copy of the text and returns the result as one edit, so it undoes in one step.
    mutating func repeatLastChange(times: Int, text: String, selection: NSRange, clipboard: String?) -> VimOutcome {
        guard let keys = lastChange else { return VimOutcome() }
        var replay = self
        replay.replaying = true
        replay.clearPending()
        var result = text
        var cursor = selection
        var yanked: String?
        for _ in 0..<times {
            for key in keys {
                let outcome = replay.dispatch(key, text: result, selection: cursor, clipboard: clipboard)
                for edit in outcome.edits {
                    result = (result as NSString).replacingCharacters(in: edit.range, with: edit.replacement)
                }
                if let selection = outcome.selection { cursor = selection }
                if let text = outcome.yanked { yanked = text }
            }
        }
        // Keep what the replay learned (f / t) but stay out of insert mode, as Vim does.
        lastCharacterSearch = replay.lastCharacterSearch
        mode = .normal
        clearPending()
        desiredColumn = nil
        let edits = Self.difference(from: text, to: result).map { [$0] } ?? []
        return VimOutcome(edits: edits, selection: NSRange(location: cursor.location, length: 0), yanked: yanked)
    }

    /// While replaying, insert mode types the recorded keys itself: Return is a line break and Delete removes the character before the cursor.
    func typed(_ key: VimKey, text: VimText, selection: NSRange) -> VimOutcome {
        let location = selection.location
        switch key.text {
        case "\r", "\n":
            return VimOutcome(edits: [VimEdit(range: selection, replacement: "\n")], selection: NSRange(location: location + 1, length: 0))
        case "\u{7f}":
            guard location > 0 else { return VimOutcome() }
            let from = text.previous(location)
            return VimOutcome(
                edits: [VimEdit(range: NSRange(location: from, length: location - from), replacement: "")],
                selection: NSRange(location: from, length: 0))
        default:
            guard !key.control else { return VimOutcome() }
            return VimOutcome(
                edits: [VimEdit(range: selection, replacement: key.text)],
                selection: NSRange(location: location + (key.text as NSString).length, length: 0))
        }
    }

    /// The single edit that turns `old` into `new`: what lies between their common start and common end, kept on whole characters.
    static func difference(from old: String, to new: String) -> VimEdit? {
        let before = old as NSString
        let after = new as NSString
        guard before != after else { return nil }
        var prefix = 0
        while prefix < before.length, prefix < after.length, before.character(at: prefix) == after.character(at: prefix) { prefix += 1 }
        if prefix < before.length { prefix = min(prefix, before.rangeOfComposedCharacterSequence(at: prefix).location) }
        if prefix < after.length { prefix = min(prefix, after.rangeOfComposedCharacterSequence(at: prefix).location) }
        var suffix = 0
        while suffix < before.length - prefix, suffix < after.length - prefix,
            before.character(at: before.length - 1 - suffix) == after.character(at: after.length - 1 - suffix)
        {
            suffix += 1
        }
        // Don't let the common end start in the middle of a character.
        while suffix > 0 {
            let end = before.length - suffix
            let newEnd = after.length - suffix
            let splitsBefore = end > 0 && end < before.length && before.rangeOfComposedCharacterSequence(at: end).location != end
            let splitsAfter = newEnd > 0 && newEnd < after.length && after.rangeOfComposedCharacterSequence(at: newEnd).location != newEnd
            if !splitsBefore && !splitsAfter { break }
            suffix -= 1
        }
        let range = NSRange(location: prefix, length: before.length - suffix - prefix)
        return VimEdit(range: range, replacement: after.substring(with: NSRange(location: prefix, length: after.length - suffix - prefix)))
    }
}
