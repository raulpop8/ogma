import Foundation

@main
struct CrashReportTests {
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let suite = "OgmaCrashReportTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer {
            try? FileManager.default.removeItem(at: directory)
            defaults.removePersistentDomain(forName: suite)
        }
        let service = CrashReportService(directory: directory, defaults: defaults)
        assert(service.latestReport == nil)
        assert(!service.hasUnacknowledgedReport)

        let valid = directory.appendingPathComponent("Ogma-valid.ips")
        try """
        {"bundleID":"com.raulpop.Ogma","bug_type":"309","incident_id":"ogma-crash"}
        {"exception":{"type":"EXC_BREAKPOINT"}}
        """.write(to: valid, atomically: true, encoding: .utf8)
        let unrelated = directory.appendingPathComponent("Ogma-unrelated.ips")
        try """
        {"bundleID":"com.example.OtherApp","bug_type":"309"}
        {}
        """.write(to: unrelated, atomically: true, encoding: .utf8)
        let nonCrash = directory.appendingPathComponent("Ogma-diagnostic.ips")
        try """
        {"bundleID":"com.raulpop.Ogma","bug_type":"298"}
        {}
        """.write(to: nonCrash, atomically: true, encoding: .utf8)
        service.refresh()
        assert(service.latestReport?.id == "ogma-crash")
        assert(service.hasUnacknowledgedReport)
        service.reviewLatestReport()
        assert(service.isReviewingReport)
        assert(service.reportText.contains("EXC_BREAKPOINT"))
        assert(!service.hasUnacknowledgedReport)
        let attachment = try service.makeAttachment()
        let attachedText = try String(contentsOf: attachment, encoding: .utf8)
        assert(attachedText == service.reportText)
        let restarted = CrashReportService(directory: directory, defaults: defaults)
        assert(!restarted.hasUnacknowledgedReport)

        let legacy = directory.appendingPathComponent("Ogma-legacy.crash")
        try "Process: Ogma\nIdentifier: com.raulpop.Ogma\nException Type: EXC_BAD_ACCESS\n"
            .write(to: legacy, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.modificationDate: Date.now.addingTimeInterval(2)], ofItemAtPath: legacy.path)
        restarted.refresh()
        assert(restarted.latestReport?.id == legacy.lastPathComponent)
        assert(restarted.hasUnacknowledgedReport)
        print("Crash report checks passed")
    }
}
