import SwiftUI

/// TabBar = PillGroup of Tabs + RoundButton "+".
/// While a file is dragged over the window, a preview Tab shows where it will open.
struct TabBar: View {
    let store: DocumentStore
    let strings: Strings
    let onClose: (TextDocument) -> Void

    var body: some View {
        HStack(spacing: Space.s8) {
            PillGroup(style: .glass) {
                ForEach(store.documents) { document in
                    if let preview = store.dragPreview, preview.replacesSelection, document.id == store.selectedID {
                        Tab(title: preview.name, kind: .preview(detail: preview.size))
                    } else {
                        tab(for: document)
                    }
                }
                if let preview = store.dragPreview, !preview.replacesSelection {
                    Tab(title: preview.name, kind: .preview(detail: preview.size))
                }
            }
            .accessibilityLabel(strings.openTabs)

            RoundButton(label: .symbol("plus"), level: .track, accessibilityLabel: strings.newTab) {
                store.newTab()
            }
        }
    }

    @ViewBuilder private func tab(for document: TextDocument) -> some View {
        let title = document.title(strings)
        if document.id == store.selectedID {
            Tab(
                title: title,
                kind: .selected(onClose: document.isBlank && store.documents.count == 1 ? nil : { onClose(document) }),
                isPlaceholder: document.isBlank,
                closeAccessibilityLabel: strings.closeTab
            )
            .layoutPriority(1)
        } else {
            Tab(title: title, kind: .idle) { store.select(document) }
        }
    }
}
