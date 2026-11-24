import Foundation
import Testing

@testable import Wavi

/// Plays keys into a VimEngine against a plain string, applying its edits the way the text view does.
struct Harness {
    var text: String
    var cursor: Int
    var selection: NSRange
    var clipboard: String?
    var engine = VimEngine()
    var history: [VimOutcome.History] = []
    var searches: [VimSearch] = []

    /// `|` in `text` marks the cursor.
    init(_ text: String, clipboard: String? = nil) {
        let marker = (text as NSString).range(of: "|")
        self.text = (text as NSString).replacingCharacters(in: marker, with: "")
        cursor = marker.location
        selection = NSRange(location: marker.location, length: 0)
        self.clipboard = clipboard
    }

    /// Keys as typed; `<esc>` is Escape and `<c-r>` is Control-R. In insert mode other keys are typed as text.
    mutating func type(_ keys: String) {
        var rest = Substring(keys)
        while let first = rest.first {
            let key: VimKey
            if rest.hasPrefix("<esc>") {
                key = .escape
                rest = rest.dropFirst(5)
            } else if rest.hasPrefix("<c-") {
                key = VimKey(String(rest.dropFirst(3).prefix(1)), control: true)
                rest = rest.dropFirst(5)
            } else {
                key = VimKey(String(first))
                rest = rest.dropFirst()
            }
            let outcome = engine.handle(key, text: text, selection: selection, clipboard: clipboard)
            if outcome.passThrough {
                text = (text as NSString).replacingCharacters(in: selection, with: key.text)
                selection = NSRange(location: selection.location + (key.text as NSString).length, length: 0)
                cursor = selection.location
                continue
            }
            for edit in outcome.edits {
                text = (text as NSString).replacingCharacters(in: edit.range, with: edit.replacement)
            }
            if let yanked = outcome.yanked { clipboard = yanked }
            if let entry = outcome.history { history.append(entry) }
            if let search = outcome.search { searches.append(search) }
            if let new = outcome.selection {
                selection = new
                cursor = new.location
            }
        }
    }

    /// The text with `|` at the cursor, for comparing in one go.
    var marked: String { (text as NSString).replacingCharacters(in: NSRange(location: cursor, length: 0), with: "|") }
}

func after(_ keys: String, _ text: String, clipboard: String? = nil) -> Harness {
    var harness = Harness(text, clipboard: clipboard)
    harness.type(keys)
    return harness
}
