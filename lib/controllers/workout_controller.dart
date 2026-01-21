import 'package:flutter/material.dart';
import 'dart:async';
import '../models/workout_template_model.dart';
import '../models/workout_record_model.dart';
import '../models/exercise_history_record.dart'; // ⭐ v3.6: MVVM
import '../services/interfaces/i_workout_service.dart';
import '../services/core/error_handling_service.dart';
import '../services/service_locator.dart' show serviceLocator;
import 'interfaces/i_workout_controller.dart';
import 'interfaces/i_auth_controller.dart'; // ⭐ v3.6: EventBus fallback
import 'workout/workout_data_validator.dart';
import 'interfaces/i_event_bus_controller.dart'; // ⭐ v3.5

/// 訓練計畫控制器實現
/// 
/// 管理用戶訓練模板和記錄的業務邏輯，提供數據驗證，錯誤處理和狀態管理功能
/// ⭐ v3.5: 統一發布模板事件（Controller 層負責事件發布）
class WorkoutController extends ChangeNotifier implements IWorkoutController {
  // 依賴注入
  final IWorkoutService _workoutService;
  final ErrorHandlingService _errorService;
  final IEventBusController _eventBusController; // ⭐ v3.5
  final IAuthController _authController; // ⭐ v3.6: EventBus fallback
  
  // 狀態管理
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  
  /// 正在載入數據
  bool get isLoading => _isLoading;
  
  /// 錯誤訊息
  @override
  String? get errorMessage => _errorMessage;
  
  /// 構造函數，支持依賴注入
  WorkoutController({
    IWorkoutService? workoutService,
    ErrorHandlingService? errorService,
    IEventBusController? eventBusController, // ⭐ v3.5
    IAuthController? authController, // ⭐ v3.6: EventBus fallback
  }) :
    _workoutService = workoutService ?? serviceLocator<IWorkoutService>(),
    _errorService = errorService ?? serviceLocator<ErrorHandlingService>(),
    _eventBusController = eventBusController ?? serviceLocator<IEventBusController>(),
    _authController = authController ?? serviceLocator<IAuthController>() {
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
    super.dispose();
  }
  
  @override
  Future<List<WorkoutTemplate>> loadUserTemplates() async {
    if (!_isInitialized) await _initialize();
    
    try {
      _setLoading(true);
      clearError();
      
      // ⭐ v3.7: 快取統一到 Service 層，Controller 不再管理快取
      final templates = await _workoutService.getUserTemplates();
      
      _setLoading(false);
      return templates;
    } catch (e) {
      _handleError('載入訓練模板失敗', e);
      return [];
    }
  }
  
  /// 強制重新載入模板，忽略緩存
  @override
  Future<List<WorkoutTemplate>> reloadTemplates() async {
    // ⭐ v3.7: Service 層會處理快取刷新
    return loadUserTemplates();
  }
  
