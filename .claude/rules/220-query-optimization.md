# 查詢效能規範

<critical>
1. 禁止使用 `SELECT *`，必須明確指定欄位
2. 禁止使用 Offset 分頁 `.range()`，必須使用 Cursor 分頁
3. 禁止 N+1 查詢（循環中單獨查詢）
4. 禁止 `COUNT(*)` exact（全表掃描）
</critical>

## ✅ 正確做法

```dart
// 明確欄位 + Cursor 分頁
final data = await supabase
  .from('workout_plans')
  .select('id, title, scheduled_date, completed')
  .lt('scheduled_date', lastCursor)
  .order('scheduled_date', ascending: false)
  .limit(20);

// 批量查詢
final exercises = await supabase
  .from('exercises')
  .select('id, name')
  .in_('id', exerciseIds);

// TSTZRANGE 使用 'ov' 運算子
.filter('time_range', 'ov', '[${start},${end})')
```

## ❌ 禁止做法

```dart
// SELECT * + Offset 分頁
final data = await supabase
  .from('workout_plans')
  .select()
  .range(100, 119);

// N+1 查詢
for (var id in ids) {
  final item = await getById(id);  // 每個都是一次查詢！
}
```

詳見：`@docs/DATABASE_OPTIMIZATION_GUIDE.md`
