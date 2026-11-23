import SwiftUI

/// What the close button at the top right of a Panel does, and what assistive technology calls it. Components carry no text of their own, so the label comes from the feature.
struct PanelClose {
    let accessibilityLabel: String
    let action: () -> Void
}

/// A rounded glass board (radius 24) that stacks PanelSections. 320pt wide; content that does not fit scrolls inside. With `close`, a round × sits at the right end of the title row.
struct Panel<Content: View, Footer: View>: View {
    var title: String?
    var message: String?
    var close: PanelClose?
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: Space.s24) {
                if title != nil || message != nil || close != nil {
                    HStack(alignment: .top, spacing: Space.s16) {
                        VStack(alignment: .leading, spacing: Space.s8) {
                            if let title {
                                Text(title).textStyle(.mono16, bold: true).foregroundStyle(Palette.ink)
                            }
                            if let message {
                                Text(message)
                                    .textStyle(.mono12)
                                    .foregroundStyle(Palette.inkMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if let close {
                            PanelCloseButton(close: close)
                        }
                    }
                }
                content
                if Footer.self != EmptyView.self {
                    VStack(alignment: .leading, spacing: 0) {
                        Rectangle().fill(Palette.separator).frame(height: 1)
                        HStack(spacing: Space.s16) { footer }
                            .textStyle(.mono12)
                            .foregroundStyle(Palette.inkSubtle)
                            .padding(.top, Space.s16)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Space.s24)
        }
        .scrollIndicators(.automatic)
        .frame(width: Space.s80 * 4)
        .glassSurface(.panel, shape: .rounded)
    }
}

extension Panel where Footer == EmptyView {
    init(title: String? = nil, message: String? = nil, close: PanelClose? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: title, message: message, close: close, content: content, footer: { EmptyView() })
    }
}

/// A 24pt round ×, the same height as the panel title and drawn like a tab's close button.
private struct PanelCloseButton: View {
    let close: PanelClose

    var body: some View {
        Button(action: close.action) {
            Image(systemName: "xmark")
                .font(.system(size: Space.s8, weight: .bold))
                .foregroundStyle(Palette.inkMuted)
                .frame(width: Space.s24, height: Space.s24)
                .background(Palette.fillClose, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .clickable()
        .accessibilityLabel(close.accessibilityLabel)
    }
}

/// A small heading (12pt, subtle) followed by 8pt and its content.
struct PanelSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s8) {
            Text(title).textStyle(.mono12).foregroundStyle(Palette.inkSubtle)
            content
        }
    }
}
