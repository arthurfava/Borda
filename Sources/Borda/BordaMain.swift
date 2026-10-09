import AppKit

@main
struct BordaMain {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let applicationDelegate = AppDelegate()
        application.setActivationPolicy(.accessory)
        application.delegate = applicationDelegate
        application.run()
    }
}
