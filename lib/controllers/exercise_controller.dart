import 'package:flutter/material.dart';
import 'dart:async';
import '../models/exercise_model.dart';
import '../services/interfaces/i_exercise_service.dart';
import '../services/core/error_handling_service.dart';
import '../services/service_locator.dart' show serviceLocator;
import 'interfaces/i_exercise_controller.dart';
import 'exercise/exercise_cache_manager.dart';
import 'exercise/exercise_cache_key_builder.dart';
import 'exercise/exercise_filter_validator.dart';
import 'exercise/exercise_filter_builder.dart';
import 'exercise/exercise_cache_invalidator.dart';

/// 訓練動作控制器實現
/// 
/// 管理訓練動作數據的業務邏輯，提供數據驗證，錯誤處理和緩存功能
class ExerciseController extends ChangeNotifier implements IExerciseController {
  // 依賴注入
  final IExerciseService _service;
  final ErrorHandlingService _errorService;
  
  // 狀態管理
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  
  // 子模組
  late final ExerciseCacheManager _cacheManager;
  late final ExerciseCacheInvalidator _cacheInvalidator;
  
  /// 正在載入數據
  bool get isLoading => _isLoading;
  
  /// 錯誤訊息
  String? get errorMessage => _errorMessage;
  
  /// 構造函數，支持依賴注入
  ExerciseController({
    IExerciseService? service,
    ErrorHandlingService? errorService,
  }) : 
    _service = service ?? serviceLocator<IExerciseService>(),
    _errorService = errorService ?? serviceLocator<ErrorHandlingService>() {
    // 初始化子模組
    _cacheManager = ExerciseCacheManager();
    _cacheInvalidator = ExerciseCacheInvalidator(_cacheManager);
    _initialize();
  }
  
  /// 初始化控制器
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      
      // 確保服務已初始化
      if (_service.runtimeType.toString().contains('ExerciseService')) {
        await Future.microtask(() async {
          // 可能的初始化代碼，取決於服務實現
        });
      }
      
      // 預載入常用數據
      _cacheManager.exerciseTypes = await _service.getExerciseTypes();
      _cacheManager.bodyParts = await _service.getBodyParts();
      
