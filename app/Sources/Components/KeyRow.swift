import SwiftUI

/// A shortcut's description on the left and its keys on the right, one KeyCap each, pushed to opposite edges of the row.
struct KeyRow: View {
    let keys: [String]
    let description: String

    var body: some View {
        HStack(spacing: Space.s16) {
            Text(description)
                .textStyle(.mono12)
                .foregroundStyle(Palette.inkMuted)
            Spacer(minLength: 0)
            HStack(spacing: Space.s4) {
                ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                    KeyCap(key: key)
                }
            }
        }
    }
}
