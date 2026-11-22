import Foundation

/// Text encodings Wavi detects and writes back.
nonisolated enum TextEncoding: String, Sendable, CaseIterable {
    case utf8
    case utf16LittleEndian
    case utf16BigEndian
    case shiftJIS
    case eucJP

    var foundation: String.Encoding {
        switch self {
        case .utf8: .utf8
        case .utf16LittleEndian: .utf16LittleEndian
        case .utf16BigEndian: .utf16BigEndian
        case .shiftJIS: .shiftJIS
        case .eucJP: .japaneseEUC
        }
    }

    var label: String {
        switch self {
        case .utf8: "UTF-8"
        case .utf16LittleEndian, .utf16BigEndian: "UTF-16"
        case .shiftJIS: "Shift_JIS"
        case .eucJP: "EUC-JP"
        }
    }

    var byteOrderMark: [UInt8] {
        switch self {
        case .utf8: [0xEF, 0xBB, 0xBF]
        case .utf16LittleEndian: [0xFF, 0xFE]
        case .utf16BigEndian: [0xFE, 0xFF]
        case .shiftJIS, .eucJP: []
        }
    }
}

/// Line ending style of a file. Kept as-is in the text; used when saving new lines.
nonisolated enum LineEnding: String, Sendable {
    case lf = "\n"
    case crlf = "\r\n"
    case cr = "\r"
}

/// The result of reading bytes as text.
nonisolated struct DecodedText: Sendable, Equatable {
    var text: String
    var encoding: TextEncoding
    var hasByteOrderMark: Bool
    var lineEnding: LineEnding
}

nonisolated enum TextFileError: Error, Equatable {
    /// The bytes are not text (an image, an archive, ...).
    case binary
    /// The file is larger than Wavi will open.
    case tooLarge
}

/// Reads bytes as text: detects the encoding (UTF-8 / UTF-16 / Shift_JIS / EUC-JP), rejects binary data, and remembers the line ending.
nonisolated enum TextDecoder {
    /// Files above this size are opened read-only.
    static let readOnlyThreshold = 20 * 1_000_000
    /// Files above this size are not opened at all.
    static let openLimit = 512 * 1_000_000

    static func decode(_ data: Data) throws(TextFileError) -> DecodedText {
        let bytes = [UInt8](data.prefix(4))

        for encoding in [TextEncoding.utf8, .utf16LittleEndian, .utf16BigEndian] {
            let bom = encoding.byteOrderMark
            if bytes.starts(with: bom), let text = String(data: data.dropFirst(bom.count), encoding: encoding.foundation) {
                return DecodedText(text: text, encoding: encoding, hasByteOrderMark: true, lineEnding: lineEnding(of: text))
            }
        }

        if let encoding = utf16WithoutBOM(data), let text = String(data: data, encoding: encoding.foundation) {
            return DecodedText(text: text, encoding: encoding, hasByteOrderMark: false, lineEnding: lineEnding(of: text))
        }

        if looksBinary(data) { throw .binary }

        if let text = String(data: data, encoding: .utf8) {
            return DecodedText(text: text, encoding: .utf8, hasByteOrderMark: false, lineEnding: lineEnding(of: text))
        }

        let candidates: [TextEncoding] = [.shiftJIS, .eucJP]
        let decoded = candidates.compactMap { encoding in
            String(data: data, encoding: encoding.foundation).map { (encoding: encoding, text: $0) }
        }
        // On a tie the earlier candidate wins.
        if let best = decoded.max(by: { japaneseScore($0.text) < japaneseScore($1.text) }) {
            return DecodedText(
                text: best.text, encoding: best.encoding, hasByteOrderMark: false, lineEnding: lineEnding(of: best.text))
        }
        throw .binary
    }

    static func encode(_ text: String, as encoding: TextEncoding, byteOrderMark: Bool) -> Data? {
        guard let body = text.data(using: encoding.foundation, allowLossyConversion: false) else { return nil }
        return byteOrderMark ? Data(encoding.byteOrderMark) + body : body
    }

    /// Counts lines the way people read them: empty text has 0 lines, and a trailing line break does not start a new line.
    static func lineCount(_ text: String) -> Int {
        var count = 0
        var lastWasBreak = true
        var previousWasCR = false
        for unit in text.utf8 {
            switch unit {
            case 0x0A:
                if !previousWasCR { count += 1 }
                lastWasBreak = true
                previousWasCR = false
            case 0x0D:
                count += 1
                lastWasBreak = true
                previousWasCR = true
            default:
                lastWasBreak = false
                previousWasCR = false
            }
        }
        if text.isEmpty { return 0 }
        return lastWasBreak ? count : count + 1
    }

    static func lineEnding(of text: String) -> LineEnding {
        var lf = 0
        var crlf = 0
        var cr = 0
        var previousWasCR = false
        for unit in text.utf8.prefix(1_000_000) {
            if unit == 0x0A {
                if previousWasCR {
                    crlf += 1
                    cr -= 1
                } else {
                    lf += 1
                }
                previousWasCR = false
            } else if unit == 0x0D {
                cr += 1
                previousWasCR = true
            } else {
                previousWasCR = false
            }
        }
        if crlf > lf && crlf >= cr { return .crlf }
        if cr > lf && cr > crlf { return .cr }
        return .lf
    }

    // MARK: - Heuristics

    private static func looksBinary(_ data: Data) -> Bool {
        let sample = data.prefix(8192)
        if sample.isEmpty { return false }
        var control = 0
        for byte in sample {
            if byte == 0 { return true }
            if byte < 0x09 || (byte > 0x0D && byte < 0x20 && byte != 0x1B) { control += 1 }
        }
        return control * 10 > sample.count
    }

    /// UTF-16 text without a BOM has a zero byte in every other position for ASCII.
    private static func utf16WithoutBOM(_ data: Data) -> TextEncoding? {
        let sample = [UInt8](data.prefix(4096))
        guard sample.count >= 4, sample.count % 2 == 0 else { return nil }
        var evenZeros = 0
        var oddZeros = 0
        for (index, byte) in sample.enumerated() where byte == 0 {
            if index % 2 == 0 { evenZeros += 1 } else { oddZeros += 1 }
        }
        let half = sample.count / 2
        if oddZeros * 10 > half * 6, evenZeros * 10 < half { return .utf16LittleEndian }
        if evenZeros * 10 > half * 6, oddZeros * 10 < half { return .utf16BigEndian }
        return nil
    }

    /// Higher when the decoded text looks like ordinary Japanese.
    private static func japaneseScore(_ text: String) -> Int {
        var score = 0
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x3040...0x30FF: score += 3  // kana
            case 0x4E00...0x9FFF: score += 2  // common kanji
            case 0x3000...0x303F, 0xFF01...0xFF5E: score += 1  // full-width punctuation
            case 0xFF61...0xFF9F: score -= 1  // half-width kana: common in mis-decoding
            case 0xE000...0xF8FF, 0xFFFD: score -= 5  // private use / replacement
            default: break
            }
        }
        return score
    }
}

/// Formats byte counts the way Finder does (base 1000).
nonisolated enum ByteFormat {
    static func string(_ bytes: Int) -> String {
        if bytes < 1000 { return "\(bytes) B" }
        let units = ["KB", "MB", "GB", "TB"]
        var value = Double(bytes) / 1000
        var index = 0
        while value >= 1000, index < units.count - 1 {
            value /= 1000
            index += 1
        }
        let rounded = value < 100 ? String(format: "%.1f", value) : String(format: "%.0f", value)
        return "\(rounded) \(units[index])"
    }
}
