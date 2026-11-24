import AppKit
import SwiftUI

/// The single Wavi window: a glass window with 24pt corners holding DocumentWindowView.
final class DocumentWindowController: NSWindowController, NSWindowDelegate, NSMenuItemValidation {
    let store: DocumentStore
    let settings: AppSettings
    private var keyMonitor: Any?
    private var appearanceObservation: NSKeyValueObservation?

    /// The window's default size in the adopted design.
    static let defaultSize = NSSize(width: 900, height: 600)

    init(store: DocumentStore, settings: AppSettings, defaultApps: DefaultApps) {
        self.store = store
        self.settings = settings

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.defaultSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 640, height: 400)
        window.setFrameAutosaveName("DocumentWindow")
        window.tabbingMode = .disallowed

        super.init(window: window)
        window.delegate = self

        var closeTab: (TextDocument) -> Void = { _ in }
        let root = DocumentWindowView(store: store, settings: settings, defaultApps: defaultApps) { document in
            closeTab(document)
        }
        let hosting = DropHostingView(rootView: root)
        hosting.onDragEntered = { [weak store] urls in store?.beginDrag(urls) }
        hosting.onDragExited = { [weak store] in store?.endDrag() }
        hosting.onDrop = { [weak store] urls in store?.open(urls) }

        let glass = NSGlassEffectView()
        // The OS gives a titled window without a toolbar 16pt corners (measured on macOS 26); the glass follows them so the window reads as a standard one.
        glass.cornerRadius = Radius.r16
        // Lean the material toward paper so body text stays legible on any desktop.
        glass.tintColor = NSColor(Palette.paper).withAlphaComponent(0.6)
        glass.contentView = hosting
        window.contentView = glass

        closeTab = { [weak self] document in self?.close(document) }
        store.presentMessage = { [weak self] message in self?.presentMessage(message) }
        store.strings = { [weak settings] in settings?.strings ?? Strings(language: .system) }

        if window.frame.origin == .zero { window.center() }
        installKeyMonitor()
        // Switching the theme makes AppKit lay the titlebar out again, which puts the buttons back at the top. That layout runs after this change is reported, so the buttons are placed again on the next turn of the run loop.
        appearanceObservation = window.observe(\.effectiveAppearance) { [weak self] _, _ in
            DispatchQueue.main.async { self?.layoutTrafficLights() }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Window

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        layoutTrafficLights()
    }

    func windowDidResize(_ notification: Notification) { layoutTrafficLights() }
    func windowDidBecomeKey(_ notification: Notification) { layoutTrafficLights() }
    func windowDidExitFullScreen(_ notification: Notification) { layoutTrafficLights() }

