# Panasonic CF-SR Fan Control (CFSRFanControl)

專為 Panasonic Let's Note CF-SR 系列筆電打造的 Linux (Ubuntu) 散熱與風扇控制解決方案。

本專案包含自訂的 ACPI 核心模組、自動化的 MOK 數位簽章（支援 UEFI Secure Boot），以及一個背景動態溫控守護行程（Daemon）。它能完美解決在 Linux 環境下 CF-SR 筆電風扇策略過於保守導致的過熱降頻問題。

## ✨ 核心特色

*   **硬體級控制**：透過呼叫底層 ACPI 方法 (`\_SB.PC00.LPCB.EC0.SEFM`)，直接控制實體風扇的效能狀態。
*   **Secure Boot 完美相容**：自動產生金鑰並利用 `sign-file` 對 `.ko` 核心模組進行數位簽章，全程無痛支援 Secure Boot 啟動環境。
*   **智慧動態溫控**：背景監控 CPU (`x86_pkg_temp`) 溫度，並配合 `thermald` 動態放寬或收緊效能限制。
*   **Ubuntu 電源模式聯動**：完美整合 `powerprofilesctl`。當切換至 `performance` (效能模式) 時，系統將無視溫度閾值，強制開啟最高散熱檔位。

---

## 📂 專案結構

```text
CFSRFanControl/
├── module/
│   ├── panasonic_sr.c           # C 語言核心模組原始碼
│   └── Makefile                 # 模組編譯設定檔
├── daemon/
│   └── cf-sr-thermal.sh         # 監控與動態溫控腳本
├── systemd/
│   └── cf-sr-thermal.service    # Systemd 服務註冊檔
├── install.sh                   # 一鍵編譯與安裝腳本
└── uninstall.sh                 # 乾淨卸載腳本
```

---

## 🚀 安裝與部署

1. 確保已將本專案複製到本地環境。
2. 進入專案目錄，並賦予腳本執行權限：
   ```bash
   cd CFSRFanControl
   chmod +x install.sh uninstall.sh
   ```
3. 使用 `sudo` 執行一鍵安裝腳本。腳本會自動完成依賴安裝、編譯、簽章、清理快取與服務註冊：
   ```bash
   sudo ./install.sh
   ```
4. 安裝完成後，可透過以下指令確認服務是否正常運作：
   ```bash
   systemctl status cf-sr-thermal.service
   ```

---

## 🌡️ 修改溫度閾值 (自訂風扇觸發時機)

預設的溫控邏輯為：**高於 70°C 啟動高效能風扇，降至 55°C 以下恢復靜音模式**。

如果你想調整這個觸發溫度，請按照以下步驟修改：

1. 打開本專案目錄下的 `daemon/cf-sr-thermal.sh` 檔案。
2. 找到檔案最上方的這兩個變數：
   ```bash
   HIGH_TEMP=70000  # 觸發高效能風扇的溫度 (預設 70°C)
   LOW_TEMP=55000   # 恢復靜音模式的溫度 (預設 55°C)
   ```
   *(註：溫度數值單位為微攝氏度 milli-Celsius，所以 `70000` 代表 70.000°C)*
3. 依照你的需求修改這兩個數值並存檔（例如將 `HIGH_TEMP` 改為 `65000`）。
4. **重新套用設定**：修改完成後，請重新執行安裝腳本以覆蓋系統中的舊檔案，並自動重啟服務：
   ```bash
   sudo ./install.sh
   ```

---

## 🗑️ 乾淨卸載

如果你需要移除此風扇控制系統，只需在專案目錄下執行卸載腳本：

```bash
sudo ./uninstall.sh
```
此動作會停止背景服務、卸載核心模組、刪除系統路徑下的所有相關檔案，並將系統狀態完全恢復至安裝前。