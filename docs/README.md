# 📚 StrengthWise 文檔中心

> 專案文檔與開發指南

**最後更新**：2026年1月4日 - 文檔整理完成 ✅

---

## 🚀 快速開始

| 文檔 | 說明 | 必讀 |
|------|------|------|
| [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) | 📊 **精簡版**（800+ 行）：當前開發狀態、已完成功能、**詳細任務清單** | ⭐⭐⭐ |
| [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) | 🏗️ **精簡版**（518 行）：專案架構、技術棧、檔案結構 | ⭐⭐ |
| [SAAS_PLATFORM_ROADMAP.md](SAAS_PLATFORM_ROADMAP.md) | 🗺️ **精簡版**（1991 行）：v2.0 SaaS 平台完整計劃（Phase 1-5） | ⭐⭐ |
| [DATETIME_UTILS_GUIDE.md](DATETIME_UTILS_GUIDE.md) | ⏰ 時間轉換工具指南（v2.2 完整統一化） | ⭐⭐ |

---

## 📖 核心文檔

### 專案狀態
- **[DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)** ⭐⭐⭐ **必讀**（精簡版 738 行）
  - ✅ v1.0 單機版完成（個人健身記錄）
  - ✅ v2.0 Phase 1-4 全部完成（教練學員、預約、筆記、手繪板、統計、整合、行事曆）
  - ✅ Migrations 優化完成（19 → 7 個）⭐
  - ✅ 預約系統 UI 優化（2025-01-02）⭐
  - ⚡ 性能優化總覽（應用啟動 -92%、主線程優化 -96%、統計秒開 -99%）
  - **📋 詳細任務清單**（性能監控 6 項 + UX 優化 7 項 + Bug 檢查 3 項）⭐⭐⭐
  - 🎯 清晰結構：已完成摘要 → 技術總覽 → 下一步計劃 → 未來規劃

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

- **[../migrations/README.md](../migrations/README.md)** ⭐ 2025-01-01 新增
  - Migrations 優化（19 → 7 個檔案）
  - 清晰的版本劃分（v1.0 vs v2.0）
  - 執行順序說明
  - 部署指南（完整 vs 單機版）

### 健康評估系統
- **[HEALTH_ASSESSMENT_SYSTEM.md](HEALTH_ASSESSMENT_SYSTEM.md)** ⭐ v2.8 新增
  - 完整 PAR-Q+ 問卷系統
  - 視覺化評估報告
  - RLS 隱私保護
  - 教練評估備註（v2.8.1）✅

### v2.0 SaaS 平台
- **[SAAS_PLATFORM_ROADMAP.md](SAAS_PLATFORM_ROADMAP.md)**
  - 完整 5 階段計劃
  - Phase 1：教練學員系統 ✅
  - Phase 2：預約系統 ✅
  - Phase 3：視覺化筆記與雙向時間管理 ✅
  - Phase 4A：完整手繪板 ✅⭐⭐⭐
  - Phase 4C：教練學員頁面整合 ✅⭐⭐⭐
  - Phase 4D：統一行事曆系統 ✅⭐⭐⭐
  - Phase 4B：教練多學員統計視圖（完成）✅
  - Phase 5：進階功能（規劃中）

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
  - Email Authentication Deep Link 配置 ⭐
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
- `PERFORMANCE_BOTTLENECK_ANALYSIS.md` - 性能瓶頸分析

**UI/UX 設計**（archived/ui_ux/）：
- `UNIFIED_TIME_PICKER_DESIGN.md` - 統一時間選擇器設計（v2.0）

**階段性任務文檔**（archived/cursor_tasks/）：
- `01-05_TASK_*.md` - 各階段開發任務記錄

**Phase 1 文檔**（archived/phase1/）：
- `PHASE1_QUICK_START.md` - Phase 1 快速開始 ✅ 已完成
- `PHASE1_IMPLEMENTATION_GUIDE.md` - Phase 1 實作指南 ✅ 已完成

**Phase 3 文檔**（archived/phase3/）：
- `PHASE3_IMPLEMENTATION_DECISIONS.md` - Phase 3 設計決策 ✅ 已完成
- `PHASE3_TEST_PLAN.md` - Phase 3 測試計劃 ✅ 已完成

**v2.8 健康評估系統**（archived/v2.8_health_assessment/）：
- `COACH_ASSESSMENT_NOTES_IMPLEMENTATION.md` - 教練備註實作
- `COACH_ASSESSMENT_NOTES_COMPLETED.md` - 完成報告

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

### v2.0 Phase 4C ✅ 完成（2025-01-01）⭐⭐⭐
- **教練學員頁面整合**（100% 完成）
  - ✅ 教練為學員創建訓練（行事曆快速創建）⭐
  - ✅ 學員多教練切換（一對多關係）⭐
  - ✅ 行事曆整合時間偏好（背景色視覺化）
  - ✅ 完全解耦架構（100% Interface）
  - ✅ UI 整合（TrainingHubPage 統一入口）

**新增檔案**：18 個（Controller 2 + UI 15 + Hub 1）

### v2.0 Phase 4D ✅ 完成（2025-01-01）⭐⭐⭐
- **統一行事曆系統**（Layer-based Composition 架構）
  - ✅ 完全解耦的行事曆架構（8 個核心組件）⭐⭐⭐
  - ✅ 5 個頁面重構完成（-218 行重複代碼）
  - ✅ UI 樣式優化（原始 BookingPage 風格）⭐
  - ✅ 維護成本 -80%，開發效率 +70%

**技術亮點**：
- ✅ Layer-based Composition（單一職責 + 組合優於繼承）
- ✅ 7 個行事曆組件 → 1 個統一組件
- ✅ 100% 可測試（每個 Layer 獨立）
- ✅ 極易擴展（添加新 Layer 無需修改核心）

**新增檔案**：8 個（CalendarLayer + UnifiedCalendar + 2 Layers + 2 Models + Export）

---

## 🎯 下一步工作（2025-01-02 起）

### 當前狀態
- ✅ 核心功能開發完成（100%）
- ✅ 手繪板/照片/預約系統測試完成（100%）
- ⏳ **性能監控**（Day 2-3，6 項任務）
- ⏳ **UX 優化**（Day 4-5，7 項任務）
- ⏳ **Bug 檢查**（Day 6，3 項任務）

### 快速查找
- **完整任務清單**：[DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) → 「下一步計劃（詳細清單）」章節
- **測試步驟**：每個任務包含詳細執行步驟、工具使用、驗收標準
- **預計時間**：2-3 天完成所有任務

### 其他選項（測試完成後）
- **Onboarding 流程設計**（1 週）- 首次使用引導
- **準備 Beta 測試**（1-2 週）- 用戶文檔、測試計劃、生產環境
- **進階功能開發**（2-3 週，可選）- 模板市場、社群、進階統計

---

## 🛠️ 開發工具

### Python 腳本
- **[scripts/README.md](../scripts/README.md)** - Python 工具使用指南（✅ 2025-01-01 更新）
  - 資料庫完整下載（v2 全新版本）⭐
  - 資料庫結構文檔生成
  - 動作資料導出
  - 假訓練資料生成
  - 用戶資料重置
  - Migrations 優化工具（已歸檔）

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
**最後更新**：2026年1月4日 - 文檔整理完成 ✅（減少 3 個重複文檔，新增 1 個歸檔目錄）
