import Foundation

enum AppInfo {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    /// The project website. Not decided yet (SPEC 7); the link stays inert until set.
    static let siteURL: URL? = nil
}
