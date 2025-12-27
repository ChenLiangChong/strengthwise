import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../models/favorite_exercise_model.dart';
import '../interfaces/i_favorites_service.dart';
import '../core/error_handling_service.dart';

/// 收藏服務實作
/// 
/// 使用 SharedPreferences 進行本地持久化儲存
/// 數據格式：{userId}_favorites = List<Map<String, dynamic>>
class FavoritesService implements IFavoritesService {
  // 依賴注入
  final ErrorHandlingService _errorService;
  
  // SharedPreferences 實例
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// 創建服務實例
  FavoritesService({
    ErrorHandlingService? errorService,
  }) : _errorService = errorService ?? ErrorHandlingService();

  /// 初始化服務
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      _logDebug('收藏服務初始化完成');
    } catch (e) {
      _logError('收藏服務初始化失敗: $e');
      rethrow;
    }
  }

  /// 確保服務已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// 獲取使用者收藏的 key
  String _getFavoritesKey(String userId) => '${userId}_favorites';

  @override
  Future<List<String>> getFavoriteExerciseIds(String userId) async {
    await _ensureInitialized();
    
    try {
      final key = _getFavoritesKey(userId);
      final jsonString = _prefs!.getString(key);
      
      if (jsonString == null) {
        _logDebug('使用者 $userId 沒有收藏記錄');
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(jsonString);
      final favorites = jsonList
          .map((item) => FavoriteExercise.fromMap(item as Map<String, dynamic>))
          .toList();
      
      final ids = favorites.map((f) => f.exerciseId).toList();
      _logDebug('獲取使用者 $userId 的收藏 ID：${ids.length} 個');
      return ids;
    } catch (e) {
      _logError('獲取收藏 ID 失敗: $e');
      return [];
    }
  }

  @override
  Future<List<FavoriteExercise>> getFavoriteExercises(String userId) async {
    await _ensureInitialized();
    
    try {
      final key = _getFavoritesKey(userId);
      final jsonString = _prefs!.getString(key);
      
      if (jsonString == null) {
        _logDebug('使用者 $userId 沒有收藏記錄');
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(jsonString);
      final favorites = jsonList
          .map((item) => FavoriteExercise.fromMap(item as Map<String, dynamic>))
          .toList();
      
      _logDebug('獲取使用者 $userId 的收藏：${favorites.length} 個');
      return favorites;
    } catch (e) {
      _logError('獲取收藏列表失敗: $e');
      return [];
    }
  }

  @override
  Future<void> addFavorite(
    String userId,
    String exerciseId,
    String exerciseName,
    String bodyPart,
  ) async {
    await _ensureInitialized();
    
    try {
      // 獲取現有收藏
      final favorites = await getFavoriteExercises(userId);
      
      // 檢查是否已存在
      if (favorites.any((f) => f.exerciseId == exerciseId)) {
        _logDebug('動作 $exerciseId 已在收藏中');
        return;
      }
      
      // 創建新收藏
      final newFavorite = FavoriteExercise(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        bodyPart: bodyPart,
        addedAt: DateTime.now(),
      );
      
      // 添加到列表開頭
      favorites.insert(0, newFavorite);
      
      // 保存
      await _saveFavorites(userId, favorites);
      
      _logDebug('添加收藏成功: $exerciseName');
    } catch (e) {
      _logError('添加收藏失敗: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeFavorite(String userId, String exerciseId) async {
    await _ensureInitialized();
    
    try {
      // 獲取現有收藏
      final favorites = await getFavoriteExercises(userId);
      
      // 移除指定動作
      favorites.removeWhere((f) => f.exerciseId == exerciseId);
      
      // 保存
      await _saveFavorites(userId, favorites);
      
      _logDebug('移除收藏成功: $exerciseId');
    } catch (e) {
      _logError('移除收藏失敗: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isFavorite(String userId, String exerciseId) async {
    await _ensureInitialized();
    
    try {
      final favorites = await getFavoriteExercises(userId);
      return favorites.any((f) => f.exerciseId == exerciseId);
    } catch (e) {
      _logError('檢查收藏狀態失敗: $e');
      return false;
    }
  }

  @override
  Future<void> updateLastViewedAt(String userId, String exerciseId) async {
    await _ensureInitialized();
    
    try {
      // 獲取現有收藏
      final favorites = await getFavoriteExercises(userId);
      
      // 查找並更新
      final index = favorites.indexWhere((f) => f.exerciseId == exerciseId);
      if (index == -1) {
        _logDebug('動作 $exerciseId 不在收藏中');
        return;
      }
      
      // 更新最後查看時間
      favorites[index] = favorites[index].copyWith(
        lastViewedAt: DateTime.now(),
      );
      
      // 保存
      await _saveFavorites(userId, favorites);
      
      _logDebug('更新最後查看時間成功: $exerciseId');
    } catch (e) {
      _logError('更新最後查看時間失敗: $e');
      // 不拋出異常，避免影響主要功能
    }
  }

  @override
  Future<void> clearFavorites(String userId) async {
    await _ensureInitialized();
    
    try {
      final key = _getFavoritesKey(userId);
      await _prefs!.remove(key);
      
      _logDebug('清空使用者 $userId 的所有收藏');
    } catch (e) {
      _logError('清空收藏失敗: $e');
      rethrow;
    }
  }

  /// 保存收藏列表到 SharedPreferences
  Future<void> _saveFavorites(String userId, List<FavoriteExercise> favorites) async {
    final key = _getFavoritesKey(userId);
    final jsonList = favorites.map((f) => f.toMap()).toList();
    final jsonString = json.encode(jsonList);
    
    await _prefs!.setString(key, jsonString);
    _logDebug('保存 ${favorites.length} 個收藏到 SharedPreferences');
  }

  /// 記錄調試信息
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[FAVORITES] $message');
    }
  }

  /// 記錄錯誤信息
  void _logError(String message) {
    if (kDebugMode) {
      print('[FAVORITES ERROR] $message');
    }
    
    _errorService.logError(message, type: 'FavoritesService');
  }
}

