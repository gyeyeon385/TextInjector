# v0.3.0 驗證紀錄

本版新增 Google Chrome 目標。自動測試會驗證瀏覽器選擇、PID 前景檢查、權限與取消流程；這些測試不會向真實瀏覽器發送鍵盤事件。

## 自動驗證

- `swift test`：28 項中 26 項通過；兩項直接建立 `CGEvent` 的既有測試在此執行環境收到 `eventCreationFailed`。其餘新增瀏覽器選擇、Chrome PID 驗證、焦點遺失、錯誤處理與既有核心測試均通過。
- Xcode Debug 與 Universal Release build 通過；Release 包含 arm64 + x86_64，Bundle 版本 0.3.0（build 3）。
- `codesign --verify --deep --strict` 與 ZIP 完整性檢查通過。
- 發布資產：`TextInjector-0.3.0-universal.zip` 與 `SHA256SUMS.txt`；本版沒有 DMG。
- DMG 尚未產生：本執行環境的 `hdiutil create` 回報 `Device not configured`。

## 瀏覽器端實機驗收

請在 Safari 與 Google Chrome 各自執行內建測試頁，使用合成文字，不要使用包含私人資料的真實表單。

- [ ] 單行 Unicode 範例完全相符，`paste` 計數為 0
- [ ] 多行、連續／前後空格與空白行完全相符
- [ ] D 區實體 Tab 縮排、B 區原生 Tab 移焦與四空格模式符合預期
- [ ] 注入中切換至其他 App 後，下一事件前停止
- [ ] 未啟動所選瀏覽器時顯示對應名稱的錯誤

此執行環境沒有安裝 Google Chrome，尚未完成以上瀏覽器端驗收，因此不宣稱 v0.3.0 的 Chrome 相容性已實機通過。Safari v0.2.0 的既有驗證紀錄見 [VALIDATION-0.2.0.md](VALIDATION-0.2.0.md)。
