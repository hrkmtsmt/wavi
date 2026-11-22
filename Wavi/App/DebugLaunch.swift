#if DEBUG
    import Foundation

    /// Debug-only launch arguments to put the window into a given state,
    /// used to compare the app with the adopted design:
    ///   -WaviDebugPanel help|settings
    ///   -WaviDebugDrag /path/to/file   (shows the drag state for that file)
    ///   -WaviDebugSelect <index>       (selects a tab after files have opened)
    ///   -WaviDebugCopied YES           (shows the "copied" state of the copy button)
    enum DebugLaunch {
        static func apply(store: DocumentStore) {
            let defaults = UserDefaults.standard
            switch defaults.string(forKey: "WaviDebugPanel") {
            case "help": store.openPanel = .help
            case "settings": store.openPanel = .settings
            default: break
            }
            // Wait for files opened at launch before touching tabs.
            Task {
                try? await Task.sleep(for: .seconds(2))
                if let index = defaults.object(forKey: "WaviDebugSelect") as? Int ?? Int(defaults.string(forKey: "WaviDebugSelect") ?? ""),
                    store.documents.indices.contains(index)
                {
                    store.select(store.documents[index])
                }
                if let path = defaults.string(forKey: "WaviDebugDrag") {
                    store.beginDrag([URL(fileURLWithPath: path)])
                }
                if defaults.bool(forKey: "WaviDebugCopied") {
                    store.copyAll()
                }
            }
        }
    }
#endif
