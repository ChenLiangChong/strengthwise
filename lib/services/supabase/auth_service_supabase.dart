import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../interfaces/i_auth_service.dart';
import '../core/error_handling_service.dart';
import '../service_locator.dart' show Environment;
import 'auth/auth_google_provider.dart';
import 'auth/auth_email_provider.dart';
import 'auth/auth_state_manager.dart';
import 'auth/auth_session_manager.dart';

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

  // 子模組
  late final AuthGoogleProvider _googleProvider;
  late final AuthEmailProvider _emailProvider;
  late final AuthStateManager _stateManager;
  late final AuthSessionManager _sessionManager;

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
        _errorService = errorService {
    // 初始化子模組
    _googleProvider = AuthGoogleProvider(
      supabase: _supabase,
      googleSignIn: _googleSignIn,
      logDebug: _logDebug,
      logError: _logError,
    );
    _emailProvider = AuthEmailProvider(
      supabase: _supabase,
      logDebug: _logDebug,
      logError: _logError,
    );
    _stateManager = AuthStateManager(
      supabase: _supabase,
      logDebug: _logDebug,
      logError: _logError,
    );
    _sessionManager = AuthSessionManager(
      supabase: _supabase,
      logDebug: _logDebug,
      logError: _logError,
      signOutFromGoogle: _googleProvider.signOutFromGoogle,
    );
  }

  /// 初始化服務
  ///
  /// 設置狀態監聽器並嘗試靜默登入（如果已啟用）
  Future<void> initialize({Environment environment = Environment.development}) async {
    if (_isInitialized) return;

    try {
      // 設置環境
      configureForEnvironment(environment);

      // 設置身份驗證狀態監聽
      _stateManager.setupAuthStateListener();

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
      await _stateManager.dispose();

      // 其他資源清理
      _isInitialized = false;
      _logDebug('認證服務資源已釋放');
    } catch (e) {
      _logError('釋放認證服務資源時發生錯誤: $e');
    }
  }

  /// 根據環境配置服務
  void configureForEnvironment(Environment environment) {
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

  @override
  bool isUserLoggedIn() {
    _ensureInitialized();
    return _stateManager.isUserLoggedIn();
  }

  @override
  Map<String, dynamic>? getCurrentUser() {
    _ensureInitialized();
    return _stateManager.getCurrentUser();
  }

  @override
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    _ensureInitialized();

    try {
      final user = await _googleProvider.signInWithGoogle();
      return user;
    } catch (e) {
      _errorService?.logError('Google 登入失敗: $e', type: 'AuthError');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> signInWithEmail(String email, String password) async {
    _ensureInitialized();

    try {
      final user = await _emailProvider.signInWithEmail(email, password);
      return user;
    } catch (e) {
      _errorService?.logError('Email 登入失敗: $e', type: 'AuthError');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> registerWithEmail(String email, String password) async {
    _ensureInitialized();

    try {
      final user = await _emailProvider.registerWithEmail(email, password);
      return user;
    } catch (e) {
      _errorService?.logError('Email 註冊失敗: $e', type: 'AuthError');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    _ensureInitialized();

    try {
      await _sessionManager.signOut();
    } catch (e) {
      _errorService?.logError('登出失敗: $e', type: 'AuthError');
      rethrow;
    }
  }

  /// 確保服務已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      _logDebug('警告：認證服務在初始化前被呼叫');
      throw StateError('認證服務未初始化，請確保在 Service Locator 中正確初始化');
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

