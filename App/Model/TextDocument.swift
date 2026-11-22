import Foundation
import Observation

/// One tab's text and what Wavi knows about it.
/// The live text is edited by the Editor; it writes every change back to `text`.
@Observable
final class TextDocument: Identifiable {
    let id = UUID()
    private(set) var url: URL?
    private(set) var encoding: TextEncoding
    private(set) var hasByteOrderMark: Bool
    private(set) var lineEnding: LineEnding
    let isReadOnly: Bool
    private(set) var isDirty = false

    private(set) var byteCount = 0
    private(set) var lineCount = 0

    /// The text exactly as it is, line endings included.
    var text: String {
        didSet {
            guard text != oldValue else { return }
            isDirty = true
            updateStatistics()
        }
    }

    init(text: String = "", url: URL? = nil, decoded: DecodedText? = nil, isReadOnly: Bool = false) {
        self.text = decoded?.text ?? text
        self.url = url
        self.encoding = decoded?.encoding ?? .utf8
        self.hasByteOrderMark = decoded?.hasByteOrderMark ?? false
        self.lineEnding = decoded?.lineEnding ?? .lf
        self.isReadOnly = isReadOnly
        updateStatistics()
    }

    /// An untitled tab with nothing typed yet. Dropping a file replaces it.
    var isBlank: Bool { url == nil && text.isEmpty }

    func title(_ strings: Strings) -> String {
        url?.lastPathComponent ?? strings.untitled
    }

    /// Type label for the status bar: the extension in capitals, or TEXT.
    var kindLabel: String {
        let ext = url?.pathExtension ?? ""
        return ext.isEmpty ? "TEXT" : ext.uppercased()
    }

    /// Data to write to disk. Lone line feeds typed into a CRLF / CR file
    /// are converted to that file's line ending.
    func dataForSaving() -> (Data, fellBackToUTF8: Bool) {
        let normalized = normalizedLineEndings(text)
        if let data = TextDecoder.encode(normalized, as: encoding, byteOrderMark: hasByteOrderMark) {
            return (data, false)
        }
        let data = TextDecoder.encode(normalized, as: .utf8, byteOrderMark: false) ?? Data()
        return (data, true)
    }

    func didSave(to url: URL, fellBackToUTF8: Bool) {
        self.url = url
        if fellBackToUTF8 {
            encoding = .utf8
            hasByteOrderMark = false
        }
        isDirty = false
        updateStatistics()
    }

    private func normalizedLineEndings(_ text: String) -> String {
        switch lineEnding {
        case .lf:
            return text
        case .crlf:
            return text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\n", with: "\r\n")
        case .cr:
            return text.replacingOccurrences(of: "\r\n", with: "\r").replacingOccurrences(of: "\n", with: "\r")
        }
    }

    private func updateStatistics() {
        lineCount = TextDecoder.lineCount(text)
        switch encoding {
        case .utf8:
            byteCount = text.utf8.count + (hasByteOrderMark ? 3 : 0)
        case .utf16LittleEndian, .utf16BigEndian:
            byteCount = text.utf16.count * 2 + (hasByteOrderMark ? 2 : 0)
        case .shiftJIS, .eucJP:
            byteCount = text.data(using: encoding.foundation, allowLossyConversion: true)?.count ?? text.utf8.count
        }
    }
}
