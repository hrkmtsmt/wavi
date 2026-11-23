import SwiftUI

extension View {
    /// Shows the pointing-hand pointer over anything clickable, and the normal arrow while it is disabled. Wavi's buttons are plain-styled and many sit over the text view, so without this the pointer stays an arrow or turns into the text cursor.
    func clickable() -> some View {
        modifier(Clickable())
    }
}

private struct Clickable: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content.pointerStyle(isEnabled ? .link : nil)
    }
}
