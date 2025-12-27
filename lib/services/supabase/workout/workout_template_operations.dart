import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/workout_template_model.dart';
import '_workout_cache_manager.dart';

/// 訓練模板操作類別
/// 
/// 負責訓練模板的 CRUD 操作
class WorkoutTemplateOperations {
  final SupabaseClient _supabase;
  final WorkoutCacheManager _cacheManager;
  final Function(String) _logDebug;
  final Function(String) _logError;
  final bool _cacheTemplates;

  WorkoutTemplateOperations({
    required SupabaseClient supabase,
    required WorkoutCacheManager cacheManager,
    required Function(String) logDebug,
    required Function(String) logError,
    required bool cacheTemplates,
  })  : _supabase = supabase,
        _cacheManager = cacheManager,
        _logDebug = logDebug,
        _logError = logError,
        _cacheTemplates = cacheTemplates;

  /// 獲取用戶訓練模板列表（Cursor 分頁）
  Future<List<WorkoutTemplate>> getUserTemplates({
    required String userId,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      // ⚡ 優化：檢查模板列表快取（5 分鐘內）
      if (cursor == null && _cacheTemplates) {
        if (_cacheManager.isTemplatesListCacheValid(userId)) {
          final cached = _cacheManager.templatesListCache;
          if (cached != null) {
            _logDebug('⚡ 從快取返回 ${cached.length} 個模板');
            return limit >= cached.length ? cached : cached.sublist(0, limit);
          }
        }
      }

      _logDebug('獲取用戶訓練模板，userId: $userId, cursor: $cursor, limit: $limit');

      // ⚡ 優化：使用 Cursor-based 分頁（基於 updated_at 欄位）
      var queryBuilder = _supabase
          .from('workout_templates')
          .select(
              'id, title, description, plan_type, exercises, training_time, updated_at, user_id, created_at')
          .eq('user_id', userId);

      // 如果提供了游標，查詢比游標更舊的記錄
      if (cursor != null && cursor.isNotEmpty) {
        queryBuilder = queryBuilder.lt('updated_at', cursor);
        _logDebug('使用游標: $cursor（查詢更早的記錄）');
      }

      // 排序並限制返回數量
      final response =
          await queryBuilder.order('updated_at', ascending: false).limit(limit);

      final templates =
          (response as List).map((data) => WorkoutTemplate.fromSupabase(data)).toList();

      // 更新緩存
      if (_cacheTemplates) {
        for (final template in templates) {
          _cacheManager.setTemplate(template.id, template);
        }

        // ⚡ 如果是首次查詢（無 cursor），快取結果
        if (cursor == null && templates.isNotEmpty) {
          _cacheManager.updateTemplatesListCache(userId, templates);
          _logDebug('⚡ 已快取 ${templates.length} 個訓練模板（5 分鐘有效）');
        }
      }

      _logDebug('成功獲取 ${templates.length} 個訓練模板');

      // 如果有結果，打印下一頁的游標（最後一筆的 updated_at）
      if (templates.isNotEmpty) {
        final nextCursor = templates.last.updatedAt.toIso8601String();
        _logDebug('下一頁游標: $nextCursor');
      }

      return templates;
    } catch (e) {
      _logError('獲取訓練模板失敗: $e');
      return [];
    }
  }

  /// 獲取單個訓練模板詳情
  Future<WorkoutTemplate?> getTemplateById(String templateId) async {
    try {
      // 首先檢查緩存
      if (_cacheTemplates) {
        final cached = _cacheManager.getTemplate(templateId);
        if (cached != null) {
          _logDebug('從緩存獲取模板: $templateId');
          return cached;
        }
      }

      _logDebug('從數據庫獲取模板: $templateId');

      // 優化：詳情頁需要完整欄位（包含 exercises）
      final response = await _supabase
          .from('workout_templates')
          .select(
              'id, user_id, title, description, plan_type, exercises, training_time, created_at, updated_at')
          .eq('id', templateId)
          .single();

      final template = WorkoutTemplate.fromSupabase(response);

      // 更新緩存
      if (_cacheTemplates) {
        _cacheManager.setTemplate(templateId, template);
      }

      return template;
    } catch (e) {
      _logError('獲取訓練模板詳情失敗: $e');
      return null;
    }
  }

  /// 創建訓練模板
  Future<WorkoutTemplate> createTemplate({
    required String userId,
    required WorkoutTemplate template,
    required String Function() generateId,
  }) async {
    try {
      _logDebug('創建新的訓練模板');

      // 生成新的 ID（使用 Firestore 兼容格式）
      final newId = generateId();

      // 準備數據（使用 snake_case）
      final templateData = {
        'id': newId, // 明確指定 ID
        'user_id': userId,
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

      // ⚡ Optimistic Update：同步更新快取
      if (_cacheTemplates) {
        _cacheManager.addTemplate(userId, newTemplate);
        _logDebug('⚡ 已同步更新模板快取');
      }

      _logDebug('訓練模板創建成功: ${newTemplate.id}');
      return newTemplate;
    } catch (e) {
      _logError('創建訓練模板失敗: $e');
      rethrow;
    }
  }

  /// 更新訓練模板
  Future<bool> updateTemplate({
    required String userId,
    required WorkoutTemplate template,
  }) async {
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
          .eq('user_id', userId);

      // ⚡ Optimistic Update：同步更新快取
      if (_cacheTemplates) {
        _cacheManager.updateTemplate(userId, template);
        _logDebug('⚡ 已同步更新模板快取');
      }

      _logDebug('訓練模板更新成功');
      return true;
    } catch (e) {
      _logError('更新訓練模板失敗: $e');
      return false;
    }
  }

  /// 刪除訓練模板
  Future<bool> deleteTemplate({
    required String userId,
    required String templateId,
  }) async {
    try {
      _logDebug('刪除訓練模板: $templateId');

      await _supabase
          .from('workout_templates')
          .delete()
          .eq('id', templateId)
          .eq('user_id', userId);

      // ⚡ Optimistic Update：同步更新快取
      if (_cacheTemplates) {
        _cacheManager.removeTemplate(userId, templateId);
        _logDebug('⚡ 已同步更新模板快取');
      }

      _logDebug('訓練模板刪除成功');
      return true;
    } catch (e) {
      _logError('刪除訓練模板失敗: $e');
      return false;
    }
  }
}

