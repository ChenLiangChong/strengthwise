import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import '../models/user_model.dart';
import 'interfaces/i_user_service.dart';
import 'error_handling_service.dart';
import 'service_locator.dart' show Environment;

/// 用戶服務的Firebase實現
/// 
/// 提供用戶資料管理、資料更新和角色管理等功能
/// 支持環境配置，統一錯誤處理與資源管理
class UserService implements IUserService {
  // 依賴注入
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final ErrorHandlingService _errorService;
  
  // 服務狀態
  bool _isInitialized = false;
  Environment _environment = Environment.development;
  
  // 服務配置
  bool _autoCreateProfile = true;
  bool _cacheUserProfiles = true;
  
  // 用戶資料緩存
  final Map<String, UserModel> _userCache = {};
  Timer? _cacheClearTimer;
  
  /// 創建服務實例
  /// 
  /// 允許注入自定義的Firestore、Auth和Storage實例，便於測試
  UserService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    ErrorHandlingService? errorService,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _auth = auth ?? FirebaseAuth.instance,
    _storage = storage ?? FirebaseStorage.instance,
    _errorService = errorService ?? ErrorHandlingService();
  
  /// 初始化服務
  /// 
  /// 設置環境配置並初始化緩存系統
  Future<void> initialize({Environment environment = Environment.development}) async {
    if (_isInitialized) return;
    
    try {
      // 設置環境
      configureForEnvironment(environment);
      
      // 設置緩存清理計時器（每小時）
      if (_cacheUserProfiles) {
        _setupCacheCleanupTimer();
      }
      
      _isInitialized = true;
      _logDebug('用戶服務初始化完成');
    } catch (e) {
      _logError('用戶服務初始化失敗: $e');
      rethrow;
    }
  }
  
  /// 釋放資源
  Future<void> dispose() async {
    try {
      // 取消緩存清理計時器
      _cacheClearTimer?.cancel();
      _cacheClearTimer = null;
      
      // 清空緩存
      _userCache.clear();
      
      // 其他資源清理
      _isInitialized = false;
      _logDebug('用戶服務資源已釋放');
    } catch (e) {
      _logError('釋放用戶服務資源時發生錯誤: $e');
    }
  }
  
  /// 根據環境配置服務
  void configureForEnvironment(Environment environment) {
    _environment = environment;
    
    switch (environment) {
      case Environment.development:
        // 開發環境設置
        _autoCreateProfile = true;
        _cacheUserProfiles = true;
        _logDebug('用戶服務配置為開發環境');
        break;
      case Environment.testing:
        // 測試環境設置
        _autoCreateProfile = false;
        _cacheUserProfiles = false;
        _logDebug('用戶服務配置為測試環境');
        break;
      case Environment.production:
        // 生產環境設置
        _autoCreateProfile = true;
        _cacheUserProfiles = true;
        _logDebug('用戶服務配置為生產環境');
        break;
    }
  }
  
