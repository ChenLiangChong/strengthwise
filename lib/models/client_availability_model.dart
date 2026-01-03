import 'package:strengthwise/utils/datetime_utils.dart';

/// 學員時間偏好優先級
enum AvailabilityPriority {
  /// 最佳時段
  preferred,

  /// 可用時段
  available,

  /// 避免時段
  avoid;

  String toJson() => name;

  static AvailabilityPriority fromJson(String value) {
    return AvailabilityPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AvailabilityPriority.available,
    );
  }

  /// 取得顯示文字
  String get displayName {
    switch (this) {
      case AvailabilityPriority.preferred:
        return '最佳時段';
      case AvailabilityPriority.available:
        return '可用時段';
      case AvailabilityPriority.avoid:
        return '避免時段';
    }
  }

  /// 取得顏色（用於 UI 顯示）
  String get colorHex {
    switch (this) {
      case AvailabilityPriority.preferred:
        return '#4CAF50'; // Green
      case AvailabilityPriority.available:
        return '#2196F3'; // Blue
      case AvailabilityPriority.avoid:
        return '#F44336'; // Red
    }
  }
}

/// 學員時間偏好模型
/// 
/// Phase 3: 雙向時間管理系統
/// 學員設定可運動時間，教練可查看並主動安排訓練
class ClientAvailabilityModel {
  /// ID
  final String id;

  /// 學員 ID
  final String clientId;

  /// 時間範圍（從 TSTZRANGE 轉換）
  final DateTime startTime;
  final DateTime endTime;

  /// 週期性規則（iCal RRULE 格式）
  /// 例如：FREQ=WEEKLY;BYDAY=MO,WE,FR
  final String? recurrenceRule;

  /// 優先級
  final AvailabilityPriority priority;

  /// 備註
  final String? notes;

  /// 創建時間
  final DateTime createdAt;

  /// 更新時間
  final DateTime updatedAt;

  const ClientAvailabilityModel({
    required this.id,
    required this.clientId,
    required this.startTime,
    required this.endTime,
    this.recurrenceRule,
    this.priority = AvailabilityPriority.available,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 從 Supabase JSON 創建實例
  factory ClientAvailabilityModel.fromSupabase(Map<String, dynamic> json) {
    // 解析 TSTZRANGE 格式（與 Phase 2 一致）
    // ⭐ DateTimeUtils.parseTstzRange 已自動轉換為本地時間
    final timeRangeMap = DateTimeUtils.parseTstzRange(json['time_range'] as String);
    
    return ClientAvailabilityModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      startTime: timeRangeMap['start']!,  // ⭐ 已經是本地時間
      endTime: timeRangeMap['end']!,      // ⭐ 已經是本地時間
      recurrenceRule: json['recurrence_rule'] as String?,
      priority: AvailabilityPriority.fromJson(
        json['priority'] as String? ?? 'available',
      ),
      notes: json['notes'] as String?,
      createdAt: DateTimeUtils.parseIsoTimestamp(json['created_at'] as String),  // ⭐ 統一工具類
      updatedAt: DateTimeUtils.parseIsoTimestamp(json['updated_at'] as String),  // ⭐ 統一工具類
    );
  }

  /// 轉換為 Supabase Map（用於插入/更新）
  Map<String, dynamic> toSupabase({bool includeId = true}) {
    return {
      if (includeId) 'id': id,
      'client_id': clientId,
      'time_range': DateTimeUtils.formatToTstzRange(startTime, endTime),
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      'priority': priority.toJson(),
      if (notes != null) 'notes': notes,
      // created_at 和 updated_at 由資料庫自動管理
    };
  }

  /// 創建副本
  ClientAvailabilityModel copyWith({
    String? id,
    String? clientId,
    DateTime? startTime,
    DateTime? endTime,
    String? recurrenceRule,
    AvailabilityPriority? priority,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientAvailabilityModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 是否為週期性時段
  bool get isRecurring => recurrenceRule != null;

  /// 是否為最佳時段
  bool get isPreferred => priority == AvailabilityPriority.preferred;

  /// 是否為避免時段
  bool get isAvoid => priority == AvailabilityPriority.avoid;

  /// 時長（小時）
  double get durationHours {
    final duration = endTime.difference(startTime);
    return duration.inMinutes / 60.0;
  }

  /// 格式化顯示時間範圍
  String get formattedTimeRange {
    return DateTimeUtils.formatToTstzRange(startTime, endTime);
  }

  @override
  String toString() {
    return 'ClientAvailabilityModel(id: $id, clientId: $clientId, startTime: $startTime, endTime: $endTime, priority: ${priority.displayName})';
  }
}

