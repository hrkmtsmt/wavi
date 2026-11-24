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
    /// Set while a file is dragged over the window, so no cursor is drawn.
    var hidesCaretForDrag = false {
        didSet { if oldValue != hidesCaretForDrag { vimStateChanged() } }
    }
    private var vim = VimEngine()

    private var showsBlockCursor: Bool { vimEnabled && vim.mode != .insert && !hidesCaretForDrag }

    override func keyDown(with event: NSEvent) {
        guard vimEnabled, !hasMarkedText(), let key = Self.vimKey(event) else {
            super.keyDown(with: event)
            return
        }
        let clipboard = NSPasteboard.general.string(forType: .string)
        let outcome = vim.handle(key, text: string, selection: selectedRange(), clipboard: clipboard)
        if outcome.passThrough {
            super.keyDown(with: event)
            return
        }
        perform(outcome)
        if !isEditable, vim.mode == .insert { vim.reset() }
        vimStateChanged()
    }

    /// The key as Vim reads it, or nil for keys Vim leaves to the text view: ⌘ shortcuts, arrows and other function keys.
    private static func vimKey(_ event: NSEvent) -> VimKey? {
        if event.keyCode == 53 { return .escape }
        if event.modifierFlags.contains(.command) { return nil }
        let control = event.modifierFlags.contains(.control)
        guard let characters = control ? event.charactersIgnoringModifiers : event.characters,
            let scalar = characters.unicodeScalars.first,
            !(0xF700...0xF8FF).contains(scalar.value)
        else { return nil }
        return VimKey(characters, control: control)
    }

    /// Applies what the engine decided. A command's edits are one undo step, and yanked text goes to the clipboard.
    private func perform(_ outcome: VimOutcome) {
        if let yanked = outcome.yanked {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(yanked, forType: .string)
        }
        switch outcome.history {
        case .undo: undoManager?.undo()
        case .redo: undoManager?.redo()
        case nil: break
        }
        if outcome.history != nil {
            // Undo selects what it restored; in Vim the cursor just goes to its start.
            let text = VimText(string)
            setSelectedRange(NSRange(location: text.clampedToLine(text.normalCursor(selectedRange().location)), length: 0))
        }
        if !outcome.edits.isEmpty, isEditable, let storage = textStorage {
            breakUndoCoalescing()
            undoManager?.beginUndoGrouping()
            for edit in outcome.edits where NSMaxRange(edit.range) <= storage.length {
                guard shouldChangeText(in: edit.range, replacementString: edit.replacement) else { continue }
                storage.replaceCharacters(in: edit.range, with: NSAttributedString(string: edit.replacement, attributes: typingAttributes))
                didChangeText()
            }
            undoManager?.endUndoGrouping()
        }
        if let selection = outcome.selection {
            let length = (string as NSString).length
            let location = min(selection.location, length)
            let range = NSRange(location: location, length: min(selection.length, length - location))
            setSelectedRange(range)
            scrollRangeToVisible(range)
        }
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

    /// The block over the character at the cursor (or a space's width at the end of a line), drawn behind the text so the character stays readable.
    private func drawBlockCursor(in rect: NSRect) {
        let selection = selectedRange()
        guard selection.length == 0, let layoutManager = textLayoutManager, let contentManager = layoutManager.textContentManager else {
            return
        }
        let text = string as NSString
        let documentStart = contentManager.documentRange.location
        guard let start = contentManager.location(documentStart, offsetBy: selection.location) else { return }
        let atCharacter = selection.location < text.length && !VimText(string).isNewline(at: selection.location)
        let length = atCharacter ? text.rangeOfComposedCharacterSequence(at: selection.location).length : 0
        guard let end = contentManager.location(start, offsetBy: length), let range = NSTextRange(location: start, end: end) else { return }
        let spaceWidth = NSAttributedString(string: " ", attributes: typingAttributes).size().width
        let origin = textContainerOrigin
        layoutManager.enumerateTextSegments(in: range, type: .standard, options: []) { _, frame, _, _ in
            var box = frame.offsetBy(dx: origin.x, dy: origin.y)
            if !atCharacter { box.size.width = spaceWidth }
            guard box.intersects(rect) else { return false }
            NSColor(Palette.ink).withAlphaComponent(0.35).setFill()
            box.fill()
            return false
        }
    }

    private static let fileTypes: Set<NSPasteboard.PasteboardType> = [
        .fileURL, .URL, NSPasteboard.PasteboardType("NSFilenamesPboardType"),
    ]

    override var acceptableDragTypes: [NSPasteboard.PasteboardType] {
        super.acceptableDragTypes.filter { !Self.fileTypes.contains($0) }
    }

    // Finder also puts a file's URL on the pasteboard as plain text, which the text view would insert. Drags that carry files go to the window instead.

    private var fileDropTarget: NSView? {
        var view = superview
        while let current = view {
            if current is FileDropTarget { return current }
            view = current.superview
        }
        return nil
    }

    private func carriesFiles(_ info: NSDraggingInfo) -> Bool {
        info.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if carriesFiles(sender), let target = fileDropTarget { return target.draggingEntered(sender) }
        return super.draggingEntered(sender)
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if carriesFiles(sender), let target = fileDropTarget { return target.draggingUpdated(sender) }
        return super.draggingUpdated(sender)
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        if let sender, carriesFiles(sender), let target = fileDropTarget { return target.draggingExited(sender) }
        super.draggingExited(sender)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if carriesFiles(sender), let target = fileDropTarget { return target.prepareForDragOperation(sender) }
        return super.prepareForDragOperation(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if carriesFiles(sender), let target = fileDropTarget { return target.performDragOperation(sender) }
        return super.performDragOperation(sender)
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        if let sender, carriesFiles(sender) { return }
        super.concludeDragOperation(sender)
    }

    // The status bar, tab bar and panels are drawn over the text view. AppKit would still show the text cursor across the whole text view, so it is only set where the text view really is the frontmost view; elsewhere the buttons on top set their own pointer.

    private func isCovered(at locationInWindow: NSPoint) -> Bool {
        guard let frameView = window?.contentView?.superview, let hit = frameView.hitTest(locationInWindow) else { return false }
        return !hit.isDescendant(of: self)
    }

    override func resetCursorRects() {
        // Cursor rects would show the text cursor even under the views on top; cursorUpdate and mouseMoved set it instead.
    }

    override func cursorUpdate(with event: NSEvent) {
        if isCovered(at: event.locationInWindow) { return }
        NSCursor.iBeam.set()
    }

    override func mouseMoved(with event: NSEvent) {
        if isCovered(at: event.locationInWindow) { return }
        super.mouseMoved(with: event)
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
