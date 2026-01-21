import 'package:flutter/foundation.dart';
import '../../models/coach_profile/coach_profile_model.dart';
import '../../models/coach_profile/certification_model.dart';
import '../../models/coach_display_preferences_model.dart';

/// 教練公開檔案控制器接口
///
/// 負責管理教練檔案的業務邏輯與狀態
abstract class ICoachProfileController extends ChangeNotifier {
  // ==================== 狀態 Getters ====================

  /// 教練檔案
  CoachProfileModel? get profile;

  /// 載入中狀態
  bool get isLoading;

  /// 儲存中狀態
  bool get isSaving;

  /// 錯誤訊息
  String? get errorMessage;

  /// 是否已有檔案
  bool get hasProfile;

  // 表單狀態
  String get displayName;
  String get headline;
  String get bio;
  List<String> get specialties;
  List<CertificationModel> get certifications;
  int get yearsExperience;
  List<String> get languages;

  // 衍生狀態
  String? get currentUserId;
  String? get currentUserEmail;
  bool get isFormValid;
  bool get hasChanges;

  // ==================== 載入功能 ====================

  /// 載入教練檔案
  Future<void> loadCoachProfile({String? coachId});

  /// 重置表單
  void resetForm();

  // ==================== 表單更新 ====================

  void setDisplayName(String value);
  void setHeadline(String value);
  void setBio(String value);
  void setYearsExperience(int value);

  // ==================== 專長標籤管理 ====================

  void addSpecialty(String specialty);
  void removeSpecialty(String specialty);
  void addCustomSpecialty(String label);

  // ==================== 證照管理 ====================

  void addCertification(CertificationModel cert);
  void removeCertification(int index);
  void updateCertification(int index, CertificationModel cert);

  // ==================== 語言管理 ====================

  void addLanguage(String language);
  void removeLanguage(String language);

  // ==================== 儲存功能 ====================

  /// 儲存教練檔案
  Future<bool> saveProfile();

  /// 清除錯誤訊息
  void clearError();

  // ==================== MVVM 查詢方法 ====================

  /// 查詢指定教練的公開檔案
  Future<CoachProfileModel?> getCoachProfileById(String coachId);

  /// 取得教練的顯示偏好設定
  Future<CoachDisplayPreferencesModel?> getDisplayPreferences(String coachId);

  /// 更新教練顯示偏好設定
  Future<bool> updateDisplayPreferences(CoachDisplayPreferencesModel preferences);

  /// 重置顯示偏好為預設值
  Future<bool> resetDisplayPreferences(String coachId);
}
