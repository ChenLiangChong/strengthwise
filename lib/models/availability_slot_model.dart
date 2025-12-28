/// AvailabilitySlotModel - Phase 2 教練可用時段模型
/// 
/// 對應 Supabase `availability_slots` 表
/// 處理教練設定的可預約時段

class AvailabilitySlotModel {
  // 基礎欄位
  final String id;
  final String coachId;
  
  // 時間範圍（從 TSTZRANGE 轉換）
  final DateTime startTime;
  final DateTime endTime;
  
  // 週期性規則（iCal RRULE 格式，可選）
  final String? recurrenceRule;
  
  // 特殊覆蓋（如：休假日）
  final bool isOverride;
  
  // 備註
  final String? notes;
  
  // 時間戳記
  final DateTime createdAt;
  final DateTime updatedAt;

  AvailabilitySlotModel({
    required this.id,
    required this.coachId,
    required this.startTime,
    required this.endTime,
    this.recurrenceRule,
    this.isOverride = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 從 Supabase 資料創建 Model（處理 snake_case 和 TSTZRANGE）
  factory AvailabilitySlotModel.fromSupabase(Map<String, dynamic> json) {
    // 解析 TSTZRANGE 格式
    final timeRange = _parseTimeRange(json['time_range'] as String);
    
    return AvailabilitySlotModel(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      startTime: timeRange['start']!,
      endTime: timeRange['end']!,
      recurrenceRule: json['recurrence_rule'] as String?,
      isOverride: json['is_override'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// 轉換為 Supabase 格式（camelCase → snake_case，DateTime → TSTZRANGE）
  Map<String, dynamic> toMap({bool includeId = true}) {
    final map = {
      'coach_id': coachId,
      'time_range': _formatTimeRange(startTime, endTime),
      'recurrence_rule': recurrenceRule,
      'is_override': isOverride,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    // 只在 id 不為空且 includeId 為 true 時才包含 id
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }

  /// 解析 PostgreSQL TSTZRANGE 格式
  /// 範例："[2024-12-28 10:00:00+00,2024-12-28 11:00:00+00)"
  static Map<String, DateTime> _parseTimeRange(String timeRange) {
    // 移除前後的 [ 和 )
    final cleaned = timeRange.substring(1, timeRange.length - 1);
    
    // 分割為開始和結束時間
    final parts = cleaned.split(',');
    if (parts.length != 2) {
      throw FormatException('Invalid time range format: $timeRange');
    }
    
    return {
      'start': _parsePostgresTimestamp(parts[0].trim()),
      'end': _parsePostgresTimestamp(parts[1].trim()),
    };
  }

  /// 解析 PostgreSQL 時間戳格式
  /// 輸入：2024-12-28 10:00:00+00 或 "2024-12-28 10:00:00+00"
  /// 輸出：DateTime (UTC)
  static DateTime _parsePostgresTimestamp(String timestamp) {
    // PostgreSQL 可能返回帶雙引號的字符串，先移除
    var cleaned = timestamp.trim();
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    
    // PostgreSQL 格式：2024-12-28 10:00:00+00
    // Dart 期望：2024-12-28T10:00:00+00:00 (ISO 8601)
    
    // 1. 將空格替換為 T
    var normalized = cleaned.replaceFirst(' ', 'T');
    
    // 2. 處理時區格式
    // 使用正則表達式匹配末尾的時區部分
    // 匹配：+00, +08, -05 等格式
    final tzPattern = RegExp(r'([+-]\d{2})$');
    final match = tzPattern.firstMatch(normalized);
    
    if (match != null) {
      // 找到時區，補上 :00
      normalized = '${normalized.substring(0, match.start)}${match.group(1)}:00';
    }
    
    return DateTime.parse(normalized);
  }

  /// 格式化為 PostgreSQL TSTZRANGE 格式
  static String _formatTimeRange(DateTime start, DateTime end) {
    return '[${start.toIso8601String()},${end.toIso8601String()})';
  }

  /// 創建副本（用於更新）
  AvailabilitySlotModel copyWith({
    String? id,
    String? coachId,
    DateTime? startTime,
    DateTime? endTime,
    String? recurrenceRule,
    bool? isOverride,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AvailabilitySlotModel(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      isOverride: isOverride ?? this.isOverride,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 計算時段時長（分鐘）
  int get durationMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  /// 是否為週期性時段
  bool get isRecurring => recurrenceRule != null && recurrenceRule!.isNotEmpty;

  /// 是否為單次時段
  bool get isOneTime => !isRecurring;

  /// 檢查時段是否在指定日期範圍內
  bool isInRange(DateTime rangeStart, DateTime rangeEnd) {
    return startTime.isBefore(rangeEnd) && endTime.isAfter(rangeStart);
  }

  /// 檢查時段是否與另一個時段重疊
  bool overlaps(AvailabilitySlotModel other) {
    return startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime);
  }

  /// 檢查時段是否包含指定時間點
  bool contains(DateTime time) {
    return time.isAfter(startTime) && time.isBefore(endTime);
  }

  /// 格式化顯示時間範圍（繁體中文）
  String get displayTimeRange {
    final startFormatted = _formatTime(startTime);
    final endFormatted = _formatTime(endTime);
    return '$startFormatted - $endFormatted';
  }

  /// 獲取時間範圍字串（別名，與 displayTimeRange 相同）
  String getTimeRangeString() => displayTimeRange;

  /// 獲取週期性描述（繁體中文）
  String getRecurrenceDescription() {
    if (!isRecurring || recurrenceRule == null) {
      return '單次時段';
    }
    
    try {
      final rule = RecurrenceRule.parse(recurrenceRule!);
      return rule.displayName;
    } catch (e) {
      return '週期性時段';
    }
  }

  /// 格式化時間（HH:mm）
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// 格式化顯示日期時間範圍（繁體中文）
  String get displayFullRange {
    final startDate = _formatDate(startTime);
    final startTimeStr = _formatTime(startTime);
    final endTimeStr = _formatTime(endTime);
    return '$startDate $startTimeStr - $endTimeStr';
  }

  /// 格式化日期（yyyy-MM-dd）
  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  String toString() {
    return 'AvailabilitySlotModel(id: $id, coachId: $coachId, '
        'startTime: $startTime, endTime: $endTime, isRecurring: $isRecurring)';
  }
}

/// 週期性規則輔助類（iCal RRULE 格式）
class RecurrenceRule {
  final RecurrenceFrequency frequency;
  final List<int>? byDay;  // 星期幾（1=週一, 7=週日）
  final DateTime? until;    // 結束日期

  RecurrenceRule({
    required this.frequency,
    this.byDay,
    this.until,
  });

  /// 解析 iCal RRULE 字串
  /// 範例："FREQ=WEEKLY;BYDAY=MO,WE,FR"
  factory RecurrenceRule.parse(String rrule) {
    final parts = rrule.split(';');
    RecurrenceFrequency? frequency;
    List<int>? byDay;
    DateTime? until;

    for (final part in parts) {
      final keyValue = part.split('=');
      if (keyValue.length != 2) continue;

      final key = keyValue[0].trim();
      final value = keyValue[1].trim();

      switch (key) {
        case 'FREQ':
          frequency = _parseFrequency(value);
          break;
        case 'BYDAY':
          byDay = _parseByDay(value);
          break;
        case 'UNTIL':
          until = DateTime.parse(value);
          break;
      }
    }

    if (frequency == null) {
      throw FormatException('Invalid RRULE: missing FREQ');
    }

    return RecurrenceRule(
      frequency: frequency,
      byDay: byDay,
      until: until,
    );
  }

  /// 轉換為 iCal RRULE 字串
  String toRRuleString() {
    final parts = <String>['FREQ=${frequency.name.toUpperCase()}'];

    if (byDay != null && byDay!.isNotEmpty) {
      final dayStrings = byDay!.map(_dayToString).join(',');
      parts.add('BYDAY=$dayStrings');
    }

    if (until != null) {
      parts.add('UNTIL=${until!.toIso8601String()}');
    }

    return parts.join(';');
  }

  /// 解析頻率
  static RecurrenceFrequency _parseFrequency(String freq) {
    switch (freq.toUpperCase()) {
      case 'DAILY':
        return RecurrenceFrequency.daily;
      case 'WEEKLY':
        return RecurrenceFrequency.weekly;
      case 'MONTHLY':
        return RecurrenceFrequency.monthly;
      default:
        throw ArgumentError('Unknown frequency: $freq');
    }
  }

  /// 解析星期幾
  static List<int> _parseByDay(String byDay) {
    final days = byDay.split(',');
    return days.map((day) => _stringToDay(day.trim())).toList();
  }

  /// 星期字串轉數字（MO=1, TU=2, ..., SU=7）
  static int _stringToDay(String day) {
    switch (day.toUpperCase()) {
      case 'MO':
        return 1;
      case 'TU':
        return 2;
      case 'WE':
        return 3;
      case 'TH':
        return 4;
      case 'FR':
        return 5;
      case 'SA':
        return 6;
      case 'SU':
        return 7;
      default:
        throw ArgumentError('Unknown day: $day');
    }
  }

  /// 數字轉星期字串
  static String _dayToString(int day) {
    switch (day) {
      case 1:
        return 'MO';
      case 2:
        return 'TU';
      case 3:
        return 'WE';
      case 4:
        return 'TH';
      case 5:
        return 'FR';
      case 6:
        return 'SA';
      case 7:
        return 'SU';
      default:
        throw ArgumentError('Invalid day number: $day');
    }
  }

  /// 顯示名稱（繁體中文）
  String get displayName {
    final freqName = frequency.displayName;
    if (byDay != null && byDay!.isNotEmpty) {
      final dayNames = byDay!.map(_dayToChineseName).join('、');
      return '$freqName（$dayNames）';
    }
    return freqName;
  }

  /// 數字轉繁體中文星期名稱
  String _dayToChineseName(int day) {
    switch (day) {
      case 1:
        return '週一';
      case 2:
        return '週二';
      case 3:
        return '週三';
      case 4:
        return '週四';
      case 5:
        return '週五';
      case 6:
        return '週六';
      case 7:
        return '週日';
      default:
        return '';
    }
  }
}

/// 週期頻率枚舉
enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
}

/// 枚舉擴展方法
extension RecurrenceFrequencyExtension on RecurrenceFrequency {
  /// 顯示名稱（繁體中文）
  String get displayName {
    switch (this) {
      case RecurrenceFrequency.daily:
        return '每日';
      case RecurrenceFrequency.weekly:
        return '每週';
      case RecurrenceFrequency.monthly:
        return '每月';
    }
  }
}

