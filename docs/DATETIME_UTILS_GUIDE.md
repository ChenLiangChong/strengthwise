# DateTimeUtils 時間轉換工具 - 完整指南

> 統一時間轉換工具的使用指南與實作記錄

**創建日期**：2024年12月29日  
**最後更新**：2025年1月2日 - v2.2 時區統一化完成 ✅  
**狀態**：✅ 100% 完成

---

## 📑 目錄

1. [快速開始](#快速開始)
2. [核心規範](#核心規範)
3. [API 參考](#api-參考)
4. [實作記錄](#實作記錄)
5. [v2.2 時區統一化](#v22-時區統一化-2025-01-02)
6. [常見問題](#常見問題)

---

## 快速開始

### 基本使用（v2.2 更新）

```dart
import 'package:strengthwise/utils/datetime_utils.dart';

// ⭐ v2.2 新增：統一解析方法
final dt = DateTimeUtils.parseIsoTimestamp('2025-12-15T09:00:00Z');

// ⭐ v2.2 新增：統一格式化方法
final utcStr = DateTimeUtils.formatToUtcIso(DateTime.now());

// PostgreSQL 時間戳解析（已有）
final dt2 = DateTimeUtils.parsePostgresTimestamp('2025-12-15 09:00:00+00');

// TSTZRANGE 解析（已有）
final range = DateTimeUtils.parseTstzRange('[2025-12-15 09:00:00+00,2025-12-15 10:00:00+00)');

// UTC 日期比較（已有）
if (DateTimeUtils.isWithinUtcDateRange(trainingDate, startDate, endDate)) {
  // 在範圍內
}
```

---

## 核心規範

### 必須遵守 ⭐⭐⭐

1. **所有時間解析必須使用 `parseIsoTimestamp()`**（v2.2 新增）
   ```dart
   // ✅ 正確
   final dt = DateTimeUtils.parseIsoTimestamp(json['created_at']);
   
   // ❌ 錯誤
   final dt = DateTime.parse(json['created_at']); // 禁止直接使用
   ```

2. **所有時間格式化必須使用 `formatToUtcIso()`**（v2.2 新增）
   ```dart
   // ✅ 正確
   'created_at': DateTimeUtils.formatToUtcIso(DateTime.now())
   
   // ❌ 錯誤
   'created_at': DateTime.now().toUtc().toIso8601String() // 禁止直接使用
   ```

3. **PostgreSQL 時間戳解析**
   ```dart
   // ✅ 正確
   final dt = DateTimeUtils.parsePostgresTimestamp(timestamp);
   
   // ❌ 錯誤
   final dt = DateTime.parse(timestamp); // 格式不兼容
   ```

4. **UTC 日期比較**（統計過濾）
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

### 完整方法列表（v2.2 更新）

| 方法 | 用途 | 返回值 |
|------|------|--------|
| `parseIsoTimestamp()` ⭐ | 解析 ISO 8601 為本地時間 | `DateTime` |
| `formatToUtcIso()` ⭐ | 格式化本地時間為 UTC ISO | `String` |
| `parsePostgresTimestamp()` | 解析 PostgreSQL 時間戳 | `DateTime` |
| `parsePostgresTimestampUtc()` | 解析為 UTC 時間 | `DateTime` |
| `parseTstzRange()` | 解析 TSTZRANGE 字串 | `Map<String, DateTime>` |
| `parseTstzRangeUtc()` | 解析為 UTC 時間 | `Map<String, DateTime>` |
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

## v2.2 時區統一化 (2025-01-02) ✅

### 完成狀態：100%

**核心成果**：
- ✅ 40+ 個文件統一使用 `DateTimeUtils`
- ✅ 消除 120+ 處重複代碼
- ✅ Model 層：所有 `DateTime` 都是本地時間
- ✅ Service 層：統一使用 `formatToUtcIso()`
- ✅ UI 層：零轉換（不需要 `.toLocal()`）
- ✅ 零 `DateTime.parse()` 直接使用
- ✅ 零 `.toUtc().toIso8601String()` 直接使用

### 統一架構

```
┌────────────────────────────────────────────┐
│  UI 層（用戶交互）                         │
│  DateTime（本地時間）                      │
│  ✅ 直接顯示 slot.startTime.hour           │
│  ✅ 不需要任何 .toLocal() 轉換             │
└──────────────┬─────────────────────────────┘
               │
┌──────────────▼─────────────────────────────┐
│  Model 層（數據模型）                      │
│  fromSupabase():                           │
│    createdAt: DateTimeUtils                │
│      .parseIsoTimestamp(json['created_at'])│  ⭐ 統一
│  toSupabase():                             │
│    'created_at': DateTimeUtils             │
│      .formatToUtcIso(createdAt)            │  ⭐ 統一
└──────────────┬─────────────────────────────┘
               │
┌──────────────▼─────────────────────────────┐
│  Service 層（業務邏輯）                    │
│  創建：'created_at': DateTimeUtils         │
│    .formatToUtcIso(DateTime.now())         │  ⭐ 統一
│  查詢：.gte('scheduled_date',              │
│    DateTimeUtils.formatToUtcIso(date))     │  ⭐ 統一
└──────────────┬─────────────────────────────┘
               │
┌──────────────▼─────────────────────────────┐
│  資料庫層（PostgreSQL + Supabase）         │
│  TIMESTAMPTZ / TSTZRANGE（永遠 UTC）       │
└────────────────────────────────────────────┘
```

### 統計數據

**修改的文件：40+ 個**
- 核心工具：1 個（DateTimeUtils）
- Model 層：13 個
- Service 層：23+ 個
- UI 層：5 個

**消除的重複代碼：120+ 處**
- `DateTime.parse()` → `DateTimeUtils.parseIsoTimestamp()`：50+ 處
- `.toUtc().toIso8601String()` → `DateTimeUtils.formatToUtcIso()`：70+ 處
- 不必要的 `.toLocal()` 調用：10+ 處

### 開發者指南

**新增時間欄位時**：

```dart
// Model（fromSupabase）
createdAt: DateTimeUtils.parseIsoTimestamp(json['created_at'] as String)

// Model（toSupabase）
'created_at': DateTimeUtils.formatToUtcIso(createdAt)

// Service（查詢）
.gte('created_at', DateTimeUtils.formatToUtcIso(startDate))

// UI（顯示）
Text('${model.createdAt.hour}:${model.createdAt.minute}')  // 直接用！
```

**完成時間**：1 天

---

## 常見問題

### ❌ 錯誤 1：直接使用 DateTime.parse()

```dart
// ❌ 錯誤（v2.2 禁止）
final dt = DateTime.parse(json['created_at']); 

// ✅ 正確
final dt = DateTimeUtils.parseIsoTimestamp(json['created_at']);
```

### ❌ 錯誤 2：直接使用 .toUtc().toIso8601String()

```dart
// ❌ 錯誤（v2.2 禁止）
'created_at': DateTime.now().toUtc().toIso8601String()

// ✅ 正確
'created_at': DateTimeUtils.formatToUtcIso(DateTime.now())
```

### ❌ 錯誤 3：UI 層使用 .toLocal() 轉換

```dart
// ❌ 錯誤（Model 已經是本地時間）
Text('${model.createdAt.toLocal().hour}')

// ✅ 正確
Text('${model.createdAt.hour}')  // 直接用！
```

### ❌ 錯誤 4：直接使用 DateTime.parse() 解析 PostgreSQL 時間戳

```dart
// ❌ 錯誤
final dt = DateTime.parse('2025-12-15 09:00:00+00'); // FormatException!

// ✅ 正確
final dt = DateTimeUtils.parsePostgresTimestamp('2025-12-15 09:00:00+00');
```

### ❌ 錯誤 5：使用本地時間比較導致日期偏移

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

### ❌ 錯誤 6：重複實作時間轉換邏輯

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
- **專案狀態**：`docs/DEVELOPMENT_STATUS.md`（v2.2 章節）
- **資料庫設計**：`docs/DATABASE_SUPABASE.md`

---

**維護者**：StrengthWise 開發團隊  
**最後更新**：2025年1月2日 - v2.2 時區統一化完成 ✅

