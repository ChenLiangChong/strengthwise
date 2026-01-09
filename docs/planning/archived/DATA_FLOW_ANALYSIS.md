# 數據流分析與快取策略討論

> 建立時間：2026-01-09  
> 最後更新：2026-01-09  
> 狀態：✅ **實施完成**（Phase 3.1-E）  
> 目的：分析所有數據的儲存、查詢、更新策略，實現「離線優先」架構

---

## 📋 實施摘要

本文檔的建議已於 v3.1.1 實施完成：

| 建議項目 | 實施狀態 | 說明 |
|---------|---------|------|
| Phase 2：關鍵持久化 | ✅ 完成 | `UserLocalCacheService`、`RelationshipLocalCacheService` |
| Phase 3：主線程優化 | ✅ 完成 | `IsolateUtils`、統計/訓練批量解析移至 Isolate |
| 啟動優化 | ✅ 完成 | Hive 並行初始化、事件驅動 SplashScreen |
| Stale-While-Revalidate | ✅ 完成 | 移除強制 clearCache |
| 骨架屏整合 | ✅ 完成 | 6 個頁面整合 shimmer 骨架屏 |

**相關代碼**：
- `lib/services/cache/user_local_cache_service.dart`
- `lib/services/cache/relationship_local_cache_service.dart`
- `lib/utils/isolate_utils.dart`
- `lib/common_widgets/loading/skeleton_loader.dart`

---

## 🎯 設計原則（基於深度研究報告）

### 核心理念：離線優先（Offline-First）

```
傳統模式（問題）：
  UI 請求 → await 網路 → 等待... → 顯示
  
離線優先模式（目標）：
  UI 請求 → 立即顯示本地快取 → 背景更新 → 自動刷新 UI
```

### 資料分類學（Data Taxonomy）

| 類別 | 特徵 | 儲存策略 | 讀取策略 |
|------|------|---------|---------|
| **A：關鍵持久化** | App 啟動必須、存取頻率極高 | 本地資料庫（Hive/Isar） | 同步/極速非同步 |
| **B：暫態會話** | 情境依賴、生命週期短 | 記憶體（Provider） | 直接網路請求 |
| **C：靜態資源** | 圖片、檔案 | 檔案系統快取 | LRU 快取 |
| **D：即時數據** | 秒級時效性 | 記憶體串流 | Realtime 訂閱 |

### 效能瓶頸識別

| 瓶頸類型 | 症狀 | 解決方案 |
|---------|------|---------|
| 冷啟動阻塞 | 啟動時長時間空白/轉圈 | 移除 `main()` 中的 `await`，使用本地快取 |
| JSON 解析阻塞 | 列表滑動卡頓、動畫掉幀 | 使用 `Isolate.run()` 背景解析 |
| 記憶體過載 | App 被系統殺掉 | 區分持久化 vs 記憶體，設定 TTL |
| N+1 查詢 | 網路請求爆炸 | 使用 DB 彙總表、RPC、批次查詢 |

---

## 📊 資料分類與儲存策略（24 個表格）

### 類別 A：關鍵持久化資料（必須本地儲存）

> 這些資料構成 App 的「骨架」，啟動時必須立即可用

| 表格 | 說明 | 目前狀態 | 建議策略 | 優先級 |
|------|------|---------|---------|--------|
| `users` | 用戶資料（每頁都用） | 記憶體 5 分 | ⚠️ 應加 Hive 持久化 | 🔥 高 |
| `exercises` | 系統動作庫（794 個） | ✅ Hive | ✅ 已優化 | - |
| `workout_plans` | 今日訓練計劃 | ✅ 記憶體 + Hive | ✅ 已優化 | - |
| `coaching_relationships` | 教練/學員列表 | 記憶體 | ⚠️ 應加 Hive 持久化 | 🔥 高 |
| `daily_workout_summary` | 統計彙總 | ✅ 記憶體 + Hive | ✅ 已優化 | - |
| `personal_records` | 個人記錄 | ✅ 記憶體 + Hive | ✅ 已優化 | - |

**讀取策略**：`優先讀取 Hive → 顯示 → 背景更新 Supabase → 自動刷新 UI`

---

### 類別 B：暫態會話資料（記憶體即可）

> 情境依賴、生命週期短，持久化反而有害

