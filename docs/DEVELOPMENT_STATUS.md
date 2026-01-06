# StrengthWise - 開發狀態

> 下一步計劃、當前版本、未來規劃

**當前版本**：v3.1（2026-01-07 開發中）  
**上一版本**：v3.0（2026-01-06 已完成）  
**維護者**：StrengthWise 開發團隊

---

## 📋 目錄

- [下一步計劃（v3.1）](#下一步計劃v31)
- [v3.0 已完成](#v30-已完成)
- [未來計劃](#未來計劃)
- [已完成功能](#已完成功能)

---

## 下一步計劃（v3.1）

### 🎯 v3.1 總覽：Session Mode 完善 + 功能測試 + Widget

| Phase | 說明 | 任務數 | 狀態 |
|-------|------|--------|------|
| **3.1-SM** | Session Mode 完善 | 16 | ✅ |
| **3.1-A** | v3.0 功能測試 | 33 | ⏳ |
| **3.1-B** | Widget（可選） | 3 | ⏳ |
| **3.1-C** | 打磨與優化 | 16 | ⏳ |

---

## ✅ v3.1-SM：Session Mode 完善（2026-01-07）

### 訓練執行內嵌（4/4 ✅）

| # | 任務 | 狀態 | 說明 |
|---|------|------|------|
| SM-E1 | 提取 `WorkoutExecutionContent` Widget | ✅ | 可復用訓練執行 UI |
| SM-E2 | Session Mode 權限覆寫 | ✅ | `overrideCanEdit/CanMarkSet/ShowTimerUI` |
| SM-E3 | FAB 整合（SpeedDial） | ✅ | 照片、繪圖、新增動作 |
| SM-E4 | 全頁滾動整合 | ✅ | ReadinessCard + 訓練 + Notes |

### 即時保存機制（3/3 ✅）

| # | 任務 | 狀態 | 說明 |
|---|------|------|------|
| SM-S1 | 訓練修改即時保存 | ✅ | 新增/刪除動作組數、打勾 |
| SM-S2 | SOAP 自動保存（Debounced） | ✅ | 1 秒防抖 |
| SM-S3 | Lifecycle 保存 | ✅ | App 背景/頁面離開時保存 |

### Supabase Realtime 同步（4/4 ✅）

| # | 任務 | 狀態 | 說明 |
|---|------|------|------|
| SM-R1 | `SessionRealtimeService` | ✅ | 新 Service |
| SM-R2 | `workout_plans` Realtime | ✅ | 教練學員同步訓練狀態 |
| SM-R3 | `session_notes` Realtime | ✅ | SOAP/照片/手繪同步 |
| SM-R4 | 防抖機制 | ✅ | 避免自己觸發的更新閃爍 |

### 學員模式（3/3 ✅）

| # | 任務 | 狀態 | 說明 |
|---|------|------|------|
| SM-ST1 | 訓練唯讀（含運動時長顯示） | ✅ | 可看不可改 |
| SM-ST2 | SOAP 唯讀 + Realtime 更新 | ✅ | 即時看到教練筆記 |
| SM-ST3 | 隱藏 FAB | ✅ | 學員無操作按鈕 |

### Bug 修復（4/4 ✅）

| # | 任務 | 狀態 | 說明 |
|---|------|------|------|
| SM-F1 | 繪圖保存修復 | ✅ | SOAP 覆蓋問題 |
| SM-F2 | Session Note 可見性 | ✅ | Migration 035 |
| SM-F3 | RLS 修復（教練操作學員資料） | ✅ | Migration 036, 037 |
| SM-F4 | TrainingHubPage 教練模式即時更新 | ✅ | 改用 Consumer 監聯 |

### 新增檔案清單

```
lib/
├── services/realtime/
│   └── session_realtime_service.dart    ⭐ 新增
├── views/pages/session/widgets/
│   └── session_speed_dial.dart          ⭐ 新增
├── views/pages/notes/widgets/
│   ├── uploaded_photo_grid.dart         ⭐ 新增
│   └── quick_tags_section.dart          ⭐ 新增
└── views/pages/workout/execution/
    └── workout_execution_content.dart   ⭐ 新增

migrations/
├── 035_fix_session_note_visibility.sql  ⭐ 新增
├── 036_fix_missing_rls.sql              ⭐ 新增（RLS 啟用）
└── 037_fix_daily_summary_rls.sql        ⭐ 新增（教練操作學員 RLS）
```

### 主要修改檔案

| 檔案 | 變更說明 |
|------|----------|
| `workout_execution_controller.dart` | 權限覆寫、Realtime reload、防抖 |
| `workout_execution_data_manager.dart` | `_isInitialized` 標記、`updateTimeInfo` |
| `session_mode_controller.dart` | SOAP 自動保存、照片上傳、Realtime 訂閱 |
| `session_mode_page.dart` | SpeedDial FAB、GlobalKey |
| `session_execution_tab.dart` | 學員模式、權限覆寫 |
| `session_notes_section.dart` | 照片/快速標籤顯示、Realtime 更新 |
| `health_assessment_tab.dart` | 學員/教練模式區分 |
| `session_note_model.dart` | 預設 visibility = 'shared' |
| `readiness_form_page.dart` | 痠痛滑桿順序修正 |
| `service_registry.dart` | 註冊 SessionRealtimeService |
| `i_workout_execution_controller.dart` | 新增介面方法 |
| `training_hub_page.dart` | 改用 Consumer 監聯教練模式即時更新 |

---

## 🧪 待測試清單（按流程順序）

> ⭐ 按實際使用流程排列，需要兩個帳號（教練 + 學員）

---

### 階段 1️⃣：預約流程（教練設定 → 學員預約 → 教練確認）

| # | 測試項目 | 狀態 | 操作 | 驗收標準 |
|---|----------|------|------|----------|
| T-01 | 教練設定預約時間 | ⏳ | 教練：設定可預約時段 | `coach_booking_settings` 有資料 |
| T-02 | 水平日期選擇器 | ⏳ | 學員：左右滑動選日期 | UI 正常 |
| T-03 | 時間網格視圖 | ⏳ | 學員：查看可預約時段 | 顯示教練開放時段 |
| T-04 | 學員發起預約 | ⏳ | 學員：選時段 → 確認 | `appointments` 狀態=`requested` |
| T-05 | 🔔 新預約通知教練 | ⏳ | 自動觸發 | 教練手機收到推播 |
| T-06 | 教練確認預約 | ⏳ | 教練：點確認 | 狀態=`confirmed` |
| T-07 | 🔔 確認通知學員 | ⏳ | 自動觸發 | 學員手機收到推播 |
| T-08 | 預約自動創建資料 | ⏳ | 自動觸發 | `workout_plans` + `daily_readiness` 自動建立 |

---

### 階段 2️⃣：課前準備（學員填問卷 → 教練查看）

| # | 測試項目 | 狀態 | 操作 | 驗收標準 |
|---|----------|------|------|----------|
| T-09 | 🔔 課前 1hr 提醒 | ⏳ | pg_cron 觸發 | 雙方收到提醒 |
| T-10 | 學員填問卷入口 | ⏳ | 學員：點通知/課程卡片 | 進入問卷頁面 |
| T-11 | 表情滑桿操作 | ⏳ | 學員：拖拉 5 維度 | UI 正常 |
| T-12 | 問卷送出成功 | ⏳ | 學員：點送出 | `daily_readiness` 有資料 |
| T-13 | 紅綠燈計算正確 | ⏳ | 系統計算 | 🟢🟡🔴 狀態正確 |
| T-14 | 🔔 問卷通知教練 | ⏳ | 自動觸發 | 教練收到通知+紅綠燈 |

---

### 階段 3️⃣：上課模式（Session Mode）

| # | 測試項目 | 狀態 | 操作 | 驗收標準 |
|---|----------|------|------|----------|
| T-15 | Session Mode 入口 | ⏳ | 教練：點「開始課程」 | 進入 Session Mode |
| T-16 | 學員狀態卡 | ⏳ | 教練：查看 | 顯示問卷結果+紅綠燈 |
| T-17 | 訓練動作卡 PREV | ⏳ | 教練：查看 | 顯示歷史重量/次數 |
| T-18 | 動作歷史彈窗 | ⏳ | 教練：點「歷史」 | 顯示完整歷史記錄 |
| T-19 | 教練編輯訓練 | ⏳ | 教練：打勾/調整 | 可正常編輯 |
| T-20 | 學員唯讀模式 | ⏳ | 學員：同時查看 | 無法編輯 |
| T-21 | 休息計時器 | ⏳ | 教練：開始計時 | 計時+震動 |
| T-22 | 手繪 FAB | ⏳ | 教練：點手繪按鈕 | 手繪板開啟+保存 |
| T-23 | 近期統計 Tab | ⏳ | 教練：切到統計 | 顯示學員統計 |
| T-24 | 健康評估 Tab | ⏳ | 教練：切到評估 | 顯示歷史評估 |

---

### 階段 4️⃣：課後收尾

| # | 測試項目 | 狀態 | 操作 | 驗收標準 |
|---|----------|------|------|----------|
| T-25 | 課程結束 SOAP 提醒 | ⏳ | 系統觸發 | 對話框提醒填寫 |
| T-26 | 課程筆記 SOAP | ⏳ | 教練：填寫筆記 | 正常儲存 |
| T-27 | 學員課後查看紀錄 | ⏳ | 學員：查看課程 | SessionRecordPage 正常 |

---

### 階段 5️⃣：其他流程

| # | 測試項目 | 狀態 | 操作 | 驗收標準 |
|---|----------|------|------|----------|
| T-28 | 教練拒絕預約 | ⏳ | 教練：點拒絕 | 狀態=`rejected` |
| T-29 | 🔔 拒絕通知學員 | ⏳ | 自動觸發 | 學員收到推播 |
| T-30 | 取消預約 | ⏳ | 任一方取消 | 狀態=`cancelled` |
| T-31 | 🔔 取消通知對方 | ⏳ | 自動觸發 | 對方收到推播 |
| T-32 | 一鍵續約卡片 | ⏳ | 學員：點續約 | 跳轉預約頁 |
| T-33 | 教練臨時建立課程 | ⏳ | 教練：無預約直接上課 | AdHocSession 正常 |

---

### 📊 測試進度：0/33

---

## Phase 詳細（開發已完成）

### Phase 3.0-A：基礎設施 ✅

| # | 任務 | 狀態 |
|---|------|------|
| DB-1 | `coach_booking_settings` 表 | ✅ `028` |
| DB-2 | 新增 `rejected` 預約狀態 | ✅ `029` |
| DB-3 | `daily_readiness` 表 | ✅ `030` |
| DB-4 | 預約確認自動創建資料 Function | ✅ `031` |

---

### Phase 3.0-B：Session Mode + 課前問卷 🔄

#### Session Mode 主體（9/9 ✅）

| # | 任務 | 狀態 | 備註 |
|---|------|------|------|
| SM-1 | `session_mode_page.dart` 主框架 | ✅ | 3 Tab 結構 |
| SM-2 | 訓練動作卡（含 PREV） | ✅ | 擴展 `PlanExerciseCard` |
| SM-3 | 動作歷史查詢 Service | ✅ | 擴展 `IWorkoutService` |
| SM-4 | 動作歷史彈窗 | ✅ | `ExerciseHistoryDialog` |
| SM-5 | 學員狀態卡（問卷結果） | ✅ | `ReadinessCard` |
| SM-6 | 課程筆記區塊 | ✅ | 複用 `SoapFieldCard` |
| SM-7 | 近期統計 Tab | ✅ | 複用統計組件 |
| SM-8 | 手繪 FAB | ✅ | 複用 `DrawingCanvasPage` |
| SM-9 | 健康評估 Tab | ✅ | 複用 `HealthAssessmentSummaryCard` |

#### 課前問卷系統（8/8 ✅）

| # | 任務 | 狀態 | 備註 |
|---|------|------|------|
| RQ-1 | Model `daily_readiness_model.dart` | ✅ | 含 `ReadinessMetrics` |
| RQ-2 | Service `readiness_service.dart` | ✅ | 含紅綠燈計算 |
| RQ-3 | 表情滑桿組件 | ✅ | `EmojiSlider` |
| RQ-4 | 學員問卷頁面 | ✅ | `ReadinessFormPage` |
| RQ-5 | 紅綠燈計算邏輯 | ✅ | Hooper Index 變體 |
| RQ-6 | 課前提醒推播 | ✅ | `session-reminder` Edge Function |
| RQ-7 | 學員填完通知教練 | ✅ | `readiness-notify` Edge Function |
| RQ-8 | Session Mode 顯示結果 | ✅ | 整合到 `ReadinessCard` |

#### 權限與自動創建（9/9 ✅）

| # | 任務 | 狀態 | 備註 |
|---|------|------|------|
| AC-1 | 預約確認自動創建資料 | ✅ | DB-4 Trigger |
| AC-2 | 教練手動建立臨時課程 | ✅ | `AdHocSessionDialog` |
| AC-3 | 教練編輯/打勾時間控制 | ✅ | `canMarkSet` 參數 |
| AC-4 | 學員只能看不能改 | ✅ | `readOnly` 參數 |
| AC-5 | 課程結束 + SOAP 提醒 | ✅ | 對話框已實現 |
| AC-6 | 學員課後查看紀錄 | ✅ | `SessionRecordPage` |
| AC-7 | 無計畫時的建立流程 | ✅ | 跳轉現有頁面 |
| AC-8 | 休息計時器（複用） | ✅ | `RestTimerWidget` |
| AC-9 | Session Mode 入口 | ✅ | `AppointmentCard` 開始課程按鈕 |

#### 預約 UX 優化（5/5 ✅）

| # | 任務 | 狀態 | 備註 |
|---|------|------|------|
| UI-1 | 一鍵續約卡片 | ✅ | `QuickRebookCard` 整合到首頁 |
| UI-2 | 水平日期選擇器 | ✅ | `HorizontalDatePicker` |
| UI-3 | 時間網格視圖 | ✅ | `TimeGridView` |
| UI-4 | 預約確認底部彈窗 | ✅ | `BookingConfirmationSheet` |
| UI-5 | 骨架屏載入 | ✅ | `SkeletonLoader` |

---

### Phase 3.0-A.1：基礎設施測試 🧪

| # | 測試項目 | 狀態 | 說明 |
|---|----------|------|------|
| DB-T1 | `coach_booking_settings` 表 CRUD | ⏳ | 教練設定可正常讀寫 |
| DB-T2 | `rejected` 狀態流轉 | ⏳ | 確認 → 拒絕 → 取消 流程 |
| DB-T3 | `daily_readiness` 表寫入 | ⏳ | 學員填問卷資料正確 |
| DB-T4 | 預約確認自動創建 | ⏳ | Trigger 自動創建 workout_plan + daily_readiness |

---

### Phase 3.0-B.1：Session Mode 測試 🧪

#### Session Mode 主體測試
| # | 測試項目 | 狀態 | 說明 |
|---|----------|------|------|
| SM-T1 | Session Mode 頁面載入 | ⏳ | 3 Tab 結構正常渲染 |
| SM-T2 | 訓練動作卡 PREV 數據 | ⏳ | 歷史重量/次數正確顯示 |
| SM-T3 | 動作歷史彈窗 | ⏳ | 查詢 + 顯示歷史記錄 |
| SM-T4 | 學員狀態卡（紅綠燈） | ⏳ | 問卷結果正確顯示 |
| SM-T5 | 課程筆記 SOAP 保存 | ⏳ | 課後筆記正常儲存 |
| SM-T6 | 近期統計 Tab | ⏳ | 統計組件正常顯示 |
| SM-T7 | 手繪 FAB 功能 | ⏳ | 手繪板開啟 + 保存 |
| SM-T8 | 健康評估 Tab | ⏳ | 歷史評估正常顯示 |

#### 課前問卷測試
| # | 測試項目 | 狀態 | 說明 |
|---|----------|------|------|
| RQ-T1 | 表情滑桿操作 | ⏳ | 5 維度正常拖拉 |
| RQ-T2 | 問卷送出成功 | ⏳ | 資料寫入 `daily_readiness` |
| RQ-T3 | 紅綠燈計算正確 | ⏳ | 🟢🟡🔴 狀態正確 |
| RQ-T4 | 教練端收到通知 | ⏳ | 依賴 FCM 測試 |

#### 權限與自動創建測試
| # | 測試項目 | 狀態 | 說明 |
|---|----------|------|------|
| AC-T1 | 教練臨時建立課程 | ⏳ | AdHocSessionDialog 流程 |
| AC-T2 | 教練編輯時間控制 | ⏳ | 開始前15分~結束後4小時 |
| AC-T3 | 學員唯讀模式 | ⏳ | 無法編輯訓練內容 |
| AC-T4 | 課程結束 SOAP 提醒 | ⏳ | 對話框正確觸發 |
| AC-T5 | 學員課後查看紀錄 | ⏳ | SessionRecordPage 正常 |
| AC-T6 | 休息計時器 | ⏳ | 計時 + 震動 |
| AC-T7 | Session Mode 入口 | ⏳ | AppointmentCard 按鈕 |

#### 預約 UX 測試
| # | 測試項目 | 狀態 | 說明 |
|---|----------|------|------|
| UI-T1 | 一鍵續約卡片 | ⏳ | 點擊正確跳轉 |
| UI-T2 | 水平日期選擇器 | ⏳ | 左右滑動 + 選擇 |
| UI-T3 | 時間網格視圖 | ⏳ | 可用時段正確顯示 |
| UI-T4 | 預約確認彈窗 | ⏳ | 資訊正確 + 確認送出 |
| UI-T5 | 骨架屏載入 | ⏳ | 載入時顯示 |

---

### Phase 3.0-C：即時通訊 ✅

| # | 任務 | 狀態 | 備註 |
|---|------|------|------|
| NT-1 | FCM Android 整合 | ✅ | `NotificationService` + `firebase_messaging` |
| NT-2 | Edge Function `push-notify` | ✅ | HTTP v1 API（OAuth 2.0）|
| NT-3 | Database Webhook 配置 | ✅ | `push_notify_appointments` + `readiness_notify` |
| NT-4 | 課前 1hr 上課提醒（雙方） | ✅ | `session-reminder` + pg_cron |
| NT-5 | iOS APNs 預留接口 | 📅 | 延後至 v3.1 |
| NT-6 | 學員填問卷通知教練 | ✅ | `readiness-notify` Edge Function |
| NT-7 | `user_devices` 表 | ✅ | Migration 033（獨立設備表）|

**技術決策**：
- 使用 **HTTP v1 API**（非 Legacy API）- 更安全、長期支援
- 獨立 `user_devices` 表（非 `users.fcm_tokens` 欄位）- 支援多設備、平台追蹤
- 自動清理無效 Token 機制

---

### Phase 3.0-C.1：FCM 測試計畫 🧪

#### 前置條件
| # | 項目 | 狀態 |
|---|------|------|
| PRE-1 | Firebase 專案配置 | ✅ |
| PRE-2 | `google-services.json` | ✅ |
| PRE-3 | Supabase Secrets（FCM_*）| ✅ |
| PRE-4 | Edge Functions 部署 | ✅ |
| PRE-5 | Database Webhooks | ✅ |
| PRE-6 | pg_cron 定時任務 | ✅ |
| PRE-7 | Migration 033 執行 | ✅ |

#### App 端測試
| # | 測試項目 | 狀態 | 說明 |
|---|----------|------|------|
| APP-1 | 登入時保存 Token | ✅ | 確認 `user_devices` 有資料 |
| APP-2 | Token 刷新自動更新 | ✅ | `onTokenRefresh` 監聽 |
| APP-3 | 登出時移除 Token | ✅ | 確認 Token 被刪除 |

#### 推播測試
| # | 測試項目 | 狀態 | 說明 |
|---|----------|------|------|
| PUSH-1 | 新預約 → 通知教練 | ⏳ | `status: requested` |
| PUSH-2 | 確認預約 → 通知學員 | ⏳ | `status: confirmed` |
| PUSH-3 | 拒絕預約 → 通知學員 | ⏳ | `status: rejected` |
| PUSH-4 | 取消預約 → 通知對方 | ⏳ | `status: cancelled` |
| PUSH-5 | 課前 1hr 提醒（雙方）| ⏳ | pg_cron 觸發 |
| PUSH-6 | 學員填問卷 → 通知教練 | ⏳ | 紅綠燈狀態顯示 |

#### 驗收標準
- [x] `user_devices` 表有登入用戶的 Token ✅
- [ ] 預約狀態變更時收到推播
- [ ] 課前 1 小時收到提醒
- [ ] 點擊通知跳轉到對應頁面

---

### Phase 3.1-B：Widget（可選）

| # | 任務 | 狀態 |
|---|------|------|
| WG-1 | `home_widget` 套件整合 | ⏳ |
| WG-2 | Android AppWidget（下堂課倒數） | ⏳ |
| WG-3 | iOS WidgetKit 預留 | ⏳ |

---

### Phase 3.1-C：打磨與測試（最後）

#### 📊 性能監控

| # | 項目 | 目標 | 狀態 |
|---|------|------|------|
| perf-1 | 應用啟動時間 | 冷啟動 <200ms | ⏳ |
| perf-2 | 主線程 Frames Skip | <30，FPS >55 | ⏳ |
| perf-3 | 統計頁面載入 | 快取 <5ms | ⏳ |
| perf-4 | 記憶體使用 | 增長 <50MB | ⏳ |
| perf-5 | 網路查詢延遲 | 95% <50ms | ⏳ |
| perf-6 | Storage 上傳 | 5MB <3 秒 | ⏳ |

#### 🎨 UX 優化

| # | 項目 | 說明 | 狀態 |
|---|------|------|------|
| UX-1 | 照片上傳 Loading | 進度條 + 百分比 | ⏳ |
| UX-2 | 資料載入 Shimmer | 骨架屏佔位符 | ⏳ |
| UX-3 | 網路錯誤提示 | 友善提示 + 重試機制 | ⏳ |
| UX-4 | 離線模式提示 | 頂部 Banner | ⏳ |
| UX-5 | 無學員引導頁面 | 空狀態 + 邀請按鈕 | ⏳ |
| UX-6 | 無訓練引導頁面 | 空狀態 + 創建按鈕 | ⏳ |
| UX-7 | 無筆記引導頁面 | 空狀態 + 新增按鈕 | ⏳ |

#### 🐛 Bug 檢查

| # | 項目 | 檢查重點 | 狀態 |
|---|------|---------|------|
| Bug-1 | 不同屏幕尺寸 | UI 不溢出、文字自適應 | ⏳ |
| Bug-2 | 深色模式 | 對比度、陰影 | ⏳ |
| Bug-3 | 淺色模式 | 文字清晰、按鈕狀態 | ⏳ |

---

### ✅ v3.1 完成標準

- [ ] Phase 3.1-A 完成（v3.0 功能測試 33 項）
- [ ] Phase 3.1-B 完成（Widget，可選）
- [ ] Phase 3.1-C 完成（打磨與測試）

---

## v3.0 已完成

### 🎯 v3.0 總覽：預約系統優化 + Session Mode + 響應式 UI（2026-01-06）

| Phase | 說明 | 狀態 |
|-------|------|------|
| **3.0-A** | 基礎設施（DB 優化 4 項） | ✅ |
| **3.0-B** | Session Mode + 課前問卷（31 項） | ✅ |
| **3.0-C** | 即時通訊 FCM（6 項，NT-5 延後） | ✅ |
| **3.0-UI** | 響應式 UI 改造 | ✅ |

#### ✅ 響應式 UI 改造（Phase 0）

| 項目 | 內容 |
|------|------|
| 基礎架構 | 7 級斷點、Context Extensions、ResponsiveBuilder |
| P0 核心頁面 | 訓練、動作庫、歷史、個人檔案、統計（5 頁） |
| P1 教練端 | 行事曆、學員管理、預約、筆記、健康評估（5 頁） |
| P2 自適應導航 | BottomNav → NavigationRail（平板/桌面） |
| P3 平板分欄 | 預約列表/詳情、學員列表/詳情（Master-Detail）|
| 組件改造 | 38 個 widgets 使用 `context.cardPadding` |

**設計規格**：[RESPONSIVE_ARCHITECTURE_DESIGN.md](planning/RESPONSIVE_ARCHITECTURE_DESIGN.md)

#### 📝 v3.0 技術決策

| 決策 | 說明 |
|------|------|
| **組件複用** | 擴展 `PlanExerciseCard` 而非新建（DRY 原則）|
| **Service 擴展** | `IWorkoutService.getExerciseHistory()` 而非新建 Service |
| **PREV 數據** | 使用 JSONB `exercises` 欄位解析歷史記錄 |
| **紅綠燈算法** | 基於 Hooper Index，加權平均 + 閾值判定 |
| **時間控制** | 課程開始前 15 分鐘 ~ 結束後 4 小時可編輯 |
| **FCM HTTP v1 API** | 使用 OAuth 2.0 JWT 驗證（非 Legacy Server Key）|
| **user_devices 表** | 獨立設備表（1:N），支援多設備、平台追蹤 |
| **響應式間距** | `context.cardPadding`、`context.spacing.md` 統一間距 |

---

## 未來計劃

### Phase 5+: 進階功能

| 優先級 | 項目 | 說明 |
|--------|------|------|
| 高 | Onboarding 流程 | 首次使用引導頁面 |
| 高 | Beta 測試準備 | 招募測試用戶、生產環境配置 |
| 中 | 訓練計劃模板市場 | 教練分享、學員訂閱 |
| 低 | 社群功能 | 動態分享、排行榜 |
| 低 | 語音筆記 | 語音轉文字（Whisper API）|
| 低 | AI 功能 | 智能筆記建議（GPT-4）|

### 教練公開檔案未來擴展

| 項目 | 說明 |
|------|------|
| PostGIS 地理搜尋 | 搜尋附近教練 |
| 審核狀態機 | pending → verified |
| Edge Functions | 權限提升流程 |
| 公開搜尋 | RLS 政策開放 |
| 圖片上傳 | gallery_images |
| 評價系統 | 學員評價教練 |

---

## 已完成功能

| 版本 | 功能 |
|------|------|
| v1.0 | 單機版（訓練記錄、統計、794 動作）|
| v2.0 | 教練學員系統（Phase 1-4）|
| v2.1-v2.7 | 時區統一、登入驗證、UI 重構 |
| v2.8 | 健康評估系統 |
| v2.8.1 | 教練評估備註 |
| v2.8.2 | 文檔架構重構 |
| v2.8.3 | PR 觸發器修復 |
| v2.8.4 | 用戶角色修復 |
| v2.9 | 教練公開檔案 + 訓練權限系統 |
| v2.9.1 | 訓練 UX 優化（TRN-1~7）|
| v3.0 | 預約系統優化 + Session Mode + 響應式 UI |
| **v3.1-SM** | **Session Mode 完善（Realtime + 即時保存）** |

**詳細版本歷史**：[archived/VERSION_HISTORY.md](archived/VERSION_HISTORY.md)  
**技術架構**：[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)  
**規格書**：[planning/](planning/)

---

## 📊 專案狀態摘要

| 項目 | 狀態 |
|------|------|
| v1.0 單機版 | ✅ 100% |
| v2.0-v2.9.1 教練學員系統 | ✅ 100% |
| v3.0 預約系統 + Session Mode + 響應式 UI | ✅ 100% |
| **v3.1-SM Session Mode 完善** | ✅ 100% |
| v3.1-A 功能測試 | ⏳ 待測試 |
| 代碼品質 | ✅ 0 linter errors |

**下一步重點**：v3.1-A 功能測試（33 項）→ Widget（可選）→ 打磨與測試

> ✅ **v3.1-SM 開發完成**（2026-01-07）：
> - 訓練執行內嵌（WorkoutExecutionContent 可復用 Widget）
> - 即時保存機制（所有修改即時保存 + SOAP Debounced）
> - Supabase Realtime 同步（workout_plans + session_notes）
> - 學員模式（唯讀 + 運動時長顯示）
> - FAB 整合（SpeedDial：照片、繪圖、新增動作）
> - Bug 修復（繪圖保存、Session Note 可見性、RLS、教練模式即時更新）
>
> 📱 **Google Play 上架進度**（2026-01-07）：
> - ✅ Package Name 更新：`com.strengthwise.fitness`
> - ✅ Release Keystore 已配置
> - ✅ 內部測試版已發布（v1.0.0）
> - ✅ App Signing SHA-1 已配置到 Firebase
> - ✅ Supabase Redirect URL 已更新
> - ✅ 隱私政策 / 使用條款連結已加入 App
> - ⏳ 等待 Google 審核完成
>
> 🧪 **v3.1-A 待測試**：33 項功能測試（預約流程、Session Mode、FCM 推播）
