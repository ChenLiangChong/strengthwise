# 時間處理規範

<critical>
1. 禁止使用 `DateTime.parse()`，必須使用 `DateTimeUtils.parseIsoTimestamp()`
2. 禁止使用 `.toUtc().toIso8601String()`，必須使用 `DateTimeUtils.formatToUtcIso()`
3. Model 中的 DateTime 都是本地時間，UI 不需要 `.toLocal()`
4. 統計過濾必須使用 UTC 日期比較
</critical>

## ✅ 正確做法

```dart
import 'package:strengthwise/utils/datetime_utils.dart';

// 解析
final dt = DateTimeUtils.parseIsoTimestamp(json['created_at']);

// 格式化
'created_at': DateTimeUtils.formatToUtcIso(DateTime.now())

// TSTZRANGE
final range = DateTimeUtils.parseTstzRange(json['time_range']);
'time_range': DateTimeUtils.formatToTstzRange(startTime, endTime)

// UTC 日期比較
if (DateTimeUtils.isWithinUtcDateRange(trainingDate, startDate, endDate)) {}
```

## ❌ 禁止做法

```dart
// 直接解析
final dt = DateTime.parse(json['created_at']);

// 直接格式化
'created_at': DateTime.now().toUtc().toIso8601String()

// UI 層多餘轉換
Text('${model.createdAt.toLocal().hour}')  // Model 已是本地時間
```

詳見：`@docs/DATETIME_UTILS_GUIDE.md`
