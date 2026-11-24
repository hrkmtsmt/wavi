import AppKit

/// The text view behind the Editor (TextKit 2).
/// - Leaves file drops to the window, so dropping a file opens it instead of
///   inserting its path.
/// - Optionally marks full-width spaces (U+3000) with a faint "□".
/// - Optionally takes Vim keys (VimEngine), with a block cursor outside insert mode.
final class WaviTextView: NSTextView {
    var showsFullWidthSpace = false {
        didSet { if oldValue != showsFullWidthSpace { needsDisplay = true } }
    }

    // MARK: - Vim keys

    var vimEnabled = false {
        didSet {
            guard oldValue != vimEnabled else { return }
            vim.reset()
            vimStateChanged()
        }
    }
    /// Called with the mode after every Vim key, and with nil when Vim keys are turned off.
    var onVimModeChange: (VimMode?) -> Void = { _ in }
    /// Called for / ? n N * #, which run through the find bar.
    var onVimSearch: (VimSearch) -> Void = { _ in }
    /// Set while a file is dragged over the window, so no cursor is drawn.
    var hidesCaretForDrag = false {
        didSet { if oldValue != hidesCaretForDrag { vimStateChanged() } }
    }
    private(set) var vim = VimEngine()

    var showsBlockCursor: Bool { vimEnabled && vim.mode != .insert && !hidesCaretForDrag }

    override func keyDown(with event: NSEvent) {
        guard vimEnabled, !hasMarkedText(), let key = Self.vimKey(event) else {
            super.keyDown(with: event)
            return
        }
        let clipboard = NSPasteboard.general.string(forType: .string)
        // Ctrl-d / Ctrl-u move half of the lines the text view shows.
        vim.halfPage = max(1, Int(visibleRect.height / TextStyle.mono16.lineHeight / 2))
        let wasInserting = vim.mode == .insert
        let outcome = vim.handle(key, text: string, selection: selectedRange(), clipboard: clipboard)
        if outcome.passThrough {
            super.keyDown(with: event)
            return
        }
        perform(outcome)
        // Leaving insert mode ends the change, so the next one is a separate undo step.
        if wasInserting, vim.mode != .insert { breakUndoCoalescing() }
        if let search = outcome.search { onVimSearch(search) }
        if !isEditable, vim.mode == .insert { vim.reset() }
        vimStateChanged()
    }

    private func vimStateChanged() {
        insertionPointColor = showsBlockCursor || hidesCaretForDrag ? .clear : NSColor(Palette.ink)
        needsDisplay = true
        onVimModeChange(vimEnabled ? vim.mode : nil)
    }

    override func setSelectedRanges(_ ranges: [NSValue], affinity: NSSelectionAffinity, stillSelecting: Bool) {
        super.setSelectedRanges(ranges, affinity: affinity, stillSelecting: stillSelecting)
        if showsBlockCursor { needsDisplay = true }
    }

    /// The find bar's matches, marked with a faint fill behind the text. Drawn in `drawBackground`, so the text itself, undo and saving never see them.
    private var highlightedRanges: [NSRange] = []
    /// The current match, outlined in ink. While the find field has the keyboard the selection is drawn in its inactive gray, so the outline is what tells it apart.
    private var currentHighlight: NSRange?

    func highlight(_ ranges: [NSRange], current: NSRange?) {
        guard ranges != highlightedRanges || current != currentHighlight else { return }
        highlightedRanges = ranges
        currentHighlight = current
        needsDisplay = true
    }

    override func drawBackground(in rect: NSRect) {
        super.drawBackground(in: rect)
        if !highlightedRanges.isEmpty { drawHighlights(in: rect) }
        if showsBlockCursor { drawBlockCursor(in: rect) }
        if showsFullWidthSpace { drawFullWidthSpaceMarks(in: rect) }
    }

    private func drawHighlights(in rect: NSRect) {
        guard let layoutManager = textLayoutManager,
            let contentManager = layoutManager.textContentManager,
            let viewport = layoutManager.textViewportLayoutController.viewportRange
        else { return }
        let documentStart = contentManager.documentRange.location
        let visibleStart = contentManager.offset(from: documentStart, to: viewport.location)
        let visibleEnd = contentManager.offset(from: documentStart, to: viewport.endLocation)
        let origin = textContainerOrigin
        let fill = NSColor(Palette.fillTrack)
        let outline = NSColor(Palette.ink)
        // Matches are in order, so only the ones overlapping the laid-out part of the text are drawn.
        for range in highlightedRanges where NSMaxRange(range) >= visibleStart {
            if range.location > visibleEnd { break }
            guard let start = contentManager.location(documentStart, offsetBy: range.location),
                let end = contentManager.location(start, offsetBy: range.length),
                let textRange = NSTextRange(location: start, end: end)
            else { continue }
            let isCurrent = range == currentHighlight
            layoutManager.enumerateTextSegments(in: textRange, type: .standard, options: []) { _, frame, _, _ in
                let box = frame.offsetBy(dx: origin.x, dy: origin.y)
                guard box.intersects(rect) else { return true }
                fill.setFill()
                box.fill()
                if isCurrent {
                    outline.setStroke()
                    let path = NSBezierPath(rect: box.insetBy(dx: 0.5, dy: 0.5))
                    path.lineWidth = 1
                    path.stroke()
                }
                return true
            }
        }
    }

    private func drawFullWidthSpaceMarks(in rect: NSRect) {
        guard let layoutManager = textLayoutManager,
            let contentManager = layoutManager.textContentManager,
            let viewport = layoutManager.textViewportLayoutController.viewportRange
        else { return }
        let documentStart = contentManager.documentRange.location
        let start = contentManager.offset(from: documentStart, to: viewport.location)
        let end = contentManager.offset(from: documentStart, to: viewport.endLocation)
        guard end > start else { return }

        let string = self.string as NSString
        let searchRange = NSRange(location: start, length: min(end, string.length) - start)
        guard searchRange.length > 0 else { return }

        let mark = NSAttributedString(
            string: "□",
            attributes: [
                .font: font ?? WaviFont.nsFont(.mono16),
                .foregroundColor: NSColor(Palette.inkSubtle),
            ])
        let origin = textContainerOrigin
        var location = searchRange.location
        let limit = NSMaxRange(searchRange)
        while location < limit {
            let found = string.range(of: "\u{3000}", options: .literal, range: NSRange(location: location, length: limit - location))
            guard found.location != NSNotFound else { break }
            location = NSMaxRange(found)
            guard let from = contentManager.location(documentStart, offsetBy: found.location),
                let to = contentManager.location(from, offsetBy: found.length),
                let range = NSTextRange(location: from, end: to)
            else { continue }
            layoutManager.enumerateTextSegments(in: range, type: .standard, options: []) { _, frame, _, _ in
                let box = frame.offsetBy(dx: origin.x, dy: origin.y)
                guard box.intersects(rect) else { return true }
                let size = mark.size()
                let point = NSPoint(x: box.minX + (box.width - size.width) / 2, y: box.minY + (box.height - size.height) / 2)
                mark.draw(at: point)
                return false
            }
        }
    }
}
