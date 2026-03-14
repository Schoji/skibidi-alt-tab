import AppKit

struct AppEntry {
    let app: NSRunningApplication
    let shortcut: String
    let name: String
}

final class AppSwitcherController {
    private(set) var isVisible = false

    private var panel: NSPanel?
    private var scrollView: NSScrollView?
    private var switcherView: SwitcherView?
    private var clickMonitor: Any?

    private var allEntries: [AppEntry] = []
    private var typed = ""

    // MARK: - Public interface

    func toggleSwitcher() {
        isVisible ? dismiss() : show()
    }

    func handleKey(chars: String, keyCode: UInt16) {
        guard isVisible else { return }

        switch keyCode {
        case 53: // ESC
            dismiss()

        case 51: // Backspace
            if !typed.isEmpty {
                typed.removeLast()
                refresh()
            }

        default:
            let c = chars.lowercased()
            guard !c.isEmpty,
                  c.unicodeScalars.allSatisfy({ CharacterSet.letters.union(.decimalDigits).contains($0) })
            else { return }

            let candidate = typed + c

            // Exact match → switch immediately
            if let match = allEntries.first(where: { $0.shortcut == candidate }) {
                activate(app: match.app)
                return
            }

            // Still possible matches → accept input
            if allEntries.contains(where: { $0.shortcut.hasPrefix(candidate) }) {
                typed = candidate
                refresh()
            }
            // No matches → ignore keystroke
        }
    }

    // MARK: - Show / Dismiss

    private func show() {
        let apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.isFinishedLaunching }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }

        let shortcuts = ShortcutAssigner.assign(apps: apps)
        allEntries = apps.compactMap { app in
            guard let s = shortcuts[app.processIdentifier] else { return nil }
            return AppEntry(app: app, shortcut: s, name: app.localizedName ?? "?")
        }
        typed = ""

        ensurePanel()
        refresh()

        isVisible = true
        panel?.orderFrontRegardless()
        addClickMonitor()
    }

    private func dismiss() {
        isVisible = false
        typed = ""
        panel?.orderOut(nil)
        removeClickMonitor()
    }

    private func activate(app: NSRunningApplication) {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            guard let url = app.bundleURL else { return }
            // openApplication is the most reliable way to bring any app to front
            // from a background/accessory process (works even when SkibidiAltTab has no focus)
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in }
        }
    }

    // MARK: - Panel setup

    private let panelW: CGFloat = 440
    private let maxPanelH: CGFloat = 560
    private let rowH: CGFloat = 52
    private let vPad: CGFloat = 12

    private func ensurePanel() {
        guard panel == nil else { return }

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelW, height: maxPanelH),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.level = .floating
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Background layer (draws rounded dark rect)
        let bg = SwitcherBackgroundView(frame: NSRect(x: 0, y: 0, width: panelW, height: maxPanelH))
        bg.autoresizingMask = [.width, .height]

        // Scroll view clipped to the same rounded corners
        let sv = NSScrollView(frame: bg.bounds)
        sv.autoresizingMask = [.width, .height]
        sv.borderType = .noBorder
        sv.drawsBackground = false
        sv.hasVerticalScroller = true
        sv.autohidesScrollers = true
        sv.scrollerStyle = .overlay
        sv.wantsLayer = true
        sv.layer?.cornerRadius = 14
        sv.layer?.masksToBounds = true

        let rows = SwitcherView(frame: NSRect(x: 0, y: 0, width: panelW, height: maxPanelH))
        sv.documentView = rows

        bg.addSubview(sv)
        p.contentView = bg

        panel = p
        scrollView = sv
        switcherView = rows
    }

    private func refresh() {
        let visible = allEntries.filter { $0.shortcut.hasPrefix(typed) }

        let contentH = CGFloat(visible.count) * rowH + vPad * 2
        let panelH = min(contentH, maxPanelH)

        // Resize panel
        if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            let x = sf.minX + (sf.width - panelW) / 2
            let y = sf.minY + (sf.height - panelH) / 2
            panel?.setFrame(NSRect(x: x, y: y, width: panelW, height: panelH), display: false)
        }

        // Resize rows view to full content height so scroll works
        switcherView?.frame = NSRect(x: 0, y: 0, width: panelW, height: contentH)
        switcherView?.update(entries: visible, typed: typed)

        // Scroll to top whenever content refreshes
        scrollView?.contentView.scroll(to: .zero)
        scrollView?.reflectScrolledClipView(scrollView!.contentView)
    }

    // MARK: - Click-outside monitor

    private func addClickMonitor() {
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.dismiss()
        }
    }

    private func removeClickMonitor() {
        if let m = clickMonitor {
            NSEvent.removeMonitor(m)
            clickMonitor = nil
        }
    }
}
