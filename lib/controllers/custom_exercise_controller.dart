import 'package:flutter/material.dart';
import 'dart:async';
import '../models/custom_exercise_model.dart';
import '../models/exercise_model.dart';
import '../services/interfaces/i_custom_exercise_service.dart';
import '../services/core/error_handling_service.dart';
import '../services/service_locator.dart' show serviceLocator;
import 'interfaces/i_custom_exercise_controller.dart';
import 'custom_exercise/custom_exercise_cache_manager.dart';
import 'custom_exercise/custom_exercise_validator.dart';
import 'custom_exercise/custom_exercise_converter.dart';

/// 自定義動作控制器實現
/// 
/// 管理用戶自定義訓練動作的業務邏輯，提供數據驗證，錯誤處理和狀態管理功能
class CustomExerciseController extends ChangeNotifier implements ICustomExerciseController {
  // 依賴注入
  final ICustomExerciseService _service;
  final ErrorHandlingService _errorService;
  
  // 狀態管理
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  
  // 子模組
  late final CustomExerciseCacheManager _cacheManager;
  
  /// 正在載入數據
  bool get isLoading => _isLoading;
  
  /// 錯誤訊息
  String? get errorMessage => _errorMessage;
  
  /// 緩存的用戶自定義動作
  List<CustomExercise> get cachedExercises => _cacheManager.cachedExercises;
  
  /// 構造函數，支持依賴注入
  CustomExerciseController({
    ICustomExerciseService? service,
    ErrorHandlingService? errorService,
  }) : 
    _service = service ?? serviceLocator<ICustomExerciseService>(),
    _errorService = errorService ?? serviceLocator<ErrorHandlingService>() {
    // 初始化子模組
    _cacheManager = CustomExerciseCacheManager();
    _initialize();
  }
  
  /// 初始化控制器
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      
      // 確保服務已初始化
      if (_service.runtimeType.toString().contains('CustomExerciseService')) {
        await Future.microtask(() async {
          // 可能的初始化代碼，取決於服務實現
        });
      }
      
      _isInitialized = true;
      _setLoading(false);
    } catch (e) {
      _handleError('初始化自定義動作控制器失敗', e);
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
    _errorService.logError('$message: $error', type: 'CustomExerciseControllerError');
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
  
  /// 清除緩存
  void clearCache() {
    _cacheManager.clearCache();
  }
  
  /// 釋放資源
  @override
  void dispose() {
    _isInitialized = false;
    clearCache();
    super.dispose();
  }
  
  @override
  Future<List<CustomExercise>> getUserExercises() async {
    if (!_isInitialized) await _initialize();
    
    try {
      // 使用緩存管理器檢查是否需要刷新
      if (_cacheManager.shouldRefresh()) {
        _setLoading(true);
        clearError();
        
        final exercises = await _service.getUserCustomExercises();
        _cacheManager.updateCache(exercises);
        
        _setLoading(false);
      }
      
      return _cacheManager.cachedExercises;
    } catch (e) {
      _handleError('獲取自定義動作失敗', e);
      return _cacheManager.cachedExercises;
    }
  }
  
  /// 強制重新載入自定義動作，忽略緩存
  Future<List<CustomExercise>> reloadExercises() async {
    clearCache();
    return getUserExercises();
  }
  
  @override
  Future<CustomExercise> addExercise({
    required String name,
    required String trainingType,
    required String bodyPart,
    String equipment = '徒手',
    String description = '',
    String notes = '',
  }) async {
    if (!_isInitialized) await _initialize();
    
    // 使用驗證器進行輸入驗證
    try {
      CustomExerciseValidator.validateCreateParams(
        name: name,
        bodyPart: bodyPart,
      );
    } catch (e) {
      _handleError(e.toString());
      rethrow;
    }
    
    try {
      _setLoading(true);
      clearError();
      
      final exercise = await _service.addCustomExercise(
        name: name,
        trainingType: trainingType,
        bodyPart: bodyPart,
        equipment: equipment,
        description: description,
        notes: notes,
      );
      
      // 使用緩存管理器更新緩存
      _cacheManager.addToCache(exercise);
      
      _setLoading(false);
      return exercise;
    } catch (e) {
      _handleError('添加自定義動作失敗', e);
      rethrow;
    }
  }
  
  @override
  Future<void> updateExercise({
    required String exerciseId,
    String? name,
    String? trainingType,
    String? bodyPart,
    String? equipment,
    String? description,
    String? notes,
  }) async {
    if (!_isInitialized) await _initialize();
    
    // 使用驗證器進行輸入驗證
    try {
      CustomExerciseValidator.validateUpdateParams(
        exerciseId: exerciseId,
        name: name,
      );
    } catch (e) {
      _handleError(e.toString());
      rethrow;
    }
    
    try {
      _setLoading(true);
      clearError();
      
      await _service.updateCustomExercise(
        exerciseId: exerciseId,
        name: name,
        trainingType: trainingType,
        bodyPart: bodyPart,
        equipment: equipment,
        description: description,
        notes: notes,
      );
      
      // 清除緩存，下次重新載入
      _cacheManager.clearCache();
      
      _setLoading(false);
    } catch (e) {
      _handleError('更新自定義動作失敗', e);
      rethrow;
    }
  }
  
  @override
  Future<void> deleteExercise(String exerciseId) async {
    if (!_isInitialized) await _initialize();
    
    // 使用驗證器進行輸入驗證
    try {
      CustomExerciseValidator.validateId(exerciseId);
    } catch (e) {
      _handleError(e.toString());
      rethrow;
    }
    
    try {
      _setLoading(true);
      clearError();
      
      await _service.deleteCustomExercise(exerciseId);
      
      // 使用緩存管理器更新緩存
      _cacheManager.removeFromCache(exerciseId);
      
      _setLoading(false);
    } catch (e) {
      _handleError('刪除自定義動作失敗', e);
      rethrow;
    }
  }
  
  @override
  Exercise convertToExercise(CustomExercise customExercise) {
    // 使用轉換器將自定義動作轉換為標準 Exercise 對象
    return CustomExerciseConverter.toExercise(customExercise);
  }
} 