| 表格 | 說明 | 目前狀態 | 建議策略 | 理由 |
|------|------|---------|---------|------|
| `custom_exercises` | 自訂動作 | 記憶體 | ✅ 記憶體即可 | 數量少、變動時需即時同步 |
| `workout_templates` | 訓練模板 | 無 | 記憶體快取 | 低頻使用 |
| `body_data` | 身體數據 | 無 | 記憶體快取 | 統計頁才用到 |
| `notes` | 個人筆記 | 無 | 記憶體快取 | 低頻使用 |
| `session_notes` | SOAP 課程筆記 | 無 | 記憶體快取 | 僅特定頁面使用 |
| `health_assessments` | PAR-Q+ 問卷 | 無 | 記憶體快取 | 極低頻 |
| `coach_assessment_notes` | 教練備註 | 無 | 記憶體快取 | 極低頻 |
| `coach_display_preferences` | 顯示偏好 | 無 | 記憶體快取 | 極低頻 |
| `coaches` | 教練公開檔案 | 無 | 記憶體快取 | 僅查看時使用 |
| `coach_booking_settings` | 教練預約設定 | 無 | 記憶體快取 | 極低頻 |
| `client_availability` | 學員時間偏好 | 無 | 記憶體快取 | 極低頻 |
| `invite_codes` | 一次性邀請碼 | 無 | 不快取 | 每次需即時驗證 |
| `user_devices` | FCM Token | 無 | 不快取 | 僅背景使用 |

**讀取策略**：`檢查記憶體 → 有則返回 → 無則網路請求 → 快取 5 分鐘`

---

### 類別 C：即時數據（Realtime 訂閱）

> 秒級時效性，持久化歷史狀態毫無意義

| 表格 | 說明 | 目前狀態 | 建議策略 | 理由 |
|------|------|---------|---------|------|
| `availability_slots` | 教練可用時段 | 無 | ❌ 不快取 | 需即時查詢避免衝突 |
| `appointments` | 預約記錄 | 無 | ⚠️ Realtime 訂閱 | 狀態變更需即時通知 |
| `daily_readiness` | 課前問卷 | 無 | ❌ 不快取 | 僅上課時使用 |

**讀取策略**：`Realtime 訂閱 + 進入頁面時 Fetch`

---

### 類別 D：靜態資源（檔案快取）

| 資源 | 說明 | 目前狀態 | 建議策略 |
|------|------|---------|---------|
| 用戶頭像 | 圖片 | ✅ CachedNetworkImage | ✅ 已優化 |
| 動作示範圖 | 圖片 | ✅ CachedNetworkImage | ✅ 已優化 |
| SOAP 照片 | 圖片 | ✅ CachedNetworkImage | ✅ 已優化 |

---

### 類別 E：元數據（硬編碼）

| 表格 | 說明 | 目前狀態 | 理由 |
|------|------|---------|------|
| `body_parts` | 身體部位（8 個） | ✅ 硬編碼 | 永不變動 |
| `exercise_types` | 訓練類型（3 個） | ✅ 硬編碼 | 永不變動 |

---

## 📱 App 端計算的數據（非 DB 表格）

| 數據 | 說明 | 來源 | 目前快取 | 狀態 |
|------|------|------|---------|-----------|
| `StatisticsData` | 統計頁面數據 | 混合（彙總表 + workout_plans） | 記憶體 + Hive | ✅ 部分優化 |
| `ExerciseWithRecord` | 力量進步數據 | 從 workout_plans 計算 | 記憶體 5 分 | ⚠️ 可加 Hive |
| `TrainingFrequency` | 訓練頻率 | ✅ 從 daily_workout_summary | 同上 | ✅ 已優化 |
| `TrainingVolume` | 訓練量歷史 | ✅ 從 daily_workout_summary | 同上 | ✅ 已優化 |
| `TrainingTypeStats` | 訓練類型分佈 | ✅ 從 daily_workout_summary | 同上 | ✅ 已優化 |
| `PersonalRecords` | 個人記錄 | ✅ 從 personal_records View | 同上 | ✅ 已優化 |
| `BodyPartStats` | 身體部位分佈 | 從 workout_plans 計算 | 同上 | ⚠️ 彙總表無此數據 |
| `EquipmentStats` | 器材統計 | 從 workout_plans 計算 | 同上 | ⚠️ 彙總表無此數據 |

---

## 🔬 專案現況診斷

### ✅ 已正確實現的部分

