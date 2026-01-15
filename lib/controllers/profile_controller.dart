import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/user/user_model.dart';
import '../models/body_data_record.dart';
import '../models/health_assessment_models.dart'; // ⭐ v3.5: MVVM
import '../models/injury_coach_note_model.dart'; // ⭐ v3.6: MVVM
import '../models/coach_assessment_note_model.dart'; // ⭐ v3.6: MVVM
import '../services/interfaces/i_user_service.dart';
import '../services/interfaces/i_auth_service.dart';
import '../services/interfaces/i_body_data_service.dart';
import '../services/interfaces/i_health_assessment_service.dart'; // ⭐ v3.5: MVVM
import '../services/interfaces/i_injury_coach_note_service.dart'; // ⭐ v3.5: MVVM
import '../services/interfaces/i_coach_assessment_note_service.dart'; // ⭐ v3.6: MVVM
import '../services/service_locator.dart';
import 'interfaces/i_auth_controller.dart';
import 'body_data/body_data_operation_helper.dart';
import 'event_bus_controller.dart';
import '../services/core/app_event_bus.dart'; // ⭐ v3.5: AppEvent

/// Profile 控制器
/// 
/// 負責管理個人資料相關的業務邏輯與狀態
class ProfileController extends ChangeNotifier {
  final IUserService _userService;
  final IAuthService _authService;
  final IBodyDataService _bodyDataService;
  final EventBusController _eventBusController; // ⭐ v3.5

  ProfileController({
    required IUserService userService,
    required IAuthService authService,
    required IBodyDataService bodyDataService,
    required EventBusController eventBusController,
  })  : _userService = userService,
        _authService = authService,
        _bodyDataService = bodyDataService,
        _eventBusController = eventBusController;

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

