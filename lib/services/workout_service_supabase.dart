import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/workout_template_model.dart';
import '../models/workout_record_model.dart';
import 'interfaces/i_workout_service.dart';
import 'error_handling_service.dart';
import 'service_locator.dart' show Environment;

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

  // 緩存系統
  final Map<String, WorkoutTemplate> _templateCache = {};
  final Map<String, WorkoutRecord> _recordCache = {};
  Timer? _cacheClearTimer;

  /// 創建服務實例
  WorkoutServiceSupabase({
    SupabaseClient? supabase,
    ErrorHandlingService? errorService,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _errorService = errorService;

  /// 初始化服務
  Future<void> initialize({Environment environment = Environment.development}) async {
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

      _templateCache.clear();
      _recordCache.clear();

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
    _templateCache.clear();
    _recordCache.clear();
  }

  // 獲取當前用戶ID
  String? get currentUserId {
    _ensureInitialized();
    return _supabase.auth.currentUser?.id;
  }

  @override
  Future<List<WorkoutTemplate>> getUserTemplates() async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logDebug('獲取用戶模板：沒有登入用戶');
      return [];
    }

    try {
      _logDebug('獲取用戶訓練模板');

      // 從 workout_templates 表查詢
      final response = await _supabase
          .from('workout_templates')
          .select()
          .eq('user_id', currentUserId!)
          .order('updated_at', ascending: false);

      final templates = (response as List)
          .map((data) => WorkoutTemplate.fromSupabase(data))
          .toList();

      // 更新緩存
      if (_cacheTemplates) {
        for (final template in templates) {
          _templateCache[template.id] = template;
        }
      }

      _logDebug('成功獲取 ${templates.length} 個訓練模板');
      return templates;
    } catch (e) {
      _logError('獲取訓練模板失敗: $e');
      return [];
    }
  }

  @override
  Future<WorkoutTemplate?> getTemplateById(String templateId) async {
    _ensureInitialized();

    try {
      // 首先檢查緩存
      if (_cacheTemplates && _templateCache.containsKey(templateId)) {
        _logDebug('從緩存獲取模板: $templateId');
        return _templateCache[templateId];
      }

      _logDebug('從數據庫獲取模板: $templateId');

      final response = await _supabase
          .from('workout_templates')
          .select()
          .eq('id', templateId)
          .single();

      final template = WorkoutTemplate.fromSupabase(response);

      // 更新緩存
      if (_cacheTemplates) {
        _templateCache[templateId] = template;
      }

      return template;
    } catch (e) {
      _logError('獲取訓練模板詳情失敗: $e');
      return null;
    }
  }

  @override
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logError('創建模板失敗：沒有登入用戶');
      throw Exception('用戶未登入');
    }

    try {
      _logDebug('創建新的訓練模板');

      // 生成新的 ID（使用 Firestore 兼容格式）
      final newId = _generateFirestoreId();
      
      // 準備數據（使用 snake_case）
      final templateData = {
        'id': newId,  // 明確指定 ID
        'user_id': currentUserId,
        'title': template.title,
        'description': template.description,
        'plan_type': template.planType,
        'exercises': template.exercises.map((e) => e.toJson()).toList(),
        'training_time': template.trainingTime?.toIso8601String(),
      };

      final response = await _supabase
          .from('workout_templates')
          .insert(templateData)
          .select()
          .single();

      final newTemplate = WorkoutTemplate.fromSupabase(response);

      // 更新緩存
      if (_cacheTemplates) {
        _templateCache[newTemplate.id] = newTemplate;
      }

      _logDebug('訓練模板創建成功: ${newTemplate.id}');
      return newTemplate;
    } catch (e) {
      _logError('創建訓練模板失敗: $e');
      rethrow;
    }
  }

  @override
  Future<bool> updateTemplate(WorkoutTemplate template) async {
    _ensureInitialized();

    try {
      _logDebug('更新訓練模板: ${template.id}');

      final templateData = {
        'title': template.title,
        'description': template.description,
        'plan_type': template.planType,
        'exercises': template.exercises.map((e) => e.toJson()).toList(),
        'training_time': template.trainingTime?.toIso8601String(),
      };

      await _supabase
          .from('workout_templates')
          .update(templateData)
          .eq('id', template.id)
          .eq('user_id', currentUserId!);

      // 更新緩存
      if (_cacheTemplates) {
        _templateCache[template.id] = template;
      }

      _logDebug('訓練模板更新成功');
      return true;
    } catch (e) {
      _logError('更新訓練模板失敗: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteTemplate(String templateId) async {
    _ensureInitialized();

    try {
      _logDebug('刪除訓練模板: $templateId');

      await _supabase
          .from('workout_templates')
          .delete()
          .eq('id', templateId)
          .eq('user_id', currentUserId!);

      // 從緩存中移除
      if (_cacheTemplates) {
        _templateCache.remove(templateId);
      }

      _logDebug('訓練模板刪除成功');
      return true;
    } catch (e) {
      _logError('刪除訓練模板失敗: $e');
      return false;
    }
  }

  @override
  Future<List<WorkoutRecord>> getUserRecords() async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logDebug('獲取用戶記錄：沒有登入用戶');
      return [];
    }

    try {
      _logDebug('從 workout_plans 獲取用戶已完成的訓練記錄');

      // 查詢已完成的訓練計劃（completed=true）
      final response = await _supabase
          .from('workout_plans')
          .select()
          .eq('trainee_id', currentUserId!)
          .eq('completed', true)
          .order('completed_date', ascending: false);

      final records = (response as List)
          .map((data) => WorkoutRecord.fromSupabase(data))
          .toList();

      // 更新緩存
      if (_cacheRecords) {
        for (final record in records) {
          _recordCache[record.id] = record;
        }
      }

      _logDebug('成功獲取 ${records.length} 個訓練記錄');
      return records;
    } catch (e) {
      _logError('獲取訓練記錄失敗: $e');
      return [];
    }
  }

  @override
  Future<List<WorkoutRecord>> getUserPlans({
    bool? completed,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logDebug('獲取用戶計劃：沒有登入用戶');
      return [];
    }

    try {
      _logDebug('從 workout_plans 獲取用戶訓練計劃 (completed: $completed, startDate: $startDate, endDate: $endDate)');

      // 構建查詢
      var query = _supabase
          .from('workout_plans')
          .select()
          .eq('trainee_id', currentUserId!);

      // 篩選完成狀態
      if (completed != null) {
        query = query.eq('completed', completed);
      }

      // 篩選日期範圍
      if (startDate != null) {
        query = query.gte('scheduled_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lt('scheduled_date', endDate.toIso8601String());
      }

      // 執行查詢並排序
      final response = await query.order('scheduled_date', ascending: completed == false);

      final plans = (response as List)
          .map((data) => WorkoutRecord.fromSupabase(data))
          .toList();

      _logDebug('成功獲取 ${plans.length} 個訓練計劃');
      return plans;
    } catch (e) {
      _logError('獲取訓練計劃失敗: $e');
      return [];
    }
  }

  @override
  Future<WorkoutRecord?> getRecordById(String recordId) async {
    _ensureInitialized();

    try {
      // 首先檢查緩存
      if (_cacheRecords && _recordCache.containsKey(recordId)) {
        _logDebug('從緩存獲取記錄: $recordId');
        return _recordCache[recordId];
      }

      _logDebug('從 workout_plans 獲取記錄: $recordId');

      final response = await _supabase
          .from('workout_plans')
          .select()
          .eq('id', recordId)
          .single();

      final record = WorkoutRecord.fromSupabase(response);

      // 更新緩存
      if (_cacheRecords) {
        _recordCache[recordId] = record;
      }

      return record;
    } catch (e) {
      _logError('獲取訓練記錄詳情失敗: $e');
      return null;
    }
  }

  @override
  Future<WorkoutRecord> createRecord(WorkoutRecord record) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logError('創建記錄失敗：沒有登入用戶');
      throw Exception('用戶未登入');
    }

    try {
      _logDebug('創建新的訓練記錄: ${record.title}');

      // 生成新的 ID（使用 Firestore 兼容格式）
      final newId = _generateFirestoreId();
      
      // 準備數據（存入 workout_plans 表，completed=true）
      final recordData = {
        'id': newId,  // 明確指定 ID
        'user_id': currentUserId,
        'trainee_id': currentUserId,
        'creator_id': currentUserId,
        'title': record.title,  // 使用記錄的標題
        'plan_type': 'self',
        'scheduled_date': record.date.toIso8601String(),
        'completed_date': record.completed ? DateTime.now().toIso8601String() : null,
        'training_time': record.trainingTime?.toIso8601String(),
        'exercises': record.exerciseRecords.map((e) => e.toJson()).toList(),
        'completed': record.completed,
        'note': record.notes,
      };

      final response = await _supabase
          .from('workout_plans')
          .insert(recordData)
          .select()
          .single();

      final newRecord = WorkoutRecord.fromSupabase(response);

      // 更新緩存
      if (_cacheRecords) {
        _recordCache[newRecord.id] = newRecord;
      }

      _logDebug('訓練記錄創建成功: ${newRecord.id}');
      return newRecord;
    } catch (e) {
      _logError('創建訓練記錄失敗: $e');
      rethrow;
    }
  }

  @override
  Future<bool> updateRecord(WorkoutRecord record) async {
    _ensureInitialized();

    try {
      _logDebug('更新訓練記錄: ${record.id}');

      final recordData = {
        'scheduled_date': record.date.toIso8601String(),
        'completed_date': record.completed ? DateTime.now().toIso8601String() : null,
        'training_time': record.trainingTime?.toIso8601String(),
        'exercises': record.exerciseRecords.map((e) => e.toJson()).toList(),
        'completed': record.completed,
        'note': record.notes,
      };

      await _supabase
          .from('workout_plans')
          .update(recordData)
          .eq('id', record.id)
          .eq('trainee_id', currentUserId!);

      // 更新緩存
      if (_cacheRecords) {
        _recordCache[record.id] = record;
      }

      _logDebug('訓練記錄更新成功');
      return true;
    } catch (e) {
      _logError('更新訓練記錄失敗: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteRecord(String recordId) async {
    _ensureInitialized();

    try {
      _logDebug('刪除訓練記錄: $recordId');

      await _supabase
          .from('workout_plans')
          .delete()
          .eq('id', recordId)
          .eq('trainee_id', currentUserId!);

      // 從緩存中移除
      if (_cacheRecords) {
        _recordCache.remove(recordId);
      }

      _logDebug('訓練記錄刪除成功');
      return true;
    } catch (e) {
      _logError('刪除訓練記錄失敗: $e');
      return false;
    }
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
        title: template.title,  // 使用模板的標題
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

  /// 生成 Firestore 兼容格式的 ID
  String _generateFirestoreId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    
    // 生成 20 個字符的隨機 ID（類似 Firestore）
    for (int i = 0; i < 20; i++) {
      buffer.write(chars[(random + i) % chars.length]);
    }
    
    return buffer.toString();
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

