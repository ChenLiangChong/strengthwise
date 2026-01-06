# StrengthWise 終極測試策略文檔

> 為 Google Play 上架做準備的 **超完整** 測試計劃

**最後更新**：2026-01-07  
**目標版本**：v3.1-A  
**總測試數**：**444+**

---

## 📋 目錄

0. [🚨 上架必備速查](#-上架必備速查160-個--12-hr)
1. [總覽與統計](#總覽與統計)

**▸ 上架必備測試**
2. [P13：Google Play 合規性](#p13google-play-合規性)
3. [P14：設備兼容性](#p14設備兼容性)
4. [P15：發布與打包](#p15發布與打包)
5. [P18：網路與穩定性](#p18網路與穩定性)
6. [P19：第三方 SDK](#p19第三方-sdk)
7. [P20：RLS 安全性](#p20rls-安全性)
8. [P21：Patrol 原生自動化](#p21patrol-原生自動化)

**▸ 核心功能測試**
7. [P0：工具類與純函數](#p0工具類與純函數)
8. [P1：Model 序列化與邏輯](#p1model-序列化與邏輯)
9. [P2：Service 層測試](#p2service-層測試)
10. [P3：Controller 層測試](#p3controller-層測試)
11. [P4：Widget 測試](#p4widget-測試)

**▸ 進階功能測試**
12. [P5：整合測試](#p5整合測試)
13. [P6：即時通訊與推播](#p6即時通訊與推播)
14. [P7：響應式 UI](#p7響應式-ui)
15. [P8：快取層](#p8快取層)
16. [P9：Edge Functions](#p9edge-functions)
17. [P10：Edge Cases 與安全](#p10edge-cases-與安全)
18. [P11：效能測試](#p11效能測試)
19. [P12：無障礙與使用者體驗](#p12無障礙與使用者體驗)
20. [P16：深連結與導航](#p16深連結與導航)
21. [P17：資料備份與遷移](#p17資料備份與遷移)

---

## 🚨 上架必備速查（182 個 / 14.5 hr）

> **Google Play 上架前必須完成的測試清單**

### 核心功能（120 個 / 7.5 hr）

| 類別 | 必測項目 | 數量 |
|------|---------|------|
| **P0** | DateTimeUtils、紅綠燈算法、CanvasUtils | 40 |
| **P1** | WorkoutRecord、AppointmentModel、SessionNoteModel、HealthAssessmentModel | 50 |
| **P2** | AppointmentService、WorkoutService、SessionNoteService | 30 |

### Google Play 強制要求（26 個 / 3 hr）

| 類別 | 必測項目 | 數量 |
|------|---------|------|
| **P13** | 隱私政策、帳號刪除、API 34、權限說明 | 10 |
| **P15** | APK 簽名、App Bundle、64 位、混淆驗證 | 8 |
| **P19** | Google Sign-In 全流程、Supabase 重連 | 8 |

### 穩定性保障（14 個 / 1.5 hr）

| 類別 | 必測項目 | 數量 |
|------|---------|------|
| **P14** | Android 8/12/13/14、小螢幕、大螢幕、低 RAM、旋轉 | 8 |
| **P18** | Monkey 測試、ANR 檢測、弱網、網路切換、長時運行、背景恢復 | 6 |

### 安全性與自動化（22 個 / 2.5 hr）

| 類別 | 必測項目 | 數量 |
|------|---------|------|
| **P20** | RLS 策略驗證、用戶隔離、教練學員權限、教練操作學員資料 | 14 |
| **P21** | Patrol 權限彈窗、通知驗證、冷啟動跳轉、E2E 流程 | 12 |

### ⚡ 快速檢查清單

```
□ 隱私政策連結有效
□ 帳號刪除功能可用
□ targetSdkVersion >= 34
□ 64 位架構支援
□ APK 簽名正確
□ Google Sign-In 流程正常
□ Monkey 10 分鐘無崩潰
□ 弱網環境可用
□ Android 8.0 最低版本可運行
□ RLS 策略全覆蓋驗證
□ service_role 金鑰未洩漏
□ 通知權限彈窗正常
□ 冷啟動點擊通知跳轉正確
```

---

## 總覽與統計

### 🚨 上架必備測試（70 個 / 8 hr）

| 優先級 | 類別 | 測試數 | 預估時間 |
|--------|------|--------|----------|
| **P13** | Google Play 合規 | 10 | 1 hr |
| **P14** | 設備兼容性 | 12 | 1.5 hr |
| **P15** | 發布與打包 | 8 | 1 hr |
| **P18** | 網路與穩定性 | 10 | 1 hr |
| **P19** | 第三方 SDK | 8 | 1 hr |
| **P20** | RLS 安全性 | 14 | 1.5 hr |
| **P21** | Patrol 原生自動化 | 12 | 1.5 hr |

### 核心功能測試（245 個 / 15.5 hr）

| 優先級 | 類別 | 測試數 | 預估時間 |
|--------|------|--------|----------|
| **P0** | 工具類/純函數 | 40 | 2.5 hr |
| **P1** | Model 序列化 | 70 | 4 hr |
| **P2** | Service 層 | 60 | 4 hr |
| **P3** | Controller 層 | 45 | 3 hr |
| **P4** | Widget 測試 | 30 | 2 hr |

### 進階功能測試（126 個 / 11 hr）

| 優先級 | 類別 | 測試數 | 預估時間 |
|--------|------|--------|----------|
| **P5** | 整合測試 | 18 | 2 hr |
| **P6** | 推播/Realtime | 18 | 1.5 hr |
| **P7** | 響應式 UI | 15 | 1 hr |
| **P8** | 快取層 | 12 | 1 hr |
| **P9** | Edge Functions | 8 | 1 hr |
| **P10** | 安全/Edge Cases | 25 | 2 hr |
| **P11** | 效能測試 | 10 | 1 hr |
| **P12** | 無障礙/UX | 8 | 0.5 hr |
| **P16** | 深連結/導航 | 6 | 0.5 hr |
| **P17** | 資料備份/遷移 | 6 | 0.5 hr |

### 📊 總計

| | 測試數 | 時間 |
|--|--------|------|
| **全部** | **445** | **~35.5 hr** |

---

# 🚨 Part 1：上架必備測試

---

## P13：Google Play 合規性（10 個）

### 隱私與資料政策（5 個）

| # | 測試案例 |
|---|----------|
| 390 | 隱私政策連結可點擊且有效 |
| 391 | 資料收集聲明完整（收集哪些、用途）|
| 392 | 帳號刪除功能可用（Google Play 強制要求）|
| 393 | 刪除帳號後資料完全清除 |
| 394 | 敏感權限使用說明（相機、儲存）|

### 應用商店要求（5 個）

| # | 測試案例 |
|---|----------|
| 395 | 目標 API Level ≥ 34（2024 要求）|
| 396 | 年齡分級內容符合宣告 |
| 397 | 無違規廣告/內購行為 |
| 398 | App 名稱/圖示/截圖符合規範 |
| 399 | 功能說明與實際功能一致 |

---

## P14：設備兼容性（12 個）

### Android 版本（4 個）

| # | 測試案例 |
|---|----------|
| 400 | Android 8.0 (API 26) - 最低版本 |
| 401 | Android 12 (API 31) - 隱私變更 |
| 402 | Android 13 (API 33) - 通知權限 |
| 403 | Android 14 (API 34) - 目標版本 |

### 螢幕與硬體（8 個）

| # | 測試案例 |
|---|----------|
| 404 | 小螢幕 (5 吋, hdpi) |
| 405 | 大螢幕 (6.7 吋, xxhdpi) |
| 406 | 平板 (10 吋, mdpi) |
| 407 | 折疊屏展開/折疊切換 |
| 408 | 低 RAM 設備 (2GB) |
| 409 | 螢幕旋轉狀態保持 |
| 410 | 分割畫面模式 |
| 411 | 深色/淺色主題切換 |

---

## P15：發布與打包（8 個）

### 建置驗證（4 個）

| # | 測試案例 |
|---|----------|
| 412 | Release APK 簽名正確 |
| 413 | App Bundle 分包正確 |
| 414 | 64 位元架構支援 |
| 415 | ProGuard/R8 混淆後功能正常 |

### 安裝與更新（4 個）

| # | 測試案例 |
|---|----------|
| 416 | 全新安裝流程 |
| 417 | 覆蓋安裝（舊版→新版）|
| 418 | 資料遷移（升級後資料保留）|
| 419 | 降級阻止（不允許安裝舊版）|

---

## P18：網路與穩定性（10 個）

### 網路狀態（5 個）

| # | 測試案例 |
|---|----------|
| 432 | 弱網環境（3G/Edge）請求成功 |
| 433 | 網路切換（WiFi↔行動）不中斷 |
| 434 | 請求超時正確處理與重試 |
| 435 | 離線操作佇列與恢復同步 |
| 436 | 飛航模式開關資料不丟失 |

### 穩定性（5 個）

| # | 測試案例 |
|---|----------|
| 437 | Monkey 測試 10 分鐘無崩潰 |
| 438 | 連續快速操作（狂點）不 ANR |
| 439 | 長時間運行（1hr）記憶體穩定 |
| 440 | 背景 30 分鐘後恢復前景正常 |
| 441 | 低電量模式功能正常 |

---

## P19：第三方 SDK（8 個）

### Google Sign-In（4 個）

| # | 測試案例 |
|---|----------|
| 442 | 首次登入完整流程 |
| 443 | 已登入帳號自動選擇 |
| 444 | 登入取消正確處理 |
| 445 | Token 過期自動刷新 |

### Supabase SDK（4 個）

| # | 測試案例 |
|---|----------|
| 446 | Realtime 連線斷線重連 |
| 447 | Auth Session 過期處理 |
| 448 | Storage 上傳失敗重試 |
| 449 | 批量請求限流處理 |

---

## P20：RLS 安全性（14 個）

### 策略驗證（6 個）

| # | 測試案例 |
|---|----------|
| 450 | 用戶只能讀取自己的 workout_records |
| 451 | 教練可讀取學員的訓練記錄（關係存在時）|
| 452 | 學員無法讀取其他學員的數據 |
| 453 | anon 角色無法寫入任何表 |
| 454 | service_role 繞過所有 RLS |
| 455 | 刪除用戶後關聯數據級聯刪除 |

### 教練操作學員資料（4 個）⭐ v3.1

| # | 測試案例 |
|---|----------|
| 456 | daily_workout_summary：教練可 SELECT 學員統計 |
| 457 | daily_workout_summary：教練可 INSERT/UPDATE/DELETE 學員統計 |
| 458 | personal_records：教練可 CRUD 學員 PR |
| 459 | 無活躍關係時教練無法存取學員資料 |

### 邊界與性能（4 個）

| # | 測試案例 |
|---|----------|
| 460 | RLS 策略中的索引覆蓋驗證 (EXPLAIN ANALYZE) |
| 461 | 大數據量下 RLS 查詢延遲 < 100ms |
| 462 | 複雜多表 JOIN 的 RLS 正確性 |
| 463 | JWT Claims 過期後的權限拒絕 |

---

## P21：Patrol 原生自動化（12 個）

### 權限交互（4 個）

| # | 測試案例 |
|---|----------|
| 460 | 自動點擊「允許通知」權限彈窗 |
| 461 | 自動點擊「允許相機」權限彈窗 |
| 462 | 權限拒絕後的 UI 引導正確顯示 |
| 463 | 系統設置頁面跳轉正常 |

### 通知驗證（4 個）

| # | 測試案例 |
|---|----------|
| 464 | 下拉通知欄驗證通知標題/內容 |
| 465 | 點擊通知跳轉到正確頁面 |
| 466 | 終止狀態點擊通知冷啟動跳轉 |
| 467 | 多通知堆疊時點擊正確處理 |

### 端到端流程（4 個）

| # | 測試案例 |
|---|----------|
| 468 | 完整預約流程（選時段→確認→收到通知）|
| 469 | 課前問卷提交→教練收到推播 |
| 470 | 訓練完成→學員收到摘要通知 |
| 471 | 離線操作→恢復網路→同步成功 |

---

# 📦 Part 2：核心功能測試

---

## P0：工具類與純函數（40 個）

### DateTimeUtils（12 個）

| # | 方法 | 測試案例 |
|---|------|----------|
| 1 | `parsePostgresTimestamp` | 標準格式轉本地時間 |
| 2 | `parsePostgresTimestamp` | 帶引號格式 |
| 3 | `parsePostgresTimestampUtc` | 保持 UTC |
| 4 | `parseIsoTimestamp` | ISO 8601 |
| 5 | `formatToUtcIso` | 本地 → UTC ISO |
| 6 | `parseTstzRange` | `[start,end)` |
| 7 | `parseTstzRangeUtc` | UTC 版本 |
| 8 | `formatToTstzRange` | DateTime → TSTZRANGE |
| 9 | `getUtcDate` | 忽略時間 |
| 10 | `compareUtcDates` | 日期比較 |
| 11 | `isWithinUtcDateRange` | 範圍判斷 |
| 12 | `formatToDateOnly` | YYYY-MM-DD |

### BodyPartUtils（6 個）

| # | 測試案例 |
|---|----------|
| 13 | 英文 → 中文翻譯 |
| 14 | 部位 → Emoji |
| 15 | 部位 → 顏色 |
| 16 | 標準化名稱 |
| 17 | 未知部位預設值 |
| 18 | 空字串處理 |

### CanvasUtils（8 個）

| # | 測試案例 |
|---|----------|
| 19 | 點陣列 → Path |
| 20 | Path → 點陣列 |
| 21 | 計算邊界 |
| 22 | 序列化繪圖 |
| 23 | 反序列化繪圖 |
| 24 | 空點陣列 |
| 25 | 單點陣列 |
| 26 | 大量點（1000+）|

### 紅綠燈算法（8 個）

| # | 測試案例 |
|---|----------|
| 27 | 全最佳 → 🟢 100 |
| 28 | 邊界綠 → 🟢 70 |
| 29 | 黃燈 → 🟡 50-69 |
| 30 | 低分紅 → 🔴 <50 |
| 31 | 單項=1 強制 🔴 |
| 32 | sleep<4hr 強制 🔴 |
| 33 | 睡眠時數轉分數（6 個邊界）|
| 34 | 權重計算驗證 |

### NotificationUtils（6 個）

| # | 測試案例 |
|---|----------|
| 35 | 格式化推播標題 |
| 36 | 格式化推播內容 |
| 37 | 解析 payload |
| 38 | 生成通知 ID |
| 39 | 通知優先級判斷 |
| 40 | 深連結解析 |

---

## P1：Model 序列化與邏輯（70 個）

### ReadinessMetrics（6 個）

| # | 測試案例 |
|---|----------|
| 41-46 | fromJson/toJson/copyWith/empty/emoji/預設值 |

### TrafficLight（4 個）

| # | 測試案例 |
|---|----------|
| 47-50 | fromString/null/invalid/getter |

### DailyReadinessModel（8 個）

| # | 測試案例 |
|---|----------|
| 51-58 | fromSupabase/toSupabase/copyWith/isSubmitted/needsAttention/statusSummary/shortSummary/create |

### AppointmentModel（10 個）

| # | 測試案例 |
|---|----------|
| 59-68 | TSTZRANGE/toMap/duration/狀態判斷/copyWith/未知狀態/displayName/colorHex/跨日/空notes |

### AppointmentStatus（4 個）

| # | 測試案例 |
|---|----------|
| 69-72 | toSupabaseString/displayName/colorHex/狀態流轉 |

### WorkoutRecord（12 個）

| # | 測試案例 |
|---|----------|
| 73-84 | fromJson/toJson/fromSupabase/fromWorkoutPlan/copyWith/markAsCompleted/updateNotes/addExercise/updateExercise/removeExercise/trainingStatus/elapsedSeconds |

### ExerciseRecord（6 個）

| # | 測試案例 |
|---|----------|
| 85-90 | fromJson/toJson/addSet/removeSet/toggleCompletion/完成百分比 |

### SetRecord（4 個）

| # | 測試案例 |
|---|----------|
| 91-94 | fromJson/toJson/copyWith/完成狀態 |

### SessionNoteModel（8 個）

| # | 測試案例 |
|---|----------|
| 95-102 | fromSupabase/toSupabase/copyWith/SOAP/visualElements/quickTags/visibility/hidden |

### SoapNoteModel（4 個）

| # | 測試案例 |
|---|----------|
| 103-106 | fromJson/toJson/copyWith/isEmpty |

### VisualElementModel（4 個）

| # | 測試案例 |
|---|----------|
| 107-110 | fromJson/toJson/type 枚舉/path 處理 |

### HealthAssessmentModel（10 個）

| # | 測試案例 |
|---|----------|
| 111-120 | fromSupabase/toSupabase/copyWith/warningSummary/PAR-Q+/傷病史/訓練目標/emergency/version/isCurrent |

### InjuryRecord（3 個）

| # | 測試案例 |
|---|----------|
| 121-123 | fromJson/toJson/copyWith |

### TrainingGoals（3 個）

| # | 測試案例 |
|---|----------|
| 124-126 | fromJson/toJson/copyWith |

### 統計 Models（10 個）

| # | Model | 測試 |
|---|-------|------|
| 127-136 | TrainingVolume/CompletionRate/PersonalRecord/StrengthProgress/BodyPartStats/MuscleGroupBalance/TrainingFrequency/TimeRange/TrainingCalendar/TrainingSuggestion |

### 其他 Models（4 個）

| # | Model | 測試 |
|---|-------|------|
| 137 | InviteCodeModel | 序列化/過期判斷 |
| 138 | CoachingRelationshipModel | 狀態 |
| 139 | AvailabilitySlotModel | 時間範圍 |
| 140 | DrawingNoteModel | 筆畫資料 |

---

## P2：Service 層測試（60 個）

### ReadinessService（8 個）

| # | 方法 |
|---|------|
| 141 | getByAppointmentId |
| 142 | getByUserAndDate |
| 143 | getRecentByUser |
| 144 | createReadiness |
| 145 | updateReadiness |
| 146 | getClientReadiness |
| 147 | batchGetLatestReadiness |
| 148 | 錯誤處理 |

### AppointmentService（10 個）

| # | 方法 |
|---|------|
| 149-158 | getCoachAppointments/getClientAppointments/getById/getPending/checkConflict/create/confirm/cancel/createAdHocSession/getLastCompleted |

### WorkoutService（8 個）

| # | 方法 |
|---|------|
| 159-166 | getUserPlans/getRecordById/getByAppointmentId/createRecord/updateRecord/deleteRecord/checkTimeOverlap/getExerciseHistory |

### SessionNoteService（10 個）

| # | 方法 |
|---|------|
| 167-176 | getCoachNotes/getClientNotes/getNoteById/getNotesByAppointment/createNote/updateNote/deleteNote/toggleVisibility/hideNote/searchNotes |

### StatisticsService（12 個）

| # | 方法 |
|---|------|
| 177-188 | getStatistics/getTrainingFrequency/getVolumeHistory/getBodyPartStats/getSpecificMuscleStats/getTrainingTypeStats/getEquipmentStats/getPersonalRecords/getStrengthProgress/getMuscleGroupBalance/getTrainingCalendar/getCompletionRate |

### CoachingRelationshipService（6 個）

| # | 方法 |
|---|------|
| 189-194 | getMyClients/getMyCoaches/createInviteCode/validateInviteCode/acceptInvitation/terminateRelationship |

### HealthAssessmentService（4 個）

| # | 方法 |
|---|------|
| 195-198 | getByUserId/create/update/getHistory |

### DrawingService（2 個）

| # | 方法 |
|---|------|
| 199-200 | saveDrawing/getDrawing |

---

## P3：Controller 層測試（45 個）

### WorkoutExecutionController（15 個）

| # | 方法 |
|---|------|
| 201-215 | loadWorkoutPlan/reloadForRealtime/canModify/canEdit/canToggleCompletion/shouldShowTimerUI/setPermissionOverride/toggleSetCompletion/updateSetData/startTraining/pauseTraining/resumeTraining/completeTraining/isCoachViewingTrainee/autoSave |

### SessionModeController（10 個）

| # | 方法 |
|---|------|
| 216-225 | loadSession/subscribeToRealtime/unsubscribe/updateSOAP/autoSaveDebounce/uploadPhoto/saveDrawing/addExercise/學員模式/教練模式 |

### ReadinessController（5 個）

| # | 方法 |
|---|------|
| 226-230 | loadReadiness/updateMetrics/submitReadiness/表單驗證/即時計算 |

### AppointmentController（5 個）

| # | 方法 |
|---|------|
| 231-235 | loadAppointments/confirmAppointment/cancelAppointment/狀態過濾/日期範圍 |

### AuthController（5 個）

| # | 方法 |
|---|------|
| 236-240 | signInWithEmail/signUp/signOut/resetPassword/錯誤處理 |

### BookingController（5 個）

| # | 方法 |
|---|------|
| 241-245 | loadAvailableSlots/selectSlot/confirmBooking/日期切換/時段篩選 |

---

## P4：Widget 測試（30 個）

### 表單組件（10 個）

| # | Widget |
|---|--------|
| 246 | EmojiSlider - 拖拉互動 |
| 247 | EmojiSlider - 值變更回調 |
| 248 | EmojiSlider - 邊界值 1-5 |
| 249 | TimeGridView - 時段選擇 |
| 250 | TimeGridView - 已預約標記 |
| 251 | HorizontalDatePicker - 日期選擇 |
| 252 | HorizontalDatePicker - 滑動 |
| 253 | BookingConfirmationSheet |
| 254 | DateTimePicker |
| 255 | TimePicker |

### 卡片組件（10 個）

| # | Widget |
|---|--------|
| 256 | ReadinessCard - 紅綠燈 |
| 257 | ReadinessCard - 分數 |
| 258 | AppointmentCard - 狀態 |
| 259 | AppointmentCard - 開始課程按鈕 |
| 260 | PlanExerciseCard - PREV |
| 261 | SessionNoteCard - SOAP |
| 262 | QuickRebookCard |
| 263 | HealthAssessmentCard |
| 264 | StatisticsCard |
| 265 | ClientCard |

### 手繪組件（5 個）

| # | Widget |
|---|--------|
| 266 | DrawingCanvas - 繪製 |
| 267 | DrawingCanvas - 撤銷/重做 |
| 268 | DrawingCanvas - 清除 |
| 269 | DrawingCanvas - 保存 |
| 270 | DrawingToolbar |

### 載入/狀態組件（5 個）

| # | Widget |
|---|--------|
| 271 | SkeletonLoader |
| 272 | EmptyStateWidget |
| 273 | ErrorStateWidget |
| 274 | LoadingOverlay |
| 275 | RefreshIndicator |

---

# 🔧 Part 3：進階功能測試

---

## P5：整合測試（18 個）

### 預約流程（6 個）

| # | 流程 |
|---|------|
| 276 | 學員選時段 → 確認 → requested |
| 277 | 教練確認 → confirmed → 自動創建 |
| 278 | 教練拒絕 → rejected |
| 279 | 任一方取消 → cancelled |
| 280 | 臨時課程 → confirmed |
| 281 | 一鍵續約 → 預填資料 |

### Session Mode 流程（6 個）

| # | 流程 |
|---|------|
| 282 | 進入課程 → 3 Tab |
| 283 | 訓練打勾 → 自動保存 |
| 284 | SOAP 輸入 → Debounce |
| 285 | Realtime 教練↔學員 |
| 286 | 課程結束 → SOAP 提醒 |
| 287 | 學員唯讀模式 |

### 課前問卷流程（6 個）

| # | 流程 |
|---|------|
| 288 | 填問卷入口 |
| 289 | 5 維度滑桿 |
| 290 | 提交 → 計算分數 |
| 291 | 紅綠燈顯示 |
| 292 | 教練查看 ReadinessCard |
| 293 | 通知教練（FCM）|

---

## P6：即時通訊與推播（18 個）

### NotificationService（10 個）

| # | 方法 |
|---|------|
| 294 | initialize |
| 295 | getToken |
| 296 | saveTokenToDatabase |
| 297 | removeTokenFromDatabase |
| 298 | listenForTokenChanges |
| 299 | showLocalNotification |
| 300 | cancelAllNotifications |
| 301 | requestPermission |
| 302 | hasPermission |
| 303 | dispose |

### SessionRealtimeService（5 個）

| # | 方法 |
|---|------|
| 304 | subscribeToWorkoutPlan |
| 305 | subscribeToSessionNote |
| 306 | unsubscribe |
| 307 | unsubscribeAll |
| 308 | dispose |

### 推播場景（3 個）

| # | 場景 |
|---|------|
| 309 | 前景接收通知 |
| 310 | 背景接收通知 |
| 311 | 點擊通知跳轉 |

---

## P7：響應式 UI（15 個）

### ResponsiveBreakpoints（7 個）

| # | 方法 |
|---|------|
| 312 | getScaleFactor - 各斷點 |
| 313 | getScreenType - 各類型 |
| 314 | isMobile |
| 315 | isTablet |
| 316 | isDesktop |
| 317 | 斷點邊界值 |
| 318 | 縮放係數連續性 |

### ResponsiveExtensions（4 個）

| # | 方法 |
|---|------|
| 319 | context.cardPadding |
| 320 | context.spacing |
| 321 | context.isMobile |
| 322 | context.screenType |

### ResponsiveBuilder（2 個）

| # | 方法 |
|---|------|
| 323 | builder 回調 |
| 324 | 斷點切換 |

### 佈局測試（2 個）

| # | 場景 |
|---|------|
| 325 | NavigationRail 顯示 |
| 326 | Master-Detail 分欄 |

---

## P8：快取層（12 個）

### ExerciseLocalCacheService（6 個）

| # | 方法 |
|---|------|
| 327 | getExerciseById - 快取命中 |
| 328 | getExerciseById - 快取未命中 |
| 329 | searchExercises |
| 330 | invalidateCache |
| 331 | 快取過期 |
| 332 | 離線存取 |

### FavoritesService（6 個）

| # | 方法 |
|---|------|
| 333 | addFavorite |
| 334 | removeFavorite |
| 335 | isFavorite |
| 336 | getFavoriteExercises |
| 337 | clearFavorites |
| 338 | 持久化 |

---

## P9：Edge Functions（8 個）

### push-notify（3 個）

| # | 場景 |
|---|------|
| 339 | 有效 payload |
| 340 | 無效 token 處理 |
| 341 | 錯誤回應格式 |

### readiness-notify（2 個）

| # | 場景 |
|---|------|
| 342 | 學員提交 → 通知教練 |
| 343 | 紅綠燈資訊正確 |

### session-reminder（3 個）

| # | 場景 |
|---|------|
| 344 | 課前 1hr 觸發 |
| 345 | 雙方都收到 |
| 346 | 已取消不通知 |

---

## P10：Edge Cases 與安全（25 個）

### 邊界條件（10 個）

| # | 場景 |
|---|------|
| 347 | 空列表（無訓練記錄）|
| 348 | 超長文字（10000 字）|
| 349 | 特殊字符（Emoji、換行）|
| 350 | 極端時區（UTC+14）|
| 351 | 跨日預約（23:00-01:00）|
| 352 | 閏年（2024-02-29）|
| 353 | 大量資料（1000 筆）|
| 354 | 並發操作 |
| 355 | 離線狀態 |
| 356 | 低記憶體 |

### 安全測試（15 個）

| # | 場景 |
|---|------|
| 357 | 未登入存取 → redirect |
| 358 | 他人資料 → 403 |
| 359 | 過期 Token → refresh |
| 360 | 無效 Token → logout |
| 361 | SQL Injection 輸入 |
| 362 | XSS 輸出過濾 |
| 363 | RLS 教練↔學員 |
| 364 | RLS 學員↔學員（禁止）|
| 365 | Storage 私人檔案 |
| 366 | Storage 簽名 URL |
| 367 | 敏感資料遮罩 |
| 368 | 日誌不含密碼 |
| 369 | 刪除帳號清除 |
| 370 | 密碼強度驗證 |
| 371 | 請求限流（Rate Limit）|

---

## P11：效能測試（10 個）

| # | 指標 | 目標 |
|---|------|------|
| 372 | 冷啟動時間 | <2s |
| 373 | 首頁載入 | <500ms |
| 374 | 統計頁載入 | <100ms（快取）|
| 375 | 列表滾動 FPS | >55 |
| 376 | 記憶體增長 | <50MB/hr |
| 377 | 圖片載入 | <1s |
| 378 | 網路請求 P95 | <200ms |
| 379 | 動畫流暢度 | 60 FPS |
| 380 | 大量 Marker 渲染 | <100ms |
| 381 | 離線啟動 | <3s |

---

## P12：無障礙與 UX（8 個）

| # | 測試案例 |
|---|----------|
| 382 | 螢幕閱讀器標籤 |
| 383 | 語義化標籤 |
| 384 | 對比度（WCAG AA）|
| 385 | 觸控目標大小（48dp）|
| 386 | 鍵盤導航 |
| 387 | 減少動態偏好 |
| 388 | 錯誤提醒音效 |
| 389 | Focus 狀態可見 |

---

## P16：深連結與導航（6 個）

| # | 測試案例 |
|---|----------|
| 420 | App Links 驗證（assetlinks.json）|
| 421 | 深連結開啟指定頁面 |
| 422 | 未登入時深連結 → 登入後跳轉 |
| 423 | 無效深連結 → 首頁 |
| 424 | 通知點擊跳轉正確頁面 |
| 425 | 返回鍵導航正確 |

---

## P17：資料備份與遷移（6 個）

| # | 測試案例 |
|---|----------|
| 426 | Android Auto Backup 設定正確 |
| 427 | 敏感資料排除備份 |
| 428 | 換機後資料還原 |
| 429 | 登出後本地快取清除 |
| 430 | 離線資料同步恢復 |
| 431 | 多設備登入資料一致性 |

---

## 驗收標準

### 覆蓋率目標

| 層級 | 最低 | 理想 |
|------|------|------|
| Utils | 95% | 100% |
| Models | 85% | 95% |
| Services | 75% | 85% |
| Controllers | 65% | 80% |
| Widgets | 50% | 70% |

### 上架前必測

| 優先級 | 測試數 | 時間 |
|--------|--------|------|
| P0 | 40 | 2.5 hr |
| P1 核心 | 50 | 3 hr |
| P2 核心 | 30 | 2 hr |
| P13 全部 | 10 | 1 hr |
| P14 核心 | 8 | 1 hr |
| P15 全部 | 8 | 1 hr |
| P18 核心 | 6 | 0.5 hr |
| P19 全部 | 8 | 1 hr |
| P20 全部 | 10 | 1 hr |
| P21 全部 | 12 | 1.5 hr |
| **小計** | **182** | **14.5 hr** |

---

## 相關文檔

- [PRODUCTION_LAUNCH_GUIDE.md](./PRODUCTION_LAUNCH_GUIDE.md) - 生產環境發布指南
- [800-testing-workflow.md](../../.cursor/rules/800-testing-workflow.mdc)
- [DEVELOPMENT_STATUS.md](../DEVELOPMENT_STATUS.md)
- [SESSION_MODE_SPEC.md](./SESSION_MODE_SPEC.md)
- [RESPONSIVE_ARCHITECTURE_DESIGN.md](./RESPONSIVE_ARCHITECTURE_DESIGN.md)
- [FCM_SETUP_GUIDE.md](../FCM_SETUP_GUIDE.md)
