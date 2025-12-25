# StrengthWise - 資料庫查詢完整列表

> 應用程式中所有 Supabase 資料庫查詢的完整列表

**匯出時間**: 2024-12-26  
**資料來源**: lib/services/**/*_supabase.dart  
**目的**: 效能優化 - 識別查詢瓶頸和優化機會

---

## 📊 查詢統計總覽

### 按表格分類
| 表格名稱 | 查詢數量 | 使用頻率 | 優化優先級 |
|---------|---------|---------|-----------|
| `workout_plans` | 45+ | 極高 | ⭐⭐⭐ |
| `exercises` | 25+ | 極高 | ⭐⭐⭐ |
| `users` | 15+ | 高 | ⭐⭐ |
| `body_data` | 10+ | 中 | ⭐⭐ |
| `workout_templates` | 8+ | 中 | ⭐ |
| `favorite_exercises` | 5+ | 中 | ⭐ |
| `notes` | 5+ | 低 | ⭐ |
| `equipments` | 3 | 低 | - |
| `joint_types` | 2 | 低 | - |

### 按操作類型分類
| 操作類型 | 數量 | 說明 |
|---------|------|------|
| SELECT | ~80 | 查詢數據 |
| INSERT | ~15 | 新增數據 |
| UPDATE | ~12 | 更新數據 |
| DELETE | ~8 | 刪除數據 |

---

## 🔍 1. exercises 表格查詢

### Service: `ExerciseServiceSupabase`

#### 1.1 取得所有系統動作
```dart
// 使用頻率: 極高（首頁載入、動作選擇）
// 預估執行時間: 100-200ms
// 結果大小: 794 筆

await supabase
  .from('exercises')
  .select()
  .is_('user_id', null);  // 只查系統預設動作
```

**優化建議**:
- ⭐⭐⭐ 新增索引: `CREATE INDEX idx_exercises_user_id_null ON exercises (user_id) WHERE user_id IS NULL;`
- ⭐⭐ 考慮分頁載入（實作無限滾動）
- ⭐ 實作客戶端快取（首次載入後快取）

#### 1.2 按身體部位篩選
```dart
// 使用頻率: 高（動作篩選器）
// 預估執行時間: 50-100ms
// 結果大小: 50-150 筆

await supabase
  .from('exercises')
  .select()
  .eq('body_part', bodyPart)
  .is_('user_id', null);
```

**優化建議**:
- ⭐⭐⭐ 新增複合索引: `CREATE INDEX idx_exercises_body_part ON exercises (body_part) WHERE user_id IS NULL;`

#### 1.3 按器材篩選
```dart
// 使用頻率: 高
// 預估執行時間: 50-100ms

await supabase
  .from('exercises')
  .select()
  .eq('equipment', equipment)
  .is_('user_id', null);
```

**優化建議**:
- ⭐⭐⭐ 新增複合索引: `CREATE INDEX idx_exercises_equipment ON exercises (equipment) WHERE user_id IS NULL;`

#### 1.4 模糊搜尋動作名稱
```dart
// 使用頻率: 中（搜尋功能）
// 預估執行時間: 100-300ms（全表掃描）
// ⚠️ 效能瓶頸

await supabase
  .from('exercises')
  .select()
  .ilike('name', '%$searchTerm%')
  .is_('user_id', null);
```

**優化建議**:
- ⭐⭐⭐ 新增全文搜尋索引: `CREATE INDEX idx_exercises_name_gin ON exercises USING gin(to_tsvector('chinese', name));`
- ⭐⭐ 使用 PostgreSQL Full-Text Search (FTS)
- ⭐ 限制結果數量（LIMIT 50）

#### 1.5 複合篩選
```dart
// 使用頻率: 中（進階篩選）
// 預估執行時間: 80-150ms

await supabase
  .from('exercises')
  .select()
  .eq('body_part', bodyPart)
  .eq('equipment', equipment)
  .eq('training_type', trainingType)
  .is_('user_id', null);
```

**優化建議**:
- ⭐⭐⭐ 新增複合索引: `CREATE INDEX idx_exercises_filters ON exercises (body_part, equipment, training_type) WHERE user_id IS NULL;`

