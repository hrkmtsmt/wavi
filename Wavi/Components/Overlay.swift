import SwiftUI

/// A color film laid over the whole window, with a 2pt inner line and a glow
/// that thickens toward the edges. Lets mouse events through.
struct Overlay: View {
    var tint: Color = Palette.stateDropTint
    var line: Color = Palette.stateDrop
    var cornerRadius: CGFloat = Radius.r24

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            shape.fill(tint)
            shape
                .stroke(line.opacity(0.16), lineWidth: Space.s64)
                .blur(radius: Space.s32)
            shape.strokeBorder(line.opacity(0.55), lineWidth: Space.s2)
        }
        .clipShape(shape)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
