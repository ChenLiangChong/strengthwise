import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'dart:async';
import '../models/user_model.dart';
import '../services/interfaces/i_auth_service.dart';
import '../services/auth_wrapper.dart';
import '../services/error_handling_service.dart';
import '../services/service_locator.dart' show Environment, serviceLocator;
import 'interfaces/i_auth_controller.dart';

/// 身份驗證控制器
/// 
/// 管理用戶身份驗證狀態和操作，作為應用程序與身份驗證服務的中間層
/// 提供反應式狀態管理和統一的錯誤處理
class AuthController extends ChangeNotifier implements IAuthController {
  // 依賴注入
  final IAuthService _authService;
  final ErrorHandlingService _errorService;
  
  // 控制器狀態
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  
  // 狀態監聽
  StreamSubscription? _authStateSubscription;
  
  @override
  bool get isLoading => _isLoading;
  
  @override
  String? get errorMessage => _errorMessage;
  
  @override
  bool get isLoggedIn => _user != null;
  
  @override
  UserModel? get user => _user;
  
  /// 構造函數，支持依賴注入
  AuthController({
    IAuthService? authService,
    ErrorHandlingService? errorService,
  }) : 
    _authService = authService ?? serviceLocator<IAuthService>(),
    _errorService = errorService ?? serviceLocator<ErrorHandlingService>() {
    _initialize();
  }
  
  /// 初始化控制器
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // 確保服務已初始化（如果它是AuthWrapper）
      if (_authService is AuthWrapper) {
        final authWrapper = _authService as AuthWrapper;
        await authWrapper.initialize(environment: Environment.production);
      }
      
      // 初始化當前用戶
      _refreshCurrentUser();
      
