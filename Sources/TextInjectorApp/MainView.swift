import SwiftUI
#if canImport(TextInjectorCore)
import TextInjectorCore
#endif

struct MainView: View {
    @ObservedObject var permission: PermissionManager
    @ObservedObject var controller: InjectionController
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                Image(nsImage: NSImage(named: NSImage.applicationIconName) ?? NSImage())
                    .resizable().frame(width: 58, height: 58)
                VStack(alignment: .leading, spacing: 5) {
                    Text("TextInjector").font(.largeTitle.bold())
                    Text("Safari Unicode 輸入 · v0.2.0 預覽版").foregroundStyle(.secondary)
                }
                Spacer()
                Button("開啟 Safari 測試頁") { SafariManager().openFixture() }
                    .disabled(controller.isRunning)
            }

            GroupBox {
                HStack {
                    Image(systemName: permission.accessibilityGranted && permission.postingGranted ? "checkmark.shield.fill" : "lock.shield")
                        .foregroundStyle(permission.accessibilityGranted && permission.postingGranted ? .green : .orange)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(permission.accessibilityGranted && permission.postingGranted ? "已取得輔助使用權限" : "需要輔助使用權限")
                        Text("僅在按下授權按鈕時提出系統請求。")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !permission.accessibilityGranted || !permission.postingGranted {
                        Button("授予權限") { permission.request() }
                    }
                    Button("系統設定") { permission.openSettings() }
                }.padding(6)
            }

            Text("先在 Safari 點選目標文字欄位，再回到此視窗。App 會將 Safari 切到前景後開始輸入。")
                .font(.callout).foregroundStyle(.secondary)
            PlainTextEditor(text: $controller.text, isEditable: !controller.isRunning)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(.background)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                .frame(minHeight: 150)
                .disabled(controller.isRunning)
            HStack {
                Text("\(controller.text.count) 個字元").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("還原測試文字") { controller.text = InjectionController.sample }
                Button("多行與 Tab 範例") { controller.text = InjectionController.multilineSample }
                Button("清除") { controller.text = "" }
            }.disabled(controller.isRunning)

            HStack {
                Picker("每字延遲", selection: $controller.delayMS) {
                    ForEach([0, 5, 10, 20, 50], id: \.self) { Text("\($0) ms").tag($0) }
                }
                Picker("Safari 切換等待", selection: $controller.focusDelayMS) {
                    ForEach([100, 150, 200, 250, 500, 1000], id: \.self) { Text("\($0) ms").tag($0) }
                }
            }.disabled(controller.isRunning)

            HStack {
                Text("換行 → Return 鍵").font(.callout)
                Spacer()
                Picker("Tab 行為", selection: $controller.tabBehavior) {
                    Text("實體 Tab 鍵").tag(TabBehavior.key)
                    Text("轉成 4 個空格").tag(TabBehavior.fourSpaces)
                }.frame(maxWidth: 280)
            }.disabled(controller.isRunning)

            Text(controller.tabBehavior == .key
                 ? "Return 可能提交表單；Tab 依網頁行為縮排或切換欄位，後續文字會送到新欄位。請先用測試頁確認。"
                 : "Tab 轉成 4 個空格，空格與空白行會保留。Return 可能提交表單，請先在多行欄位測試。")
                .font(.caption).foregroundStyle(.secondary)
            if controller.isRunning {
                ProgressView(value: Double(controller.completed), total: Double(max(controller.total, 1)))
            }
            HStack {
                Text(controller.status).font(.callout).textSelection(.enabled)
                Spacer()
                if controller.isRunning {
                    Button("停止") { controller.cancel() }.keyboardShortcut(.cancelAction)
                } else {
                    Button("輸入到 Safari") { controller.inject() }
                        .buttonStyle(.borderedProminent)
                        .disabled(controller.text.isEmpty || !permission.accessibilityGranted || !permission.postingGranted)
                }
            }
        }
        .padding(24)
        .task {
            while !Task.isCancelled {
                permission.refresh()
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { permission.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            controller.cancel()
        }
    }
}
