import 'package:strengthwise/utils/datetime_utils.dart';

/// 紅綠燈狀態枚舉
enum TrafficLight {
  red('RED'),
  amber('AMBER'),
  green('GREEN');

  final String value;
  const TrafficLight(this.value);

  /// 從字串解析
  static TrafficLight? fromString(String? value) {
    if (value == null) return null;
    return TrafficLight.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => TrafficLight.amber,
    );
  }

  /// 取得中文標籤
  String get label {
    switch (this) {
      case TrafficLight.red:
        return '需關注';
      case TrafficLight.amber:
        return '稍注意';
      case TrafficLight.green:
        return '狀態良好';
    }
  }

  /// 取得表情圖示
  String get emoji {
    switch (this) {
      case TrafficLight.red:
        return '🔴';
      case TrafficLight.amber:
        return '🟡';
      case TrafficLight.green:
        return '🟢';
    }
  }
}

/// 課前問卷詳細指標
///
/// 基於 Hooper Index 的五維度評估
class ReadinessMetrics {
  /// 睡眠品質 (1-5，5=很好)
  final int sleepQuality;

  /// 睡眠時數 (3-12 小時)
  final double sleepHours;

  /// 肌肉痠痛程度 (1-5，5=無痠痛)
  final int soreness;

  /// 心理壓力程度 (1-5，5=無壓力)
  final int stress;

  /// 能量水平 (1-5，5=精力充沛)
  final int energyLevel;

  /// 學員備註（選填）
  final String? notes;

  const ReadinessMetrics({
    required this.sleepQuality,
    required this.sleepHours,
    required this.soreness,
    required this.stress,
    required this.energyLevel,
    this.notes,
  });

  /// 從 JSONB 解析
  factory ReadinessMetrics.fromJson(Map<String, dynamic> json) {
    return ReadinessMetrics(
      sleepQuality: (json['sleep_quality'] as num?)?.toInt() ?? 3,
      sleepHours: (json['sleep_hours'] as num?)?.toDouble() ?? 7.0,
      soreness: (json['soreness'] as num?)?.toInt() ?? 3,
      stress: (json['stress'] as num?)?.toInt() ?? 3,
      energyLevel: (json['energy_level'] as num?)?.toInt() ?? 3,
      notes: json['notes'] as String?,
    );
  }

