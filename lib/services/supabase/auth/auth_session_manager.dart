import 'package:supabase_flutter/supabase_flutter.dart';

/// 會話管理器
/// 
/// 負責登出和會話管理
class AuthSessionManager {
  final SupabaseClient _supabase;
  final Function(String) _logDebug;
  final Function(String) _logError;
  final Future<void> Function() _signOutFromGoogle;

  AuthSessionManager({
    required SupabaseClient supabase,
    required Function(String) logDebug,
    required Function(String) logError,
    required Future<void> Function() signOutFromGoogle,
  })  : _supabase = supabase,
        _logDebug = logDebug,
        _logError = logError,
        _signOutFromGoogle = signOutFromGoogle;

  /// 登出
  Future<void> signOut() async {
    try {
      _logDebug('開始登出');

      // 登出 Google（如果使用 Google 登入）
      await _signOutFromGoogle();

      // 登出 Supabase
      await _supabase.auth.signOut();
      _logDebug('Supabase 登出成功');
    } catch (e) {
      _logError('登出失敗: $e');
      rethrow;
    }
  }
}

