import Foundation
import CoreGraphics

@MainActor public protocol KeyboardPosting {
    func post(_ input: KeyboardInput, to processID: Int32) throws
}

@MainActor public final class KeyboardInjector: KeyboardPosting {
    public init() {}

    /// Construct both events before posting either; no task suspension between
    /// down/up. Clear physical modifier state from the synthetic events.
    public static func events(for units: [UInt16]) throws -> (CGEvent, CGEvent) {
        try events(for: .unicode(units))
    }

    public static func events(for input: KeyboardInput) throws -> (CGEvent, CGEvent) {
        let keyCode: CGKeyCode
        switch input {
        case .unicode: keyCode = 0
        case .key(let key): keyCode = key.rawValue
        }
        guard let source = CGEventSource(stateID: .privateState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else { throw InjectionError.eventCreationFailed }
        down.flags = []
        up.flags = []
        if case .unicode(let units) = input {
            units.withUnsafeBufferPointer { buffer in
                down.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
                up.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
            }
        }
        return (down, up)
    }

    public func post(_ input: KeyboardInput, to processID: Int32) throws {
        let (down, up) = try Self.events(for: input)
        // Pin the recipient to the verified Safari PID. This closes the race
        // where foreground app changes between a focus check and global post.
        down.postToPid(processID)
        up.postToPid(processID)
    }
}
