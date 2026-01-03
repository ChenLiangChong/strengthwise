import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../interfaces/i_invite_code_service.dart';
import '../../models/invite_code_model.dart';

/// 邀請碼服務實作（Supabase）- 簡化版
class InviteCodeServiceSupabase implements IInviteCodeService {
  final SupabaseClient _supabase;

  InviteCodeServiceSupabase(this._supabase);

  /// 生成隨機邀請碼（6 位大寫字母+數字）
  /// 排除易混淆的字符（I, O, 0, 1）
  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  @override
  Future<InviteCodeModel> generateInviteCode(String coachId) async {
    // 刪除該教練之前的所有邀請碼（確保只有一個有效碼）
    await _supabase
        .from('invite_codes')
        .delete()
        .eq('coach_id', coachId);

    // 生成唯一邀請碼（最多嘗試 10 次）
    String code = '';
    bool isUnique = false;
    int attempts = 0;

    while (!isUnique && attempts < 10) {
      code = _generateRandomCode();
      attempts++;

      // 檢查邀請碼是否已存在
      final existing = await _supabase
          .from('invite_codes')
          .select('code')
          .eq('code', code)
          .maybeSingle();

      if (existing == null) {
        isUnique = true;
      }
    }

    if (!isUnique) {
      throw Exception('無法生成唯一邀請碼，請稍後重試');
    }

    // 創建邀請碼（5 分鐘有效）
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 5));

    final data = {
      'code': code,
      'coach_id': coachId,
      'created_at': now.toUtc().toIso8601String(),
      'expires_at': expiresAt.toUtc().toIso8601String(),
    };

    final result = await _supabase
        .from('invite_codes')
        .insert(data)
        .select()
        .single();

    return InviteCodeModel.fromSupabase(result);
  }

  @override
  Future<String> validateAndUseCode({
    required String code,
    required String traineeId,
  }) async {
    // 轉換為大寫（不區分大小寫）
    final upperCode = code.trim().toUpperCase();

    if (upperCode.length != 6) {
      throw Exception('邀請碼格式錯誤（應為 6 位字母+數字）');
    }

    // 查詢邀請碼
    final result = await _supabase
        .from('invite_codes')
        .select()
        .eq('code', upperCode)
        .maybeSingle();

    if (result == null) {
      throw Exception('邀請碼不存在或已失效');
    }

    final inviteCode = InviteCodeModel.fromSupabase(result);

    // 檢查是否過期
    if (!inviteCode.isValid) {
      // 刪除過期邀請碼
      await _supabase
          .from('invite_codes')
          .delete()
          .eq('code', upperCode);

      throw Exception('邀請碼已過期');
    }

    // 檢查是否自己邀請自己
    if (inviteCode.coachId == traineeId) {
      throw Exception('無法使用自己的邀請碼');
    }

    // 刪除邀請碼（用完即刪）
    await _supabase
        .from('invite_codes')
        .delete()
        .eq('code', upperCode);

    return inviteCode.coachId;
  }
}

