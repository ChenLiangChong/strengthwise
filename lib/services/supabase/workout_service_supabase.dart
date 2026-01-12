import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../models/workout_template_model.dart';
import '../../models/workout_record_model.dart';
import '../../models/exercise_history_record.dart';
import '../../models/tracking_mode.dart';
import '../../utils/datetime_utils.dart';  // ⭐ 使用時間工具
import '../interfaces/i_workout_service.dart';
import '../core/error_handling_service.dart';
import '../service_locator.dart' show Environment;
import '../cache/workout_plan_local_cache_service.dart';
import '../cache/statistics_local_cache_service.dart';
import 'workout/_workout_cache_manager.dart';
import 'workout/workout_template_operations.dart';
import 'workout/workout_record_operations.dart';
import 'workout/workout_id_generator.dart';

/// 訓練計畫服務的 Supabase 實現
///
/// 提供訓練模板管理、訓練記錄追蹤和從模板創建記錄等功能
/// v3.1.1: 新增本地持久化快取支持
class WorkoutServiceSupabase implements IWorkoutService {
  // 依賴注入
  final SupabaseClient _supabase;
  final ErrorHandlingService? _errorService;
  final WorkoutPlanLocalCacheService? _localCacheService;
  final StatisticsLocalCacheService? _statisticsCacheService;

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
    WorkoutPlanLocalCacheService? localCacheService,
    StatisticsLocalCacheService? statisticsCacheService,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _errorService = errorService,
        _localCacheService = localCacheService,
        _statisticsCacheService = statisticsCacheService {
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

  /// 清除用戶的訓練計劃快取 ⭐
  @override
  void clearUserPlansCache(String userId) {
    _logDebug('🧹 準備清除用戶 $userId 的訓練計劃快取');
    _cacheManager.clearUserPlans(userId);
    _logDebug('✅ 已清除用戶 $userId 的訓練計劃快取');
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
    String? userId,  // ⭐ 新增：可選的用戶 ID
    bool? completed,
    DateTime? startDate,
    DateTime? endDate,
    String? cursor,
    int limit = 20,
  }) async {
    _ensureInitialized();

    // ⭐ 如果沒有指定 userId，使用當前用戶
    final targetUserId = userId ?? currentUserId;
    
    if (targetUserId == null) {
      _logDebug('獲取用戶計劃：沒有登入用戶且未指定 userId');
      return [];
    }

    // ⚡ v3.1.1: 本地快取優先（僅適用於查詢未完成的計劃，且沒有分頁）
    if (_localCacheService != null &&
        completed == false &&
        cursor == null &&
        startDate == null &&
        endDate == null) {
      final cachedPlans = await _localCacheService!.getCachedPlans(targetUserId);
      if (cachedPlans != null && cachedPlans.isNotEmpty) {
        _logDebug('⚡ 從本地快取返回 ${cachedPlans.length} 個訓練計劃');
        
        // 背景更新快取（不阻塞返回）
        _refreshAndCachePlans(targetUserId, completed, limit);
        
        return cachedPlans;
      }
    }

    final plans = await _recordOps.getUserPlans(
      userId: targetUserId,
      completed: completed,
      startDate: startDate,
      endDate: endDate,
      cursor: cursor,
      limit: limit,
    );

    // ⚡ 更新本地快取（僅未完成的計劃）
    if (_localCacheService != null && completed == false && cursor == null) {
      _localCacheService!.cacheActivePlans(targetUserId, plans);
    }

    return plans;
  }

  /// ⚡ 背景刷新並更新本地快取
  Future<void> _refreshAndCachePlans(
    String userId,
    bool? completed,
    int limit,
  ) async {
    try {
      final freshPlans = await _recordOps.getUserPlans(
        userId: userId,
        completed: completed,
        limit: limit,
      );
      if (_localCacheService != null && completed == false) {
        await _localCacheService!.cacheActivePlans(userId, freshPlans);
        _logDebug('⚡ 本地快取已更新');
      }
    } catch (e) {
      _logDebug('⚠️ 背景刷新失敗：$e');
    }
  }

  @override
  Future<WorkoutRecord?> getRecordById(String recordId) async {
    _ensureInitialized();
    return await _recordOps.getRecordById(recordId);
  }

