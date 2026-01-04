---
description: "Supabase PostgreSQL 資料庫規範：表格設計、Model 轉換、RLS 策略。適用於 Model 和 Service 層。"
globs: lib/models/**/*.dart,lib/services/**/*.dart,migrations/**/*.sql
alwaysApply: false
---

# Supabase 資料庫規範

<critical>
1. 禁止直接操作 `Map<String, dynamic>`，必須透過 Model
2. 禁止直接呼叫 `supabase.from()`，必須透過 Service Interface
3. Model 必須實作 `fromSupabase()` 和 `toMap()`
4. 資料庫使用 `snake_case`，Dart 使用 `camelCase`
</critical>

## ✅ 正確做法

```dart
// Model 操作
final record = WorkoutRecord.fromSupabase(data);
await workoutService.createRecord(record);

// Service 使用
final workoutService = serviceLocator<IWorkoutService>();
```

## ❌ 禁止做法

```dart
// 直接插入 Map
await supabase.from('workout_plans').insert({'title': 'Test'});

// 直接實例化 Service
final service = WorkoutServiceSupabase();
```

## 🔐 RLS 索引規則

```sql
-- RLS 欄位必須建立索引（避免全表掃描）
CREATE INDEX idx_workout_plans_user_id ON workout_plans(user_id);
CREATE INDEX idx_workout_plans_trainee_id ON workout_plans(trainee_id);
```

詳見：`@docs/DATABASE_SUPABASE.md`
