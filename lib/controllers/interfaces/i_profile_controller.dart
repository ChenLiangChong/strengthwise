import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/user/user_model.dart';
import '../../models/health_assessment_models.dart';
import '../../models/injury_coach_note_model.dart';
import '../../models/coach_assessment_note_model.dart';

/// Profile 控制器接口
///
/// 定義與用戶個人資料相關的業務邏輯操作。
/// ⭐ v4.0: 架構優化 - 補充 Interface 以支援 Mock 測試
abstract class IProfileController extends ChangeNotifier {
  // ==================== 狀態 Getters ====================

  /// 當前用戶資料
  UserModel? get userProfile;

  /// 載入中狀態
  bool get isLoading;

  /// 錯誤訊息
  String? get errorMessage;

  /// 是否為 OAuth 登入用戶
  bool get isOAuthUser;

  /// 是否已設置密碼
  bool get hasPassword;

  /// 用戶 Email
  String get userEmail;

  // ==================== 狀態管理方法 ====================

  /// 載入當前用戶的個人資料
  Future<void> loadUserProfile();

  /// 直接返回當前用戶資料（純查詢方法）
  Future<UserModel?> getCurrentUserProfile();

  /// 查詢指定用戶的個人資料
  Future<UserModel?> getUserProfileById(String userId);

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
  });

  /// 切換教練模式
  Future<bool> toggleCoachRole(bool isCoach);

  /// 為 OAuth 用戶設置密碼
  Future<bool> setPasswordForOAuthUser(String newPassword);

  /// 登出
  Future<void> signOut();

  /// 檢查個人資料是否完整
  bool isProfileCompleted();

  /// 清除錯誤訊息
  void clearError();

  // ==================== 健康評估相關 ====================

  /// 創建健康評估
  Future<bool> createHealthAssessment(
    HealthAssessmentModel assessment, {
    bool setAsCurrent = true,
  });

  /// 更新健康評估
  Future<bool> updateHealthAssessment(HealthAssessmentModel assessment);

  /// 取得學員當前有效的健康評估
  Future<HealthAssessmentModel?> getCurrentHealthAssessment(String userId);

  // ==================== 傷病備註相關 ====================

  /// 刪除傷病備註
  Future<bool> deleteInjuryNote({
    required String coachId,
    required String clientId,
    required String injurySite,
  });

  /// 新增或更新傷病備註
  Future<bool> upsertInjuryNote({
    required String coachId,
    required String clientId,
    required String injurySite,
    required String note,
  });

  /// 取得學員的所有傷病教練備註
  Future<Map<String, List<InjuryCoachNoteModel>>> getInjuryCoachNotes(
    String clientId,
  );

  // ==================== 教練評估備註 ====================

  /// 取得教練對健康評估的備註
  Future<CoachAssessmentNoteModel?> getCoachAssessmentNote({
    required String coachId,
    required String assessmentId,
  });

  /// 新增或更新教練對健康評估的備註
  Future<CoachAssessmentNoteModel?> upsertCoachAssessmentNote({
    required String coachId,
    required String assessmentId,
    required String notes,
  });
}