  /// 設置緩存清理計時器
  void _setupCacheCleanupTimer() {
    _cacheClearTimer?.cancel();
    // 每小時清理一次緩存
    _cacheClearTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _clearCache();
    });
  }
  
  /// 清除緩存
  void _clearCache() {
    _logDebug('清理用戶資料緩存');
    _userCache.clear();
  }
  
  @override
  Future<bool> isProfileCompleted() async {
    _ensureInitialized();
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;
      
      final userData = doc.data();
      if (userData == null) return false;
      
      // 检查必填字段是否已填写
      return userData['nickname'] != null && 
             userData['gender'] != null;
    } catch (e) {
      _logError('檢查用戶資料出錯: $e');
      return false;
    }
  }
  
  @override
  Future<UserModel?> getCurrentUserProfile() async {
    _ensureInitialized();
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logDebug('獲取用戶資料：沒有登入用戶');
        return null;
      }
      
      // 檢查緩存
      if (_cacheUserProfiles && _userCache.containsKey(user.uid)) {
        _logDebug('從緩存獲取用戶資料: ${user.uid}');
        return _userCache[user.uid];
      }
      
      _logDebug('從Firestore獲取用戶資料: ${user.uid}');
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        if (_autoCreateProfile) {
          _logDebug('自動創建基本用戶資料: ${user.uid}');
          // 如果在 Firestore 中没有用户数据，创建一个基本记录
          final basicUserData = {
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'isCoach': false,
            'isStudent': true,
            'profileCreatedAt': FieldValue.serverTimestamp(),
          };
          
          await _firestore.collection('users').doc(user.uid).set(basicUserData);
          
          final newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            photoURL: user.photoURL,
            isCoach: false,
            isStudent: true,
          );
          
          // 保存到緩存
          if (_cacheUserProfiles) {
            _userCache[user.uid] = newUser;
          }
          
          return newUser;
        } else {
          _logDebug('用戶資料不存在且未開啟自動創建: ${user.uid}');
          return null;
        }
      }
      
      final userData = doc.data()!;
      final userModel = UserModel.fromMap({...userData, 'uid': user.uid});
      
      // 保存到緩存
      if (_cacheUserProfiles) {
        _userCache[user.uid] = userModel;
      }
      
      return userModel;
    } catch (e) {
      _logError('獲取用戶資料出錯: $e');
      return null;
    }
  }
  
  @override
  Future<bool> updateUserProfile({
    String? displayName,
    String? nickname,
    String? gender,
    double? height,
    double? weight,
    int? age,
    bool? isCoach,
    bool? isStudent,
    File? avatarFile,
  }) async {
    _ensureInitialized();
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logError('更新用戶資料：沒有登入用戶');
        return false;
      }
      
      _logDebug('開始更新用戶資料: ${user.uid}');
      
      // 获取当前用户数据
      final currentProfile = await getCurrentUserProfile();
      if (currentProfile == null) {
        _logError('無法獲取當前用戶資料進行更新');
        return false;
      }
      
      // 处理头像上传
      String? photoURL = currentProfile.photoURL;
      if (avatarFile != null) {
        try {
          _logDebug('上傳用戶頭像');
          final storageRef = _storage.ref().child('user_avatars/${user.uid}');
          final uploadTask = storageRef.putFile(avatarFile);
          final snapshot = await uploadTask;
          photoURL = await snapshot.ref.getDownloadURL();
          
          // 更新 Firebase Auth 中的用户资料
          await user.updatePhotoURL(photoURL);
          _logDebug('頭像上傳完成: $photoURL');
        } catch (e) {
          _logError('頭像上傳失敗: $e');
          // 繼續執行其他更新，不因為頭像上傳失敗而中斷整個流程
        }
      }
      
      // 更新显示名称，使用 try-catch 隔離 Firebase Auth 操作
      if (displayName != null && displayName.isNotEmpty) {
        try {
          _logDebug('更新顯示名稱: $displayName');
          await user.updateDisplayName(displayName);
        } catch (e) {
          _logError('更新顯示名稱失敗: $e');
          // 繼續執行其他更新，不因為更新顯示名稱失敗而中斷整個流程
        }
      }
      
      // 创建更新后的用户模型，避免使用 copyWith 來減少轉換問題
      final Map<String, dynamic> updatedUserData = {
        'displayName': displayName ?? currentProfile.displayName,
        'photoURL': photoURL,
        'nickname': nickname ?? currentProfile.nickname,
        'gender': gender ?? currentProfile.gender,
        'height': height ?? currentProfile.height,
        'weight': weight ?? currentProfile.weight,
        'age': age ?? currentProfile.age,
        'isCoach': isCoach ?? currentProfile.isCoach,
        'isStudent': isStudent ?? currentProfile.isStudent,
        'email': currentProfile.email,
        'profileUpdatedAt': FieldValue.serverTimestamp(),
      };
      
      // 如果是首次更新，添加创建时间
      if (currentProfile.profileCreatedAt == null) {
        updatedUserData['profileCreatedAt'] = FieldValue.serverTimestamp();
      }
      
      // 保存到 Firestore
      await _firestore.collection('users').doc(user.uid).set(updatedUserData, SetOptions(merge: true));
      
      // 更新緩存
      if (_cacheUserProfiles) {
        // 從 Firestore 中重新獲取最新數據，避免類型轉換問題
        final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
        if (docSnapshot.exists) {
          final userData = docSnapshot.data()!;
          final updatedProfile = UserModel.fromMap({...userData, 'uid': user.uid});
          _userCache[user.uid] = updatedProfile;
        }
      } else {
        // 如果不使用緩存，清除舊有緩存
        _userCache.remove(user.uid);
      }
      
      _logDebug('用戶資料更新完成: ${user.uid}');
      return true;
    } catch (e) {
      _logError('更新用戶資料出錯: $e');
      return false;
    }
  }
  
  @override
  Future<bool> toggleUserRole(bool isCoach) async {
    _ensureInitialized();
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logError('切換用戶角色：沒有登入用戶');
        return false;
      }
      
      _logDebug('切換用戶角色 - isCoach: $isCoach');
      await _firestore.collection('users').doc(user.uid).update({
        'isCoach': isCoach,
        'profileUpdatedAt': FieldValue.serverTimestamp(),
      });
      
      // 更新緩存
      if (_cacheUserProfiles && _userCache.containsKey(user.uid)) {
        final updatedUser = _userCache[user.uid]!.copyWith(isCoach: isCoach);
        _userCache[user.uid] = updatedUser;
      }
      
      _logDebug('用戶角色切換完成');
      return true;
    } catch (e) {
      _logError('切換用戶角色出錯: $e');
      return false;
    }
  }
  
  /// 確保服務已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      _logDebug('警告: 用戶服務在初始化前被調用');
      // 在開發環境中自動初始化，但在其他環境拋出錯誤
      if (_environment == Environment.development) {
        initialize();
      } else {
        throw StateError('用戶服務未初始化');
      }
    }
  }
  
  /// 記錄調試信息
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[USER] $message');
    }
  }
  
  /// 記錄錯誤信息
  void _logError(String message) {
    // 首先記錄到控制台（僅在調試模式）
    if (kDebugMode) {
      print('[USER ERROR] $message');
    }
    
    // 使用錯誤處理服務記錄錯誤
    _errorService.logError(message);
  }
} 