# StrengthWise 💪

> 智慧型重訓追蹤應用 - 用數據驅動你的訓練進步

一個基於 Flutter 與 Supabase 打造的**專業級教練學員管理與訓練記錄平台**，支援個人訓練追蹤、教練學員管理、預約系統、SOAP 筆記、手繪板等完整功能。

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Latest-3ECF8E?logo=supabase)](https://supabase.com/)
[![Dart](https://img.shields.io/badge/Dart-3.1+-0175C2?logo=dart)](https://dart.dev/)

**最新版本**：v3.1（2026-01-08）✅  
**專案狀態**：🚀 生產就緒 (Production Ready)

---

## ✨ 核心功能

### 👤 個人訓練系統（v1.0）

**🏋️ 訓練管理**
- ✅ 訓練計劃創建、編輯、刪除（支援時間範圍設定）
- ✅ 訓練模板系統（快速創建常用計劃）
- ✅ 實時訓練記錄（每組單獨編輯、自動保存）
- ✅ 統一行事曆視圖（UnifiedCalendar + 雙層疊加）

**📊 專業統計分析**（16 個獨立模組）
- ✅ 訓練頻率統計（週/月/季/年）
- ✅ 訓練量趨勢圖表（fl_chart）
- ✅ 力量進步追蹤（個人最佳記錄 PR）
- ✅ 肌群平衡分析（雷達圖）
- ✅ 訓練日曆熱力圖（7x5 格式）
- ✅ 身體數據追蹤（體重/體脂/BMI/肌肉量 + 趨勢圖）
- ⚡ 秒開載入（首頁預載入 + 智能快取）

**💪 運動庫**
- ✅ 794 個專業動作（完整雙語資料）
- ✅ 階層式瀏覽（訓練類型/身體部位/動作分類）
- ✅ 繁體中文全文搜尋（pgroonga）
- ✅ 自訂動作系統（CRUD + 統計整合）

---

### 👥 教練學員系統（v2.0）⭐⭐⭐

**Phase 1：雙向綁定與管理**
- ✅ 教練邀請學員（UUID 綁定）
- ✅ 學員接受/拒絕邀請
- ✅ 雙向訓練記錄查看
- ✅ 教練為學員創建訓練計劃

**Phase 2：預約系統**
- ✅ 教練時段管理（單次 + 週期性 RRULE）
- ✅ 學員線上預約
- ✅ 物理層防雙重預約（GiST 排除約束）
- ✅ 狀態管理（待確認/已確認/已完成/已取消/已拒絕）

**Phase 3：視覺化筆記系統**
- ✅ SOAP 格式專業筆記（Subjective, Objective, Assessment, Plan）
- ✅ 照片拍攝與上傳（Supabase Storage）
- ✅ Private/Shared 切換（學員可見性控制）
- ✅ 學員時間偏好設定（行事曆模式 + 優先級）

**Phase 4：進階功能**
- ✅ 完整手繪板（4 種底圖 + 4 種工具 + 向量繪圖）
- ✅ 教練多學員統計視圖（複用 16 個統計模組）
- ✅ 教練學員中心整合（4 個 Tab 統一導航）
- ✅ 統一行事曆系統（訓練計劃 + 時間偏好雙層疊加）

---

### 🎓 教練上課模式（v3.0-3.1）⭐⭐⭐

**Session Mode - 教練專屬上課介面**
- ✅ 課前問卷（5 維度表情滑桿 + 紅綠燈狀態）
- ✅ 訓練動作卡（含 PREV 歷史數據 + 動作歷史彈窗）
- ✅ SOAP 筆記即時編輯（Debounced 自動保存）
- ✅ 照片拍攝 + 手繪模板（SpeedDial FAB）
- ✅ 學員健康評估查看

**Realtime 即時同步（v3.1）**
- ✅ Supabase Realtime 訂閱（workout_plans + session_notes）
- ✅ 教練學員畫面同步（教練打勾學員即時看到）
- ✅ 智慧防抖（避免自己觸發的更新閃爍）

**權限控制**
- ✅ 教練：課程時間內可編輯、打勾
- ✅ 學員：唯讀模式（可看訓練 + 運動時長）
- ✅ 時間窗口控制（課程開始至結束後 4 小時）

**推播通知（FCM）**
- ✅ 課前 1 小時提醒（雙方）
- ✅ 學員填問卷通知教練（含紅綠燈）
- ✅ 預約狀態變更通知

---

### 🛠️ 技術特色

**時區統一化（v2.2）** ⭐
- ✅ 全項目統一使用 `DateTimeUtils` 工具類
- ✅ 40+ 個文件，消除 120+ 處重複代碼
- ✅ Model 層所有 `DateTime` 都是本地時間
- ✅ Service 層統一 UTC 轉換
- ✅ UI 層零轉換（開箱即用）

**資料庫優化**
- ✅ Phase 1-4 完整優化（索引 + 全文搜尋 + 彙總表 + Cursor 分頁）
- ✅ 查詢效能提升 80-99%（統計頁面秒開）
- ✅ pgroonga 全文搜尋（繁體中文優化）
- ✅ TSTZRANGE 時間範圍查詢（GiST 索引）

**效能優化** ⚡
- ✅ 主線程優化 v3（卡頓 -96%）
- ✅ 首頁預載入 + 智能快取
- ✅ 所有頁面秒開（<5ms）

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

| 分類 | 技術 | 版本 |
|------|------|------|
| **框架** | Flutter | 3.16+ |
| **語言** | Dart | 3.1+ |
| **後端** | Supabase PostgreSQL | Latest |
| **認證** | Supabase Auth | Latest |
| **儲存** | Supabase Storage | Latest |
| **狀態管理** | Provider (ChangeNotifier) | - |
| **依賴注入** | GetIt (Service Locator) | - |
| **本地儲存** | SharedPreferences | - |
| **圖表** | fl_chart | Latest |
| **全文搜尋** | pgroonga | Latest |

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

**特色**：
- ✅ 100% Interface 使用（完全解耦）
- ✅ 60+ 獨立元件（模組化設計）
- ✅ 統一時間轉換工具（DateTimeUtils）
- ✅ 統一錯誤處理（ErrorHandlingService）

### 專案結構

```
strengthwise/
├── lib/                    # Flutter 核心程式碼
│   ├── models/             # 資料模型（與 Supabase 對接）
│   ├── services/           # 服務層（資料存取）
│   │   ├── interfaces/     # Service Interface
│   │   └── supabase/       # Supabase 實作
│   ├── controllers/        # 控制器層（業務邏輯）
│   │   └── interfaces/     # Controller Interface
│   ├── views/              # UI 層（頁面和元件）
│   │   ├── pages/          # 完整頁面
│   │   └── widgets/        # 可復用元件
│   └── utils/              # 工具類（DateTimeUtils 等）
├── scripts/                # Python 工具腳本（8 個核心工具）
│   └── tools/              # 資料庫下載、假資料生成等
├── migrations/             # 資料庫 Migrations（35 個檔案）
├── docs/                   # 專案文檔（完整技術文檔）
├── assets/                 # 靜態資源
└── test/                   # 測試檔案
```

### 代碼統計（v3.1）

| 項目 | 數量 |
|------|------|
| 總行數 | 68,000+ |
| Model 類別 | 67+ |
| Service 類別 | 55+ |
| Controller 類別 | 22+ |
| 獨立 Widget 元件 | 200+ |
| 頁面 | 65+ |
| 統計模組 | 16 |
| 資料庫表格 | 24 |
| RLS 策略 | 50+ |
| Migrations | 35 |
| Python 工具 | 8 |

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

### 核心表格（v1.0）

| 表格 | 說明 | 記錄數 |
|------|------|--------|
| `users` | 用戶資料（與 Supabase Auth 同步） | - |
| `workout_plans` | 訓練計劃和記錄（統一表） | - |
| `workout_templates` | 訓練模板 | - |
| `exercises` | 系統動作庫 | 794 |
| `custom_exercises` | 用戶自訂動作 | - |
| `body_data` | 身體數據記錄 | - |

### 彙總表（效能優化）

| 表格 | 說明 | 效能提升 |
|------|------|---------|
| `daily_workout_summary` | 每日訓練彙總表 | 99%+ |
| `personal_records` | 個人最佳記錄彙總表 | 95%+ |

### 教練學員系統（v2.0-3.1）

| 表格 | 說明 |
|------|------|
| `coaching_relationships` | 教練學員關係 |
| `availability_slots` | 教練可用時段（RRULE 週期性） |
| `appointments` | 預約記錄 |
| `session_notes` | SOAP 格式課程筆記 |
| `client_availability` | 學員時間偏好 |
| `coaches` | 教練公開檔案 |
| `coach_booking_settings` | 教練預約設定 ⭐ v3.0 |
| `daily_readiness` | 課前問卷 ⭐ v3.0 |
| `health_assessments` | PAR-Q+ 健康評估 |
| `user_devices` | FCM 推播 Token ⭐ v3.0 |

### 資料庫特色

**效能優化**
- ✅ Phase 1-4 完整優化（索引 + 全文搜尋 + 彙總表 + Cursor 分頁）
- ✅ 查詢效能提升 80-99%
- ✅ pgroonga 全文搜尋（繁體中文優化）
- ✅ TSTZRANGE 時間範圍查詢（GiST 索引）

**安全性**
- ✅ 50+ 個 RLS 策略（Row Level Security）
- ✅ 物理層防雙重預約（GiST 排除約束）
- ✅ Storage 檔案隔離（Private/Shared）

**詳細設計**：請參考 [docs/DATABASE_SUPABASE.md](docs/DATABASE_SUPABASE.md)

---

## 📖 文檔導航

### 📚 核心文檔（必讀）

| 文檔 | 說明 | 適合對象 |
|------|------|---------|
| **[docs/README.md](docs/README.md)** | 📚 文檔導航（入口） | 所有人 |
| **[AGENTS.md](AGENTS.md)** | AI 開發指南 | AI Agent / 開發者 |
| **[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)** ⭐ | 開發狀態（精簡版 800+ 行） | 所有人 |
| **[docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md)** | 專案架構和技術棧 | 開發者 |
| **[docs/DATABASE_SUPABASE.md](docs/DATABASE_SUPABASE.md)** | Supabase PostgreSQL 資料庫設計 | 後端開發者 |

### 🛠️ 技術指南

| 文檔 | 說明 |
|------|------|
| **[docs/DATETIME_UTILS_GUIDE.md](docs/DATETIME_UTILS_GUIDE.md)** | 時間轉換工具指南（v2.2 完整） |
| **[docs/UI_DEVELOPER_GUIDE.md](docs/UI_DEVELOPER_GUIDE.md)** | UI/UX 設計規範 |
| **[docs/DATABASE_OPTIMIZATION_GUIDE.md](docs/DATABASE_OPTIMIZATION_GUIDE.md)** | 資料庫優化指南 |
| **[docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)** | 部署指南 |

### 🎯 設計文檔

| 文檔 | 說明 |
|------|------|
| **[docs/SAAS_PLATFORM_ROADMAP.md](docs/SAAS_PLATFORM_ROADMAP.md)** | 完整 SaaS 計劃（Phase 1-5） |
| **[docs/UNIFIED_TIME_PICKER_DESIGN.md](docs/UNIFIED_TIME_PICKER_DESIGN.md)** | 統一時間設定模組設計 |

### 🔧 工具腳本

| 文檔 | 說明 |
|------|------|
| **[scripts/README.md](scripts/README.md)** | Python 工具腳本使用指南（8 個核心工具） |
| **[migrations/README.md](migrations/README.md)** | 資料庫 Migrations 執行指南（35 個檔案） |

---

## 🗺️ 版本歷程

### 🎉 v3.1 - Session Mode 完善 + 首頁行事曆 UX（2026-01-08）✅

**Session Mode 完善**
- ✅ 訓練執行內嵌（WorkoutExecutionContent 可復用 Widget）
- ✅ 即時保存機制（所有修改即時保存 + SOAP Debounced）
- ✅ Supabase Realtime 同步（workout_plans + session_notes）

**首頁 + 行事曆 UX 優化（Phase 3.1-B）**
- ✅ 首頁快捷按鈕列（根據身份動態顯示）
- ✅ 今日行程 / 我的學員可折疊區塊
- ✅ 行事曆「我的」/「教練」Tab
- ✅ 多色點點標記：🟠上課 🔵訓練 🟢教練可上課 🟡學員可訓練
- ✅ SpeedDial FAB（根據身份+Tab 顯示選項）
- ✅ 學員模式（唯讀 + 運動時長顯示）
- ✅ SpeedDial FAB（照片、繪圖、新增動作）
- ✅ 可復用組件（UploadedPhotoGrid、QuickTagsSection）

### 🎉 v3.0 - 預約系統優化 + Session Mode + 響應式 UI（2026-01-06）✅

**Session Mode - 教練上課模式**
- ✅ 課前問卷系統（5 維度 + 紅綠燈）
- ✅ 訓練動作卡（PREV 歷史數據）
- ✅ 健康評估 Tab
- ✅ 手繪 FAB

**FCM 推播通知**
- ✅ HTTP v1 API（OAuth 2.0）
- ✅ 課前提醒、問卷通知、預約狀態變更

**響應式 UI**
- ✅ 7 級斷點系統
- ✅ 自適應導航（BottomNav → NavigationRail）
- ✅ Master-Detail 分欄佈局

### 🎉 v2.8-2.9 - 健康評估 + 教練公開檔案（2026-01-03~04）✅

- ✅ PAR-Q+ 健康評估問卷
- ✅ 教練評估備註
- ✅ 教練公開檔案
- ✅ 訓練權限系統

### 🎉 v2.2 - 時區統一化與專案整理（2026-01-02）✅

**時區統一化** ⭐
- ✅ 全項目統一使用 `DateTimeUtils` 工具類
- ✅ 40+ 個文件，消除 120+ 處重複代碼
- ✅ Model 層所有 `DateTime` 都是本地時間
- ✅ 完整測試通過

**資料庫修復與整理**
- ✅ 修復 `personal_records.body_part` 欄位（從 exercises 表自動查詢）
- ✅ 修復統計觸發器支援布林值（向後相容）
- ✅ 修復 `get_available_slots()` 函數
- ✅ Python 工具腳本整理（14 → 8 個，-43%）
- ✅ Migrations 檔案整理（19 → 11 個，-42%）

### 🎉 v2.1 - 訓練時間範圍（2025-01-02）✅

- ✅ `training_time_range` TSTZRANGE 欄位
- ✅ 資料庫層排除約束（防止雙重預約）
- ✅ 應用層重疊檢查
- ✅ GiST 索引優化

### 🎉 v2.0 - 教練學員平台（2024-12-28 ~ 2025-01-01）✅

**Phase 1：教練學員系統**
- ✅ 雙向綁定與管理
- ✅ 教練為學員創建訓練

**Phase 2：預約系統**
- ✅ 教練時段管理（RRULE 週期性）
- ✅ 學員線上預約
- ✅ 物理層防雙重預約

**Phase 3：視覺化筆記**
- ✅ SOAP 格式專業筆記
- ✅ 照片上傳與標註
- ✅ 學員時間偏好設定

**Phase 4：進階功能**
- ✅ 完整手繪板（向量繪圖）
- ✅ 教練多學員統計視圖
- ✅ 教練學員中心整合
- ✅ 統一行事曆系統

### 🎉 v1.0 - 單機版（2024-12-24）✅

**核心功能**
- ✅ 用戶認證（Supabase Auth + Google Sign-In）
- ✅ 訓練計劃管理（創建、編輯、刪除、模板）
- ✅ 訓練執行和記錄（實時保存、每組單獨編輯）
- ✅ 運動庫（794 個專業動作 + 階層式瀏覽）
- ✅ 自訂動作功能（CRUD + 統計整合）
- ✅ 行事曆視圖（月曆 + 快速創建）

**專業統計系統**（16 個模組）
- ✅ 訓練頻率、訓練量趨勢、力量進步追蹤
- ✅ 肌群平衡分析、訓練日曆熱力圖
- ✅ 身體數據追蹤（體重/體脂/BMI/肌肉量）

**效能優化**
- ✅ Phase 1-4 資料庫優化（提升 80-99%）
- ✅ 主線程優化 v3（卡頓 -96%）
- ✅ 所有頁面秒開（<5ms）

**技術架構**
- ✅ MVVM + Clean Architecture（100% Interface 使用）
- ✅ 全代碼解耦合（60+ 獨立元件）
- ✅ Supabase PostgreSQL（完全移除 Firebase）

---

## 🔮 未來規劃

### 短期（1-2 個月）
- [ ] v3.1 功能測試（33 項）
- [ ] Android 首頁 Widget（下堂課倒數）
- [ ] iOS APNs 推播整合
- [ ] 準備 Beta 測試

### 中期（3-6 個月）
- [ ] Onboarding 流程
- [ ] 語音筆記與 AI 功能
  - 語音轉文字（Whisper API）
  - 智能筆記建議（GPT-4）
- [ ] 數據匯出（CSV/PDF）
- [ ] 訓練計劃模板市場

### 長期（6 個月以上）
- [ ] 社交功能（動態分享、排行榜）
- [ ] 多語言支援
- [ ] Web 版本
- [ ] Apple Watch / Wear OS 支援

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
