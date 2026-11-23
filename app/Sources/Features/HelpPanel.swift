import SwiftUI

/// HelpPanel = Panel (message / KeyRow x6 / command + PillButton / footer).
struct HelpPanel: View {
    let strings: Strings
    let onClose: () -> Void
    @State private var isCommandInstalled = CommandLineTool.isInstalled
    @State private var isInstalling = false
    @State private var failed = false

    var body: some View {
        Panel(
            title: strings.helpTitle, message: strings.helpMessage,
            close: PanelClose(accessibilityLabel: strings.closePanel, action: onClose)
        ) {
            PanelSection(title: strings.shortcuts) {
                KeyRow(keys: ["⌘", "O"], description: strings.open)
                KeyRow(keys: ["⌘", "N"], description: strings.new)
                KeyRow(keys: ["⌘", "V"], description: strings.paste)
                KeyRow(keys: ["⌘", "⇧", "C"], description: strings.copyAll)
                KeyRow(keys: ["⌘", "W"], description: strings.closeTab)
                KeyRow(keys: ["⌘", ","], description: strings.settings)
            }
            PanelSection(title: strings.terminal) {
                Text("\(Text("$ wv").bold().foregroundStyle(Palette.ink)) ./file.txt")
                    .foregroundStyle(Palette.inkMuted)
                    .textStyle(.mono12)
                if isCommandInstalled {
                    Text(strings.commandInstalled).textStyle(.mono12).foregroundStyle(Palette.ink)
                } else {
                    PillButton(title: strings.installCommand) { install() }
                        .disabled(isInstalling)
                    if failed {
                        Text(strings.installFailed).textStyle(.mono12).foregroundStyle(Palette.inkMuted)
                    }
                }
            }
        } footer: {
            Text("Wavi \(AppInfo.version)")
            if let site = AppInfo.siteURL {
                Link(strings.site, destination: site).foregroundStyle(Palette.inkSubtle).clickable()
            } else {
                Text(strings.site)
            }
        }
        .onAppear { isCommandInstalled = CommandLineTool.isInstalled }
    }

    private func install() {
        isInstalling = true
        failed = false
        Task {
            let ok = await CommandLineTool.install()
            isInstalling = false
            isCommandInstalled = ok
            failed = !ok
        }
    }
}
