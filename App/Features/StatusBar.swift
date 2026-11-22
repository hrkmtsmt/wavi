import SwiftUI

/// StatusBar = GlassSurface (InfoItem x4 + PillButton "Copy") + RoundButton "?" and gear.
struct StatusBar: View {
    let document: TextDocument
    let store: DocumentStore
    let strings: Strings

    var body: some View {
        HStack(spacing: Space.s8) {
            HStack(spacing: Space.s16) {
                InfoItem(text: document.kindLabel)
                InfoItem(text: ByteFormat.string(document.byteCount), kind: .value)
                InfoItem(text: strings.lines(document.lineCount))
                InfoItem(text: document.encoding.label)
                if document.isReadOnly {
                    InfoItem(text: strings.readOnly)
                }
                PillButton(
                    title: store.isCopied ? strings.copied : strings.copy,
                    systemImage: store.isCopied ? "checkmark" : "doc.on.doc",
                    isDone: store.isCopied
                ) {
                    store.copyAll()
                }
                .disabled(document.text.isEmpty)
            }
            .padding(.leading, Space.s16)
            .padding([.top, .bottom, .trailing], Space.s4)
            .fixedSize()
            .glassSurface(.bar, shape: .capsule)

            RoundButton(
                label: .character("?"),
                isSelected: store.openPanel == .help,
                accessibilityLabel: strings.help
            ) {
                store.toggle(.help)
            }
            RoundButton(
                label: .symbol("gearshape"),
                isSelected: store.openPanel == .settings,
                accessibilityLabel: strings.settings
            ) {
                store.toggle(.settings)
            }
        }
    }
}