      _isInitialized = true;
      _setLoading(false);
    } catch (e) {
      _handleError('初始化訓練動作控制器失敗', e);
    }
  }
  
  /// 設置載入狀態
  void _setLoading(bool isLoading) {
    if (_isLoading != isLoading) {
      _isLoading = isLoading;
      notifyListeners();
    }
  }
  
  /// 處理錯誤
  void _handleError(String message, [dynamic error]) {
    _errorMessage = message;
    _errorService.logError('$message: $error', type: 'ExerciseControllerError');
    _setLoading(false);
    notifyListeners();
  }
  
  /// 清除錯誤消息
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
  
  /// 清除特定類型的緩存
  void clearCache(String cacheType) {
    _cacheManager.clearCache(cacheType);
    logDebug('已清除${cacheType}緩存');
  }
  
  /// 清除特定層級的分類緩存
  /// 
  /// 在用戶選擇條件變化時使用，確保獲取最新的分類數據
  void clearLevelCache(int level) {
    _cacheManager.clearLevelCache(level);
    logDebug('已清除Level$level相關緩存');
  }
  
  /// 當選擇條件變化時清除受影響的緩存
  /// 
  /// [changedSelection] 可以是 'type', 'bodyPart', 'level1' 等
  void clearCacheOnSelectionChange(String changedSelection) {
    _cacheInvalidator.clearCacheOnSelectionChange(changedSelection, logDebug: logDebug);
  }
  
  /// 釋放資源
  @override
  void dispose() {
    _isInitialized = false;
    clearCache('all');
    super.dispose();
  }
  
  @override
  void logDebug(String message) {
    _service.logDebug(message);
    _errorService.logError(message, type: 'Debug');
  }
  
  @override
  Future<List<String>> loadExerciseTypes() async {
    if (!_isInitialized) await _initialize();
    
    try {
      if (_cacheManager.exerciseTypes == null) {
        _setLoading(true);
        clearError();
        _cacheManager.exerciseTypes = await _service.getExerciseTypes();
        _setLoading(false);
      }
      return _cacheManager.exerciseTypes ?? [];
    } catch (e) {
      _handleError('載入訓練類型失敗', e);
      return [];
    }
  }
  
  @override
  Future<List<String>> loadBodyParts() async {
    if (!_isInitialized) await _initialize();
    
    try {
      if (_cacheManager.bodyParts == null) {
        _setLoading(true);
        clearError();
        _cacheManager.bodyParts = await _service.getBodyParts();
        _setLoading(false);
      }
      return _cacheManager.bodyParts ?? [];
    } catch (e) {
      _handleError('載入身體部位失敗', e);
      return [];
    }
  }
  
  @override
  Future<List<String>> loadCategories({
    required int level,
    String? selectedType,
    String? selectedBodyPart,
    String? selectedLevel1,
    String? selectedLevel2,
    String? selectedLevel3,
    String? selectedLevel4,
  }) async {
    if (!_isInitialized) await _initialize();
    
    try {
      // 驗證必要條件
      ExerciseFilterValidator.validateCategoryFilters(
        level: level,
        selectedType: selectedType,
        selectedBodyPart: selectedBodyPart,
      );

      // 構建過濾器
      final filters = ExerciseFilterBuilder.buildCategoryFilters(
        level: level,
        selectedType: selectedType,
        selectedBodyPart: selectedBodyPart,
        selectedLevel1: selectedLevel1,
        selectedLevel2: selectedLevel2,
        selectedLevel3: selectedLevel3,
        selectedLevel4: selectedLevel4,
      );

      // 生成緩存鍵
      final cacheKey = ExerciseCacheKeyBuilder.buildCategoryCacheKey(
        level: level,
        selectedType: selectedType,
        selectedBodyPart: selectedBodyPart,
        selectedLevel1: selectedLevel1,
        selectedLevel2: selectedLevel2,
        selectedLevel3: selectedLevel3,
        selectedLevel4: selectedLevel4,
      );
      logDebug('緩存鍵: $cacheKey');
      
      // 清除緩存以確保獲取最新數據
      clearCache('categories');
      
      // 從服務獲取數據
      _setLoading(true);
      clearError();
      final categories = await _service.getCategoriesByLevel(level, filters);
      
      // 儲存到緩存
      _cacheManager.setCategoriesByKey(cacheKey, categories);
      
      _setLoading(false);
      logDebug('成功載入 ${categories.length} 個Level$level分類');
      
      return categories;
    } catch (e) {
      _handleError('載入分類失敗', e);
      return [];
    }
  }
  
  @override
  Future<List<Exercise>> loadFinalExercises({
    String? selectedType,
    String? selectedBodyPart,
    String? selectedLevel1,
    String? selectedLevel2,
    String? selectedLevel3,
    String? selectedLevel4,
    String? selectedLevel5,
  }) async {
    try {
      // 驗證必要條件
      ExerciseFilterValidator.validateExerciseFilters(
        selectedType: selectedType,
        selectedBodyPart: selectedBodyPart,
      );
      
      // 構建過濾器
      final filters = ExerciseFilterBuilder.buildExerciseFilters(
        selectedType: selectedType!,
        selectedBodyPart: selectedBodyPart!,
        selectedLevel1: selectedLevel1,
        selectedLevel2: selectedLevel2,
        selectedLevel3: selectedLevel3,
        selectedLevel4: selectedLevel4,
        selectedLevel5: selectedLevel5,
      );

      // 生成緩存鍵
      final cacheKey = ExerciseCacheKeyBuilder.buildExercisesCacheKey(
        selectedType: selectedType,
        selectedBodyPart: selectedBodyPart,
        selectedLevel1: selectedLevel1,
        selectedLevel2: selectedLevel2,
        selectedLevel3: selectedLevel3,
        selectedLevel4: selectedLevel4,
        selectedLevel5: selectedLevel5,
      );
      
      // 檢查緩存
      final cachedExercises = _cacheManager.getExercisesByKey(cacheKey);
      if (cachedExercises != null) {
        logDebug('從緩存返回 ${cachedExercises.length} 個運動');
        return cachedExercises.cast<Exercise>();
      }

      // 使用服務層方法獲取數據
      _setLoading(true);
      clearError();
      final exercises = await _service.getExercisesByFilters(filters);
      
      // 緩存結果
      if (exercises.isNotEmpty) {
        _cacheManager.setExercisesByKey(cacheKey, exercises);
      }
      
      logDebug('查詢到 ${exercises.length} 個最終動作');
      _setLoading(false);
      
      return exercises;
    } catch (e) {
      _handleError('載入最終動作失敗', e);
      rethrow;
    }
  }
  
  @override
  Future<Exercise?> getExerciseById(String exerciseId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      // 檢查緩存
      if (_cacheManager.hasExerciseDetails(exerciseId)) {
        return _cacheManager.getExerciseDetails(exerciseId);
      }
      
      // 從服務獲取數據
      _setLoading(true);
      clearError();
      final exercise = await _service.getExerciseById(exerciseId);
      
      if (exercise != null) {
        _cacheManager.setExerciseDetails(exerciseId, exercise);
      }
      
      _setLoading(false);
      return exercise;
    } catch (e) {
      _handleError('獲取動作詳情失敗', e);
      return null;
    }
  }
} 
