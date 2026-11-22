import SwiftUI

/// A key (bold) on the left and its description on the right. The key column is at least 48pt so descriptions line up.
struct KeyRow: View {
    let key: String
    let description: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.s16) {
            Text(key)
                .textStyle(.mono12, bold: true)
                .foregroundStyle(Palette.ink)
                .frame(minWidth: Space.s48, alignment: .leading)
            Text(description)
                .textStyle(.mono12)
                .foregroundStyle(Palette.inkMuted)
        }
    }
}
