/// 時間轉換工具類
///
/// 統一管理所有與時間相關的轉換邏輯：
/// - PostgreSQL TSTZRANGE 解析
/// - UTC/本地時間轉換
/// - 日期比較（忽略時間部分）
///
/// 使用範例：
/// ```dart
/// // 解析 PostgreSQL 時間戳
/// final dt = DateTimeUtils.parsePostgresTimestamp('2025-12-15 09:00:00+00');
///
/// // 解析 TSTZRANGE
/// final range = DateTimeUtils.parseTstzRange('[2025-12-15 09:00:00+00,2025-12-15 10:00:00+00)');
///
/// // UTC 日期比較
/// if (DateTimeUtils.isWithinUtcDateRange(trainingDate, startDate, endDate)) {
///   // 在範圍內
/// }
/// ```
class DateTimeUtils {
  // 私有構造函數（工具類不需要實例化）
  DateTimeUtils._();

  /// PostgreSQL 時間戳格式轉換為 Dart DateTime（本地時間）
  ///
  /// PostgreSQL 格式範例：
  ///   - 無引號：2025-12-15 09:00:00+00
  ///   - 有引號："2025-12-15 09:00:00+00"
  ///
  /// Dart ISO 8601 格式：
  ///   - 2025-12-15T09:00:00+00:00
  ///
  /// 轉換步驟：
  ///   1. 移除引號（如果有）
  ///   2. 替換第一個空格為 'T'
  ///   3. 規範化時區（+00 → +00:00）
  ///   4. ⭐ 轉換為本地時間（預設行為）
  ///
  /// 範例：
  /// ```dart
  /// final dt = DateTimeUtils.parsePostgresTimestamp("2025-12-15 09:00:00+00");
  /// print(dt); // 2025-12-15T17:00:00.000+08:00（本地時間，UTC+8）
  /// ```
  ///
  /// 如果需要 UTC 時間，使用 [parsePostgresTimestampUtc]
  static DateTime parsePostgresTimestamp(String timestamp) {
    return parsePostgresTimestampUtc(timestamp).toLocal();
  }

  /// PostgreSQL 時間戳格式轉換為 Dart DateTime（UTC 時間）
  ///
  /// 用於特殊場景（如統計過濾），大部分情況請使用 [parsePostgresTimestamp]
  ///
  /// 範例：
  /// ```dart
  /// final dt = DateTimeUtils.parsePostgresTimestampUtc("2025-12-15 09:00:00+00");
  /// print(dt); // 2025-12-15T09:00:00.000Z（UTC 時間）
  /// ```
  static DateTime parsePostgresTimestampUtc(String timestamp) {
    // 步驟 1：移除引號並修剪空白
    String cleaned = timestamp.trim();
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }

    // 步驟 2：替換第一個空格為 'T'
    cleaned = cleaned.replaceFirst(' ', 'T');

    // 步驟 3：規範化時區格式（+00 → +00:00）
    // 使用正則表達式精確匹配時區部分
    final timezoneRegex = RegExp(r'([+-]\d{2})$');
    if (timezoneRegex.hasMatch(cleaned)) {
      cleaned = cleaned.replaceFirstMapped(
        timezoneRegex,
        (match) => '${match.group(1)}:00',
      );
    }

