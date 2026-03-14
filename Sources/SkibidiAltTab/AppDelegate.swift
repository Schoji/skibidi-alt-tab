import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var keyMonitor: KeyboardMonitor!
    private var switcher: AppSwitcherController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Only prompt for Accessibility if not already granted
        if !AXIsProcessTrusted() {
            let opts = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(opts)
        }

        // Menu bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let icon = NSImage(named: "AppIcon") {
            icon.size = NSSize(width: 18, height: 18)
            statusItem.button?.image = icon
        } else {
            statusItem.button?.title = "⌘"
        }
        let menu = NSMenu()
        menu.addItem(withTitle: "SkibidiAltTab — hotkey: ⌥Space", action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu

        switcher = AppSwitcherController()
        keyMonitor = KeyboardMonitor(switcher: switcher)
        keyMonitor.start()
    }
}
