/// 邀請碼模型（簡化版）
///
/// 教練生成邀請碼邀請學員遠端綁定
/// - 5 分鐘過期
/// - 用完即刪
/// - 無需管理介面
class InviteCodeModel {
  /// 邀請碼（6 位大寫字母+數字，如：A1B2C3）
  final String code;

  /// 教練 ID
  final String coachId;

  /// 創建時間
  final DateTime createdAt;

  /// 過期時間
  final DateTime expiresAt;

  InviteCodeModel({
    required this.code,
    required this.coachId,
    required this.createdAt,
    required this.expiresAt,
  });

  /// 從 Supabase 數據創建模型
  factory InviteCodeModel.fromSupabase(Map<String, dynamic> json) {
    return InviteCodeModel(
      code: json['code'] as String,
      coachId: json['coach_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  /// 轉換為 Supabase 格式
  Map<String, dynamic> toSupabase() {
    return {
      'code': code,
      'coach_id': coachId,
      'created_at': createdAt.toUtc().toIso8601String(),
      'expires_at': expiresAt.toUtc().toIso8601String(),
    };
  }

  /// 檢查邀請碼是否有效
  bool get isValid {
    return expiresAt.isAfter(DateTime.now());
  }

  /// 獲取剩餘有效時間（秒）
  int get remainingSeconds {
    if (!isValid) return 0;
    return expiresAt.difference(DateTime.now()).inSeconds;
  }

  /// 獲取剩餘有效時間文字（如：「3 分 20 秒」）
  String get remainingTimeText {
    if (!isValid) return '已過期';
    final seconds = remainingSeconds;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes 分 $secs 秒';
    }
    return '$secs 秒';
  }

  @override
  String toString() {
    return 'InviteCodeModel(code: $code, coachId: $coachId, expiresAt: $expiresAt)';
  }
}
