import AppKit

/// The text view behind the Editor (TextKit 2).
/// - Leaves file drops to the window, so dropping a file opens it instead of
///   inserting its path.
/// - Optionally marks full-width spaces (U+3000) with a faint "□".
final class WaviTextView: NSTextView {
    var showsFullWidthSpace = false {
        didSet { if oldValue != showsFullWidthSpace { needsDisplay = true } }
    }

    private static let fileTypes: Set<NSPasteboard.PasteboardType> = [
        .fileURL, .URL, NSPasteboard.PasteboardType("NSFilenamesPboardType"),
    ]

    override var acceptableDragTypes: [NSPasteboard.PasteboardType] {
        super.acceptableDragTypes.filter { !Self.fileTypes.contains($0) }
    }

    override func drawBackground(in rect: NSRect) {
        super.drawBackground(in: rect)
        if showsFullWidthSpace { drawFullWidthSpaceMarks(in: rect) }
    }

    private func drawFullWidthSpaceMarks(in rect: NSRect) {
        guard let layoutManager = textLayoutManager,
              let contentManager = layoutManager.textContentManager,
              let viewport = layoutManager.textViewportLayoutController.viewportRange else { return }
        let documentStart = contentManager.documentRange.location
        let start = contentManager.offset(from: documentStart, to: viewport.location)
        let end = contentManager.offset(from: documentStart, to: viewport.endLocation)
        guard end > start else { return }

        let string = self.string as NSString
        let searchRange = NSRange(location: start, length: min(end, string.length) - start)
        guard searchRange.length > 0 else { return }

        let mark = NSAttributedString(string: "□", attributes: [
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
                  let range = NSTextRange(location: from, end: to) else { continue }
            layoutManager.enumerateTextSegments(in: range, type: .standard, options: []) { _, frame, baseline, _ in
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
