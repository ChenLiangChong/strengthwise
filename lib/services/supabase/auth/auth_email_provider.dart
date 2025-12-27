import 'package:supabase_flutter/supabase_flutter.dart';

/// Email/Password 認證提供者
/// 
/// 負責處理 Email 和密碼的登入、註冊功能
class AuthEmailProvider {
  final SupabaseClient _supabase;
  final Function(String) _logDebug;
  final Function(String) _logError;

  AuthEmailProvider({
    required SupabaseClient supabase,
    required Function(String) logDebug,
    required Function(String) logError,
  })  : _supabase = supabase,
        _logDebug = logDebug,
        _logError = logError;

  /// 使用 Email 登入
  Future<Map<String, dynamic>?> signInWithEmail(String email, String password) async {
    try {
      _logDebug('開始 Email 登入: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        throw Exception('登入失敗：無法創建會話');
      }

      final user = response.user;
      if (user == null) {
        throw Exception('登入失敗：無法獲取用戶資訊');
      }

      _logDebug('Email 登入成功: ${user.email}');

      return {
        'uid': user.id,
        'email': user.email ?? '',
        'displayName': user.userMetadata?['display_name'] ?? '',
        'photoURL': user.userMetadata?['avatar_url'] ?? '',
      };
    } catch (e) {
      _logError('Email 登入失敗: $e');
      rethrow;
    }
  }

  /// 使用 Email 註冊
  Future<Map<String, dynamic>?> registerWithEmail(String email, String password) async {
    try {
      _logDebug('開始 Email 註冊: $email');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': email.split('@')[0], // 預設顯示名稱
        },
      );

      final user = response.user;
      if (user == null) {
        throw Exception('註冊失敗：無法創建用戶');
      }

      _logDebug('Email 註冊成功: ${user.email}');

      // 注意：Supabase 預設需要 Email 驗證
      // 如果啟用了 Email 驗證，用戶需要點擊驗證郵件才能登入
      if (response.session == null) {
        _logDebug('請檢查郵箱並驗證帳號');
      }

      return {
        'uid': user.id,
        'email': user.email ?? '',
        'displayName': user.userMetadata?['display_name'] ?? '',
        'photoURL': user.userMetadata?['avatar_url'] ?? '',
      };
    } catch (e) {
      _logError('Email 註冊失敗: $e');
      rethrow;
    }
  }
}

