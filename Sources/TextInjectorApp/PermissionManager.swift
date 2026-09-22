import AppKit
@preconcurrency import ApplicationServices
import CoreGraphics
#if canImport(TextInjectorCore)
import TextInjectorCore
#endif

@MainActor final class PermissionManager: ObservableObject, PermissionChecking {
    @Published private(set) var accessibilityGranted = false
    @Published private(set) var postingGranted = false

    var canPost: Bool { AXIsProcessTrusted() && CGPreflightPostEventAccess() }

    init() { refresh() }

    func refresh() {
        accessibilityGranted = AXIsProcessTrusted()
        postingGranted = CGPreflightPostEventAccess()
    }

    func request() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        if AXIsProcessTrusted() && !CGPreflightPostEventAccess() {
            _ = CGRequestPostEventAccess()
        }
        refresh()
    }

    func openSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
