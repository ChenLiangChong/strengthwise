# TrackingMode 擴充規格書

> 支援 HIIT、有氧、功能性訓練的多元記錄模式

**狀態**：已完成 ✅  
**優先級**：高  
**預估工時**：1-2 天  
**建立日期**：2026-01-12  
**完成日期**：2026-01-12（v3.2-v3.3）  
**方案**：簡化版（只記錄，不統計）

---

## 背景

目前的資料結構以「重訓（重量 x 次數）」為核心設計，對於 HIIT、有氧或功能性訓練的輸入欄位不夠精確。

### 設計哲學

| 訓練類型 | 統計需求 | 說明 |
|----------|----------|------|
| 重訓 (Strength) | 高 | 需要數據趨勢（1RM、Volume、漸進式負荷）|
| 功能性/有氧 (Conditioning) | 低 | 重點是「完成度」或「當下紀錄」|

**結論**：功能性訓練不需要複雜的統計圖表，只需要記錄和完成標記。

---

## 解決方案（簡化版）

### 1. 單位標準化

| 欄位 | 儲存單位 | 資料型別 | UI 顯示 | 範例 |
|------|----------|----------|---------|------|
| `weight` | 公斤 (kg) | `double` | kg | 40.0 kg |
| `reps` | 次 | `int` | 次 | 10 次 |
| `time` | 秒 (seconds) | `int` | 分:秒 | 90 秒 → 1:30 |
| `distance` | 公尺 (meters) | `double` | m 或 km | 5000.0 m → 5.0 km |
| `calories` | 大卡 (kcal) | `double` | kcal | 200.0 kcal |
| `restTime` | 秒 (seconds) | `int` | 秒 | 90 秒 |

**轉換規則**：
- `time` UI 顯示：≥60 秒顯示為 `分:秒` 格式（如 1:30），<60 秒顯示為 `秒`
- `distance` UI 顯示：≥1000 m 顯示為 km（如 5.0 km），<1000 m 顯示為 m

### 2. 擴充 SetRecord 欄位

```dart
class SetRecord {
  final int setNumber;
  final int reps;              // 重複次數
  final double weight;         // 重量 (kg)
  final int restTime;          // 休息時間 (秒)
  final bool completed;
  final String note;
  
  // 新增欄位（選填）
  final int? time;             // 時間 (秒) - UI 顯示分:秒
  final double? distance;      // 距離 (公尺) - UI 顯示 m 或 km
  final double? calories;      // 熱量 (大卡 kcal)
}
```

### 2. 定義 TrackingMode（追蹤模式）

在每個動作上定義記錄模式，UI 會根據此模式顯示不同輸入框。

| 模式 | 代碼 | 輸入欄位 | 歷史記錄顯示範例 | 適用動作 |
|------|------|----------|------------------|----------|
| 重量 & 次數 | `weight_reps` | weight, reps | 40kg × 10次 | 深蹲、臥推（預設）|
| 重量 & 時間 | `weight_time` | weight, time | 40kg × 30秒 | 農夫走路 |
| 僅次數 | `reps_only` | reps | 15次 | 波比跳、跳箱 |
| 僅時間 | `time_only` | time | 60秒 | 棒式、靜態支撐 |
| 次數 & 時間 | `reps_time` | reps, time | 10次 × 5秒 | 動態伸展 |
| 距離 & 時間 | `distance_time` | distance, time | 5000m / 25:00 | 跑步機、划船機 |
| 僅距離 | `distance_only` | distance | 2.5m | 立定跳遠、投擲 |
| 卡路里 | `calories` | calories | 200卡 | 風扇車 |

### 3. 統計策略

| 頁面 | 重訓 (`weight_reps`) | 其他模式 |
|------|---------------------|----------|
| 總覽（Volume、訓練天數）| ✅ 納入計算 | ❌ 不納入 |
| PR 追蹤 | ✅ 更新 max_weight, max_reps | ❌ 不追蹤 |
| 力量進步（選動作）| ✅ 顯示趨勢圖表 | 📋 只顯示歷史記錄列表 |

