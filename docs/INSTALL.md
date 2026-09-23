# 安裝 TextInjector v0.2.0 預覽版

系統需求：macOS 13 以上。Universal App 包含 Apple Silicon 與 Intel 版本；Intel 版本已交叉編譯，但尚未於 Intel 硬體實測。

1. 開啟 TextInjector-0.2.0-universal.dmg。
2. 將 TextInjector.app 拖曳至 Applications（應用程式）。
3. 退出磁碟映像檔，從「應用程式」開啟 TextInjector。
4. 按「授予權限」，到「系統設定 → 隱私權與安全性 → 輔助使用」啟用 TextInjector。
5. 按「開啟 Safari 測試頁」，點選 textarea，回到 App 按「輸入到 Safari」。

此版本使用 ad-hoc 簽章，尚未經 Apple Developer ID 簽署與公證。從網路下載後 macOS 可能阻止開啟；若你已核對專案來源且決定使用，可依系統提示到「隱私權與安全性」選擇「仍要打開」。不需要關閉 Gatekeeper 或執行移除隔離屬性的指令。

這是技術預覽版：支援 Unicode、空格、多行與 Tab。Tab 預設為實體按鍵，依網頁行為縮排或切換欄位；也可改為 4 個空格。換行會發送 Return，在部分網站可能提交表單。不會額外送出結尾 Return。尚無剪貼簿快速輸入、Menu Bar 或全域快捷鍵。已通過內建 Safari 頁面的多行、空格、Tab 縮排與移焦測試；其他網站請先試用。

更新前請先結束舊版 App。若系統顯示授權已開啟，但 App 仍說未授權，請在輔助使用列表移除舊 TextInjector，再加入 /Applications/TextInjector.app，啟用並重開 App。

移除方式：結束 App、將 /Applications/TextInjector.app 移至垃圾桶，並在輔助使用設定移除權限。App 不建立文字歷史。

原始碼：https://github.com/gyeyeon385/TextInjector
版本下載：https://github.com/gyeyeon385/TextInjector/releases
