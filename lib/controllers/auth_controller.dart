import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../services/interfaces/i_auth_service.dart';
import '../services/core/error_handling_service.dart';
import '../services/service_locator.dart' show serviceLocator;
import 'interfaces/i_auth_controller.dart';
import 'auth/auth_error_handler.dart';
import 'auth/auth_user_manager.dart';
import 'auth/auth_state_listener.dart';
import 'auth/auth_validators.dart';

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
  
  // 子模組
  late final AuthStateListener _stateListener;
  
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
    // 初始化子模組
    _stateListener = AuthStateListener(
      authService: _authService,
      onStateChanged: _refreshCurrentUser,
    );
    _initialize();
  }
  
  /// 初始化控制器
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
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
      // 使用子模組取消狀態監聽
      await _stateListener.cancel();
      
      _isInitialized = false;
      super.dispose();
    } catch (e) {
      _errorService.logError('釋放身份驗證控制器資源時發生錯誤: $e');
    }
  }
  
  /// 設置認證狀態監聽器
  void _setupAuthStateListener() {
    // 使用子模組設置定期檢查
    _stateListener.setupPeriodicListener();
  }
  
  /// 刷新當前用戶信息
  void _refreshCurrentUser() {
    final userData = _authService.getCurrentUser();
    _user = AuthUserManager.createUserFromData(userData);
    notifyListeners();
  }
  
  /// 處理錯誤
  void _handleError(String errorMsg, {dynamic originalError}) {
    _isLoading = false;
    _errorMessage = AuthErrorHandler.getUserFriendlyError(errorMsg, originalError);
    _errorService.logError('認證錯誤: $errorMsg', type: 'AuthError');
    notifyListeners();
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
        _user = AuthUserManager.createUserFromData(userData);
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
            _user = AuthUserManager.createUserFromData(currentUser);
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
        _user = AuthUserManager.createUserFromData(userData);
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
        _user = AuthUserManager.createUserFromData(userData);
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
    return AuthValidators.isEmailValid(email);
  }
  
  /// 檢查密碼強度
  /// 返回值: 0 (弱) 到 3 (強)
  int getPasswordStrength(String password) {
    return AuthValidators.getPasswordStrength(password);
  }
} 