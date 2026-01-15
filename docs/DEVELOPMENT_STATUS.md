# StrengthWise - 開發狀態

> 下一步計劃、當前版本、未來規劃

**當前版本**：v3.6（2026-01-15 完成）  
**上一版本**：v3.5（2026-01-15 完成）  
**維護者**：StrengthWise 開發團隊

---

## 📋 目錄

- [v3.6 已完成](#v36-已完成)
- [未來計劃](#未來計劃)
- [已完成功能](#已完成功能)

---

## v3.6 已完成

> MVVM 純架構重構 - View 層完全透過 Controller 操作

### 完成項目

| 項目 | 說明 |
|------|------|
| ✅ MVVM 100% 合規 | View 層不再直接調用 Service（含 CUD 和 Query）|
| ✅ Controller 介面擴展 | 新增純查詢方法，支援 View 層數據獲取 |
| ✅ IStatisticsController 擴展 | 新增 6 個查詢方法（getStrengthProgress 等）|
| ✅ IWorkoutController 擴展 | 新增 getRecordById、getCoachCreatedPlans 等 |
| ✅ 全專案 Service 調用清理 | 60+ 個 View 檔案的 Service 調用改為 Controller |

### 架構成果

```
View Layer → Controller Layer → Service Layer
    ↑              ↑                 ↑
  只負責 UI      業務邏輯         數據存取
              + 事件發布        + 快取管理
              + 狀態管理        + 本地持久化
```

### 修改檔案（重點）

| 類型 | 檔案數 | 說明 |
|------|--------|------|
| Controller 介面 | 8+ | 新增純查詢方法到 Interface |
| View 層 | 60+ | Service 調用改為 Controller 調用 |
| main.dart | 1 | 使用 IAuthController/IStatisticsController |

### 擴展的 Controller 介面

| Controller | 新增方法 |
|------------|---------|
| `IStatisticsController` | `getStrengthProgress()`, `getExercisesWithRecords()`, `clearStatisticsCache()`, `warmupFromLocalCache()`, `preloadAllTimeRanges()`, `getStatistics()` |
| `IWorkoutController` | `getRecordById()`, `getCoachCreatedPlans()`, `getTodayPlans()`, `getUserTemplates()` |
| `ProfileController` | `getCurrentUserProfile()`, `getUserProfile()`, `upsertCoachAssessmentNote()` |
| `CoachingRelationshipController` | `getCoachClientsWithRelationship()`, `hasActiveCoach()` |
| `AppointmentController` | `getUserAppointments()` |

---

## ✅ v3.5 MVVM CUD 事件修復（已完成）

> View 層 CUD 操作改為透過 Controller，事件由 Controller 統一發布

### 已修復項目

| 檔案 | 原違規操作 | 修復方案 |
|------|----------|---------|
| `home_page.dart` | `_appointmentService.confirmAppointment()` | → `AppointmentController.confirmAppointment()` |
| `home_page.dart` | `_appointmentService.cancelAppointment()` | → `AppointmentController.rejectAppointment()` |
| `home_page.dart` | `_workoutService.deleteRecord()` | → `WorkoutController.deleteRecord()` |
| `booking_page.dart` | `_appointmentService.createAppointment()` | → `AppointmentController.createAppointment()` |
| `booking_page.dart` | `_workoutService.deleteRecord()` | → `WorkoutController.deleteRecord()` |
| `training_page.dart` | `_workoutService.createRecord()` | → `WorkoutController.createRecord()` |
| `template_editor_page.dart` | `_workoutService.createTemplate()` | → `WorkoutController.createTemplate()` |
| `template_editor_page.dart` | `_workoutService.updateTemplate()` | → `WorkoutController.updateTemplate()` |
| `plan_editor_page.dart` | `_workoutService.createTemplate()` | → `WorkoutController.createTemplate()` |
| `plan_editor_page.dart` | `_workoutService.create/updateRecord()` | → `WorkoutController.create/updateRecord()` |
| `adhoc_session_dialog.dart` | `_appointmentService.createAdHocSession()` | → `AppointmentController.createAdHocSession()` |
| `client_workout_calendar_tab.dart` | `_workoutService.deleteRecord()` | → `WorkoutController.deleteRecord()` |
| `template_management_page.dart` | `_workoutService.createRecord()` | → `WorkoutController.createRecord()` |

### Controller 事件發布

| Controller | 已內建事件 |
|------------|----------|
| `AppointmentController` | confirm/reject/cancel/complete/create/createAdHocSession 事件 |
| `WorkoutController` | template CUD + workout record CUD 事件 |
| `ClientManagementController` | workout CUD 事件 |
| `BodyDataController` | bodyDataUpdated 事件 |

### 額外修復項目（第二輪）

| 檔案 | 原違規操作 | 修復方案 |
|------|----------|---------|
| `health_assessment_page.dart` | `_healthService.create/updateAssessment()` | → `ProfileController.create/updateHealthAssessment()` |
| `health_assessment_page.dart` | `_injuryNoteService.delete/upsertNote()` | → `ProfileController.delete/upsertInjuryNote()` |
| `favorite_exercises_list.dart` | `_favoritesService.removeFavorite()` | → `ExerciseController.removeFavorite()` |
| `exercise_selection_navigator.dart` | `_favoritesService.add/removeFavorite()` | → `ExerciseController.add/removeFavorite()` |
| `exercise_strength_detail_page.dart` | `_favoritesService.add/removeFavorite()` | → `ExerciseController.add/removeFavorite()` |
| `client_management_page.dart` | `_relationshipService.deleteRelationship()` | → `CoachingRelationshipController.deleteRelationship()` |
| `coach_display_preferences_page.dart` | `_preferencesService.updatePreferences()` | → `CoachProfileController.updateDisplayPreferences()` |
| `booking_page.dart` | `_clientAvailabilityService.createAvailability()` | → `ClientAvailabilityController.createAvailability()` |

### Controller 方法擴展

| Controller | 新增方法 |
|------------|---------|
| `ExerciseController` | `addFavorite()`, `removeFavorite()` |
| `ProfileController` | `createHealthAssessment()`, `updateHealthAssessment()`, `deleteInjuryNote()`, `upsertInjuryNote()` |
| `CoachProfileController` | `updateDisplayPreferences()` |

### 架構優化成果

1. **事件發布集中**：所有需要跨頁面刷新的事件發布邏輯在 Controller 層統一處理
2. **維護簡化**：修改事件邏輯只需修改 Controller
3. **一致性保證**：透過 Controller 操作自動發布事件，不會遺漏

---

## 未來計劃

### Phase 5+: 進階功能

| 優先級 | 項目 | 說明 |
|--------|------|------|
| 高 | Beta 測試準備 | 招募測試用戶、生產環境配置、性能驗證（perf-2~6）|
| 中 | 訓練計劃模板市場 | 教練分享、學員訂閱 |
| 低 | 社群功能 | 動態分享、排行榜 |
| 低 | AI 功能 | 語音筆記（Whisper）、智能建議（GPT-4）|

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
| **v3.6** | **MVVM 純架構重構（View 完全透過 Controller）** |

**詳細版本歷史**：[archived/VERSION_HISTORY.md](archived/VERSION_HISTORY.md)  
**技術架構**：[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)  
**規格書**：[planning/](planning/)

---

## 📊 專案狀態摘要

| 項目 | 狀態 |
|------|------|
| v1.0-v3.6 | ✅ 100% |
| 代碼品質 | ✅ 0 linter errors |
| MVVM 架構 | ✅ 100% 合規 |

**下一步重點**：
1. Beta 測試準備
2. 生產環境性能驗證

---

> ✅ **v3.6 完成**（2026-01-15）：MVVM 純架構重構
>
> 📱 **Google Play**：內部測試已發布（v1.0.0），等待 Google 審核
>
> 🤖 **CI/CD**：GitHub Actions 已配置（analyze + test + build）
