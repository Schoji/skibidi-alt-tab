import AppKit

// Draws the dark rounded background of the panel.
final class SwitcherBackgroundView: NSView {
    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        let bg = NSColor(calibratedRed: 0.11, green: 0.11, blue: 0.13, alpha: 0.97)
        let path = NSBezierPath(roundedRect: bounds, xRadius: 14, yRadius: 14)
        bg.setFill()
        path.fill()

        NSColor.white.withAlphaComponent(0.09).setStroke()
        path.lineWidth = 1
        path.stroke()
    }
}

// Draws just the rows — sized to full content height, placed inside a scroll view.
final class SwitcherView: NSView {
    private var entries: [AppEntry] = []
    private var typed = ""

    private let rowH: CGFloat = 52
    private let vPad: CGFloat = 12
    private let hPad: CGFloat = 16
    private let iconSize: CGFloat = 32
    private let shortcutW: CGFloat = 52

    override var isFlipped: Bool { true }
    override var isOpaque: Bool { false }

    func update(entries: [AppEntry], typed: String) {
        self.entries = entries
        self.typed = typed
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        for (i, entry) in entries.enumerated() {
            let y = vPad + CGFloat(i) * rowH
            // Only draw rows that intersect the dirty rect (perf for large lists)
            let rowRect = NSRect(x: 0, y: y, width: bounds.width, height: rowH)
            if dirtyRect.intersects(rowRect) {
                drawRow(entry: entry, y: y)
            }
        }

        if !typed.isEmpty {
            drawTypingIndicator()
        }
    }

    private func drawRow(entry: AppEntry, y: CGFloat) {
        let isExact = !typed.isEmpty && entry.shortcut == typed

        if isExact {
            let rect = NSRect(x: hPad / 2, y: y, width: bounds.width - hPad, height: rowH - 3)
            NSColor.white.withAlphaComponent(0.13).setFill()
            NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8).fill()
        }

        let midY = y + rowH / 2

        // Icon
        entry.app.icon?.draw(
            in: NSRect(x: hPad, y: midY - iconSize / 2, width: iconSize, height: iconSize),
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0,
            respectFlipped: true,
            hints: nil
        )

        let shortcutX = hPad + iconSize + 12
        let textY = midY - 9

        // Shortcut: matched part in yellow, remaining dim
        let matched = String(entry.shortcut.prefix(typed.count)).uppercased()
        let remaining = String(entry.shortcut.dropFirst(typed.count)).uppercased()
        var xOff = shortcutX

        if !matched.isEmpty {
            let s = NSAttributedString(string: matched, attributes: [
                .foregroundColor: NSColor.systemYellow,
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .bold),
            ])
            s.draw(at: NSPoint(x: xOff, y: textY))
            xOff += s.size().width
        }
        if !remaining.isEmpty {
            let color: NSColor = typed.isEmpty ? .systemYellow : NSColor(white: 0.45, alpha: 1)
            let s = NSAttributedString(string: remaining, attributes: [
                .foregroundColor: color,
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .bold),
            ])
            s.draw(at: NSPoint(x: xOff, y: textY))
        }

        // App name
        NSAttributedString(string: entry.name, attributes: [
            .foregroundColor: isExact ? NSColor.white : NSColor(white: 0.88, alpha: 1),
            .font: NSFont.systemFont(ofSize: 14, weight: isExact ? .semibold : .regular),
        ]).draw(at: NSPoint(x: shortcutX + shortcutW, y: textY))
    }

    private func drawTypingIndicator() {
        let s = NSAttributedString(string: typed.uppercased(), attributes: [
            .foregroundColor: NSColor(white: 0.35, alpha: 1),
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
        ])
        s.draw(at: NSPoint(x: bounds.width - s.size().width - hPad, y: 5))
    }
}
