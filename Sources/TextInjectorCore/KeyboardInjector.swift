import Foundation
import CoreGraphics

@MainActor public protocol KeyboardPosting {
    func post(units: [UInt16], to processID: Int32) throws
}

@MainActor public final class KeyboardInjector: KeyboardPosting {
    public init() {}

    /// Construct both events before posting either; no task suspension between
    /// down/up. Clear physical modifier state from the synthetic events.
    public static func events(for units: [UInt16]) throws -> (CGEvent, CGEvent) {
        guard let source = CGEventSource(stateID: .privateState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        else { throw InjectionError.eventCreationFailed }
        down.flags = []
        up.flags = []
        units.withUnsafeBufferPointer { buffer in
            down.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
            up.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
        }
        return (down, up)
    }

    public func post(units: [UInt16], to processID: Int32) throws {
        let (down, up) = try Self.events(for: units)
        // Pin the recipient to the verified Safari PID. This closes the race
        // where foreground app changes between a focus check and global post.
        down.postToPid(processID)
        up.postToPid(processID)
    }
}
