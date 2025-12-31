# 📚 StrengthWise 文檔中心

> 專案文檔與開發指南

**最後更新**：2024年12月31日

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
  - ✅ v2.0 Phase 2 完成（預約系統）
  - ✅ v2.0 Phase 2.5 完成（時間工具統一化）
  - ✅ v2.0 Phase 3 完成 + 測試通過（視覺化筆記）⭐
  - ✅ v2.0 Phase 4A 完成 + 測試通過（完整手繪板）⭐⭐⭐
  - 📋 下一步計劃（語音筆記、AI 功能、Phase 4B）
  - ⚡ 性能優化總覽

### 專案架構
- **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)**
  - 技術棧（Flutter 3.x + Supabase）
  - MVVM + Clean Architecture
  - 服務定位器（GetIt）
  - 檔案結構說明

### 資料庫設計
- **[DATABASE_SUPABASE.md](DATABASE_SUPABASE.md)**
  - 完整 Schema（16 個表）
  - RLS 策略與權限
  - 索引設計與優化
  - Supabase Storage 配置 ⭐
  - 查詢範例

- **[DATABASE_OPTIMIZATION_GUIDE.md](DATABASE_OPTIMIZATION_GUIDE.md)**
  - 查詢效能優化
  - Cursor-based 分頁
  - 索引策略
  - RLS 優化

- **[DATABASE_STRUCTURE.md](DATABASE_STRUCTURE.md)**（自動生成）
  - 實時資料庫結構快照
  - 各表記錄數量
  - 欄位範例值

### v2.0 SaaS 平台
- **[SAAS_PLATFORM_ROADMAP.md](SAAS_PLATFORM_ROADMAP.md)**
  - 完整 5 階段計劃
  - Phase 1：教練學員系統 ✅
  - Phase 2：預約系統 ✅
  - Phase 3：視覺化筆記與雙向時間管理 ✅
  - Phase 4A：完整手繪板 ✅⭐⭐⭐
  - Phase 4B-5：進階功能（規劃中）

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

### 時間處理工具
- **[DATETIME_UTILS_GUIDE.md](DATETIME_UTILS_GUIDE.md)**
  - DateTimeUtils 工具類使用指南
  - PostgreSQL 時間戳解析
  - UTC 日期比較
  - 完整 API 參考

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

**Phase 3 文檔**（archived/phase3/）：
- `PHASE3_IMPLEMENTATION_DECISIONS.md` - Phase 3 設計決策 ✅ 已完成
- `PHASE3_TEST_PLAN.md` - Phase 3 測試計劃 ✅ 已完成

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

### v2.0 Phase 2.5 ✅ 完成（2024-12-29）
- **時間轉換工具統一化**（技術債重構）
  - ✅ 創建 `DateTimeUtils` 工具類（9 個方法）
  - ✅ 消除 76 行重複代碼（2 個 Model）
  - ✅ 簡化 Statistics Service UTC 邏輯
  - ✅ 創建 30 個單元測試（全部通過）
  - 詳見：[DATETIME_UTILS_GUIDE.md](DATETIME_UTILS_GUIDE.md)

**技術亮點**（Phase 2）：
- PostgreSQL TSTZRANGE 時間範圍管理
- GiST 排除約束物理層防止雙重預約 ⭐
- 10 個 RLS 策略保護資料安全
- iCal RRULE 支援週期性時段
- PostgreSQL 時間戳正確解析 ⭐
- 雙角色支援（教練/學員）
- UI 組件化設計（平均 ~60 行）

**新增檔案**：35 個（完全解耦合設計）

### v2.0 Phase 3 ✅ 完成 + 測試通過（2024-12-30）⭐⭐⭐
- **視覺化筆記與雙向時間管理**（100% 完成 + 測試驗證）
  - ✅ 資料庫層（469 行 Migration + 15 個 RLS 策略）
  - ✅ Model 層（7 個類別，完全解耦）
  - ✅ Service 層（5 個檔案 + 3 個子模組）
  - ✅ Storage 配置（3 個 Buckets + RLS 策略）⭐
  - ✅ Controller 層（2 個控制器 + 4 個子模組）
  - ✅ UI 層（18 個頁面/組件）⭐
  - ✅ 照片功能測試（100% 通過）⭐

