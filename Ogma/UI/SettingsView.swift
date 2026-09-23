import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: AppState

    var body: some View {
        Form {
            Section("General") {
                Toggle("Enable Ogma", isOn: Binding(
                    get: { state.isEnabled },
                    set: { state.setEnabled($0) }
                ))
                Text("Type : followed by an emoji name in another app. Use arrow keys to choose, Return to insert, and Escape to cancel.")
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
                Text("Accessibility lets Ogma detect shortcuts and insert emoji in the active app.")
                    .foregroundStyle(.secondary)
                Button("Check Permissions Again") { state.refreshPermissionsAndMonitor() }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 320)
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
