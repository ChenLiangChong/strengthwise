# 📚 StrengthWise 文檔導航

> **最後更新**：2024-12-26

---

## 🎯 核心文檔（必讀）

### 1. [AGENTS.md](../AGENTS.md) ⭐⭐⭐
**AI 程式碼助手開發指南**
- 核心開發規則
- 資料庫約定
- 架構規範
- 型別安全要求
- 註解規範

### 2. [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) ⭐⭐⭐
**專案架構總覽**
- Flutter 技術棧
- Clean Architecture 設計
- 目錄結構
- 核心功能列表
- 服務依賴圖

### 3. [DATABASE_SUPABASE.md](DATABASE_SUPABASE.md) ⭐⭐⭐
**Supabase PostgreSQL 資料庫設計**
- 完整資料表結構
- RLS 安全策略
- 索引設計
- 資料模型關聯圖
- Migration 腳本

### 4. [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) ⭐⭐
**開發狀態與變更記錄**
- 當前進度追蹤
- 已完成功能清單
- 待實作功能
- 最新變更記錄
- 下一步任務

### 5. [UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md) ⭐⭐
**UI/UX 設計規範**
- Kinetic 設計系統
- Material 3 實作
- 色彩系統（Titanium Blue）
- 間距系統（8 點網格）
- 觸覺回饋標準

---

## 📖 功能實作文檔

### [STATISTICS_IMPLEMENTATION.md](STATISTICS_IMPLEMENTATION.md)
**統計功能實作細節**
- 統計服務架構
- 圖表元件使用
- 數據聚合邏輯
- 性能優化策略

---

## 🔧 操作指南

### [BUILD_RELEASE.md](BUILD_RELEASE.md)
**Release APK 構建指南**
- Android 打包流程
- 簽名配置
- ProGuard 規則
- 版本號管理

### [GOOGLE_SIGNIN_COMPLETE_SETUP.md](GOOGLE_SIGNIN_COMPLETE_SETUP.md)
**Google Sign-In 完整配置**
- Android 配置
- iOS 配置
- Supabase Auth 設定
- 測試驗證步驟

---

## 🗄️ 資料庫匯出文檔

### [database_export/](../database_export/)
**資料庫效能優化分析**（僅供資料庫設計專家使用）
- `00_README.md` - 總結報告
- `01_EXERCISES_COMPLETE.md` - 健身動作完整資訊（794 個動作）
- `02_DATABASE_QUERIES.md` - 查詢完整列表與優化建議

**📝 說明**：這些文檔用於資料庫效能優化分析，包含完整的查詢列表、索引建議和優化策略。

---

## 📜 變更記錄

最近完成的工作已整合到 [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) 的「變更記錄」章節。

**最近完成**（2024-12-26）：
- ✅ 個人資料頁面完善（Phase 1-3 全部完成）
- ✅ 身體數據功能完整實作
- ✅ 統計頁面整合（新增「身體數據」Tab）
- ✅ 資料庫完整匯出與分析文檔

---

## 🗂️ 已歸檔文檔

以下文檔已完成階段性任務，移至 `docs/archived/` 目錄：

### 階段性任務文檔（已完成）
- `PROFILE_PAGE_OPTIMIZATION.md` → 個人資料頁面優化已完成
- `PROFILE_PAGE_PHASE3_FINAL.md` → Phase 3 統計整合已完成
- `NOTIFICATION_QUICKSTART.md` → 通知系統升級已完成
- `NOTIFICATION_SYSTEM_2025.md` → 通知系統報告（參考用）
- `NOTIFICATION_UPGRADE_REPORT.md` → 通知系統升級報告（參考用）
- `TEMPLATE_DEBUG_GUIDE.md` → 模板除錯已完成

### 舊版本文檔（已過時）
- `cursor_tasks/` 目錄 → 移至 `docs/archived/cursor_tasks/`（Firestore 時代的任務）

---

## 🔍 快速查找

| 我想... | 查看文檔 |
|---------|---------|
| 了解專案整體架構 | [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) |
| 查看資料庫結構 | [DATABASE_SUPABASE.md](DATABASE_SUPABASE.md) |
| 遵循開發規範 | [AGENTS.md](../AGENTS.md) |
| 了解當前進度 | [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) |
| 設計 UI 元件 | [UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md) |
| 打包 Release 版本 | [BUILD_RELEASE.md](BUILD_RELEASE.md) |
| 配置 Google 登入 | [GOOGLE_SIGNIN_COMPLETE_SETUP.md](GOOGLE_SIGNIN_COMPLETE_SETUP.md) |
| 優化資料庫效能 | [database_export/00_README.md](../database_export/00_README.md) |

---

## 📌 文檔維護原則

1. **必要性原則**：只保留必要的核心文檔
2. **及時歸檔**：階段性任務完成後立即歸檔
3. **避免重複**：相同主題合併到一個文檔
4. **保持更新**：核心文檔需與代碼同步更新
5. **中文優先**：所有文檔使用繁體中文

---

**文檔樹狀圖**：
```
docs/
├── README.md (本文件 - 導航)
├── 核心文檔/
│   ├── PROJECT_OVERVIEW.md
│   ├── DATABASE_SUPABASE.md
│   ├── DEVELOPMENT_STATUS.md
│   └── UI_UX_GUIDELINES.md
├── 功能文檔/
│   └── STATISTICS_IMPLEMENTATION.md
├── 操作指南/
│   ├── BUILD_RELEASE.md
│   └── GOOGLE_SIGNIN_COMPLETE_SETUP.md
└── archived/ (已歸檔)
    ├── PROFILE_PAGE_OPTIMIZATION.md
    ├── PROFILE_PAGE_PHASE3_FINAL.md
    ├── NOTIFICATION_*.md
    ├── TEMPLATE_DEBUG_GUIDE.md
    └── cursor_tasks/

database_export/ (資料庫分析)
├── 00_README.md (總結報告)
├── 01_EXERCISES_COMPLETE.md (動作資訊)
└── 02_DATABASE_QUERIES.md (查詢優化)
```
