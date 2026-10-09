import AppKit
import BordaCore

struct ShelfDragItem {
    let item: ShelfItem
    let payloadURL: URL
    let text: String?
}

@MainActor
final class ShelfItemView: NSView, NSDraggingSource {
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    let item: ShelfItem
    var onRemove: ((ShelfItem) -> Void)?
    var onSelect: ((ShelfItem, NSEvent.ModifierFlags) -> Void)?
    var onQuickLook: ((ShelfItem) -> Void)?
    var onReveal: ((ShelfItem) -> Void)?
    var onShare: ((ShelfItem, NSView) -> Void)?
    var onCopyPath: ((ShelfItem) -> Void)?
    var onRename: ((ShelfItem) -> Void)?
    var onZip: ((ShelfItem) -> Void)?
    var onResize: ((ShelfItem) -> Void)?
    var onOCR: ((ShelfItem) -> Void)?
    var onMove: ((ShelfItem, Int) -> Void)?
    var onDragBegan: (() -> Void)?
    var onDragEnded: (([ShelfItem], Bool) -> Void)?
    var dragItemsProvider: (() -> [ShelfDragItem])?

    private let payloadURL: URL
    private let text: String?
    private var mouseDownPoint: NSPoint?
    private let removeButton: NSButton
    private var trackingAreaReference: NSTrackingArea?

    var isSelected = false {
        didSet {
            layer?.backgroundColor = NSColor.clear.cgColor
            layer?.borderWidth = 0
            setAccessibilitySelected(isSelected)
        }
    }