---

## 🏋️ 2. workout_plans 表格查詢

### Service: `WorkoutServiceSupabase`

#### 2.1 查詢用戶訓練計劃（未完成）
```dart
// 使用頻率: 極高（首頁顯示）
// 預估執行時間: 30-80ms
// 結果大小: 5-20 筆

await supabase
  .from('workout_plans')
  .select()
  .eq('trainee_id', userId)
  .eq('completed', false)
  .order('scheduled_date', ascending: true);
```

**優化建議**:
- ⭐⭐⭐ 新增複合索引: `CREATE INDEX idx_workout_plans_user_pending ON workout_plans (trainee_id, completed, scheduled_date);`

#### 2.2 查詢今日訓練
```dart
// 使用頻率: 極高（首頁「今日訓練」）
// 預估執行時間: 20-50ms
// 結果大小: 0-5 筆

await supabase
  .from('workout_plans')
  .select()
  .eq('trainee_id', userId)
  .eq('completed', false)
  .gte('scheduled_date', todayStart)
  .lte('scheduled_date', todayEnd)
  .order('scheduled_date', ascending: true);
```

**優化建議**:
- ⭐⭐⭐ 新增複合索引: `CREATE INDEX idx_workout_plans_today ON workout_plans (trainee_id, completed, scheduled_date) WHERE completed = false;`
- ⭐⭐ 考慮使用日期範圍索引（BRIN）

#### 2.3 查詢已完成訓練（統計用）
```dart
// 使用頻率: 高（統計頁面）
// 預估執行時間: 50-150ms
// 結果大小: 10-500 筆

await supabase
  .from('workout_plans')
  .select()
  .eq('trainee_id', userId)
  .eq('completed', true)
  .gte('completed_date', startDate)
  .lte('completed_date', endDate)
  .order('completed_date', ascending: false);
```

**優化建議**:
- ⭐⭐⭐ 新增複合索引: `CREATE INDEX idx_workout_plans_completed ON workout_plans (trainee_id, completed, completed_date) WHERE completed = true;`

#### 2.4 查詢教練創建的計劃
```dart
// 使用頻率: 中（教練模式）
// 預估執行時間: 40-100ms

await supabase
  .from('workout_plans')
  .select()
  .eq('creator_id', coachId)
  .eq('plan_type', 'trainer')
  .order('scheduled_date', ascending: false);
```

**優化建議**:
- ⭐⭐ 新增複合索引: `CREATE INDEX idx_workout_plans_coach ON workout_plans (creator_id, plan_type, scheduled_date);`

#### 2.5 更新訓練計劃
```dart
// 使用頻率: 高（完成訓練、編輯計劃）
// 預估執行時間: 20-50ms

await supabase
  .from('workout_plans')
  .update({
    'completed': true,
    'completed_date': DateTime.now(),
    'exercises': updatedExercises,
  })
  .eq('id', planId);
```

**優化建議**:
- ✅ 已有主鍵索引（id）
- ⭐ 考慮使用 JSONB 索引加速 exercises 欄位查詢

#### 2.6 刪除訓練計劃
```dart
// 使用頻率: 低
// 預估執行時間: 10-30ms

await supabase
  .from('workout_plans')
  .delete()
  .eq('id', planId);
```

---

## 👤 3. users 表格查詢

### Service: `UserServiceSupabase`

#### 3.1 取得當前用戶資料
```dart
// 使用頻率: 極高（每頁載入）
// 預估執行時間: 10-30ms

await supabase
  .from('users')
  .select()
  .eq('id', userId)
  .maybeSingle();
```

**優化建議**:
- ✅ 已有主鍵索引（id）
- ⭐⭐ 考慮客戶端快取（減少重複查詢）

#### 3.2 檢查資料完整性
```dart
// 使用頻率: 高（登入後）
// 預估執行時間: 10-30ms

await supabase
  .from('users')
  .select('nickname, height, weight')
  .eq('id', userId)
  .maybeSingle();
```

**優化建議**:
- ✅ 已有主鍵索引
- ⭐ 考慮合併到「取得當前用戶資料」查詢

