import 'package:flutter/material.dart';
import 'dart:async';
import '../models/workout_template_model.dart';
import '../models/workout_record_model.dart';
import '../services/interfaces/i_workout_service.dart';
import '../services/core/error_handling_service.dart';
import '../services/service_locator.dart' show serviceLocator;
import 'interfaces/i_workout_controller.dart';
import 'workout/workout_cache_manager.dart';
import 'workout/workout_data_validator.dart';

/// 訓練計畫控制器實現
/// 
/// 管理用戶訓練模板和記錄的業務邏輯，提供數據驗證，錯誤處理和狀態管理功能
class WorkoutController extends ChangeNotifier implements IWorkoutController {
  // 依賴注入
  final IWorkoutService _workoutService;
  final ErrorHandlingService _errorService;
  
  // 狀態管理
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  
  // 子模組
  late final WorkoutCacheManager _cacheManager;
  
  /// 正在載入數據
  bool get isLoading => _isLoading;
  
  /// 錯誤訊息
  String? get errorMessage => _errorMessage;
  
  /// 緩存的模板
  List<WorkoutTemplate> get cachedTemplates => _cacheManager.templatesCache ?? [];
  
  /// 緩存的記錄
  List<WorkoutRecord> get cachedRecords => _cacheManager.recordsCache ?? [];
  
  /// 構造函數，支持依賴注入
  WorkoutController({
    IWorkoutService? workoutService,
    ErrorHandlingService? errorService,
  }) : 
    _workoutService = workoutService ?? serviceLocator<IWorkoutService>(),
    _errorService = errorService ?? serviceLocator<ErrorHandlingService>() {
    // 初始化子模組
    _cacheManager = WorkoutCacheManager();
    _initialize();
  }
  
  /// 初始化控制器
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      
      // 確保服務已初始化
      if (_workoutService.runtimeType.toString().contains('WorkoutService')) {
        await Future.microtask(() async {
          // 可能的初始化代碼，取決於服務實現
        });
      }
      
