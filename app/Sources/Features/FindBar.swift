import SwiftUI

/// FindBar = GlassSurface (magnifier + field + InfoItem count) + RoundButton ▲ ▼, floating in the middle of the window.
/// Return goes to the next match and Shift-Return to the previous one (handled by the window), Esc closes it.
struct FindBar: View {
    @Bindable var find: FindState
    let document: TextDocument
    let strings: Strings
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Space.s8) {
            HStack(spacing: Space.s8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: TextStyle.mono12.size, weight: .bold))
                    .frame(width: Space.s16, height: Space.s16)
                    .foregroundStyle(Palette.inkMuted)
                    .accessibilityHidden(true)
                TextField(strings.findPlaceholder, text: $find.query)
                    .textFieldStyle(.plain)
                    .textStyle(.mono16)
                    .foregroundStyle(Palette.ink)
                    .focused($isFocused)
                if !find.query.isEmpty {
                    InfoItem(text: countText)
                }
            }
            .padding(.horizontal, Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)

            RoundButton(label: .symbol("chevron.up"), level: .track, accessibilityLabel: strings.findPrevious) {
                find.previous()
            }
            .disabled(find.matches.isEmpty)
            RoundButton(label: .symbol("chevron.down"), level: .track, accessibilityLabel: strings.findNext) {
                find.next()
            }
            .disabled(find.matches.isEmpty)
        }
        .padding(Space.s4)
        .frame(width: Space.s80 * 6)
        .glassSurface(.bar, shape: .capsule)
        .onAppear { focusField() }
        .onChange(of: find.focusRequest) { focusField() }
        .onChange(of: find.query) { find.search(in: document.text) }
        .onChange(of: document.text) { find.refresh(in: document.text) }
        .onChange(of: document.id) { find.search(in: document.text, from: document.cursorLocation) }
    }

    /// On the next turn of the run loop, once the bar is in the window and the text view has let go of the keyboard.
    private func focusField() {
        DispatchQueue.main.async { isFocused = true }
    }

    private var countText: String {
        guard let current = find.current else { return strings.noMatches }
        return "\(current + 1) / \(find.matches.count)\(find.isTruncated ? "+" : "")"
    }
}
