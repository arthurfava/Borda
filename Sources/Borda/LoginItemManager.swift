import Foundation
import ServiceManagement

@MainActor
final class LoginItemManager {
    enum LoginError: LocalizedError {
        case appNotInstalled

        var errorDescription: String? {
            L10n.text("login.install_required", "Keep Borda in the Applications folder to launch it with your Mac.")
        }
    }

    func apply(enabled: Bool) throws {
        guard Bundle.main.bundleURL.pathExtension == "app",
              Bundle.main.bundleURL.path.contains("/Applications/") else {
            if enabled { throw LoginError.appNotInstalled }
            return
        }
        let service = SMAppService.mainApp
        if enabled {
            if service.status == .notRegistered || service.status == .notFound {
                try service.register()
            }
        } else if service.status == .enabled || service.status == .requiresApproval {
            try service.unregister()
        }
    }

    var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    var statusText: String {
        switch SMAppService.mainApp.status {
        case .enabled: return L10n.text("login.enabled", "Enabled in macOS Login Items")
        case .requiresApproval: return L10n.text("login.approval", "Waiting for approval in System Settings › General › Login Items")
        case .notRegistered: return L10n.text("login.disabled", "Disabled")
        case .notFound: return L10n.text("login.not_found", "Borda must be in the Applications folder")
        @unknown default: return L10n.text("login.unknown", "Unknown status")
        }
    }
}
