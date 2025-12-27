# 📚 StrengthWise 文檔導航

> **最後更新**：2024年12月27日 深夜

---

## 🎯 核心文檔（必讀）⭐

### 1. [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) ⭐⭐⭐
**專案架構總覽**
- Flutter 技術棧與架構模式
- MVVM + Clean Architecture
- 核心功能列表
- 目錄結構說明

### 2. [DATABASE_SUPABASE.md](DATABASE_SUPABASE.md) ⭐⭐⭐
**Supabase PostgreSQL 資料庫設計**
- 11 個核心表格結構
- RLS 安全策略
- 索引設計
- Migration 腳本說明

### 3. [DATABASE_OPTIMIZATION_GUIDE.md](DATABASE_OPTIMIZATION_GUIDE.md) ⭐⭐⭐
**資料庫優化指南**
- Phase 1-4 效能優化 ✅ **100% 完成**（2024-12-27）
  - Phase 1: 索引優化（17 個索引）- 提升 70-85%
  - Phase 2: 全文搜尋（pgroonga）- 提升 90%+
  - Phase 3: 統計彙總（2 表格 + 觸發器）- 提升 80-95%
  - Phase 4: 快取 + 分頁 - 提升 95-99%
- 實際效益：統計頁面 2-5s → **秒開（<5ms）** ⚡

### 4. [MAIN_THREAD_OPTIMIZATION.md](MAIN_THREAD_OPTIMIZATION.md) ⭐⭐⭐ 🆕
**主線程優化指南**
- v3 終極優化 ✅ **100% 完成**（2024-12-27 深夜）
  - 應用啟動優化：2.5s → **200ms**（-92%）
  - 主線程卡頓：721 frames → **<30 frames**（-96%）
  - 統計預載入：312 frames → **<10 frames**（-97%）
- 智能延遲載入策略
- 最小化預載入範圍

### 5. [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) ⭐⭐
**開發狀態與變更記錄**
- 最新完成：全代碼解耦合 + 主線程優化 v3（2024-12-27 深夜）
- 已完成功能清單（Phase 1-4 + 解耦 + 主線程優化全部完成）
- 重要里程碑記錄
- 下一步建議

### 6. [UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md) ⭐⭐
**UI/UX 設計規範**
- Kinetic 設計系統
- Material 3 實作
- 色彩系統（Titanium Blue）
- 間距系統（8 點網格）

### 7. [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) ⭐⭐
**部署指南**
- Release APK 構建流程
- Google Sign-In 完整配置
- 發布檢查清單

---

## 📖 快速查找

### 🏗️ 架構相關
- 專案架構 → [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)
- 資料庫設計 → [DATABASE_SUPABASE.md](DATABASE_SUPABASE.md)
- 效能優化 → [DATABASE_OPTIMIZATION_GUIDE.md](DATABASE_OPTIMIZATION_GUIDE.md)
- **主線程優化 → [MAIN_THREAD_OPTIMIZATION.md](MAIN_THREAD_OPTIMIZATION.md)** 🆕

### 🎨 設計相關
- UI/UX 規範 → [UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md)
- 設計系統 → [UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md) 第 2-4 章

