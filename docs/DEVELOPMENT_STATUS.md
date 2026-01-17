# StrengthWise - 開發狀態

> 下一步計劃、當前版本、未來規劃

**當前版本**：v4.0（2026-01-17 完成）  
**上一版本**：v3.9（2026-01-17 完成）  
**維護者**：StrengthWise 開發團隊

---

## 📋 目錄

- [已完成版本](#已完成版本)
- [未來計劃](#未來計劃)
- [已完成功能](#已完成功能)

---

## 已完成版本

### ✅ v3.9 跨用戶即時同步 + FCM 完善（已完成）

> 詳細說明：[VERSION_HISTORY.md](archived/VERSION_HISTORY.md#v39-跨用戶即時同步--fcm-完善2026-01-17-完成)

- Realtime 跨用戶同步（4 個表：availability_slots、client_availability、appointments、workout_plans）
- FCM 推播完善（NotificationRouter、workout_plans 通知）
- EventBus 擴展（9 個新事件類型）
- BookingPage Tab 1 顯示教練自己的可上課時段
- 增量刪除優化 + ReasonInputDialog 共用組件

### ✅ v3.8 時間輸入 UX 優化（已完成）

> 詳細說明：[VERSION_HISTORY.md](archived/VERSION_HISTORY.md#v38-時間輸入-ux-優化2026-01-17-完成)

- TimeInputField 通用組件（分鐘:秒數雙欄位輸入）
- 訓練執行計時器（每 Set 倒數計時，自動完成 + 震動）
- 模板編輯優化（移除休息時間欄位）

### ✅ v3.7 快取架構統一（已完成）

> 詳細說明：[VERSION_HISTORY.md](archived/VERSION_HISTORY.md#v37-快取架構統一--di-優化--bug-修復2026-01-17-完成)

- 快取統一到 Service 層（Workout、Booking、Note、Custom Exercise）
- Controller Singleton 優化（ExerciseController、AuthController）
- Hive 解析修復、Box 名稱對齊
- 重複卡片 Bug、setState during build 修復
- Android 11+ URL 啟動支援

### ✅ v3.6 MVVM 純架構重構（已完成）

- MVVM 100% 合規（View 不再直接調用 Service）
- Controller 介面擴展（IStatisticsController、IWorkoutController 等）
- 60+ 個 View 檔案的 Service 調用改為 Controller

### ✅ v3.5 MVVM CUD 事件修復（已完成）

- View 層 CUD 操作改為透過 Controller
- 事件由 Controller 統一發布（AppEventBus）
- 13 個 View 檔案修復

---

## 未來計劃

### Phase 5+: 進階功能

| 優先級 | 項目 | 說明 |
|--------|------|------|
| 高 | Beta 測試準備 | 招募測試用戶、生產環境配置、性能驗證（perf-2~6）|
| 高 | App 版本檢查 | 設定頁顯示版本號、檢查更新、強制更新機制（Supabase app_config 表）|
| 中 | 訓練計劃模板市場 | 教練分享、學員訂閱 |
| 低 | 社群功能 | 動態分享、排行榜 |
| 低 | AI 功能 | 語音筆記（Whisper）、智能建議（GPT-4）|

### 架構優化（非緊急）

| 優先級 | 項目 | 說明 |
|--------|------|------|
| 低 | 統一 LocalCacheManager | 建立 Hive 快取統一入口，集中管理 5 個 LocalCacheService |
| 低 | Controller 接口統一 | 12 個 Controller 缺少接口（Profile、Coaching、Appointment、EventBus、SessionNote 等），涉及 62 處 View 調用 |

### 教練公開檔案未來擴展

PostGIS 地理搜尋、審核狀態機、評價系統、圖片上傳

### 延後項目

| 原編號 | 項目 | 說明 |
|--------|------|------|
| T-17 | 訓練動作卡 PREV | 顯示歷史重量/次數 |
| T-18 | 動作歷史彈窗 | 顯示完整歷史記錄 |
| WG-1~3 | Widget | Android/iOS 桌面小工具 |

---

## 已完成功能

| 版本 | 功能 |
|------|------|
| v1.0 | 單機版（訓練記錄、統計、794 動作）|
| v2.0 | 教練學員系統（Phase 1-4）|
| v2.1-v2.7 | 時區統一、登入驗證、UI 重構 |
| v2.8-v2.8.4 | 健康評估系統、教練評估備註、文檔重構 |
| v2.9-v2.9.1 | 教練公開檔案、訓練權限系統、UX 優化 |
| v3.0 | 預約系統優化、Session Mode、響應式 UI、FCM 推播 |
| v3.1 | Session Mode 完善、性能優化、首頁 UX、離線提示 |
| v3.2 | Coach Mark Onboarding、TrackingMode 擴充、Web PWA |
| v3.3 | TrackingMode 統計適配、PR 修復、Migrations 整理 |
| v3.4 | 傷病教練備註顯示、模板儲存優化 |
| v3.5 | MVVM CUD 事件修復（Controller 統一發布事件）|
| v3.6 | MVVM 純架構重構（View 完全透過 Controller）|
| v3.7 | 快取架構統一 + DI 優化 + Bug 修復 |
| v3.8 | 時間輸入 UX 優化 + 訓練執行計時器 |
| v3.9 | 跨用戶即時同步 + FCM 完善 + BookingPage 優化 |
| **v4.0** | **v3.9 進版（里程碑版本）** |

**詳細版本歷史**：[archived/VERSION_HISTORY.md](archived/VERSION_HISTORY.md)  
**技術架構**：[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)  
**規格書**：[planning/](planning/)

---

## 📊 專案狀態摘要

| 項目 | 狀態 |
|------|------|
| v1.0-v4.0 | ✅ 100% |
| 代碼品質 | ✅ 0 linter errors |
| MVVM 架構 | ✅ 100% 合規 |
| 快取架構 | ✅ Service 層統一管理 |
| Realtime 同步 | ✅ 跨用戶即時同步 |

**下一步重點**：
1. Beta 測試準備
2. 生產環境性能驗證

---

> ✅ **v4.0 完成**（2026-01-17）：跨用戶即時同步 + FCM 完善 + BookingPage 優化
>
> 📱 **Google Play**：v1.1.0+15（2026-01-17 發布）
>
> 🌐 **Web**：v1.1.0（2026-01-17 發布）
>
> 🤖 **CI/CD**：GitHub Actions 已配置（analyze + test + build）
