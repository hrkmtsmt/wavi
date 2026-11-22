import SwiftUI

/// One piece of information in a status bar.
struct InfoItem: View {
    enum Kind {
        /// 12pt, muted.
        case label
        /// 12pt bold, ink. Same size as labels; weight and color set it apart.
        case value
    }

    let text: String
    var kind: Kind = .label

    var body: some View {
        switch kind {
        case .label:
            Text(text).textStyle(.mono12).foregroundStyle(Palette.inkMuted)
        case .value:
            Text(text).textStyle(.mono12, bold: true).foregroundStyle(Palette.ink)
        }
    }
}
