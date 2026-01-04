import '../../models/invite_code_model.dart';

/// 邀請碼綁定結果
class InviteCodeBindResult {
  final bool success;
  final String? error;
  final String? relationshipId;
  final String? coachId;
  final String? coachName;

  InviteCodeBindResult({
    required this.success,
    this.error,
    this.relationshipId,
    this.coachId,
    this.coachName,
  });

  factory InviteCodeBindResult.fromJson(Map<String, dynamic> json) {
    return InviteCodeBindResult(
      success: json['success'] as bool? ?? false,
      error: json['error'] as String?,
      relationshipId: json['relationship_id'] as String?,
      coachId: json['coach_id'] as String?,
      coachName: json['coach_name'] as String?,
    );
  }
}

/// 邀請碼服務接口
abstract class IInviteCodeService {
  /// 生成新的邀請碼（教練專用）
  ///
  /// [coachId] - 教練 ID
  /// 返回生成的邀請碼模型
  /// 注意：舊的邀請碼會被自動刪除，確保每個教練只有一個有效邀請碼
  Future<InviteCodeModel> generateInviteCode(String coachId);

  /// 驗證並使用邀請碼（舊版，保留相容性）
  ///
  /// [code] - 邀請碼
  /// [traineeId] - 學員 ID
  /// 返回教練 ID
  /// 如果邀請碼無效或已過期，拋出異常
  /// 使用後會自動刪除邀請碼
  Future<String> validateAndUseCode({
    required String code,
    required String traineeId,
  });

  /// ⭐ 使用邀請碼綁定教練（RPC 版本）
  ///
  /// 使用 SECURITY DEFINER RPC 函數，可驗證教練是否存在
  /// 並在資料庫層面完成所有邏輯
  ///
  /// [code] - 邀請碼
  /// [traineeId] - 學員 ID
  /// 返回綁定結果（包含成功/失敗、錯誤訊息、教練資訊）
  Future<InviteCodeBindResult> bindCoachByInviteCode({
    required String code,
    required String traineeId,
  });
}