#### 3.3 更新用戶資料
```dart
// 使用頻率: 低（編輯個人資料）
// 預估執行時間: 20-50ms

await supabase
  .from('users')
  .update({
    'display_name': displayName,
    'height': height,
    'weight': weight,
    'profile_updated_at': DateTime.now(),
  })
  .eq('id', userId);
```

#### 3.4 切換用戶角色
```dart
// 使用頻率: 低
// 預估執行時間: 20-50ms

await supabase
  .from('users')
  .update({
    'is_coach': isCoach,
    'is_student': !isCoach,
  })
  .eq('id', userId);
```

#### 3.5 更新體重（同步自 body_data）
```dart
// 使用頻率: 低（新增身體數據時自動觸發）
// 預估執行時間: 20-40ms

await supabase
  .from('users')
  .update({
    'weight': weight,
    'profile_updated_at': DateTime.now(),
  })
  .eq('id', userId);
```

---

## 📊 4. body_data 表格查詢

### Service: `BodyDataServiceSupabase`

#### 4.1 取得用戶身體數據記錄
```dart
// 使用頻率: 中（身體數據頁面）
// 預估執行時間: 20-60ms
// 結果大小: 10-100 筆

await supabase
  .from('body_data')
  .select()
  .eq('user_id', userId)
  .order('record_date', ascending: false);
```

**優化建議**:
- ⭐⭐⭐ 新增複合索引: `CREATE INDEX idx_body_data_user_date ON body_data (user_id, record_date DESC);`

#### 4.2 取得最新記錄
```dart
// 使用頻率: 高（個人資料頁面、統計頁面）
// 預估執行時間: 10-30ms

await supabase
  .from('body_data')
  .select()
  .eq('user_id', userId)
  .order('record_date', ascending: false)
  .limit(1)
  .maybeSingle();
```

**優化建議**:
- ⭐⭐⭐ 使用上述複合索引 + LIMIT 1
- ⭐ 考慮物化視圖（Materialized View）快取最新記錄

#### 4.3 新增身體數據記錄
```dart
// 使用頻率: 低（手動新增）
// 預估執行時間: 20-50ms

await supabase
  .from('body_data')
  .insert({
    'id': generateId(),
    'user_id': userId,
    'record_date': recordDate,
    'weight': weight,
    'body_fat': bodyFat,
    'muscle_mass': muscleMass,
    'bmi': bmi,
  });
```

#### 4.4 更新記錄
```dart
// 使用頻率: 低
// 預估執行時間: 20-50ms

await supabase
  .from('body_data')
  .update(data)
  .eq('id', recordId);
```

#### 4.5 刪除記錄
```dart
// 使用頻率: 低
// 預估執行時間: 10-30ms

await supabase
  .from('body_data')
  .delete()
  .eq('id', recordId);
```

---

## 📈 5. 統計查詢（複雜聚合）

### Service: `StatisticsServiceSupabase`

#### 5.1 訓練頻率統計
```dart
// 使用頻率: 高（統計頁面「概覽」Tab）
// 預估執行時間: 50-150ms
// ⚠️ 複雜聚合查詢

// 客戶端聚合（目前方案）
final plans = await supabase
  .from('workout_plans')
  .select()
  .eq('trainee_id', userId)
  .eq('completed', true)
  .gte('completed_date', startDate)
  .lte('completed_date', endDate);

// 在 Dart 中計算統計
final frequency = calculateFrequency(plans);
```

**優化建議**:
- ⭐⭐⭐ 使用資料庫聚合函式（減少數據傳輸）:
  ```sql
  SELECT 
    COUNT(*) as total_workouts,
    COUNT(DISTINCT DATE(completed_date)) as training_days,
    AVG(total_volume) as avg_volume
  FROM workout_plans
  WHERE trainee_id = ? 
    AND completed = true
    AND completed_date BETWEEN ? AND ?
  ```
- ⭐⭐ 建立 View 或 Function 封裝複雜查詢
- ⭐ 考慮使用快取（Redis）

