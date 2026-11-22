import SwiftUI

/// DropOverlay = Overlay over the whole window. The preview Tab is placed by TabBar,
/// and the "release to open" line by the Editor, from the same drag state.
struct DropOverlay: View {
    let isVisible: Bool

    var body: some View {
        if isVisible {
            Overlay()
                .ignoresSafeArea()
                .transition(.opacity)
        }
    }
}
