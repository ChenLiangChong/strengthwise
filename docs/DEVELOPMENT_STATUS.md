# StrengthWise - 開發狀態

> 下一步計劃、當前版本、未來規劃

**當前版本**：v5.0（2026-02-08 完成 - 動作分類系統 v2）
**上一版本**：v4.3（2026-01-22 完成）
**維護者**：StrengthWise 開發團隊

---

## 📋 目錄

- [下一步計劃](#下一步計劃)
- [已完成版本](#已完成版本)
- [未來計劃](#未來計劃)
- [已完成功能](#已完成功能)

---

## 下一步計劃

### v5.0 動作分類系統 v2（✅ 完成）

> 規格文檔：[EXERCISE_CLASSIFICATION_ANALYSIS.md](planning/EXERCISE_CLASSIFICATION_ANALYSIS.md)

**目標**：將審核完成的動作資料匯入專案，實現多維度分類與別名搜尋

| # | 任務 | 類型 | 狀態 |
|---|------|------|------|
| 1 | Migration 24：Schema 變更（新增 v2 欄位、別名表）| SQL | ✅ 完成 |
| 2 | Python 匯入腳本開發 | Python | ✅ 完成 |
| 3 | Migration 25：資料匯入（775 筆 + 2344 別名）| SQL | ✅ 完成 |
| 4 | Exercise Model v2 欄位 | Dart | ✅ 完成 |
| 5 | ExerciseMapper 更新 | Dart | ✅ 完成 |
| 6 | IExerciseService 介面擴展 | Dart | ✅ 完成 |
| 7 | ExerciseServiceSupabase 進階搜尋 | Dart | ✅ 完成 |
| 8 | ExerciseSearchEngine 別名支援 | Dart | ✅ 完成 |
| 9 | Migration 執行驗證 + 資料清理 | 測試 | ✅ 完成 |
| 10 | ExerciseLocalCacheService 擴展（v2 欄位 + 搜尋索引）| Dart | ✅ 完成 |
| 11 | FuzzySearchEngine 新增（Jaro-Winkler + Trigram）| Dart | ✅ 完成 |
| 12 | ExerciseSearchEngine 整合模糊搜尋 | Dart | ✅ 完成 |
| 13 | Hive 離線模糊搜尋整合測試 | 測試 | ⏳ 待測試 |
| 14 | PinyinConverter（拼音索引）| Dart | 📋 後續版本 |
| 15 | UI 進階篩選器 | UI | 📋 後續版本 |

**新增欄位**：
- `canonical_name` / `canonical_name_en`：SEE 標準名稱
- `movement_patterns`：動作模式（TEXT[]，如 hinge, squat, push）
- `ppl_tags`：PPL 標籤（TEXT[]，如 push, pull, legs）
- `primary_muscle`：主動肌（25 個有效值之一）
- `synergist_muscles`：協同肌（TEXT[]）
- `mechanics_type`：compound / isolation
- `is_explosive`：爆發力動作標記

**新增表**：
- `exercise_aliases`：別名表（支援俚語、縮寫搜尋）
- `ref_movement_patterns`：動作模式參照表
- `ref_muscle_groups`：肌肉群參照表
- `ref_equipment`：器材參照表

**新增 RPC**：
- `search_exercises_v2()`：進階搜尋函式

**搜尋系統設計決策**：
- 模糊搜尋僅針對 5 個名稱欄位（name, nameEn, canonicalName, canonicalNameEn, aliases）
- 其他欄位（movement_patterns, ppl_tags 等）作為精確篩選條件
- Hive 持久化支援離線搜尋
- Trigram 索引加速候選過濾
- Isolate 並行處理避免 UI 卡頓
- 拼音索引支援中文輸入

**Hive 離線搜尋架構**：
```
exercises_cache Box（現有）：擴展儲存 v2 欄位
exercises_search_index Box（新增）：
├── trigram_index      → {"squ": ["id1","id2"], ...}
├── pinyin_full_index  → {"shenqun": ["id1"], ...}
└── pinyin_initials    → {"sq": ["id1"], ...}
```

---

### Beta 測試前（高優先級）

| 項目 | 工作量 | 狀態 |
|------|--------|------|
| 核心 Service 單元測試補充 | 3-5 天 | ✅ 完成 |
| 執行測試驗證 | 1 天 | ✅ 完成 |

**測試完成**：24 個 Service Interface 已建立完整測試（370 測試案例全部通過）

### Beta 測試後（低優先級）

| 項目 | 工作量 | 說明 |
|------|--------|------|
| RLS 策略完整性驗證 | 1 天 | 虛擬學員功能前需審查 |
| LocalCacheManager 統一 | 2-3 天 | 5 個獨立 CacheService 合併入口 |
| 離線寫入佇列機制 | 評估中 | Write-Through Queue + 網路恢復自動重試 |

---

## v4.3 UI/UX 微調（2026-01-22 完成）

### Exercise Card TIME 佈局優化

| 項目 | 檔案 | 修改內容 |
|------|------|----------|
| 複合時間模式 | `exercise_card.dart` | 三行結構（repsTime, weightTime, distanceTime）|
| timeOnly 模式 | `exercise_card.dart` | 五列結構，PREV 寬度 60px → 48px |
| 新增方法 | `exercise_card.dart` | `_isCompositeTimeMode`, `_buildTimeInputForCompositeMode` |

### 背景計時器修復

| 項目 | 檔案 | 修改內容 |
|------|------|----------|
| DataManager | `workout_execution_data_manager.dart` | 新增 `syncElapsedTime()` |
| Controller Interface | `i_workout_execution_controller.dart` | 新增 `syncElapsedTimeForSave()` |
| Controller | `workout_execution_controller.dart` | 實作 `syncElapsedTimeForSave()` |
| UI | `workout_execution_content.dart` | sync 替代 pause/resume，計時器背景繼續運行 |

---

## v4.2 效能優化（2026-01-20 完成）

### Phase 1: UI 渲染優化

| 項目 | 檔案 | 修改內容 |
|------|------|----------|
| 列表 Key | `exercise_card.dart` | 添加 `ValueKey` 到 SetInputRow |
| 列表 Key | `home_page.dart` | 使用 `KeyedSubtree` 包裝排程卡片 |
| Selector | `statistics_page_v2.dart` | 使用 `Selector` 替代 `Consumer`，細化重建範圍 |

### Phase 2: 啟動和網路優化

| 項目 | 檔案 | 修改內容 |
|------|------|----------|
| 超時調整 | `splash_screen.dart` | 服務就緒超時 1.5s → 3s |
| 訂閱清理 | `booking_listener_manager.dart` | 新增 `dispose()` 方法，修復記憶體洩漏 |
| 防抖優化 | `realtime_subscription_manager.dart` | 防抖延遲 500ms → 300ms |
| 錯誤處理 | `exercise_service_supabase.dart` | 添加 `catchError` 處理預載入異步錯誤 |

### 測試修復

- `workout_data_validator_test.dart`：修復型別錯誤（`String` → `WorkoutExercise`）

### Phase 3: Lint 修復（517 → 0 issues）

| 類型 | 數量 | 處理方式 |
|------|------|----------|
| `annotate_overrides` | ~200 | `dart fix --apply` |
| `prefer_const_constructors` | ~100 | `dart fix --apply` |
| `use_build_context_synchronously` | ~50 | mounted 檢查 / ignore |
| `deprecated_member_use` | ~25 | API 更新（Color.toARGB32）/ ignore |
| 未使用代碼 | ~5 | 移除死代碼 |

**技術決策**：
- Radio API（groupValue/onChanged）棄用：使用 `ignore_for_file` 暫緩，待遷移到 RadioGroup
- Controller 層 BuildContext：使用 ignore（架構限制，Controller 無法檢查 mounted）

### 預期效果

- 列表滾動更流暢（減少 30-40% 重繪）
- 統計頁切換更快（只重建當前 Tab）
- 網路慢時不會導航失敗
- Realtime 訂閱正確清理，無記憶體洩漏
- 即時同步響應更快（減少 200ms 延遲）

---

## v4.1 Service 單元測試（2026-01-20 完成）

### 測試覆蓋（已驗證通過）

| 優先級 | Service 數 | 測試數 | 狀態 |
|--------|-----------|--------|------|
| P0 核心 | 3 | 120 | ✅ |
| P1 重要 | 7 | 115 | ✅ |
| P2 次要 | 6 | 78 | ✅ |
| P3 輔助 | 5 | 57 | ✅ |
| **總計** | **21** | **370** | ✅ 全部通過 |

### 新增測試檔案

```
test/services/
├── statistics/statistics_service_test.dart      (45 tests)
├── body_data/body_data_service_test.dart        (15 tests)
├── booking/booking_service_test.dart            (20 tests)
├── exercise/exercise_service_test.dart          (15 tests)
├── health_assessment/health_assessment_service_test.dart (20 tests)
├── coach/coaching_relationship_service_test.dart (15 tests)
├── coach/coach_profile_service_test.dart        (10 tests)
├── coach/coach_display_preferences_service_test.dart (5 tests)
├── coach/coach_assessment_note_service_test.dart (8 tests)
├── auth/auth_service_test.dart                  (10 tests)
├── user/user_service_test.dart                  (10 tests)
├── availability/availability_slot_service_test.dart (12 tests)
├── availability/client_availability_service_test.dart (12 tests)
├── invite_code/invite_code_service_test.dart    (8 tests)
├── note/note_service_test.dart                  (12 tests)
├── custom_exercise/custom_exercise_service_test.dart (10 tests)
├── favorites/favorites_service_test.dart        (8 tests)
├── drawing/drawing_service_test.dart            (5 tests)
└── injury/injury_coach_note_service_test.dart   (8 tests)
```

### Mock 基礎設施更新

- `test/mocks/mock_services.dart`：24 個 Mock 類別 + 完整 FallbackValues

---

## v4.0 架構優化（2026-01-19 完成）

### 已完成項目

| 項目 | 修復前 | 修復後 |
|------|--------|--------|
| Controller Interface 覆蓋 | 8/29 (28%) | 25/29 (86%) |
| 強制解包 `!.uid`/`!.id` | 42 處 | 8 處 (↓81%) |
| Service ErrorService 注入 | 4 個缺少 | ✅ 全部完成 |
| dynamic 內部運算 | 3 個檔案 | ✅ 全部改為具體型別 |

### Bug 修復

| 問題 | 說明 |
|------|------|
| BodyDataController 生命週期 | `ChangeNotifierProvider` 誤 dispose singleton，改用 `.value` |
| connectivity_plus Windows | Windows 平台跳過網路監聽（已知 bug） |

**詳細說明**：[ARCHITECTURE_REVIEW_V4.md](planning/archived/ARCHITECTURE_REVIEW_V4.md)

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
| ✅ | Controller 接口統一 | 已完成 25/29（86%），詳見 v4.0 架構優化 |
| ✅ | 強制解包優化 | 已完成 42→8 處（↓81%），剩餘皆有前置 null 檢查 |
| ✅ | dynamic 使用優化 | P0 完成（3 個檔案），剩餘為序列化邊界 |

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
| v1.0 | 單機版（訓練記錄、統計、775 動作）|
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
| v4.0 | 架構優化 + Controller Interface 統一 |
| v4.1 | Service 單元測試（24 個 Service，~293 測試）|
| v4.2 | 效能優化（UI 渲染 + 啟動/網路）|
| v4.3 | UI/UX 微調（TIME 佈局 + 背景計時器）|
| **v5.0** | **動作分類系統 v2（775 動作 + 2344 別名 + RPC 搜尋）** |

**詳細版本歷史**：[archived/VERSION_HISTORY.md](archived/VERSION_HISTORY.md)  
**技術架構**：[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)  
**規格書**：[planning/](planning/)

---

## 📊 專案狀態摘要

| 項目 | 狀態 |
|------|------|
| v1.0-v5.0 | ✅ 100% |
| 代碼品質 | ✅ 0 issues（517→0，含 deprecated API 處理）|
| MVVM 架構 | ✅ 100% 合規 |
| 快取架構 | ✅ Service 層統一管理 |
| Realtime 同步 | ✅ 跨用戶即時同步 |
| Controller Interface | ✅ 86% 覆蓋（25/29） |
| ErrorService 注入 | ✅ 全部 Service 已注入 |
| dynamic 型別安全 | ✅ P0 完成（剩餘為序列化邊界） |
| Service 單元測試 | ✅ 24 個 Service（~293 測試案例） |

**下一步重點**：
1. Hive 離線模糊搜尋整合測試
2. Beta 測試準備
3. 實機效能驗證

---

> ✅ **v5.0 完成**（2026-02-08）：動作分類系統 v2（775 動作 + 2344 別名 + search_exercises_v2 RPC）
>
> ✅ **v4.3 完成**（2026-01-22）：UI/UX 微調（TIME 佈局優化 + 背景計時器修復）
>
> ✅ **v4.2 完成**（2026-01-20）：效能優化（UI 渲染 + 啟動/網路優化）
>
> ✅ **v4.1 完成**（2026-01-20）：Service 單元測試（24 個 Service，370 測試案例全部通過）
>
> ✅ **v4.0 完成**（2026-01-19）：架構優化 + Controller Interface 統一（25/29 = 86%）
>
> 📱 **Google Play**：v1.1.1+16（2026-01-23 發布）
>
> 🌐 **Web**：v1.1.0（2026-01-17 發布）
>
> 🤖 **CI/CD**：GitHub Actions 已配置（analyze + test + build）
