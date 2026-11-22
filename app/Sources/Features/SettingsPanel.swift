import SwiftUI

/// SettingsPanel = Panel (Chips / Switch / PillGroup x2).
struct SettingsPanel: View {
    @Bindable var settings: AppSettings
    let defaultApps: DefaultApps
    @State private var failed = false

    var body: some View {
        let strings = settings.strings
        Panel(title: strings.settings) {
            PanelSection(title: strings.defaultApp) {
                ChipFlow {
                    ForEach(DefaultApps.extensions, id: \.self) { ext in
                        Chip(title: ".\(ext)", isOn: defaultApps.enabled.contains(ext)) {
                            toggle(ext)
                        }
                    }
                }
                if failed {
                    Text(strings.defaultAppFailed).textStyle(.mono12).foregroundStyle(Palette.inkMuted)
                }
            }
            PanelSection(title: strings.fullWidthSpace) {
                Switch(
                    isOn: $settings.showsFullWidthSpace,
                    label: settings.showsFullWidthSpace ? strings.showFullWidthSpace : strings.hideFullWidthSpace
                )
            }
            PanelSection(title: strings.appearance) {
                PillGroup(style: .flat) {
                    item(strings.light, .light)
                    item(strings.dark, .dark)
                    item(strings.automatic, .automatic)
                }
            }
            PanelSection(title: strings.languageTitle) {
                PillGroup(style: .flat) {
                    PillGroupItem(title: "日本語", isSelected: settings.language == .japanese) {
                        settings.language = .japanese
                    }
                    PillGroupItem(title: "English", isSelected: settings.language == .english) {
                        settings.language = .english
                    }
                }
            }
        }
        .onAppear { defaultApps.refresh() }
    }

    private func item(_ title: String, _ mode: AppearanceMode) -> some View {
        PillGroupItem(title: title, isSelected: settings.appearance == mode) {
            settings.appearance = mode
        }
    }

    private func toggle(_ ext: String) {
        failed = false
        Task {
            do {
                try await defaultApps.toggle(ext)
            } catch {
                defaultApps.refresh()
                // Cancelling the system confirmation is not a failure worth showing.
                failed = (error as NSError).code != NSUserCancelledError
            }
        }
    }
}
