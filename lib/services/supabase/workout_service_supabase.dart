import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../models/workout_template_model.dart';
import '../../models/workout_record_model.dart';
import '../interfaces/i_workout_service.dart';
import '../core/error_handling_service.dart';
import '../service_locator.dart' show Environment;
import 'workout/_workout_cache_manager.dart';
import 'workout/workout_template_operations.dart';
import 'workout/workout_record_operations.dart';
import 'workout/workout_id_generator.dart';

/// 訓練計畫服務的 Supabase 實現
///
/// 提供訓練模板管理、訓練記錄追蹤和從模板創建記錄等功能
class WorkoutServiceSupabase implements IWorkoutService {
  // 依賴注入
  final SupabaseClient _supabase;
  final ErrorHandlingService? _errorService;

  // 服務狀態
  bool _isInitialized = false;
  Environment _environment = Environment.development;

  // 服務配置
  bool _cacheTemplates = true;
  bool _cacheRecords = true;

  // 子模組
  late final WorkoutCacheManager _cacheManager;
  late final WorkoutTemplateOperations _templateOps;
  late final WorkoutRecordOperations _recordOps;
  Timer? _cacheClearTimer;

  /// 創建服務實例
  WorkoutServiceSupabase({
    SupabaseClient? supabase,
    ErrorHandlingService? errorService,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _errorService = errorService {
    _cacheManager = WorkoutCacheManager();
    _templateOps = WorkoutTemplateOperations(
      supabase: _supabase,
      cacheManager: _cacheManager,
      logDebug: _logDebug,
      logError: _logError,
      cacheTemplates: _cacheTemplates,
    );
    _recordOps = WorkoutRecordOperations(
      supabase: _supabase,
      cacheManager: _cacheManager,
      logDebug: _logDebug,
      logError: _logError,
      cacheRecords: _cacheRecords,
    );
  }

  /// 初始化服務
  Future<void> initialize(
      {Environment environment = Environment.development}) async {
    if (_isInitialized) return;

    try {
      configureForEnvironment(environment);

      if (_cacheTemplates || _cacheRecords) {
        _setupCacheCleanupTimer();
      }

      _isInitialized = true;
      _logDebug('訓練計畫服務初始化完成');
    } catch (e) {
      _logError('訓練計畫服務初始化失敗: $e');
      rethrow;
    }
  }

  /// 釋放資源
  Future<void> dispose() async {
    try {
      _cacheClearTimer?.cancel();
      _cacheClearTimer = null;

      _cacheManager.clearAll();

      _isInitialized = false;
      _logDebug('訓練計畫服務資源已釋放');
    } catch (e) {
      _logError('釋放訓練計畫服務資源時發生錯誤: $e');
    }
  }

  /// 根據環境配置服務
  void configureForEnvironment(Environment environment) {
    _environment = environment;

    switch (environment) {
      case Environment.development:
        _cacheTemplates = true;
        _cacheRecords = true;
        _logDebug('訓練計畫服務配置為開發環境');
        break;
      case Environment.testing:
        _cacheTemplates = false;
        _cacheRecords = false;
        _logDebug('訓練計畫服務配置為測試環境');
        break;
      case Environment.production:
        _cacheTemplates = true;
        _cacheRecords = true;
        _logDebug('訓練計畫服務配置為生產環境');
        break;
    }
  }

  /// 設置緩存清理計時器
  void _setupCacheCleanupTimer() {
    _cacheClearTimer?.cancel();
    _cacheClearTimer = Timer.periodic(const Duration(hours: 3), (_) {
      _clearCache();
    });
  }

  /// 清除緩存
  void _clearCache() {
    _logDebug('清理訓練計畫緩存');
    _cacheManager.clearAll();
  }

  // 獲取當前用戶ID
  String? get currentUserId {
    _ensureInitialized();
    return _supabase.auth.currentUser?.id;
  }

  @override
  Future<List<WorkoutTemplate>> getUserTemplates({
    String? cursor,
    int limit = 20,
  }) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logDebug('獲取用戶模板：沒有登入用戶');
      return [];
    }

    return await _templateOps.getUserTemplates(
      userId: currentUserId!,
      cursor: cursor,
      limit: limit,
    );
  }

  @override
  Future<WorkoutTemplate?> getTemplateById(String templateId) async {
    _ensureInitialized();
    return await _templateOps.getTemplateById(templateId);
  }

