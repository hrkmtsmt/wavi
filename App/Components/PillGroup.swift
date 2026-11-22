import SwiftUI

/// A capsule container whose single selected item floats up in white. The tab bar and the appearance / language switches are this same component.
struct PillGroup<Content: View>: View {
    var style: PillGroupStyle = .glass
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: Space.s4) {
            content
        }
        .padding(Space.s4)
        .modifier(PillGroupTrack(style: style))
    }
}

enum PillGroupStyle {
    /// Glass track (tab bar).
    case glass
    /// Flat light-gray track (switches inside a panel).
    case flat
}

private struct PillGroupTrack: ViewModifier {
    let style: PillGroupStyle

    @ViewBuilder
    func body(content: Content) -> some View {
        switch style {
        case .glass:
            content.glassSurface(.track, shape: .capsule)
        case .flat:
            content.background(Palette.fillTrack, in: Capsule())
        }
    }
}

/// A plain text item of a PillGroup.
struct PillGroupItem: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .textStyle(.mono12, bold: isSelected)
                .foregroundStyle(isSelected ? Palette.ink : Palette.inkMuted)
                .padding(.horizontal, Space.s16)
                .frame(height: Space.s32)
                .background { RaisedBackground(isVisible: isSelected) }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// The white "raised" pill behind the selected item of a PillGroup.
struct RaisedBackground: View {
    var isVisible = true

    var body: some View {
        if isVisible {
            Capsule()
                .fill(Palette.paper)
                .shadow(color: RaisedShadow.color, radius: RaisedShadow.radius, y: RaisedShadow.y)
        }
    }
}
