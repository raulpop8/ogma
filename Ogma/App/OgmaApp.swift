import AppKit
import Sparkle
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
    #if !DEBUG
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
    #endif
    private var state: AppState!
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let image = NSImage(named: "MenuBarIcon") {
            image.size = NSSize(width: 22, height: 22)
            image.isTemplate = true
            statusItem.button?.image = image
        } else {
            statusItem.button?.title = "O"
        }
        statusItem.button?.toolTip = "Ogma"
        state = AppState()
        updateMenu()
        NSLog("Ogma menu bar ready")
        DispatchQueue.main.async { [weak self] in self?.showPreviousCrashNotice() }
    }

    private func showPreviousCrashNotice() {
        guard state.crashReports.hasUnacknowledgedReport else { return }
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Ogma quit unexpectedly"
        alert.informativeText = "A crash report from a previous session is available. You can review it and choose to share it to help diagnose the problem."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Review Report…")
        alert.addButton(withTitle: "Not Now")
        let response = alert.runModal()
        state.crashReports.acknowledgeLatestReport()
        if response == .alertFirstButtonReturn {
            openSettings()
            state.crashReports.reviewLatestReport()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        state?.refreshPermissionsAndMonitor()
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
        #if !DEBUG
        let updates = NSMenuItem(
            title: "Check for Updates…",
            action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
            keyEquivalent: ""
        )
        updates.target = updaterController
        menu.addItem(updates)
        #endif
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
                contentRect: NSRect(x: 0, y: 0, width: 620, height: 440),
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
