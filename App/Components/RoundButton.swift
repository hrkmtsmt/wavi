import SwiftUI

/// A 40pt round glass button holding a 16pt icon or a single bold character.
struct RoundButton: View {
    enum Label {
        case symbol(String)
        case character(String)
    }

    let label: Label
    /// Glass density when not selected: `.track` or `.bar`.
    var level: GlassLevel = .bar
    /// Selected (its panel is open): ink glass with white content.
    var isSelected = false
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            content
                .foregroundStyle(isSelected ? Palette.onInk : Palette.ink)
                .frame(width: Space.s40, height: Space.s40)
                .contentShape(Circle())
                .glassSurface(isSelected ? .ink : level, shape: .capsule, interactive: true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder private var content: some View {
        switch label {
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: TextStyle.mono12.size, weight: .bold))
                .frame(width: Space.s16, height: Space.s16)
        case .character(let text):
            Text(text).textStyle(.mono16, bold: true)
        }
    }
}
