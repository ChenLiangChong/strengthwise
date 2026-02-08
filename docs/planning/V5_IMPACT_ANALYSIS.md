# v5.0 動作分類系統 — 全面影響分析

> v5.0 對應用各層的影響盤點 + DB 是否需要改動的結論

**建立日期**：2026-02-09
**目標版本**：v5.0
**狀態**：✅ 分析完成

---

## 已完成（Phase A-F）

| 項目 | 改動 |
|------|------|
| Exercise model | v5.0 欄位完整（primaryMuscle, pplTags, movementPatterns, etc.） |
| Exercise search | `searchAdvancedFromCache()` 支援全部 v5.0 篩選 |
| Exercise detail page | 顯示 v5.0 分類、別名、動作模式、肌肉 |
| Exercise list/browse | PPL chips、進階篩選、瀏覽卡片 |
| Exercise cache | v6 版本，含完整 v5.0 欄位 |
| bodyPartStats | `primaryMuscle → parentGroup` 取代 v4 bodyPart 字串 |
| muscleBalance | 使用 pplTags 判斷推/拉/腿/核心 |
| trainingTypeStats | 客戶端計算（pplTags），修復從 v1 起永遠為 0 的 bug |
| equipmentStats | v5.0 映射 |
| training suggestions | 字串比對修正 |

---

## 關鍵洞見：v4 和 v5 的天然對應

v4 `body_part` 實際值：`"胸部"`, `"背部"`, `"腿部"`, `"肩部"`, `"手臂"`, `"核心"`
v5 `muscleGroups` 顯示名：`"胸部"`, `"背部"`, `"腿部"`, `"肩部"`, `"手臂"`, `"核心"`

**完全一致。** v4 body_part 中文字串 = v5 parentGroup 的 resolve 結果。

```
v4 路徑：exercises.body_part → "胸部"（直接字串）
v5 路徑：exercises.primary_muscle → muscleToGroup → "chest" → resolve → "胸部"
```

差異：
- v4 = 扁平分類（6 個大分區）
- v5 = 多層分類（26 個肌肉 → 6 個分區 → PPL → 動作模式）

---

## DB 層（不需要改動）

| 元件 | 欄位 | 現況 | 風險 |
|------|------|------|------|
| `update_personal_records()` trigger | v4 `body_part` | 775/775 完整數據 | 無 |
| `update_daily_workout_summary()` trigger | 無 | hardcoded 0，已被客戶端計算取代 | 無 |
| `personal_records_top_by_body_part` View | v4 `body_part` | DISTINCT ON (body_part) | 無 |
| v4 搜尋 RPCs | v4 欄位 | fallback，v5 搜尋已是主力 | 無 |

---

## 仍用 v4 但功能正常（7 個區域）

由於 v4 body_part 顯示名 = v5 parentGroup 顯示名，**從用戶角度看不出差異**。

| # | 區域 | 檔案 | v4 欄位用途 | 改動成本 |
|---|------|------|-----------|---------|
| 1 | ExerciseWithRecord | `exercise_with_record.dart` | bodyPart/trainingType 做 3 層導航分類 | 低 |
| 2 | ExerciseStrengthProgress | `statistics_strength_progress.dart` | bodyPart 做力量進度分區標題 | 低 |
| 3 | TrainingCalendarDay | `statistics_calendar.dart` | bodyPart 做日曆 tooltip | 低 |
| 4 | PersonalRecord | `personal_record.dart` | bodyPart 做 PR 分組（來自 DB trigger） | 中 |
| 5 | FavoriteExercise | `favorite_exercise.dart` | bodyPart 做副標題顯示 | 低 |
| 6 | WorkoutExercise JSONB | `workout_exercise.dart` | bodyParts + equipment 存入 workout_plans | 高（歷史數據） |
| 7 | CustomExercise | `custom_exercise.dart` | 完全 v4 | 高（需改 DB） |

---

## DB 是否需要改？

### 結論：業務上不需要

| 維度 | 分析 |
|------|------|
| 分類精度 | v4 body_part（6 分區）對「顯示分組」已足夠。v5 的 26 肌肉精度已在客戶端統計使用 |
| 訓練類型 | v4 training_type = v5 pplTags 聚合結果。客戶端已用 pplTags 計算 |
| 自訂動作 | 用戶只選 6 個 bodyPart + 3 個 trainingType，與 v5 parentGroup 完全對應 |
| WorkoutExercise JSONB | 歷史數據，改動需遷移所有 JSONB，風險高且無收益 |

### 什麼時候可能需要改 DB？

- 個人紀錄按「具體肌肉」分組（而非按「腿部」）
- 自訂動作參與細粒度肌群平衡分析
- 移除 v4 欄位簡化 schema

---

## 向後兼容架構

```
┌─────────────────────────────────────────────┐
│                  exercises 表                │
│                                             │
│  v4 欄位（向後兼容層）    v5 欄位（精細分類）  │
│  ├── body_part "胸部"     ├── primary_muscle  │
│  ├── training_type        ├── ppl_tags []     │
│  ├── specific_muscle      ├── movement_patterns │
│  ├── equipment_category   ├── synergist_muscles │
│  └── equipment_subcategory├── difficulty_level  │
│                           └── mechanics_type   │
└──────────┬────────────────────────┬──────────┘
           │                        │
    DB triggers / Views       Flutter 統計計算
    (用 v4，安全運作)          (用 v5，精確分析)
```

v4 = 扁平化「摘要」，適合 DB 層簡單分組
v5 = 多維度「源資料」，適合客戶端靈活計算
兩者共存，各司其職
