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
        let accessibilityIsGranted = AXIsProcessTrusted()
        let postingIsGranted = CGPreflightPostEventAccess()
        if accessibilityGranted != accessibilityIsGranted {
            accessibilityGranted = accessibilityIsGranted
        }
        if postingGranted != postingIsGranted {
            postingGranted = postingIsGranted
        }
    }

    func request() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if !AXIsProcessTrusted() {
            _ = AXIsProcessTrustedWithOptions(options)
        }
        if !CGPreflightPostEventAccess() {
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
