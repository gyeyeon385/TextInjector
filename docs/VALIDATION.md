# Sprint 1 驗證紀錄

日期：2026-09-22。環境：本機 Apple Silicon、Xcode 27.0（27A266a）、Swift 6.4。

## 已實際完成

| 項目 | 結果 |
|---|---|
| 原生 Xcode Debug App 編譯 | BUILD SUCCEEDED |
| Swift Package 核心測試 | 12 項通過，0 failures |
| App ad-hoc 簽章驗證 | codesign --verify --deep --strict 通過 |
| App 啟動 | 視窗成功顯示，字數與預設參數正確 |
| 未授權狀態 | 顯示需要輔助使用權限，輸入按鈕停用 |
| 內建測試頁 | 從 App 按鈕成功於 Safari 新分頁開啟 |
| Release Universal 編譯 | arm64 + x86_64，BUILD SUCCEEDED |
| Release 介面與圖示 | 已啟動並目視確認 |
| DMG 完整性 | hdiutil verify 通過；掛載後 App 簽章驗證通過 |
| DMG 安裝內容 | TextInjector.app、Applications 捷徑、INSTALL.txt |
| Release 回歸測試 | 12 項通過，0 failures |

編譯過程有一則 Xcode AppIntents metadata extraction skipped 訊息：本 App 未依賴 AppIntents，不影響本次編譯。

## 自動測試涵蓋

1. 英文、繁中、韓文、日文、重音字、希臘字、Emoji、ZWJ family 與超長合成字元的 UTF-16 round-trip。
2. 控制字元拒絕與空文字驗證。
3. 10,000 字元 payload 完整性。
4. 真正 CGEvent 的 keyDown/keyUp、flags 與 Unicode payload（只建立事件，不 post）。
5. 無權限時不啟用 Safari、不 post。
6. Safari 失焦後不再 post 下一個事件。
7. 權限撤銷後不再 post 下一個事件。
8. 取消後不再 post 下一個事件。
9. 切換等待期間取消時零事件發送。
10. 正常流程的文字與進度一致。
11. Safari 未啟動或啟用失敗時零事件發送。
12. 含控制字元的全文在切換 Safari 前被拒絕。

流程測試使用替身驗證行為，**不代表 Safari 已實際收到文字**。10,000 字元測試是編碼完整性測試，不是 Safari 丟字率或效能測量。

## 尚待輔助使用授權後實機驗證

- [ ] Safari textarea 顯示 `Hello 世界 안녕하세요 😀`，字串完全相符。
- [ ] 普通 input、禁止 paste 的 textarea、contenteditable 均通過。
- [ ] 注入時 `paste` 計數為 0。
- [ ] 禁止 paste 的欄位手動 Cmd+V 無效，鍵盤注入有效。
- [ ] 1,000 字無丟字，0 / 10 / 50 ms 節奏比較。
- [ ] 連續 20 / 20 次 App → Safari 恢復焦點成功。
- [ ] 手動切到 Finder 後停止；Finder 未收到文字。
- [ ] 取消、授權撤銷、重新授予與重新啟動恢復。
- [ ] 不同鍵盤輸入法、全螢幕、多視窗。
- [ ] 比較三種 Event Tap 與 PID 定向發送。

截至本紀錄，新 Release Bundle ID 為 `io.github.gyeyeon385.TextInjector`，尚未取得 Accessibility 權限；舊 `dev.local.TextInjector` 的授權不會視為新版本已授權。尚未宣稱 Safari 端到端驗收通過。Intel 版本僅交叉編譯，未在 Intel 硬體執行。

## 後續順序

1. 先完成上述授權後的 Safari 核心技術驗證。
2. Phase 2：特殊鍵 tokenizer、Enter / Tab / Backspace 明確策略與提交風險處理。
3. Clipboard → Keyboard、Menu Bar、全域快捷鍵。
4. React / Vue controlled input、長文字與相容性測試。
5. Developer ID 簽署與 Apple 公證（預覽版 DMG 已提供）。
