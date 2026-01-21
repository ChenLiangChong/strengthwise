import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strengthwise/utils/datetime_utils.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import '../interfaces/i_invite_code_service.dart';
import '../../models/invite_code_model.dart';

/// 邀請碼服務實作（Supabase）- 簡化版

/// ⭐ 定義 invite_codes 表的標準查詢欄位（避免 SELECT *）
/// 注意：invite_codes 表以 code 為主鍵，沒有 id 欄位
const String _kInviteCodeSelectFields = '''
  code, coach_id, created_at, expires_at
''';

class InviteCodeServiceSupabase implements IInviteCodeService {
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;

  InviteCodeServiceSupabase(this._supabase, this._errorService);

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
    try {
      // 刪除該教練之前的所有邀請碼（確保只有一個有效碼）
      await _supabase.from('invite_codes').delete().eq('coach_id', coachId);

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
        'created_at': DateTimeUtils.formatToUtcIso(now),
        'expires_at': DateTimeUtils.formatToUtcIso(expiresAt),
      };

      final result = await _supabase
          .from('invite_codes')
          .insert(data)
          .select(_kInviteCodeSelectFields)
          .single();

      return InviteCodeModel.fromSupabase(result);
    } catch (e) {
      _errorService.logError(
        '生成邀請碼失敗: $e',
        type: 'InviteCodeServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<String> validateAndUseCode({
    required String code,
    required String traineeId,
  }) async {
    try {
      // 轉換為大寫（不區分大小寫）
      final upperCode = code.trim().toUpperCase();

      if (upperCode.length != 6) {
        throw Exception('邀請碼格式錯誤（應為 6 位字母+數字）');
      }

      // 查詢邀請碼
      final result = await _supabase
          .from('invite_codes')
          .select(_kInviteCodeSelectFields)
          .eq('code', upperCode)
          .maybeSingle();

      if (result == null) {
        throw Exception('邀請碼不存在或已失效');
      }

      final inviteCode = InviteCodeModel.fromSupabase(result);

      // 檢查是否過期
      if (!inviteCode.isValid) {
        // 刪除過期邀請碼
        await _supabase.from('invite_codes').delete().eq('code', upperCode);

        throw Exception('邀請碼已過期');
      }

      // 檢查是否自己邀請自己
      if (inviteCode.coachId == traineeId) {
        throw Exception('無法使用自己的邀請碼');
      }

      // 刪除邀請碼（用完即刪）
      await _supabase.from('invite_codes').delete().eq('code', upperCode);

      return inviteCode.coachId;
    } catch (e) {
      _errorService.logError(
        '驗證邀請碼失敗: $e',
        type: 'InviteCodeServiceError',
      );
      rethrow;
    }
  }

  /// ⭐ 使用邀請碼綁定教練（RPC 版本）
  ///
  /// 使用 SECURITY DEFINER RPC 函數，可驗證教練是否存在
  @override
  Future<InviteCodeBindResult> bindCoachByInviteCode({
    required String code,
    required String traineeId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'bind_coach_by_invite_code',
        params: {
          'p_code': code.trim().toUpperCase(),
          'p_trainee_id': traineeId,
        },
      );

      // RPC 返回 JSON
      if (response is Map<String, dynamic>) {
        return InviteCodeBindResult.fromJson(response);
      }

      // 異常情況
      return InviteCodeBindResult(
        success: false,
        error: '綁定失敗：無效的回應格式',
      );
    } catch (e) {
      _errorService.logError(
        '使用邀請碼綁定教練失敗: $e',
        type: 'InviteCodeServiceError',
      );
      rethrow;
    }
  }
}
