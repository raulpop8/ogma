import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct CrashReportSettingsView: View {
    @ObservedObject var service: CrashReportService

    var body: some View {
        Section("Crash reports") {
            Button("Review Crash Report…") { service.reviewLatestReport() }
            Text("Review the latest crash log, then save it or share it as an attachment. Reports are only shared when you choose to send them.")
                .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $service.isReviewingReport) {
            CrashReportView(service: service)
        }
        .alert("Crash Report", isPresented: Binding(
            get: { service.errorMessage != nil },
            set: { if !$0 { service.errorMessage = nil } }
        )) {
            Button("OK") { service.errorMessage = nil }
        } message: {
            Text(service.errorMessage ?? "")
        }
    }
}

private struct CrashReportView: View {
    @ObservedObject var service: CrashReportService
    @Environment(\.dismiss) private var dismiss
    @State private var saveError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review Crash Report").font(.title2.bold())
            Text("Includes app and macOS details and crash stack traces. It may contain file paths. Review it before sharing.")
                .foregroundStyle(.secondary)
            ScrollView([.vertical, .horizontal]) {
                Text(service.reportText)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
            HStack {
                Button("Save Report…", action: saveReport)
                CrashReportShareButton(service: service, onError: { saveError = $0 })
                    .frame(width: 110, height: 24)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 680, height: 500)
        .alert("Crash Report", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    private func saveReport() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Ogma-crash-report.txt"
        panel.allowedContentTypes = [.plainText]
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do { try service.reportText.write(to: url, atomically: true, encoding: .utf8) }
            catch { saveError = error.localizedDescription }
        }
    }
}

private struct CrashReportShareButton: NSViewRepresentable {
    let service: CrashReportService
    let onError: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(service: service, onError: onError) }

    func makeNSView(context: Context) -> NSButton {
        NSButton(title: "Share Report…", target: context.coordinator, action: #selector(Coordinator.share(_:)))
    }

    func updateNSView(_ button: NSButton, context: Context) {}

    final class Coordinator: NSObject {
        private let service: CrashReportService
        private let onError: (String) -> Void
        private var picker: NSSharingServicePicker?

        init(service: CrashReportService, onError: @escaping (String) -> Void) {
            self.service = service
            self.onError = onError
        }

        @objc func share(_ sender: NSButton) {
            do {
                let url = try service.makeAttachment()
                let picker = NSSharingServicePicker(items: [url])
                self.picker = picker
                picker.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            } catch {
                onError("The crash report attachment could not be created: \(error.localizedDescription)")
            }
        }
    }
}
