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
    var inputs: [KeyboardInput] = []
    var times: [ContinuousClock.Instant] = []
    var payloads: [[UInt16]] {
        inputs.compactMap { if case .unicode(let units) = $0 { units } else { nil } }
    }
    var afterPost: (() -> Void)?
    func post(_ input: KeyboardInput, to processID: Int32) throws {
        XCTAssertEqual(processID, 42)
        inputs.append(input)
        times.append(ContinuousClock.now)
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
            try await runner.inject("Hello\n\tWorld\u{1B}", options: .init()) { _, _ in }
            XCTFail("Expected unsupported input")
        } catch { XCTAssertEqual(error as? InjectionError, .unsupportedControl) }
        XCTAssertEqual(safari.activations, 0)
        XCTAssertTrue(keyboard.payloads.isEmpty)
    }

    @MainActor func testMixedWhitespaceDeliveryAndProgress() async throws {
        let (runner, _, _, keyboard) = environment()
        let text = " A  \r\n\n\t😀 \t"
        var progress: [Int] = []
        try await runner.inject(text, options: .init(characterDelay: .zero)) { count, total in
            progress.append(count)
            XCTAssertEqual(total, text.count)
        }
        XCTAssertEqual(keyboard.inputs, [
            .unicode([32]), .unicode([65]), .unicode([32]), .unicode([32]),
            .key(.enter), .key(.enter), .key(.tab), .unicode(Array("😀".utf16)),
            .unicode([32]), .key(.tab)
        ])
        XCTAssertEqual(progress, Array(0...text.count))
    }

    @MainActor func testTabExpansionKeepsSourceProgress() async throws {
        let (runner, _, _, keyboard) = environment()
        var progress: [Int] = []
        try await runner.inject("\tX", options: .init(characterDelay: .zero, tabBehavior: .fourSpaces)) { count, total in
            progress.append(count)
            XCTAssertEqual(total, 2)
        }
        XCTAssertEqual(keyboard.inputs, Array(repeating: .unicode([32]), count: 4) + [.unicode([88])])
        XCTAssertEqual(progress, [0, 1, 2])
    }

    @MainActor func testFocusLossAfterTabStopsFollowingText() async {
        let (runner, _, safari, keyboard) = environment()
        keyboard.afterPost = { safari.foreground = false }
        do {
            try await runner.inject("\tX", options: .init(characterDelay: .zero)) { _, _ in }
            XCTFail("Expected focus loss")
        } catch { XCTAssertEqual(error as? InjectionError, .focusLost) }
        XCTAssertEqual(keyboard.inputs, [.key(.tab)])
    }

    @MainActor func testCancellationInterruptsExpandedTab() async {
        let (runner, _, _, keyboard) = environment()
        var task: Task<Void, Error>?
        keyboard.afterPost = { task?.cancel() }
        task = Task {
            try await runner.inject("\tX", options: .init(characterDelay: .zero, tabBehavior: .fourSpaces)) { _, _ in }
        }
        do { try await task?.value; XCTFail("Expected cancellation") }
        catch { XCTAssertTrue(error is CancellationError) }
        XCTAssertEqual(keyboard.inputs, [.unicode([32])])
    }

    @MainActor func testOnlyWhitespaceIsNotEmpty() async throws {
        let (runner, _, _, keyboard) = environment()
        try await runner.inject(" \n\t", options: .init(characterDelay: .zero)) { _, _ in }
        XCTAssertEqual(keyboard.inputs, [.unicode([32]), .key(.enter), .key(.tab)])
    }

    @MainActor func testZeroDelayStillSeparatesTextFromSpecialKeys() async throws {
        let (runner, _, _, keyboard) = environment()
        try await runner.inject("A\nB\tC", options: .init(characterDelay: .zero)) { _, _ in }
        XCTAssertEqual(keyboard.times.count, 5)
        for index in 1..<keyboard.times.count {
            // Regression: without a boundary pause WebKit inserted the first
            // following character before its Tab indentation handler ran.
            XCTAssertGreaterThanOrEqual(keyboard.times[index - 1].duration(to: keyboard.times[index]), .milliseconds(95))
        }
    }
}

final class InputTokenizerTests: XCTestCase {
    func testLineEndingNormalizationAndBlankLines() throws {
        XCTAssertEqual(try InputTokenizer.tokenize("A\r\n\r\nB\rC\n\u{85}\u{2028}\u{2029}"),
                       [.text("A"), .enter, .enter, .text("B"), .enter, .text("C"), .enter, .enter, .enter, .enter])
    }

    func testLeadingRepeatedTrailingSpacesAndTabs() throws {
        XCTAssertEqual(try InputTokenizer.tokenize("  A\t\t \u{00A0}\u{3000} "),
                       [.text(" "), .text(" "), .text("A"), .tab, .tab, .text(" "), .text("\u{00A0}"), .text("\u{3000}"), .text(" ")])
    }

    func testLiteralBackslashIsNotAnEscape() throws {
        XCTAssertEqual(try InputTokenizer.tokenize(#"\n\t"#), [.text("\\"), .text("n"), .text("\\"), .text("t")])
    }

    func testRejectsUnsupportedControlsAnywhere() {
        for control in ["\u{00}", "\u{08}", "\u{0B}", "\u{1B}", "\u{7F}", "\u{9F}"] {
            XCTAssertThrowsError(try InputTokenizer.prepare("A\n\t" + control, tabBehavior: .key)) {
                XCTAssertEqual($0 as? InjectionError, .unsupportedControl)
            }
        }
    }

    func testLongMixedTextDoesNotLoseTokens() throws {
        let text = String(repeating: "😀漢\t \r\n", count: 2000)
        let inputs = try InputTokenizer.prepare(text, tabBehavior: .key)
        XCTAssertEqual(inputs.count, 10_000)
        XCTAssertEqual(inputs.filter { $0 == [.key(.enter)] }.count, 2000)
        XCTAssertEqual(inputs.filter { $0 == [.key(.tab)] }.count, 2000)
    }

    @MainActor func testSpecialKeyEventsHaveRealKeyCodesAndCleanFlags() throws {
        for (key, expectedCode) in [(SpecialKey.enter, 36), (.tab, 48)] {
            let (down, up) = try KeyboardInjector.events(for: .key(key))
            XCTAssertEqual(down.type, .keyDown)
            XCTAssertEqual(up.type, .keyUp)
            for event in [down, up] {
                XCTAssertEqual(event.getIntegerValueField(.keyboardEventKeycode), Int64(expectedCode))
                XCTAssertEqual(event.flags, [])
            }
        }
    }
}
