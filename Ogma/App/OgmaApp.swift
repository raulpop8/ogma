import AppKit
import SwiftUI

@main
enum OgmaMain {
    private static let delegate = OgmaAppDelegate()

    static func main() {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        application.delegate = delegate
        application.run()
    }
}

final class OgmaAppDelegate: NSObject, NSApplicationDelegate {
    private var state: AppState!
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        state = AppState()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let image = NSImage(systemSymbolName: "text.cursor", accessibilityDescription: "Ogma") {
            image.isTemplate = true
            statusItem.button?.image = image
        } else {
            statusItem.button?.title = "O"
        }
        statusItem.button?.toolTip = "Ogma"
        updateMenu()
        NSLog("Ogma menu bar ready")
    }

    private func updateMenu() {
        let menu = NSMenu()
        let toggle = NSMenuItem(title: "Enable Ogma", action: #selector(toggleEnabled), keyEquivalent: "")
        toggle.target = self
        toggle.state = state.isEnabled ? .on : .off
        menu.addItem(toggle)
        menu.addItem(.separator())
        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Ogma", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
    }

    @objc private func toggleEnabled() {
        state.setEnabled(!state.isEnabled)
        updateMenu()
    }

    @objc private func openSettings() {
        state.refreshPermissionsAndMonitor()
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 440, height: 320),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Ogma Settings"
            window.contentView = NSHostingView(rootView: SettingsView(state: state))
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func quitApp() { NSApp.terminate(nil) }
}
