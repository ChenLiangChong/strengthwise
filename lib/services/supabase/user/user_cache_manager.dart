import 'package:flutter/foundation.dart';
import '../../../models/user_model.dart';

/// 用戶資料快取管理器
/// 
/// 負責用戶資料的快取和驗證
class UserCacheManager {
  // 快取資料
  UserModel? _userProfileCache;
  DateTime? _userProfileCacheTime;
  String? _cachedUserId;
  
  // 快取有效期（分鐘）
  int _cacheValidityMinutes = 5;
  
  /// 配置快取有效期
  void configure(int validityMinutes) {
    _cacheValidityMinutes = validityMinutes;
  }
  
  /// 檢查快取是否有效
  bool isCacheValid(String userId) {
    if (_userProfileCache == null || 
        _cachedUserId != userId ||
        _userProfileCacheTime == null) {
      return false;
    }
    
    final cacheAge = DateTime.now().difference(_userProfileCacheTime!);
    return cacheAge.inMinutes < _cacheValidityMinutes;
  }
  
  /// 獲取快取的用戶資料
  UserModel? getCachedProfile(String userId) {
    if (!isCacheValid(userId)) {
      return null;
    }
    
    final cacheAge = DateTime.now().difference(_userProfileCacheTime!);
    _logDebug('⚡ 從快取返回用戶資料（${cacheAge.inSeconds}秒前）');
    return _userProfileCache;
  }
  
  /// 更新快取
  void updateCache(String userId, UserModel profile) {
    _userProfileCache = profile;
    _userProfileCacheTime = DateTime.now();
    _cachedUserId = userId;
    _logDebug('⚡ 已快取用戶資料（$_cacheValidityMinutes 分鐘有效）');
  }
  
  /// 清除快取
  void clearCache() {
    _userProfileCache = null;
    _userProfileCacheTime = null;
    _cachedUserId = null;
    _logDebug('⚡ 已清除用戶資料快取');
  }
  
  /// 釋放資源
  void dispose() {
    clearCache();
  }
  
  /// 偵錯日誌
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[USER_CACHE_MANAGER] $message');
    }
  }
}

