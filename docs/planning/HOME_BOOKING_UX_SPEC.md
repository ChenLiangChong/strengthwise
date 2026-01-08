# 首頁 + 行事曆 UX 優化規格書

> 版本：v1.2  
> 建立日期：2026-01-07  
> 更新日期：2026-01-08  
> 狀態：🔄 開發中（Phase 1-4 完成，剩餘 Phase 5 課後流程）

---

## 📋 目錄

- [背景與痛點](#背景與痛點)
- [身份邏輯](#身份邏輯)
- [BookingPage 擴展](#bookingpage-擴展)
- [首頁改造](#首頁改造)
- [TrainingPlanCard 擴展](#trainingplancard-擴展)
- [開發任務清單](#開發任務清單)

---

## 背景與痛點

### 當前操作路徑

| 角色 | 操作 | 當前路徑 | 點擊次數 |
|------|------|----------|----------|
| 教練 | 設定可上課時間 | 教練中心 → 預約時段 → 設定 | 3 |
| 教練 | 查看學員可訓練時間 | 教練中心 → 學員詳情 → 訓練行事曆 | 3 |
| 教練 | 確認預約 | 教練中心 → 預約列表 | 2 |
| 教練 | 開始上課 | 教練中心 → 預約列表 → 開始課程 | 3 |
| 學員 | 跟教練預約 | 學員中心 → 教練詳情 → 預約上課 | 3 |
| 學員 | 開始上課 | 學員中心 → 預約列表 → 開始上課 | 3 |

### 目標

- 減少點擊次數
- 首頁直接顯示今日課程，一鍵進入
- 行事曆整合所有時段資訊

---

## 身份邏輯

### 身份組合

| 身份 | 說明 | hasCoach | isCoach |
|------|------|:--------:|:-------:|
| **一般用戶** | 沒綁定教練 | ❌ | ❌ |
| **學員** | 有綁定教練 | ✅ | ❌ |
| **學員 + 教練** | 有綁定教練 + 自己也是教練 | ✅ | ✅ |

> ⚠️ 不存在「純教練」，所有用戶都是學員起步

### 各身份功能權限

| 功能 | 一般用戶 | 學員 | 學員+教練 |
|------|:--------:|:----:|:---------:|
| 自主訓練 | ✅ | ✅ | ✅ |
| 我的課程（作為學員） | ❌ | ✅ | ✅ |
| 我的學員（作為教練） | ❌ | ❌ | ✅ |
| 設定可訓練時間 | ❌ | ✅ | ✅ |
| 設定可上課時間 | ❌ | ❌ | ✅ |
| 確認預約 | ❌ | ❌ | ✅ |

---

## BookingPage 擴展

### Tab 設計

| Tab | 顯示條件 | 內容 |
|-----|----------|------|
| **🎓 我的** | 所有人 | 我的訓練（🔵）+ 我要上的課（🟠） |
| **🏋️ 教練** | `isCoach` | 我要教的課（🟠）+ 學員可訓練時段（🟡） |

> **注意**：教練 Tab 不顯示學員的訓練計畫，那個去「學員詳情頁」看

### 行事曆顏色標記

| 類型 | 顏色 | Tab「我的」 | Tab「教練」 | 說明 |
|------|------|:-----------:|:-----------:|------|
| 📍 上課（統一） | 🟠 橘色 | ✅ | ✅ | 不分教練/學員視角 |
| 🏃 自主訓練 | 🔵 藍色 | ✅ | ❌ | 我的訓練 |
| 📋 教練安排 | 🔵 藍色 | ✅ | ❌ | 我的訓練 |
| ⏰ 教練可上課時段 | 🟢 綠色 | ✅ | ❌ | 學員可點擊預約 |
| ⏰ 學員可訓練時段 | 🟡 黃色 | ❌ | ✅ | 供教練參考 |

**顯示方式**：
- 行事曆日期格用點點標記
- 選中日期 → 下方顯示對應卡片（複用 `TrainingPlanCard`）

### FAB 設計（SpeedDial）

| 身份 | Tab | FAB 選項 |
|------|-----|----------|
| 學員（無教練） | 我的 | ➕ 新增訓練 |
| 學員（有教練） | 我的 | ➕ 新增訓練<br>⏰ 設定可訓練時間 |
| 教練 | 教練 | ➕ 幫學員新增訓練<br>⏰ 設定可上課時間 |

```dart
// FAB 邏輯示意
Widget buildFab() {
  if (currentTab == '教練') {
    return SpeedDial(
      children: [
        SpeedDialChild(label: '幫學員新增訓練', onTap: _onAddTrainingForStudent),
        SpeedDialChild(label: '設定可上課時間', onTap: _onSetAvailableTime),
      ],
    );
  } else {
    final items = [
      SpeedDialChild(label: '新增訓練', onTap: _onAddTraining),
    ];
    if (hasCoach) {
      items.add(SpeedDialChild(label: '設定可訓練時間', onTap: _onSetTrainableTime));
    }
    return SpeedDial(children: items);
  }
}
```

---

## 首頁改造

### 設計原則

| 原則 | 說明 |
|------|------|
| **聚焦今天** | 首頁只顯示「今天要做什麼」 |
| **歷史去行事曆** | 過去的訓練記錄移到行事曆查看 |
| **移除最近訓練** | ❌ 原有「最近訓練」區塊移除 |
| **快捷操作** | ⚡ 常用功能一鍵直達 |
| **可折疊區塊** | 📚 今日行程、🏋️ 我的學員可收起 |

### 快捷按鈕設計 ✅ 已實現

**檔案**：`lib/views/widgets/quick_action_bar.dart`

| 用戶類型 | 按鈕順序（從左到右） |
|----------|----------------------|
| **教練+學員+有教練** | 我的教練 → 我的學員 → 設可訓練 → 設可上課 → 新訓練 → 統計 |
| **教練+學員+無教練** | 我的學員 → 設可上課 → 新訓練 → 統計 |
| **學員+有教練** | 我的教練 → 設可訓練 → 新訓練 → 統計 |
| **學員** | 新訓練 → 統計 |

**按鈕跳轉目標**：

| 按鈕 | 跳轉頁面 |
|------|----------|
| 我的教練 | `ClientHubPage`（學員中心） |
| 我的學員 | `CoachHubPage`（教練中心） |
| 設可訓練 | `ClientAvailabilityPage` |
| 設可上課 | `CoachSlotsManagementPage` |
| 新訓練 | `PlanEditorPage`（今日日期） |
| 統計 | `StatisticsPageV2` |

### 可折疊區塊設計 ✅ 已實現

**檔案**：`lib/views/widgets/collapsible_section.dart`

- 動畫時長：250ms
- 曲線：ease-out
- 箭頭圖標指示展開/收起
- 標題右側顯示計數 Badge

### 結構設計

> 💡 歷史記錄直接點底部導航「行事曆」查看，不需要額外跳轉按鈕

```
┌─────────────────────────────────────────┐
│  👋 Hi, [用戶名]                [📊][🔔]│
├─────────────────────────────────────────┤
│  ⚡ 快捷操作                             │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐    │
│  │👨‍🏫│ │👥│ │⏰│ │➕│ │📊│           │
│  │教練│ │學員│ │時段│ │新增│ │統計│    │
│  └────┘ └────┘ └────┘ └────┘ └────┘    │
├─────────────────────────────────────────┤
│  📚 今日行程                    [2] [▼] │ ← 可折疊
│  ┌─────────────────────────────────────┐│
│  │ 🟠 14:00 · 李教練 · 重量訓練        ││  ← 上課（我是學員）
│  │ [填問卷] [進入課程]                 ││     → ReadinessFormPage / SessionModePage
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │ 🔵 全天 · 腿部訓練                  ││  ← 自主訓練
│  │ [開始訓練]                          ││     → WorkoutExecutionPage
│  └─────────────────────────────────────┘│
├─────────────────────────────────────────┤
│  🏋️ 我的學員                   [3] [▼] │ ← 只有 isCoach，可折疊
│  ┌─────────────────────────────────────┐│
│  │ 🟠 16:00 · 王小明 · 體態雕塑        ││  ← 上課（我是教練）
│  │ [開始課程]                          ││     → SessionModePage
│  └─────────────────────────────────────┘│
│  ⏳ 待確認 (1)                          │
│  張小強 明天10:00           [✓] [✗]    │
└─────────────────────────────────────────┘
```

### 卡片行為

| 卡片類型 | 點擊行為 | 目標頁面 |
|----------|----------|----------|
| 📍 上課（我是學員） | 進入課程 | `SessionModePage`（學員模式） |
| 📍 上課（我是教練） | 開始課程 | `SessionModePage`（教練模式） |
| 🏃 自主 / 📋 教練安排 | 開始訓練 | `WorkoutExecutionPage` |

### 顯示邏輯

```dart
Widget buildHomeSessions() {
  final hasCoach = user.coachId != null;
  final isCoach = user.isCoach;
  
  return Column(
    children: [
      // 1. 我的行程（作為學員）
      if (hasCoach || hasTodayTraining)
        _MySessionsSection(
          title: '📚 今日行程',
          sessions: getTodaySessionsAsStudent() + getTodayTrainings(),
        ),
      
      // 2. 我的學員（作為教練）
      if (isCoach) ...[
        _MyStudentsSection(
          title: '🏋️ 我的學員',
          sessions: getTodaySessionsAsCoach(),
        ),
        
        // 待確認預約
        _PendingBookingsSection(
          bookings: getPendingBookings(),
        ),
      ],
    ],
  );
}
```

---

## TrainingPlanCard 擴展

### 現有功能

檔案：`lib/views/pages/scheduling/booking/widgets/training_plan_card.dart`

已支援：
- 訓練類型標籤：🏃 自主、📋 教練安排、📍 上課
- 完成狀態、進度條
- 編輯/刪除權限控制
- 時間範圍顯示

### 需要擴展 ✅ 已完成

| # | 參數 | 類型 | 說明 |
|---|------|------|------|
| C-1 | `studentName` | `String?` | 教練視角顯示學員名稱 |
| C-2 | `onFillReadiness` | `Function(appointmentId)?` | 填問卷 → `ReadinessFormPage` |
| C-3 | `onEnterSession` | `Function(planId, appointmentId)?` | 進入課程 → `SessionModePage` |
| C-4 | `showReadinessButton` | `bool` | 是否顯示填問卷按鈕（課前限定） |

### 按鈕顯示邏輯

| 卡片類型 | 角色 | 按鈕 | 跳轉目標 |
|----------|------|------|----------|
| 📍 上課 | 學員（課前 1hr 內） | `[填問卷]` `[進入課程]` | ReadinessFormPage / SessionModePage |
| 📍 上課 | 學員（其他時間） | `[進入課程]` | SessionModePage |
| 📍 上課 | 教練 | `[開始課程]` | SessionModePage |
| 🏃 自主 | - | `[開始訓練]` | WorkoutExecutionPage |
| 📋 教練安排 | - | `[開始訓練]` | WorkoutExecutionPage |

> 💡 教練不需要「查看狀態」按鈕，SessionModePage 裡面都能看到學員狀態

---

## 開發任務清單

### Phase 1：首頁改造 ✅ 完成

| # | 任務 | 說明 | 狀態 |
|---|------|------|------|
| H-0 | 移除「最近訓練」區塊 | 歷史記錄改到行事曆查看 | ✅ |
| H-1 | 今日行程區塊 | 複用 `TrainingPlanCard` | ✅ |
| H-2 | 上課卡片 → SessionModePage | 區分教練/學員模式 | ✅ |
| H-3 | 訓練卡片 → WorkoutExecutionPage | 現有邏輯 | ✅ |
| H-4 | 待確認預約 inline | 教練首頁直接確認/拒絕 | ✅ |
| H-5 | 我的學員區塊 | 只有 `isCoach` 顯示 | ✅ |
| H-6 | 空狀態引導 | 無行程時顯示友善提示 | ✅ |
| H-7 | 快捷按鈕列 | `QuickActionBar` Widget | ✅ |
| H-8 | 可折疊區塊 | `CollapsibleSection` Widget | ✅ |

### Phase 2：TrainingPlanCard 擴展 ✅

| # | 任務 | 說明 | 狀態 |
|---|------|------|------|
| C-1 | 加 `studentName` 參數 | 教練視角顯示學員名稱 | ✅ |
| C-2 | 加 `onFillReadiness` 回調 | 填問卷 → ReadinessFormPage | ✅ |
| C-3 | 加 `onEnterSession` 回調 | 進入課程 → SessionModePage | ✅ |
| C-4 | 按鈕顯示邏輯 | 根據角色和時間控制 | ✅ |

### Phase 3：BookingPage Tab + 顏色 ✅

| # | 任務 | 說明 | 狀態 |
|---|------|------|------|
| B-1 | Tab「我的」/「教練」 | 教練才顯示第二個 Tab | ✅ |
| B-2 | 行事曆點點標記 | 🟠上課 🔵訓練 🟢教練可上課 🟡學員可訓練 | ✅ |
| B-3 | 選中日期顯示卡片 | 複用 `TrainingPlanCard` | ✅ |
| B-3.1 | 點點排序 | 同色放一起（藍→橙→綠→黃） | ✅ |

### Phase 4：時段設定功能 ✅

| # | 任務 | 說明 | 狀態 |
|---|------|------|------|
| B-4 | 教練可上課時段卡片 | 學員可看教練開放時段（支援多教練） | ✅ |
| B-5 | 學員可訓練時段卡片 | 教練可看學員偏好時段 | ✅ |
| B-6 | FAB SpeedDial | `BookingSpeedDial` 根據身份+Tab顯示 | ✅ |
| B-6.1 | `getCoachCreatedPlans` | 教練 Tab 顯示上課卡片 | ✅ |

### Phase 5：課後流程

| # | 任務 | 說明 | 預估 |
|---|------|------|------|
| P-1 | 課程回顧頁面 | 唯讀的 Session Mode Page | 2hr |
| P-2 | 問卷填寫提醒 | 首頁卡片顯示「填問卷」按鈕 | 1hr |
| P-5 | 通知跳轉 | 點擊推播直接進入對應頁面 | 3hr |

---

## 📊 總覽

| Phase | 任務數 | 狀態 |
|-------|--------|------|
| Phase 1：首頁改造 | 9 | ✅ 完成 |
| Phase 2：TrainingPlanCard | 4 | ✅ 完成 |
| Phase 3：BookingPage Tab | 4 | ✅ 完成 |
| Phase 4：時段設定 | 4 | ✅ 完成 |
| Phase 5：課後流程 | 3 | ⏳ 待開發 |
| **總計** | **24** | **21/24（88%）** |

---

## 相關文檔

### 新增/修改檔案

| 檔案 | 說明 |
|------|------|
| `lib/views/pages/home/home_page.dart` | 首頁（已改造） |
| `lib/views/widgets/quick_action_bar.dart` | 快捷按鈕列組件 ⭐新增 |
| `lib/views/widgets/collapsible_section.dart` | 可折疊區塊組件 ⭐新增 |
| `lib/views/pages/scheduling/booking/booking_page.dart` | 行事曆頁面（Tab + 數據載入）|
| `lib/views/pages/scheduling/booking/widgets/booking_calendar_view.dart` | 行事曆視圖（多色點點） |
| `lib/views/pages/scheduling/booking/widgets/booking_speed_dial.dart` | SpeedDial FAB ⭐新增 |
| `lib/views/pages/scheduling/booking/widgets/training_plan_card.dart` | 訓練卡片組件（擴展） |
| `lib/views/shared/calendar/unified_calendar.dart` | 統一行事曆（markerBuilder） |
| `lib/services/interfaces/i_workout_service.dart` | 新增 `getCoachCreatedPlans` |
| `lib/services/supabase/workout_service_supabase.dart` | 實現 `getCoachCreatedPlans` |
| `lib/services/supabase/workout/workout_record_operations.dart` | 實現查詢 |

### 參考文檔

- `lib/views/pages/session/session_mode_page.dart` - Session Mode 頁面
- `docs/planning/SESSION_MODE_SPEC.md` - Session Mode 規格書