      // 設置認證狀態變更監聽
      _setupAuthStateListener();
      
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _handleError('初始化身份驗證控制器失敗: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 釋放資源
  @override
  Future<void> dispose() async {
    try {
      // 取消狀態監聽
      await _authStateSubscription?.cancel();
      _authStateSubscription = null;
      
      // 釋放服務資源（如果它是AuthWrapper）
      if (_authService is AuthWrapper) {
        final authWrapper = _authService as AuthWrapper;
        await authWrapper.dispose();
      }
      
      _isInitialized = false;
      super.dispose();
    } catch (e) {
      _errorService.logError('釋放身份驗證控制器資源時發生錯誤: $e');
    }
  }
  
  /// 設置認證狀態監聽器
  void _setupAuthStateListener() {
    if (_authService is AuthWrapper) {
      // AuthWrapper 已經有內建的狀態監聽和處理
      // 這裡可以添加額外的回調或自定義處理邏輯
    } else {
      // 根據具體需求實現狀態監聽
      // 這裡是一個簡單的定期檢查示例
      _authStateSubscription?.cancel();
      _authStateSubscription = Stream.periodic(const Duration(seconds: 30)).listen((_) {
        _refreshCurrentUser();
      });
    }
  }
  
  /// 刷新當前用戶信息
  void _refreshCurrentUser() {
    final userData = _authService.getCurrentUser();
    if (userData != null) {
      _user = UserModel(
        uid: userData['uid'],
        email: userData['email'],
        displayName: userData['displayName'] ?? '',
        photoURL: userData['photoURL'] ?? '',
      );
    } else {
      _user = null;
    }
    notifyListeners();
  }
  
  /// 處理錯誤
  void _handleError(String errorMsg, {dynamic originalError}) {
    _isLoading = false;
    _errorMessage = _getUserFriendlyError(errorMsg, originalError);
    _errorService.logError('認證錯誤: $errorMsg', type: 'AuthError');
    notifyListeners();
  }
  
  /// 將技術錯誤轉換為用戶友好的消息
  String _getUserFriendlyError(String errorMsg, dynamic originalError) {
    // 處理Firebase Auth常見錯誤
    if (originalError is firebase_auth.FirebaseAuthException) {
      switch (originalError.code) {
        case 'user-not-found':
          return '找不到該用戶，請檢查您的電子郵件';
        case 'wrong-password':
          return '密碼不正確';
        case 'invalid-email':
          return '電子郵件格式無效';
        case 'user-disabled':
          return '該帳戶已被停用';
        case 'email-already-in-use':
          return '該電子郵件已被註冊';
        case 'operation-not-allowed':
          return '此操作不被允許';
        case 'weak-password':
          return '密碼強度太弱，請使用更複雜的密碼';
        case 'network-request-failed':
          return '網絡連接失敗，請檢查您的網絡連接';
        case 'too-many-requests':
          return '登入嘗試次數過多，請稍後再試';
        case 'account-exists-with-different-credential':
          return '此電子郵件已與其他登入方式關聯';
        default:
          return '登入失敗: ${originalError.message}';
      }
    }
    
    // 處理Google登入錯誤
    if (originalError.toString().contains('GoogleSignIn')) {
      return 'Google登入失敗，請稍後再試';
    }
    
    // 其他常見錯誤模式
    if (errorMsg.toLowerCase().contains('network')) {
      return '網絡連接錯誤，請檢查您的網絡連接';
    }
    if (errorMsg.toLowerCase().contains('timeout')) {
      return '連接超時，請稍後再試';
    }
    if (errorMsg.toLowerCase().contains('credential')) {
      return '登入憑證無效';
    }
    
    // 默認錯誤消息
    return '登入失敗，請稍後再試';
  }
  
  /// 清除錯誤信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  Future<bool> signInWithEmail(String email, String password) async {
    if (!_isInitialized) await _initialize();
    
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userData = await _authService.signInWithEmail(email, password);
      
      if (userData != null) {
        _user = UserModel(
          uid: userData['uid'],
          email: userData['email'],
          displayName: userData['displayName'] ?? '',
          photoURL: userData['photoURL'] ?? '',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _handleError('登入失敗，請檢查您的電子郵件和密碼');
      return false;
    } catch (e) {
      // 檢查是否為憑證錯誤
      final errorStr = e.toString();
      if (errorStr.contains('invalid-credential') || 
          errorStr.contains('wrong-password') ||
          errorStr.contains('user-not-found')) {
        _handleError('電子郵件或密碼不正確', originalError: e);
      } else if (errorStr.contains('PigeonUserDetails') || 
                 errorStr.contains('is not a subtype')) {
        // 類型轉換錯誤，但可能已經登入成功，嘗試從服務獲取當前用戶
        try {
          await Future.delayed(const Duration(milliseconds: 500));
          final currentUser = _authService.getCurrentUser();
          if (currentUser != null) {
            _user = UserModel(
              uid: currentUser['uid'],
              email: currentUser['email'],
              displayName: currentUser['displayName'] ?? '',
              photoURL: currentUser['photoURL'] ?? '',
            );
            _isLoading = false;
            notifyListeners();
            return true;
          }
        } catch (_) {
          // 如果獲取失敗，繼續顯示錯誤
        }
        _handleError('登入成功但載入用戶資料時出現問題，請重試', originalError: e);
      } else {
        _handleError('電子郵件登入錯誤', originalError: e);
      }
      return false;
    }
  }

  @override
  Future<bool> registerWithEmail(String email, String password) async {
    if (!_isInitialized) await _initialize();
    
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userData = await _authService.registerWithEmail(email, password);
      
      if (userData != null) {
        _user = UserModel(
          uid: userData['uid'],
          email: userData['email'],
          displayName: userData['displayName'] ?? '',
          photoURL: userData['photoURL'] ?? '',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _handleError('註冊失敗，請稍後再試');
      return false;
    } catch (e) {
      _handleError('電子郵件註冊錯誤', originalError: e);
      return false;
    }
  }

  @override
  Future<bool> signInWithGoogle() async {
    if (!_isInitialized) await _initialize();
    
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userData = await _authService.signInWithGoogle();
      
      if (userData != null) {
        _user = UserModel(
          uid: userData['uid'],
          email: userData['email'],
          displayName: userData['displayName'] ?? '',
          photoURL: userData['photoURL'] ?? '',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _handleError("Google 登入失敗");
      return false;
    } catch (e) {
      // 檢查是否為模擬器相關錯誤
      final errorStr = e.toString();
      if (errorStr.contains('模擬器') || errorStr.contains('真實設備')) {
        _handleError("Google 登入在模擬器上不可用。請使用真實設備測試，或使用電子郵件登入功能。", originalError: e);
      } else {
        _handleError("Google 登入錯誤", originalError: e);
      }
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    if (!_isInitialized) await _initialize();
    
    try {
      _isLoading = true;
      notifyListeners();
      
      await _authService.signOut();
      _user = null;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _handleError("登出錯誤", originalError: e);
    }
  }
  
  /// 檢查電子郵件格式是否有效
  bool isEmailValid(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }
  
  /// 檢查密碼強度
  /// 返回值: 0 (弱) 到 3 (強)
  int getPasswordStrength(String password) {
    if (password.length < 6) return 0;
    
    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    
    return strength > 3 ? 3 : strength;
  }
} 