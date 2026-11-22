import AppKit
import SwiftUI

// Design tokens of the Wavi design system, as Swift constants. Only these values may be used for sizes, spacing, radii and type. Exceptions (OS traffic lights, the window's own size) live where they are used.

/// Spacing and size steps: 2 / 4 / 8 / 16 / 24 / 32 / 40 / 48 / 64 / 80.
nonisolated enum Space {
    static let s2: CGFloat = 2
    static let s4: CGFloat = 4
    static let s8: CGFloat = 8
    static let s16: CGFloat = 16
    static let s24: CGFloat = 24
    static let s32: CGFloat = 32
    static let s40: CGFloat = 40
    static let s48: CGFloat = 48
    static let s64: CGFloat = 64
    static let s80: CGFloat = 80
}

/// Corner radii.
nonisolated enum Radius {
    static let r8: CGFloat = 8
    static let r16: CGFloat = 16
    static let r24: CGFloat = 24
}

/// Colors. Light values come from the design system; dark values are provisional (dark mode is not designed yet, see SPEC 7).
enum Palette {
    static let surface = dynamic(light: 0xF6F6F7, dark: 0x1C1C1E)
    static let paper = dynamic(light: 0xFFFFFF, dark: 0x2C2C2E)
    static let ink = dynamic(light: 0x1C1C1E, dark: 0xF2F2F4)
    /// Secondary text. One of only two grays allowed for text.
    static let inkMuted = dynamic(light: 0x55555A, dark: 0xAEAEB2)
    /// Weakest text. One of only two grays allowed for text.
    static let inkSubtle = dynamic(light: 0x6B6B70, dark: 0x8E8E93)
    static let hairline = dynamic(light: 0xE4E4E7, dark: 0x3A3A3C)
    /// Ink glass: black buttons, selected round buttons, chips that are on.
    static let buttonGlass = Color(nsColor: NSColor(hex: 0x161618))
    /// Text on ink glass.
    static let onInk = Color.white

    /// State: copy finished. Only on ink glass.
    static let stateCopied = Color(nsColor: NSColor(hex: 0x86E3A8))
    /// State: a file is being dragged over the window.
    static let stateDrop = dynamic(light: 0x2F6FE0, dark: 0x5B8FF0)
    static let stateDropTint = Color(nsColor: NSColor(srgbRed: 60 / 255, green: 130 / 255, blue: 246 / 255, alpha: 0.10))

    /// Neutral fills used inside components (segmented track, separators, close dot).
    static let fillTrack = dynamicAlpha(light: (0x3C3C43, 0.08), dark: (0xFFFFFF, 0.10))
    static let separator = dynamicAlpha(light: (0x3C3C43, 0.12), dark: (0xFFFFFF, 0.14))
    static let fillClose = dynamicAlpha(light: (0x000000, 0.05), dark: (0xFFFFFF, 0.10))

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(
            nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor(hex: dark) : NSColor(hex: light)
            })
    }

    static func dynamicAlpha(light: (UInt32, CGFloat), dark: (UInt32, CGFloat)) -> Color {
        Color(
            nsColor: NSColor(name: nil) { appearance in
                appearance.isDark
                    ? NSColor(hex: dark.0).withAlphaComponent(dark.1)
                    : NSColor(hex: light.0).withAlphaComponent(light.1)
            })
    }
}

/// Glass density. Four levels only; the system material does the rendering.
enum GlassLevel {
    /// Thinnest: tab track (PillGroup) and the "+" button.
    case track
    /// Medium: status bar and round buttons.
    case bar
    /// Thickest: help and settings panels.
    case panel
    /// Ink glass: black buttons.
    case ink
}

/// Type scale. Sizes 12 / 16 / 20 / 24 only, weights 400 and 700 only.
nonisolated enum TextStyle {
    case mono24
    case mono20
    case mono16
    case mono12

    var size: CGFloat {
        switch self {
        case .mono24: 24
        case .mono20: 20
        case .mono16: 16
        case .mono12: 12
        }
    }

    var lineHeight: CGFloat {
        switch self {
        case .mono24, .mono20: 32
        case .mono16: 24
        case .mono12: 16
        }
    }

    var defaultBold: Bool {
        switch self {
        case .mono24, .mono20: true
        case .mono16, .mono12: false
        }
    }
}

/// The non-glass "raised" shadow (selected item in a PillGroup). Glass surfaces get their depth from the system material instead.
enum RaisedShadow {
    static let color = Color.black.opacity(0.12)
    static let radius: CGFloat = 4
    static let y: CGFloat = 2
}

/// Motion and timing.
nonisolated enum Timing {
    /// How long the "done" state of a PillButton stays.
    static let doneDuration: Duration = .milliseconds(1600)
}

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension NSAppearance {
    var isDark: Bool {
        bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    }
}
