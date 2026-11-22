import SwiftUI

/// Shape of a glass surface.
enum GlassShape {
    /// Pill shape (`radius-full`).
    case capsule
    /// Rounded rectangle (`radius-24`). Panels and the window only.
    case rounded

    var shape: AnyShape {
        switch self {
        case .capsule: AnyShape(Capsule())
        case .rounded: AnyShape(RoundedRectangle(cornerRadius: Radius.r24, style: .continuous))
        }
    }
}

/// The base of every glass face in Wavi: a shape times a density.
/// Other components never draw glass themselves; they go through this.
///
/// Uses the system Liquid Glass (`glassEffect`). Density differences are
/// approximated with tint only; mockup opacities are not copied.
struct GlassSurface: ViewModifier {
    let level: GlassLevel
    let shape: GlassShape
    var isInteractive = false

    func body(content: Content) -> some View {
        content.glassEffect(glass, in: shape.shape)
    }

    private var glass: Glass {
        let base: Glass
        switch level {
        case .track: base = .regular
        case .bar: base = .regular.tint(Palette.paper.opacity(0.32))
        case .panel: base = .regular.tint(Palette.paper.opacity(0.56))
        case .ink: base = .regular.tint(Palette.buttonGlass)
        }
        return base.interactive(isInteractive)
    }
}

extension View {
    func glassSurface(_ level: GlassLevel, shape: GlassShape = .capsule, interactive: Bool = false) -> some View {
        modifier(GlassSurface(level: level, shape: shape, isInteractive: interactive))
    }
}
