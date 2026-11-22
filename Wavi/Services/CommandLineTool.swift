import AppKit

/// Installs the `wv` command: a symbolic link in /usr/local/bin pointing at
/// the script bundled in the app. Asks for an administrator password only
/// when /usr/local/bin is not writable.
enum CommandLineTool {
    static let installURL = URL(fileURLWithPath: "/usr/local/bin/wv")

    static var bundledScriptURL: URL? {
        Bundle.main.url(forResource: "wv", withExtension: nil)
    }

    static var isInstalled: Bool {
        FileManager.default.isExecutableFile(atPath: installURL.path)
    }

    static func install() async -> Bool {
        guard let script = bundledScriptURL else { return false }
        if installWithoutPrivileges(script: script) { return true }
        return await installWithPrivileges(script: script)
    }

    private static func installWithoutPrivileges(script: URL) -> Bool {
        let manager = FileManager.default
        let directory = installURL.deletingLastPathComponent()
        do {
            if !manager.fileExists(atPath: directory.path) {
                try manager.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            if (try? installURL.checkResourceIsReachable()) == true || manager.destinationOfSymbolicLinkExists(installURL) {
                try manager.removeItem(at: installURL)
            }
            try manager.createSymbolicLink(at: installURL, withDestinationURL: script)
            return true
        } catch {
            return false
        }
    }

    private static func installWithPrivileges(script: URL) async -> Bool {
        let directory = installURL.deletingLastPathComponent().path
        let command = "mkdir -p \(shellQuoted(directory)) && ln -sf \(shellQuoted(script.path)) \(shellQuoted(installURL.path))"
        let source = "do shell script \(appleScriptQuoted(command)) with administrator privileges"
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
        return error == nil && isInstalled
    }

    private static func shellQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func appleScriptQuoted(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }
}

private extension FileManager {
    /// True when `url` is a symbolic link, even a dangling one.
    func destinationOfSymbolicLinkExists(_ url: URL) -> Bool {
        (try? destinationOfSymbolicLink(atPath: url.path)) != nil
    }
}
