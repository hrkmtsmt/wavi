import SwiftUI

/// TabBar = PillGroup of Tabs + RoundButton "+". While a file is dragged over the window, a preview Tab shows where it will open.
struct TabBar: View {
    let store: DocumentStore
    let strings: Strings
    let onClose: (TextDocument) -> Void

    var body: some View {
        HStack(spacing: Space.s8) {
            PillGroup(style: .glass) {
                ForEach(store.documents) { document in
                    Group {
                        if let preview = store.dragPreview, preview.replacesSelection, document.id == store.selectedID {
                            Tab(title: preview.name, kind: .preview(detail: preview.size))
                        } else {
                            tab(for: document)
                        }
                    }
                    // The selected tab keeps its full name when the bar runs out of room.
                    .transition(.pillGroupGrow(priority: document.id == store.selectedID ? 1 : 0))
                }
                if let preview = store.dragPreview, !preview.replacesSelection {
                    Tab(title: preview.name, kind: .preview(detail: preview.size))
                        .transition(.pillGroupGrow())
                }
            }
            .accessibilityLabel(strings.openTabs)

            RoundButton(label: .symbol("plus"), level: .track, accessibilityLabel: strings.newTab) {
                store.newTab()
            }
        }
        // Tabs change from many places (menu, keyboard, open queue, drag), so animate here rather than at each call.
        .animation(Timing.tabBar, value: AnimationKey(store: store))
    }

    /// What the tab bar animates on: tabs coming and going, the selection moving, and the drag preview.
    private struct AnimationKey: Equatable {
        let ids: [TextDocument.ID]
        let selectedID: TextDocument.ID
        let preview: DragPreview?

        init(store: DocumentStore) {
            ids = store.documents.map(\.id)
            selectedID = store.selectedID
            preview = store.dragPreview
        }
    }

    /// One Tab whether selected or not, so a selection change restyles the same view instead of swapping it for another.
    private func tab(for document: TextDocument) -> some View {
        let isSelected = document.id == store.selectedID
        let canClose = !(document.isBlank && store.documents.count == 1)
        return Tab(
            title: document.title(strings),
            kind: isSelected ? .selected(onClose: canClose ? { onClose(document) } : nil) : .idle,
            isPlaceholder: document.isBlank,
            closeAccessibilityLabel: strings.closeTab
        ) {
            store.select(document)
        }
    }
}
