import AppKit
import Foundation
#if APP_STORE
import StoreKit
#endif

@MainActor
protocol SupportService {
    func presentSupport()
}

@MainActor
enum SupportServiceFactory {
    static func make() -> SupportService {
        #if APP_STORE
        return StoreKitSupportService()
        #else
        return ExternalSupportService()
        #endif
    }
}

@MainActor
private final class ExternalSupportService: SupportService {
    func presentSupport() {
        guard let url = URL(string: "https://getborda.app/cafe") else { return }
        NSWorkspace.shared.open(url)
    }
}

#if APP_STORE
@MainActor
private final class StoreKitSupportService: SupportService {
    private let identifiers = [
        "com.arthurfava.Borda.coffee.small",
        "com.arthurfava.Borda.coffee.medium",
        "com.arthurfava.Borda.coffee.large"
    ]

    func presentSupport() {
        Task { await purchaseCoffee() }
    }

    private func purchaseCoffee() async {
        do {
            let products = try await Product.products(for: identifiers).sorted { $0.price < $1.price }
            guard !products.isEmpty else {
                show(message: L10n.text("support.unavailable", "Support options are temporarily unavailable."))
                return
            }

            let alert = NSAlert()
            alert.messageText = L10n.text("support.title", "Support Borda")
            alert.informativeText = L10n.text("support.message", "Borda is free. If it helps your work, you can support its continued development with a coffee.")
            let selector = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 260, height: 26))
            products.forEach { selector.addItem(withTitle: "\($0.displayName) — \($0.displayPrice)") }
            alert.accessoryView = selector
            alert.addButton(withTitle: L10n.text("support.buy", "Buy a coffee"))
            alert.addButton(withTitle: L10n.text("common.cancel", "Cancel"))
            guard alert.runModal() == .alertFirstButtonReturn else { return }

            let product = products[selector.indexOfSelectedItem]
            switch try await product.purchase() {
            case .success(let verification):
                let transaction = try verification.payloadValue
                await transaction.finish()
                show(message: L10n.text("support.thanks", "Thank you for supporting Borda!"))
            case .pending:
                show(message: L10n.text("support.pending", "Your contribution is awaiting approval."))
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            show(message: error.localizedDescription)
        }
    }

    private func show(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
    }
}
#endif
