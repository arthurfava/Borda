import AppKit
import BordaCore

@MainActor
final class PreferencesWindowController: NSWindowController {
    private let preferences: BordaPreferencesStore
    private let onChange: () -> Void
    private let left = NSButton(checkboxWithTitle: L10n.text("settings.left_edge", "Enable left edge"), target: nil, action: nil)
    private let right = NSButton(checkboxWithTitle: L10n.text("settings.right_edge", "Enable right edge"), target: nil, action: nil)
    private let width = NSSlider(value: 8, minValue: 4, maxValue: 24, target: nil, action: nil)
    private let delay = NSSlider(value: 0.08, minValue: 0, maxValue: 1.5, target: nil, action: nil)
    private let removeAfterDrag = NSButton(checkboxWithTitle: L10n.text("settings.remove_after_drag", "Remove from shelf after a successful drag"), target: nil, action: nil)
    private let clipboard = NSButton(checkboxWithTitle: L10n.text("settings.clipboard_history", "Save clipboard history"), target: nil, action: nil)
    private let launchAtLogin = NSButton(checkboxWithTitle: L10n.text("settings.launch_at_login", "Open Borda when I log in"), target: nil, action: nil)
    private let modifier = NSPopUpButton()
    private let watchedLabel = NSTextField(wrappingLabelWithString: L10n.text("settings.no_folders", "No watched folders"))

    init(preferences: BordaPreferencesStore, onChange: @escaping () -> Void) {
        self.preferences = preferences; self.onChange = onChange
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 520), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = L10n.text("settings.title", "Borda Settings"); window.center(); window.isReleasedWhenClosed = false
        super.init(window: window)
        configure()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show() { load(); showWindow(nil); window?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }

    private func configure() {
        let root = NSStackView(); root.orientation = .vertical; root.alignment = .leading; root.spacing = 14; root.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24); root.translatesAutoresizingMaskIntoConstraints = false
        let edgeTitle = title(L10n.text("settings.edges", "Edges"))
        let widthLabel = NSTextField(labelWithString: L10n.text("settings.capture_area", "Invisible capture area: 4–24 px"))
        let delayLabel = NSTextField(labelWithString: L10n.text("settings.open_delay", "Open delay: instant–1.5 s"))
        let shortcutTitle = title(L10n.text("settings.shortcuts", "Global shortcuts"))
        modifier.addItems(withTitles: ["⌘⌥ + B / C", "⌃⌥ + B / C", "⌃⇧ + B / C"]); modifier.target = self; modifier.action = #selector(save)
        let shortcutHelp = NSTextField(wrappingLabelWithString: L10n.text("settings.shortcut_help", "B shows shelves; C saves copied content.")); shortcutHelp.textColor = .secondaryLabelColor
        let automationTitle = title(L10n.text("settings.automation", "Automation"))
        let addFolder = NSButton(title: L10n.text("settings.add_folder", "Add watched folder…"), target: self, action: #selector(addWatchedFolder))
        let clearFolders = NSButton(title: L10n.text("settings.clear_folders", "Clear folders"), target: self, action: #selector(clearWatchedFolders))
        let folderButtons = NSStackView(views: [addFolder, clearFolders]); folderButtons.orientation = .horizontal; folderButtons.spacing = 8
        [left, right, width, delay, removeAfterDrag, clipboard, launchAtLogin].forEach { $0.target = self; $0.action = #selector(save) }
        [edgeTitle, left, right, widthLabel, width, delayLabel, delay, removeAfterDrag, launchAtLogin, shortcutTitle, modifier, shortcutHelp, automationTitle, clipboard, watchedLabel, folderButtons].forEach(root.addArrangedSubview)
        [width, delay, watchedLabel].forEach { $0.widthAnchor.constraint(equalToConstant: 420).isActive = true }
        window?.contentView?.addSubview(root)
        NSLayoutConstraint.activate([root.leadingAnchor.constraint(equalTo: window!.contentView!.leadingAnchor), root.trailingAnchor.constraint(equalTo: window!.contentView!.trailingAnchor), root.topAnchor.constraint(equalTo: window!.contentView!.topAnchor), root.bottomAnchor.constraint(lessThanOrEqualTo: window!.contentView!.bottomAnchor)])
    }

    private func title(_ string: String) -> NSTextField { let label = NSTextField(labelWithString: string); label.font = .systemFont(ofSize: 15, weight: .semibold); return label }

    private func load() {
        let value = preferences.value
        left.state = value.leftEdgeEnabled ? .on : .off; right.state = value.rightEdgeEnabled ? .on : .off
        width.doubleValue = value.triggerWidth; delay.doubleValue = value.openingDelay
        removeAfterDrag.state = value.removeAfterSuccessfulDrag ? .on : .off; clipboard.state = value.clipboardHistoryEnabled ? .on : .off
        launchAtLogin.state = value.launchAtLogin ? .on : .off
        modifier.selectItem(at: Int(value.shortcutModifiers).clamped(to: 0...2))
        watchedLabel.stringValue = value.watchedFolderPaths.isEmpty ? L10n.text("settings.no_folders", "No watched folders") : value.watchedFolderPaths.joined(separator: "\n")
    }

    @objc private func save() {
        do {
            try preferences.update { value in
                value.leftEdgeEnabled = left.state == .on; value.rightEdgeEnabled = right.state == .on
                value.triggerWidth = width.doubleValue; value.openingDelay = delay.doubleValue
                value.removeAfterSuccessfulDrag = removeAfterDrag.state == .on; value.clipboardHistoryEnabled = clipboard.state == .on
                value.launchAtLogin = launchAtLogin.state == .on
                value.shortcutModifiers = UInt32(modifier.indexOfSelectedItem)
            }
            onChange()
        } catch { NSSound.beep() }
    }

    @objc private func addWatchedFolder() {
        let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        try? preferences.update { value in
            for url in panel.urls {
                let path = url.standardizedFileURL.path
                value.watchedFolderPaths.append(path)
                if let bookmark = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                    value.watchedFolderBookmarks[path] = bookmark
                }
            }
        }
        load(); onChange()
    }
    @objc private func clearWatchedFolders() {
        try? preferences.update {
            $0.watchedFolderPaths = []
            $0.watchedFolderBookmarks = [:]
        }
        load(); onChange()
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self { min(max(self, limits.lowerBound), limits.upperBound) }
}
