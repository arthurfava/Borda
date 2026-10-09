import Cocoa
import UniformTypeIdentifiers

/// Fonte da extensão “Guardar no Borda”. O alvo precisa ser anexado por Xcode
/// quando houver o toolchain completo e um certificado Apple Developer.
final class ShareViewController: NSViewController {
    override func loadView() { view = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 120)) }

    override func viewDidAppear() {
        super.viewDidAppear()
        importAttachments()
    }

    private func importAttachments() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { complete(); return }
        let providers = items.flatMap { $0.attachments ?? [] }
        let group = DispatchGroup()
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { value, _ in
                defer { group.leave() }
                guard let url = value as? URL else { return }
                let destination = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.copyItem(at: url, to: destination)
                var components = URLComponents(string: "borda://import")!
                components.queryItems = [URLQueryItem(name: "file", value: destination.path)]
                if let actionURL = components.url { NSWorkspace.shared.open(actionURL) }
            }
        }
        group.notify(queue: .main) { [weak self] in self?.complete() }
    }

    private func complete() { extensionContext?.completeRequest(returningItems: nil) }
}
