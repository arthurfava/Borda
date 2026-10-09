import AppKit
import BordaCore

@MainActor
final class ShelfPanelController: NSObject, ShelfContentViewDelegate, EdgeTriggerViewDelegate {
    fileprivate enum Metrics {
        static let expandedWidth: CGFloat = 286
        static let collapsedWidth: CGFloat = 44
        static let visibleTabWidth: CGFloat = 17
        static let collapsedHeight: CGFloat = 84
        static let screenInset: CGFloat = 10
        static let existingShelfRadius: CGFloat = 74
    }

    var onHistoryChanged: (() -> Void)?
    private let store: ShelfStore
    fileprivate let preferences: BordaPreferencesStore
    private let actionService = ShelfActionService()
    private let quickLookPresenter = QuickLookPresenter()
    private var pods: [UUID: ShelfPodController] = [:]
    private var draftPod: ShelfPodController?
    private weak var activeDropPod: ShelfPodController?
    private var triggerPanels: [EdgeTriggerPanel] = []
    private var lastTargetShelfID: UUID?
    private var automationTimer: Timer?
    private var pointerTimer: Timer?
    private var lastPasteboardChange = NSPasteboard.general.changeCount
    private var watchedSnapshots: [String: Set<String>] = [:]

    init(store: ShelfStore, preferences: BordaPreferencesStore) {
        self.store = store
        self.preferences = preferences
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func start() {
        syncPods()
        if !ProcessInfo.processInfo.arguments.contains("--show") { rebuildEdgeTriggers() }
        if ProcessInfo.processInfo.arguments.contains("--show") { showAll() }
        refreshAutomation()
        startPointerTracking()
    }

    func showAll() {
        syncPods()
        for pod in pods.values { pod.expand() }
    }

    func captureClipboard() {
        do {
            let pod = try targetPodForClipboard()
            guard ingest(NSPasteboard.general, into: pod) else { return }
            pod.expand()
            pod.scheduleCollapse(after: 1.2)
        } catch { show(error: error, in: nil) }
    }

    func capture(urls: [URL]) {
        let pasteboard = NSPasteboard(name: .init("BordaInbound-\(UUID().uuidString)"))
        pasteboard.clearContents(); pasteboard.writeObjects(urls as [NSURL])
        do { let pod = try targetPodForClipboard(); _ = ingest(pasteboard, into: pod) }
        catch { show(error: error, in: nil) }
    }

    func capture(pasteboard: NSPasteboard) {
        do { let pod = try targetPodForClipboard(); _ = ingest(pasteboard, into: pod) }
        catch { show(error: error, in: nil) }
    }

    @discardableResult
    func restoreLastExported() -> Bool {
        do {
            guard let result = try store.restoreLastExported() else { return false }
            syncPods()
            if let pod = pods[result.shelfID] {
                lastTargetShelfID = result.shelfID
                pod.expand()
                pod.scheduleCollapse(after: 1.2)
            }
            onHistoryChanged?()
            return true
        } catch {
            show(error: error, in: nil)
            onHistoryChanged?()
            return false
        }
    }

    var canRestoreLastExported: Bool { store.canRestoreExportedItem }

    var pinnedShelves: [ShelfGroup] { store.openShelves.filter(\.isPinned) }
    var allShelves: [ShelfGroup] { store.openShelves }
    var recentShelves: [ShelfGroup] { store.recentShelves }

    func reopenShelf(_ id: UUID) {
        do { try store.reopenShelf(id); syncPods(); pods[id]?.expand(); onHistoryChanged?() }
        catch { show(error: error, in: nil) }
    }

    func showShelf(_ id: UUID) { syncPods(); pods[id]?.expand() }

    func preferencesDidChange() {
        rebuildEdgeTriggers()
        pods.values.forEach { $0.scheduleCollapse(after: 0.1) }
        refreshAutomation()
    }

    // MARK: Edge trigger

    func edgeTriggerUpdated(at screenPoint: NSPoint, on screen: NSScreen, side: ShelfSide) {
        let screenID = Self.screenID(for: screen)
        let matching = pods.values
            .filter { $0.side == side && $0.screenID == screenID }
            .min { abs($0.anchorY(on: screen) - screenPoint.y) < abs($1.anchorY(on: screen) - screenPoint.y) }

        if let matching, abs(matching.anchorY(on: screen) - screenPoint.y) <= Metrics.existingShelfRadius {
            if activeDropPod !== matching {
                discardDraft()
                activeDropPod?.scheduleCollapse(after: 0.15)
                activeDropPod = matching
            }
            matching.expand()
            return
        }

        let normalized = Self.normalizedY(screenPoint.y, on: screen)
        if let draft = draftPod, draft.side == side, draft.screenID == screenID {
            draft.normalizedY = normalized
            draft.expand()
        } else {
            discardDraft()
            activeDropPod?.scheduleCollapse(after: 0.15)
            let draft = ShelfPodController(
                shelfID: nil,
                side: side,
                screenID: screenID,
                normalizedY: normalized,
                screen: screen,
                manager: self
            )
            draft.display(items: [], store: store)
            draftPod = draft
            activeDropPod = draft
            draft.expand()
        }
    }

    func edgeTriggerExited() {
        activeDropPod?.scheduleCollapse(after: preferences.value.collapseDelay)
    }

    func edgeTriggerDidReceiveDrop(_ pasteboard: NSPasteboard, at screenPoint: NSPoint, on screen: NSScreen, side: ShelfSide) -> Bool {
        edgeTriggerUpdated(at: screenPoint, on: screen, side: side)
        guard let pod = activeDropPod else { return false }
        return ingest(pasteboard, into: pod)
    }

    // MARK: Shelf content

    func shelfViewDidReceiveDrop(_ view: ShelfContentView, pasteboard: NSPasteboard) -> Bool {
        guard let pod = pod(containing: view) else { return false }
        return ingest(pasteboard, into: pod)
    }

    func shelfViewRequestedExpansion(_ view: ShelfContentView) {
        pod(containing: view)?.expand()
    }

    func shelfViewRequestedCollapse(_ view: ShelfContentView) {
        pod(containing: view)?.scheduleCollapse(after: 0.45)
    }

    func shelfView(_ view: ShelfContentView, requestedRemovalOf item: ShelfItem) {
        guard let pod = pod(containing: view), let shelfID = pod.shelfID else { return }
        do {
            try store.remove(item, fromShelf: shelfID)
            syncPods()
        } catch { show(error: error, in: pod) }
    }

    func shelfViewDidBeginDraggingItem(_ view: ShelfContentView) {
        pod(containing: view)?.isDraggingOut = true
    }

    func shelfView(_ view: ShelfContentView, didFinishDragging items: [ShelfItem], completed: Bool) {
        guard let pod = pod(containing: view), let shelfID = pod.shelfID else { return }
        pod.isDraggingOut = false
        guard completed else {
            pod.scheduleCollapse(after: 0.35)
            return
        }
        do {
            if preferences.value.removeAfterSuccessfulDrag {
                for item in items { try store.markExported(item, fromShelf: shelfID) }
            }
            syncPods()
            onHistoryChanged?()
            pods[shelfID]?.scheduleCollapse(after: 0.35)
        } catch { show(error: error, in: pod) }
    }

    func shelfView(_ view: ShelfContentView, perform action: ShelfItemAction, on items: [ShelfItem], anchor: NSView?) {
        guard let pod = pod(containing: view), let shelfID = pod.shelfID, !items.isEmpty else { return }
        let urls = items.map(store.payloadURL(for:))
        do {
            switch action {
            case .quickLook: quickLookPresenter.show(urls)
            case .reveal: NSWorkspace.shared.activateFileViewerSelecting(urls)
            case .share:
                guard let anchor else { return }
                NSSharingServicePicker(items: urls).show(relativeTo: anchor.bounds, of: anchor, preferredEdge: .maxX)
            case .copyPaths:
                NSPasteboard.general.clearContents(); NSPasteboard.general.setString(urls.map(\.path).joined(separator: "\n"), forType: .string)
                view.showTransientMessage(items.count == 1 ? L10n.text("notice.path_copied", "Path copied") : L10n.text("notice.paths_copied", "Paths copied"))
            case .rename:
                guard let item = items.first, let name = prompt(title: L10n.text("action.rename_item", "Rename item"), value: item.displayName) else { return }
                try store.rename(item, to: name); syncPods()
            case .zip:
                let output = try actionService.createZIP(from: urls, in: generatedDirectory(), preferredName: items.count == 1 ? items[0].displayName : L10n.text("generated.borda_items", "Borda Items"))
                defer { try? FileManager.default.removeItem(at: output) }
                try store.addFile(at: output, toShelf: shelfID); syncPods(); view.showTransientMessage(L10n.text("notice.zip_created", "ZIP added to the shelf"))
            case .resize:
                guard let source = urls.first else { return }
                let output = try actionService.resizeImage(at: source, maximumDimension: 1600, in: generatedDirectory())
                defer { try? FileManager.default.removeItem(at: output) }
                try store.addFile(at: output, toShelf: shelfID); syncPods(); view.showTransientMessage(L10n.text("notice.image_resized", "Image resized"))
            case .ocr:
                guard let source = urls.first else { return }
                Task { @MainActor [weak self, weak view] in
                    guard let self else { return }
                    do {
                        let text = try await actionService.recognizeText(in: source)
                        guard !text.isEmpty else { view?.showTransientMessage(L10n.text("notice.no_text", "No text found")); return }
                        try store.addText(text, toShelf: shelfID); syncPods(); view?.showTransientMessage(L10n.text("notice.ocr_complete", "Text extracted with OCR"))
                    } catch { show(error: error, in: pod) }
                }
            case .move(let delta):
                guard let item = items.first, let shelf = store.shelf(withID: shelfID), let index = shelf.itemIDs.firstIndex(of: item.id) else { return }
                var ordered = shelf.itemIDs
                let destination = min(max(index + delta, 0), ordered.count - 1)
                guard destination != index else { return }
                ordered.remove(at: index); ordered.insert(item.id, at: destination)
                try store.reorderItems(inShelf: shelfID, orderedIDs: ordered); syncPods()
            }
        } catch { show(error: error, in: pod) }
    }

    func shelfView(_ view: ShelfContentView, perform action: ShelfAction) {
        guard let pod = pod(containing: view), let shelfID = pod.shelfID, let shelf = store.shelf(withID: shelfID) else { return }
        do {
            switch action {
            case .rename:
                guard let name = prompt(title: L10n.text("shelf.name", "Shelf name"), value: shelf.name ?? L10n.text("shelf.title", "Shelf")) else { return }
                try store.updateShelfIdentity(shelfID, name: name, color: shelf.color)
            case .pin(let pinned): try store.setShelfPinned(shelfID, pinned: pinned)
            case .color(let color): try store.updateShelfIdentity(shelfID, name: shelf.name, color: color)
            case .close: try store.closeShelf(shelfID)
            }
            syncPods(); onHistoryChanged?()
        } catch { show(error: error, in: pod) }
    }

    // MARK: Ingestion

    private func ingest(_ pasteboard: NSPasteboard, into pod: ShelfPodController) -> Bool {
        do {
            let createdShelfID: UUID?
            if pod.shelfID == nil {
                let shelf = try store.createShelf(side: pod.side, screenID: pod.screenID, normalizedY: pod.normalizedY)
                pod.shelfID = shelf.id
                createdShelfID = shelf.id
            } else {
                createdShelfID = nil
            }
            guard let shelfID = pod.shelfID else { return false }

            var imported = false
            if try ingestFileURLs(from: pasteboard, toShelf: shelfID) {
                imported = true
            } else if let image = NSImage(pasteboard: pasteboard), let data = image.pngData {
                try store.addData(data, fileName: "Image.png", kind: .image, displayName: L10n.text("kind.image", "Image"), toShelf: shelfID)
                imported = true
            } else if let urlString = pasteboard.string(forType: .URL), let url = URL(string: urlString) {
                try store.addURL(url, toShelf: shelfID)
                imported = true
            } else if let data = pasteboard.data(forType: .rtf) {
                try store.addData(data, fileName: "Text.rtf", kind: .richText, displayName: L10n.text("kind.rich_text", "Rich text"), toShelf: shelfID)
                imported = true
            } else if let data = pasteboard.data(forType: .html) {
                try store.addData(data, fileName: "Text.html", kind: .richText, displayName: "HTML", toShelf: shelfID)
                imported = true
            } else if let value = pasteboard.string(forType: .string), !value.isEmpty {
                try store.addText(value, toShelf: shelfID)
                imported = true
            }

            guard imported else {
                if let createdShelfID { try store.discardShelfIfEmpty(createdShelfID) }
                return false
            }
            lastTargetShelfID = shelfID
            draftPod = nil
            activeDropPod = pod
            syncPods(reusing: pod)
            pod.expand()
            pod.scheduleCollapse(after: 0.9)
            return true
        } catch {
            if let shelfID = pod.shelfID { try? store.discardShelfIfEmpty(shelfID) }
            show(error: error, in: pod)
            return false
        }
    }

    private func ingestFileURLs(from pasteboard: NSPasteboard, toShelf shelfID: UUID) throws -> Bool {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        guard let values = pasteboard.readObjects(forClasses: [NSURL.self], options: options), !values.isEmpty else { return false }
        var added: [ShelfItem] = []
        do {
            for case let value as NSURL in values {
                guard let url = value as URL?, url.isFileURL else { continue }
                added.append(try store.addFile(at: url, toShelf: shelfID))
            }
        } catch {
            for item in added { try? store.remove(item, fromShelf: shelfID) }
            throw error
        }
        return !added.isEmpty
    }

    private func targetPodForClipboard() throws -> ShelfPodController {
        if let id = lastTargetShelfID, let pod = pods[id] { return pod }
        if let shelf = store.openShelves.first, let pod = pods[shelf.id] { return pod }
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let shelf = try store.createShelf(side: .right, screenID: Self.screenID(for: screen), normalizedY: 0.5)
        syncPods()
        return pods[shelf.id]!
    }

    // MARK: Pods and geometry

    private func syncPods(reusing reusedPod: ShelfPodController? = nil) {
        let activeIDs = Set(store.openShelves.map(\.id))
        let staleIDs = pods.keys.filter { !activeIDs.contains($0) }
        for id in staleIDs {
            pods[id]?.close()
            pods.removeValue(forKey: id)
        }

        for shelf in store.openShelves {
            let pod: ShelfPodController
            if let reusedPod, reusedPod.shelfID == shelf.id {
                pod = reusedPod
                pods[shelf.id] = reusedPod
            } else if let existing = pods[shelf.id] {
                pod = existing
            } else {
                let screen = screen(forID: shelf.screenID)
                pod = ShelfPodController(
                    shelfID: shelf.id,
                    side: shelf.side,
                    screenID: shelf.screenID ?? Self.screenID(for: screen),
                    normalizedY: shelf.normalizedY,
                    screen: screen,
                    manager: self
                )
                pods[shelf.id] = pod
                pod.collapse(immediately: true)
            }
            pod.side = shelf.side
            pod.screenID = shelf.screenID ?? pod.screenID
            pod.normalizedY = shelf.normalizedY
            pod.display(items: store.items(inShelf: shelf.id), shelf: shelf, store: store)
        }
    }

    private func pod(containing view: ShelfContentView) -> ShelfPodController? {
        if draftPod?.view === view { return draftPod }
        return pods.values.first { $0.view === view }
    }

    private func startPointerTracking() {
        pointerTimer?.invalidate()
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.updatePointerTarget() }
        }
        RunLoop.main.add(timer, forMode: .common)
        pointerTimer = timer
        updatePointerTarget()
    }

    private func updatePointerTarget() {
        let point = NSEvent.mouseLocation
        let candidates = pods.values.filter { $0.containsPointer(point) }
        let preferred = candidates.min { lhs, rhs in
            if lhs.isExpanded != rhs.isExpanded { return lhs.isExpanded }
            let lhsScreen = screen(forID: lhs.screenID)
            let rhsScreen = screen(forID: rhs.screenID)
            return abs(lhs.anchorY(on: lhsScreen) - point.y) < abs(rhs.anchorY(on: rhsScreen) - point.y)
        }
        for pod in pods.values { pod.updatePointer(isInside: pod === preferred) }
    }

    private func discardDraft() {
        guard let draft = draftPod else { return }
        draft.close()
        draftPod = nil
        if activeDropPod === draft { activeDropPod = nil }
    }

    private func rebuildEdgeTriggers() {
        triggerPanels.forEach { $0.orderOut(nil) }
        triggerPanels.removeAll()
        for screen in NSScreen.screens {
            for side in ShelfSide.allCases where (side == .left ? preferences.value.leftEdgeEnabled : preferences.value.rightEdgeEnabled) {
                let view = EdgeTriggerView(side: side)
                view.delegate = self
                let panel = EdgeTriggerPanel(
                    contentRect: triggerFrame(on: screen, side: side),
                    styleMask: [.borderless, .nonactivatingPanel],
                    backing: .buffered,
                    defer: false,
                    screen: screen
                )
                panel.contentView = view
                // Uma janela com alpha exatamente zero pode ser ignorada pelo WindowServer
                // durante um drag vindo de outro aplicativo. 0,1% continua invisível,
                // mas mantém a faixa como destino de arrasto confiável.
                panel.backgroundColor = NSColor.black.withAlphaComponent(0.001)
                panel.isOpaque = false
                panel.hasShadow = false
                panel.level = .statusBar
                panel.hidesOnDeactivate = false
                panel.isReleasedWhenClosed = false
                panel.ignoresMouseEvents = false
                panel.acceptsMouseMovedEvents = true
                panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
                panel.orderFrontRegardless()
                triggerPanels.append(panel)
            }
        }
    }

    private func triggerFrame(on screen: NSScreen, side: ShelfSide) -> NSRect {
        let visible = screen.visibleFrame
        let width = CGFloat(preferences.value.triggerWidth)
        let x = side == .right ? visible.maxX - width : visible.minX
        return NSRect(x: x, y: visible.minY, width: width, height: visible.height)
    }

    fileprivate func screen(forID id: String?) -> NSScreen {
        NSScreen.screens.first { Self.screenID(for: $0) == id } ?? NSScreen.main ?? NSScreen.screens[0]
    }

    fileprivate static func screenID(for screen: NSScreen) -> String {
        if let value = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            return value.stringValue
        }
        return "main"
    }

    fileprivate static func normalizedY(_ y: CGFloat, on screen: NSScreen) -> Double {
        let visible = screen.visibleFrame
        guard visible.height > 0 else { return 0.5 }
        return Double(min(max((y - visible.minY) / visible.height, 0), 1))
    }

    private func show(error: Error, in pod: ShelfPodController?) {
        NSSound.beep()
        if let pod {
            pod.view.showTransientMessage(error.localizedDescription)
            pod.expand()
        } else {
            let alert = NSAlert()
            alert.messageText = L10n.text("error.save_content", "Borda couldn’t save this content")
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    private func prompt(title: String, value: String) -> String? {
        let alert = NSAlert(); alert.messageText = title
        alert.addButton(withTitle: L10n.text("common.ok", "OK")); alert.addButton(withTitle: L10n.text("common.cancel", "Cancel"))
        let field = NSTextField(string: value); field.frame = NSRect(x: 0, y: 0, width: 280, height: 24)
        alert.accessoryView = field
        return alert.runModal() == .alertFirstButtonReturn ? field.stringValue : nil
    }

    private func generatedDirectory() throws -> URL {
        let url = store.rootURL.appendingPathComponent("Generated", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func refreshAutomation() {
        automationTimer?.invalidate()
        for path in preferences.value.watchedFolderPaths where watchedSnapshots[path] == nil {
            watchedSnapshots[path] = folderContents(path)
        }
        automationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.automationTick() }
        }
    }

    private func automationTick() {
        if preferences.value.clipboardHistoryEnabled, NSPasteboard.general.changeCount != lastPasteboardChange {
            lastPasteboardChange = NSPasteboard.general.changeCount
            captureClipboardHistory()
        } else { lastPasteboardChange = NSPasteboard.general.changeCount }
        for path in preferences.value.watchedFolderPaths {
            processWatchedFolder(path)
        }
    }

    private func processWatchedFolder(_ path: String) {
            let folderURL = watchedFolderURL(for: path)
            let granted = folderURL.startAccessingSecurityScopedResource()
            defer { if granted { folderURL.stopAccessingSecurityScopedResource() } }
            let current = folderContents(at: folderURL)
            let newPaths = current.subtracting(watchedSnapshots[path] ?? current)
            watchedSnapshots[path] = current
            guard !newPaths.isEmpty else { return }
            do {
                let pod = try targetPodForClipboard()
                guard let shelfID = pod.shelfID else { return }
                for child in newPaths.sorted() { _ = try store.addFile(at: URL(fileURLWithPath: child), toShelf: shelfID) }
                syncPods(); pod.expand(); pod.scheduleCollapse(after: 1.2)
            } catch { show(error: error, in: nil) }
    }

    private func folderContents(_ path: String) -> Set<String> {
        let url = watchedFolderURL(for: path)
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }
        return folderContents(at: url)
    }

    private func folderContents(at url: URL) -> Set<String> {
        let values = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        return Set(values.map(\.path))
    }

    private func watchedFolderURL(for path: String) -> URL {
        guard let bookmark = preferences.value.watchedFolderBookmarks[path] else {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        var stale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ) else { return URL(fileURLWithPath: path, isDirectory: true) }
        if stale, let refreshed = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
            try? preferences.update { $0.watchedFolderBookmarks[path] = refreshed }
        }
        return url
    }

    private func captureClipboardHistory() {
        do {
            let pod: ShelfPodController
            if let shelf = store.openShelves.first(where: { $0.name == "Clipboard" }), let existing = pods[shelf.id] {
                pod = existing
            } else {
                let screen = NSScreen.main ?? NSScreen.screens[0]
                let shelf = try store.createShelf(side: .right, screenID: Self.screenID(for: screen), normalizedY: 0.68)
                try store.updateShelfIdentity(shelf.id, name: "Clipboard", color: .blue)
                try store.setShelfPinned(shelf.id, pinned: true)
                syncPods(); guard let created = pods[shelf.id] else { return }; pod = created
            }
            guard ingest(NSPasteboard.general, into: pod), let shelfID = pod.shelfID else { return }
            let excess = max(0, store.items(inShelf: shelfID).count - preferences.value.clipboardHistoryLimit)
            for item in store.items(inShelf: shelfID).prefix(excess) { try store.remove(item, fromShelf: shelfID) }
            syncPods()
        } catch { show(error: error, in: nil) }
    }

    @objc private func screenConfigurationChanged() {
        rebuildEdgeTriggers()
        syncPods()
        pods.values.forEach { $0.collapse(immediately: true) }
    }
}