  /// ⭐ v3.1-B: 獲取教練創建給學員的訓練計劃
  @override
  Future<List<WorkoutRecord>> getCoachCreatedPlans({
    required String coachId,
    required List<String> clientIds,
    int limit = 100,
  }) async {
    _ensureInitialized();

    if (clientIds.isEmpty) {
      _logDebug('獲取教練創建的計劃：學員列表為空');
      return [];
    }

    try {
      _logDebug('查詢教練 $coachId 創建的計劃，學員: $clientIds');

      final response = await _supabase
          .from('workout_plans')
          .select(
              'id, user_id, trainee_id, creator_id, title, scheduled_date, completed_date, completed, '
              'total_volume, total_exercises, total_sets, plan_type, exercises, note, training_time, '
              'actual_start_time, actual_end_time, elapsed_seconds, training_status, appointment_id, '
              'created_at, updated_at')
          .eq('creator_id', coachId)
          .inFilter('trainee_id', clientIds)
          .order('scheduled_date', ascending: false)
          .limit(limit);

      final records = (response as List)
          .map((data) => WorkoutRecord.fromSupabase(data))
          .toList();

      _logDebug('找到 ${records.length} 筆教練創建的計劃');
      return records;
    } catch (e) {
      _logError('查詢教練創建的計劃失敗: $e');
      return [];
    }
  }

  @override
  Future<WorkoutRecord?> getRecordByAppointmentId(String appointmentId) async {
    _ensureInitialized();
    return await _recordOps.getRecordByAppointmentId(appointmentId);
  }