| 項目 | 實現方式 | 符合報告建議 |
|------|---------|-------------|
| 動作庫持久化 | Hive | ✅ 類別 A 資料正確持久化 |
| 統計數據持久化 | Hive + 記憶體 | ✅ 離線優先架構 |
| 訓練計劃持久化 | Hive + 記憶體 | ✅ 離線優先架構 |
| 彙總表使用 | daily_workout_summary, personal_records | ✅ 避免 N+1 查詢 |
| 首頁預熱 | warmupFromLocalCache() | ✅ Stale-While-Revalidate |
| 圖片快取 | CachedNetworkImage | ✅ 類別 C 靜態資源 |
| Session Realtime | SessionRealtimeService | ✅ 類別 D 即時數據 |

### ⚠️ 需要改進的部分

| 問題 | 現況 | 報告建議 | 優先級 |
|------|------|---------|--------|
| **users 未持久化** | 僅記憶體 5 分鐘 | 應加 Hive，App 啟動第一幀需顯示 | 🔥 高 |
| **coaching_relationships 未持久化** | 僅記憶體 | 應加 Hive，首頁需顯示學員列表 | 🔥 高 |
| **JSON 解析未用 Isolate** | 主執行緒解析 | 大型列表應用 Isolate.run() | 🔥 高 |
| **ExerciseWithRecord 未持久化** | 僅記憶體 5 分 | 可加 Hive 減少冷啟動延遲 | 中 |
| **快取清除粒度太粗** | 清除整個用戶快取 | 應只清除當天/本週 | 中 |

### ❌ 潛在風險

| 風險 | 說明 | 影響 |
|------|------|------|
| Hive vs Isar | 目前使用 Hive | 報告建議 Isar 效能更好，但遷移成本高 |
| 無衝突解決機制 | 離線編輯後同步 | 目前假設總是有網路，未來需考慮 |
| 無增量同步 | 每次全量拉取 | 隨數據增長會變慢 |

---

## 🛠️ 優化執行計劃

### 第一階段：止血（Quick Wins）⏱️ 1-2 天

| 任務 | 預期效果 | 實現方式 |
|------|---------|---------|
| 1. users 加入 Hive 持久化 | App 啟動立即顯示用戶名/頭像 | 新增 UserLocalCacheService |
| 2. coaching_relationships 加入 Hive | 首頁立即顯示學員列表 | 新增 RelationshipLocalCacheService |
| 3. 大型列表加入 Isolate 解析 | 消除列表滑動卡頓 | 封裝 `Isolate.run()` 工具函數 |

### 第二階段：架構強化 ⏱️ 3-5 天

| 任務 | 預期效果 | 實現方式 |
|------|---------|---------|
| 4. ExerciseWithRecord 加入 Hive | 力量進步頁秒開 | 新增 StrengthProgressLocalCacheService |
| 5. 精確化快取清除 | 訓練完成後快取仍大部分有效 | 修改 clearUserCache → clearDateRangeCache |
| 6. 增量同步機制 | 減少網路傳輸量 | 使用 updated_at 做增量查詢 |

### 第三階段：進階優化（可選）⏱️ 視需求

| 任務 | 預期效果 | 實現方式 |
|------|---------|---------|
| 7. 新增 daily_body_part_summary | 身體部位統計秒開 | 新增 Migration + Trigger |
| 8. 預約 Realtime 訂閱 | 預約狀態即時更新 | 使用 Supabase Realtime Channel |
| 9. 考慮遷移至 Isar | 查詢效能提升 | 評估遷移成本 |

---

## 🔄 數據流向圖

### 離線優先架構（Stale-While-Revalidate）

```
┌─────────────────────────────────────────────────────────────┐
│                       UI 請求數據                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     Repository 層                            │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ 1. 同步讀取 Hive（毫秒級）→ 立即返回 UI 顯示             ││
│  │ 2. 背景啟動 Supabase 請求（不阻塞 UI）                   ││
│  │ 3. 網路返回後 → 更新 Hive → 觸發 UI 刷新                 ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                            │
            ┌───────────────┴───────────────┐
            ▼                               ▼
┌───────────────────────┐       ┌───────────────────────┐
│    Hive 本地資料庫      │       │    Supabase 雲端       │
│  （類別 A 關鍵資料）     │       │  （資料真實來源）       │
│  - users              │       │  - 所有 24 個表格       │
│  - exercises          │       │  - Realtime 訂閱       │
│  - workout_plans      │       │  - RPC/Views          │
│  - statistics         │       └───────────────────────┘
│  - relationships      │
└───────────────────────┘
```

