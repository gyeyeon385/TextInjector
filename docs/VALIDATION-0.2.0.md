# v0.2.0 驗證紀錄

日期：2026-09-23。環境：Apple Silicon、Xcode 27.0 / Swift 6.4、本機 Safari。

## 實機通過

使用本版本 Release App，授予輔助使用權限後，由 App 按鈕發送鍵盤事件至內建本地測試頁。除清空測試欄位外，未使用自動化工具向 Safari 欄位填入預期內容。

| 測試 | 結果 |
|---|---|
| App 編輯器直接按空格、Return、Tab | 保留空格、換行及真正 U+0009；8 個來源字元符合預期 |
| 多行範例 → 支援 Tab 的 D 區編輯器 | PASS，完整文字、連續空格、前後空格、空白行與 Tab 完全相符 |
| D 區事件計數 | 39 keyDown / keyUp、3 Return、1 Tab、0 paste |
| `Left\tRight` → B 區原生 textarea | B 區為 Left、下一欄為 Right，Tab 正常移焦 |
| 原生 Tab 事件計數 | 10 keyDown / keyUp、1 Tab、0 Return、0 paste |
| 多行範例 + Tab → 4 空格 → 禁止 paste 的 B 區 | PASS，完整文字與空白完全相符 |
| 四空格模式事件計數 | 42 keyDown / keyUp、3 Return、0 Tab、0 paste |

D 區是示範網頁編輯器：其自身 Tab keydown handler 插入 U+0009。B 區保留 Safari 原生行為，Tab 會移動焦點。App 核心僅發送系統鍵盤事件。

## 本次修正的實測問題

最初 10 ms 全速發送時，Safari 的 Unicode 插入與 Tab handler 處理順序出現競爭，導致 Tab 落在下一字之後。已在 Return / Tab 與相鄰文字之間加入至少 100 ms 的等待；修正後上述實測通過。0 ms 文字模式也保留此特殊鍵等待。這是固定節流，不是對所有網站的接收確認保證。

## 自動驗證

- 24 項核心測試：既有 Unicode、權限、取消、失焦測試，加上空格保留、換行正規化、實體鍵碼、Tab 展開、混合事件順序、10,000 字元及特殊鍵時序回歸。
- Xcode Release Universal build：arm64 + x86_64。
- DMG 完整性驗證通過；掛載後的 App 簽章驗證、版本 0.2.0 及雙架構檢查通過。
- 本版本仍採 ad-hoc 簽章；未經 Developer ID 簽署／Apple 公證。

## 尚未驗證

- Intel 硬體執行、React / Vue / Monaco / CodeMirror、各輸入法、Safari 全螢幕及多視窗。
- 1,000 字以上 Safari 實際丟字率、20 次重複焦點恢復及效能數據。
- 特殊網站可能將 Return 視為提交，或自行攔截 Tab；請在目標欄位先試用。

## 升級權限注意

本機曾存在多個同 Bundle ID 的 ad-hoc 開發版本，造成設定顯示已開啟但新 App 仍未受信任。移除本 App 的舊授權、重新加入正確版本並重新啟動後恢復。更新時請先結束舊版，固定使用 Applications 中的一份 App；若權限失效，依安裝說明重新加入，無需變更其他 App 權限。
