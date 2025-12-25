import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'interfaces/i_auth_service.dart';
import 'error_handling_service.dart';
import 'service_locator.dart' show Environment;

/// 身份驗證服務的 Supabase 實現
///
/// 提供 Google 登入、Email/Password 登入/註冊以及登出功能
/// 使用 Supabase Auth 作為後端
class AuthServiceSupabase implements IAuthService {
  // 依賴注入
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;
  final ErrorHandlingService? _errorService;

  // 服務狀態
  bool _isInitialized = false;
  Environment _environment = Environment.development;

  // 驗證監聽器
  StreamSubscription<AuthState>? _authStateSubscription;

  /// 創建服務實例
  ///
  /// 允許注入自定義的 Supabase、GoogleSignIn 和 ErrorHandling 實例，便於測試
  AuthServiceSupabase({
    SupabaseClient? supabase,
    GoogleSignIn? googleSignIn,
    ErrorHandlingService? errorService,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _googleSignIn = googleSignIn ?? GoogleSignIn(
          serverClientId: '254965941837-e2p11s22qejt49o5rfd0p2qk20ilefqu.apps.googleusercontent.com',
        ),
        _errorService = errorService;

  /// 初始化服務
  ///
  /// 設置狀態監聽器並嘗試靜默登入（如果已啟用）
  Future<void> initialize({Environment environment = Environment.development}) async {
    if (_isInitialized) return;

    try {
      // 設置環境
      configureForEnvironment(environment);

      // 設置身份驗證狀態監聽
      _setupAuthStateListener();

      _isInitialized = true;
      _logDebug('認證服務初始化完成');
    } catch (e) {
      _logError('認證服務初始化失敗: $e');
      rethrow;
    }
  }

  /// 釋放資源
  Future<void> dispose() async {
    try {
      // 取消身份驗證狀態監聽
      await _authStateSubscription?.cancel();
      _authStateSubscription = null;

      // 其他資源清理
      _isInitialized = false;
      _logDebug('認證服務資源已釋放');
    } catch (e) {
      _logError('釋放認證服務資源時發生錯誤: $e');
    }
  }

  /// 根據環境配置服務
  void configureForEnvironment(Environment environment) {
    _environment = environment;

    switch (environment) {
      case Environment.development:
        _logDebug('認證服務配置為開發環境');
        break;
      case Environment.testing:
        _logDebug('認證服務配置為測試環境');
        break;
      case Environment.production:
        _logDebug('認證服務配置為生產環境');
        break;
    }
  }

  /// 設置身份驗證狀態監聽器
  void _setupAuthStateListener() {
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

  @override
  bool isUserLoggedIn() {
    _ensureInitialized();
    return _supabase.auth.currentSession != null;
  }

  @override
  Map<String, dynamic>? getCurrentUser() {
    _ensureInitialized();
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    return {
      'uid': user.id,
      'email': user.email ?? '',
      'displayName': user.userMetadata?['display_name'] ?? user.userMetadata?['full_name'] ?? '',
      'photoURL': user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'] ?? '',
    };
  }

  @override
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    _ensureInitialized();

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
      _errorService?.logError('Google 登入失敗: $e', type: 'AuthError');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> signInWithEmail(String email, String password) async {
    _ensureInitialized();

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
      _errorService?.logError('Email 登入失敗: $e', type: 'AuthError');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> registerWithEmail(String email, String password) async {
    _ensureInitialized();

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
      _errorService?.logError('Email 註冊失敗: $e', type: 'AuthError');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    _ensureInitialized();

    try {
      _logDebug('開始登出');

      // 登出 Google（如果使用 Google 登入）
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
        _logDebug('Google 登出成功');
      }

      // 登出 Supabase
      await _supabase.auth.signOut();
      _logDebug('Supabase 登出成功');
    } catch (e) {
      _logError('登出失敗: $e');
      _errorService?.logError('登出失敗: $e', type: 'AuthError');
      rethrow;
    }
  }

  /// 確保服務已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      _logDebug('警告：認證服務在初始化前被呼叫');
      if (_environment == Environment.development) {
        // 開發環境自動初始化
        initialize();
      } else {
        throw StateError('認證服務未初始化');
      }
    }
  }

  /// 偵錯日誌
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[AUTH_SUPABASE] $message');
    }
  }

  /// 錯誤日誌
  void _logError(String message) {
    if (kDebugMode) {
      print('[AUTH_SUPABASE ERROR] $message');
    }
    _errorService?.logError(message, type: 'AuthError');
  }
}