    init(item: ShelfItem, payloadURL: URL, text: String?) {
        self.item = item
        self.payloadURL = payloadURL
        self.text = text
        removeButton = NSButton(image: NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: L10n.text("action.remove", "Remove")) ?? NSImage(), target: nil, action: nil)
        super.init(frame: .zero)
        configure()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func configure() {
        wantsLayer = true
        focusRingType = .none
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 57).isActive = true
        let icon = NSImageView(); icon.image = NSWorkspace.shared.icon(forFile: payloadURL.path); icon.imageScaling = .scaleProportionallyUpOrDown; icon.translatesAutoresizingMaskIntoConstraints = false
        let title = NSTextField(labelWithString: item.displayName); title.font = .systemFont(ofSize: 12.5, weight: .semibold); title.lineBreakMode = .byTruncatingMiddle; title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal); title.translatesAutoresizingMaskIntoConstraints = false
        let subtitle = NSTextField(labelWithString: subtitleText); subtitle.font = .systemFont(ofSize: 10.5); subtitle.textColor = .secondaryLabelColor; subtitle.lineBreakMode = .byTruncatingTail; subtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal); subtitle.translatesAutoresizingMaskIntoConstraints = false
        removeButton.target = self; removeButton.action = #selector(removePressed); removeButton.isBordered = false; removeButton.contentTintColor = .tertiaryLabelColor; removeButton.alphaValue = 0; removeButton.toolTip = L10n.text("action.remove_from_shelf", "Remove from shelf"); removeButton.translatesAutoresizingMaskIntoConstraints = false
        let separator = NSBox(); separator.boxType = .separator; separator.translatesAutoresizingMaskIntoConstraints = false
        [icon, title, subtitle, removeButton, separator].forEach(addSubview)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10), icon.centerYAnchor.constraint(equalTo: centerYAnchor), icon.widthAnchor.constraint(equalToConstant: 32), icon.heightAnchor.constraint(equalToConstant: 32),
            title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 9), title.trailingAnchor.constraint(equalTo: removeButton.leadingAnchor, constant: -8), title.topAnchor.constraint(equalTo: topAnchor, constant: 11),
            subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor), subtitle.trailingAnchor.constraint(equalTo: title.trailingAnchor), subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 3),
            removeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10), removeButton.centerYAnchor.constraint(equalTo: centerYAnchor), removeButton.widthAnchor.constraint(equalToConstant: 28), removeButton.heightAnchor.constraint(equalToConstant: 28),
            separator.leadingAnchor.constraint(equalTo: title.leadingAnchor), separator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10), separator.bottomAnchor.constraint(equalTo: bottomAnchor), separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        setAccessibilityElement(true); setAccessibilityRole(.group); setAccessibilityLabel(item.displayName)
        setAccessibilityHelp(L10n.text("accessibility.item_help", "Click to select, double-click to preview, or drag to remove."))
        setAccessibilityCustomActions([
            NSAccessibilityCustomAction(name: L10n.text("action.copy_item", "Copy item"), target: self, selector: #selector(copyForAccessibility)),
            NSAccessibilityCustomAction(name: L10n.text("action.preview_item", "Preview item"), target: self, selector: #selector(previewForAccessibility)),
            NSAccessibilityCustomAction(name: L10n.text("action.remove_item", "Remove item"), target: self, selector: #selector(removeForAccessibility))
        ])
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard bounds.contains(point), let hit = super.hitTest(point) else { return nil }
        if hit === removeButton || hit.isDescendant(of: removeButton) { return hit }
        return self
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaReference { removeTrackingArea(trackingAreaReference) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(area); trackingAreaReference = area
    }
    override func mouseEntered(with event: NSEvent) { NSAnimationContext.runAnimationGroup { $0.duration = 0.12; removeButton.animator().alphaValue = 1 } }
    override func mouseExited(with event: NSEvent) { NSAnimationContext.runAnimationGroup { $0.duration = 0.12; removeButton.animator().alphaValue = 0 } }
    override func mouseDown(with event: NSEvent) { window?.makeFirstResponder(self); mouseDownPoint = convert(event.locationInWindow, from: nil); onSelect?(item, event.modifierFlags) }
    override func mouseUp(with event: NSEvent) { if event.clickCount == 2 { onQuickLook?(item) }; mouseDownPoint = nil }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 { onQuickLook?(item) }
        else if event.keyCode == 51 || event.keyCode == 117 { onRemove?(item) }
        else { super.keyDown(with: event) }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let mouseDownPoint else { return }
        let point = convert(event.locationInWindow, from: nil)
        guard hypot(point.x - mouseDownPoint.x, point.y - mouseDownPoint.y) > 4 else { return }
        self.mouseDownPoint = nil
        let contexts = dragItemsProvider?() ?? [ShelfDragItem(item: item, payloadURL: payloadURL, text: text)]
        let draggingItems = contexts.enumerated().map { index, context -> NSDraggingItem in
            let dragging = NSDraggingItem(pasteboardWriter: ShelfPasteboardWriter(payloadURL: context.payloadURL, item: context.item, text: context.text))
            let size: CGFloat = 48
            dragging.setDraggingFrame(NSRect(x: point.x - size / 2 + CGFloat(index * 3), y: point.y - size / 2 - CGFloat(index * 3), width: size, height: size), contents: NSWorkspace.shared.icon(forFile: context.payloadURL.path))
            return dragging
        }
        onDragBegan?(); beginDraggingSession(with: draggingItems, event: event, source: self)
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation { .copy }
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) { onDragEnded?(dragItemsProvider?().map(\.item) ?? [item], !operation.isEmpty) }

    override func rightMouseDown(with event: NSEvent) {
        onSelect?(item, [])
        let menu = NSMenu()
        add(menu, L10n.text("action.quick_look", "Quick Look"), #selector(quickLookPressed), key: " "); add(menu, L10n.text("action.share", "Share…"), #selector(sharePressed)); add(menu, L10n.text("action.reveal", "Show in Finder"), #selector(revealPressed)); add(menu, L10n.text("action.copy_path", "Copy path"), #selector(copyPathPressed)); menu.addItem(.separator())
        add(menu, L10n.text("action.rename", "Rename…"), #selector(renamePressed)); add(menu, L10n.text("action.create_zip", "Create ZIP"), #selector(zipPressed))
        if item.kind == .image { add(menu, L10n.text("action.resize", "Resize image…"), #selector(resizePressed)); add(menu, L10n.text("action.ocr", "Recognize text (OCR)"), #selector(ocrPressed)) }
        menu.addItem(.separator()); add(menu, L10n.text("action.move_up", "Move up"), #selector(moveUpPressed)); add(menu, L10n.text("action.move_down", "Move down"), #selector(moveDownPressed)); menu.addItem(.separator()); add(menu, L10n.text("action.remove", "Remove"), #selector(removePressed))
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
    private func add(_ menu: NSMenu, _ title: String, _ action: Selector, key: String = "") { let entry = menu.addItem(withTitle: title, action: action, keyEquivalent: key); entry.target = self }
    @objc private func removePressed() { onRemove?(item) }
    @objc private func quickLookPressed() { onQuickLook?(item) }
    @objc private func sharePressed() { onShare?(item, self) }
    @objc private func revealPressed() { onReveal?(item) }
    @objc private func copyPathPressed() { onCopyPath?(item) }
    @objc private func renamePressed() { onRename?(item) }
    @objc private func zipPressed() { onZip?(item) }
    @objc private func resizePressed() { onResize?(item) }
    @objc private func ocrPressed() { onOCR?(item) }
    @objc private func moveUpPressed() { onMove?(item, -1) }
    @objc private func moveDownPressed() { onMove?(item, 1) }
    @objc private func copyForAccessibility() -> Bool { NSPasteboard.general.clearContents(); return NSPasteboard.general.writeObjects([ShelfPasteboardWriter(payloadURL: payloadURL, item: item, text: text)]) }
    @objc private func previewForAccessibility() -> Bool { onQuickLook?(item); return true }
    @objc private func removeForAccessibility() -> Bool { onRemove?(item); return true }

    private var subtitleText: String {
        if item.kind == .folder { return L10n.text("kind.folder", "Folder") }
        let formatter = ByteCountFormatter(); formatter.countStyle = .file
        let size = item.byteCount > 0 ? formatter.string(fromByteCount: item.byteCount) : item.kind.rawValue
        return "\(item.kind.label) · \(size)"
    }
}

private final class ShelfPasteboardWriter: NSObject, NSPasteboardWriting {
    private let payloadURL: URL; private let item: ShelfItem; private let text: String?
    init(payloadURL: URL, item: ShelfItem, text: String?) { self.payloadURL = payloadURL; self.item = item; self.text = text }
    func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] { text != nil ? [.string, .fileURL] : [.fileURL] }
    func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? { switch type { case .string: return text; case .fileURL: return payloadURL.absoluteString; default: return nil } }
}

private extension ShelfItem.Kind {
    var label: String { switch self { case .file: return L10n.text("kind.file", "File"); case .folder: return L10n.text("kind.folder", "Folder"); case .text: return L10n.text("kind.text", "Text"); case .richText: return L10n.text("kind.rich_text", "Rich text"); case .image: return L10n.text("kind.image", "Image"); case .url: return L10n.text("kind.link", "Link") } }
}
