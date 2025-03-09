import 'package:flutter/material.dart';
import 'dart:async';
import '../models/custom_exercise_model.dart';
import '../models/exercise_model.dart';
import '../services/interfaces/i_custom_exercise_service.dart';
import '../services/error_handling_service.dart';
import '../services/service_locator.dart' show Environment, serviceLocator;
import 'interfaces/i_custom_exercise_controller.dart';

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
  
  // 數據緩存
  List<CustomExercise>? _userExercisesCache;
  DateTime? _lastCacheRefreshTime;
  
  /// 正在載入數據
  bool get isLoading => _isLoading;
  
  /// 錯誤訊息
  String? get errorMessage => _errorMessage;
  
  /// 緩存的用戶自定義動作
  List<CustomExercise> get cachedExercises => _userExercisesCache ?? [];
  
  /// 構造函數，支持依賴注入
  CustomExerciseController({
    ICustomExerciseService? service,
    ErrorHandlingService? errorService,
  }) : 
    _service = service ?? serviceLocator<ICustomExerciseService>(),
    _errorService = errorService ?? serviceLocator<ErrorHandlingService>() {
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
    _userExercisesCache = null;
    _lastCacheRefreshTime = null;
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
      // 檢查是否需要重新載入 (5分鐘過期)
      final now = DateTime.now();
      final shouldRefresh = _lastCacheRefreshTime == null || 
          now.difference(_lastCacheRefreshTime!).inMinutes > 5;
      
      if (shouldRefresh || _userExercisesCache == null) {
        _setLoading(true);
        clearError();
        
        _userExercisesCache = await _service.getUserCustomExercises();
        _lastCacheRefreshTime = now;
        
        _setLoading(false);
      }
      
      return _userExercisesCache ?? [];
    } catch (e) {
      _handleError('獲取自定義動作失敗', e);
      return _userExercisesCache ?? [];
    }
  }
  
  /// 強制重新載入自定義動作，忽略緩存
  Future<List<CustomExercise>> reloadExercises() async {
    clearCache();
    return getUserExercises();
  }
  
  @override
  Future<CustomExercise> addExercise(String name) async {
    if (!_isInitialized) await _initialize();
    
    // 輸入驗證
    if (name.trim().isEmpty) {
      _handleError('動作名稱不能為空');
      throw ArgumentError('動作名稱不能為空');
    }
    
    // 業務邏輯 - 例如限制名稱長度或格式
    if (name.length > 50) {
      _handleError('動作名稱不能超過50個字符');
      throw ArgumentError('動作名稱不能超過50個字符');
    }
    
    try {
      _setLoading(true);
      clearError();
      
      final exercise = await _service.addCustomExercise(name);
      
      // 更新緩存
      if (_userExercisesCache != null) {
        _userExercisesCache = [..._userExercisesCache!, exercise];
      }
      
      _setLoading(false);
      return exercise;
    } catch (e) {
      _handleError('添加自定義動作失敗', e);
      rethrow;
    }
  }
  
  @override
  Future<void> updateExercise(String exerciseId, String newName) async {
    if (!_isInitialized) await _initialize();
    
    // 輸入驗證
    if (exerciseId.trim().isEmpty) {
      _handleError('動作ID不能為空');
      throw ArgumentError('動作ID不能為空');
    }
    
    if (newName.trim().isEmpty) {
      _handleError('新的動作名稱不能為空');
      throw ArgumentError('新的動作名稱不能為空');
    }
    
    try {
      _setLoading(true);
      clearError();
      
      await _service.updateCustomExercise(exerciseId, newName);
      
      // 更新緩存
      if (_userExercisesCache != null) {
        _userExercisesCache = _userExercisesCache!.map((exercise) {
          if (exercise.id == exerciseId) {
            return CustomExercise(
              id: exercise.id,
              name: newName,
              userId: exercise.userId,
              createdAt: exercise.createdAt,
            );
          }
          return exercise;
        }).toList();
      }
      
      _setLoading(false);
    } catch (e) {
      _handleError('更新自定義動作失敗', e);
      rethrow;
    }
  }
  
  @override
  Future<void> deleteExercise(String exerciseId) async {
    if (!_isInitialized) await _initialize();
    
    if (exerciseId.trim().isEmpty) {
      _handleError('動作ID不能為空');
      throw ArgumentError('動作ID不能為空');
    }
    
    try {
      _setLoading(true);
      clearError();
      
      await _service.deleteCustomExercise(exerciseId);
      
      // 更新緩存
      if (_userExercisesCache != null) {
        _userExercisesCache = _userExercisesCache!
            .where((exercise) => exercise.id != exerciseId)
            .toList();
      }
      
      _setLoading(false);
    } catch (e) {
      _handleError('刪除自定義動作失敗', e);
      rethrow;
    }
  }
  
  @override
  Exercise convertToExercise(CustomExercise customExercise) {
    // 將自定義動作轉換為標準Exercise對象，可以添加更多邏輯
    return Exercise(
      id: customExercise.id,
      name: customExercise.name,
      nameEn: '',
      bodyParts: [],
      type: '自訂',
      equipment: '自訂',
      jointType: '',
      level1: '',
      level2: '',
      level3: '',
      level4: '',
      level5: '',
      actionName: customExercise.name,
      description: '用戶自訂動作',
      videoUrl: '',
      apps: [],
      createdAt: customExercise.createdAt,
    );
  }
} 