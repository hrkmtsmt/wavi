import SwiftUI

/// A PillGroup item shaped for a tab bar. Shows a name at 12pt.
struct Tab: View {
    enum Kind {
        /// Selected: raised, bold, with a close button when `onClose` is set.
        case selected(onClose: (() -> Void)?)
        /// Not selected: no background, muted text.
        case idle
        /// Preview of where a dragged item will open: dashed outline, bar glass, name plus a bold detail (for example a size).
        case preview(detail: String)
    }

    let title: String
    let kind: Kind
    /// Shows the title in the muted color even when selected (an empty placeholder tab).
    var isPlaceholder = false
    var closeAccessibilityLabel = ""
    var action: () -> Void = {}

    var body: some View {
        switch kind {
        case .selected(let onClose):
            selected(onClose: onClose)
        case .idle:
            Button(action: action) {
                label(bold: false, color: Palette.inkMuted)
                    .padding(.horizontal, Space.s16)
                    .frame(height: Space.s32)
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        case .preview(let detail):
            preview(detail: detail)
        }
    }

    private func label(bold: Bool, color: Color) -> some View {
        Text(title)
            .textStyle(.mono12, bold: bold)
            .foregroundStyle(color)
            .lineLimit(1)
            .truncationMode(.middle)
    }

    private func selected(onClose: (() -> Void)?) -> some View {
        HStack(spacing: Space.s8) {
            label(bold: true, color: isPlaceholder ? Palette.inkMuted : Palette.ink)
            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: Space.s8, weight: .bold))
                        .foregroundStyle(Palette.inkSubtle)
                        .frame(width: Space.s16, height: Space.s16)
                        .background(Palette.fillClose, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(closeAccessibilityLabel)
            }
        }
        .padding(.leading, Space.s16)
        .padding(.trailing, onClose == nil ? Space.s16 : Space.s8)
        .frame(height: Space.s32)
        .background { RaisedBackground() }
        .contentShape(Capsule())
        .onTapGesture(perform: action)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isSelected)
    }

    private func preview(detail: String) -> some View {
        HStack(spacing: Space.s8) {
            label(bold: false, color: Palette.ink)
            Text(detail).textStyle(.mono12, bold: true).foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, Space.s16)
        .frame(height: Space.s32)
        .glassSurface(.bar, shape: .capsule)
        .overlay {
            Capsule()
                .strokeBorder(Palette.stateDrop.opacity(0.65), style: StrokeStyle(lineWidth: Space.s2, dash: [Space.s4, Space.s4]))
        }
    }
}
