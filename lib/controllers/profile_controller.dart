import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/user/user_model.dart';
import '../services/interfaces/i_user_service.dart';
import '../services/interfaces/i_auth_service.dart';
import '../services/service_locator.dart' show serviceLocator;
import 'interfaces/i_auth_controller.dart';

/// Profile 控制器
/// 
/// 負責管理個人資料相關的業務邏輯與狀態
class ProfileController extends ChangeNotifier {
  final IUserService _userService;
  final IAuthService _authService;

  ProfileController({
    required IUserService userService,
    required IAuthService authService,
  })  : _userService = userService,
        _authService = authService;

  // ==================== 狀態 ====================

  UserModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // ==================== Getters ====================

  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOAuthUser => _authService.isOAuthUser();
  bool get hasPassword => _authService.hasPassword();
  
  Map<String, dynamic>? get currentUser => _authService.getCurrentUser();
  String get userEmail => currentUser?['email'] ?? '';

  // ==================== 個人資料載入 ====================

  /// 載入當前用戶的個人資料
  Future<void> loadUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userProfile = await _userService.getCurrentUserProfile();
      _userProfile = userProfile;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '載入個人資料失敗: $e';
      debugPrint('[PROFILE_CONTROLLER] ❌ $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== 個人資料更新 ====================

  /// 更新個人資料
  Future<bool> updateUserProfile({
    String? displayName,
    String? nickname,
    String? gender,
    bool? genderVisible,
    double? height,
    double? weight,
    DateTime? birthDate,
    String? bio,
    String? unitSystem,
    bool? isCoach,
    bool? isStudent,
    File? avatarFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _userService.updateUserProfile(
        displayName: displayName,
        nickname: nickname,
        gender: gender,
        genderVisible: genderVisible,
        height: height,
        weight: weight,
        birthDate: birthDate,
        bio: bio,
        unitSystem: unitSystem,
        isCoach: isCoach,
        isStudent: isStudent,
        avatarFile: avatarFile,
      );

      if (success) {
        // 重新載入最新資料
        await loadUserProfile();
        _errorMessage = null;
      } else {
        _errorMessage = '保存失敗';
      }

      return success;
    } catch (e) {
      _errorMessage = '保存失敗: $e';
      debugPrint('[PROFILE_CONTROLLER] ❌ $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== 角色切換 ====================

  /// 切換教練模式
  Future<bool> toggleCoachRole(bool isCoach) async {
    try {
      await _userService.toggleUserRole(isCoach);
      await loadUserProfile();
      return true;
    } catch (e) {
      _errorMessage = '切換角色失敗: $e';
      debugPrint('[PROFILE_CONTROLLER] ❌ $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  // ==================== 認證相關 ====================

  /// 為 OAuth 用戶設置密碼
  Future<bool> setPasswordForOAuthUser(String newPassword) async {
    try {
      final success = await _authService.setPasswordForOAuthUser(newPassword);
      if (success) {
        // 密碼狀態已改變，通知 UI 更新
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = '設置密碼失敗: $e';
      debugPrint('[PROFILE_CONTROLLER] ❌ $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  /// 登出
  /// 
  /// 委託給 AuthController 處理（統一登出邏輯，包括 FCM Token 刪除）
  Future<void> signOut() async {
    try {
      // ⭐ v3.0-C: 統一使用 AuthController 登出（包含 FCM Token 刪除）
      final authController = serviceLocator<IAuthController>();
      await authController.signOut();
    } catch (e) {
      _errorMessage = '登出失敗: $e';
      debugPrint('[PROFILE_CONTROLLER] ❌ $_errorMessage');
      notifyListeners();
      rethrow;
    }
  }

  // ==================== 檢查個人資料完整度 ====================

  /// 檢查個人資料是否完整（用於首次設置檢查）
  bool isProfileCompleted() {
    if (_userProfile == null) return false;

    return _userProfile!.displayName != null &&
        _userProfile!.displayName!.isNotEmpty &&
        _userProfile!.nickname != null &&
        _userProfile!.nickname!.isNotEmpty &&
        _userProfile!.gender != null &&
        _userProfile!.height != null &&
        _userProfile!.weight != null &&
        _userProfile!.birthDate != null;
  }

  // ==================== 清理 ====================

  /// 清除錯誤訊息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

