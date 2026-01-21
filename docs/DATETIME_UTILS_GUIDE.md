# DateTimeUtils - 時間處理工具

> 統一時間轉換工具 API 參考

**最後更新**：2026-01-19

---

## 📋 目錄

1. [快速開始](#快速開始)
2. [API 參考](#api-參考)
3. [使用場景](#使用場景)
4. [常見錯誤](#常見錯誤)

---

## 快速開始

```dart
import 'package:strengthwise/utils/datetime_utils.dart';

// 解析 ISO 時間戳（→ 本地時間）
final dt = DateTimeUtils.parseIsoTimestamp('2025-12-15T09:00:00Z');

// 格式化為 UTC ISO（→ 資料庫）
final utcStr = DateTimeUtils.formatToUtcIso(DateTime.now());

// PostgreSQL 時間戳解析
final dt2 = DateTimeUtils.parsePostgresTimestamp('2025-12-15 09:00:00+00');

// TSTZRANGE 解析
final range = DateTimeUtils.parseTstzRange('[2025-12-15 09:00:00+00,2025-12-15 10:00:00+00)');

// UTC 日期比較
if (DateTimeUtils.isWithinUtcDateRange(trainingDate, startDate, endDate)) {
  // 在範圍內
}
```

---

## API 參考

### 方法列表

| 方法 | 用途 | 返回值 |
|------|------|--------|
| `parseIsoTimestamp()` ⭐ | 解析 ISO 8601 為本地時間 | `DateTime` |
| `formatToUtcIso()` ⭐ | 格式化為 UTC ISO 字串 | `String` |
| `parsePostgresTimestamp()` | 解析 PostgreSQL 時間戳 | `DateTime` |
| `parsePostgresTimestampUtc()` | 解析為 UTC 時間 | `DateTime` |
| `parseTstzRange()` | 解析 TSTZRANGE 字串 | `Map<String, DateTime>` |
| `parseTstzRangeUtc()` | 解析為 UTC 時間 | `Map<String, DateTime>` |
| `formatToTstzRange()` | 格式化為 TSTZRANGE | `String` |
| `getUtcDate()` | 取得 UTC 日期（忽略時間）| `DateTime` |
| `compareUtcDates()` | 比較兩個 UTC 日期 | `int` |
| `isSameUtcDate()` | 檢查是否為同一天 | `bool` |
| `isWithinUtcDateRange()` | 檢查是否在日期範圍內 | `bool` |
| `localDateToUtcDate()` | 本地日期轉 UTC 日期 | `DateTime` |
| `formatToDateOnly()` | 格式化為日期字串（YYYY-MM-DD）| `String` |

---

## 使用場景

### Model 層（fromSupabase / toSupabase）

```dart
factory AppointmentModel.fromSupabase(Map<String, dynamic> json) {
  final range = DateTimeUtils.parseTstzRange(json['time_range'] as String);
  return AppointmentModel(
    startTime: range['start']!,
    endTime: range['end']!,
    createdAt: DateTimeUtils.parseIsoTimestamp(json['created_at']),
  );
}

Map<String, dynamic> toMap() {
  return {
    'time_range': DateTimeUtils.formatToTstzRange(startTime, endTime),
    'created_at': DateTimeUtils.formatToUtcIso(createdAt),
  };
}
```

### Service 層（查詢過濾）

```dart
// 日期範圍查詢
.gte('scheduled_date', DateTimeUtils.formatToUtcIso(startDate))
.lte('scheduled_date', DateTimeUtils.formatToUtcIso(endDate))

// 統計過濾
if (!DateTimeUtils.isWithinUtcDateRange(trainingDate, startDate, endDate)) {
  continue;
}
```

### UI 層（直接使用）

```dart
// ✅ Model 中的 DateTime 已是本地時間
Text('${model.createdAt.hour}:${model.createdAt.minute}')

// ❌ 不需要 .toLocal()
Text('${model.createdAt.toLocal().hour}')  // 多餘！
```

---

## 常見錯誤

### ❌ 直接使用 DateTime.parse()

```dart
// ❌ 錯誤
final dt = DateTime.parse(json['created_at']); 

// ✅ 正確
final dt = DateTimeUtils.parseIsoTimestamp(json['created_at']);
```

### ❌ 直接使用 .toUtc().toIso8601String()

```dart
// ❌ 錯誤
'created_at': DateTime.now().toUtc().toIso8601String()

// ✅ 正確
'created_at': DateTimeUtils.formatToUtcIso(DateTime.now())
```

### ❌ UI 層多餘的 .toLocal()

```dart
// ❌ 錯誤（Model 已經是本地時間）
Text('${model.createdAt.toLocal().hour}')

// ✅ 正確
Text('${model.createdAt.hour}')
```

### ❌ 解析 PostgreSQL 時間戳格式錯誤

```dart
// ❌ 錯誤（格式不兼容）
final dt = DateTime.parse('2025-12-15 09:00:00+00'); // FormatException!

// ✅ 正確
final dt = DateTimeUtils.parsePostgresTimestamp('2025-12-15 09:00:00+00');
```

### ❌ 時區導致日期偏移

```dart
// 問題：UTC 12/27 16:00 → 本地 12/28 00:00
// ❌ 錯誤
final trainingDate = record.scheduledDate.toLocal();
if (trainingDate.day == 27) { /* 誤判！ */ }

// ✅ 正確
if (DateTimeUtils.isWithinUtcDateRange(record.scheduledDate, start, end)) { }
```

---

## 📎 相關資源

- **源碼**：`lib/utils/datetime_utils.dart`
- **測試**：`test/utils/datetime_utils_test.dart`
- **規範**：`.cursor/rules/210-datetime-utils.mdc`
