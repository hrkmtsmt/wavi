import AppKit
import Observation

enum AppearanceMode: String, CaseIterable {
    case light
    case dark
    case automatic

    var nsAppearance: NSAppearance? {
        switch self {
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        case .automatic: nil
        }
    }
}

/// User preferences, persisted in UserDefaults.
@Observable
final class AppSettings {
    private enum Key {
        static let showsFullWidthSpace = "showsFullWidthSpace"
        static let appearance = "appearance"
        static let language = "language"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var showsFullWidthSpace: Bool {
        didSet { defaults.set(showsFullWidthSpace, forKey: Key.showsFullWidthSpace) }
    }

    var appearance: AppearanceMode {
        didSet {
            defaults.set(appearance.rawValue, forKey: Key.appearance)
            applyAppearance()
        }
    }

    var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Key.language) }
    }

    var strings: Strings { Strings(language: language) }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showsFullWidthSpace = defaults.object(forKey: Key.showsFullWidthSpace) as? Bool ?? true
        appearance = defaults.string(forKey: Key.appearance).flatMap(AppearanceMode.init(rawValue:)) ?? .automatic
        language = defaults.string(forKey: Key.language).flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    func applyAppearance() {
        NSApp.appearance = appearance.nsAppearance
    }
}
