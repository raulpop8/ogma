import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: AppState
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("emojiPickerLayout") private var emojiPickerLayout = EmojiPickerLayout.grid.rawValue

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
                    Text("Emoji and text shortcuts").foregroundStyle(.secondary)
                }
            }
            Section("General") {
                Toggle("Enable Ogma", isOn: Binding(
                    get: { state.isEnabled },
                    set: { state.setEnabled($0) }
                ))
                Text("Type : for emoji or / for a saved text shortcut. Use arrow keys to choose, Return to insert, and Escape to cancel.")
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
                    Text(state.keyboardMonitoringReady ? "Ready" : "Unavailable")
                        .foregroundStyle(state.keyboardMonitoringReady ? .green : .secondary)
                }
                Text("Accessibility lets Ogma detect shortcuts and insert text in the active app.")
                    .foregroundStyle(.secondary)
                Button("Check Permissions Again") { state.refreshPermissionsAndMonitor() }
            }
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
}
