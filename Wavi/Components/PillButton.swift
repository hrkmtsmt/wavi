import SwiftUI

/// A 32pt ink-glass button: the main "something happens" action on screen.
/// States: normal, done (green content), disabled (35% opacity via `.disabled`).
struct PillButton: View {
    let title: String
    var systemImage: String?
    var isDone = false
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.s8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: TextStyle.mono12.size, weight: .semibold))
                        .frame(width: Space.s16, height: Space.s16)
                }
                Text(title).textStyle(.mono12, bold: true)
            }
            .foregroundStyle(isDone ? Palette.stateCopied : Palette.onInk)
            .padding(.horizontal, Space.s16)
            .frame(height: Space.s32)
            .contentShape(Capsule())
            .glassSurface(.ink, shape: .capsule, interactive: isEnabled)
            .opacity(isEnabled ? 1 : 0.35)
        }
        .buttonStyle(.plain)
    }
}
