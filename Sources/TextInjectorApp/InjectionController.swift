import AppKit
#if canImport(TextInjectorCore)
import TextInjectorCore
#endif

@MainActor final class InjectionController: ObservableObject {
    static let sample = "Hello 世界 안녕하세요 😀"
    @Published var text = sample
    @Published var delayMS = 10
    @Published var focusDelayMS = 200
    @Published private(set) var isRunning = false
    @Published private(set) var completed = 0
    @Published private(set) var total = 0
    @Published private(set) var status = "先在 Safari 點選文字欄位，再回到這裡開始測試。"
    private var task: Task<Void, Never>?
    private let runner: InjectionRunner

    init(permission: PermissionManager) {
        runner = InjectionRunner(permission: permission, safari: SafariManager(), keyboard: KeyboardInjector())
    }

    func inject() {
        guard !isRunning else { return }
        let snapshot = text
        let options = InjectionOptions(characterDelay: .milliseconds(delayMS), activationDelay: .milliseconds(focusDelayMS))
        isRunning = true
        completed = 0
        total = snapshot.count
        status = "正在準備 Safari…"
        task = Task { [weak self] in
            guard let self else { return }
            defer { isRunning = false; task = nil }
            do {
                try await runner.inject(snapshot, options: options) { current, count in
                    completed = current
                    total = count
                    status = "正在發送鍵盤事件… \(current) / \(count)"
                }
                status = "已發送 \(completed) 個字元。請核對 Safari 欄位的實際內容。"
            } catch is CancellationError {
                status = "已停止（已發送 \(completed) / \(total)）。"
            } catch {
                status = error.localizedDescription
            }
        }
    }

    func cancel() { task?.cancel() }
}
