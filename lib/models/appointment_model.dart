/// AppointmentModel - Phase 2 預約模型
///
/// 對應 Supabase `appointments` 表
/// 處理教練-學員預約資料

import 'package:strengthwise/utils/datetime_utils.dart';

class AppointmentModel {
  // 基礎欄位
  final String id;
  final String coachId;
  final String clientId;

  // 時間範圍（從 TSTZRANGE 轉換）
  final DateTime startTime;
  final DateTime endTime;

  // 狀態
  final AppointmentStatus status;

  // 關聯訓練計劃（可選）
  final String? workoutPlanId;

  // 備註
  final String? notes;
  final String? clientNotes; // 學員備註
  final String? coachNotes; // 教練備註（私密）

  // 取消相關
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime? cancelledAt;

  // 時間戳記
  final DateTime createdAt;
  final DateTime updatedAt;

  AppointmentModel({
    required this.id,
    required this.coachId,
    required this.clientId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.workoutPlanId,
    this.notes,
    this.clientNotes,
    this.coachNotes,
    this.cancellationReason,
    this.cancelledBy,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 從 Supabase 資料創建 Model（處理 snake_case 和 TSTZRANGE）
  factory AppointmentModel.fromSupabase(Map<String, dynamic> json) {
    // 解析 TSTZRANGE 格式："[2024-12-28 10:00:00+00,2024-12-28 11:00:00+00)"
    final timeRange =
        DateTimeUtils.parseTstzRange(json['time_range'] as String);

    return AppointmentModel(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      clientId: json['client_id'] as String,
      startTime: timeRange['start']!, // ⭐ 已經是本地時間
      endTime: timeRange['end']!, // ⭐ 已經是本地時間
      status: _parseStatus(json['status'] as String),
      workoutPlanId: json['workout_plan_id'] as String?,
      notes: json['notes'] as String?,
      clientNotes: json['client_notes'] as String?,
      coachNotes: json['coach_notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledBy: json['cancelled_by'] as String?,
      cancelledAt: json['cancelled_at'] != null
          ? DateTimeUtils.parseIsoTimestamp(
              json['cancelled_at'] as String) // ⭐ 統一工具類
          : null,
      createdAt: DateTimeUtils.parseIsoTimestamp(
          json['created_at'] as String), // ⭐ 統一工具類
      updatedAt: DateTimeUtils.parseIsoTimestamp(
          json['updated_at'] as String), // ⭐ 統一工具類
    );
  }

  /// 轉換為 Supabase 格式（camelCase → snake_case，DateTime → TSTZRANGE）
  Map<String, dynamic> toMap({bool includeId = true}) {
    final map = {
      'coach_id': coachId,
      'client_id': clientId,
      'time_range': DateTimeUtils.formatToTstzRange(startTime, endTime),
      'status': status.toSupabaseString(),
      'workout_plan_id': workoutPlanId,
      'notes': notes,
      'client_notes': clientNotes,
      'coach_notes': coachNotes,
      'cancellation_reason': cancellationReason,
      'cancelled_by': cancelledBy,
      'cancelled_at': cancelledAt != null
          ? DateTimeUtils.formatToUtcIso(cancelledAt!)
          : null,
      'created_at': DateTimeUtils.formatToUtcIso(createdAt),
      'updated_at': DateTimeUtils.formatToUtcIso(updatedAt),
    };

    // 只在 id 不為空且 includeId 為 true 時才包含 id
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }

  /// 解析狀態字串為枚舉
  static AppointmentStatus _parseStatus(String status) {
    switch (status) {
      case 'requested':
        return AppointmentStatus.requested;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      default:
        throw ArgumentError('Unknown appointment status: $status');
    }
  }

  /// 創建副本（用於更新）
  AppointmentModel copyWith({
    String? id,
    String? coachId,
    String? clientId,
    DateTime? startTime,
    DateTime? endTime,
    AppointmentStatus? status,
    String? workoutPlanId,
    String? notes,
    String? clientNotes,
    String? coachNotes,
    String? cancellationReason,
    String? cancelledBy,
    DateTime? cancelledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      clientId: clientId ?? this.clientId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      workoutPlanId: workoutPlanId ?? this.workoutPlanId,
      notes: notes ?? this.notes,
      clientNotes: clientNotes ?? this.clientNotes,
      coachNotes: coachNotes ?? this.coachNotes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 計算預約時長（分鐘）
  int get durationMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  /// 是否已取消
  bool get isCancelled => status == AppointmentStatus.cancelled;

  /// 是否已完成
  bool get isCompleted => status == AppointmentStatus.completed;

  /// 是否待確認
  bool get isPending => status == AppointmentStatus.requested;

  /// 是否已確認
  bool get isConfirmed => status == AppointmentStatus.confirmed;

  @override
  String toString() {
    return 'AppointmentModel(id: $id, coachId: $coachId, clientId: $clientId, '
        'startTime: $startTime, endTime: $endTime, status: $status)';
  }
}

/// 預約狀態枚舉（對應 PostgreSQL appointment_status）
enum AppointmentStatus {
  requested, // 學員請求（待確認）
  confirmed, // 教練確認
  completed, // 已完成
  cancelled, // 已取消
}

/// 枚舉擴展方法
extension AppointmentStatusExtension on AppointmentStatus {
  /// 轉換為 Supabase 字串
  String toSupabaseString() {
    switch (this) {
      case AppointmentStatus.requested:
        return 'requested';
      case AppointmentStatus.confirmed:
        return 'confirmed';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
    }
  }

  /// 顯示名稱（繁體中文）
  String get displayName {
    switch (this) {
      case AppointmentStatus.requested:
        return '待確認';
      case AppointmentStatus.confirmed:
        return '已確認';
      case AppointmentStatus.completed:
        return '已完成';
      case AppointmentStatus.cancelled:
        return '已取消';
    }
  }

  /// 狀態顏色（用於 UI）
  String get colorHex {
    switch (this) {
      case AppointmentStatus.requested:
        return '#FF9800'; // 橙色
      case AppointmentStatus.confirmed:
        return '#4CAF50'; // 綠色
      case AppointmentStatus.completed:
        return '#2196F3'; // 藍色
      case AppointmentStatus.cancelled:
        return '#F44336'; // 紅色
    }
  }
}
