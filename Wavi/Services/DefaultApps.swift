import AppKit
import Observation
import UniformTypeIdentifiers

/// Which file types open with Wavi by default (Launch Services).
@Observable
final class DefaultApps {
    /// The extensions offered in the settings panel.
    static let extensions = ["txt", "log", "json", "md", "csv", "yaml"]

    private(set) var enabled: Set<String> = []

    func refresh() {
        let bundleURL = Bundle.main.bundleURL.standardizedFileURL
        enabled = Set(Self.extensions.filter { ext in
            guard let type = UTType(filenameExtension: ext),
                  let app = NSWorkspace.shared.urlForApplication(toOpen: type) else { return false }
            return app.standardizedFileURL == bundleURL
        })
    }

    /// Turning on makes Wavi the default (macOS shows its own confirmation).
    /// Turning off hands the type to the next app macOS would choose.
    func toggle(_ ext: String) async throws {
        guard let type = UTType(filenameExtension: ext) else { return }
        let workspace = NSWorkspace.shared
        let bundleURL = Bundle.main.bundleURL.standardizedFileURL
        if enabled.contains(ext) {
            let other = workspace.urlsForApplications(toOpen: type)
                .first { $0.standardizedFileURL != bundleURL }
            if let other {
                try await workspace.setDefaultApplication(at: other, toOpen: type)
            }
        } else {
            try await workspace.setDefaultApplication(at: bundleURL, toOpen: type)
        }
        refresh()
    }
}
