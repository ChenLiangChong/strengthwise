import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'interfaces/i_auth_service.dart';
import 'error_handling_service.dart';
import 'service_locator.dart' show Environment;

/// 身份驗證服務的Firebase實現
/// 
/// 提供Google登入、電子郵件登入/註冊以及登出功能
/// 支持環境配置，統一錯誤處理與資源管理
class AuthWrapper implements IAuthService {
  // 依賴注入
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final ErrorHandlingService? _errorService;
  
  // 服務狀態
  bool _isInitialized = false;
  Environment _environment = Environment.development;
  
  // 驗證監聽器
  StreamSubscription<User?>? _authStateSubscription;
  
  // 服務配置
  bool _silentSignInEnabled = true;
  
  /// 創建服務實例
  /// 
  /// 允許注入自定義的Auth、GoogleSignIn和ErrorHandling實例，便於測試
  AuthWrapper({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    ErrorHandlingService? errorService,
  }) : 
    _auth = auth ?? FirebaseAuth.instance,
    _googleSignIn = googleSignIn ?? GoogleSignIn(),
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
      
      // 嘗試靜默登入（如果已啟用）
      if (_silentSignInEnabled) {
        await _attemptSilentSignIn();
      }
      
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
        // 開發環境設置
        _silentSignInEnabled = true;
        _logDebug('認證服務配置為開發環境');
        break;
      case Environment.testing:
        // 測試環境設置
        _silentSignInEnabled = false;
        _logDebug('認證服務配置為測試環境');
        break;
      case Environment.production:
        // 生產環境設置
        _silentSignInEnabled = true;
        _logDebug('認證服務配置為生產環境');
        break;
    }
  }
  
  /// 設置認證狀態監聽器
  void _setupAuthStateListener() {
    _authStateSubscription?.cancel();
    _authStateSubscription = _auth.authStateChanges().listen(
      (User? user) {
        if (user != null) {
          _logDebug('用戶已登入: ${user.uid}');
        } else {
          _logDebug('用戶已登出');
        }
      },
      onError: (error) {
        _logError('認證狀態監聽錯誤: $error');
      }
    );
  }
  
  /// 嘗試靜默登入（使用現有憑證）
  Future<bool> _attemptSilentSignIn() async {
    try {
      // 檢查Firebase是否已經有登入用戶
      if (_auth.currentUser != null) {
        _logDebug('檢測到現有Firebase會話');
        return true;
      }
      
      // 嘗試使用Google靜默登入
      final googleAccount = await _googleSignIn.signInSilently();
      if (googleAccount != null) {
        _logDebug('Google靜默登入成功');
        
        // 獲取認證信息
        final googleAuth = await googleAccount.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        // 使用Google憑證登入Firebase
        await _auth.signInWithCredential(credential);
        return true;
      }
      
      _logDebug('沒有可用的現有會話');
      return false;
    } catch (e) {
      _logError('靜默登入嘗試失敗: $e');
      return false;
    }
  }
  
  @override
  bool isUserLoggedIn() {
    _ensureInitialized();
    return _auth.currentUser != null;
  }
  
  @override
  Map<String, dynamic>? getCurrentUser() {
    _ensureInitialized();
    final user = _auth.currentUser;
    if (user == null) return null;
    
    return {
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': user.displayName,
      'photoURL': user.photoURL,
    };
  }
  
  @override
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    _ensureInitialized();
    try {
      // 正常流程取得 GoogleSignInAccount...
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _logDebug('Google登入被用戶取消');
        return null;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // 嘗試登入但不使用返回值
      await _auth.signInWithCredential(credential);
      
      // 直接從 currentUser 取得登入資訊
      final user = _auth.currentUser;
      if (user == null) {
        _logError('Google登入後無法獲取用戶資料');
        return null;
      }
      
      _logDebug('Google登入成功: ${user.uid}');
      return {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
      };
    } catch (e) {
      _logError('Google登入錯誤: $e');
      return null;
    }
  }
  
  @override
  Future<Map<String, dynamic>?> signInWithEmail(String email, String password) async {
    _ensureInitialized();
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user == null) {
        _logError('電子郵件登入後無法獲取用戶資料');
        return null;
      }
      
      _logDebug('電子郵件登入成功: ${user.uid}');
      return {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName,
        'photoURL': user.photoURL,
      };
    } catch (e) {
      _logError('電子郵件登入錯誤: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> registerWithEmail(String email, String password) async {
    _ensureInitialized();
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user == null) {
        _logError('電子郵件註冊後無法獲取用戶資料');
        return null;
      }
      
      _logDebug('電子郵件註冊成功: ${user.uid}');
      return {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName,
        'photoURL': user.photoURL,
      };
    } catch (e) {
      _logError('電子郵件註冊錯誤: $e');
      return null;
    }
  }
  
  @override
  Future<void> signOut() async {
    _ensureInitialized();
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _logDebug('用戶登出成功');
    } catch (e) {
      _logError('登出過程發生錯誤: $e');
      rethrow;
    }
  }
  
  /// 確保服務已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      _logDebug('警告: 認證服務在初始化前被調用');
      // 在開發環境中自動初始化，但在其他環境拋出錯誤
      if (_environment == Environment.development) {
        initialize();
      } else {
        throw StateError('認證服務未初始化');
      }
    }
  }
  
  /// 記錄調試信息
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[AUTH] $message');
    }
  }
  
  /// 記錄錯誤信息
  void _logError(String message) {
    // 首先記錄到控制台（僅在調試模式）
    if (kDebugMode) {
      print('[AUTH ERROR] $message');
    }
    
    // 如果有錯誤處理服務，則使用它記錄錯誤
    _errorService?.logError(message);
  }
} 