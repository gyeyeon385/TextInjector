import AppKit
#if canImport(TextInjectorCore)
import TextInjectorCore
#endif

@MainActor final class BrowserManager: BrowserTargeting {
    func activate(_ browser: InjectionBrowser) async throws -> Int32 {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: browser.bundleIdentifier)
            .first(where: { !$0.isTerminated }) else { throw InjectionError.browserNotRunning(browser) }
        guard app.activate(options: [.activateAllWindows]) else { throw InjectionError.activationFailed(browser) }
        return app.processIdentifier
    }

    func isForeground(_ browser: InjectionBrowser, processID: Int32) -> Bool {
        guard let app = NSWorkspace.shared.frontmostApplication else { return false }
        return app.bundleIdentifier == browser.bundleIdentifier && app.processIdentifier == processID
    }

    func openFixture(for browser: InjectionBrowser) {
        guard let url = Bundle.main.url(forResource: "browser-input", withExtension: "html"),
              let application = NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleIdentifier) else { return }
        NSWorkspace.shared.open([url], withApplicationAt: application,
                                configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    }
}
