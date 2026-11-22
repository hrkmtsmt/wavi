import SwiftUI

/// A rounded glass board (radius 24) that stacks PanelSections. 320pt wide; content that does not fit scrolls inside.
struct Panel<Content: View, Footer: View>: View {
    var title: String?
    var message: String?
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: Space.s24) {
                if title != nil || message != nil {
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
    init(title: String? = nil, message: String? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: title, message: message, content: content, footer: { EmptyView() })
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