  @override
  Future<WorkoutRecord> createRecord(WorkoutRecord record) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logError('創建記錄失敗：沒有登入用戶');
      throw Exception('用戶未登入');
    }

    final createdRecord = await _recordOps.createRecord(
      userId: currentUserId!,
      record: record,
      generateId: WorkoutIdGenerator.generateFirestoreId,
    );

    // ⚡ v3.1.1: 更新本地快取
    if (_localCacheService != null && !createdRecord.completed) {
      _localCacheService!.updateCachedPlan(currentUserId!, createdRecord);
    }

    return createdRecord;
  }

  @override
  Future<bool> updateRecord(WorkoutRecord record) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logError('更新記錄失敗：沒有登入用戶');
      return false;
    }

    final success = await _recordOps.updateRecord(
      userId: currentUserId!,
      record: record,
    );

    // ⚡ v3.1.1: 更新本地快取
    if (success && _localCacheService != null) {
      if (record.completed) {
        // 已完成的計劃從快取移除
        _localCacheService!.removeCachedPlan(currentUserId!, record.id);
        
        // ⚡ 訓練完成時，清除統計快取（下次會重新計算）
        if (_statisticsCacheService != null) {
          _statisticsCacheService!.clearUserCache(currentUserId!);
          _logDebug('🔄 訓練完成，已清除統計快取');
        }
      } else {
        // 未完成的計劃更新快取
        _localCacheService!.updateCachedPlan(currentUserId!, record);
      }
    }

    return success;
  }

  @override
  Future<bool> deleteRecord(String recordId) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logError('刪除記錄失敗：沒有登入用戶');
      return false;
    }

    final success = await _recordOps.deleteRecord(
      userId: currentUserId!,
      recordId: recordId,
    );

    // ⚡ v3.1.1: 從本地快取移除
    if (success && _localCacheService != null) {
      _localCacheService!.removeCachedPlan(currentUserId!, recordId);
    }

    return success;
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

  @override
  void clearUserCache({String? userId}) {
    _ensureInitialized();
    
    final targetUserId = userId ?? currentUserId;
    
    if (targetUserId != null) {
      _recordOps.clearUserCache(targetUserId);
      _logDebug('🔄 已清除用戶快取: $targetUserId');
    } else {
      _logDebug('⚠️ 無法清除快取：沒有指定 userId 且當前未登入');
    }
  }

  @override
  Future<List<WorkoutRecord>> checkTimeOverlap({
    required String traineeId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeRecordId,
  }) async {
    _ensureInitialized();
    
    try {
      _logDebug('檢查時間重疊: traineeId=$traineeId, $startTime - $endTime');

      // ⭐ 使用 DateTimeUtils 格式化時間範圍
      final queryRange = DateTimeUtils.formatToTstzRange(startTime, endTime);
      
      // ⭐ 查詢重疊的訓練計畫（使用 PostgreSQL 範圍重疊運算子 &&）
      var query = _supabase
          .from('workout_plans')
          .select('id, trainee_id, creator_id, title, scheduled_date, completed, training_time, training_time_range, exercises, note, created_at, updated_at')
          .eq('trainee_id', traineeId)
          .filter('training_time_range', 'ov', queryRange);  // ⭐ 範圍重疊檢查
      
      // 排除特定記錄（編輯時使用）
      if (excludeRecordId != null) {
        query = query.neq('id', excludeRecordId);
      }
      
      final response = await query;
      
      final overlappingRecords = (response as List)
          .map((data) => WorkoutRecord.fromSupabase(data))
          .toList();
      
      _logDebug('找到 ${overlappingRecords.length} 個重疊的訓練計畫');
      
      return overlappingRecords;
    } catch (e) {
      _logError('檢查時間重疊失敗: $e');
      return [];
    }
  }

  @override
  Future<List<ExerciseHistoryRecord>> getExerciseHistory({
    required String userId,
    required String exerciseId,
    int limit = 10,
  }) async {
    _ensureInitialized();
    
    try {
      _logDebug('查詢動作歷史: userId=$userId, exerciseId=$exerciseId');

      // 查詢已完成的訓練計畫，包含該動作
      // 使用 JSONB 查詢，找出 exercises 陣列中包含該 exerciseId 的記錄
      final response = await _supabase
          .from('workout_plans')
          .select('id, title, scheduled_date, exercises')
          .eq('trainee_id', userId)
          .eq('completed', true)
          .order('scheduled_date', ascending: false)
          .limit(limit * 2);  // 多取一些，因為不是每個都包含該動作

      final records = <ExerciseHistoryRecord>[];
      
      for (final data in response as List) {
        final exercises = data['exercises'] as List? ?? [];
        
        // 找到該動作的記錄
        for (final exercise in exercises) {
          if (exercise['exercise_id'] == exerciseId || 
              exercise['id'] == exerciseId) {
            // 解析每組數據
            final setTargets = exercise['set_targets'] as List? ?? [];
            final sets = <SetRecord>[];
            
            for (var i = 0; i < setTargets.length; i++) {
              final target = setTargets[i] as Map<String, dynamic>;
              sets.add(SetRecord(
                setNumber: i + 1,
                reps: (target['reps'] as num?)?.toInt() ?? 0,
                weight: (target['weight'] as num?)?.toDouble() ?? 0,
                restTime: (target['rest_time'] as num?)?.toInt() ?? 90,
                completed: target['completed'] as bool? ?? true,
                // v3.2+ 新增欄位
                time: (target['time'] as num?)?.toInt(),
                distance: (target['distance'] as num?)?.toDouble(),
                calories: (target['calories'] as num?)?.toDouble(),
              ));
            }
            
            // 如果沒有 set_targets，使用預設值
            if (sets.isEmpty) {
              final defaultSets = (exercise['sets'] as num?)?.toInt() ?? 3;
              final defaultReps = (exercise['reps'] as num?)?.toInt() ?? 10;
              final defaultWeight = (exercise['weight'] as num?)?.toDouble() ?? 0;
              
              for (var i = 0; i < defaultSets; i++) {
                sets.add(SetRecord(
                  setNumber: i + 1,
                  reps: defaultReps,
                  weight: defaultWeight,
                  restTime: 90,
                  completed: true,
                ));
              }
            }
            
            records.add(ExerciseHistoryRecord(
              workoutRecordId: data['id'] as String,
              exerciseId: exerciseId,
              exerciseName: exercise['name'] as String? ?? '未知動作',
              trainingDate: DateTimeUtils.parseIsoTimestamp(data['scheduled_date']),
              sets: sets,
              // v3.2+ 追蹤模式
              trackingMode: TrackingModeExtension.fromJson(
                exercise['trackingMode'] as String?,
              ),
            ));
            
            break;  // 每個訓練計畫只取一個該動作
          }
        }
        
        // 達到限制數量就停止
        if (records.length >= limit) break;
      }
      
      _logDebug('找到 ${records.length} 筆動作歷史記錄');
      return records;
    } catch (e) {
      _logError('查詢動作歷史失敗: $e');
      return [];
    }
  }
}
