import SwiftUI

/// One piece of information in a status bar.
struct InfoItem: View {
    enum Kind {
        /// 12pt, muted.
        case label
        /// 16pt bold, ink. One step larger so it reads at a glance.
        case value
    }

    let text: String
    var kind: Kind = .label

    var body: some View {
        switch kind {
        case .label:
            Text(text).textStyle(.mono12).foregroundStyle(Palette.inkMuted)
        case .value:
            Text(text).textStyle(.mono16, bold: true).foregroundStyle(Palette.ink)
        }
    }
}
