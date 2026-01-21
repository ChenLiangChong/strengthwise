import 'package:flutter/foundation.dart';
import 'package:strengthwise/models/coach_profile/coach_profile_model.dart';
import 'package:strengthwise/models/coach_profile/certification_model.dart';
import 'package:strengthwise/models/coach_display_preferences_model.dart'; // ⭐ v3.5: MVVM
import 'package:strengthwise/services/interfaces/i_coach_profile_service.dart';
import 'package:strengthwise/services/interfaces/i_coach_display_preferences_service.dart'; // ⭐ v3.5: MVVM
import 'package:strengthwise/services/interfaces/i_auth_service.dart';
import 'package:strengthwise/services/service_locator.dart'; // ⭐ v3.5: MVVM
import 'interfaces/i_coach_profile_controller.dart';

/// 教練公開檔案控制器
///
/// 負責管理教練檔案的業務邏輯與狀態
class CoachProfileController extends ChangeNotifier implements ICoachProfileController {
  final ICoachProfileService _profileService;
  final IAuthService _authService;

  CoachProfileController({
    required ICoachProfileService profileService,
    required IAuthService authService,
  })  : _profileService = profileService,
        _authService = authService;

  // ==================== 狀態 ====================

  CoachProfileModel? _profile;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _hasProfile = false;

  // 表單編輯狀態
  String _displayName = '';
  String _headline = '';
  String _bio = '';
  List<String> _specialties = [];
  List<CertificationModel> _certifications = [];
  int _yearsExperience = 0;
  List<String> _languages = ['zh-TW'];

  // ==================== Getters ====================

  @override
  CoachProfileModel? get profile => _profile;
  @override
  bool get isLoading => _isLoading;
  @override
  bool get isSaving => _isSaving;
  @override
  String? get errorMessage => _errorMessage;
  @override
  bool get hasProfile => _hasProfile;

  // 表單狀態
  @override
  String get displayName => _displayName;
  @override
  String get headline => _headline;
  @override
  String get bio => _bio;
  @override
  List<String> get specialties => _specialties;
  @override
  List<CertificationModel> get certifications => _certifications;
  @override
  int get yearsExperience => _yearsExperience;
  @override
  List<String> get languages => _languages;

  /// 當前用戶 ID
  @override
  String? get currentUserId {
    final user = _authService.getCurrentUser();
    return user?['uid'] as String?;  // AuthService 使用 'uid' 不是 'id'
  }

  /// 當前用戶 Email
  @override
  String? get currentUserEmail {
    final user = _authService.getCurrentUser();
    return user?['email'] as String?;
  }

  /// 表單是否有效（可提交）
  @override
  bool get isFormValid {
    return _displayName.isNotEmpty &&
        _bio.isNotEmpty &&
        _specialties.isNotEmpty;
  }

  /// 表單是否有變更
  @override
  bool get hasChanges {
    if (_profile == null) return true;
    
    return _displayName != (_profile?.displayName ?? '') ||
        _headline != (_profile?.headline ?? '') ||
        _bio != (_profile?.bio ?? '') ||
        !_listEquals(_specialties, _profile?.specialties ?? []) ||
        !_certificationsEquals(_certifications, _profile?.certifications ?? []) ||
        _yearsExperience != (_profile?.yearsExperience ?? 0) ||
        !_listEquals(_languages, _profile?.languages ?? ['zh-TW']);
  }

  // ==================== 載入 ====================

