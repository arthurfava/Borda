import Carbon
import Foundation
import BordaCore

@MainActor
final class GlobalHotKeyManager {
    var onShow: (() -> Void)?
    var onCapture: (() -> Void)?
    private var references: [EventHotKeyRef?] = []
    private var handler: EventHandlerRef?

    init() {
        var specification = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, pointer in
            guard let event, let pointer else { return noErr }
            var id = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
            guard status == noErr else { return status }
            let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(pointer).takeUnretainedValue()
            Task { @MainActor in id.id == 1 ? manager.onShow?() : manager.onCapture?() }
            return noErr
        }, 1, &specification, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }

    deinit { references.forEach { if let reference = $0 { UnregisterEventHotKey(reference) } }; if let handler { RemoveEventHandler(handler) } }

    func register(preferences: BordaPreferences) {
        references.forEach { if let reference = $0 { UnregisterEventHotKey(reference) } }; references.removeAll()
        let flags: UInt32
        switch preferences.shortcutModifiers {
        case 1: flags = UInt32(controlKey | optionKey)
        case 2: flags = UInt32(controlKey | shiftKey)
        default: flags = UInt32(cmdKey | optionKey)
        }
        for (id, keyCode) in [(UInt32(1), preferences.showShortcutKeyCode), (UInt32(2), preferences.captureShortcutKeyCode)] {
            var reference: EventHotKeyRef?
            RegisterEventHotKey(keyCode, flags, EventHotKeyID(signature: 0x424F5244, id: id), GetApplicationEventTarget(), 0, &reference)
            references.append(reference)
        }
    }
}
