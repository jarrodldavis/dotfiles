import AppKit
import IOKit.pwr_mgt

final class CaffeinateApp: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var assertionID: IOPMAssertionID?

    private lazy var contextMenu: NSMenu = {
        let menu = NSMenu()
        menu.delegate = self
        let quit = menu.addItem(withTitle: "Quit Caffeinate", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        return menu
    }()

    func start() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(clicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        updateIcon()
    }

    @objc private func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            // Let AppKit present the menu as a native status-bar menu.
            statusItem.menu = contextMenu
            statusItem.button?.performClick(nil)
        } else {
            toggle()
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        // Restore the button's click action after menu tracking has ended.
        DispatchQueue.main.async { [self] in
            statusItem.menu = nil
        }
    }

    private func toggle() {
        if let id = assertionID {
            let result = IOPMAssertionRelease(id)
            guard result == kIOReturnSuccess else {
                NSLog("Unable to release display sleep assertion: %d", result)
                return
            }
            assertionID = nil
        } else {
            var id: IOPMAssertionID = 0
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertionTypeNoDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "Caffeinate Menu Bar" as CFString,
                &id
            )
            guard result == kIOReturnSuccess else {
                NSLog("Unable to prevent display sleep: %d", result)
                return
            }
            assertionID = id
        }
        updateIcon()
    }

    private func updateIcon() {
        let enabled = assertionID != nil
        let symbol = enabled ? "cup.and.saucer.fill" : "cup.and.saucer"
        statusItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Caffeinate")
        statusItem.button?.toolTip = enabled ? "Caffeinate: Enabled" : "Caffeinate: Disabled"
    }

    @objc private func quit() {
        if let id = assertionID {
            IOPMAssertionRelease(id)
            assertionID = nil
        }
        NSApp.terminate(nil)
    }
}

let application = NSApplication.shared
application.setActivationPolicy(.accessory)
let caffeinate = CaffeinateApp()
caffeinate.start()
application.run()