  /// 載入教練檔案
  /// 
  /// 如果 [coachId] 為 null，則載入當前登入用戶的檔案
  /// 如果 [coachId] 有值，則載入指定教練的檔案（學員查看模式）
  @override
  Future<void> loadCoachProfile({String? coachId}) async {
    final targetId = coachId ?? currentUserId;
    if (targetId == null) {
      _errorMessage = '請先登入';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _profileService.getProfile(targetId);
      _hasProfile = _profile != null;

      if (_profile != null) {
        _initFormFromProfile(_profile!);
      } else {
        _initEmptyForm();
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = '載入教練檔案失敗: $e';
      debugPrint('[COACH_PROFILE_CONTROLLER] ❌ $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 從現有檔案初始化表單
  void _initFormFromProfile(CoachProfileModel profile) {
    _displayName = profile.displayName ?? '';
    _headline = profile.headline ?? '';
    _bio = profile.bio ?? '';
    _specialties = List.from(profile.specialties);
    _certifications = List.from(profile.certifications);
    _yearsExperience = profile.yearsExperience;
    _languages = List.from(profile.languages);
  }

  /// 初始化空白表單
  void _initEmptyForm() {
    _displayName = '';
    _headline = '';
    _bio = '';
    _specialties = [];
    _certifications = [];
    _yearsExperience = 0;
    _languages = ['zh-TW'];
  }

  // ==================== 表單更新 ====================

  /// 更新顯示名稱
  @override
  void setDisplayName(String value) {
    _displayName = value;
    notifyListeners();
  }

  /// 更新專業頭銜
  @override
  void setHeadline(String value) {
    _headline = value;
    notifyListeners();
  }

  /// 更新專業介紹
  @override
  void setBio(String value) {
    _bio = value;
    notifyListeners();
  }

  /// 更新年資
  @override
  void setYearsExperience(int value) {
    _yearsExperience = value;
    notifyListeners();
  }

  // ==================== 專長標籤 ====================

  /// 新增專長標籤
  @override
  void addSpecialty(String specialty) {
    if (!_specialties.contains(specialty) && _specialties.length < 8) {
      _specialties = [..._specialties, specialty];
      notifyListeners();
    }
  }

  /// 移除專長標籤
  @override
  void removeSpecialty(String specialty) {
    _specialties = _specialties.where((s) => s != specialty).toList();
    notifyListeners();
  }

  /// 新增自定義專長標籤
  @override
  void addCustomSpecialty(String label) {
    final customValue = 'custom:$label';
    addSpecialty(customValue);
  }

  // ==================== 證照 ====================

  /// 新增證照
  @override
  void addCertification(CertificationModel cert) {
    _certifications = [..._certifications, cert];
    notifyListeners();
  }

  /// 移除證照
  @override
  void removeCertification(int index) {
    if (index >= 0 && index < _certifications.length) {
      _certifications = List.from(_certifications)..removeAt(index);
      notifyListeners();
    }
  }

  /// 更新證照
  @override
  void updateCertification(int index, CertificationModel cert) {
    if (index >= 0 && index < _certifications.length) {
      _certifications = List.from(_certifications)..[index] = cert;
      notifyListeners();
    }
  }

  // ==================== 語言 ====================

  /// 新增語言
  @override
  void addLanguage(String language) {
    if (!_languages.contains(language)) {
      _languages = [..._languages, language];
      notifyListeners();
    }
  }

  /// 移除語言
  @override
  void removeLanguage(String language) {
    if (_languages.length > 1) {
      _languages = _languages.where((l) => l != language).toList();
      notifyListeners();
    }
  }

  // ==================== 儲存 ====================

  /// 儲存教練檔案
  @override
  Future<bool> saveProfile() async {
    final userId = currentUserId;
    if (userId == null) {
      _errorMessage = '請先登入';
      notifyListeners();
      return false;
    }

    if (!isFormValid) {
      _errorMessage = '請填寫必填欄位（顯示名稱、專業介紹、至少一個專長）';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newProfile = CoachProfileModel(
        id: userId,
        displayName: _displayName,
        headline: _headline.isNotEmpty ? _headline : null,
        bio: _bio,
        specialties: _specialties,
        certifications: _certifications,
        yearsExperience: _yearsExperience,
        languages: _languages,
      );

      _profile = await _profileService.upsertProfile(newProfile);
      _hasProfile = true;
      _errorMessage = null;
      
      debugPrint('[COACH_PROFILE_CONTROLLER] ✅ 教練檔案儲存成功');
      return true;
    } catch (e) {
      _errorMessage = '儲存教練檔案失敗: $e';
      debugPrint('[COACH_PROFILE_CONTROLLER] ❌ $_errorMessage');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ==================== 輔助方法 ====================

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _certificationsEquals(List<CertificationModel> a, List<CertificationModel> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 清除錯誤訊息
  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 重置表單
  @override
  void resetForm() {
    if (_profile != null) {
      _initFormFromProfile(_profile!);
    } else {
      _initEmptyForm();
    }
    notifyListeners();
  }

  // =========================================================================
  // ⭐ v3.5: 教練顯示偏好設定（MVVM 重構）
  // Controller 內部獲取 Service，View 不需要知道 Service 的存在
  // =========================================================================

  /// 更新教練顯示偏好設定
  @override
  Future<bool> updateDisplayPreferences(
    CoachDisplayPreferencesModel preferences,
  ) async {
    try {
      _isSaving = true;
      _errorMessage = null;
      notifyListeners();

      final preferencesService = serviceLocator<ICoachDisplayPreferencesService>();
      await preferencesService.updatePreferences(preferences);

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '儲存設定失敗: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // ⭐ v3.6 MVVM 重構：純查詢方法（不更新 Controller 狀態）
  // ============================================================================

  /// 查詢指定教練的公開檔案
  ///
  /// 用於純展示場景，不影響 Controller 內部狀態
  ///
  /// [coachId] 教練 ID
  /// 返回 CoachProfileModel 或 null
  @override
  Future<CoachProfileModel?> getCoachProfileById(String coachId) async {
    try {
      return await _profileService.getProfile(coachId);
    } catch (e) {
      debugPrint('[COACH_PROFILE_CONTROLLER] ⚠️ 查詢教練檔案失敗: $coachId, $e');
      return null;
    }
  }

  /// 取得教練的顯示偏好設定
  /// ⭐ v3.6 MVVM 重構
  @override
  Future<CoachDisplayPreferencesModel?> getDisplayPreferences(String coachId) async {
    try {
      final preferencesService = serviceLocator<ICoachDisplayPreferencesService>();
      return await preferencesService.getPreferences(coachId);
    } catch (e) {
      debugPrint('[COACH_PROFILE_CONTROLLER] ⚠️ 查詢顯示偏好失敗: $coachId, $e');
      return null;
    }
  }

  /// 重置顯示偏好為預設值
  /// ⭐ v3.6 MVVM 重構
  @override
  Future<bool> resetDisplayPreferences(String coachId) async {
    try {
      final preferencesService = serviceLocator<ICoachDisplayPreferencesService>();
      await preferencesService.resetToDefault(coachId);
      return true;
    } catch (e) {
      debugPrint('[COACH_PROFILE_CONTROLLER] ⚠️ 重置顯示偏好失敗: $coachId, $e');
      return false;
    }
  }
}

