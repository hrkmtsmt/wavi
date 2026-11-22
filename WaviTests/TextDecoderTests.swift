import Foundation
import Testing
@testable import Wavi

struct TextDecoderTests {
    @Test func decodesUTF8() throws {
        let decoded = try TextDecoder.decode(Data("こんにちは\nworld\n".utf8))
        #expect(decoded.encoding == .utf8)
        #expect(decoded.text == "こんにちは\nworld\n")
        #expect(decoded.hasByteOrderMark == false)
    }

    @Test func decodesUTF8WithBOM() throws {
        let data = Data([0xEF, 0xBB, 0xBF]) + Data("abc".utf8)
        let decoded = try TextDecoder.decode(data)
        #expect(decoded.encoding == .utf8)
        #expect(decoded.hasByteOrderMark)
        #expect(decoded.text == "abc")
    }

    @Test func decodesUTF16WithAndWithoutBOM() throws {
        let text = "hello 世界\r\n"
        let withBOM = Data([0xFF, 0xFE]) + text.data(using: .utf16LittleEndian)!
        #expect(try TextDecoder.decode(withBOM).encoding == .utf16LittleEndian)
        #expect(try TextDecoder.decode(withBOM).text == text)

        let bigEndian = "plain ascii text here".data(using: .utf16BigEndian)!
        #expect(try TextDecoder.decode(bigEndian).encoding == .utf16BigEndian)
    }

    @Test func decodesShiftJISAndEUCJP() throws {
        let text = "日本語のテキストです。設定ファイル"
        let sjis = try TextDecoder.decode(text.data(using: .shiftJIS)!)
        #expect(sjis.encoding == .shiftJIS)
        #expect(sjis.text == text)

        let euc = try TextDecoder.decode(text.data(using: .japaneseEUC)!)
        #expect(euc.encoding == .eucJP)
        #expect(euc.text == text)
    }

    @Test func rejectsBinary() {
        let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D])
        #expect(throws: TextFileError.binary) { try TextDecoder.decode(png) }
    }

    @Test func keepsLineEndings() throws {
        let crlf = try TextDecoder.decode(Data("a\r\nb\r\n".utf8))
        #expect(crlf.lineEnding == .crlf)
        #expect(crlf.text == "a\r\nb\r\n")
        #expect(try TextDecoder.decode(Data("a\rb\r".utf8)).lineEnding == .cr)
        #expect(try TextDecoder.decode(Data("a\nb".utf8)).lineEnding == .lf)
    }

    @Test func countsLines() {
        #expect(TextDecoder.lineCount("") == 0)
        #expect(TextDecoder.lineCount("a") == 1)
        #expect(TextDecoder.lineCount("a\n") == 1)
        #expect(TextDecoder.lineCount("a\nb") == 2)
        #expect(TextDecoder.lineCount("a\r\nb\r\n") == 2)
        #expect(TextDecoder.lineCount("\n\n") == 2)
        #expect(TextDecoder.lineCount("a\rb") == 2)
    }

    @Test func formatsBytes() {
        #expect(ByteFormat.string(0) == "0 B")
        #expect(ByteFormat.string(412) == "412 B")
        #expect(ByteFormat.string(1_200) == "1.2 KB")
        #expect(ByteFormat.string(18_600) == "18.6 KB")
        #expect(ByteFormat.string(2_400_000) == "2.4 MB")
        #expect(ByteFormat.string(512_000) == "512 KB")
    }
}

@MainActor
struct TextDocumentTests {
    @Test func savesWithOriginalEncodingAndLineEnding() throws {
        let decoded = try TextDecoder.decode("一行目\r\n".data(using: .shiftJIS)!)
        let document = TextDocument(url: URL(fileURLWithPath: "/tmp/x.txt"), decoded: decoded)
        document.text += "二行目\n"
        let (data, fellBack) = document.dataForSaving()
        #expect(fellBack == false)
        #expect(String(data: data, encoding: .shiftJIS) == "一行目\r\n二行目\r\n")
    }

    @Test func fallsBackToUTF8WhenNotRepresentable() throws {
        let decoded = try TextDecoder.decode("日本語のテキスト".data(using: .shiftJIS)!)
        #expect(decoded.encoding == .shiftJIS)
        let document = TextDocument(url: URL(fileURLWithPath: "/tmp/x.txt"), decoded: decoded)
        document.text = "emoji 🌊"
        let (data, fellBack) = document.dataForSaving()
        #expect(fellBack)
        #expect(String(data: data, encoding: .utf8) == "emoji 🌊")
    }

    @Test func blankUntitledTab() {
        let document = TextDocument()
        #expect(document.isBlank)
        #expect(document.kindLabel == "TEXT")
        #expect(document.byteCount == 0)
        document.text = "x"
        #expect(!document.isBlank)
        #expect(document.byteCount == 1)
    }

    @Test func dropReplacesBlankTabOnly() {
        let store = DocumentStore()
        #expect(store.documents.count == 1)
        store.beginDrag([URL(fileURLWithPath: "/tmp/a.json")])
        #expect(store.dragPreview?.replacesSelection == true)
        store.endDrag()
        store.selected.text = "typed"
        store.beginDrag([URL(fileURLWithPath: "/tmp/a.json")])
        #expect(store.dragPreview?.replacesSelection == false)
    }
}
