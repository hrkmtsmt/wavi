import AppKit
import SwiftUI

/// The body text. The one Wavi-specific piece: an NSTextView per tab, the placeholder of an empty tab, and the full-width-space marks.
struct Editor: View {
    let document: TextDocument
    /// All open tabs, so closed tabs' text views can be released.
    let openDocumentIDs: Set<TextDocument.ID>
    let showsFullWidthSpace: Bool
    let vimKeys: Bool
    let isDragging: Bool
    let find: FindState
    let strings: Strings

    var body: some View {
        GeometryReader { proxy in
            // Show whole lines only: the text never runs behind the status bar.
            let lineHeight = TextStyle.mono16.lineHeight
            let visibleHeight = (proxy.size.height / lineHeight).rounded(.down) * lineHeight
            ZStack(alignment: .topLeading) {
                EditorTextView(
                    document: document, openDocumentIDs: openDocumentIDs, showsFullWidthSpace: showsFullWidthSpace, vimKeys: vimKeys,
                    find: find
                )
                .frame(height: visibleHeight)
                if document.text.isEmpty {
                    placeholder
                }
            }
        }
    }

    @ViewBuilder private var placeholder: some View {
        Group {
            if isDragging {
                Text(strings.releaseToOpen)
                    .textStyle(.mono16, bold: true)
                    .foregroundStyle(Palette.stateDrop)
            } else {
                Text(strings.placeholder)
                    .textStyle(.mono16)
                    .foregroundStyle(Palette.inkSubtle)
            }
        }
        .frame(height: TextStyle.mono16.lineHeight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Hosts one scroll view per document and shows the selected one, so each tab keeps its own undo history, selection and scroll position.
private struct EditorTextView: NSViewRepresentable {
    let document: TextDocument
    let openDocumentIDs: Set<TextDocument.ID>
    let showsFullWidthSpace: Bool
    let vimKeys: Bool
    let find: FindState

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.masksToBounds = true
        return container
    }

    func updateNSView(_ container: NSView, context: Context) {
        let coordinator = context.coordinator
        coordinator.release(keeping: openDocumentIDs)
        let scrollView = coordinator.scrollView(for: document)
        coordinator.textView(for: document)?.showsFullWidthSpace = showsFullWidthSpace
        coordinator.textView(for: document)?.vimEnabled = vimKeys
        coordinator.hideCaret(context.environment.isDragging)
        if let textView = coordinator.textView(for: document) {
            coordinator.apply(find, to: textView)
        }

        if scrollView.superview !== container {
            for subview in container.subviews { subview.removeFromSuperview() }
            scrollView.frame = container.bounds
            scrollView.autoresizingMask = [.width, .height]
            container.addSubview(scrollView)
            let textView = coordinator.textView(for: document)
            DispatchQueue.main.async {
                container.window?.makeFirstResponder(textView)
            }
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        private var scrollViews: [TextDocument.ID: NSScrollView] = [:]
        private var documents: [ObjectIdentifier: TextDocument] = [:]
        private var observers: [NSObjectProtocol] = []

        func textView(for document: TextDocument) -> WaviTextView? {
            scrollViews[document.id]?.documentView as? WaviTextView
        }

        func scrollView(for document: TextDocument) -> NSScrollView {
            if let existing = scrollViews[document.id] { return existing }
            let scrollView = Self.makeScrollView(for: document)
            if let textView = scrollView.documentView as? WaviTextView {
                textView.delegate = self
                textView.onVimModeChange = { [weak document] mode in document?.vimMode = mode }
                documents[ObjectIdentifier(textView)] = document
                observers.append(
                    NotificationCenter.default.addObserver(
                        forName: NSView.boundsDidChangeNotification,
                        object: scrollView.contentView,
                        queue: .main
                    ) { [weak textView] _ in
                        MainActor.assumeIsolated { textView?.needsDisplay = true }
                    })
            }
            scrollViews[document.id] = scrollView
            return scrollView
        }

        func release(keeping ids: Set<TextDocument.ID>) {
            for (id, scrollView) in scrollViews where !ids.contains(id) {
                if let textView = scrollView.documentView {
                    documents[ObjectIdentifier(textView)] = nil
                }
                scrollView.removeFromSuperview()
                scrollViews[id] = nil
            }
        }

        func hideCaret(_ hidden: Bool) {
            for scrollView in scrollViews.values {
                (scrollView.documentView as? WaviTextView)?.hidesCaretForDrag = hidden
            }
        }

        // MARK: Find

        private var revealedRequest = 0
        private var highlighted: FindHighlight?
        private var wasFinding = false

        /// Shows the find bar's state in the text view: every match lightly highlighted, the current one selected and scrolled into view, and the text view focused again once the bar closes.
        func apply(_ find: FindState, to textView: WaviTextView) {
            let matches = find.isVisible ? find.matches : []
            let current = find.isVisible ? find.currentRange : nil
            let wanted = FindHighlight(view: ObjectIdentifier(textView), matches: matches, current: current)
            if highlighted != wanted {
                for scrollView in scrollViews.values {
                    (scrollView.documentView as? WaviTextView)?.highlight([], current: nil)
                }
                textView.highlight(matches, current: current)
                highlighted = wanted
            }
            if find.revealRequest != revealedRequest {
                revealedRequest = find.revealRequest
                if let range = find.currentRange, NSMaxRange(range) <= (textView.string as NSString).length {
                    textView.setSelectedRange(range)
                    textView.scrollRangeToVisible(range)
                    textView.showFindIndicator(for: range)
                }
            }
            if wasFinding, !find.isVisible {
                DispatchQueue.main.async { textView.window?.makeFirstResponder(textView) }
            }
            wasFinding = find.isVisible
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                let document = documents[ObjectIdentifier(textView)]
            else { return }
            document.cursorLocation = textView.selectedRange().location
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                let document = documents[ObjectIdentifier(textView)]
            else { return }
            document.text = textView.string
            textView.needsDisplay = true
        }

        private static func makeScrollView(for document: TextDocument) -> NSScrollView {
            let textView = WaviTextView(usingTextLayoutManager: true)
            let font = WaviFont.nsFont(.mono16)
            let lineHeight = TextStyle.mono16.lineHeight
            let natural = font.ascender - font.descender + font.leading
            let paragraph = NSMutableParagraphStyle()
            paragraph.minimumLineHeight = lineHeight
            paragraph.maximumLineHeight = lineHeight
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor(Palette.ink),
                .paragraphStyle: paragraph,
                .baselineOffset: (lineHeight - natural) / 2,
            ]

            textView.isRichText = false
            textView.importsGraphics = false
            textView.allowsUndo = true
            textView.isEditable = !document.isReadOnly
            textView.isSelectable = true
            // Wavi draws its own find bar in the middle of the window (FindBar).
            textView.usesFindBar = false
            textView.drawsBackground = false
            textView.textContainerInset = .zero
            textView.textContainer?.lineFragmentPadding = 0
            textView.textContainer?.widthTracksTextView = true
            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.autoresizingMask = [.width]
            textView.font = font
            textView.textColor = NSColor(Palette.ink)
            textView.defaultParagraphStyle = paragraph
            textView.typingAttributes = attributes
            textView.insertionPointColor = NSColor(Palette.ink)
            disableSmartReplacements(in: textView)
            textView.setAccessibilityLabel(Strings(language: .system).body)

            if !document.text.isEmpty {
                textView.textStorage?.setAttributedString(NSAttributedString(string: document.text, attributes: attributes))
            }

            let scrollView = NSScrollView()
            scrollView.drawsBackground = false
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = true
            scrollView.scrollerStyle = .overlay
            scrollView.documentView = textView
            scrollView.contentView.postsBoundsChangedNotifications = true
            textView.minSize = .zero
            textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            return scrollView
        }

        /// Plain text, exactly as typed: no smart replacements.
        private static func disableSmartReplacements(in textView: NSTextView) {
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.isAutomaticDashSubstitutionEnabled = false
            textView.isAutomaticTextReplacementEnabled = false
            textView.isAutomaticSpellingCorrectionEnabled = false
            textView.isContinuousSpellCheckingEnabled = false
            textView.isGrammarCheckingEnabled = false
            textView.isAutomaticLinkDetectionEnabled = false
            textView.isAutomaticDataDetectionEnabled = false
            textView.smartInsertDeleteEnabled = false
        }
    }
}

private struct IsDraggingKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True while a file is dragged over the window.
    var isDragging: Bool {
        get { self[IsDraggingKey.self] }
        set { self[IsDraggingKey.self] = newValue }
    }
}

/// What the find highlights were last drawn for, so they are only redrawn when something changed.
private struct FindHighlight: Equatable {
    var view: ObjectIdentifier
    var matches: [NSRange]
    var current: NSRange?
}