  /// 轉換為 JSONB
  Map<String, dynamic> toJson() {
    return {
      'sleep_quality': sleepQuality,
      'sleep_hours': sleepHours,
      'soreness': soreness,
      'stress': stress,
      'energy_level': energyLevel,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  /// 預設值（未填寫）
  factory ReadinessMetrics.empty() {
    return const ReadinessMetrics(
      sleepQuality: 3,
      sleepHours: 7.0,
      soreness: 3,
      stress: 3,
      energyLevel: 3,
    );
  }

  /// 複製並修改
  ReadinessMetrics copyWith({
    int? sleepQuality,
    double? sleepHours,
    int? soreness,
    int? stress,
    int? energyLevel,
    String? notes,
  }) {
    return ReadinessMetrics(
      sleepQuality: sleepQuality ?? this.sleepQuality,
      sleepHours: sleepHours ?? this.sleepHours,
      soreness: soreness ?? this.soreness,
      stress: stress ?? this.stress,
      energyLevel: energyLevel ?? this.energyLevel,
      notes: notes ?? this.notes,
    );
  }

  /// 取得睡眠品質表情
  String get sleepQualityEmoji => _getEmoji(sleepQuality, ['😴', '🥱', '😐', '🙂', '😃']);

  /// 取得痠痛程度表情
  String get sorenessEmoji => _getEmoji(soreness, ['🤕', '😣', '😐', '💪', '⚡']);

  /// 取得壓力程度表情
  String get stressEmoji => _getEmoji(stress, ['🤯', '😓', '😐', '😌', '🧘']);

  /// 取得能量水平表情
  String get energyEmoji => _getEmoji(energyLevel, ['😴', '😑', '😐', '😊', '🔥']);

  String _getEmoji(int value, List<String> emojis) {
    final index = (value - 1).clamp(0, emojis.length - 1);
    return emojis[index];
  }

  @override
  String toString() {
    return 'ReadinessMetrics(sleepQuality: $sleepQuality, sleepHours: $sleepHours, '
        'soreness: $soreness, stress: $stress, energyLevel: $energyLevel)';
  }
}

/// 每日準備度問卷模型
///
/// 記錄學員課前狀態（睡眠品質、痠痛、壓力、能量水平）
class DailyReadinessModel {
  /// 問卷 ID
  final String id;

  /// 學員 ID
  final String userId;

  /// 關聯預約 ID（可選）
  final String? appointmentId;

  /// 關聯課程筆記 ID（可選）
  final String? sessionNoteId;

  /// 記錄日期
  final DateTime logDate;

  /// 準備度總分 (0-100)
  final int? readinessScore;

  /// 紅綠燈狀態
  final TrafficLight? trafficLight;

  /// 詳細指標
  final ReadinessMetrics metrics;

  /// 建立時間
  final DateTime createdAt;

  /// 更新時間
  final DateTime updatedAt;

  const DailyReadinessModel({
    required this.id,
    required this.userId,
    this.appointmentId,
    this.sessionNoteId,
    required this.logDate,
    this.readinessScore,
    this.trafficLight,
    required this.metrics,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 從 Supabase 創建實例
  factory DailyReadinessModel.fromSupabase(Map<String, dynamic> json) {
    final metricsJson = json['metrics'] as Map<String, dynamic>? ?? {};

    return DailyReadinessModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      appointmentId: json['appointment_id'] as String?,
      sessionNoteId: json['session_note_id'] as String?,
      logDate: DateTimeUtils.parseIsoTimestamp(json['log_date'] as String),
      readinessScore: json['readiness_score'] as int?,
      trafficLight: TrafficLight.fromString(json['traffic_light'] as String?),
      metrics: ReadinessMetrics.fromJson(metricsJson),
      createdAt: DateTimeUtils.parseIsoTimestamp(json['created_at']),
      updatedAt: DateTimeUtils.parseIsoTimestamp(json['updated_at']),
    );
  }

  /// 轉換為 Supabase 格式（用於 INSERT）
  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (sessionNoteId != null) 'session_note_id': sessionNoteId,
      'log_date': DateTimeUtils.formatToDateOnly(logDate),
      'readiness_score': readinessScore,
      'traffic_light': trafficLight?.value,
      'metrics': metrics.toJson(),
    };
  }

  /// 轉換為 Supabase 格式（用於 UPDATE，包含 id）
  Map<String, dynamic> toSupabaseWithId() {
    return {
      'id': id,
      ...toSupabase(),
    };
  }

  /// 是否已填寫（metrics 不為空）
  bool get isSubmitted => readinessScore != null;

  /// 是否需要關注（紅燈或低分）
  bool get needsAttention =>
      trafficLight == TrafficLight.red ||
      (readinessScore != null && readinessScore! < 50);

  /// 取得狀態摘要文字
  String get statusSummary {
    if (!isSubmitted) return '尚未填寫';
    return '${trafficLight?.emoji ?? ''} ${trafficLight?.label ?? ''} ($readinessScore 分)';
  }

  /// 取得簡短狀態（用於卡片顯示）
  String get shortSummary {
    if (!isSubmitted) return '未填寫';
    final light = trafficLight ?? TrafficLight.amber;
    return '${light.emoji} ${metrics.sleepQualityEmoji} ${metrics.sleepHours.toStringAsFixed(0)}h | '
        '${metrics.sorenessEmoji} | ${metrics.stressEmoji} | ${metrics.energyEmoji}';
  }

  /// 建立新問卷（未提交狀態）
  factory DailyReadinessModel.create({
    required String userId,
    String? appointmentId,
    DateTime? logDate,
  }) {
    final now = DateTime.now();
    return DailyReadinessModel(
      id: '', // 由資料庫生成
      userId: userId,
      appointmentId: appointmentId,
      sessionNoteId: null,
      logDate: logDate ?? now,
      readinessScore: null,
      trafficLight: null,
      metrics: ReadinessMetrics.empty(),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 複製並修改
  DailyReadinessModel copyWith({
    String? id,
    String? userId,
    String? appointmentId,
    String? sessionNoteId,
    DateTime? logDate,
    int? readinessScore,
    TrafficLight? trafficLight,
    ReadinessMetrics? metrics,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyReadinessModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      appointmentId: appointmentId ?? this.appointmentId,
      sessionNoteId: sessionNoteId ?? this.sessionNoteId,
      logDate: logDate ?? this.logDate,
      readinessScore: readinessScore ?? this.readinessScore,
      trafficLight: trafficLight ?? this.trafficLight,
      metrics: metrics ?? this.metrics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DailyReadinessModel(userId: $userId, logDate: $logDate, '
        'score: $readinessScore, trafficLight: ${trafficLight?.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyReadinessModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

