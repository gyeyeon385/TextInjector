import Foundation

public enum TabBehavior: String, CaseIterable, Sendable {
    case key, fourSpaces
}

public enum SpecialKey: UInt16, Sendable {
    // macOS HIToolbox virtual key codes: kVK_Return and kVK_Tab.
    case enter = 0x24
    case tab = 0x30
}

public enum KeyboardInput: Equatable, Sendable {
    case unicode([UInt16])
    case key(SpecialKey)
}

public enum InputToken: Equatable, Sendable {
    case text(String)
    case enter
    case tab
}

public enum InputTokenizer {
    /// Never trim whitespace or interpret backslash escape notation. CRLF is
    /// one Swift Character and becomes exactly one Return, as do CR and LF.
    public static func tokenize(_ text: String) throws -> [InputToken] {
        guard !text.isEmpty else { throw InjectionError.emptyText }
        return try text.map { character in
            switch String(character) {
            case "\r\n", "\r", "\n", "\u{0085}", "\u{2028}", "\u{2029}": return .enter
            case "\t": return .tab
            default:
                // Validate all text before the runner activates Safari.
                _ = try UnicodePayload.prepare(String(character))
                return .text(String(character))
            }
        }
    }

    /// Each outer element represents one source Character for progress.
    public static func prepare(_ text: String, tabBehavior: TabBehavior) throws -> [[KeyboardInput]] {
        try tokenize(text).map { token in
            switch token {
            case .enter: return [.key(.enter)]
            case .tab:
                return tabBehavior == .key ? [.key(.tab)] : Array(repeating: .unicode([0x20]), count: 4)
            case .text(let value):
                return try UnicodePayload.prepare(value).flatMap { $0 }.map(KeyboardInput.unicode)
            }
        }
    }
}
