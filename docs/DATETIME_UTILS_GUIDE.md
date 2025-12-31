# DateTimeUtils 時間轉換工具 - 完整指南

> 統一時間轉換工具的使用指南與實作記錄

**創建日期**：2024年12月29日  
**狀態**：✅ Phase 2.5 完成

---

## 📑 目錄

1. [快速開始](#快速開始)
2. [核心規範](#核心規範)
3. [API 參考](#api-參考)
4. [實作記錄](#實作記錄)
5. [常見問題](#常見問題)

---

## 快速開始

### 基本使用

```dart
import 'package:strengthwise/utils/datetime_utils.dart';

// PostgreSQL 時間戳解析
final dt = DateTimeUtils.parsePostgresTimestamp('2025-12-15 09:00:00+00');

// TSTZRANGE 解析
final range = DateTimeUtils.parseTstzRange('[2025-12-15 09:00:00+00,2025-12-15 10:00:00+00)');

// UTC 日期比較（統計過濾）
if (DateTimeUtils.isWithinUtcDateRange(trainingDate, startDate, endDate)) {
  // 在範圍內
}
```

---

## 核心規範

### 必須遵守 ⭐⭐⭐

1. **所有時間轉換必須使用 `DateTimeUtils`**
   - ✅ 統一工具類（單一真相來源）
   - ❌ 禁止在 Model 中重複實作

2. **PostgreSQL 時間戳解析**
   ```dart
   // ✅ 正確
   final dt = DateTimeUtils.parsePostgresTimestamp(timestamp);
   
   // ❌ 錯誤
   final dt = DateTime.parse(timestamp); // 格式不兼容
   ```

3. **UTC 日期比較**（統計過濾）
   ```dart
   // ✅ 正確
   if (DateTimeUtils.isWithinUtcDateRange(target, start, end)) { }
   
   // ❌ 錯誤：手動實作
   final utcDate = DateTime.utc(target.toUtc().year, ...);
   ```

### 時區處理原則 ⭐

**訓練記錄按 UTC 日期分組**，避免時區轉換導致日期改變：

```dart
// 問題：
// 數據庫：2025-12-27T16:00:45Z (UTC)
// 本地：  2025-12-28 00:00:45 (UTC+8)
// 結果：12/27 的訓練被算成 12/28！❌

// 解決方案：使用 UTC 日期比較
if (DateTimeUtils.isWithinUtcDateRange(trainingDate, startDate, endDate)) {
  // 正確：12/27 < 12/28 → 不在範圍內 ✅
}
```

---

## API 參考

### 完整方法列表

| 方法 | 用途 | 返回值 |
|------|------|--------|
| `parsePostgresTimestamp()` | 解析 PostgreSQL 時間戳 | `DateTime` |
| `parseTstzRange()` | 解析 TSTZRANGE 字串 | `Map<String, DateTime>` |
| `formatToTstzRange()` | 格式化為 TSTZRANGE | `String` |
| `getUtcDate()` | 取得 UTC 日期（忽略時間） | `DateTime` |
| `compareUtcDates()` | 比較兩個 UTC 日期 | `int` |
| `isSameUtcDate()` | 檢查是否為同一天 | `bool` |
| `isWithinUtcDateRange()` | 檢查是否在日期範圍內 | `bool` |
| `localDateToUtcDate()` | 本地日期轉 UTC 日期 | `DateTime` |

### 使用場景

#### 1. TSTZRANGE 解析（Model 層）

```dart
import 'package:strengthwise/utils/datetime_utils.dart';

factory AppointmentModel.fromSupabase(Map<String, dynamic> json) {
  final range = DateTimeUtils.parseTstzRange(json['time_range'] as String);
  return AppointmentModel(
    startTime: range['start']!,
    endTime: range['end']!,
    // ...
  );
}

Map<String, dynamic> toMap() {
  return {
    'time_range': DateTimeUtils.formatToTstzRange(startTime, endTime),
    // ...
  };
}
```

#### 2. UTC 日期比較（Service 層）

```dart
import 'package:strengthwise/utils/datetime_utils.dart';

// 統計過濾
if (trainingDate != null) {
  if (!DateTimeUtils.isWithinUtcDateRange(
    trainingDate,
    timeRange.startDate,
    timeRange.endDate,
  )) {
    continue; // 過濾掉不在範圍內的記錄
  }
}
```

#### 3. 檢查是否為同一天

```dart
final dt1 = DateTime.parse('2025-12-27T09:00:00Z');
final dt2 = DateTime.parse('2025-12-27T23:59:59Z');

if (DateTimeUtils.isSameUtcDate(dt1, dt2)) {
  print('同一天！');
}
```

---

## 實作記錄

### Phase 2.5 完成（2024-12-29）✅

**完成內容**：
- ✅ 創建 `DateTimeUtils` 工具類（240 行，9 個方法）
- ✅ 重構 `AppointmentModel`（-38 行重複代碼）
- ✅ 重構 `AvailabilitySlotModel`（-38 行重複代碼）
- ✅ 重構 `StatisticsServiceSupabase`（簡化 39 行為 9 行）
- ✅ 創建 30 個單元測試（全部通過）
- ✅ 0 個 linter errors

**重構效果**：
- 消除 76 行重複代碼
- 簡化 30 行邏輯代碼
- 代碼質量大幅提升

**測試驗證**：
- 30/30 單元測試通過
- 時區邊界測試通過（核心用例）⭐
- 統計頁面功能正常
- 預約系統功能正常

**新增檔案**：
- `lib/utils/datetime_utils.dart` - 統一工具類
- `test/utils/datetime_utils_test.dart` - 單元測試

**完成時間**：1 天

---

## 常見問題

### ❌ 錯誤 1：直接使用 DateTime.parse() 解析 PostgreSQL 時間戳

```dart
// ❌ 錯誤
final dt = DateTime.parse('2025-12-15 09:00:00+00'); // FormatException!

// ✅ 正確
final dt = DateTimeUtils.parsePostgresTimestamp('2025-12-15 09:00:00+00');
```

### ❌ 錯誤 2：使用本地時間比較導致日期偏移

```dart
// ❌ 錯誤
final trainingDate = record.scheduledDate.toLocal();
if (trainingDate.day == 27) {
  // 可能誤判（UTC 12/27 16:00 → 本地 12/28 00:00）
}

// ✅ 正確
final trainingDateUtc = DateTimeUtils.getUtcDate(record.scheduledDate);
if (trainingDateUtc.day == 27) {
  // 正確（永遠使用 UTC 日期）
}
```

### ❌ 錯誤 3：重複實作時間轉換邏輯

```dart
// ❌ 錯誤：在 Model 中重複實作
static DateTime _parsePostgresTimestamp(String timestamp) {
  // 20+ 行重複代碼
}

// ✅ 正確：使用統一工具類
import 'package:strengthwise/utils/datetime_utils.dart';
final dt = DateTimeUtils.parsePostgresTimestamp(timestamp);
```

### 測試建議

```dart
test('時區邊界測試', () {
  // UTC 12/27 23:59:59
  final dt1 = DateTime.parse('2025-12-27T23:59:59Z');
  // UTC 12/28 00:00:00
  final dt2 = DateTime.parse('2025-12-28T00:00:00Z');
  
  // 應該判斷為不同天
  expect(DateTimeUtils.isSameUtcDate(dt1, dt2), isFalse);
});
```

---

## 相關文檔

- **工具類源碼**：`lib/utils/datetime_utils.dart`
- **單元測試**：`test/utils/datetime_utils_test.dart`
- **開發規範**：`AGENTS.md`（第 7 章節）
- **專案狀態**：`docs/DEVELOPMENT_STATUS.md`

---

**維護者**：StrengthWise 開發團隊  
**最後更新**：2024年12月29日

