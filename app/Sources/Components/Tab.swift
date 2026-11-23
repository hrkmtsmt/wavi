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
        Group {
            if case .preview(let detail) = kind {
                preview(detail: detail)
            } else {
                TabItem(
                    title: title,
                    isSelected: isSelected,
                    isPlaceholder: isPlaceholder,
                    closeAccessibilityLabel: closeAccessibilityLabel,
                    onClose: onClose,
                    action: action,
                    closeFraction: onClose == nil ? 0 : 1
                )
            }
        }
        .pillGroupGap()
    }

    private var isSelected: Bool {
        if case .selected = kind { true } else { false }
    }

    private var onClose: (() -> Void)? {
        if case .selected(let onClose) = kind { onClose } else { nil }
    }

    private func preview(detail: String) -> some View {
        HStack(spacing: Space.s8) {
            TabTitle(title: title, bold: false, color: Palette.ink)
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

/// A selected or idle tab. Both share one layout, so the name stays put and only its weight and color change when the selection moves.
private struct TabItem: View, Animatable {
    let title: String
    let isSelected: Bool
    let isPlaceholder: Bool
    let closeAccessibilityLabel: String
    let onClose: (() -> Void)?
    let action: () -> Void
    /// 1 while the close button shows, 0 while it doesn't. Animated, so the tab's width eases with the rest of the bar instead of jumping by the button's width.
    var closeFraction: CGFloat

    var animatableData: CGFloat {
        get { closeFraction }
        set { closeFraction = newValue }
    }

    var body: some View {
        HStack(spacing: 0) {
            Button(action: action) {
                TabTitle(title: title, bold: isSelected, color: isSelected && !isPlaceholder ? Palette.ink : Palette.inkMuted)
                    .padding(.leading, Space.s16)
                    .padding(.trailing, Space.s16 * (1 - closeFraction))
                    .frame(height: Space.s32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .clickable()
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            // Always in the layout: 8 + 16pt button + 8 when shown, nothing when hidden.
            Button {
                onClose?()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: Space.s8, weight: .bold))
                    .foregroundStyle(Palette.inkSubtle)
                    .frame(width: Space.s16, height: Space.s16)
                    .background(Palette.fillClose, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .clickable()
            .padding(.horizontal, Space.s8)
            .frame(width: Space.s32 * closeFraction, alignment: .leading)
            .clipped()
            .opacity(closeFraction)
            .allowsHitTesting(onClose != nil)
            .accessibilityLabel(closeAccessibilityLabel)
            .accessibilityHidden(onClose == nil)
        }
        .raised(isSelected)
        .accessibilityElement(children: .contain)
    }
}

/// A tab's name at 12pt, on one line.
private struct TabTitle: View {
    let title: String
    let bold: Bool
    let color: Color

    var body: some View {
        Text(title)
            .textStyle(.mono12, bold: bold)
            .foregroundStyle(color)
            .lineLimit(1)
            .truncationMode(.middle)
            // Swap the weight at once: morphing between regular and bold glyphs smears the name while the tab moves.
            .contentTransition(.identity)
    }
}
