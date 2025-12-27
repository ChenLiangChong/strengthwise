import '../../models/workout_template_model.dart';
import '../../models/workout_record_model.dart';

/// 訓練計劃緩存管理器
///
/// 負責管理訓練模板和記錄的記憶體緩存
class WorkoutCacheManager {
  // 數據緩存
  List<WorkoutTemplate>? templatesCache;
  List<WorkoutRecord>? recordsCache;
  
  // 緩存刷新時間
  final Map<String, DateTime> _lastRefreshTime = {};
  
  /// 緩存過期時間（分鐘）
  static const int cacheExpirationMinutes = 5;
  
  /// 檢查是否需要刷新模板緩存
  bool shouldRefreshTemplates() {
    final lastRefresh = _lastRefreshTime['templates'];
    if (lastRefresh == null || templatesCache == null) return true;
    
    final now = DateTime.now();
    return now.difference(lastRefresh).inMinutes > cacheExpirationMinutes;
  }
  
  /// 檢查是否需要刷新記錄緩存
  bool shouldRefreshRecords() {
    final lastRefresh = _lastRefreshTime['records'];
    if (lastRefresh == null || recordsCache == null) return true;
    
    final now = DateTime.now();
    return now.difference(lastRefresh).inMinutes > cacheExpirationMinutes;
  }
  
  /// 更新模板緩存
  void updateTemplatesCache(List<WorkoutTemplate> templates) {
    templatesCache = templates;
    _lastRefreshTime['templates'] = DateTime.now();
  }
  
  /// 更新記錄緩存
  void updateRecordsCache(List<WorkoutRecord> records) {
    recordsCache = records;
    _lastRefreshTime['records'] = DateTime.now();
  }
  
  /// 從模板緩存中查找
  WorkoutTemplate? findTemplateInCache(String templateId) {
    if (templatesCache == null) return null;
    
    return templatesCache!
        .where((t) => t.id == templateId)
        .firstOrNull;
  }
  
  /// 從記錄緩存中查找
  WorkoutRecord? findRecordInCache(String recordId) {
    if (recordsCache == null) return null;
    
    return recordsCache!
        .where((r) => r.id == recordId)
        .firstOrNull;
  }
  
  /// 在緩存中添加模板
  void addTemplateToCache(WorkoutTemplate template) {
    if (templatesCache != null) {
      templatesCache = [...templatesCache!, template];
    }
  }
  
  /// 在緩存中添加記錄
  void addRecordToCache(WorkoutRecord record) {
    if (recordsCache != null) {
      recordsCache = [...recordsCache!, record];
    }
  }
  
  /// 在緩存中更新模板
  void updateTemplateInCache(WorkoutTemplate template) {
    if (templatesCache != null) {
      templatesCache = templatesCache!.map((t) => 
        t.id == template.id ? template : t
      ).toList();
    }
  }
  
  /// 在緩存中更新記錄
  void updateRecordInCache(WorkoutRecord record) {
    if (recordsCache != null) {
      recordsCache = recordsCache!.map((r) => 
        r.id == record.id ? record : r
      ).toList();
    }
  }
  
  /// 從緩存中刪除模板
  void removeTemplateFromCache(String templateId) {
    if (templatesCache != null) {
      templatesCache = templatesCache!
          .where((t) => t.id != templateId)
          .toList();
    }
  }
  
  /// 從緩存中刪除記錄
  void removeRecordFromCache(String recordId) {
    if (recordsCache != null) {
      recordsCache = recordsCache!
          .where((r) => r.id != recordId)
          .toList();
    }
  }
  
  /// 清除所有模板緩存
  void clearTemplatesCache() {
    templatesCache = null;
    _lastRefreshTime.remove('templates');
  }
  
  /// 清除所有記錄緩存
  void clearRecordsCache() {
    recordsCache = null;
    _lastRefreshTime.remove('records');
  }
  
  /// 清除所有緩存
  void clearAllCache() {
    templatesCache = null;
    recordsCache = null;
    _lastRefreshTime.clear();
  }
}

