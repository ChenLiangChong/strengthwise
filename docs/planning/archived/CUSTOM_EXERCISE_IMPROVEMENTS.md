# 自訂動作功能改進規劃

> 解決自訂動作在教練學員場景下的兩個核心問題

**版本**：v1.1 (2026-01-12)
**狀態**：方案 B 已完成 ✅ / 方案 A 延後

---

## 📋 問題總覽

### 問題 A：TrackingMode 編輯可能破壞歷史數據

**情境**：
1. 用戶創建自訂動作，選擇 `weight_reps` 模式
2. 使用該動作完成多次訓練，累積 PR 記錄
3. 用戶編輯動作，改成 `time_only` 模式
4. 歷史記錄與統計變得混亂

**現有機制**（好消息）：
- 每筆訓練記錄的 JSONB 已獨立保存 `trackingMode`
- 舊記錄不會被覆蓋，只影響未來訓練

**仍需處理**：
- 用戶可能不知道這個影響
- PR 表可能有舊的 weight 數據變得無意義
- 統計頁面可能顯示不連續的數據

### 問題 B：學員找不到教練的自訂動作

**情境**：
1. 教練創建自訂動作（`user_id = 教練ID`）
2. 教練用此動作為學員安排訓練計畫
3. 學員執行訓練 ✅（從 JSONB 讀取，正常運作）
4. 學員想自己創建新訓練 ❌（在動作選擇中找不到）

**根本原因**：
- `custom_exercises` RLS：`user_id = auth.uid()`
- 學員只能看到自己的自訂動作

---

## 🛠️ 解決方案

### 方案 A：TrackingMode 編輯警告

#### 需求描述
- 編輯自訂動作時，如果修改 `tracking_mode`
- 檢查是否有使用此動作的歷史訓練記錄
- 如果有，彈出確認對話框，說明影響

#### 實作位置
- `lib/views/pages/exercises/widgets/custom_exercise_dialog.dart`
- `lib/services/supabase/custom_exercise_service_supabase.dart`

#### UI 流程
```
用戶點擊「更新」
      ↓
檢查 tracking_mode 是否改變
      ↓ 是
檢查是否有訓練記錄（查詢 workout_plans）
      ↓ 有
顯示警告對話框：
┌────────────────────────────────────┐
│ ⚠️ 確定要修改追蹤模式？              │
│                                    │
│ 此動作已有 12 筆歷史訓練記錄。       │
│                                    │
│ • 舊記錄將保留原本的追蹤模式         │
│ • 新記錄將使用新的追蹤模式           │
│ • 統計數據可能會分成兩部分           │
│                                    │
│        [取消]    [確定修改]         │
└────────────────────────────────────┘
      ↓ 確定
執行更新
```

#### 查詢邏輯
```sql
-- 檢查是否有使用此動作的訓練記錄
SELECT COUNT(*) 
FROM workout_plans 
WHERE exercises @> '[{"exerciseId": "xxx"}]'::jsonb
  AND completed = true
  AND (trainee_id = $userId OR creator_id = $userId);
```

#### 預估工時
- Service 層查詢方法：0.5h
- Dialog 警告邏輯：1h
- 測試：0.5h
- **總計：2h**

---

### 方案 B：加入我的動作庫

#### 需求描述
- 學員在訓練計畫詳情頁，對於教練的自訂動作
- 可以點擊「加入我的動作庫」
- 複製一份到學員的 `custom_exercises`

#### 實作位置
- `lib/views/pages/workout/execution/plan_editor_page.dart`
- `lib/views/pages/workout/execution/template_editor_page.dart`
- `lib/services/interfaces/i_custom_exercise_service.dart`

#### 資料模型
```sql
-- 現有 custom_exercises 表，新增欄位（可選）
ALTER TABLE custom_exercises 
ADD COLUMN source_exercise_id TEXT;  -- 來源動作 ID（追蹤用）
```

> 🤔 **討論**：是否需要 `source_exercise_id`？
> - 優點：可追蹤來源、未來可能同步更新
> - 缺點：增加複雜度，可能不需要

