import AppKit
import BordaCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: ShelfStore?
    private var shelfController: ShelfPanelController?
    private var preferences: BordaPreferencesStore?
    private var preferencesWindow: PreferencesWindowController?
    private var hotKeys: GlobalHotKeyManager?
    private let loginItemManager = LoginItemManager()
    private lazy var supportService = SupportServiceFactory.make()
    private var statusItem: NSStatusItem?
    private var restoreMenuItem: NSMenuItem?
    private let pinnedMenu = NSMenu()
    private let recentMenu = NSMenu()
    private let allShelvesMenu = NSMenu()

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let store = try ShelfStore(rootURL: dataRootOverride())
            let preferences = try BordaPreferencesStore(rootURL: store.rootURL)
            try seedDemoIfRequested(store)
            let controller = ShelfPanelController(store: store, preferences: preferences)
            self.store = store
            self.preferences = preferences
            self.shelfController = controller
            controller.onHistoryChanged = { [weak self] in
                self?.updateRestoreMenuItem()
                self?.rebuildShelfMenus()
            }
            preferencesWindow = PreferencesWindowController(preferences: preferences) { [weak self] in self?.preferencesChanged() }
            configureStatusItem()
            configureHotKeys()
            synchronizeLoginItem(showErrors: false)
            NSApp.servicesProvider = self
            controller.start()
        } catch {
            let alert = NSAlert()
            alert.messageText = L10n.text("error.launch", "Borda couldn’t start")
            alert.informativeText = error.localizedDescription
            alert.runModal()
            NSApplication.shared.terminate(nil)
        }
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "rectangle.portrait.rightthird.inset.filled",
            accessibilityDescription: "Borda"
        )

        let menu = NSMenu()
        menu.addItem(withTitle: L10n.text("menu.show", "Show shelves"), action: #selector(showShelf), keyEquivalent: "")
        menu.addItem(withTitle: L10n.text("menu.capture", "Save copied content"), action: #selector(captureClipboard), keyEquivalent: "")
        let all = NSMenuItem(title: L10n.text("menu.shelf_map", "Shelf map"), action: nil, keyEquivalent: ""); all.submenu = allShelvesMenu; menu.addItem(all)
        let pinned = NSMenuItem(title: L10n.text("menu.pinned", "Pinned shelves"), action: nil, keyEquivalent: ""); pinned.submenu = pinnedMenu; menu.addItem(pinned)
        let recent = NSMenuItem(title: L10n.text("menu.recent", "Recent shelves"), action: nil, keyEquivalent: ""); recent.submenu = recentMenu; menu.addItem(recent)
        let restoreItem = menu.addItem(
            withTitle: L10n.text("menu.restore", "Restore last removed item"),
            action: #selector(restoreLastExported),
            keyEquivalent: ""
        )
        restoreMenuItem = restoreItem
        menu.addItem(.separator())
        menu.addItem(withTitle: L10n.text("menu.preferences", "Settings…"), action: #selector(showPreferences), keyEquivalent: ",")
        menu.addItem(withTitle: L10n.text("menu.open_data", "Open data folder"), action: #selector(openDataFolder), keyEquivalent: "")
        menu.addItem(withTitle: L10n.text("menu.support", "Support Borda…"), action: #selector(showSupport), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: L10n.text("menu.quit", "Quit"), action: #selector(quit), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        item.menu = menu
        statusItem = item
        updateRestoreMenuItem()
        rebuildShelfMenus()
    }

    @objc private func showShelf() {
        shelfController?.showAll()
    }

    @objc private func captureClipboard() {
        shelfController?.captureClipboard()
    }

    @objc private func restoreLastExported() {
        shelfController?.restoreLastExported()
        updateRestoreMenuItem()
    }

    private func updateRestoreMenuItem() {
        restoreMenuItem?.isEnabled = shelfController?.canRestoreLastExported ?? false
    }

    private func rebuildShelfMenus() {
        allShelvesMenu.removeAllItems(); pinnedMenu.removeAllItems(); recentMenu.removeAllItems()
        for shelf in shelfController?.allShelves.sorted(by: { $0.side.rawValue + String($0.normalizedY) < $1.side.rawValue + String($1.normalizedY) }) ?? [] { allShelvesMenu.addItem(shelfMenuItem(shelf, recent: false)) }
        for shelf in shelfController?.pinnedShelves ?? [] { pinnedMenu.addItem(shelfMenuItem(shelf, recent: false)) }
        for shelf in shelfController?.recentShelves.prefix(12) ?? [] { recentMenu.addItem(shelfMenuItem(shelf, recent: true)) }
        if pinnedMenu.items.isEmpty { let item = NSMenuItem(title: L10n.text("common.none", "None"), action: nil, keyEquivalent: ""); item.isEnabled = false; pinnedMenu.addItem(item) }
        if recentMenu.items.isEmpty { let item = NSMenuItem(title: L10n.text("common.none", "None"), action: nil, keyEquivalent: ""); item.isEnabled = false; recentMenu.addItem(item) }
        if allShelvesMenu.items.isEmpty { let item = NSMenuItem(title: L10n.text("common.none", "None"), action: nil, keyEquivalent: ""); item.isEnabled = false; allShelvesMenu.addItem(item) }
    }

    private func shelfMenuItem(_ shelf: ShelfGroup, recent: Bool) -> NSMenuItem {
        let fallback = L10n.format("shelf.summary", "Shelf · %d items", shelf.itemIDs.count)
        let item = NSMenuItem(title: shelf.name ?? fallback, action: recent ? #selector(reopenShelf(_:)) : #selector(showSpecificShelf(_:)), keyEquivalent: "")
        item.target = self; item.representedObject = shelf.id.uuidString; return item
    }

    @objc private func reopenShelf(_ sender: NSMenuItem) { guard let raw = sender.representedObject as? String, let id = UUID(uuidString: raw) else { return }; shelfController?.reopenShelf(id) }
    @objc private func showSpecificShelf(_ sender: NSMenuItem) { guard let raw = sender.representedObject as? String, let id = UUID(uuidString: raw) else { return }; shelfController?.showShelf(id) }
    @objc private func showPreferences() { preferencesWindow?.show() }

    private func configureHotKeys() {
        let manager = GlobalHotKeyManager(); manager.onShow = { [weak self] in self?.showShelf() }; manager.onCapture = { [weak self] in self?.captureClipboard() }
        if let preferences { manager.register(preferences: preferences.value) }; hotKeys = manager
    }

    private func preferencesChanged() {
        if let preferences { hotKeys?.register(preferences: preferences.value) }
        shelfController?.preferencesDidChange()
        synchronizeLoginItem(showErrors: true)
    }

    private func synchronizeLoginItem(showErrors: Bool) {
        guard let preferences else { return }
        do { try loginItemManager.apply(enabled: preferences.value.launchAtLogin) }
        catch where showErrors {
            let alert = NSAlert(); alert.messageText = L10n.text("error.login_item", "Couldn’t configure launch at login"); alert.informativeText = error.localizedDescription; alert.runModal()
        } catch { }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        let files = urls.filter(\.isFileURL)
        if !files.isEmpty { shelfController?.capture(urls: files); return }
        for url in urls where url.scheme == "borda" {
            switch url.host {
            case "capture": captureClipboard()
            case "restore": restoreLastExported()
            case "import":
                if let path = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "file" })?.value {
                    shelfController?.capture(urls: [URL(fileURLWithPath: path)])
                }
            default: showShelf()
            }
        }
    }

    @objc func receiveInBorda(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options)?.compactMap { ($0 as? NSURL) as URL? } ?? []
        if !urls.isEmpty { shelfController?.capture(urls: urls) }
        else { shelfController?.capture(pasteboard: pasteboard) }
    }

    @objc private func openDataFolder() {
        guard let store else { return }
        NSWorkspace.shared.activateFileViewerSelecting([store.rootURL])
    }

    @objc private func showSupport() {
        supportService.presentSupport()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func dataRootOverride() -> URL? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "--data-root"), arguments.indices.contains(index + 1) else { return nil }
        return URL(fileURLWithPath: arguments[index + 1], isDirectory: true)
    }

    private func seedDemoIfRequested(_ store: ShelfStore) throws {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--demo-seed"), arguments.contains("--data-root"), store.shelves.isEmpty else { return }
        let upper = try store.createShelf(side: .right, screenID: nil, normalizedY: 0.72)
        try store.addText("Briefing da campanha — revisar antes da reunião", toShelf: upper.id)
        try store.addURL(URL(string: "https://apple.com")!, toShelf: upper.id)
        let lower = try store.createShelf(side: .right, screenID: nil, normalizedY: 0.34)
        try store.addText("Ideia rápida para guardar e usar depois", toShelf: lower.id)
    }
}