**核心功能**：
- ✅ SOAP 格式專業筆記（S.O.A.P 四欄位）
- ✅ 照片拍攝與上傳（image_picker + file_picker for Windows）
- ✅ Supabase Storage 上傳（進度顯示 + 檔名清理）⭐
- ✅ Private/Shared 切換（RLS 保護）
- ✅ Storage RLS 學員隔離（不同學員看不到對方照片）⭐
- ✅ 筆記刪除自動清理照片 ⭐
- ✅ 學員時間偏好設定（TSTZRANGE + 優先級）
- ✅ 雙向時間管理系統（教練可查看學員偏好）⭐
- ⏸️ 照片標註功能 → 移至 Phase 4（完整手繪板）

**測試結果**（100% 通過）：
- ✅ 照片上傳與顯示（跨平台）
- ✅ Storage RLS 策略（學員隔離驗證）
- ✅ 筆記創建與綁定
- ✅ 學員時間偏好設定
- ✅ 教練查看學員偏好（只讀模式）

**新增檔案**：26 個，~5,000 行代碼
- Controller 層：7 個檔案（~1,800 行）
- UI 層：19 個檔案（~3,200 行）

### v2.0 Phase 4A ✅ 完成 + 測試通過（2024-12-31）⭐⭐⭐
- **完整手繪板**（100% 完成 + 7 個 Bug 修復）
  - ✅ 向量繪圖系統（JSONB 儲存，可編輯）
  - ✅ 4 種底圖模板（身體解剖圖）
  - ✅ 4 種繪圖工具（鉛筆/麥克筆/螢光筆/橡皮擦）
  - ✅ 底圖保護（擦除不影響底圖）⭐
  - ✅ 多繪圖支援（drawing.id 唯一識別）
  - ✅ 模式切換（繪圖 vs 查看）⭐⭐⭐
  - ✅ 只讀查看器（zoom + pan）
  - ✅ 權限控制（學員只讀）
  - ✅ 手機適配（橫向滾動工具列）⭐
  - ✅ 性能優化（RepaintBoundary + filterQuality）

**技術亮點**：
- ✅ CustomPainter 向量渲染
- ✅ JSONB 儲存（無需 Storage）
- ✅ Undo/Redo 堆疊
- ✅ 多圖層支援
- ✅ 顏色/粗細/透明度控制
- ✅ 完全解耦架構（Interface + GetIt）

**Bug 修復（7 個）**：
- ✅ 多繪圖保存邏輯（drawing.id 唯一識別）
- ✅ 編輯保存覆蓋繪圖（重新載入最新資料）
- ✅ 照片上傳 clientId 缺失
- ✅ 工具列溢出（橫向滾動）⭐
- ✅ GPU 緩衝區錯誤（RepaintBoundary）
- ✅ 縮放衝突（模式切換）⭐⭐⭐
- ✅ Debug 輸出

**新增檔案**：17 個
- Model 1 + Service 2 + Controller 3 + UI 7 + Migration 1

---

## 🎯 下一步工作（2025-01-01 起）

### ⭐⭐⭐ Phase 4B：教練多學員統計視圖（推薦優先）

**預計時間**：2-3 天

**核心發現**：v1.0 已完成完整統計系統（16 個模組），Phase 4B 只需新增學員切換功能！

**任務清單**：
1. 統計頁面新增學員選擇器（教練模式）
2. 複用現有 16 個統計組件
3. （可選）學員完成率總覽頁面
4. 測試

### 其他選項

- **選項 2**：深度測試與優化（3-5 天）- 確保現有功能穩定
- **選項 3**：UX 改進與導航優化（1 週）- 提升用戶體驗
- **選項 4**：準備 Beta 測試（1-2 週）- 上線準備

**詳細說明**：查看 [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) 末尾的「下一步工作項目」章節

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
**最後更新**：2024年12月31日 - v2.0 Phase 3 完成 + 文檔精簡 ✅
