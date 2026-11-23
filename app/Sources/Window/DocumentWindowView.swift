import SwiftUI

/// The only screen. Home, dragging, help and settings are combinations of:
/// whether the current tab is blank, whether a file is dragged over, and the open panel.
struct DocumentWindowView: View {
    let store: DocumentStore
    let settings: AppSettings
    let defaultApps: DefaultApps
    let onCloseTab: (TextDocument) -> Void

    /// Header: 16 top + 40 tab bar. Footer: 40 status bar + 24 bottom. Body keeps 32 from both.
    private let headerHeight = Space.s16 + Space.s40
    private let footerHeight = Space.s40 + Space.s24
    private let bodyGap = Space.s32

    var body: some View {
        let strings = settings.strings
        let document = store.selected
        let isDragging = store.dragPreview != nil

        ZStack(alignment: .topLeading) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: headerHeight + bodyGap)
                .contentShape(Rectangle())
                .gesture(WindowDragGesture())
                .allowsWindowActivationEvents(true)

            VStack(alignment: .leading, spacing: 0) {
                TabBar(store: store, strings: strings, onClose: onCloseTab)
                    .frame(height: Space.s40)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, Space.s16)

                Editor(
                    document: document,
                    openDocumentIDs: Set(store.documents.map(\.id)),
                    showsFullWidthSpace: settings.showsFullWidthSpace,
                    isDragging: isDragging,
                    strings: strings
                )
                .padding(.vertical, bodyGap)
                .frame(maxHeight: .infinity)

                StatusBar(document: document, store: store, strings: strings)
                    .frame(height: Space.s40)
                    .padding(.bottom, Space.s24)
            }
            .padding(.horizontal, Space.s80)

            if let panel = store.openPanel {
                // A click anywhere outside the panel only closes it; nothing underneath reacts. Dragging still moves the window, as the header does when no panel is open.
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .gesture(WindowDragGesture())
                    .onTapGesture { store.closePanel() }
                    .accessibilityHidden(true)

                Group {
                    switch panel {
                    case .help: HelpPanel(strings: strings) { store.closePanel() }
                    case .settings: SettingsPanel(settings: settings, defaultApps: defaultApps) { store.closePanel() }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.leading, Space.s80)
                .padding(.top, headerHeight + bodyGap)
                .padding(.bottom, footerHeight + bodyGap)
                .transition(.opacity)
            }

            DropOverlay(isVisible: isDragging)
        }
        .environment(\.isDragging, isDragging)
        .animation(.easeOut(duration: 0.15), value: isDragging)
        .animation(.easeOut(duration: 0.15), value: store.openPanel)
        .frame(minWidth: 640, minHeight: 400)
        // Measure from the window's edge, not below the (hidden) title bar.
        .ignoresSafeArea()
    }
}
