import Foundation

@MainActor public protocol PermissionChecking {
    var canPost: Bool { get }
}

@MainActor public protocol SafariTargeting {
    func activate() async throws -> Int32
    func isForeground(processID: Int32) -> Bool
}

@MainActor public struct InjectionRunner {
    private let permission: any PermissionChecking
    private let safari: any SafariTargeting
    private let keyboard: any KeyboardPosting

    public init(permission: any PermissionChecking, safari: any SafariTargeting, keyboard: any KeyboardPosting) {
        self.permission = permission
        self.safari = safari
        self.keyboard = keyboard
    }

    public func inject(_ text: String, options: InjectionOptions,
                       progress: (Int, Int) -> Void) async throws {
        try Task.checkCancellation()
        guard options.characterDelay >= .zero, options.characterDelay <= .milliseconds(50),
              options.activationDelay >= .milliseconds(100), options.activationDelay <= .seconds(2)
        else { throw InjectionError.invalidDelay }
        // Validate the entire input before activating Safari or sending any event.
        let payloads = try UnicodePayload.prepare(text)
        guard permission.canPost else { throw InjectionError.permissionDenied }
        let pid = try await safari.activate()
        try await Task.sleep(for: options.activationDelay)
        guard safari.isForeground(processID: pid) else { throw InjectionError.activationFailed }
        progress(0, payloads.count)
        for (index, chunks) in payloads.enumerated() {
            for chunk in chunks {
                try Task.checkCancellation()
                guard permission.canPost else { throw InjectionError.permissionDenied }
                guard safari.isForeground(processID: pid) else { throw InjectionError.focusLost }
                try keyboard.post(units: chunk, to: pid)
            }
            progress(index + 1, payloads.count)
            // One task for the whole operation. Even zero-delay input yields so
            // Stop, workspace notifications and UI updates can be processed.
            if options.characterDelay > .zero {
                try await Task.sleep(for: options.characterDelay)
            } else {
                await Task.yield()
            }
        }
        try Task.checkCancellation()
    }
}