  /// ⭐ v3.6: MVVM 純查詢方法
  /// 
  /// 直接返回當前用戶資料，不影響 Controller 狀態
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      return await _userService.getCurrentUserProfile();
    } catch (e) {
      debugPrint('[PROFILE_CONTROLLER] ❌ getCurrentUserProfile 失敗: $e');
      return null;
    }
  }

  // ==================== 個人資料更新 ====================

  /// 更新個人資料
  /// 
  /// ⭐ v3.5: 當體重有變更時，自動同步到 body_data 表
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
      // 記錄舊的體重（用於判斷是否有變更）
      final oldWeight = _userProfile?.weight;
      
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
        
        // ⭐ v3.5: 體重有變更時，同步到 body_data
        if (weight != null && weight != oldWeight && _userProfile != null) {
          await _syncWeightToBodyData(
            userId: _userProfile!.uid,
            weight: weight,
            height: height ?? _userProfile!.height,
          );
        }
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
  
  /// ⭐ v3.5: 同步體重到 body_data 表
  /// 
  /// 邏輯：
  /// - 如果當天已有記錄：更新現有記錄
  /// - 如果當天無記錄：新增記錄
  Future<void> _syncWeightToBodyData({
    required String userId,
    required double weight,
    double? height,
  }) async {
    try {
      debugPrint('[PROFILE_CONTROLLER] 📊 同步體重到 body_data: $weight kg');
      
      final today = DateTime.now();
      final existingRecord = await _bodyDataService.getRecordByDate(userId, today);
      
      if (existingRecord != null) {
        // 當天已有記錄：更新
        debugPrint('[PROFILE_CONTROLLER] 更新當天 body_data 記錄: ${existingRecord.id}');
        final updatedRecord = existingRecord.copyWith(
          weight: weight,
          bmi: height != null ? BodyDataRecord.calculateBMI(weight, height) : existingRecord.bmi,
        );
        await _bodyDataService.updateRecord(updatedRecord);
      } else {
        // 當天無記錄：新增
        debugPrint('[PROFILE_CONTROLLER] 新增 body_data 記錄');
        final newRecord = BodyDataOperationHelper.createRecord(
          userId: userId,
          recordDate: today,
          weight: weight,
          heightCm: height,
        );
        await _bodyDataService.createRecord(newRecord);
      }
      
      debugPrint('[PROFILE_CONTROLLER] ✅ 體重同步完成');
      
      // ⭐ v3.5: 發布身體數據更新事件（觸發身體數據頁面、統計頁面自動刷新）
      _eventBusController.publishBodyDataUpdated(userId: userId);
    } catch (e) {
      // 同步失敗不影響主流程，只記錄錯誤
      debugPrint('[PROFILE_CONTROLLER] ⚠️ 同步體重到 body_data 失敗: $e');
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

  // =========================================================================
  // ⭐ v3.5: 健康評估（MVVM 重構）
  // Controller 內部獲取 Service，View 不需要知道 Service 的存在
  // =========================================================================

  /// 創建健康評估
  Future<bool> createHealthAssessment(
    HealthAssessmentModel assessment, {
    bool setAsCurrent = true,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final healthService = serviceLocator<IHealthAssessmentService>();
      await healthService.createAssessment(assessment, setAsCurrent: setAsCurrent);

      // ⭐ 發布健康評估更新事件
      _eventBusController.publish(AppEvent(
        type: AppEventType.healthAssessmentUpdated,
        entityId: assessment.id,
        userId: assessment.userId,
        timestamp: DateTime.now(),
      ));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '建立健康評估失敗: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 更新健康評估
  Future<bool> updateHealthAssessment(HealthAssessmentModel assessment) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final healthService = serviceLocator<IHealthAssessmentService>();
      await healthService.updateAssessment(assessment);

      // ⭐ 發布健康評估更新事件
      _eventBusController.publish(AppEvent(
        type: AppEventType.healthAssessmentUpdated,
        entityId: assessment.id,
        userId: assessment.userId,
        timestamp: DateTime.now(),
      ));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '更新健康評估失敗: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 刪除傷病備註
  Future<bool> deleteInjuryNote({
    required String coachId,
    required String clientId,
    required String injurySite,
  }) async {
    try {
      final injuryNoteService = serviceLocator<IInjuryCoachNoteService>();
      await injuryNoteService.deleteNote(
        coachId: coachId,
        clientId: clientId,
        injurySite: injurySite,
      );
      return true;
    } catch (e) {
      _errorMessage = '刪除備註失敗: $e';
      notifyListeners();
      return false;
    }
  }

  /// 新增或更新傷病備註
  Future<bool> upsertInjuryNote({
    required String coachId,
    required String clientId,
    required String injurySite,
    required String note,
  }) async {
    try {
      final injuryNoteService = serviceLocator<IInjuryCoachNoteService>();
      await injuryNoteService.upsertNote(
        coachId: coachId,
        clientId: clientId,
        injurySite: injurySite,
        note: note,
      );
      return true;
    } catch (e) {
      _errorMessage = '儲存備註失敗: $e';
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // ⭐ MVVM 重構：查詢方法（直接返回結果，不更新 Controller 狀態）
  // ============================================================================

  /// 取得學員的所有傷病教練備註
  /// ⭐ v3.6 MVVM 重構：View 層透過 Controller 查詢
  ///
  /// [clientId] 學員 ID
  /// 返回 Map<injurySite, List<InjuryCoachNoteModel>>
  Future<Map<String, List<InjuryCoachNoteModel>>> getInjuryCoachNotes(
    String clientId,
  ) async {
    try {
      final injuryNoteService = serviceLocator<IInjuryCoachNoteService>();
      return await injuryNoteService.getNotesForClient(clientId: clientId);
    } catch (e) {
      debugPrint('[PROFILE_CONTROLLER] ⚠️ 查詢傷病備註失敗: $clientId, $e');
      return {};
    }
  }

  /// 查詢指定用戶的個人資料
  ///
  /// 用於查詢教練或學員的資料，不影響 Controller 內部狀態
  ///
  /// [userId] 用戶 ID
  /// 返回 UserModel 或 null
  Future<UserModel?> getUserProfileById(String userId) async {
    try {
      return await _userService.getUserProfile(userId);
    } catch (e) {
      debugPrint('[PROFILE_CONTROLLER] ⚠️ 查詢用戶資料失敗: $userId, $e');
      return null;
    }
  }

  /// 取得學員當前有效的健康評估
  /// ⭐ v3.6 MVVM 重構
  Future<HealthAssessmentModel?> getCurrentHealthAssessment(String userId) async {
    try {
      final healthService = serviceLocator<IHealthAssessmentService>();
      return await healthService.getCurrentAssessment(userId);
    } catch (e) {
      debugPrint('[PROFILE_CONTROLLER] ⚠️ 查詢健康評估失敗: $userId, $e');
      return null;
    }
  }

  /// 取得教練對健康評估的備註
  /// ⭐ v3.6 MVVM 重構
  Future<CoachAssessmentNoteModel?> getCoachAssessmentNote({
    required String coachId,
    required String assessmentId,
  }) async {
    try {
      final noteService = serviceLocator<ICoachAssessmentNoteService>();
      return await noteService.getNote(
        coachId: coachId,
        assessmentId: assessmentId,
      );
    } catch (e) {
      debugPrint('[PROFILE_CONTROLLER] ⚠️ 查詢教練評估備註失敗: $e');
      return null;
    }
  }

  /// 新增或更新教練對健康評估的備註
  /// ⭐ v3.6 MVVM 重構
  Future<CoachAssessmentNoteModel?> upsertCoachAssessmentNote({
    required String coachId,
    required String assessmentId,
    required String notes,
  }) async {
    try {
      final noteService = serviceLocator<ICoachAssessmentNoteService>();
      return await noteService.upsertNote(
        coachId: coachId,
        assessmentId: assessmentId,
        notes: notes,
      );
    } catch (e) {
      debugPrint('[PROFILE_CONTROLLER] ⚠️ 儲存教練評估備註失敗: $e');
      return null;
    }
  }
}

