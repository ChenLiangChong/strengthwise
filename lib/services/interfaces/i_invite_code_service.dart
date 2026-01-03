import '../../models/invite_code_model.dart';

/// 邀請碼服務接口（簡化版）
abstract class IInviteCodeService {
  /// 生成新的邀請碼（教練專用）
  ///
  /// [coachId] - 教練 ID
  /// 返回生成的邀請碼模型
  /// 注意：舊的邀請碼會被自動刪除，確保每個教練只有一個有效邀請碼
  Future<InviteCodeModel> generateInviteCode(String coachId);

  /// 驗證並使用邀請碼
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
}
