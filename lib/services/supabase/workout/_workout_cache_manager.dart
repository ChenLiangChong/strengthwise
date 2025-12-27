import '../../../models/workout_template_model.dart';
import '../../../models/workout_record_model.dart';

/// 內部快取管理器（簡化版，避免循環依賴）
class WorkoutCacheManager {
  final Map<String, WorkoutTemplate> _templateCache = {};
  final Map<String, WorkoutRecord> _recordCache = {};
  
  List<WorkoutRecord>? _allPlansCache;
  DateTime? _allPlansCacheTime;
  String? _allPlansCachedUserId;
  
  List<WorkoutRecord>? _completedRecordsCache;
  DateTime? _completedRecordsCacheTime;
  String? _completedRecordsCachedUserId;
  
  List<WorkoutTemplate>? _templatesListCache;
  DateTime? _templatesListCacheTime;
  String? _templatesListCachedUserId;

  bool isTemplatesListCacheValid(String userId) {
    if (_templatesListCache == null || 
        _templatesListCachedUserId != userId ||
        _templatesListCacheTime == null) return false;
    return DateTime.now().difference(_templatesListCacheTime!).inMinutes < 5;
  }

  List<WorkoutTemplate>? get templatesListCache => _templatesListCache;
  
  void updateTemplatesListCache(String userId, List<WorkoutTemplate> templates) {
    _templatesListCache = templates;
    _templatesListCacheTime = DateTime.now();
    _templatesListCachedUserId = userId;
    for (final template in templates) {
      _templateCache[template.id] = template;
    }
  }

  WorkoutTemplate? getTemplate(String id) => _templateCache[id];
  
  void setTemplate(String id, WorkoutTemplate template) {
    _templateCache[id] = template;
  }

  void addTemplate(String userId, WorkoutTemplate template) {
    _templateCache[template.id] = template;
    if (_templatesListCache != null && _templatesListCachedUserId == userId) {
      _templatesListCache!.insert(0, template);
    }
  }

  void updateTemplate(String userId, WorkoutTemplate template) {
    _templateCache[template.id] = template;
    if (_templatesListCache != null && _templatesListCachedUserId == userId) {
      final index = _templatesListCache!.indexWhere((t) => t.id == template.id);
      if (index != -1) _templatesListCache![index] = template;
    }
  }

  void removeTemplate(String userId, String templateId) {
    _templateCache.remove(templateId);
    if (_templatesListCache != null && _templatesListCachedUserId == userId) {
      _templatesListCache!.removeWhere((t) => t.id == templateId);
    }
  }

  bool isCompletedRecordsCacheValid(String userId) {
    if (_completedRecordsCache == null ||
        _completedRecordsCachedUserId != userId ||
        _completedRecordsCacheTime == null) return false;
    return DateTime.now().difference(_completedRecordsCacheTime!).inMinutes < 5;
  }

  List<WorkoutRecord>? get completedRecordsCache => _completedRecordsCache;

  void updateCompletedRecordsCache(String userId, List<WorkoutRecord> records) {
    _completedRecordsCache = records;
    _completedRecordsCacheTime = DateTime.now();
    _completedRecordsCachedUserId = userId;
    for (final record in records) {
      _recordCache[record.id] = record;
    }
  }

  bool isAllPlansCacheValid(String userId) {
    if (_allPlansCache == null ||
        _allPlansCachedUserId != userId ||
        _allPlansCacheTime == null) return false;
    return DateTime.now().difference(_allPlansCacheTime!).inMinutes < 5;
  }

  List<WorkoutRecord>? get allPlansCache => _allPlansCache;

  void updateAllPlansCache(String userId, List<WorkoutRecord> plans) {
    _allPlansCache = plans;
    _allPlansCacheTime = DateTime.now();
    _allPlansCachedUserId = userId;
  }

  WorkoutRecord? getRecord(String id) => _recordCache[id];

  void setRecord(String id, WorkoutRecord record) {
    _recordCache[id] = record;
  }

  void addRecord(String userId, WorkoutRecord record) {
    _recordCache[record.id] = record;
    if (_allPlansCache != null && _allPlansCachedUserId == userId) {
      _allPlansCache!.insert(0, record);
    }
    if (record.completed && 
        _completedRecordsCache != null &&
        _completedRecordsCachedUserId == userId) {
      _completedRecordsCache!.insert(0, record);
    }
  }

  void updateRecord(String userId, WorkoutRecord record) {
    _recordCache[record.id] = record;
    if (_allPlansCache != null && _allPlansCachedUserId == userId) {
      final index = _allPlansCache!.indexWhere((r) => r.id == record.id);
      if (index != -1) _allPlansCache![index] = record;
    }
    if (_completedRecordsCache != null && _completedRecordsCachedUserId == userId) {
      final index = _completedRecordsCache!.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _completedRecordsCache![index] = record;
      } else if (record.completed) {
        _completedRecordsCache!.insert(0, record);
      }
    }
  }

  void removeRecord(String userId, String recordId) {
    _recordCache.remove(recordId);
    if (_allPlansCache != null && _allPlansCachedUserId == userId) {
      _allPlansCache!.removeWhere((r) => r.id == recordId);
    }
    if (_completedRecordsCache != null && _completedRecordsCachedUserId == userId) {
      _completedRecordsCache!.removeWhere((r) => r.id == recordId);
    }
  }

  void clearAll() {
    _templateCache.clear();
    _recordCache.clear();
    _allPlansCache = null;
    _allPlansCacheTime = null;
    _allPlansCachedUserId = null;
    _completedRecordsCache = null;
    _completedRecordsCacheTime = null;
    _completedRecordsCachedUserId = null;
    _templatesListCache = null;
    _templatesListCacheTime = null;
    _templatesListCachedUserId = null;
  }
}