#### UI 流程
```
學員檢視訓練計畫中的動作
      ↓
識別到教練的自訂動作（exerciseId 以 custom_ 開頭且不在學員的 custom_exercises 中）
      ↓
顯示「加入我的動作庫」按鈕
      ↓ 點擊
顯示確認/編輯對話框：
┌────────────────────────────────────┐
│ 📥 加入我的動作庫                   │
│                                    │
│ 動作名稱：單腳羅馬尼亞硬舉           │
│ 身體部位：腿部                      │
│ 追蹤模式：重量 & 次數               │
│ 器材：啞鈴                          │
│                                    │
│ （可編輯以上欄位）                  │
│                                    │
│        [取消]    [加入]            │
└────────────────────────────────────┘
      ↓ 確定
在 custom_exercises 中創建新記錄
顯示成功提示
```

#### 判斷邏輯：如何識別教練的自訂動作？

```dart
/// 檢查動作是否為「不屬於當前用戶的自訂動作」
Future<bool> isCoachCustomExercise(String exerciseId) async {
  // 1. 檢查是否在系統動作庫中
  final systemExercise = await _exerciseService.getExerciseById(exerciseId);
  if (systemExercise != null) return false;  // 是系統動作
  
  // 2. 檢查是否在當前用戶的自訂動作中
  final myCustomExercises = await _customExerciseService.getAll();
  final isMyCustom = myCustomExercises.any((e) => e.id == exerciseId);
  
  return !isMyCustom;  // 不是我的自訂動作 = 是教練的
}
```

#### 複製邏輯

```dart
/// 複製動作到我的動作庫
Future<CustomExercise> copyToMyExercises({
  required WorkoutExercise sourceExercise,
  String? customName,
  String? customBodyPart,
  TrackingMode? customTrackingMode,
}) async {
  final currentUser = _authController.user;
  if (currentUser == null) throw Exception('未登入');
  
  final newExercise = CustomExercise(
    id: _generateFirestoreId(),
    userId: currentUser.uid,
    name: customName ?? sourceExercise.name,
    bodyPart: customBodyPart ?? sourceExercise.bodyParts.firstOrNull ?? '其他',
    equipment: sourceExercise.equipment,
    trackingMode: customTrackingMode ?? sourceExercise.trackingMode,
    createdAt: DateTime.now(),
    // source_exercise_id: sourceExercise.exerciseId,  // 可選
  );
  
  return await _customExerciseService.create(newExercise);
}
```

#### 預估工時
- Service 層：判斷邏輯 + 複製方法：1h
- UI：「加入動作庫」按鈕 + 對話框：1.5h
- 測試：0.5h
- **總計：3h**

---

## 📊 優先順序

| 功能 | 優先級 | 原因 |
|------|--------|------|
| 方案 B：加入我的動作庫 | **P1** | 直接影響教練學員使用體驗 |
| 方案 A：TrackingMode 警告 | P2 | 預防性功能，影響較小 |

---

## 🔗 相關檔案

### 方案 A
- `lib/views/pages/exercises/widgets/custom_exercise_dialog.dart`
- `lib/services/supabase/custom_exercise_service_supabase.dart`
- `lib/models/custom_exercise/custom_exercise.dart`

### 方案 B
- `lib/views/pages/workout/execution/plan_editor_page.dart`
- `lib/views/pages/workout/execution/template_editor_page.dart`
- `lib/services/interfaces/i_custom_exercise_service.dart`
- `lib/models/workout_template/workout_exercise.dart`

---

## ✅ 驗收標準

### 方案 A（延後）
- [ ] 編輯自訂動作時，修改 tracking_mode 會觸發檢查
- [ ] 有歷史記錄時顯示警告對話框
- [ ] 對話框顯示受影響的記錄數量
- [ ] 用戶可選擇取消或繼續

### 方案 B ✅ 已完成
- [x] 學員可在訓練計畫中識別教練的自訂動作
- [x] 顯示「加入我的動作庫」按鈕（⊕ 圖示）
- [x] 點擊後顯示確認/編輯對話框
- [x] 成功複製到學員的 custom_exercises
- [x] 複製後可在學員的自訂動作頁面看到

---

## 📝 備註

### 關於 source_exercise_id 欄位

**決定**：暫不實作

**理由**：
1. 增加資料庫複雜度
2. 需要處理同步邏輯（教練更新時是否通知學員？）
3. 當前需求是「複製」而非「引用」
4. 未來如有需要，可用 migration 補上

### 關於 RLS 策略

目前 `custom_exercises` 的 RLS：
```sql
-- 現有
SELECT: user_id = auth.uid()
SELECT: 動作存在於自己的訓練中（Trainees view in workouts）
```

不需要修改 RLS，因為：
1. 複製後的動作 `user_id = 學員ID`，學員可正常操作
2. 原動作仍屬於教練，不影響教練端