  @override
  Future<WorkoutTemplate?> getTemplateById(String templateId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      // ⭐ v3.7: 快取統一到 Service 層
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
      
      // ⭐ v3.7: Service 層會自動更新快取
      final result = await _workoutService.createTemplate(updatedTemplate);

      // ⭐ v3.5: 發布模板創建事件
      _eventBusController.publishTemplateCreated(
        templateId: result.id,
        userId: result.userId,
      );
      
      _setLoading(false);
      return result;
    } catch (e) {
      _handleError('創建訓練模板失敗', e);
      rethrow;
    }
  }

  @override
  Future<WorkoutTemplate> saveRecordAsTemplate({
    required List<ExerciseRecord> exerciseRecords,
    required String templateName,
    required String planType,
    String description = '',
  }) async {
    if (!_isInitialized) await _initialize();

    // 輸入驗證
    if (templateName.trim().isEmpty) {
      throw ArgumentError('模板名稱不能為空');
    }
    if (exerciseRecords.isEmpty) {
      throw ArgumentError('至少需要一個訓練動作');
    }

    try {
      _setLoading(true);
      clearError();

      // 轉換 ExerciseRecord 為 WorkoutExercise
      final exercises = exerciseRecords
          .map((record) => record.toWorkoutExercise())
          .toList();

      // 創建模板
      final template = WorkoutTemplate(
        id: '', // 由 Service 層生成
        userId: '', // 由 Service 層填入當前用戶 ID
        title: templateName.trim(),
        description: description,
        planType: planType,
        exercises: exercises,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // ⭐ v3.7: Service 層會自動更新快取
      final result = await _workoutService.createTemplate(template);

      // ⭐ v3.5: 發布模板創建事件
      _eventBusController.publishTemplateCreated(
        templateId: result.id,
        userId: result.userId,
      );

      _setLoading(false);
      return result;
    } catch (e) {
      _handleError('儲存為模板失敗', e);
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
      
      // ⭐ v3.7: Service 層會自動更新快取
      final success = await _workoutService.updateTemplate(updatedTemplate);
      
      if (success) {
        // ⭐ v3.5: 發布模板更新事件
        _eventBusController.publishTemplateUpdated(
          templateId: template.id,
          userId: template.userId,
        );
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

      // ⭐ v3.7: 先從 Service 取得模板資訊用於事件發布
      final templateToDelete = await _workoutService.getTemplateById(templateId);
      final userId = templateToDelete?.userId ?? _authController.user?.uid;

      // ⭐ v3.7: Service 層會自動更新快取
      final success = await _workoutService.deleteTemplate(templateId);

      if (success) {
        // ⭐ v3.5: 發布模板刪除事件
        if (userId != null) {
          _eventBusController.publishTemplateDeleted(
            templateId: templateId,
            userId: userId,
          );
        }
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
      
      // ⭐ v3.7: 快取統一到 Service 層
      final records = await _workoutService.getUserRecords();
      
      _setLoading(false);
      return records;
    } catch (e) {
      _handleError('載入訓練記錄失敗', e);
      return [];
    }
  }
  
  /// 強制重新載入記錄，忽略緩存
  Future<List<WorkoutRecord>> reloadRecords() async {
    // ⭐ v3.7: Service 層會處理快取刷新
    return loadUserRecords();
  }
  
  @override
  Future<WorkoutRecord?> getRecordById(String recordId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      // ⭐ v3.7: 快取統一到 Service 層
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
      
      // ⭐ v3.7: Service 層會自動更新快取
      final result = await _workoutService.createRecord(record);

      // ⭐ v3.5: 發布訓練記錄創建事件
      _eventBusController.publishWorkoutCreated(
        workoutId: result.id,
        userId: result.userId,
      );
      
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
      
      // ⭐ v3.7: Service 層會自動更新快取
      final success = await _workoutService.updateRecord(record);
      
      if (success) {
        // ⭐ v3.5: 發布訓練記錄更新事件
        _eventBusController.publishWorkoutUpdated(
          workoutId: record.id,
          userId: record.userId,
        );
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

      // ⭐ v3.7: 先從 Service 取得記錄資訊用於事件發布
      final recordToDelete = await _workoutService.getRecordById(recordId);
      final userId = recordToDelete?.userId ?? _authController.user?.uid;

      // ⭐ v3.7: Service 層會自動更新快取
      final success = await _workoutService.deleteRecord(recordId);

      if (success) {
        // ⭐ v3.5: 發布訓練記錄刪除事件
        if (userId != null) {
          _eventBusController.publishWorkoutDeleted(
            workoutId: recordId,
            userId: userId,
          );
        }
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
      
      // ⭐ v3.7: Service 層會自動更新快取
      final record = await _workoutService.createRecordFromTemplate(templateId);
      
      _setLoading(false);
      return record;
    } catch (e) {
      _handleError('從模板創建訓練記錄失敗', e);
      rethrow;
    }
  }

  // ============================================================================
  // ⭐ MVVM 重構：查詢方法（直接返回結果，不更新 Controller 狀態）
  // ============================================================================

  /// 查詢用戶的訓練計劃（日期範圍）
  ///
  /// 代理 Service 調用，用於首頁等需要直接獲取數據的場景
  @override
  Future<List<WorkoutRecord>> getUserPlans({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) async {
    try {
      return await _workoutService.getUserPlans(
        startDate: startDate,
        endDate: endDate,
        userId: userId,
      );
    } catch (e) {
      _errorService.logError('查詢訓練計劃失敗: $e', type: 'WorkoutControllerError');
      return [];
    }
  }

  /// 清除用戶的訓練計劃快取
  @override
  void clearUserPlansCache(String userId) {
    _workoutService.clearUserPlansCache(userId);
  }

  /// 清除用戶快取
  /// ⭐ v3.6 MVVM 重構
  @override
  void clearUserCache({String? userId}) {
    _workoutService.clearUserCache(userId: userId);
  }

  /// 檢查時間重疊
  /// ⭐ v3.6 MVVM 重構
  @override
  Future<List<WorkoutRecord>> checkTimeOverlap({
    required String traineeId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeRecordId,
  }) async {
    try {
      return await _workoutService.checkTimeOverlap(
        traineeId: traineeId,
        startTime: startTime,
        endTime: endTime,
        excludeRecordId: excludeRecordId,
      );
    } catch (e) {
      _errorMessage = '檢查時間重疊失敗: $e';
      notifyListeners();
      return [];
    }
  }

  /// 查詢教練創建的訓練計畫（直接返回結果）
  /// ⭐ v3.6 MVVM 重構
  ///
  /// [coachId] 教練 ID（creator_id）
  /// [clientIds] 學員 ID 列表（trainee_id）
  @override
  Future<List<WorkoutRecord>> getCoachCreatedPlans({
    required String coachId,
    required List<String> clientIds,
    int limit = 100,
  }) async {
    try {
      return await _workoutService.getCoachCreatedPlans(
        coachId: coachId,
        clientIds: clientIds,
        limit: limit,
      );
    } catch (e) {
      _errorMessage = '查詢教練創建計畫失敗: $e';
      notifyListeners();
      return [];
    }
  }

  /// 查詢動作歷史記錄（直接返回結果）
  /// ⭐ v3.6 MVVM 重構
  ///
  /// 用於 Session Mode 顯示 PREV 幽靈數據
  @override
  Future<List<ExerciseHistoryRecord>> getExerciseHistory({
    required String userId,
    required String exerciseId,
    int limit = 10,
  }) async {
    try {
      return await _workoutService.getExerciseHistory(
        userId: userId,
        exerciseId: exerciseId,
        limit: limit,
      );
    } catch (e) {
      _errorMessage = '查詢動作歷史失敗: $e';
      notifyListeners();
      return [];
    }
  }
} 