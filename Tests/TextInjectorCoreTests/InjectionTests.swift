import XCTest
import CoreGraphics
@testable import TextInjectorCore

final class UnicodePayloadTests: XCTestCase {
    func testUnicodeRoundTripAndScalarBoundaries() throws {
        let examples = ["Hello World", "繁體中文測試", "한국어 입력 테스트", "日本語入力", "Café", "αβγ", "😀 🚀 ❤️", "👨‍👩‍👧‍👦", "e" + String(repeating: "\u{0301}", count: 40)]
        for text in examples {
            let payloads = try UnicodePayload.prepare(text)
            XCTAssertEqual(payloads.count, text.count)
            let chunks = payloads.flatMap { $0 }
            XCTAssertTrue(chunks.allSatisfy { $0.count <= 16 && !$0.isEmpty })
            XCTAssertEqual(chunks.map { String(decoding: $0, as: UTF16.self) }.joined(), text)
        }
    }

    func testRejectsControlsBeforePartialInput() {
        for control in ["\n", "\r\n", "\t", "\u{08}", "\u{1B}", "\u{00}", "\u{7F}", "\u{85}", "\u{2028}", "\u{2029}"] {
            XCTAssertThrowsError(try UnicodePayload.prepare("Hello" + control + "World")) {
                XCTAssertEqual($0 as? InjectionError, .unsupportedControl)
            }
        }
        XCTAssertThrowsError(try UnicodePayload.prepare(""))
        XCTAssertNoThrow(try UnicodePayload.prepare("   "))
    }

    func testTenThousandCharacters() throws {
        let text = String(repeating: "😀漢한A", count: 2500)
        let payloads = try UnicodePayload.prepare(text)
        XCTAssertEqual(payloads.count, 10_000)
        XCTAssertEqual(String(decoding: payloads.flatMap { $0 }.flatMap { $0 }, as: UTF16.self), text)
    }

    @MainActor func testQuartzEventPayloadWithoutPosting() throws {
        let units = Array("Hello 世界 한😀".utf16)
        let (down, up) = try KeyboardInjector.events(for: units)
        XCTAssertEqual(down.type, .keyDown)
        XCTAssertEqual(up.type, .keyUp)
        for event in [down, up] {
            XCTAssertEqual(event.flags, [])
            var buffer = [UInt16](repeating: 0, count: 32)
            var length = 0
            event.keyboardGetUnicodeString(maxStringLength: buffer.count, actualStringLength: &length, unicodeString: &buffer)
            XCTAssertEqual(Array(buffer.prefix(length)), units)
        }
    }
}

@MainActor private final class FakePermission: PermissionChecking {
    var canPost = true
}

@MainActor private final class FakeSafari: SafariTargeting {
    var foreground = true
    var activations = 0
    var activationError: InjectionError?
    func activate() async throws -> Int32 {
        activations += 1
        if let activationError { throw activationError }
        return 42
    }
    func isForeground(processID: Int32) -> Bool { foreground && processID == 42 }
}

@MainActor private final class FakeKeyboard: KeyboardPosting {
    var payloads: [[UInt16]] = []
    var afterPost: (() -> Void)?
    func post(units: [UInt16], to processID: Int32) throws {
        XCTAssertEqual(processID, 42)
        payloads.append(units)
        afterPost?()
    }
}

final class InjectionRunnerTests: XCTestCase {
    @MainActor private func environment() -> (InjectionRunner, FakePermission, FakeSafari, FakeKeyboard) {
        let permission = FakePermission()
        let safari = FakeSafari()
        let keyboard = FakeKeyboard()
        return (InjectionRunner(permission: permission, safari: safari, keyboard: keyboard), permission, safari, keyboard)
    }

    @MainActor func testPermissionDeniedDoesNotActivateOrPost() async {
        let (runner, permission, safari, keyboard) = environment()
        permission.canPost = false
        do {
            try await runner.inject("Hello", options: .init()) { _, _ in }
            XCTFail("Expected denial")
        } catch { XCTAssertEqual(error as? InjectionError, .permissionDenied) }
        XCTAssertEqual(safari.activations, 0)
        XCTAssertTrue(keyboard.payloads.isEmpty)
    }

    @MainActor func testFocusLossStopsBeforeNextEvent() async {
        let (runner, _, safari, keyboard) = environment()
        keyboard.afterPost = { safari.foreground = false }
        do {
            try await runner.inject("Hello", options: .init(characterDelay: .zero)) { _, _ in }
            XCTFail("Expected focus loss")
        } catch { XCTAssertEqual(error as? InjectionError, .focusLost) }
        XCTAssertEqual(keyboard.payloads.count, 1)
    }

    @MainActor func testPermissionRevokedStopsBeforeNextEvent() async {
        let (runner, permission, _, keyboard) = environment()
        keyboard.afterPost = { permission.canPost = false }
        do {
            try await runner.inject("Hello", options: .init(characterDelay: .zero)) { _, _ in }
            XCTFail("Expected revocation")
        } catch { XCTAssertEqual(error as? InjectionError, .permissionDenied) }
        XCTAssertEqual(keyboard.payloads.count, 1)
    }

    @MainActor func testCancelStopsBeforeNextEvent() async {
        let (runner, _, _, keyboard) = environment()
        var task: Task<Void, Error>?
        keyboard.afterPost = { task?.cancel() }
        task = Task { try await runner.inject("Hello", options: .init(characterDelay: .zero)) { _, _ in } }
        do { try await task?.value; XCTFail("Expected cancellation") }
        catch { XCTAssertTrue(error is CancellationError) }
        XCTAssertEqual(keyboard.payloads.count, 1)
    }

    @MainActor func testCancelDuringActivationDelayPostsNothing() async {
        let (runner, _, _, keyboard) = environment()
        let task = Task { try await runner.inject("Hello", options: .init(activationDelay: .seconds(2))) { _, _ in } }
        await Task.yield()
        task.cancel()
        do { try await task.value; XCTFail("Expected cancellation") }
        catch { XCTAssertTrue(error is CancellationError) }
        XCTAssertTrue(keyboard.payloads.isEmpty)
    }

    @MainActor func testSuccessfulInjectionAndProgress() async throws {
        let (runner, _, _, keyboard) = environment()
        let text = "Hello 世界 안녕하세요 😀"
        var counts: [Int] = []
        try await runner.inject(text, options: .init(characterDelay: .zero)) { current, total in
            counts.append(current)
            XCTAssertEqual(total, text.count)
        }
        XCTAssertEqual(counts, Array(0...text.count))
        XCTAssertEqual(String(decoding: keyboard.payloads.flatMap { $0 }, as: UTF16.self), text)
    }

    @MainActor func testSafariMissingOrActivationFailedPostsNothing() async {
        for failure in [InjectionError.safariNotRunning, .activationFailed] {
            let (runner, _, safari, keyboard) = environment()
            safari.activationError = failure
            do {
                try await runner.inject("Hello", options: .init()) { _, _ in }
                XCTFail("Expected activation failure")
            } catch { XCTAssertEqual(error as? InjectionError, failure) }
            XCTAssertTrue(keyboard.payloads.isEmpty)
        }
    }

    @MainActor func testInputValidationPrecedesActivation() async {
        let (runner, _, safari, keyboard) = environment()
        do {
            try await runner.inject("Hello\nWorld", options: .init()) { _, _ in }
            XCTFail("Expected unsupported input")
        } catch { XCTAssertEqual(error as? InjectionError, .unsupportedControl) }
        XCTAssertEqual(safari.activations, 0)
        XCTAssertTrue(keyboard.payloads.isEmpty)
    }
}
