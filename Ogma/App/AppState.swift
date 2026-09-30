import AppKit
import CoreGraphics

final class AppState: ObservableObject {
    @Published private(set) var isEnabled = true
    @Published private(set) var accessibilityGranted = false
    @Published private(set) var keyboardMonitoringReady = false

    enum KeyboardStatus: Equatable {
        case disabled
        case accessibilityRequired
        case ready
        case listenerUnavailable
    }

    var keyboardStatus: KeyboardStatus {
        if !isEnabled { return .disabled }
        if !accessibilityGranted { return .accessibilityRequired }
        return keyboardMonitoringReady ? .ready : .listenerUnavailable
    }

    private let permissions = PermissionService()
    private let accessibility = AccessibilityService()
    private let insertion = TextInsertionService()
    private let search = EmojiSearchService()
    let snippetStore = SnippetStore()
    let crashReports = CrashReportService()
    private let snippetSearch = SnippetSearchService()
    private let trigger = TriggerEngine()
    private let monitor = GlobalKeyboardMonitor()
    private let panel = SuggestionPanelController()
    private var activePID: pid_t?

    init() {
        monitor.handler = { [weak self] event in self?.handle(event) ?? false }
        monitor.onPointerDown = { [weak self] event in
            guard let self, !self.panel.containsPointerEvent(event) else { return }
            self.cancel()
        }
        panel.onSelect = { [weak self] item in self?.choose(item) }
        refreshPermissionsAndMonitor()
    }

    func setEnabled(_ value: Bool) {
        isEnabled = value
        if value { refreshPermissionsAndMonitor() }
        else {
            monitor.stop()
            keyboardMonitoringReady = false
            cancel()
        }
    }

    func refreshPermissionsAndMonitor() {
        accessibilityGranted = permissions.hasAccessibility
        if isEnabled && accessibilityGranted {
            keyboardMonitoringReady = monitor.start()
            if !keyboardMonitoringReady { NSLog("Ogma keyboard listener could not start") }
        } else {
            monitor.stop()
            keyboardMonitoringReady = false
            cancel()
        }
    }

    func requestAccessibility() {
        permissions.requestAccessibility()
        permissions.openAccessibilitySettings()
        refreshPermissionsAndMonitor()
    }

    private func handle(_ event: CGEvent) -> Bool {
        guard isEnabled else { return false }
        let flags = event.flags
        if !flags.intersection([.maskCommand, .maskControl, .maskAlternate]).isEmpty {
            if trigger.isActive { cancel() }
            return false
        }
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let key: TriggerEngine.Key
        switch keyCode {
        case 51: key = .backspace
        case 126: key = .up
        case 125: key = .down
        case 123: key = .left
        case 124: key = .right
        case 36, 76: key = .enter
        case 53: key = .escape
        default:
            var buffer = [UniChar](repeating: 0, count: 8)
            var length = 0
            event.keyboardGetUnicodeString(maxStringLength: buffer.count, actualStringLength: &length, unicodeString: &buffer)
            let text = String(utf16CodeUnits: buffer, count: length)
            key = text.isEmpty ? .other : .character(text)
        }

        let wasActive = trigger.isActive
        if !wasActive {
            guard case .character(let character) = key,
                  character == ":" || character == "/" else { return false }
        }
        guard let pid = accessibility.focusedApplicationPID(),
              pid != ProcessInfo.processInfo.processIdentifier else { cancel(); return false }
        if wasActive && pid != activePID { cancel(); return false }
        if accessibility.isSecureField() { cancel(); return false }
        let outcome = trigger.handle(key)
        if !wasActive && trigger.isActive { activePID = pid }
        switch outcome {
        case .updated(let mode, let query):
            let results: [SuggestionItem]
            switch mode {
            case .emoji:
                results = search.search(query, limit: search.items.count).map(SuggestionItem.emoji)
            case .snippet:
                let saved = snippetSearch.search(query, in: snippetStore.snippets.filter { $0.trigger != "date" })
                    .map(SuggestionItem.snippet)
                results = "date".contains(query) ? [.date] + saved : saved
            }
            panel.update(results, caretRect: accessibility.caretRect())
            return false
        case .navigate(let direction):
            guard panel.hasResults else { cancel(); return false }
            panel.moveSelection(direction)
            return true
        case .navigateHorizontal(let direction):
            guard panel.hasResults else { cancel(); return false }
            panel.moveSelection(direction, horizontal: true)
            return true
        case .accept:
            guard let item = panel.selectedItem else { cancel(); return false }
            choose(item)
            return true
        case .cancelled(let consume):
            panel.hide()
            activePID = nil
            return consume
        case .none: return false
        }
    }

    private func cancel() {
        trigger.reset()
        activePID = nil
        panel.hide()
    }

    private func choose(_ item: SuggestionItem) {
        guard trigger.isActive else { return }
        let length = trigger.typedLength
        cancel()
        _ = insertion.replaceTrigger(length: length, with: item.insertionText)
    }
}
