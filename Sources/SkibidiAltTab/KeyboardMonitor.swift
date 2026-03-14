import AppKit
import CoreGraphics

final class KeyboardMonitor {
    private weak var switcher: AppSwitcherController?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(switcher: AppSwitcherController) {
        self.switcher = switcher
    }

    func start() {
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        // Non-capturing @convention(c) closure — accesses state only via userInfo pointer
        let cb: CGEventTapCallBack = { (_, type, event, userInfo) -> Unmanaged<CGEvent>? in
            guard let userInfo = userInfo else {
                return Unmanaged.passRetained(event)
            }
            let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(userInfo).takeUnretainedValue()
            return monitor.process(event: event)
        }

        // Retain self for the lifetime of the tap
        let retained = Unmanaged.passRetained(self)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: cb,
            userInfo: retained.toOpaque()
        )

        guard let tap = eventTap else {
            print("SkibidiAltTab: Could not create event tap — please grant Accessibility permission in System Settings.")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func process(event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags

        // Hotkey: Option + Space (keyCode 49)
        let isHotkey = keyCode == 49
            && flags.contains(.maskAlternate)
            && !flags.contains(.maskCommand)
            && !flags.contains(.maskControl)
            && !flags.contains(.maskShift)

        if isHotkey {
            DispatchQueue.main.async { [weak self] in
                self?.switcher?.toggleSwitcher()
            }
            return nil // consume
        }

        // While switcher is visible: capture all key events
        let switcherOpen = switcher?.isVisible ?? false
        if switcherOpen {
            // Let system shortcuts (Cmd+…) pass through
            if flags.contains(.maskCommand) {
                return Unmanaged.passRetained(event)
            }
            if let nsEvent = NSEvent(cgEvent: event) {
                let chars = nsEvent.charactersIgnoringModifiers ?? ""
                let kc = keyCode
                DispatchQueue.main.async { [weak self] in
                    self?.switcher?.handleKey(chars: chars, keyCode: kc)
                }
            }
            return nil // consume
        }

        return Unmanaged.passRetained(event)
    }
}