### 訓練數據流（DB Trigger 自動彙總）

```
用戶訓練 → workout_plans (INSERT/UPDATE)
                ↓
         DB Trigger 自動執行 ✅
                ↓
    ┌──────────┴──────────┐
    ↓                     ↓
daily_workout_summary   personal_records
（每日統計彙總）        （PR 自動更新）
         ↓                     ↓
    App 直接查詢彙總表 ✅（已實現）
```

### 統計頁面數據流（目前已優化）

```
用戶進入統計頁面
        ↓
1. 讀取 Hive 快取（毫秒級）→ 立即顯示 ✅
        ↓
2. 背景查詢 Supabase：
   - daily_workout_summary（36KB）✅
   - personal_records（10KB）✅
   - workout_plans（僅用於 BodyPartStats）⚠️
        ↓
3. 更新 Hive + UI 刷新
```

### JSON 解析流程（待優化）

```
目前（主執行緒阻塞）：
  網路返回 JSON → jsonDecode() 在主執行緒 → UI 卡頓 ❌

優化後（背景 Isolate）：
  網路返回 JSON → Isolate.run() 背景解析 → UI 保持 60fps ✅
```

---

## 🔍 彙總表 vs 統計需求分析

### StatisticsData 需要的數據

| 數據項 | 說明 | 彙總表能提供？ | 需要的來源 |
|--------|------|---------------|-----------|
| **TrainingFrequency** | | | |
| ├─ totalWorkouts | 總訓練計劃數 | ✅ daily_workout_summary.workout_count | SUM |
| ├─ completedWorkouts | 完整完成數 | ✅ daily_workout_summary.completed_workout_count | SUM |
| ├─ partialWorkouts | 部分完成數 | ✅ daily_workout_summary.partial_workout_count | SUM |
| ├─ trainingDays | 訓練天數 | ✅ daily_workout_summary | COUNT(*) |
| ├─ totalHours | 總訓練時長 | ✅ daily_workout_summary.total_training_time | SUM |
| ├─ averageHours | 平均訓練時長 | ✅ 可計算 | AVG |
| ├─ consecutiveDays | 連續訓練天數 | ⚠️ 需額外計算 | 需遍歷日期 |
| └─ comparisonValue | 與上期對比 | ⚠️ 需額外查詢 | 需兩個時間範圍 |
| **TrainingVolume** | | | |
| └─ volumeHistory | 訓練量歷史 | ✅ daily_workout_summary | GROUP BY date |
| **BodyPartStats** | 身體部位分佈 | ❌ 沒有 | 需查 workout_plans |
| **TrainingTypeStats** | 訓練類型分佈 | ✅ daily_workout_summary | 有 resistance/cardio/mobility |
| **EquipmentStats** | 器材統計 | ❌ 沒有 | 需查 workout_plans |
| **PersonalRecords** | 個人記錄 | ✅ personal_records | 直接查詢 |
| **StrengthProgress** | 力量進步 | ⚠️ 部分 | 需查 workout_plans 歷史 |
| **MuscleGroupBalance** | 肌群平衡 | ❌ 沒有 | 需查 workout_plans |
| **TrainingCalendar** | 訓練日曆 | ✅ daily_workout_summary | 按日期 |
| **CompletionRate** | 完成率 | ✅ daily_workout_summary | 計算 completed/total |

---

### 目前彙總表結構（實際）

#### daily_workout_summary

```sql
CREATE TABLE daily_workout_summary (
  user_id UUID,
  date DATE,
  
  -- ✅ 可直接用於 TrainingFrequency
  workout_count INT,              -- 當天訓練數
  completed_workout_count INT,    -- 完整完成數
  partial_workout_count INT,      -- 部分完成數
  total_exercises INT,            -- 總動作數
  total_sets INT,                 -- 總組數
  total_volume DECIMAL,           -- 總訓練量
  total_training_time INT,        -- 總訓練時間（分鐘）
  
  -- ✅ 可直接用於 TrainingTypeStats
  resistance_training_count INT,  -- 阻力訓練次數
  cardio_count INT,               -- 心肺訓練次數
  mobility_count INT,             -- 活動度訓練次數
  
  UNIQUE(user_id, date)
);
```

#### personal_records

