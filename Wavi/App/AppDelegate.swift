import AppKit
import Observation

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = AppSettings()
    private let store = DocumentStore()
    private let defaultApps = DefaultApps()
    private var windowController: DocumentWindowController?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        settings.applyAppearance()
        rebuildMenuOnLanguageChange()
        windowController = DocumentWindowController(store: store, settings: settings, defaultApps: defaultApps)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowController?.showWindow(nil)
        NSApp.activate()
        #if DEBUG
        DebugLaunch.apply(store: store)
        #endif
    }

    /// Files from Finder, the Dock icon and `wv` (Launch Services "open" events).
    func application(_ application: NSApplication, open urls: [URL]) {
        windowController?.showWindow(nil)
        store.open(urls.filter(\.isFileURL))
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { windowController?.showWindow(nil) }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let windowController, windowController.window?.isVisible == true else { return .terminateNow }
        let unsaved = store.documents.filter(\.needsSaveConfirmation)
        return windowController.confirmClosing(unsaved) ? .terminateNow : .terminateCancel
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    private func rebuildMenuOnLanguageChange() {
        withObservationTracking {
            NSApp.mainMenu = MainMenu.make(strings: settings.strings)
        } onChange: { [weak self] in
            Task { @MainActor in self?.rebuildMenuOnLanguageChange() }
        }
    }
}
