import 'package:strengthwise/models/session_note/soap_note_model.dart';
import 'package:strengthwise/models/session_note/visual_element_model.dart';
import 'package:strengthwise/utils/datetime_utils.dart';  // ⭐ 新增

/// 課程筆記模型
/// 
/// Phase 3: 視覺化筆記系統
/// 支援 SOAP 格式 + 多模態視覺元素（手繪、照片、語音、文字）
class SessionNoteModel {
  /// 筆記 ID
  final String id;

  /// 筆記標題
  final String title;

  /// 學員 ID（可能為 null，如果學員被刪除）⭐ 修改
  final String? clientId;

  /// 教練 ID（可能為 null，如果教練被刪除）⭐ 修改
  final String? coachId;

  /// 教練名稱快照（即使帳號刪除也保留）⭐ 新增
  final String? coachName;

  /// 學員名稱快照（即使帳號刪除也保留）⭐ 新增
  final String? clientName;

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

  /// 學員是否隱藏此筆記（不影響教練端查看）⭐ 新增
  final bool hiddenByClient;

  /// 教練是否隱藏此筆記（不影響學員端查看）⭐ 新增
  final bool hiddenByCoach;

  /// 創建時間
  final DateTime createdAt;

  /// 更新時間
  final DateTime updatedAt;

  const SessionNoteModel({
    required this.id,
    required this.title,
    this.clientId, // ⭐ 改為可選（學員可能被刪除）
    this.coachId, // ⭐ 改為可選（教練可能被刪除）
    this.coachName, // ⭐ 名稱快照
    this.clientName, // ⭐ 名稱快照
    this.appointmentId,
    this.workoutLogId,
    this.soap,
    this.visualElements = const [],
    this.quickTags = const [],
    this.followUpDate,
    this.visibility = 'shared', // ⭐ v3.1: 預設共用，讓學員能看到
    this.hiddenByClient = false, // ⭐ 新增
    this.hiddenByCoach = false, // ⭐ 新增
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
        followUpDateStr != null ? DateTimeUtils.parseIsoTimestamp(followUpDateStr) : null;  // ⭐ 統一工具類

    return SessionNoteModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '課程筆記',
      clientId: json['client_id'] as String?, // ⭐ 允許為 null（學員被刪除）
      coachId: json['coach_id'] as String?, // ⭐ 允許為 null（教練被刪除）
      coachName: json['coach_name'] as String?, // ⭐ 名稱快照
      clientName: json['client_name'] as String?, // ⭐ 名稱快照
      appointmentId: json['appointment_id'] as String?,
      workoutLogId: json['workout_log_id'] as String?,
      soap: soap,
      visualElements: visualElements,
      quickTags: quickTags,
      followUpDate: followUpDate,
      visibility: json['visibility'] as String? ?? 'shared', // ⭐ v3.1: 預設共用
      hiddenByClient: json['hidden_by_client'] as bool? ?? false, // ⭐ 新增
      hiddenByCoach: json['hidden_by_coach'] as bool? ?? false, // ⭐ 新增
      createdAt: DateTimeUtils.parseIsoTimestamp(json['created_at'] as String),  // ⭐ 統一工具類
      updatedAt: DateTimeUtils.parseIsoTimestamp(json['updated_at'] as String),  // ⭐ 統一工具類
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
      content['follow_up_date'] = DateTimeUtils.formatToUtcIso(followUpDate!);
    }

    return {
      if (includeId) 'id': id,
      'title': title,
      'client_id': clientId,
      'coach_id': coachId,
      if (coachName != null) 'coach_name': coachName, // ⭐ 名稱快照
      if (clientName != null) 'client_name': clientName, // ⭐ 名稱快照
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (workoutLogId != null) 'workout_log_id': workoutLogId,
      'content': content,
      'visibility': visibility,
      'hidden_by_client': hiddenByClient, // ⭐ 新增
      'hidden_by_coach': hiddenByCoach, // ⭐ 新增
      // created_at 和 updated_at 由資料庫自動管理
    };
  }

  /// 創建副本
  SessionNoteModel copyWith({
    String? id,
    String? title,
    String? clientId,
    String? coachId,
    String? coachName, // ⭐ 名稱快照
    String? clientName, // ⭐ 名稱快照
    String? appointmentId,
    String? workoutLogId,
    SoapNoteModel? soap,
    List<VisualElementModel>? visualElements,
    List<String>? quickTags,
    DateTime? followUpDate,
    String? visibility,
    bool? hiddenByClient, // ⭐ 新增
    bool? hiddenByCoach, // ⭐ 新增
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SessionNoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      clientId: clientId ?? this.clientId,
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName, // ⭐ 名稱快照
      clientName: clientName ?? this.clientName, // ⭐ 名稱快照
      appointmentId: appointmentId ?? this.appointmentId,
      workoutLogId: workoutLogId ?? this.workoutLogId,
      soap: soap ?? this.soap,
      visualElements: visualElements ?? this.visualElements,
      quickTags: quickTags ?? this.quickTags,
      followUpDate: followUpDate ?? this.followUpDate,
      visibility: visibility ?? this.visibility,
      hiddenByClient: hiddenByClient ?? this.hiddenByClient, // ⭐ 新增
      hiddenByCoach: hiddenByCoach ?? this.hiddenByCoach, // ⭐ 新增
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

