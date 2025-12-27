import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Google 登入提供者
/// 
/// 負責處理 Google OAuth 登入流程
class AuthGoogleProvider {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;
  final Function(String) _logDebug;
  final Function(String) _logError;

  AuthGoogleProvider({
    required SupabaseClient supabase,
    required GoogleSignIn googleSignIn,
    required Function(String) logDebug,
    required Function(String) logError,
  })  : _supabase = supabase,
        _googleSignIn = googleSignIn,
        _logDebug = logDebug,
        _logError = logError;

  /// 使用 Google 登入
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      _logDebug('開始 Google 登入流程');

      // 步驟 1：使用 google_sign_in 套件獲取 Google 帳號
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _logDebug('用戶取消 Google 登入');
        return null;
      }

      _logDebug('Google 帳號獲取成功: ${googleUser.email}');

      // 步驟 2：獲取 Google Auth Token
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('無法獲取 Google 認證令牌');
      }

      _logDebug('Google Auth Token 獲取成功');

      // 步驟 3：使用 Google Token 登入 Supabase
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.session == null) {
        throw Exception('Supabase 登入失敗：無法創建會話');
      }

      final user = response.user;
      if (user == null) {
        throw Exception('Supabase 登入失敗：無法獲取用戶資訊');
      }

      _logDebug('Supabase 登入成功: ${user.email}');

      return {
        'uid': user.id,
        'email': user.email ?? '',
        'displayName': user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? '',
        'photoURL': user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'] ?? '',
      };
    } catch (e) {
      _logError('Google 登入失敗: $e');
      rethrow;
    }
  }

  /// 檢查是否已登入 Google
  Future<bool> isGoogleSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// 登出 Google
  Future<void> signOutFromGoogle() async {
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
      _logDebug('Google 登出成功');
    }
  }
}

