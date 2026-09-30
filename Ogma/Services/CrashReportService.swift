import Combine
import Foundation

enum AppVersion {
    static var display: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
}

final class CrashReportService: ObservableObject {
    struct Report: Identifiable {
        let id: String
        let url: URL
        let date: Date
    }

    @Published private(set) var latestReport: Report?
    @Published private(set) var reportText = ""
    @Published var isReviewingReport = false
    @Published var errorMessage: String?

    private let directory: URL
    private let defaults: UserDefaults
    private let acknowledgmentKey = "lastAcknowledgedCrashDate"
    private var attachments: [URL] = []

    init(directory: URL? = nil, defaults: UserDefaults = .standard) {
        self.directory = directory ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/DiagnosticReports", isDirectory: true)
        self.defaults = defaults
        refresh()
    }

    var hasUnacknowledgedReport: Bool {
        guard let latestReport else { return false }
        let acknowledged = defaults.object(forKey: acknowledgmentKey) as? Double
            ?? Date.now.addingTimeInterval(-7 * 24 * 60 * 60).timeIntervalSince1970
        return latestReport.date.timeIntervalSince1970 > acknowledged
    }

    func acknowledgeLatestReport() {
        guard let latestReport else { return }
        defaults.set(latestReport.date.timeIntervalSince1970, forKey: acknowledgmentKey)
    }

    func refresh() {
        guard FileManager.default.fileExists(atPath: directory.path) else {
            latestReport = nil
            return
        }
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: directory,
                includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey])
            latestReport = urls.compactMap(Self.readReport)
                .max { $0.date < $1.date }
        } catch {
            errorMessage = "Crash reports could not be read: \(error.localizedDescription)"
        }
    }

    // Check the report's identity, since a filename alone does not identify the app.
    private static func readReport(at url: URL) -> Report? {
        guard url.lastPathComponent.hasPrefix("Ogma"),
              ["ips", "crash"].contains(url.pathExtension),
              let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
              values.isRegularFile == true,
              let date = values.contentModificationDate,
              let file = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? file.close() }
        guard let header = try? file.read(upToCount: 16_384) else { return nil }
        if url.pathExtension == "ips" {
            let firstLine = header.prefix { $0 != 10 }
            guard let metadata = try? JSONSerialization.jsonObject(with: Data(firstLine)) as? [String: Any],
                  metadata["bundleID"] as? String == "com.raulpop.Ogma",
                  metadata["bug_type"] as? String == "309" else { return nil }
            return Report(id: metadata["incident_id"] as? String ?? url.lastPathComponent, url: url, date: date)
        }
        guard let text = String(data: header, encoding: .utf8),
              text.components(separatedBy: .newlines).contains(where: {
                  $0.hasPrefix("Identifier:") && $0.dropFirst("Identifier:".count)
                      .trimmingCharacters(in: .whitespaces) == "com.raulpop.Ogma"
              }) else { return nil }
        return Report(id: url.lastPathComponent, url: url, date: date)
    }

    func reviewLatestReport() {
        refresh()
        guard let latestReport else {
            errorMessage = "No Ogma crash report was found on this Mac."
            return
        }
        do {
            let log = try String(contentsOf: latestReport.url, encoding: .utf8)
            reportText = """
            Ogma crash report
            Current app version: \(AppVersion.display)
            macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
            Report file: \(latestReport.url.lastPathComponent)

            \(log)
            """
            acknowledgeLatestReport()
            isReviewingReport = true
        } catch {
            errorMessage = "The crash report could not be opened: \(error.localizedDescription)"
        }
    }

    func makeAttachment() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        attachments.append(folder)
        let url = folder.appendingPathComponent("Ogma-crash-report.txt")
        try reportText.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    deinit {
        for folder in attachments { try? FileManager.default.removeItem(at: folder) }
    }
}
