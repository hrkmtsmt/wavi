import AppKit

/// The menu bar. Actions travel the responder chain to the text view and
/// the DocumentWindowController.
enum MainMenu {
    static func make(strings: Strings) -> NSMenu {
        let main = NSMenu()
        main.addItem(submenu(appMenu(strings)))
        main.addItem(submenu(fileMenu(strings)))
        main.addItem(submenu(editMenu(strings)))
        let window = windowMenu(strings)
        main.addItem(submenu(window))
        NSApp.windowsMenu = window
        return main
    }

    private static func submenu(_ menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: menu.title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }

    private static func item(_ title: String, _ action: Selector?, _ key: String = "", _ modifiers: NSEvent.ModifierFlags = .command)
        -> NSMenuItem
    {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = modifiers
        return item
    }

    private static func appMenu(_ s: Strings) -> NSMenu {
        let menu = NSMenu(title: "Wavi")
        menu.addItem(item(s.about, #selector(NSApplication.orderFrontStandardAboutPanel(_:))))
        menu.addItem(.separator())
        menu.addItem(item(s.settings + "…", #selector(DocumentWindowController.toggleSettingsPanel(_:)), ","))
        menu.addItem(.separator())
        menu.addItem(item(s.hide, #selector(NSApplication.hide(_:)), "h"))
        menu.addItem(item(s.hideOthers, #selector(NSApplication.hideOtherApplications(_:)), "h", [.command, .option]))
        menu.addItem(item(s.showAll, #selector(NSApplication.unhideAllApplications(_:))))
        menu.addItem(.separator())
        menu.addItem(item(s.quit, #selector(NSApplication.terminate(_:)), "q"))
        return menu
    }

    private static func fileMenu(_ s: Strings) -> NSMenu {
        let menu = NSMenu(title: s.file)
        menu.addItem(item(s.new, #selector(DocumentWindowController.newDocument(_:)), "n"))
        menu.addItem(item(s.openEllipsis, #selector(DocumentWindowController.openDocument(_:)), "o"))
        menu.addItem(.separator())
        menu.addItem(item(s.closeTab, #selector(DocumentWindowController.closeTab(_:)), "w"))
        menu.addItem(item(s.saveEllipsis, #selector(DocumentWindowController.saveDocument(_:)), "s"))
        menu.addItem(item(s.saveAs, #selector(DocumentWindowController.saveDocumentAs(_:)), "s", [.command, .shift]))
        return menu
    }

    private static func editMenu(_ s: Strings) -> NSMenu {
        let menu = NSMenu(title: s.edit)
        menu.addItem(item(s.undo, Selector(("undo:")), "z"))
        menu.addItem(item(s.redo, Selector(("redo:")), "z", [.command, .shift]))
        menu.addItem(.separator())
        menu.addItem(item(s.cut, #selector(NSText.cut(_:)), "x"))
        menu.addItem(item(s.copyMenu, #selector(NSText.copy(_:)), "c"))
        menu.addItem(item(s.copyAll, #selector(DocumentWindowController.copyAllText(_:)), "c", [.command, .shift]))
        menu.addItem(item(s.pasteMenu, #selector(NSText.paste(_:)), "v"))
        menu.addItem(item(s.selectAll, #selector(NSText.selectAll(_:)), "a"))
        menu.addItem(.separator())
        let find = item(s.find, #selector(NSTextView.performFindPanelAction(_:)), "f")
        find.tag = Int(NSFindPanelAction.showFindPanel.rawValue)
        menu.addItem(find)
        let next = item(s.findNext, #selector(NSTextView.performFindPanelAction(_:)), "g")
        next.tag = Int(NSFindPanelAction.next.rawValue)
        menu.addItem(next)
        let previous = item(s.findPrevious, #selector(NSTextView.performFindPanelAction(_:)), "g", [.command, .shift])
        previous.tag = Int(NSFindPanelAction.previous.rawValue)
        menu.addItem(previous)
        return menu
    }

    private static func windowMenu(_ s: Strings) -> NSMenu {
        let menu = NSMenu(title: s.window)
        menu.addItem(item(s.minimize, #selector(NSWindow.performMiniaturize(_:)), "m"))
        menu.addItem(item(s.zoom, #selector(NSWindow.performZoom(_:))))
        menu.addItem(.separator())
        menu.addItem(item(s.nextTab, #selector(DocumentWindowController.selectNextTab(_:)), "}", [.command, .shift]))
        menu.addItem(item(s.previousTab, #selector(DocumentWindowController.selectPreviousTab(_:)), "{", [.command, .shift]))
        return menu
    }
}
