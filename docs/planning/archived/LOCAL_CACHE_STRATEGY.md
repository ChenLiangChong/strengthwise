# 本地持久化策略規劃

> 最後更新：2026-01-09  
> 狀態：✅ **實施完成**（Phase 3.1-E）

本文檔的策略已於 v3.1.1 實施，詳見 [DATA_FLOW_ANALYSIS.md](archived/DATA_FLOW_ANALYSIS.md)。

## 核心原則

| 原則 | 說明 |
|------|------|
| **頻繁訪問** | 用戶常常要看的數據 |
| **變化頻率低** | 不會每分鐘都變 |
| **查詢成本高** | 從 DB 拉取比較慢 |
| **離線價值** | 沒網路也能看 |

---

## 角色定義

```
所有用戶 = 學員（基礎身份）

學員（無教練）：純自主訓練
學員（有教練）：有教練指導的學員
教練：指導學員的教練（自己也可能在訓練）
教練（有自己的教練）：既是教練又有自己的教練
```

---

## 按角色分析

### 所有用戶共通（基礎層）

| 數據 | 持久化？ | 理由 |
|------|---------|------|
| 自己的統計數據 | ✅ 是 | 高頻訪問、每日最多變一次 |
| 自己的訓練計劃（進行中） | ✅ 是 | 離線訓練需要 |
| 動作資料庫 | ✅ 已做 | 794 個動作，啟動必需 |
| 收藏列表 | ✅ 是 | 變化極少、高頻訪問 |
| 個人資料 | ✅ 是 | 啟動必需 |

### 學員（有教練）額外數據

| 數據 | 持久化？ | 理由 |
|------|---------|------|
| 教練基本資料 | ✅ 是 | 姓名、頭像，變化極少 |
| 教練安排的計劃 | ✅ 是 | 離線訓練需要 |
| Session Mode 數據 | ❌ 否 | Realtime 同步，需要最新狀態 |
| 可預約時段 | ❌ 否 | 變化頻繁、需要即時 |

### 教練額外數據

| 數據 | 持久化？ | 理由 |
|------|---------|------|
| 學員列表 | ✅ 是 | 變化少、首頁顯示 |
| 學員基本資料 | ✅ 是 | 姓名、頭像、健康評估摘要 |
| 學員統計數據 | ⚠️ 僅記憶體快取 | 每個學員一份太大、變化較頻繁 |
| 學員訓練計劃 | ❌ 否 | 變化頻繁、按需查詢 |
| 今日課程 | ❌ 否 | 每天不同、需要即時 |
| 待確認預約 | ❌ 否 | 隨時可能變 |

---

## 持久化優先級

```
優先級 1（必做）⭐⭐⭐
├── 自己的統計數據（本週/本月/三個月/一年）
├── 收藏列表
└── 進行中的訓練計劃

優先級 2（建議做）⭐⭐
├── 學員列表 + 基本資料（教練視角）
├── 教練基本資料（學員視角）
└── 個人資料

優先級 3（可選）⭐
├── 歷史訓練計劃（最近 10 筆）
└── 學員健康評估摘要
```

---

## 不需要持久化的數據

| 數據 | 理由 |
|------|------|
| Session Mode | Realtime 必須即時同步 |
| 可預約/可上課時段 | 變化頻繁、需要最新 |
| 待確認預約 | 需要即時狀態 |
| 學員詳細統計 | 數據量大、按需查詢即可 |
| 訓練歷史詳情 | 低頻訪問、點進去才看 |

---

## 技術方案

### Hive Box 結構

```
┌─────────────────────────────────────────┐
│           Hive 本地儲存                  │
├─────────────────────────────────────────┤
│  exercises_cache    → 動作資料庫 (已做)   │
│  user_profile       → 個人資料            │
│  favorites          → 收藏列表            │
│  statistics_cache   → 統計數據 (多時間範圍) │
│  active_plans       → 進行中的訓練計劃     │
│  relationships      → 教練/學員列表        │
└─────────────────────────────────────────┘
```

### 快取更新策略

| 數據類型 | 更新時機 | 有效期 |
|---------|---------|--------|
| 統計數據 | 訓練完成時清除 / 24 小時後過期 | 24 小時 |
| 訓練計劃 | 每次修改後同步 | 永久（除非刪除）|
| 關係列表 | 每次登入時刷新 | 7 天 |
| 收藏列表 | 修改時同步 | 永久 |

### 統計快取失效觸發

```
用戶完成訓練 → WorkoutService.updateRecord(completed=true)
    ↓
WorkoutPlanLocalCacheService.removeCachedPlan()  ← 移除訓練計劃
    ↓
StatisticsLocalCacheService.clearUserCache()     ← 清除統計快取
    ↓
下次進入統計頁面 → 重新查詢 DB 並更新快取
```

---

## Realtime 同步策略

### workout_plan 的分類