@MainActor
private final class ShelfPodController {
    var shelfID: UUID?
    var side: ShelfSide
    var screenID: String
    var normalizedY: Double
    var isDraggingOut = false
    let view: ShelfContentView

    private weak var manager: ShelfPanelController?
    private let panel: ShelfPanel
    private var collapseWorkItem: DispatchWorkItem?
    private var expansionWorkItem: DispatchWorkItem?
    private var expanded = false
    private var pointerInside = false
    private var transitionGeneration = 0
    private var lastTargetFrame: NSRect?

    var isExpanded: Bool { expanded }

    init(shelfID: UUID?, side: ShelfSide, screenID: String, normalizedY: Double, screen: NSScreen, manager: ShelfPanelController) {
        self.shelfID = shelfID
        self.side = side
        self.screenID = screenID
        self.normalizedY = normalizedY
        self.manager = manager
        view = ShelfContentView(frame: .zero)
        panel = ShelfPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false, screen: screen)
        view.delegate = manager
        panel.contentView = view
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        panel.minSize = .zero
        panel.contentMinSize = .zero
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    }

    func display(items: [ShelfItem], shelf: ShelfGroup? = nil, store: ShelfStore) {
        view.display(items: items, shelf: shelf, store: store)
        if !expanded { view.setCollapsed(true, side: side) }
    }

    func anchorY(on screen: NSScreen) -> CGFloat {
        screen.visibleFrame.minY + CGFloat(normalizedY) * screen.visibleFrame.height
    }

    func expand() {
        expansionWorkItem?.cancel()
        collapseWorkItem?.cancel()
        guard let manager else { return }
        if expanded {
            let target = expandedFrame(on: manager.screen(forID: screenID))
            guard lastTargetFrame != target else { return }
            animate(to: target, duration: 0.16, timing: .easeOut)
            return
        }
        expanded = true
        transitionGeneration += 1
        let generation = transitionGeneration
        let screen = manager.screen(forID: screenID)
        let frame = expandedFrame(on: screen)
        if !panel.isVisible {
            view.setCollapsed(true, side: side)
            panel.setFrame(collapsedFrame(on: screen), display: false)
            panel.orderFrontRegardless()
        }
        animate(to: frame, duration: 0.18, timing: .easeOut) { [weak self] in
            guard let self, self.expanded, self.transitionGeneration == generation else { return }
            self.view.setCollapsed(false, side: self.side, animated: true)
        }
    }

    func requestExpansion(after delay: TimeInterval) {
        guard !expanded, expansionWorkItem == nil else { return }
        let work = DispatchWorkItem { [weak self] in
            self?.expansionWorkItem = nil
            self?.expand()
        }
        expansionWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, delay), execute: work)
    }

    func containsPointer(_ point: NSPoint) -> Bool {
        guard let manager else { return false }
        let screen = manager.screen(forID: screenID)
        let visualFrame = expanded ? expandedFrame(on: screen) : collapsedFrame(on: screen)
        let state: ShelfInteractionState = expanded ? .expanded : .collapsed
        return ShelfInteractionGeometry.region(around: visualFrame, state: state).contains(point)
    }

    func updatePointer(isInside: Bool) {
        guard let manager else { return }
        if isInside {
            collapseWorkItem?.cancel()
            view.setInteractionActive(true)
            if !pointerInside { requestExpansion(after: manager.preferences.value.openingDelay) }
        } else {
            expansionWorkItem?.cancel()
            expansionWorkItem = nil
            view.setInteractionActive(false)
            if pointerInside && expanded { scheduleCollapse(after: manager.preferences.value.collapseDelay) }
        }
        pointerInside = isInside
    }

    func scheduleCollapse(after delay: TimeInterval) {
        guard !isDraggingOut else { return }
        collapseWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.collapse(immediately: false) }
        collapseWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    func collapse(immediately: Bool) {
        guard !isDraggingOut else { return }
        guard immediately || !pointerInside else { return }
        guard shelfID != nil else {
            close()
            return
        }
        expansionWorkItem?.cancel()
        expansionWorkItem = nil
        collapseWorkItem?.cancel()
        expanded = false
        transitionGeneration += 1
        view.setCollapsed(true, side: side)
        guard let manager else { return }
        let screen = manager.screen(forID: screenID)
        if !panel.isVisible { panel.orderFrontRegardless() }
        animate(to: collapsedFrame(on: screen), duration: immediately ? 0 : 0.14, timing: .easeIn)
    }

    func close() {
        expansionWorkItem?.cancel()
        collapseWorkItem?.cancel()
        panel.orderOut(nil)
    }

    private func animate(to frame: NSRect, duration: TimeInterval, timing: CAMediaTimingFunctionName, completion: (@MainActor @Sendable () -> Void)? = nil) {
        lastTargetFrame = frame
        let reduced = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = reduced ? 0 : duration
            context.timingFunction = CAMediaTimingFunction(name: timing)
            panel.animator().setFrame(frame, display: true)
        }, completionHandler: {
            Task { @MainActor in completion?() }
        })
    }

    private func expandedFrame(on screen: NSScreen) -> NSRect {
        frame(on: screen, width: ShelfPanelController.Metrics.expandedWidth, height: view.preferredHeight, visibleWidth: ShelfPanelController.Metrics.expandedWidth)
    }

    private func collapsedFrame(on screen: NSScreen) -> NSRect {
        frame(on: screen, width: ShelfPanelController.Metrics.collapsedWidth, height: ShelfPanelController.Metrics.collapsedHeight, visibleWidth: ShelfPanelController.Metrics.visibleTabWidth)
    }

    private func frame(on screen: NSScreen, width: CGFloat, height: CGFloat, visibleWidth: CGFloat) -> NSRect {
        let visible = screen.visibleFrame
        let centerY = anchorY(on: screen)
        let minimumY = visible.minY + ShelfPanelController.Metrics.screenInset
        let maximumY = max(minimumY, visible.maxY - height - ShelfPanelController.Metrics.screenInset)
        let y = min(max(centerY - height / 2, minimumY), maximumY)
        let x = side == .right ? visible.maxX - visibleWidth : visible.minX - (width - visibleWidth)
        return NSRect(x: x, y: y, width: width, height: height)
    }
}

private final class ShelfPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation, let representation = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return representation.representation(using: .png, properties: [:])
    }
}
