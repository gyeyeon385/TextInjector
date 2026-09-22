import AppKit
#if canImport(TextInjectorCore)
import TextInjectorCore
#endif

@MainActor final class SafariManager: SafariTargeting {
    static let bundleID = "com.apple.Safari"

    func activate() async throws -> Int32 {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleID)
            .first(where: { !$0.isTerminated }) else { throw InjectionError.safariNotRunning }
        guard app.activate(options: [.activateAllWindows]) else { throw InjectionError.activationFailed }
        return app.processIdentifier
    }

    func isForeground(processID: Int32) -> Bool {
        guard let app = NSWorkspace.shared.frontmostApplication else { return false }
        return app.bundleIdentifier == Self.bundleID && app.processIdentifier == processID
    }

    func openFixture() {
        guard let url = Bundle.main.url(forResource: "safari-input", withExtension: "html"),
              let safari = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.bundleID) else { return }
        NSWorkspace.shared.open([url], withApplicationAt: safari,
                                configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    }
}
