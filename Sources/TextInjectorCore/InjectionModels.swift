import Foundation

public struct InjectionOptions: Sendable {
    public var characterDelay: Duration
    public var activationDelay: Duration
    public var tabBehavior: TabBehavior

    public init(characterDelay: Duration = .milliseconds(10), activationDelay: Duration = .milliseconds(200),
                tabBehavior: TabBehavior = .key) {
        self.characterDelay = characterDelay
        self.activationDelay = activationDelay
        self.tabBehavior = tabBehavior
    }
}

public enum InjectionError: Error, LocalizedError, Equatable {
    case emptyText, permissionDenied, safariNotRunning, activationFailed
    case focusLost, eventCreationFailed, unsupportedControl, invalidDelay

    public var errorDescription: String? {
        switch self {
        case .emptyText: "請先輸入測試文字。"
        case .permissionDenied: "請在系統設定授予 TextInjector 輔助使用權限，再重新檢查。"
        case .safariNotRunning: "請先開啟 Safari，並點選測試頁的文字欄位。"
        case .activationFailed: "Safari 未能切換到前景，已停止輸入。"
        case .focusLost: "Safari 已失去焦點，已停止輸入。"
        case .eventCreationFailed: "無法建立鍵盤事件。"
        case .unsupportedControl: "文字含有不支援的控制字元（例如 Backspace、Escape 或 NUL）。可使用空格、換行與 Tab。"
        case .invalidDelay: "輸入延遲必須介於 0–50 ms，切換延遲必須介於 100–2000 ms。"
        }
    }
}

/// One extended grapheme per pacing step; split unusually large graphemes only
/// at Unicode scalar boundaries so a surrogate pair is never divided.
public enum UnicodePayload {
    public static func prepare(_ text: String) throws -> [[[UInt16]]] {
        guard !text.isEmpty else { throw InjectionError.emptyText }
        guard !text.unicodeScalars.contains(where: {
            $0.value < 0x20 || (0x7F...0x9F).contains($0.value) || $0.value == 0x2028 || $0.value == 0x2029
        }) else { throw InjectionError.unsupportedControl }
        return text.map { character in
            var chunks: [[UInt16]] = []
            var current: [UInt16] = []
            for scalar in character.unicodeScalars {
                let units = Array(String(scalar).utf16)
                if current.count + units.count > 16 {
                    chunks.append(current)
                    current = []
                }
                current.append(contentsOf: units)
            }
            if !current.isEmpty { chunks.append(current) }
            return chunks
        }
    }
}