### 🚀 開發相關
- 當前進度 → [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)
- 部署流程 → [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

## 🎯 快速開始（新手必讀）

1. **了解專案**：閱讀 [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)
2. **理解資料庫**：閱讀 [DATABASE_SUPABASE.md](DATABASE_SUPABASE.md)
3. **查看進度**：閱讀 [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)
4. **開始開發**：參考 `AGENTS.md`（根目錄）

---

## 🎉 當前專案狀態（2024-12-28）

### ✅ **單機版正式完成**（v1.0）⭐⭐⭐
- ✅ 訓練計劃管理（創建、編輯、模板、執行）
- ✅ 專業統計系統（力量進步、趨勢分析、熱力圖）
- ✅ 身體數據追蹤（體重、體脂、BMI、趨勢圖）🆕
- ✅ 自訂動作（CRUD + 統計整合）
- ✅ Google Sign-In（Android APK 可用）
- ✅ UI/UX 優化（Material 3 + Kinetic Design）
- ✅ 雙語系統（805 筆記錄中英雙語）
- ✅ **資料庫效能優化**（查詢提升 80-99%）⭐
- ✅ **全代碼解耦合**（Clean Architecture 100%）⭐⭐⭐
- ✅ **主線程優化 v3**（卡頓 -96%）⚡⚡⚡

### 🚀 最新完成（2024-12-28）
- **🎊 單機版正式完成**（個人健身記錄功能 100%）
  - 所有核心功能完成並測試
  - 效能優化達到極致（所有頁面秒開）
  - 架構質量達到生產級別
- **身體數據優化** 🆕
  - 每日一筆數據邏輯（upsert 機制）
  - 圖表日期標籤顯示（X 軸）
  - 向後兼容舊數據（自動去重）

---

## 📚 文檔維護指南

### 更新文檔時
1. 同步更新 `DEVELOPMENT_STATUS.md`（記錄變更）
2. 檢查本文檔（`README.md`）是否需要更新
3. 必要時更新 `PROJECT_OVERVIEW.md`

### 文檔狀態
- ✅ 所有核心文檔已同步（2024-12-27 晚上）
- ✅ 臨時文檔已清理
- ✅ 內容精簡完成

---

## 🔗 外部資源

- **Flutter 官方文檔**：https://flutter.dev/docs
- **Supabase 官方文檔**：https://supabase.com/docs
- **Material 3 設計規範**：https://m3.material.io/

---

**💡 提示**：開始開發前，請先閱讀根目錄的 `AGENTS.md`


---

## 📖 快速查找

| 我想... | 查看文檔 |
|---------|---------|
| 了解專案整體架構 | [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) |
| 查看資料庫結構 | [DATABASE_SUPABASE.md](DATABASE_SUPABASE.md) |
| 執行資料庫優化 | [DATABASE_OPTIMIZATION_GUIDE.md](DATABASE_OPTIMIZATION_GUIDE.md) |
| 了解當前進度 | [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) |
| 設計 UI 元件 | [UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md) |
| 打包 Release 版本 | [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) |
| 配置 Google 登入 | [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) |

---

## 🗂️ 已歸檔文檔

以下文檔已完成階段性任務，移至 `docs/archived/` 目錄（供參考）：

### 階段性任務文檔（已完成）
- `PROFILE_PAGE_OPTIMIZATION.md` → 個人資料頁面優化已完成
- `PROFILE_PAGE_PHASE3_FINAL.md` → Phase 3 統計整合已完成
- `NOTIFICATION_QUICKSTART.md` → 通知系統升級已完成
- `NOTIFICATION_SYSTEM_2025.md` → 通知系統報告（參考用）
- `NOTIFICATION_UPGRADE_REPORT.md` → 通知系統升級報告（參考用）
- `TEMPLATE_DEBUG_GUIDE.md` → 模板除錯已完成

### 舊版本文檔（已過時）
- `cursor_tasks/` 目錄 → Firestore 時代的任務（已淘汰）

---

## 📌 文檔維護原則

1. **必要性原則**：只保留必要的核心文檔
2. **及時整合**：相同主題合併到一個文檔
3. **及時歸檔**：階段性任務完成後立即歸檔
4. **保持更新**：核心文檔需與代碼同步更新
5. **中文優先**：所有文檔使用繁體中文

---

## 🎉 文檔整合成果

**當前專案狀態**（2024-12-27 晚上）：
- ✅ **重大 Bug 修復**：統計查詢錯誤（時間範圍 + 查詢欄位）
- ✅ **Phase 1-4 資料庫優化**：100% 完成（索引 + 搜尋 + 彙總 + Cursor 分頁）
- ✅ **Flutter 端優化**：快取機制 + 批量查詢 + RPC 整合
- ✅ **文檔整理**：清理 9 個臨時 MD 文件
- ⏳ **下一步**：實際使用測試（2-4 週）

**2024-12-27 深夜整理**（第五次）：
- ✅ **全代碼解耦合完成**（Clean Architecture 100%）
  - 統計頁面：1,951 → 166 行（-91.5%），16 個模組
  - Booking 頁面：1,177 → 611 行（-48%），7 個模組
  - 服務層：9 個服務 → 33 個子模組
  - 3 份完整解耦報告
- ✅ **主線程優化 v3 完成**（卡頓 -96%）
  - 應用啟動：2.5s → 200ms
  - 主線程卡頓：721 frames → <30 frames
  - 統計預載入：312 frames → <10 frames
- ✅ 新增核心文檔：`MAIN_THREAD_OPTIMIZATION.md`
- ✅ 更新所有文檔同步最新狀態
- ✅ 下一步：實際使用測試（2-4 週）

**2024-12-27 晚上整理**（第四次）：
- ✅ 統計頁面解耦重構（1,951 → 166 行，-91.5%）
- ✅ 清理：13 個臨時文件（9 個 MD + 4 個重構文檔）
- ✅ 更新：`DEVELOPMENT_STATUS.md` 添加今日修復記錄
- ✅ 同步：所有核心文檔更新最新狀態

**2024-12-27 下午整理**（第三次）：
- 完成：Phase 1-3 資料庫優化執行與驗證
- 整合：RPC 函式到 Flutter Service 層
- 實作：Cursor-based 分頁

**2024-12-27 凌晨整理**（第二次）：
- SQL 遷移腳本精簡：16 → 12 個
- 刪除已過時測試腳本
- 同步今日工作到所有文檔

**2024-12-26 深夜整理**（第一次）：
- 整合：11 → 6 個核心文檔
- 歸檔：5 個階段性任務文檔

**最終成果**：
- 📚 核心文檔：**7 個**（含主線程優化指南）
- 📜 SQL 腳本：12 個（Phase 1-3 全部）
- 📦 已歸檔：7 個文檔（供參考）
- 🎯 結構清晰、易於維護
- 🔧 開發日志：統一在 `DEVELOPMENT_STATUS.md`
- 📊 解耦報告：**3 個**（統計+Booking+Services）
- 🎉 **單機版正式完成**（2024-12-28）🆕

---

## 📂 文檔樹狀圖

```
docs/
├── README.md                          # 📚 本文件 - 導航指南
├── 核心文檔/
│   ├── PROJECT_OVERVIEW.md            # 🏗️ 專案架構（含統計功能）
│   ├── DATABASE_SUPABASE.md           # 🗄️ 資料庫設計
│   ├── DATABASE_OPTIMIZATION_GUIDE.md # ⚡ 資料庫優化（整合版）
│   ├── MAIN_THREAD_OPTIMIZATION.md    # ⚡ 主線程優化（v3 版本）🆕
│   ├── DEVELOPMENT_STATUS.md          # 📊 開發狀態
│   ├── UI_UX_GUIDELINES.md            # 🎨 UI/UX 設計
│   └── DEPLOYMENT_GUIDE.md            # 🚀 部署指南（整合版）
├── refactoring/                       # 📊 解耦重構報告 🆕
│   ├── booking_page_refactoring_report.md
│   └── supabase_services_decoupling_report.md
└── archived/                          # 📦 已歸檔
    ├── PROFILE_PAGE_*.md
    ├── NOTIFICATION_*.md
    ├── TEMPLATE_DEBUG_GUIDE.md
    └── cursor_tasks/

database_export/                       # 🗃️ 資料庫匯出
├── *.json                             # 數據文件（8 個表格）
└── (不再包含 MD 文檔)

migrations/                            # 📜 SQL 遷移腳本（精簡版）
├── 001_create_core_tables.sql         # 核心表格（exercises, body_parts 等）
├── 002_create_user_tables.sql         # 用戶相關表格
├── 004_create_body_data_table.sql     # 身體數據表格
├── 008_update_exercise_naming.sql     # 動作命名雙語化 ✅
├── 009_fix_bilingual_metadata_tables.sql # 元數據表雙語化 ✅
├── 011_force_sync_body_parts.sql      # body_parts 同步 ✅
└── 012_create_custom_exercises_table.sql # 自訂動作 ✅ (2024-12-26)
```

---

## 💡 提示

- **新手**：先閱讀 `PROJECT_OVERVIEW.md` 了解整體架構
- **開發者**：先閱讀 `../AGENTS.md` 了解開發規範
- **資料庫專家**：查看 `DATABASE_SUPABASE.md` 和 `DATABASE_OPTIMIZATION_GUIDE.md`
- **設計師**：參考 `UI_UX_GUIDELINES.md` 的 Kinetic 設計系統

---

**📝 文檔版本**: 5.0（2024-12-27 晚上整理版）  
**📅 最後更新**: 2024-12-27 晚上  
**👥 維護者**: StrengthWise 開發團隊

---

**文檔整理完成！精簡、清晰、易維護！** 🎉