    return DateTime.parse(cleaned);
  }

  /// 解析 ISO 8601 時間戳為本地時間（統一入口）
  ///
  /// 用於解析資料庫中的 created_at, updated_at 等欄位
  ///
  /// 範例：
  /// ```dart
  /// final dt = DateTimeUtils.parseIsoTimestamp("2025-12-15T09:00:00.000Z");
  /// print(dt); // 2025-12-15T17:00:00.000+08:00（本地時間，UTC+8）
  /// ```
  static DateTime parseIsoTimestamp(String timestamp) {
    return DateTime.parse(timestamp).toLocal();
  }

  /// 格式化本地時間為 UTC ISO 8601 字串（用於儲存到資料庫）
  ///
  /// 用於插入/更新資料庫中的 created_at, updated_at, scheduled_date 等欄位
  ///
  /// 範例：
  /// ```dart
  /// final local = DateTime(2025, 12, 15, 17, 0);  // 本地時間 17:00
  /// final utcStr = DateTimeUtils.formatToUtcIso(local);
  /// print(utcStr); // "2025-12-15T09:00:00.000Z"（UTC）
  /// ```
  static String formatToUtcIso(DateTime localTime) {
    return localTime.toUtc().toIso8601String();
  }

  /// 解析 PostgreSQL TSTZRANGE 字串為開始和結束時間（本地時間）
  ///
  /// 格式範例：
  ///   - "[2025-12-15 09:00:00+00,2025-12-15 10:00:00+00)"
  ///   - "\"[2025-12-15 09:00:00+00,2025-12-15 10:00:00+00)\""
  ///
  /// 返回：本地時間的開始和結束時間
  /// ```dart
  /// {
  ///   'start': DateTime(2025, 12, 15, 17, 0, 0), // 本地時間（UTC+8）
  ///   'end': DateTime(2025, 12, 15, 18, 0, 0),
  /// }
  /// ```
  ///
  /// 範例：
  /// ```dart
  /// final range = DateTimeUtils.parseTstzRange(
  ///   "[2025-12-15 09:00:00+00,2025-12-15 10:00:00+00)"
  /// );
  /// print(range['start']); // 2025-12-15T17:00:00.000+08:00（本地時間）
  /// print(range['end']);   // 2025-12-15T18:00:00.000+08:00
  /// ```
  ///
  /// 如果需要 UTC 時間，使用 [parseTstzRangeUtc]
  static Map<String, DateTime> parseTstzRange(String tstzRange) {
    final utcRange = parseTstzRangeUtc(tstzRange);
    return {
      'start': utcRange['start']!.toLocal(),
      'end': utcRange['end']!.toLocal(),
    };
  }

  /// 解析 PostgreSQL TSTZRANGE 字串為開始和結束時間（UTC）
  ///
  /// 用於特殊場景（如日期範圍查詢），大部分情況請使用 [parseTstzRange]
  ///
  /// 範例：
  /// ```dart
  /// final range = DateTimeUtils.parseTstzRangeUtc(
  ///   "[2025-12-15 09:00:00+00,2025-12-15 10:00:00+00)"
  /// );
  /// print(range['start']); // 2025-12-15T09:00:00.000Z（UTC）
  /// print(range['end']);   // 2025-12-15T10:00:00.000Z
  /// ```
  static Map<String, DateTime> parseTstzRangeUtc(String tstzRange) {
    // 移除外層引號
    String cleaned = tstzRange.replaceAll('"', '').trim();

    // 移除方括號 '[' 和 ')'
    if (cleaned.startsWith('[') || cleaned.startsWith('(')) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.endsWith(']') || cleaned.endsWith(')')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }

    // 分割成兩個時間戳
    final parts = cleaned.split(',');
    if (parts.length != 2) {
      throw FormatException('Invalid TSTZRANGE format: $tstzRange');
    }

    return {
      'start': parsePostgresTimestampUtc(parts[0].trim()),
      'end': parsePostgresTimestampUtc(parts[1].trim()),
    };
  }

  /// 格式化 DateTime 為 PostgreSQL TSTZRANGE 字串
  ///
  /// 範例：
  /// ```dart
  /// final start = DateTime.utc(2025, 12, 15, 9, 0);
  /// final end = DateTime.utc(2025, 12, 15, 10, 0);
  /// final range = DateTimeUtils.formatToTstzRange(start, end);
  /// print(range); // "[2025-12-15T09:00:00.000Z,2025-12-15T10:00:00.000Z)"
  /// ```
  static String formatToTstzRange(DateTime start, DateTime end) {
    final startStr = start.toUtc().toIso8601String();
    final endStr = end.toUtc().toIso8601String();
    return '[$startStr,$endStr)';
  }

  /// 取得 UTC 日期（忽略時間部分）
  ///
  /// 用於統計過濾，避免時區轉換導致日期改變
  ///
  /// 範例：
  /// ```dart
  /// // 數據庫：2025-12-27T16:00:45Z (UTC)
  /// // 本地：  2025-12-28 00:00:45 (UTC+8)
  ///
  /// final dbTime = DateTime.parse('2025-12-27T16:00:45Z');
  /// final utcDate = DateTimeUtils.getUtcDate(dbTime);
  /// print(utcDate); // 2025-12-27 00:00:00.000Z ✅ 正確
  ///
  /// // 如果直接用 toLocal()：
  /// final localDate = dbTime.toLocal();
  /// print(localDate); // 2025-12-28 00:00:45 ❌ 日期錯誤
  /// ```
  static DateTime getUtcDate(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  /// 比較兩個 DateTime 的 UTC 日期（忽略時間部分）
  ///
  /// 返回：
  ///   - 負數：date1 < date2
  ///   - 0：date1 == date2（同一天）
  ///   - 正數：date1 > date2
  ///
  /// 範例：
  /// ```dart
  /// final date1 = DateTime.parse('2025-12-27T16:00:00Z');
  /// final date2 = DateTime.parse('2025-12-28T08:00:00Z');
  ///
  /// final result = DateTimeUtils.compareUtcDates(date1, date2);
  /// print(result); // -1 (date1 在 date2 之前)
  /// ```
  static int compareUtcDates(DateTime date1, DateTime date2) {
    final utcDate1 = getUtcDate(date1);
    final utcDate2 = getUtcDate(date2);
    return utcDate1.compareTo(utcDate2);
  }

  /// 檢查兩個 DateTime 是否為同一天（UTC）
  ///
  /// 範例：
  /// ```dart
  /// final dt1 = DateTime.parse('2025-12-27T16:00:00Z');
  /// final dt2 = DateTime.parse('2025-12-27T23:59:59Z');
  ///
  /// print(DateTimeUtils.isSameUtcDate(dt1, dt2)); // true
  /// ```
  static bool isSameUtcDate(DateTime date1, DateTime date2) {
    return compareUtcDates(date1, date2) == 0;
  }

  /// 檢查 DateTime 是否在指定的 UTC 日期範圍內（包含邊界）
  ///
  /// 範例：
  /// ```dart
  /// final target = DateTime.parse('2025-12-28T16:00:00Z');
  /// final start = DateTime.parse('2025-12-28T00:00:00Z');
  /// final end = DateTime.parse('2025-12-29T00:00:00Z');
  ///
  /// print(DateTimeUtils.isWithinUtcDateRange(target, start, end)); // true
  /// ```
  static bool isWithinUtcDateRange(
    DateTime target,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final targetDate = getUtcDate(target);
    final startDate = getUtcDate(rangeStart);
    final endDate = getUtcDate(rangeEnd);

    return !targetDate.isBefore(startDate) && !targetDate.isAfter(endDate);
  }

  /// 獲取本地時間的 UTC 日期（用於範圍查詢）
  ///
  /// 用途：將用戶選擇的日期範圍（本地時間）轉換為 UTC 日期進行比較
  ///
  /// 範例：
  /// ```dart
  /// // 用戶選擇：2025-12-28（本地時間）
  /// final localDate = DateTime(2025, 12, 28);
  /// final utcDate = DateTimeUtils.localDateToUtcDate(localDate);
  /// print(utcDate); // 2025-12-28 00:00:00.000Z（UTC）
  ///
  /// // 注意：這裡不是時區轉換，而是將本地日期「解釋」為 UTC 日期
  /// ```
  static DateTime localDateToUtcDate(DateTime localDate) {
    return DateTime.utc(localDate.year, localDate.month, localDate.day);
  }
}