  @override
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logError('創建模板失敗：沒有登入用戶');
      throw Exception('用戶未登入');
    }

    return await _templateOps.createTemplate(
      userId: currentUserId!,
      template: template,
      generateId: WorkoutIdGenerator.generateFirestoreId,
    );
  }

  @override
  Future<bool> updateTemplate(WorkoutTemplate template) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logError('更新模板失敗：沒有登入用戶');
      return false;
    }

    return await _templateOps.updateTemplate(
      userId: currentUserId!,
      template: template,
    );
  }

  @override
  Future<bool> deleteTemplate(String templateId) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logError('刪除模板失敗：沒有登入用戶');
      return false;
    }

    return await _templateOps.deleteTemplate(
      userId: currentUserId!,
      templateId: templateId,
    );
  }

  @override
  Future<List<WorkoutRecord>> getUserRecords({
    String? cursor,
    int limit = 20,
  }) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logDebug('獲取用戶記錄：沒有登入用戶');
      return [];
    }

    return await _recordOps.getUserRecords(
      userId: currentUserId!,
      cursor: cursor,
      limit: limit,
    );
  }

  @override
  Future<List<WorkoutRecord>> getUserPlans({
    bool? completed,
    DateTime? startDate,
    DateTime? endDate,
    String? cursor,
    int limit = 20,
  }) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logDebug('獲取用戶計劃：沒有登入用戶');
      return [];
    }

    return await _recordOps.getUserPlans(
      userId: currentUserId!,
      completed: completed,
      startDate: startDate,
      endDate: endDate,
      cursor: cursor,
      limit: limit,
    );
  }

  @override
  Future<WorkoutRecord?> getRecordById(String recordId) async {
    _ensureInitialized();
    return await _recordOps.getRecordById(recordId);
  }

  @override
  Future<WorkoutRecord> createRecord(WorkoutRecord record) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logError('創建記錄失敗：沒有登入用戶');
      throw Exception('用戶未登入');
    }

    return await _recordOps.createRecord(
      userId: currentUserId!,
      record: record,
      generateId: WorkoutIdGenerator.generateFirestoreId,
    );
  }

  @override
  Future<bool> updateRecord(WorkoutRecord record) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logError('更新記錄失敗：沒有登入用戶');
      return false;
    }

    return await _recordOps.updateRecord(
      userId: currentUserId!,
      record: record,
    );
  }

  @override
  Future<bool> deleteRecord(String recordId) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logError('刪除記錄失敗：沒有登入用戶');
      return false;
    }

    return await _recordOps.deleteRecord(
      userId: currentUserId!,
      recordId: recordId,
    );
  }

  @override
  Future<WorkoutRecord> createRecordFromTemplate(String templateId) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logError('從模板創建記錄失敗：沒有登入用戶');
      throw Exception('用戶未登入');
    }

    try {
      _logDebug('從模板創建訓練記錄: $templateId');

      // 獲取模板
      final template = await getTemplateById(templateId);
      if (template == null) {
        throw Exception('模板不存在: $templateId');
      }

      // 從模板創建記錄
      final exerciseRecords = template.exercises
          .map((exercise) => ExerciseRecord(
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                sets: List.generate(
                  exercise.sets,
                  (index) => SetRecord(
                    setNumber: index + 1,
                    reps: exercise.reps,
                    weight: exercise.weight,
                    restTime: exercise.restTime,
                  ),
                ),
              ))
          .toList();

      final record = WorkoutRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        workoutPlanId: templateId,
        userId: currentUserId!,
        title: template.title, // 使用模板的標題
        date: DateTime.now(),
        exerciseRecords: exerciseRecords,
        completed: false,
        createdAt: DateTime.now(),
        trainingTime: template.trainingTime,
      );

      return await createRecord(record);
    } catch (e) {
      _logError('從模板創建記錄失敗: $e');
      rethrow;
    }
  }

  /// 確保服務已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      _logDebug('警告: 訓練計畫服務在初始化前被調用');
      if (_environment == Environment.development) {
        initialize();
      } else {
        throw StateError('訓練計畫服務未初始化');
      }
    }
  }

  /// 記錄調試信息
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[WORKOUT_SERVICE_SUPABASE] $message');
    }
  }

  /// 記錄錯誤信息
  void _logError(String message) {
    if (kDebugMode) {
      print('[WORKOUT_SERVICE_SUPABASE ERROR] $message');
    }
    _errorService?.logError(message);
  }
}
