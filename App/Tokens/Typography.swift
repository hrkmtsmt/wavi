import AppKit
import SwiftUI

/// The bundled "mono" family: JetBrains Mono for Latin, falling back to
/// Gen Jyuu Gothic Monospace for kana, kanji and full-width symbols through
/// the font descriptor's cascade list. Emoji fall through to Apple Color Emoji.
enum WaviFont {
    private static let latinRegular = "JetBrainsMono-Regular"
    private static let latinBold = "JetBrainsMono-Bold"
    private static let japaneseRegular = "GenJyuuGothic-Monospace-Regular"
    private static let japaneseBold = "GenJyuuGothic-Monospace-Bold"

    static func nsFont(_ style: TextStyle, bold: Bool? = nil) -> NSFont {
        nsFont(size: style.size, bold: bold ?? style.defaultBold)
    }

    static func nsFont(size: CGFloat, bold: Bool) -> NSFont {
        let latin = bold ? latinBold : latinRegular
        let japanese = bold ? japaneseBold : japaneseRegular
        let fallback = NSFontDescriptor(fontAttributes: [.name: japanese])
        let descriptor = NSFontDescriptor(fontAttributes: [.name: latin])
            .addingAttributes([.cascadeList: [fallback]])
        return NSFont(descriptor: descriptor, size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: bold ? .bold : .regular)
    }

    static func font(_ style: TextStyle, bold: Bool? = nil) -> Font {
        Font(nsFont(style, bold: bold) as CTFont)
    }
}

private struct TextStyleModifier: ViewModifier {
    let style: TextStyle
    let bold: Bool?

    func body(content: Content) -> some View {
        let font = WaviFont.nsFont(style, bold: bold)
        let natural = font.ascender - font.descender + font.leading
        content
            .font(Font(font as CTFont))
            .lineSpacing(max(0, style.lineHeight - natural))
            .frame(minHeight: style.lineHeight)
    }
}

extension View {
    /// Applies a type-scale style: font, size and line height.
    func textStyle(_ style: TextStyle, bold: Bool? = nil) -> some View {
        modifier(TextStyleModifier(style: style, bold: bold))
    }
}