```sql
CREATE TABLE personal_records (
  user_id UUID,
  exercise_id TEXT,
  exercise_name TEXT,
  body_part TEXT,          -- ✅ 有身體部位
  max_weight DECIMAL,      -- 最大重量
  max_reps INT,            -- 最大次數
  max_volume DECIMAL,      -- 最大訓練量
  achieved_date DATE,      -- 達成日期
  workout_plan_id TEXT,    -- 關聯訓練計劃
  UNIQUE(user_id, exercise_id)
);
```

---

### 🔴 彙總表缺失的數據

| 缺失數據 | 說明 | 解決方案 |
|---------|------|---------|
| **身體部位分佈** | 每個部位的訓練量、次數 | 需新增彙總表或繼續查 workout_plans |
| **器材統計** | 每種器材的使用次數 | 需新增彙總表或繼續查 workout_plans |
| **肌群平衡** | 推/拉/腿等比例 | 需新增彙總表或繼續查 workout_plans |
| **力量進步歷史** | 每個動作的重量變化 | 需查 workout_plans 歷史數據 |
| **連續訓練天數** | 需要遍歷日期序列 | 可用 SQL Window Function |

---

### ✅ 已優化的統計項目（Phase 1 完成）

| 統計項目 | 實現方式 | 數據來源 | 狀態 |
|---------|---------|---------|------|
| 訓練頻率（總次數） | `getTrainingFrequency()` | ✅ daily_workout_summary | 已優化 |
| 訓練量歷史 | `getVolumeHistory()` | ✅ daily_workout_summary | 已優化 |
| 訓練類型分佈 | `getTrainingTypeStats()` | ✅ daily_workout_summary | 已優化 |
| 個人記錄 | `getPersonalRecords()` | ✅ personal_records View | 已優化 |
| 連續訓練天數 | `calculateTrainingFrequency()` | ✅ daily_workout_summary | 已優化 |

### ⚠️ 仍需查詢 workout_plans 的項目

| 統計項目 | 原因 |
|---------|------|
| 身體部位分佈 | 彙總表沒有按部位分組 |
| 器材統計 | 彙總表沒有器材資訊 |
| 肌群平衡 | 彙總表沒有肌群資訊 |
| 力量進步詳情 | 需要每次訓練的具體重量 |
| 特定肌群細節 | 彙總表沒有細分肌群 |

---

### 💡 可選優化：新增彙總表

如果未來需要優化身體部位分佈等統計，可考慮新增：

```sql
-- 每日身體部位彙總
CREATE TABLE daily_body_part_summary (
  user_id UUID,
  date DATE,
  body_part TEXT,          -- 身體部位
  total_volume DECIMAL,    -- 該部位總訓練量
  exercise_count INT,      -- 動作數
  set_count INT,           -- 組數
  UNIQUE(user_id, date, body_part)
);
```

**但目前不急**，因為這需要修改 Trigger，且身體部位分佈不是高頻查詢

---

## ⚠️ 目前的問題

### 問題 1：統計數據全量重新計算

```
目前流程：
1. 用戶完成訓練
2. 清除「整個」統計快取
3. 下次進入統計頁面
4. 查詢一年的 workout_plans（可能 365 筆）
5. 重新計算所有統計
6. 存入快取

問題：
- 隨著數據增長，計算越來越慢
- 沒有利用 DB 端的彙總表
- 每次都是全量計算，浪費資源
```

### 問題 2：沒有直接使用 DB 彙總表 ✅ 已解決

```
✅ 已實現：
- getTrainingFrequency() → 查詢 daily_workout_summary
- getVolumeHistory() → 查詢 daily_workout_summary
- getTrainingTypeStats() → 查詢 daily_workout_summary
- getPersonalRecords() → 查詢 personal_records_top_by_body_part View

⚠️ 仍需查詢 workout_plans 的項目（彙總表不支援）：
- 身體部位分佈（BodyPartStats）
- 器材統計（EquipmentStats）
- 肌群平衡（MuscleGroupBalance）
- 力量進步詳情（StrengthProgress）
```

### 問題 3：力量進步頁面沒有本地快取

```
目前：
- ExerciseWithRecord 只有 5 分鐘記憶體快取
- App 重開後需要重新查詢

影響：
- 關閉 App 重開後，力量進步頁面載入慢
```

### 問題 4：快取更新粒度太粗

```
目前：
- 訓練完成 → 清除「整個用戶」的統計快取
- 實際上只有當天的統計變了

應該：
- 只清除影響的日期範圍
- 或使用增量更新
```

---

## 💡 優化方案討論

