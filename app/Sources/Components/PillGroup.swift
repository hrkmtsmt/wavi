import SwiftUI

/// A capsule container whose single selected item floats up in white. The tab bar and the appearance / language switches are this same component.
struct PillGroup<Content: View>: View {
    var style: PillGroupStyle = .glass
    @ViewBuilder let content: Content

    var body: some View {
        // No spacing here: each item brings the 4pt gap before it (`pillGroupGap`), so an item growing in or shrinking away takes its gap along instead of the gap appearing at once.
        HStack(spacing: 0) {
            content
        }
        // One raised pill for the whole group, drawn behind the item marked `raised`, so a selection change slides it across instead of swapping it.
        .backgroundPreferenceValue(RaisedAnchorKey.self) { raised in
            GeometryReader { proxy in
                if let frame = raised.map({ $0.frame(in: proxy) }), !frame.isNull {
                    RaisedBackground()
                        .frame(width: frame.width, height: frame.height)
                        .offset(x: frame.minX, y: frame.minY)
                }
            }
        }
        .padding(.vertical, Space.s4)
        .padding(.trailing, Space.s4)
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
                .contentTransition(.identity)
                .padding(.horizontal, Space.s16)
                .frame(height: Space.s32)
                .raised(isSelected)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .pillGroupGap()
    }
}

extension View {
    /// Puts the PillGroup's white "raised" pill behind this item.
    func raised(_ isRaised: Bool) -> some View {
        anchorPreference(key: RaisedAnchorKey.self, value: .bounds) { isRaised ? RaisedAnchor(item: $0) : nil }
    }

    /// The 4pt gap before a PillGroup item. Every item of a PillGroup applies it once, outermost.
    func pillGroupGap() -> some View {
        padding(.leading, Space.s4)
    }
}

/// The white "raised" pill behind the selected item of a PillGroup.
private struct RaisedBackground: View {
    var body: some View {
        Capsule()
            .fill(Palette.paper)
            .shadow(color: RaisedShadow.color, radius: RaisedShadow.radius, y: RaisedShadow.y)
    }
}

/// Where the raised item of a PillGroup is, cut to the part of it that is showing.
private struct RaisedAnchor {
    var item: Anchor<CGRect>
    /// While the item grows in, only this much of it shows.
    var clip: Anchor<CGRect>?

    func frame(in proxy: GeometryProxy) -> CGRect {
        let frame = proxy[item]
        guard let clip else { return frame }
        return frame.intersection(proxy[clip])
    }
}

/// The raised item of a PillGroup. Only one item is raised at a time.
private struct RaisedAnchorKey: PreferenceKey {
    static let defaultValue: RaisedAnchor? = nil

    static func reduce(value: inout RaisedAnchor?, nextValue: () -> RaisedAnchor?) {
        value = value ?? nextValue()
    }
}

extension AnyTransition {
    /// A PillGroup item growing in from zero width and shrinking back to it, so its neighbours slide instead of jumping. `priority` is the item's layout priority, which has to sit outside the transition to reach the group.
    static func pillGroupGrow(priority: Double = 0) -> AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: PillGroupGrow(progress: 0, priority: priority, isRemoval: false),
                identity: PillGroupGrow(progress: 1, priority: priority, isRemoval: false)
            ),
            removal: .modifier(
                active: PillGroupGrow(progress: 0, priority: priority, isRemoval: true),
                identity: PillGroupGrow(progress: 1, priority: priority, isRemoval: true)
            )
        )
    }
}

/// Reveals its content from the leading edge. The content is always laid out at its full width, so text never wraps or squeezes mid-animation. Animatable, so the body sees every step of `progress`.
///
/// An arriving item grows its layout width, which pushes its neighbours along. A leaving item is already out of the group's layout (its neighbours slide on their own) and keeps its center, so it keeps its width and only its mask shrinks toward the leading edge.
private struct PillGroupGrow: ViewModifier, Animatable {
    var progress: CGFloat
    let priority: Double
    let isRemoval: Bool

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        // The same structure at rest, arriving and leaving: swapping views mid-transition breaks the animation.
        RevealLayout(progress: isRemoval ? 1 : progress) { content }
            .opacity(progress)
            .mask {
                Rectangle()
                    .scaleEffect(x: isRemoval ? progress : 1, anchor: .leading)
                    .padding(.vertical, -Space.s8)
            }
            // A raised pill covers only the revealed part, not the full-width content; a leaving item hands it over to the new selection.
            .transformAnchorPreference(key: RaisedAnchorKey.self, value: .bounds) { raised, bounds in
                guard raised != nil else { return }
                if isRemoval && progress < 1 {
                    raised = nil
                } else {
                    raised?.clip = bounds
                }
            }
            .layoutPriority(priority)
    }
}

/// Takes `progress` of its single subview's width and lays the subview out at its full width from the leading edge.
private struct RevealLayout: Layout {
    let progress: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let subview = subviews.first else { return .zero }
        let size = subview.sizeThatFits(fullProposal(proposal))
        return CGSize(width: size.width * progress, height: size.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let subview = subviews.first else { return }
        let size = subview.sizeThatFits(fullProposal(proposal))
        subview.place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(size))
    }

    /// The parent proposes the revealed width back to us; scale it up again so the subview is measured at full width and its text doesn't truncate mid-animation.
    private func fullProposal(_ proposal: ProposedViewSize) -> ProposedViewSize {
        guard progress < 1 else { return proposal }
        return ProposedViewSize(width: progress > 0 ? proposal.width.map { $0 / progress } : nil, height: proposal.height)
    }
}
