import AppKit

/// The Vim side of WaviTextView: turning key events into VimKeys, applying the engine's outcome, and drawing the block cursor.
extension WaviTextView {
    /// The key as Vim reads it, or nil for keys Vim leaves to the text view: ⌘ shortcuts, arrows and other function keys.
    static func vimKey(_ event: NSEvent) -> VimKey? {
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
    func perform(_ outcome: VimOutcome) {
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
        if vim.mode == .insert, outcome.edits.count == 1, let edit = outcome.edits.first, isEditable,
            NSMaxRange(edit.range) <= (string as NSString).length
        {
            // c, o and O start a change that goes on with typing. Making the edit as typing lets AppKit join it with what is typed next, so u undoes the whole change in one step, as in Vim.
            breakUndoCoalescing()
            insertText(edit.replacement, replacementRange: edit.range)
        } else if !outcome.edits.isEmpty, isEditable, let storage = textStorage {
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

    /// The block over the character at the cursor (or a space's width at the end of a line), drawn behind the text so the character stays readable.
    func drawBlockCursor(in rect: NSRect) {
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
}
