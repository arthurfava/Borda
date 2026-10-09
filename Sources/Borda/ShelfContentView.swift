// THESIS: Uma caixa é um endereço vivo na borda; recusa a janela flutuante genérica.
// OWN-WORLD: Vidro nativo, conteúdo branco vibrante, azul apenas durante o gesto e geometria contínua.
// STORY: A aba informa que há conteúdo, cresce sob o ponteiro e devolve o item por arrasto.
// FIRST VIEWPORT: Uma cápsula estreita fica parcialmente fora da tela; aberta, revela uma lista limpa de 286 pt.
// FORM: Gaveta de vidro espacial, direção fixada pelo pedido do usuário; seed: user-pinned-liquid-glass.
// FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, and DESIGN.md

import AppKit
import BordaCore

enum ShelfItemAction { case quickLook, reveal, share, copyPaths, rename, zip, resize, ocr, move(Int) }
enum ShelfAction { case rename, pin(Bool), color(ShelfColor), close }

@MainActor
protocol ShelfContentViewDelegate: AnyObject {
    func shelfViewDidReceiveDrop(_ view: ShelfContentView, pasteboard: NSPasteboard) -> Bool
    func shelfViewRequestedExpansion(_ view: ShelfContentView)
    func shelfViewRequestedCollapse(_ view: ShelfContentView)
    func shelfView(_ view: ShelfContentView, requestedRemovalOf item: ShelfItem)
    func shelfViewDidBeginDraggingItem(_ view: ShelfContentView)
    func shelfView(_ view: ShelfContentView, didFinishDragging items: [ShelfItem], completed: Bool)
    func shelfView(_ view: ShelfContentView, perform action: ShelfItemAction, on items: [ShelfItem], anchor: NSView?)
    func shelfView(_ view: ShelfContentView, perform action: ShelfAction)
}

@MainActor
final class ShelfContentView: NSView {
    weak var delegate: ShelfContentViewDelegate?

    private let content = NSView()
    private let header = NSView()
    private let titleLabel = NSTextField(labelWithString: L10n.text("shelf.title", "Shelf"))
    private let countLabel = NSTextField(labelWithString: "")
    private let optionsButton = NSButton()
    private let compactIcon = NSImageView()
    private let compactCount = NSTextField(labelWithString: "")
    private let emptyLabel = NSTextField(labelWithString: L10n.text("shelf.drop_here", "Drop here"))
    private let stackView = NSStackView()
    private let scrollView = NSScrollView()
    private let messageLabel = NSTextField(wrappingLabelWithString: "")
    private var trackingAreaReference: NSTrackingArea?
    private var itemCount = 0
    private var isCollapsed = false
    private var currentSide: ShelfSide = .right
    private var glassView: NSView!
    private var displayedItems: [ShelfItem] = []
    private weak var displayedStore: ShelfStore?
    private var selectedIDs: Set<UUID> = []
    private var displayedShelf: ShelfGroup?
    private var shelfColor: ShelfColor = .neutral
    private var interactionActive = false
    private var dropTargetActive = false