### 方案 A：直接使用 DB 彙總表（推薦）

```
優點：
- DB 端 Trigger 已經維護好彙總數據
- 查詢彙總表比查詢 workout_plans 快很多
- 不需要 App 端計算

改動：
1. 修改 getTrainingFrequency() → 直接查 daily_workout_summary
2. 修改 getPersonalRecords() → 直接查 personal_records
3. 其他統計（如身體部位分佈）→ 可選擇性優化

查詢範例：
SELECT 
  COUNT(*) as workout_count,
  SUM(total_volume) as total_volume,
  SUM(total_sets) as total_sets
FROM daily_workout_summary
WHERE user_id = $1 
  AND date BETWEEN $2 AND $3;
```

### 方案 B：增量更新快取

```
優點：
- 不需要每次全量重新計算
- 快取更新更精確

改動：
1. 訓練完成時，只更新當天的統計
2. 本地快取按日期分片儲存
3. 查詢時合併各日期的快取

複雜度：高
```

### 方案 C：混合方案

```
1. 高頻數據（訓練次數、PR）→ 直接查 DB 彙總表
2. 低頻數據（身體部位分佈）→ 保持現有快取策略
3. 力量進步 → 增加本地 Hive 快取
```

---

## 📋 待討論的問題

### 1. 統計計算策略

- [ ] 是否改用 DB 彙總表？
- [ ] 哪些統計需要即時計算，哪些可以用彙總？
- [ ] 彙總表是否足夠覆蓋所有統計需求？

### 2. 快取更新粒度

- [ ] 訓練完成時，是否只清除當天的快取？
- [ ] 是否需要增量更新機制？
- [ ] 快取過期時間是否需要調整？

### 3. 力量進步頁面

- [ ] 是否需要增加本地 Hive 快取？
- [ ] ExerciseWithRecord 序列化是否複雜？

### 4. 離線支持

- [ ] 離線時是否需要顯示統計？
- [ ] 離線訓練後如何同步統計？

---

## 📊 數據量估算

### 假設：用戶每天訓練 1 次，使用 1 年

| 數據 | 數量 | 單筆大小 | 總大小 |
|------|------|---------|--------|
| `workout_plans` | 365 筆 | ~5KB | ~1.8MB |
| `daily_workout_summary` | 365 筆 | ~100B | ~36KB |
| `personal_records` | ~50 筆 | ~200B | ~10KB |

**結論**：
- 查詢 `daily_workout_summary`（36KB）比查詢 `workout_plans`（1.8MB）快 50 倍
- DB 彙總表設計正確，但目前沒有被充分利用

---

## 🎯 優化優先級（基於報告建議重新設計）

### Phase 1：DB 彙總表 ✅ 已完成

| 任務 | 實現檔案 | 方法 | 狀態 |
|------|---------|------|------|
| 訓練頻率 | `statistics_data_loader.dart` | `getDailySummary()` | ✅ 已完成 |
| 訓練量歷史 | `statistics_data_loader.dart` | `getVolumeSummary()` | ✅ 已完成 |
| 訓練類型分佈 | `statistics_data_loader.dart` | `getTrainingTypeSummary()` | ✅ 已完成 |
| 個人記錄 | `statistics_data_loader.dart` | `getPersonalRecordsFromAggregation()` | ✅ 已完成 |

---

### Phase 2：關鍵持久化（Quick Wins）🔥 建議立即實施

**目標**：解決冷啟動延遲，App 啟動第一幀即顯示完整 UI

| 任務 | 影響頁面 | 實現方式 | 預期效果 |
|------|---------|---------|---------|
| **users 持久化** | 全部頁面（用戶名、頭像） | 新增 `UserLocalCacheService` | 啟動時無需等待網路 |
| **coaching_relationships 持久化** | 首頁（學員列表） | 新增 `RelationshipLocalCacheService` | 首頁立即顯示學員 |

**技術細節**：

```dart
// UserLocalCacheService 設計
class UserLocalCacheService {
  static const String _boxName = 'user_cache';
  
  // 寫入（登入/更新後）
  Future<void> cacheUser(UserModel user);
  
  // 讀取（同步，啟動時使用）
  UserModel? getCachedUser();
  
  // 清除（登出時）
  Future<void> clearCache();
}
```

---

### Phase 3：主執行緒優化（消除卡頓）🔥 建議實施

**目標**：大型 JSON 解析移至背景 Isolate，保持 UI 60fps

