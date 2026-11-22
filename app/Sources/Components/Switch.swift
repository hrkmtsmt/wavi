import SwiftUI

/// An on/off choice with the current state written in words to its right. The system switch is used as-is; only its color is set to `ink`.
struct Switch: View {
    @Binding var isOn: Bool
    let label: String

    var body: some View {
        HStack(spacing: Space.s8) {
            Toggle(label, isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(Palette.ink)
            Text(label)
                .textStyle(.mono12)
                .foregroundStyle(Palette.ink)
                .onTapGesture { isOn.toggle() }
        }
    }
}
