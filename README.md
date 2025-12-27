# StrengthWise 💪

> 智慧型重訓追蹤應用 - 用數據驅動你的訓練進步

一個基於 Flutter 與 Supabase 打造的跨平台健身訓練記錄 App，讓你輕鬆管理訓練計劃、記錄每一組動作，並透過數據分析追蹤你的肌力成長。

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Latest-3ECF8E?logo=supabase)](https://supabase.com/)
[![Dart](https://img.shields.io/badge/Dart-3.1+-0175C2?logo=dart)](https://dart.dev/)

---

## ✨ 核心功能

### 🏋️ 訓練管理
- **訓練計劃**：創建、編輯、刪除訓練計劃
- **訓練模板**：保存常用的訓練計劃為模板，快速創建新計劃
- **訓練執行**：實時記錄每一組的重量、次數、完成狀態
- **自動保存**：訓練過程中自動保存進度，不怕資料遺失

### 📊 數據記錄與統計分析 ⭐
- **完整記錄**：記錄每次訓練的詳細數據
- **訓練備註**：為每次訓練添加備註
- **歷史查詢**：查看過往的訓練記錄
- **專業統計系統**：✅ 模組化設計（16 個獨立元件）
  - 📈 訓練頻率、訓練量趨勢圖表
  - 💪 力量進步追蹤、個人最佳記錄（PR）
  - 🎯 肌群平衡分析、訓練日曆熱力圖
  - ⚡ 秒開載入（首頁預載入 + 智能快取）
- **身體數據**：✅ 體重、體脂、BMI、肌肉量追蹤（含趨勢圖）

### 💪 運動庫
- **794 個專業動作**：完整的運動動作資料庫，涵蓋各大肌群
- **階層式瀏覽**：依訓練類型（阻力/心肺/活動度）、身體部位、動作分類輕鬆查找
- **自訂動作**：✅ 創建專屬的自訂動作
- **動作搜尋**：✅ 繁體中文全文搜尋（pgroonga）
- **動作詳情**：查看動作說明和相關資訊

### 🗓️ 行事曆
- **月曆視圖**：一眼看清所有訓練安排
- **快速創建**：點擊日期快速創建訓練計劃
- **進度追蹤**：查看已完成和未完成的訓練

---

## 🚀 快速開始

### 環境需求

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.16 或更高版本
- [Dart SDK](https://dart.dev/get-dart) 3.1 或更高版本
- Supabase 專案（用於資料庫和認證）

### 安裝步驟

1. **Clone 專案**
   ```bash
   git clone https://github.com/yourusername/strengthwise.git
   cd strengthwise
   ```

2. **安裝依賴**
   ```bash
   flutter pub get
   ```

3. **設定 Supabase**
   - 在專案根目錄創建 `.env` 檔案
   - 加入你的 Supabase 憑證：
     ```env
     SUPABASE_URL=https://your-project.supabase.co
     SUPABASE_ANON_KEY=your-anon-key
     ```
   - 詳細設定請參考 `docs/DEPLOYMENT_GUIDE.md`

4. **執行應用**
   ```bash
   flutter run
   ```

---

## 🏗️ 技術架構

### 技術棧

- **框架**：Flutter 3.16+
- **語言**：Dart 3.1+
- **後端**：Supabase PostgreSQL (Database, Auth, Storage)
- **狀態管理**：Provider (ChangeNotifier)
- **依賴注入**：GetIt (Service Locator Pattern)
- **本地儲存**：SharedPreferences

### 架構模式

採用 **MVVM + Clean Architecture**，確保代碼清晰、易於維護：

```
View (UI 層)
  ↓ Provider/Consumer
Controller (業務邏輯層)
  ↓ Service Interface
Service (資料存取層)
  ↓ Supabase PostgreSQL
Model (資料模型層)
```

### 專案結構

```
strengthwise/
├── lib/             # Flutter 核心程式碼
│   ├── models/      # 資料模型
│   ├── services/    # 服務層（資料存取）
│   ├── controllers/ # 控制器層（業務邏輯）
│   └── views/       # UI 層（頁面和元件）
├── scripts/         # Python 和 Dart 工具腳本
├── docs/            # 專案文檔
├── assets/          # 靜態資源
└── ...
```

---

## 📱 功能截圖

<!-- TODO: 添加應用截圖 -->

---

## 🛠️ 開發

### 開發環境設定

1. **安裝 Flutter**
   ```bash
   # 檢查環境
   flutter doctor
   ```

2. **設定 IDE**
   - 推薦使用 VS Code 或 Android Studio
   - 安裝 Flutter 和 Dart 插件

3. **運行測試**
   ```bash
   flutter test
   ```

### 開發規範

**重要**：開始開發前，請先閱讀以下文檔：

1. **[AGENTS.md](AGENTS.md)** - AI 程式碼助手的完整開發指南
2. **[docs/README.md](docs/README.md)** - 文檔導航（入口）
3. **[docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md)** - 專案架構詳解
4. **[docs/DATABASE_SUPABASE.md](docs/DATABASE_SUPABASE.md)** - Supabase 資料庫設計
5. **[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)** - 開發狀態和變更記錄

- **代碼風格**：遵循 Dart 官方風格指南
- **註解**：關鍵邏輯使用繁體中文註解
- **提交**：使用有意義的 commit message
- **測試**：確保新功能有對應的測試

詳細的開發規範請參考 [AGENTS.md](AGENTS.md)。

---

## 📂 資料庫結構

使用 **Supabase PostgreSQL** 作為資料庫，主要表格：

| 表格 | 說明 | 狀態 |
|------|------|------|
| `users` | 用戶資料 | ✅ |
| `workout_plans` | 訓練計劃和記錄（統一） | ✅ |
| `workout_templates` | 訓練模板 | ✅ |
| `exercises` | 公共運動庫（794 個專業動作） | ✅ |
| `custom_exercises` | 用戶自訂動作 | ✅ |
| `body_data` | 身體數據記錄 | ✅ |
| `daily_workout_summary` | 每日訓練彙總表（效能優化） | ✅ |
| `personal_records` | 個人最佳記錄彙總表 | ✅ |

**效能優化**（2024-12-27 完成）：
- ✅ Phase 1-4 資料庫優化（索引 + 全文搜尋 + 彙總表 + Cursor 分頁）
- ✅ 查詢效能提升 80-99%（統計頁面秒開）
- ✅ pgroonga 全文搜尋（繁體中文優化）

詳細設計請參考 [docs/DATABASE_SUPABASE.md](docs/DATABASE_SUPABASE.md)。

---

## 📖 文檔

### 給開發者

- **[docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md)** - 專案架構和技術棧
- **[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)** - 當前開發進度
- **[docs/DATABASE_DESIGN.md](docs/DATABASE_DESIGN.md)** - 資料庫設計

### 給 AI Agent

- **[AGENTS.md](AGENTS.md)** - AI 開發指南
- **[docs/README.md](docs/README.md)** - 文檔導航
- **[docs/cursor_tasks/](docs/cursor_tasks/)** - 任務文檔

---

## 🗺️ 開發路線圖

### ✅ 已完成（v1.0）- 2024-12-27

**核心功能**：
- [x] 用戶認證（Supabase Auth + Google Sign-In）
- [x] 訓練計劃管理（創建、編輯、刪除、模板）
- [x] 訓練執行和記錄（實時保存、每組單獨編輯）
- [x] 運動庫（794 個專業動作 + 階層式瀏覽）
- [x] 自訂動作功能（CRUD + 統計整合）
- [x] 行事曆視圖（月曆 + 快速創建）
- [x] 個人資料編輯

**專業統計系統** ⭐：
- [x] 統計頁面模組化重構（1,951 行 → 16 個元件）
- [x] 訓練頻率統計（本週/本月/三個月/全年）
- [x] 訓練量趨勢圖表（使用 fl_chart）
- [x] 力量進步追蹤（個人最佳記錄 PR）
- [x] 肌群平衡分析（雷達圖）
- [x] 訓練日曆熱力圖（7x5 熱力圖）
- [x] 完成率統計
- [x] 身體數據追蹤（體重/體脂/BMI/肌肉量）

**效能優化** ⚡：
- [x] Phase 1-4 資料庫優化（提升 80-99%）
- [x] 統計頁面秒開（首頁預載入）
- [x] pgroonga 全文搜尋（繁體中文）
- [x] 智能快取與預載入

**技術架構**：
- [x] MVVM + Clean Architecture（100% Interface 使用）
- [x] Supabase PostgreSQL（完全移除 Firebase）
- [x] 依賴注入（GetIt Service Locator）

### 🚧 進行中（v1.1）

- [ ] 預約頁面查詢優化
- [ ] 實際使用測試（2-4 週）

### 📅 計劃中（v2.0）

- [ ] 體態照片記錄
- [ ] 身體圍度測量
- [ ] 數據匯出（CSV/PDF）
- [ ] 訓練提醒通知

### 🔮 未來計劃（v3.0）

- [ ] 教練-學員雙邊平台
- [ ] 預約系統完整實作
- [ ] 教學筆記
- [ ] 社交功能

---

## 🤝 貢獻

歡迎貢獻！請遵循以下步驟：

1. Fork 本專案
2. 創建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 開啟 Pull Request

### 貢獻指南

- 遵循專案的代碼風格
- 添加適當的測試
- 更新相關文檔
- 確保所有測試通過

---

## 📄 授權

本專案採用 MIT 授權 - 詳見 [LICENSE](LICENSE) 文件。

---

## 📞 聯繫方式

如有問題或建議，歡迎：

- 開 Issue
- 發 Pull Request
- 聯繫維護者

---

## 🙏 致謝

- [Flutter](https://flutter.dev/) - 優秀的跨平台框架
- [Supabase](https://supabase.com/) - 強大的開源後端服務
- [fl_chart](https://pub.dev/packages/fl_chart) - 精美的圖表庫
- 所有貢獻者和用戶的支持

---

**打造屬於你的健身訓練系統，從 StrengthWise 開始！** 💪

---

<div align="center">

Made with ❤️ by StrengthWise Team

[⬆ 回到頂部](#strengthwise-)

</div>