#### 5.2 個人最佳記錄（PR）查詢
```dart
// 使用頻率: 中（統計頁面「力量進步」Tab）
// 預估執行時間: 100-300ms
// ⚠️ 效能瓶頸：需要遍歷所有訓練記錄的 exercises JSONB 欄位

final plans = await supabase
  .from('workout_plans')
  .select()
  .eq('trainee_id', userId)
  .eq('completed', true);

// 在 Dart 中遍歷所有 exercises，找出最大重量
final personalRecords = calculatePersonalRecords(plans);
```

**優化建議**:
- ⭐⭐⭐ 新增 JSONB 索引:
  ```sql
  CREATE INDEX idx_workout_plans_exercises 
  ON workout_plans USING gin(exercises);
  ```
- ⭐⭐⭐ 使用資料庫函式:
  ```sql
  CREATE FUNCTION get_personal_records(user_id UUID, exercise_id TEXT)
  RETURNS TABLE (max_weight DOUBLE PRECISION, achieved_date TIMESTAMPTZ)
  AS $$
    SELECT 
      MAX((exercise->>'weight')::double precision) as max_weight,
      MAX(completed_date) as achieved_date
    FROM workout_plans,
         jsonb_array_elements(exercises) as exercise
    WHERE trainee_id = user_id
      AND exercise->>'exercise_id' = exercise_id
      AND completed = true
    GROUP BY exercise->>'exercise_id'
  $$ LANGUAGE sql;
  ```

#### 5.3 訓練量歷史
```dart
// 使用頻率: 中（統計頁面圖表）
// 預估執行時間: 80-200ms

final plans = await supabase
  .from('workout_plans')
  .select()
  .eq('trainee_id', userId)
  .eq('completed', true)
  .gte('completed_date', startDate)
  .lte('completed_date', endDate)
  .order('completed_date', ascending: true);

// 在 Dart 中計算每日訓練量
final volumeHistory = calculateVolumeHistory(plans);
```

**優化建議**:
- ⭐⭐⭐ 建立彙總表（Aggregated Table）:
  ```sql
  CREATE TABLE daily_workout_summary (
    user_id UUID,
    date DATE,
    total_volume DOUBLE PRECISION,
    total_sets INT,
    workout_count INT,
    PRIMARY KEY (user_id, date)
  );
  ```
- ⭐⭐ 使用觸發器（Trigger）自動更新彙總表

---

## 📝 6. notes 表格查詢

### Service: `NoteServiceSupabase`

#### 6.1 取得用戶筆記
```dart
// 使用頻率: 低（訓練備忘錄頁面）
// 預估執行時間: 20-60ms

await supabase
  .from('notes')
  .select()
  .eq('user_id', userId)
  .order('created_at', ascending: false);
```

**優化建議**:
- ⭐⭐ 新增複合索引: `CREATE INDEX idx_notes_user_date ON notes (user_id, created_at DESC);`

#### 6.2 新增筆記
```dart
// 使用頻率: 低

await supabase
  .from('notes')
  .insert(noteData);
```

#### 6.3 更新筆記
```dart
// 使用頻率: 低

await supabase
  .from('notes')
  .update(noteData)
  .eq('id', noteId);
```

#### 6.4 刪除筆記
```dart
// 使用頻率: 低

await supabase
  .from('notes')
  .delete()
  .eq('id', noteId);
```

---

## ⭐ 7. favorite_exercises 表格查詢

### Service: `FavoritesServiceSupabase`

#### 7.1 取得用戶收藏動作
```dart
// 使用頻率: 中（動作選擇頁面）
// 預估執行時間: 30-80ms
// ⚠️ JOIN 查詢

await supabase
  .from('favorite_exercises')
  .select('*, exercises(*)')
  .eq('user_id', userId)
  .order('created_at', ascending: false);
```

**優化建議**:
- ⭐⭐⭐ 新增複合索引: `CREATE INDEX idx_favorite_exercises_user ON favorite_exercises (user_id, created_at DESC);`
- ⭐⭐ 確保 exercises 表有主鍵索引（已有）

#### 7.2 新增收藏
```dart
// 使用頻率: 低

await supabase
  .from('favorite_exercises')
  .insert({
    'id': generateId(),
    'user_id': userId,
    'exercise_id': exerciseId,
  });
```