    /// Centers the OS traffic lights on the tab bar row (16 from the left, tab bar center 36 from the top). The buttons themselves are the system's.
    private func layoutTrafficLights() {
        guard let window, !window.styleMask.contains(.fullScreen) else { return }
        let types: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
        // The buttons sit inside the titlebar, which is shorter than the tab bar row. A button moved past its parent's bounds no longer gets clicks, so the titlebar is grown to the bottom of the row first.
        if let titlebar = window.standardWindowButton(.closeButton)?.superview, let container = titlebar.superview,
            let frameView = container.superview
        {
            let height = Space.s16 + Space.s40
            if container.frame.height != height {
                let y = frameView.isFlipped ? 0 : frameView.bounds.height - height
                container.frame = NSRect(x: container.frame.minX, y: y, width: container.frame.width, height: height)
                titlebar.frame = container.bounds
            }
        }
        var x = Space.s16
        for type in types {
            guard let button = window.standardWindowButton(type), let superview = button.superview else { continue }
            let rowCenterFromTop = Space.s16 + Space.s40 / 2
            let y = superview.bounds.height - rowCenterFromTop - button.frame.height / 2
            button.setFrameOrigin(NSPoint(x: x, y: superview.isFlipped ? rowCenterFromTop - button.frame.height / 2 : y))
            x += button.frame.width + Space.s8
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        confirmClosing(store.documents.filter(\.needsSaveConfirmation))
    }

    // MARK: - Keys

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.window else { return event }
            if self.store.find.isVisible, let reply = self.handleFindKey(event) { return reply }
            // Esc closes the open panel.
            if event.keyCode == 53, self.store.openPanel != nil {
                self.store.closePanel()
                return nil
            }
            return event
        }
    }

    /// While the find bar is open: Esc closes it, and Return / Shift-Return in its field go to the next / previous match. Returns nil for a key it used up, or no reply to let the key through.
    private func handleFindKey(_ event: NSEvent) -> NSEvent?? {
        let find = store.find
        if event.keyCode == 53 {
            find.close()
            return .some(nil)
        }
        let isReturn = event.keyCode == 36 || event.keyCode == 76
        guard isReturn, let field = window?.firstResponder as? NSTextView, field.isFieldEditor else { return nil }
        // Return that confirms Japanese input belongs to the input method, not to the find bar.
        guard !field.hasMarkedText() else { return nil }
        if event.modifierFlags.contains(.shift) { find.previous() } else { find.next() }
        return .some(nil)
    }

    // MARK: - Menu actions (reached through the responder chain)

    @objc func showFind(_ sender: Any?) {
        // The text view holds the keyboard as an AppKit view, and SwiftUI focus can't take it from there; let it go first so the find field gets the typing.
        window?.makeFirstResponder(nil)
        store.find.open(from: store.selected.cursorLocation)
    }

    @objc func findNextMatch(_ sender: Any?) {
        store.find.next()
    }

    @objc func findPreviousMatch(_ sender: Any?) {
        store.find.previous()
    }

    @objc func newDocument(_ sender: Any?) {
        store.newTab()
    }

    @objc func openDocument(_ sender: Any?) {
        guard let window else { return }
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK else { return }
            self?.store.open(panel.urls)
        }
    }

    @objc func saveDocument(_ sender: Any?) {
        save(store.selected, completion: { _ in })
    }

    @objc func saveDocumentAs(_ sender: Any?) {
        saveAs(store.selected, completion: { _ in })
    }

    @objc func closeTab(_ sender: Any?) {
        let document = store.selected
        if store.documents.count == 1, document.isBlank {
            window?.performClose(sender)
        } else {
            close(document)
        }
    }

    @objc func copyAllText(_ sender: Any?) {
        store.copyAll()
    }

    @objc func toggleSettingsPanel(_ sender: Any?) {
        store.toggle(.settings)
    }

    @objc func selectNextTab(_ sender: Any?) {
        store.selectNeighbor(offset: 1)
    }

    @objc func selectPreviousTab(_ sender: Any?) {
        store.selectNeighbor(offset: -1)
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(copyAllText(_:)): !store.selected.text.isEmpty
        case #selector(saveDocument(_:)), #selector(saveDocumentAs(_:)): !store.selected.isReadOnly
        case #selector(selectNextTab(_:)), #selector(selectPreviousTab(_:)): store.documents.count > 1
        case #selector(findNextMatch(_:)), #selector(findPreviousMatch(_:)): !store.find.matches.isEmpty
        default: true
        }
    }

    // MARK: - Closing and saving

    private func close(_ document: TextDocument) {
        guard document.needsSaveConfirmation, let window else {
            store.remove(document)
            return
        }
        store.select(document)
        let alert = makeSaveAlert(for: document)
        alert.beginSheetModal(for: window) { [weak self] response in
            guard let self else { return }
            switch response {
            case .alertFirstButtonReturn:
                self.save(document) { saved in if saved { self.store.remove(document) } }
            case .alertSecondButtonReturn:
                self.store.remove(document)
            default:
                break
            }
        }
    }

    /// Asks about each unsaved file one by one (modal). Returns false if cancelled.
    func confirmClosing(_ documents: [TextDocument]) -> Bool {
        for document in documents {
            store.select(document)
            switch makeSaveAlert(for: document).runModal() {
            case .alertFirstButtonReturn:
                guard let url = document.url, write(document, to: url) else { return false }
            case .alertSecondButtonReturn:
                continue
            default:
                return false
            }
        }
        return true
    }

    private func makeSaveAlert(for document: TextDocument) -> NSAlert {
        let strings = settings.strings
        let alert = NSAlert()
        alert.messageText = strings.saveChanges(document.title(strings))
        alert.addButton(withTitle: strings.save)
        alert.addButton(withTitle: strings.dontSave)
        alert.addButton(withTitle: strings.cancel)
        return alert
    }

    private func save(_ document: TextDocument, completion: @escaping (Bool) -> Void) {
        guard !document.isReadOnly else { return completion(false) }
        if let url = document.url {
            completion(write(document, to: url))
        } else {
            saveAs(document, completion: completion)
        }
    }

    private func saveAs(_ document: TextDocument, completion: @escaping (Bool) -> Void) {
        guard let window, !document.isReadOnly else { return completion(false) }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = document.url?.lastPathComponent ?? "\(settings.strings.untitled).txt"
        panel.beginSheetModal(for: window) { [weak self] response in
            guard let self, response == .OK, let url = panel.url else { return completion(false) }
            completion(self.write(document, to: url))
        }
    }

    @discardableResult
    private func write(_ document: TextDocument, to url: URL) -> Bool {
        let (data, fellBack) = document.dataForSaving()
        do {
            try data.write(to: url, options: .atomic)
            document.didSave(to: url, fellBackToUTF8: fellBack)
            if fellBack { presentMessage(settings.strings.encodingFallback) }
            return true
        } catch {
            presentError(error)
            return false
        }
    }

    private func presentMessage(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        if let window, window.isVisible {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}

extension TextDocument {
    /// Only files on disk ask before closing. Untitled text is a scratch pad and is discarded without asking (SPEC 7, decided provisionally).
    var needsSaveConfirmation: Bool { url != nil && isDirty && !isReadOnly }
}