    var preferredHeight: CGFloat {
        guard itemCount > 0 else { return 104 }
        return min(56 + CGFloat(min(itemCount, 5)) * 57, 341)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setCollapsed(_ collapsed: Bool, side: ShelfSide, animated: Bool = false) {
        isCollapsed = collapsed
        currentSide = side
        let expandedViews = [header, scrollView, emptyLabel]
        if collapsed {
            expandedViews.forEach { $0.alphaValue = 1 }
            header.isHidden = true
            scrollView.isHidden = true
            emptyLabel.isHidden = true
        } else {
            header.isHidden = false
            scrollView.isHidden = itemCount == 0
            emptyLabel.isHidden = itemCount > 0
            let visibleViews = expandedViews.filter { !$0.isHidden }
            if animated && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                visibleViews.forEach { $0.alphaValue = 0 }
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.10
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    visibleViews.forEach { $0.animator().alphaValue = 1 }
                }
            } else {
                visibleViews.forEach { $0.alphaValue = 1 }
            }
        }
        compactIcon.isHidden = !collapsed
        compactCount.isHidden = !collapsed
        compactIcon.alphaValue = collapsed && !interactionActive ? 0.72 : 1
        compactCount.alphaValue = collapsed && !interactionActive ? 0.82 : 1
        if #available(macOS 26.0, *), let glass = glassView as? NSGlassEffectView {
            glass.cornerRadius = collapsed ? 15 : 18
        } else {
            glassView.layer?.cornerRadius = collapsed ? 15 : 16
        }
        updateGlassAppearance()
        compactIcon.image = NSImage(
            systemSymbolName: side == .right ? "chevron.left.2" : "chevron.right.2",
            accessibilityDescription: L10n.text("shelf.open", "Open shelf")
        )
        setAccessibilityLabel(collapsed ? L10n.format("shelf.accessibility_collapsed", "Shelf on edge, %d items", itemCount) : L10n.format("shelf.accessibility_open", "Open shelf, %d items", itemCount))
        setAccessibilityHelp(collapsed ? L10n.text("shelf.accessibility_open_help", "Use Show shelves in the Borda menu to open it.") : L10n.text("shelf.accessibility_drag_help", "Drag an item to another app or use its accessibility actions."))
    }

    func setInteractionActive(_ active: Bool) {
        guard interactionActive != active else { return }
        interactionActive = active
        updateGlassAppearance()
        guard isCollapsed else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.08
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            compactIcon.animator().alphaValue = active ? 1 : 0.72
            compactCount.animator().alphaValue = active ? 1 : 0.82
        }
    }

    private func updateGlassAppearance() {
        let tint = shelfColor.glassColor
        let alpha: CGFloat
        if dropTargetActive {
            alpha = 0.16
        } else if isCollapsed {
            alpha = interactionActive ? 0.12 : 0.08
        } else {
            alpha = 0.075
        }
        let color = dropTargetActive ? NSColor.controlAccentColor : tint
        if #available(macOS 26.0, *), let glass = glassView as? NSGlassEffectView {
            glass.tintColor = color.withAlphaComponent(alpha)
        } else {
            glassView.layer?.backgroundColor = color.withAlphaComponent(alpha * 0.72).cgColor
        }
    }

    private func configure() {
        wantsLayer = true
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        registerForDraggedTypes([.fileURL, .URL, .string, .rtf, .html, .tiff, .png])
        content.translatesAutoresizingMaskIntoConstraints = false

        if #available(macOS 26.0, *) {
            let glass = NSGlassEffectView()
            glass.style = .clear
            glass.cornerRadius = 18
            glass.tintColor = nil
            glass.contentView = content
            glassView = glass
        } else {
            let fallback = NSVisualEffectView()
            fallback.material = .popover
            fallback.blendingMode = .behindWindow
            fallback.state = .active
            fallback.wantsLayer = true
            fallback.layer?.cornerRadius = 18
            fallback.layer?.masksToBounds = true
            fallback.addSubview(content)
            NSLayoutConstraint.activate([
                content.leadingAnchor.constraint(equalTo: fallback.leadingAnchor),
                content.trailingAnchor.constraint(equalTo: fallback.trailingAnchor),
                content.topAnchor.constraint(equalTo: fallback.topAnchor),
                content.bottomAnchor.constraint(equalTo: fallback.bottomAnchor)
            ])
            glassView = fallback
        }
        glassView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(glassView)
        NSLayoutConstraint.activate([
            glassView.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassView.topAnchor.constraint(equalTo: topAnchor),
            glassView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor
        countLabel.font = .systemFont(ofSize: 11, weight: .medium)
        countLabel.textColor = .secondaryLabelColor
        header.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        optionsButton.image = NSImage(systemSymbolName: "ellipsis.circle", accessibilityDescription: L10n.text("shelf.options", "Shelf options"))
        optionsButton.isBordered = false
        optionsButton.target = self
        optionsButton.action = #selector(showShelfMenu)
        optionsButton.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(titleLabel)
        header.addSubview(countLabel)
        header.addSubview(optionsButton)

        compactIcon.symbolConfiguration = .init(pointSize: 12, weight: .semibold)
        compactIcon.contentTintColor = .secondaryLabelColor
        compactIcon.translatesAutoresizingMaskIntoConstraints = false
        compactCount.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        compactCount.textColor = .labelColor
        compactCount.alignment = .center
        compactCount.translatesAutoresizingMaskIntoConstraints = false

        emptyLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.alignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        let documentView = FlippedView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: documentView.topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: documentView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: documentView.widthAnchor)
        ])
        scrollView.documentView = documentView
        documentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor).isActive = true
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.font = .systemFont(ofSize: 10.5, weight: .medium)
        messageLabel.textColor = .systemRed
        messageLabel.alignment = .center
        messageLabel.maximumNumberOfLines = 2
        messageLabel.isHidden = true
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        [header, scrollView, emptyLabel, compactIcon, compactCount, messageLabel].forEach(content.addSubview)
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            header.topAnchor.constraint(equalTo: content.topAnchor, constant: 10),
            header.heightAnchor.constraint(equalToConstant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            countLabel.trailingAnchor.constraint(equalTo: optionsButton.leadingAnchor, constant: -8),
            countLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            optionsButton.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            optionsButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            optionsButton.widthAnchor.constraint(equalToConstant: 24),
            optionsButton.heightAnchor.constraint(equalToConstant: 24),
            scrollView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -8),
            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -8),
            emptyLabel.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: content.centerYAnchor, constant: 8),
            compactIcon.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            compactIcon.centerYAnchor.constraint(equalTo: content.centerYAnchor, constant: -10),
            compactIcon.widthAnchor.constraint(equalToConstant: 18),
            compactIcon.heightAnchor.constraint(equalToConstant: 18),
            compactCount.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            compactCount.topAnchor.constraint(equalTo: compactIcon.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -8)
        ])
    }

    func display(items: [ShelfItem], shelf: ShelfGroup? = nil, store: ShelfStore) {
        displayedItems = items
        displayedStore = store
        displayedShelf = shelf
        shelfColor = shelf?.color ?? .neutral
        selectedIDs = selectedIDs.intersection(Set(items.map(\.id)))
        titleLabel.stringValue = shelf?.name ?? L10n.text("shelf.title", "Shelf")
        titleLabel.textColor = .labelColor
        itemCount = items.count
        countLabel.stringValue = items.count == 1 ? L10n.text("count.one_item", "1 item") : L10n.format("count.items", "%d items", items.count)
        compactCount.stringValue = "\(items.count)"
        stackView.arrangedSubviews.forEach { stackView.removeArrangedSubview($0); $0.removeFromSuperview() }
        for item in items.reversed() {
            let row = ShelfItemView(item: item, payloadURL: store.payloadURL(for: item), text: store.text(for: item))
            row.isSelected = selectedIDs.contains(item.id)
            row.onSelect = { [weak self] item, modifiers in self?.select(item, modifiers: modifiers) }
            row.dragItemsProvider = { [weak self] in self?.dragContexts(for: item) ?? [] }
            row.onRemove = { [weak self] item in
                guard let self else { return }
                delegate?.shelfView(self, requestedRemovalOf: item)
            }
            row.onDragBegan = { [weak self] in
                guard let self else { return }
                delegate?.shelfViewDidBeginDraggingItem(self)
            }
            row.onDragEnded = { [weak self] items, completed in
                guard let self else { return }
                delegate?.shelfView(self, didFinishDragging: items, completed: completed)
            }
            row.onQuickLook = { [weak self] item in self?.perform(.quickLook, item: item, anchor: row) }
            row.onReveal = { [weak self] item in self?.perform(.reveal, item: item, anchor: row) }
            row.onShare = { [weak self] item, anchor in self?.perform(.share, item: item, anchor: anchor) }
            row.onCopyPath = { [weak self] item in self?.perform(.copyPaths, item: item, anchor: row) }
            row.onRename = { [weak self] item in self?.perform(.rename, item: item, anchor: row) }
            row.onZip = { [weak self] item in self?.perform(.zip, item: item, anchor: row) }
            row.onResize = { [weak self] item in self?.perform(.resize, item: item, anchor: row) }
            row.onOCR = { [weak self] item in self?.perform(.ocr, item: item, anchor: row) }
            row.onMove = { [weak self] item, delta in
                guard let self else { return }
                delegate?.shelfView(self, perform: .move(delta), on: [item], anchor: row)
            }
            stackView.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        }
        setCollapsed(isCollapsed, side: currentSide)
    }

    private func select(_ item: ShelfItem, modifiers: NSEvent.ModifierFlags) {
        if modifiers.contains(.command) || modifiers.contains(.shift) {
            if selectedIDs.contains(item.id) { selectedIDs.remove(item.id) } else { selectedIDs.insert(item.id) }
        } else { selectedIDs = [item.id] }
        for case let row as ShelfItemView in stackView.arrangedSubviews { row.isSelected = selectedIDs.contains(row.item.id) }
    }

    private func chosenItems(for item: ShelfItem) -> [ShelfItem] {
        let ids = selectedIDs.contains(item.id) ? selectedIDs : [item.id]
        return displayedItems.filter { ids.contains($0.id) }
    }

    private func dragContexts(for item: ShelfItem) -> [ShelfDragItem] {
        guard let displayedStore else { return [] }
        return chosenItems(for: item).map { ShelfDragItem(item: $0, payloadURL: displayedStore.payloadURL(for: $0), text: displayedStore.text(for: $0)) }
    }

    private func perform(_ action: ShelfItemAction, item: ShelfItem, anchor: NSView?) {
        delegate?.shelfView(self, perform: action, on: chosenItems(for: item), anchor: anchor)
    }

    @objc private func showShelfMenu() {
        guard let shelf = displayedShelf else { return }
        let menu = NSMenu()
        func add(_ title: String, action: ShelfAction) {
            let item = ClosureMenuItem(title: title, action: { [weak self] in guard let self else { return }; self.delegate?.shelfView(self, perform: action) })
            menu.addItem(item)
        }
        add(L10n.text("shelf.rename", "Rename shelf…"), action: .rename)
        add(shelf.isPinned ? L10n.text("shelf.unpin", "Unpin shelf") : L10n.text("shelf.pin", "Pin shelf"), action: .pin(!shelf.isPinned))
        let colors = NSMenuItem(title: L10n.text("shelf.color", "Color"), action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        for color in ShelfColor.allCases {
            let entry = ClosureMenuItem(title: color.label, action: { [weak self] in guard let self else { return }; self.delegate?.shelfView(self, perform: .color(color)) })
            if color == shelf.color { entry.state = .on }
            submenu.addItem(entry)
        }
        colors.submenu = submenu; menu.addItem(colors); menu.addItem(.separator())
        add(L10n.text("shelf.close", "Close shelf"), action: .close)
        menu.popUp(positioning: nil, at: NSPoint(x: optionsButton.bounds.maxX, y: optionsButton.bounds.minY), in: optionsButton)
    }

    func showTransientMessage(_ message: String) {
        messageLabel.stringValue = message
        messageLabel.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in self?.messageLabel.isHidden = true }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaReference { removeTrackingArea(trackingAreaReference) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingAreaReference = area
    }

    override func mouseEntered(with event: NSEvent) { delegate?.shelfViewRequestedExpansion(self) }
    override func mouseExited(with event: NSEvent) { delegate?.shelfViewRequestedCollapse(self) }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard canRead(sender) else { return [] }
        dropTargetActive = true
        updateGlassAppearance()
        delegate?.shelfViewRequestedExpansion(self)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation { canRead(sender) ? .copy : [] }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        dropTargetActive = false
        updateGlassAppearance()
        delegate?.shelfViewRequestedCollapse(self)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool { canRead(sender) }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        dropTargetActive = false
        updateGlassAppearance()
        return delegate?.shelfViewDidReceiveDrop(self, pasteboard: sender.draggingPasteboard) ?? false
    }

    private func canRead(_ sender: NSDraggingInfo) -> Bool {
        guard !(sender.draggingSource is ShelfItemView) else { return false }
        return sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self, NSString.self, NSImage.self], options: nil)
    }
}

private final class FlippedView: NSView { override var isFlipped: Bool { true } }

private final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void
    init(title: String, action: @escaping () -> Void) {
        handler = action
        super.init(title: title, action: #selector(runAction), keyEquivalent: "")
        target = self
    }
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    @objc private func runAction() { handler() }
}

private extension ShelfColor {
    var label: String {
        switch self { case .neutral: return L10n.text("color.neutral", "Neutral"); case .blue: return L10n.text("color.blue", "Blue"); case .violet: return L10n.text("color.violet", "Violet"); case .pink: return L10n.text("color.pink", "Pink"); case .orange: return L10n.text("color.orange", "Orange"); case .green: return L10n.text("color.green", "Green") }
    }
    var glassColor: NSColor {
        switch self {
        case .neutral: return .secondaryLabelColor
        case .blue: return .systemBlue
        case .violet: return .systemPurple
        case .pink: return .systemPink
        case .orange: return .systemOrange
        case .green: return .systemGreen
        }
    }
}
