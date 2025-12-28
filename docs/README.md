# 📚 StrengthWise 文檔中心

> 專案文檔與開發指南

**最後更新**：2024年12月28日

---

## 🚀 快速開始

| 文檔 | 說明 | 必讀 |
|------|------|------|
| [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) | 📊 當前開發狀態、已完成功能、下一步計劃 | ⭐⭐⭐ |
| [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) | 🏗️ 專案架構、技術棧、檔案結構 | ⭐⭐ |
| [SAAS_PLATFORM_ROADMAP.md](SAAS_PLATFORM_ROADMAP.md) | 🗺️ v2.0 SaaS 平台完整計劃（Phase 1-5） | ⭐⭐ |

---

## 📖 核心文檔

### 專案狀態
- **[DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)** ⭐ 必讀
  - ✅ v1.0 單機版完成（個人健身記錄）
  - ✅ v2.0 Phase 1 完成（教練學員系統）
  - ✅ v2.0 Phase 2 完成（預約系統 - 100%）⭐
  - 📋 下一步計劃（Phase 3 時間管理與筆記）
  - ⚡ 性能優化總覽

### 專案架構
- **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)**
  - 技術棧（Flutter 3.x + Supabase）
  - MVVM + Clean Architecture
  - 服務定位器（GetIt）
  - 檔案結構說明

### 資料庫設計
- **[DATABASE_SUPABASE.md](DATABASE_SUPABASE.md)**
  - 完整 Schema（12 個表）
  - RLS 策略與權限
  - 索引設計與優化
  - 查詢範例

### v2.0 SaaS 平台
- **[SAAS_PLATFORM_ROADMAP.md](SAAS_PLATFORM_ROADMAP.md)**
  - 完整 5 階段計劃
  - Phase 1：教練學員系統 ✅
  - Phase 2：預約系統 ✅（100%）⭐
  - Phase 3-5：進階功能

### UI/UX 設計
- **[UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md)**
  - Material Design 3 規範
  - 組件設計模式
  - 動畫與過渡效果
  - 響應式設計

### 部署指南
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)**
  - Android APK 建置
  - Google Sign-In 設定
  - Supabase 配置
  - 環境變數管理

---

## 🗂️ 已歸檔文檔

**重構與優化報告**（archived/）：
- `MAIN_THREAD_OPTIMIZATION.md` - 主線程優化報告
- `ARCHITECTURE_REFACTORING_GUIDE.md` - 架構重構指南
- `STATISTICS_PAGE_REFACTORING.md` - 統計頁面重構
- `BOOKING_PAGE_REFACTORING.md` - Booking 頁面重構

**階段性任務文檔**（archived/cursor_tasks/）：
- `01-05_TASK_*.md` - 各階段開發任務記錄

**Phase 1 文檔**（archived/phase1/）：
- `PHASE1_QUICK_START.md` - Phase 1 快速開始 ✅ 已完成
- `PHASE1_IMPLEMENTATION_GUIDE.md` - Phase 1 實作指南 ✅ 已完成

---

## 📊 當前專案狀態

### v1.0 單機版 ✅ 完成
- 訓練計劃管理
- 專業統計系統
- 身體數據追蹤
- 自訂動作功能
- Google Sign-In

### v2.0 Phase 1 ✅ 完成（2024-12-28）
- **教練學員系統**
  - 邀請學員功能
  - 學員列表管理
  - 狀態篩選（活躍/待接受/已歸檔）
  - 歸檔與刪除
  - 雙設備測試通過

**新增檔案**：17 個（完全解耦合設計）

### v2.0 Phase 2 ✅ 完成（2024-12-28）
- **預約系統**（教練設定時段 + 學員預約）
  - ✅ 資料庫 Migration（TSTZRANGE + GiST 排除約束）
  - ✅ Model 層（AppointmentModel + AvailabilitySlotModel）
  - ✅ Service 層（Interface + 實現 + 註冊）
  - ✅ Controller 層（2 個主控制器 + 8 個子模組）
  - ✅ UI 層（8 個頁面 + 20+ 組件）
  - ✅ 後端測試（8/8 通過）⭐
  - ✅ 功能測試（12/12 通過）⭐

**技術亮點**：
- PostgreSQL TSTZRANGE 時間範圍管理
- GiST 排除約束物理層防止雙重預約 ⭐
- 10 個 RLS 策略保護資料安全
- iCal RRULE 支援週期性時段
- PostgreSQL 時間戳正確解析 ⭐
- 雙角色支援（教練/學員）
- UI 組件化設計（平均 ~60 行）

**新增檔案**：35 個（完全解耦合設計）

---

## 🛠️ 開發工具

### Python 腳本
- **[scripts/README.md](../scripts/README.md)** - Python 工具使用指南
  - 資料庫結構文檔生成
  - 動作資料導出
  - 假訓練資料生成
  - 用戶資料重置

### 測試帳號
詳見 `scripts/README.md` 中的「測試用戶 UUID」章節

---

## 📝 開發規範

**核心規則**（必須遵守）：
1. ✅ 不破壞現有功能
2. ✅ 型別安全（透過 Model）
3. ✅ 依賴注入（透過 Interface）
4. ✅ 錯誤處理（使用 ErrorHandlingService）
5. ✅ 繁體中文註解與 UI 文字
6. ✅ 查詢效能規範（避免 SELECT *、使用 Cursor 分頁）

詳見：`AGENTS.md` - AI 開發助手規範

---

## 🔍 快速查找

**我想...**
- 了解專案當前狀態 → [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)
- 了解技術架構 → [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)
- 查看資料庫設計 → [DATABASE_SUPABASE.md](DATABASE_SUPABASE.md)
- 了解 v2.0 計劃 → [SAAS_PLATFORM_ROADMAP.md](SAAS_PLATFORM_ROADMAP.md)
- 設計 UI 組件 → [UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md)
- 部署應用 → [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- 使用 Python 工具 → [scripts/README.md](../scripts/README.md)

---

**維護者**：StrengthWise 開發團隊  
**最後更新**：2024年12月28日 - v2.0 Phase 2 完成 ✅