```
workout_plan 類型：

1️⃣ 自己創建的計劃
   ├── created_by = trainee_id
   ├── appointment_id = NULL
   ├── 持久化：✅ 是
   └── Realtime：❌ 不需要（自己改自己的）

2️⃣ 教練安排的計劃（作業/課前準備）
   ├── created_by = coach_id
   ├── appointment_id = NULL
   ├── 持久化：✅ 是
   └── Realtime：⚠️ 可選（教練修改時通知學員）

3️⃣ 上課中的計劃（Session Mode）
   ├── appointment_id != NULL
   ├── 持久化：❌ 否
   └── Realtime：✅ 必須雙向同步
```

### 現有 Realtime 實現

```dart
// SessionRealtimeService.subscribeToWorkoutPlan()
// 訂閱特定的 workout_plan_id
// ✅ 適用於：Session Mode（進入上課頁面時訂閱）
// ❌ 不適用於：教練在後台修改計劃
```

### 問題分析：教練創建/修改計劃

```
場景 A：教練安排作業（appointment_id = NULL）
─────────────────────────────────────────────
1. 教練創建計劃 → 學員如何知道？
   - 目前：學員下次進入首頁/訓練列表時查詢
   - 優化：推送通知（FCM）

2. 教練修改計劃 → 學員如何知道？
   - 目前：學員重新載入時才會更新
   - 優化：Realtime 訂閱 + 本地快取失效

場景 B：上課計劃（appointment_id != NULL）
─────────────────────────────────────────────
1. 進入 Session Mode 前
   - 計劃可能由教練預先創建
   - 學員進入時需要查詢最新版本

2. 上課中
   - 雙方都在 Session Mode
   - ✅ 已實現：訂閱特定 workout_plan_id
   - 任何一方修改，另一方即時看到

3. 上課後
   - 訂閱自動取消
   - 計劃成為歷史記錄
```

### 建議方案

#### 方案 A：簡單方案（推薦）

```
持久化策略：
├── 自己的計劃：持久化，無需 Realtime
├── 教練安排的計劃：不持久化，每次查詢最新
└── 上課計劃：不持久化，進入時訂閱 Realtime

理由：
- 教練安排的計劃數量不多
- 查詢成本可接受
- 避免複雜的快取失效邏輯
```

#### 方案 B：完整方案

```
持久化策略：
├── 所有計劃都持久化

Realtime 訂閱：
├── 學員端：訂閱自己的所有 workout_plans
│   └── 收到變更 → 更新本地快取
│   └── 新增/刪除 → 刷新本地快取
│
└── 教練端：只訂閱正在上課的計劃

FCM 推送：
├── 教練創建新計劃 → 推送給學員
└── 教練修改計劃 → 推送給學員

缺點：
- 實現複雜
- 訂閱過多可能影響效能
```

#### 方案 C：混合方案

```
持久化策略：
├── 自己的計劃：持久化
├── 教練安排的計劃：持久化，但標記 "需要驗證"
└── 上課計劃：不持久化

啟動時驗證：
├── 檢查 "需要驗證" 的計劃
├── 比對 updated_at 時間戳
└── 如果有更新 → 拉取最新版本

優點：
- 離線可用
- 不需要複雜的 Realtime
- 啟動時自動同步
```

---

## 實作順序

### Phase 1：記憶體快取優化（已完成）✅
- [x] 統計數據多時間範圍快取
- [x] 動作訓練記錄快取
- [x] 快取有效期 5 分鐘
- [x] 一次查詢 + 客戶端過濾（避免 N+1）

### Phase 2：Hive 持久化（已完成）✅
- [x] 統計數據持久化 - `StatisticsLocalCacheService`
- [x] 統計數據序列化 - `statistics_serialization.dart`
- [x] 收藏列表持久化 - 已使用 SharedPreferences（`FavoritesService`）
- [x] 訓練計劃快取服務 - `WorkoutPlanLocalCacheService`
- [x] 訓練計劃整合到 `WorkoutServiceSupabase`

### Phase 3：Realtime 優化（設計完成）📋
- [x] 區分 workout_plan 類型（文檔已記錄）
- [x] Session Mode 專用 Realtime 通道（`SessionRealtimeService` 已實現）
- [ ] 教練安排計劃的推送通知（需要 FCM 整合）

---

## 新增的程式碼檔案

| 檔案 | 用途 |
|------|------|
| `lib/models/statistics/statistics_serialization.dart` | 統計數據 JSON 序列化擴展 |
| `lib/services/cache/statistics_local_cache_service.dart` | 統計數據 Hive 持久化 |
| `lib/services/cache/workout_plan_local_cache_service.dart` | 訓練計劃 Hive 持久化 |

---

## 已修改的程式碼檔案

| 檔案 | 修改內容 |
|------|---------|
| `lib/services/supabase/statistics_service_supabase.dart` | 整合本地快取，優先讀取持久化數據 |
| `lib/services/supabase/workout_service_supabase.dart` | 整合訓練計劃本地快取 |
| `lib/services/locator/service_registry.dart` | 註冊快取服務 |

---

## 相關文檔

- `docs/planning/SESSION_MODE_SPEC.md` - Session Mode 規格
- `docs/DATABASE_SUPABASE.md` - 資料庫結構
- `lib/services/cache/exercise_local_cache_service.dart` - 現有 Hive 實現