      _isInitialized = true;
      _setLoading(false);
    } catch (e) {
      _handleError('初始化訓練計劃控制器失敗', e);
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
    _errorService.logError('$message: $error', type: 'WorkoutControllerError');
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
  
  /// 釋放資源
  @override
  void dispose() {
    _isInitialized = false;
    _cacheManager.clearAllCache();
    super.dispose();
  }
  
  @override
  Future<List<WorkoutTemplate>> loadUserTemplates() async {
    if (!_isInitialized) await _initialize();
    
    try {
      _setLoading(true);
      clearError();
      
      // 使用緩存管理器檢查是否需要刷新
      if (_cacheManager.shouldRefreshTemplates()) {
        final templates = await _workoutService.getUserTemplates();
        _cacheManager.updateTemplatesCache(templates);
      }
      
      _setLoading(false);
      return _cacheManager.templatesCache ?? [];
    } catch (e) {
      _handleError('載入訓練模板失敗', e);
      return _cacheManager.templatesCache ?? [];
    }
  }
  
  /// 強制重新載入模板，忽略緩存
  Future<List<WorkoutTemplate>> reloadTemplates() async {
    _cacheManager.clearTemplatesCache();
    return loadUserTemplates();
  }
  
  @override
  Future<WorkoutTemplate?> getTemplateById(String templateId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      // 先從緩存中查找
      final cachedTemplate = _cacheManager.findTemplateInCache(templateId);
      if (cachedTemplate != null) {
        return cachedTemplate;
      }
      
      // 緩存中沒有，從服務中獲取
      return await _workoutService.getTemplateById(templateId);
    } catch (e) {
      _handleError('獲取訓練模板詳情失敗', e);
      return null;
    }
  }
  
  @override
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template) async {
    if (!_isInitialized) await _initialize();
    
    // 輸入驗證
    try {
      WorkoutDataValidator.validateTemplate(
        title: template.title,
        exercises: template.exercises,
      );
    } catch (e) {
      _handleError(e.toString());
      rethrow;
    }
    
    try {
      _setLoading(true);
      clearError();
      
      // 確保創建時間和更新時間
      final now = DateTime.now();
      final updatedTemplate = template.copyWith(
        createdAt: now,
        updatedAt: now,
      );
      
      final result = await _workoutService.createTemplate(updatedTemplate);
      
      // 更新緩存
      _cacheManager.addTemplateToCache(result);
      
      _setLoading(false);
      return result;
    } catch (e) {
      _handleError('創建訓練模板失敗', e);
      rethrow;
    }
  }
  
  @override
  Future<bool> updateTemplate(WorkoutTemplate template) async {
    if (!_isInitialized) await _initialize();
    
    // 輸入驗證
    try {
      WorkoutDataValidator.validateTemplate(
        title: template.title,
        exercises: template.exercises,
      );
    } catch (e) {
      _handleError(e.toString());
      rethrow;
    }
    
    try {
      _setLoading(true);
      clearError();
      
      // 更新時間
      final updatedTemplate = template.copyWith(
        updatedAt: DateTime.now(),
      );
      
      final success = await _workoutService.updateTemplate(updatedTemplate);
      
      // 更新緩存
      if (success) {
        _cacheManager.updateTemplateInCache(updatedTemplate);
      }
      
      _setLoading(false);
      return success;
    } catch (e) {
      _handleError('更新訓練模板失敗', e);
      return false;
    }
  }
  
  @override
  Future<bool> deleteTemplate(String templateId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      _setLoading(true);
      clearError();
      
      final success = await _workoutService.deleteTemplate(templateId);
      
      // 更新緩存
      if (success) {
        _cacheManager.removeTemplateFromCache(templateId);
      }
      
      _setLoading(false);
      return success;
    } catch (e) {
      _handleError('刪除訓練模板失敗', e);
      return false;
    }
  }
  
  @override
  Future<List<WorkoutRecord>> loadUserRecords() async {
    if (!_isInitialized) await _initialize();
    
    try {
      _setLoading(true);
      clearError();
      
      // 使用緩存管理器檢查是否需要刷新
      if (_cacheManager.shouldRefreshRecords()) {
        final records = await _workoutService.getUserRecords();
        _cacheManager.updateRecordsCache(records);
      }
      
      _setLoading(false);
      return _cacheManager.recordsCache ?? [];
    } catch (e) {
      _handleError('載入訓練記錄失敗', e);
      return _cacheManager.recordsCache ?? [];
    }
  }
  
  /// 強制重新載入記錄，忽略緩存
  Future<List<WorkoutRecord>> reloadRecords() async {
    _cacheManager.clearRecordsCache();
    return loadUserRecords();
  }
  
  @override
  Future<WorkoutRecord?> getRecordById(String recordId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      // 先從緩存中查找
      final cachedRecord = _cacheManager.findRecordInCache(recordId);
      if (cachedRecord != null) {
        return cachedRecord;
      }
      
      // 緩存中沒有，從服務中獲取
      return await _workoutService.getRecordById(recordId);
    } catch (e) {
      _handleError('獲取訓練記錄詳情失敗', e);
      return null;
    }
  }
  
  @override
  Future<WorkoutRecord> createRecord(WorkoutRecord record) async {
    if (!_isInitialized) await _initialize();
    
    try {
      _setLoading(true);
      clearError();
      
      final result = await _workoutService.createRecord(record);
      
      // 更新緩存
      _cacheManager.addRecordToCache(result);
      
      _setLoading(false);
      return result;
    } catch (e) {
      _handleError('創建訓練記錄失敗', e);
      rethrow;
    }
  }
  
  @override
  Future<bool> updateRecord(WorkoutRecord record) async {
    if (!_isInitialized) await _initialize();
    
    try {
      _setLoading(true);
      clearError();
      
      final success = await _workoutService.updateRecord(record);
      
      // 更新緩存
      if (success) {
        _cacheManager.updateRecordInCache(record);
      }
      
      _setLoading(false);
      return success;
    } catch (e) {
      _handleError('更新訓練記錄失敗', e);
      return false;
    }
  }
  
  @override
  Future<bool> deleteRecord(String recordId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      _setLoading(true);
      clearError();
      
      final success = await _workoutService.deleteRecord(recordId);
      
      // 更新緩存
      if (success) {
        _cacheManager.removeRecordFromCache(recordId);
      }
      
      _setLoading(false);
      return success;
    } catch (e) {
      _handleError('刪除訓練記錄失敗', e);
      return false;
    }
  }
  
  @override
  Future<WorkoutRecord> createRecordFromTemplate(String templateId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      _setLoading(true);
      clearError();
      
      final record = await _workoutService.createRecordFromTemplate(templateId);
      
      // 更新緩存
      _cacheManager.addRecordToCache(record);
      
      _setLoading(false);
      return record;
    } catch (e) {
      _handleError('從模板創建訓練記錄失敗', e);
      rethrow;
    }
  }
} 