import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 認證狀態管理器
/// 
/// 負責監聽和管理用戶認證狀態變化
class AuthStateManager {
  final SupabaseClient _supabase;
  final Function(String) _logDebug;
  final Function(String) _logError;

  StreamSubscription<AuthState>? _authStateSubscription;

  AuthStateManager({
    required SupabaseClient supabase,
    required Function(String) logDebug,
    required Function(String) logError,
  })  : _supabase = supabase,
        _logDebug = logDebug,
        _logError = logError;

  /// 設置身份驗證狀態監聽器
  void setupAuthStateListener() {
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen(
      (data) {
        final session = data.session;
        final event = data.event;

        if (session != null) {
          _logDebug('用戶已登入: ${session.user.email} (事件: $event)');
        } else {
          _logDebug('用戶已登出 (事件: $event)');
        }
      },
      onError: (error) {
        _logError('認證狀態監聽錯誤: $error');
      },
    );
  }

  /// 檢查用戶是否已登入
  bool isUserLoggedIn() {
    return _supabase.auth.currentSession != null;
  }

  /// 獲取當前用戶資訊
  Map<String, dynamic>? getCurrentUser() {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    return {
      'uid': user.id,
      'email': user.email ?? '',
      'displayName': user.userMetadata?['display_name'] ?? user.userMetadata?['full_name'] ?? '',
      'photoURL': user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'] ?? '',
    };
  }

  /// 釋放資源
  Future<void> dispose() async {
    await _authStateSubscription?.cancel();
    _authStateSubscription = null;
  }
}

