import Foundation

/// UI language. Switchable at runtime from the settings panel.
enum AppLanguage: String, CaseIterable, Sendable {
    case japanese = "ja"
    case english = "en"

    static var system: AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("ja") ? .japanese : .english
    }
}

/// All user-facing copy. Wavi-specific text lives here, never inside generic components.
struct Strings {
    let language: AppLanguage

    private func t(_ ja: String, _ en: String) -> String {
        language == .japanese ? ja : en
    }

    // Tabs and editor
    var untitled: String { t("名称未設定", "Untitled") }
    var placeholder: String { t("ファイルをドロップ、またはテキストを貼り付け", "Drop a file, or paste some text") }
    var releaseToOpen: String { t("離すと開きます", "Release to open") }
    var newTab: String { t("新しいタブ", "New Tab") }
    var closeTab: String { t("タブを閉じる", "Close Tab") }
    var closePanel: String { t("閉じる", "Close") }
    var openTabs: String { t("開いているファイル", "Open files") }
    var body: String { t("本文", "Text") }

    // Status bar
    func lines(_ count: Int) -> String { t("\(count) 行", count == 1 ? "1 line" : "\(count) lines") }
    var copy: String { t("コピー", "Copy") }
    /// Same length as `copy` in each language, so the copy button keeps its width and its icon stays put.
    var copied: String { t("できた", "Done") }
    var readOnly: String { t("読み取り専用", "Read-only") }
    var help: String { t("使い方とショートカット", "Help and shortcuts") }
    var settings: String { t("設定", "Settings") }

    // Help panel
    var helpTitle: String { t("Wavi の使い方", "How to use Wavi") }
    var helpMessage: String {
        t(
            "ファイルをドロップするか、⌘V で貼り付ける。開いた瞬間に、サイズと中身がわかります。",
            "Drop a file or paste with ⌘V. The moment it opens, you see its size and contents.")
    }
    var shortcuts: String { t("ショートカット", "Shortcuts") }
    var open: String { t("開く", "Open") }
    var new: String { t("新規", "New") }
    var paste: String { t("貼り付け", "Paste") }
    var copyAll: String { t("全部コピー", "Copy all") }
    var terminal: String { t("ターミナル", "Terminal") }
    var installCommand: String { t("wv を使えるようにする", "Install the wv command") }
    var commandInstalled: String { t("✓ wv が使えます", "✓ wv is ready") }
    var site: String { t("サイト ↗", "Website ↗") }

    // Settings panel
    var defaultApp: String { t("既定のアプリ — 押した形式を Wavi で開く", "Default app — open these types with Wavi") }
    var fullWidthSpace: String { t("全角スペース", "Full-width spaces") }
    var showFullWidthSpace: String { t("見せる（□で表示）", "Show (as □)") }
    var hideFullWidthSpace: String { t("見せない", "Hide") }
    var vimKeys: String { t("Vim キー操作", "Vim keys") }
    var vimKeysOn: String { t("使う", "On") }
    var vimKeysOff: String { t("使わない", "Off") }
    var appearance: String { t("外観", "Appearance") }
    var light: String { t("ライト", "Light") }
    var dark: String { t("ダーク", "Dark") }
    var automatic: String { t("自動", "Auto") }
    var languageTitle: String { t("言語", "Language") }

    // Alerts
    func notText(_ name: String) -> String {
        t("「\(name)」はテキストファイルではないため、開けません。", "“\(name)” is not a text file, so Wavi can’t open it.")
    }
    func tooLarge(_ name: String) -> String {
        t("「\(name)」は大きすぎるため、開けません。", "“\(name)” is too large to open.")
    }
    func cannotRead(_ name: String) -> String {
        t("「\(name)」を読み込めませんでした。", "Couldn’t read “\(name)”.")
    }
    func saveChanges(_ name: String) -> String {
        t("「\(name)」の変更を保存しますか？", "Save changes to “\(name)”?")
    }
    var save: String { t("保存", "Save") }
    var dontSave: String { t("保存しない", "Don’t Save") }
    var cancel: String { t("キャンセル", "Cancel") }
    var encodingFallback: String {
        t(
            "元の文字コードで表せない文字があるため、UTF-8 で保存しました。",
            "Some characters can’t be written in the original encoding, so the file was saved as UTF-8.")
    }
    var installFailed: String { t("wv を入れられませんでした。", "Couldn’t install the wv command.") }
    var defaultAppFailed: String { t("既定のアプリを変更できませんでした。", "Couldn’t change the default app.") }

    // Menus
    var about: String { t("Wavi について", "About Wavi") }
    var hide: String { t("Wavi を隠す", "Hide Wavi") }
    var hideOthers: String { t("ほかを隠す", "Hide Others") }
    var showAll: String { t("すべてを表示", "Show All") }
    var quit: String { t("Wavi を終了", "Quit Wavi") }
    var file: String { t("ファイル", "File") }
    var openEllipsis: String { t("開く…", "Open…") }
    var saveEllipsis: String { t("保存…", "Save…") }
    var saveAs: String { t("別名で保存…", "Save As…") }
    var edit: String { t("編集", "Edit") }
    var undo: String { t("取り消す", "Undo") }
    var redo: String { t("やり直す", "Redo") }
    var cut: String { t("カット", "Cut") }
    var copyMenu: String { t("コピー", "Copy") }
    var pasteMenu: String { t("ペースト", "Paste") }
    var selectAll: String { t("すべてを選択", "Select All") }
    var find: String { t("検索…", "Find…") }
    var findNext: String { t("次を検索", "Find Next") }
    var findPrevious: String { t("前を検索", "Find Previous") }
    var findPlaceholder: String { t("検索", "Find") }
    var noMatches: String { t("見つかりません", "No matches") }
    var view: String { t("表示", "View") }
    var window: String { t("ウインドウ", "Window") }
    var minimize: String { t("しまう", "Minimize") }
    var zoom: String { t("拡大／縮小", "Zoom") }
    var nextTab: String { t("次のタブを表示", "Show Next Tab") }
    var previousTab: String { t("前のタブを表示", "Show Previous Tab") }
}
