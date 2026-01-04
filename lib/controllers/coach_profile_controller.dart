import 'package:flutter/foundation.dart';
import 'package:strengthwise/models/coach_profile/coach_profile_model.dart';
import 'package:strengthwise/models/coach_profile/certification_model.dart';
import 'package:strengthwise/services/interfaces/i_coach_profile_service.dart';
import 'package:strengthwise/services/interfaces/i_auth_service.dart';

/// 教練公開檔案控制器
/// 
/// 負責管理教練檔案的業務邏輯與狀態
class CoachProfileController extends ChangeNotifier {
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

  CoachProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get hasProfile => _hasProfile;

  // 表單狀態
  String get displayName => _displayName;
  String get headline => _headline;
  String get bio => _bio;
  List<String> get specialties => _specialties;
  List<CertificationModel> get certifications => _certifications;
  int get yearsExperience => _yearsExperience;
  List<String> get languages => _languages;

  /// 當前用戶 ID
  String? get currentUserId {
    final user = _authService.getCurrentUser();
    return user?['uid'] as String?;  // AuthService 使用 'uid' 不是 'id'
  }

  /// 當前用戶 Email
  String? get currentUserEmail {
    final user = _authService.getCurrentUser();
    return user?['email'] as String?;
  }

  /// 表單是否有效（可提交）
  bool get isFormValid {
    return _displayName.isNotEmpty &&
        _bio.isNotEmpty &&
        _specialties.isNotEmpty;
  }

  /// 表單是否有變更
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
  void setDisplayName(String value) {
    _displayName = value;
    notifyListeners();
  }

  /// 更新專業頭銜
  void setHeadline(String value) {
    _headline = value;
    notifyListeners();
  }

  /// 更新專業介紹
  void setBio(String value) {
    _bio = value;
    notifyListeners();
  }

  /// 更新年資
  void setYearsExperience(int value) {
    _yearsExperience = value;
    notifyListeners();
  }

  // ==================== 專長標籤 ====================

  /// 新增專長標籤
  void addSpecialty(String specialty) {
    if (!_specialties.contains(specialty) && _specialties.length < 8) {
      _specialties = [..._specialties, specialty];
      notifyListeners();
    }
  }

  /// 移除專長標籤
  void removeSpecialty(String specialty) {
    _specialties = _specialties.where((s) => s != specialty).toList();
    notifyListeners();
  }

  /// 新增自定義專長標籤
  void addCustomSpecialty(String label) {
    final customValue = 'custom:$label';
    addSpecialty(customValue);
  }

  // ==================== 證照 ====================

  /// 新增證照
  void addCertification(CertificationModel cert) {
    _certifications = [..._certifications, cert];
    notifyListeners();
  }

  /// 移除證照
  void removeCertification(int index) {
    if (index >= 0 && index < _certifications.length) {
      _certifications = List.from(_certifications)..removeAt(index);
      notifyListeners();
    }
  }

  /// 更新證照
  void updateCertification(int index, CertificationModel cert) {
    if (index >= 0 && index < _certifications.length) {
      _certifications = List.from(_certifications)..[index] = cert;
      notifyListeners();
    }
  }

  // ==================== 語言 ====================

  /// 新增語言
  void addLanguage(String language) {
    if (!_languages.contains(language)) {
      _languages = [..._languages, language];
      notifyListeners();
    }
  }

  /// 移除語言
  void removeLanguage(String language) {
    if (_languages.length > 1) {
      _languages = _languages.where((l) => l != language).toList();
      notifyListeners();
    }
  }

  // ==================== 儲存 ====================

  /// 儲存教練檔案
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
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 重置表單
  void resetForm() {
    if (_profile != null) {
      _initFormFromProfile(_profile!);
    } else {
      _initEmptyForm();
    }
    notifyListeners();
  }
}