---

## 影響範圍（簡化後）

### 低影響（向後相容）

| 檔案 | 修改 |
|------|------|
| `lib/models/workout_record/set_record.dart` | 新增 `time`, `distance`, `calories` 選填欄位 |
| `lib/models/workout_record/exercise_record.dart` | 新增 `trackingMode` 欄位 |

### 中影響（需要 Migration）

| 項目 | 說明 |
|------|------|
| `exercises` 表 | 新增 `tracking_mode` 欄位 |
| `custom_exercises` 表 | 新增 `tracking_mode` 欄位 |

### 不需要修改

| 項目 | 原因 |
|------|------|
| `update_daily_workout_summary()` 觸發器 | 只統計 weight_reps |
| `update_personal_records()` 觸發器 | 只追蹤 max_weight, max_reps |
| `StatisticsCalculator` | 不需要支援其他統計類型 |
| `personal_records` 表 | 不需要新增 max_time 等欄位 |
| `daily_workout_summary` 表 | 不需要新增 total_time 等欄位 |

---

## 資料庫變更

### Migration: 044_tracking_mode.sql

```sql
-- 1. exercises 表新增 tracking_mode
ALTER TABLE exercises 
ADD COLUMN IF NOT EXISTS tracking_mode TEXT DEFAULT 'weight_reps';

-- 2. custom_exercises 表新增 tracking_mode
ALTER TABLE custom_exercises 
ADD COLUMN IF NOT EXISTS tracking_mode TEXT DEFAULT 'weight_reps';

-- 3. 更新現有動作的 tracking_mode（根據 training_type）
UPDATE exercises 
SET tracking_mode = CASE
  WHEN training_type = '心肺適能訓練' THEN 'distance_time'
  WHEN training_type = '活動度與伸展' THEN 'time_only'
  ELSE 'weight_reps'
END
WHERE tracking_mode IS NULL;

-- 4. 為 custom_exercises 設定預設值
UPDATE custom_exercises 
SET tracking_mode = 'weight_reps'
WHERE tracking_mode IS NULL;
```

---

## 實施階段

### Phase 1: Model + Migration（0.5 天）✅
- [x] 擴充 `SetRecord` 模型（新增 time, distance, calories）
- [x] 擴充 `ExerciseRecord` 模型（新增 trackingMode）
- [x] 建立 Migration 044、044b（手動設定）、045（搜尋函數）
- [x] 本地快取版本升級（v3 自動重下載）
- [x] 修復 setTargets 保存問題

### Phase 2: UI 修改（1 天）✅
- [x] 訓練執行頁面：根據 tracking_mode 顯示不同輸入框（時間/距離/卡路里）
- [x] ExerciseSettingsDialog：根據 tracking_mode 顯示對應欄位
- [x] SetEditDialog / BatchSetEditDialog：支援多元追蹤模式
- [x] ExerciseCard / PlanExerciseCard：顯示邏輯適配
- [x] 力量進步頁面：非重訓動作只顯示歷史記錄列表 ✅ v3.3 完成

---

## 相容性考量

1. **向後相容**：現有訓練記錄不受影響，預設使用 `weight_reps`
2. **統計邏輯不變**：只有 `weight_reps` 會納入 Volume 統計和 PR 追蹤
3. **漸進式部署**：可先部署 Migration，再更新 UI

---

## 與原方案比較

| 項目 | 原方案（完整版）| 新方案（簡化版）|
|------|----------------|----------------|
| 工時 | 4-5 天 | 1-2 天 |
| 觸發器修改 | 需要重寫 | 不需要 |
| 統計服務修改 | 需要 | 不需要 |
| 統計頁面 UI | 需要 | 不需要 |
| 風險 | 高（可能影響現有統計）| 低（向後相容）|

---

## 相關文件

- [DATABASE_SUPABASE.md](../DATABASE_SUPABASE.md) - 資料庫設計
- [lib/models/workout_record/set_record.dart](../../lib/models/workout_record/set_record.dart) - 現有模型