#### 7.3 刪除收藏
```dart
// 使用頻率: 低

await supabase
  .from('favorite_exercises')
  .delete()
  .eq('id', favoriteId);
```

---

## 🔧 8. 其他表格查詢

### 8.1 equipments（器材）
```dart
// 使用頻率: 低（首次載入、動作篩選器）
// 預估執行時間: 10-20ms
// 結果大小: 21 筆

await supabase
  .from('equipments')
  .select()
  .order('count', ascending: false);
```

**優化建議**:
- ⭐ 客戶端快取（一次載入後快取）

### 8.2 joint_types（關節類型）
```dart
// 使用頻率: 低
// 預估執行時間: 5-10ms
// 結果大小: 2 筆

await supabase
  .from('joint_types')
  .select();
```

**優化建議**:
- ⭐ 客戶端快取或硬編碼（只有 2 筆資料）

---

## 📊 效能優化優先級總結

### ⭐⭐⭐ 高優先級（立即執行）

1. **exercises 表索引**
   ```sql
   CREATE INDEX idx_exercises_user_id_null 
   ON exercises (user_id) WHERE user_id IS NULL;
   
   CREATE INDEX idx_exercises_body_part 
   ON exercises (body_part) WHERE user_id IS NULL;
   
   CREATE INDEX idx_exercises_equipment 
   ON exercises (equipment) WHERE user_id IS NULL;
   
   CREATE INDEX idx_exercises_filters 
   ON exercises (body_part, equipment, training_type) WHERE user_id IS NULL;
   ```

2. **workout_plans 表索引**
   ```sql
   CREATE INDEX idx_workout_plans_user_pending 
   ON workout_plans (trainee_id, completed, scheduled_date);
   
   CREATE INDEX idx_workout_plans_today 
   ON workout_plans (trainee_id, completed, scheduled_date) WHERE completed = false;
   
   CREATE INDEX idx_workout_plans_completed 
   ON workout_plans (trainee_id, completed, completed_date) WHERE completed = true;
   ```

3. **body_data 表索引**
   ```sql
   CREATE INDEX idx_body_data_user_date 
   ON body_data (user_id, record_date DESC);
   ```

### ⭐⭐ 中優先級（第二階段）

1. **全文搜尋索引**
   ```sql
   CREATE INDEX idx_exercises_name_gin 
   ON exercises USING gin(to_tsvector('chinese', name));
   ```

2. **JSONB 索引（workout_plans.exercises）**
   ```sql
   CREATE INDEX idx_workout_plans_exercises 
   ON workout_plans USING gin(exercises);
   ```

3. **統計彙總表**
   - 建立 daily_workout_summary 表
   - 使用觸發器自動更新

### ⭐ 低優先級（長期優化）

1. **客戶端快取機制**
   - exercises 表（首次載入後快取）
   - equipments 表（靜態數據快取）
   - users 表（當前用戶資料快取）

2. **分頁載入**
   - exercises 表（實作無限滾動）
   - workout_plans 表（歷史記錄分頁）

3. **查詢優化**
   - 減少重複查詢
   - 合併相似查詢
   - 使用 View 封裝複雜查詢

---

## 📈 預期效能提升

| 優化項目 | 預期提升 | 影響範圍 |
|---------|---------|---------|
| exercises 索引 | 50-70% | 動作選擇、篩選、搜尋 |
| workout_plans 索引 | 40-60% | 首頁、訓練記錄、統計 |
| 全文搜尋索引 | 70-90% | 動作搜尋功能 |
| 客戶端快取 | 80-95% | 靜態數據載入 |
| 統計彙總表 | 60-80% | 統計頁面查詢 |

---

## 🔗 相關檔案

- **資料庫結構**: `database_export/database_structure.md`
- **動作完整資訊**: `database_export/01_EXERCISES_COMPLETE.md`
- **原始數據**: `database_export/*.json`

---

**文檔版本**: 1.0  
**最後更新**: 2024-12-26  
**維護者**: StrengthWise 開發團隊

