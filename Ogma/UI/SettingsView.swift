import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: AppState
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("emojiPickerLayout") private var emojiPickerLayout = EmojiPickerLayout.grid.rawValue
    @AppStorage(DateDisplayFormat.preferenceKey) private var dateDisplayFormat = DateDisplayFormat.systemShort.rawValue

    var body: some View {
        TabView {
            general
                .tabItem { Label("General", systemImage: "gearshape") }
            SnippetsSettingsView(store: state.snippetStore)
                .tabItem { Label("Shortcuts", systemImage: "text.quote") }
        }
        .frame(width: 620, height: 440)
    }

    private var general: some View {
        Form {
            HStack(spacing: 12) {
                Image(colorScheme == .dark ? "PrimaryDark" : "PrimaryLight")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 48, height: 48)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ogma").font(.headline)
                    Text("Version \(AppVersion.display)").font(.caption).foregroundStyle(.secondary)
                    Text("Emoji and text shortcuts").foregroundStyle(.secondary)
                }
            }
            Section("General") {
                Toggle("Enable Ogma", isOn: Binding(
                    get: { state.isEnabled },
                    set: { state.setEnabled($0) }
                ))
                Text("Type : for emoji, /date for today’s date, or / for a saved text shortcut. Use arrow keys to choose, Return to insert, and Escape to cancel.")
                    .foregroundStyle(.secondary)
            }
            Section("Date shortcut") {
                Picker("Display", selection: $dateDisplayFormat) {
                    ForEach(DateDisplayFormat.allCases, id: \.rawValue) { format in
                        Text("\(format.title) · \(format.display())").tag(format.rawValue)
                    }
                }
                Text("Type /date and press Return to insert today’s date in the selected format.")
                    .foregroundStyle(.secondary)
            }
            Section("Emoji picker") {
                Picker("Display", selection: $emojiPickerLayout) {
                    ForEach(EmojiPickerLayout.allCases, id: \.rawValue) { layout in
                        Text(layout.title).tag(layout.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                Text("Type : to browse emoji. Scroll for more, or type a name to narrow the choices.")
                    .foregroundStyle(.secondary)
            }
            Section("Permissions") {
                permissionRow("Accessibility", granted: state.accessibilityGranted) {
                    state.requestAccessibility()
                }
                HStack {
                    Text("Keyboard listener")
                    Spacer()
                    Text(keyboardStatusTitle)
                        .foregroundStyle(state.keyboardMonitoringReady ? .green : .secondary)
                }
                Text(keyboardStatusDescription)
                    .foregroundStyle(.secondary)
                if state.keyboardStatus == .listenerUnavailable {
                    Text("Quit and reopen Ogma. If this continues, restart your Mac and check Accessibility access again.")
                        .foregroundStyle(.secondary)
                }
                Button("Check Again") { state.refreshPermissionsAndMonitor() }
                    .disabled(state.keyboardStatus == .disabled)
            }
            CrashReportSettingsView(service: state.crashReports)
        }
        .formStyle(.grouped)
    }

    private func permissionRow(_ title: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(granted ? "Granted" : "Required")
                .foregroundStyle(granted ? .green : .secondary)
            if !granted { Button("Open Settings", action: action) }
        }
    }

    private var keyboardStatusTitle: String {
        switch state.keyboardStatus {
        case .disabled: "Off"
        case .accessibilityRequired: "Needs access"
        case .ready: "Ready"
        case .listenerUnavailable: "Could not start"
        }
    }

    private var keyboardStatusDescription: String {
        switch state.keyboardStatus {
        case .disabled:
            "Turn on Ogma to listen for shortcuts while you type."
        case .accessibilityRequired:
            "Ogma needs Accessibility access to detect shortcuts and insert text in the active app. Choose Open Settings, enable Ogma, then return here and choose Check Again."
        case .ready:
            "Ogma can detect shortcuts and insert text in the active app."
        case .listenerUnavailable:
            "Accessibility access is granted, but Ogma could not start its keyboard listener. Choose Check Again to retry."
        }
    }
}