| 任務 | 影響場景 | 實現方式 | 預期效果 |
|------|---------|---------|---------|
| **統計數據解析** | 統計頁面載入 | `Isolate.run()` 封裝 | 列表滑動不卡頓 |
| **訓練計劃解析** | 訓練列表載入 | `Isolate.run()` 封裝 | 動畫不掉幀 |

**技術細節**：

```dart
// 封裝 Isolate 解析工具
Future<List<T>> parseInBackground<T>(
  List<dynamic> rawData,
  T Function(Map<String, dynamic>) fromJson,
) async {
  return Isolate.run(() {
    return rawData.map((json) => fromJson(json as Map<String, dynamic>)).toList();
  });
}
```

---

### Phase 4：精確化快取更新 📋 可選

| 任務 | 目前實現 | 優化方案 | 效果 |
|------|---------|---------|------|
| 快取清除粒度 | 清除整個用戶快取 | 只清除當天/本週 | 🔥🔥 |
| ExerciseWithRecord | 僅記憶體 5 分 | 加 Hive 持久化 | 🔥🔥 |

---

### Phase 5：進階優化（未來）📋 視需求

| 任務 | 說明 | 複雜度 |
|------|------|--------|
| 新增 daily_body_part_summary | 身體部位統計彙總表 | 高 |
| 預約 Realtime 訂閱 | 即時更新預約狀態 | 中 |
| 增量同步機制 | 使用 updated_at 做增量查詢 | 高 |
| Hive → Isar 遷移 | 提升查詢效能 | 極高 |

---

## 📋 詳細任務清單

### ✅ 已完成

- [x] exercises 本地快取（Hive）
- [x] 統計數據本地快取（Hive）→ StatisticsLocalCacheService
- [x] 訓練計劃本地快取（Hive）→ WorkoutPlanLocalCacheService
- [x] 記憶體快取（5 分鐘）→ StatisticsCacheManager
- [x] 首頁預熱（warmupFromLocalCache）
- [x] **使用 daily_workout_summary 查詢訓練頻率** ⭐ Phase 1
- [x] **使用 daily_workout_summary 查詢訓練量歷史** ⭐ Phase 1
- [x] **使用 daily_workout_summary 查詢訓練類型分佈** ⭐ Phase 1
- [x] **使用 personal_records View 查詢 PR** ⭐ Phase 1

### 🔥 Phase 2：關鍵持久化（建議立即實施）

- [ ] **users 加入 Hive 持久化** → 新增 UserLocalCacheService
- [ ] **coaching_relationships 加入 Hive 持久化** → 新增 RelationshipLocalCacheService

### 🔥 Phase 3：主執行緒優化（建議實施）

- [ ] **封裝 Isolate 解析工具** → 新增 `lib/utils/isolate_utils.dart`
- [ ] **統計數據解析移至 Isolate** → 修改 StatisticsServiceSupabase
- [ ] **訓練計劃解析移至 Isolate** → 修改 WorkoutServiceSupabase

### 📋 Phase 4：精確化快取（可選）

- [ ] 精確化快取清除（只清當天/本週）
- [ ] ExerciseWithRecord 加入 Hive 持久化

### 📋 Phase 5：進階優化（未來）

- [ ] 新增 daily_body_part_summary 彙總表
- [ ] 預約 Realtime 訂閱
- [ ] 增量同步機制（updated_at）
- [ ] 評估 Hive → Isar 遷移

---

## 📊 效能監控指標

| 指標 | 目標 | 如何測量 |
|------|------|---------|
| 冷啟動時間 | < 2 秒 | 從 App 啟動到首頁完整顯示 |
| 統計頁載入 | < 100ms（有快取）| 從進入頁面到內容顯示 |
| 列表滑動 FPS | ≥ 60fps | Flutter DevTools |
| 記憶體佔用 | < 200MB | Flutter DevTools |

---

## 📚 相關文檔

- `docs/DATABASE_SUPABASE.md` - 資料庫結構
- `docs/planning/LOCAL_CACHE_STRATEGY.md` - 本地快取策略
- `migrations/022_fix_pr_trigger_body_part.sql` - PR 觸發器
- `migrations/036_fix_missing_rls.sql` - 彙總表 RLS

---

## 📖 參考資料

- Flutter 與 Supabase 高效能資料持久化研究報告（2026-01-09）
- Isar Database 官方文檔
- Dart Isolates 最佳實踐
