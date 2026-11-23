import SwiftUI

/// One keyboard key drawn as a cap: at least 24pt square, radius 8, filled with the neutral track fill and no border. A shortcut is a row of caps, one per key.
struct KeyCap: View {
    let key: String

    var body: some View {
        Text(key)
            .textStyle(.mono12)
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, Space.s4)
            .frame(minWidth: Space.s24, minHeight: Space.s24)
            .background(Palette.fillTrack, in: RoundedRectangle(cornerRadius: Radius.r8, style: .continuous))
    }
}
