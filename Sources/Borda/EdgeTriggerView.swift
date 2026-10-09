import AppKit
import BordaCore

@MainActor
protocol EdgeTriggerViewDelegate: AnyObject {
    func edgeTriggerUpdated(at screenPoint: NSPoint, on screen: NSScreen, side: ShelfSide)
    func edgeTriggerExited()
    func edgeTriggerDidReceiveDrop(_ pasteboard: NSPasteboard, at screenPoint: NSPoint, on screen: NSScreen, side: ShelfSide) -> Bool
}

@MainActor
final class EdgeTriggerView: NSView {
    weak var delegate: EdgeTriggerViewDelegate?
    let side: ShelfSide

    init(side: ShelfSide) {
        self.side = side
        super.init(frame: .zero)
        setAccessibilityElement(false)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.001).cgColor
        registerForDraggedTypes([.fileURL, .URL, .string, .rtf, .html, .tiff, .png])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        debug("entered")
        return update(sender)
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation { update(sender) }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        debug("exited")
        delegate?.edgeTriggerExited()
    }
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool { canAccept(sender) }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        debug("drop")
        guard canAccept(sender), let window, let screen = window.screen else { return false }
        return delegate?.edgeTriggerDidReceiveDrop(
            sender.draggingPasteboard,
            at: window.convertPoint(toScreen: sender.draggingLocation),
            on: screen,
            side: side
        ) ?? false
    }

    private func update(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard canAccept(sender), let window, let screen = window.screen else { return [] }
        delegate?.edgeTriggerUpdated(
            at: window.convertPoint(toScreen: sender.draggingLocation),
            on: screen,
            side: side
        )
        return .copy
    }

    private func canAccept(_ sender: NSDraggingInfo) -> Bool {
        guard !(sender.draggingSource is ShelfItemView) else { return false }
        return sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self, NSString.self, NSImage.self], options: nil)
    }

    private func debug(_ event: String) {
        guard ProcessInfo.processInfo.environment["BORDA_DEBUG_EDGE"] == "1" else { return }
        FileHandle.standardError.write(Data("BORDA_EDGE \(side.rawValue) \(event)\n".utf8))
    }
}

final class EdgeTriggerPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
