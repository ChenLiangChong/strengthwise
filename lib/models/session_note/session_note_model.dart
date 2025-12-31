import 'package:strengthwise/models/session_note/soap_note_model.dart';
import 'package:strengthwise/models/session_note/visual_element_model.dart';

/// 課程筆記模型
/// 
/// Phase 3: 視覺化筆記系統
/// 支援 SOAP 格式 + 多模態視覺元素（手繪、照片、語音、文字）
class SessionNoteModel {
  /// 筆記 ID
  final String id;

  /// 學員 ID
  final String clientId;

  /// 教練 ID
  final String coachId;

  /// 關聯預約 ID（可選）
  final String? appointmentId;

  /// 關聯訓練記錄 ID（可選）
  final String? workoutLogId;

  /// SOAP 筆記內容
  final SoapNoteModel? soap;

  /// 視覺元素列表（手繪、照片、語音、文字）
  final List<VisualElementModel> visualElements;

  /// 快速標籤
  final List<String> quickTags;

  /// 追蹤日期（可選）
  final DateTime? followUpDate;

  /// 隱私控制（private | shared）
  final String visibility;

  /// 創建時間
  final DateTime createdAt;

  /// 更新時間
  final DateTime updatedAt;

  const SessionNoteModel({
    required this.id,
    required this.clientId,
    required this.coachId,
    this.appointmentId,
    this.workoutLogId,
    this.soap,
    this.visualElements = const [],
    this.quickTags = const [],
    this.followUpDate,
    this.visibility = 'private',
    required this.createdAt,
    required this.updatedAt,
  });

  /// 從 Supabase JSON 創建實例
  factory SessionNoteModel.fromSupabase(Map<String, dynamic> json) {
    // 解析 JSONB content 欄位
    final content = json['content'] as Map<String, dynamic>? ?? {};

    // 解析 SOAP 筆記
    final soapJson = content['soap'] as Map<String, dynamic>?;
    final soap = soapJson != null ? SoapNoteModel.fromJson(soapJson) : null;

    // 解析視覺元素列表
    final visualElementsJson =
        content['visual_elements'] as List<dynamic>? ?? [];
    final visualElements = visualElementsJson
        .map((e) => VisualElementModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // 解析快速標籤
    final quickTagsJson = content['quick_tags'] as List<dynamic>? ?? [];
    final quickTags =
        quickTagsJson.map((e) => e.toString()).toList();

    // 解析追蹤日期
    final followUpDateStr = content['follow_up_date'] as String?;
    final followUpDate =
        followUpDateStr != null ? DateTime.parse(followUpDateStr) : null;

    return SessionNoteModel(
      id: json['id'] as String? ?? '',
      clientId: json['client_id'] as String? ?? '',
      coachId: json['coach_id'] as String? ?? '',
      appointmentId: json['appointment_id'] as String?,
      workoutLogId: json['workout_log_id'] as String?,
      soap: soap,
      visualElements: visualElements,
      quickTags: quickTags,
      followUpDate: followUpDate,
      visibility: json['visibility'] as String? ?? 'private',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// 轉換為 Supabase Map（用於插入/更新）
  Map<String, dynamic> toSupabase({bool includeId = true}) {
    // 構建 JSONB content 欄位
    final content = <String, dynamic>{};

    if (soap != null && !soap!.isEmpty) {
      content['soap'] = soap!.toJson();
    }

    if (visualElements.isNotEmpty) {
      content['visual_elements'] =
          visualElements.map((e) => e.toJson()).toList();
    }

    if (quickTags.isNotEmpty) {
      content['quick_tags'] = quickTags;
    }

    if (followUpDate != null) {
      content['follow_up_date'] = followUpDate!.toIso8601String();
    }

    return {
      if (includeId) 'id': id,
      'client_id': clientId,
      'coach_id': coachId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (workoutLogId != null) 'workout_log_id': workoutLogId,
      'content': content,
      'visibility': visibility,
      // created_at 和 updated_at 由資料庫自動管理
    };
  }

  /// 創建副本
  SessionNoteModel copyWith({
    String? id,
    String? clientId,
    String? coachId,
    String? appointmentId,
    String? workoutLogId,
    SoapNoteModel? soap,
    List<VisualElementModel>? visualElements,
    List<String>? quickTags,
    DateTime? followUpDate,
    String? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SessionNoteModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      coachId: coachId ?? this.coachId,
      appointmentId: appointmentId ?? this.appointmentId,
      workoutLogId: workoutLogId ?? this.workoutLogId,
      soap: soap ?? this.soap,
      visualElements: visualElements ?? this.visualElements,
      quickTags: quickTags ?? this.quickTags,
      followUpDate: followUpDate ?? this.followUpDate,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 是否為私人筆記
  bool get isPrivate => visibility == 'private';

  /// 是否為共享筆記
  bool get isShared => visibility == 'shared';

  /// 是否有視覺元素
  bool get hasVisualElements => visualElements.isNotEmpty;

  /// 是否有手繪
  bool get hasDrawings =>
      visualElements.any((e) => e is DrawingElementModel);

  /// 是否有照片
  bool get hasPhotos => visualElements.any((e) => e is PhotoElementModel);

  /// 是否有語音
  bool get hasVoiceNotes =>
      visualElements.any((e) => e is VoiceNoteElementModel);

  /// 是否為空筆記（無 SOAP 內容且無視覺元素）
  bool get isEmpty =>
      (soap == null || soap!.isEmpty) && visualElements.isEmpty;

  @override
  String toString() {
    return 'SessionNoteModel(id: $id, clientId: $clientId, coachId: $coachId, visibility: $visibility, visualElements: ${visualElements.length})';
  }
}

