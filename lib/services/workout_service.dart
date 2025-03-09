import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/workout_template_model.dart';
import '../models/workout_record_model.dart';
import 'interfaces/i_workout_service.dart';
import 'error_handling_service.dart';
import 'service_locator.dart' show Environment;

/// 訓練計畫服務的Firebase實現
/// 
/// 提供訓練模板管理、訓練記錄追蹤和從模板創建記錄等功能
/// 支持環境配置，統一錯誤處理與資源管理，以及模板和記錄的緩存
class WorkoutService implements IWorkoutService {
  // 依賴注入
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ErrorHandlingService _errorService;
  
  // 服務狀態
  bool _isInitialized = false;
  Environment _environment = Environment.development;
  
  // 服務配置
  bool _cacheTemplates = true;
  bool _cacheRecords = true;
  int _recordCacheLimit = 50;
  int _templateCacheLimit = 20;
  
  // 緩存系統
  final Map<String, WorkoutTemplate> _templateCache = {};
  final Map<String, WorkoutRecord> _recordCache = {};
  Timer? _cacheClearTimer;
  
  /// 創建服務實例
  /// 
  /// 允許注入自定義的Firestore和Auth實例，便於測試
  WorkoutService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ErrorHandlingService? errorService,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _auth = auth ?? FirebaseAuth.instance,
    _errorService = errorService ?? ErrorHandlingService();
  
  /// 初始化服務
  /// 
  /// 設置環境配置並初始化緩存系統
  Future<void> initialize({Environment environment = Environment.development}) async {
    if (_isInitialized) return;
    
    try {
      // 設置環境
      configureForEnvironment(environment);
      
      // 設置緩存清理計時器（每三小時）
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
      // 取消緩存清理計時器
      _cacheClearTimer?.cancel();
      _cacheClearTimer = null;
      
      // 清空緩存
      _templateCache.clear();
      _recordCache.clear();
      
      // 其他資源清理
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
        // 開發環境設置
        _cacheTemplates = true;
        _cacheRecords = true;
        _recordCacheLimit = 50;
        _templateCacheLimit = 20;
        _logDebug('訓練計畫服務配置為開發環境');
        break;
      case Environment.testing:
        // 測試環境設置
        _cacheTemplates = false;
        _cacheRecords = false;
        _logDebug('訓練計畫服務配置為測試環境');
        break;
      case Environment.production:
        // 生產環境設置 - 使用更嚴格的緩存限制
        _cacheTemplates = true;
        _cacheRecords = true;
        _recordCacheLimit = 30;
        _templateCacheLimit = 10;
        _logDebug('訓練計畫服務配置為生產環境');
        break;
    }
  }
  
  /// 設置緩存清理計時器
  void _setupCacheCleanupTimer() {
    _cacheClearTimer?.cancel();
    // 每三小時清理一次緩存
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
  
  /// 管理記錄緩存大小
  void _manageRecordCacheSize() {
    if (_recordCache.length > _recordCacheLimit) {
      _logDebug('記錄緩存超出限制 (${_recordCache.length}/${_recordCacheLimit})，進行清理');
      
      // 保留最近使用的記錄，刪除多餘的
      final keysToRemove = _recordCache.keys.toList().sublist(0, _recordCache.length - _recordCacheLimit);
      for (final key in keysToRemove) {
        _recordCache.remove(key);
      }
      
      _logDebug('記錄緩存清理完成，當前緩存大小: ${_recordCache.length}');
    }
  }
  
  /// 管理模板緩存大小
  void _manageTemplateCacheSize() {
    if (_templateCache.length > _templateCacheLimit) {
      _logDebug('模板緩存超出限制 (${_templateCache.length}/${_templateCacheLimit})，進行清理');
      
      // 保留最近使用的模板，刪除多餘的
      final keysToRemove = _templateCache.keys.toList().sublist(0, _templateCache.length - _templateCacheLimit);
      for (final key in keysToRemove) {
        _templateCache.remove(key);
      }
      
      _logDebug('模板緩存清理完成，當前緩存大小: ${_templateCache.length}');
    }
  }
  
  // 獲取當前用戶ID
  String? get currentUserId {
    _ensureInitialized();
    return _auth.currentUser?.uid;
  }
  
  // 獲取訓練模板集合引用
  CollectionReference get _templatesRef => _firestore.collection('workoutTemplates');
  
  // 獲取訓練記錄集合引用
  CollectionReference get _recordsRef => _firestore.collection('workoutRecords');
  
  @override
  Future<List<WorkoutTemplate>> getUserTemplates() async {
    _ensureInitialized();
    
    if (currentUserId == null) {
      _logDebug('獲取用戶模板：沒有登入用戶');
      return [];
    }
    
    try {
      _logDebug('獲取用戶訓練模板');
      final querySnapshot = await _templatesRef
          .where('userId', isEqualTo: currentUserId)
          .orderBy('updatedAt', descending: true)
          .get();
      
      final templates = querySnapshot.docs
          .map((doc) => WorkoutTemplate.fromFirestore(doc))
          .toList();
      
      // 更新緩存
      if (_cacheTemplates) {
        for (final template in templates) {
          _templateCache[template.id] = template;
        }
        _manageTemplateCacheSize();
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
      final docSnapshot = await _templatesRef.doc(templateId).get();
      if (!docSnapshot.exists) {
        _logDebug('模板不存在: $templateId');
        return null;
      }
      
      final template = WorkoutTemplate.fromFirestore(docSnapshot);
      
      // 更新緩存
      if (_cacheTemplates) {
        _templateCache[templateId] = template;
        _manageTemplateCacheSize();
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
      final templateData = template.toJson();
      final docRef = await _templatesRef.add(templateData);
      
      final newTemplate = template.copyWith(id: docRef.id);
      
      // 更新緩存
      if (_cacheTemplates) {
        _templateCache[newTemplate.id] = newTemplate;
        _manageTemplateCacheSize();
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
      await _templatesRef.doc(template.id).update(template.toJson());
      
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
      await _templatesRef.doc(templateId).delete();
      
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
      _logDebug('獲取用戶訓練記錄');
      final querySnapshot = await _recordsRef
          .where('userId', isEqualTo: currentUserId)
          .orderBy('date', descending: true)
          .get();
      
      final records = querySnapshot.docs
          .map((doc) => WorkoutRecord.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // 更新緩存
      if (_cacheRecords) {
        for (final record in records) {
          _recordCache[record.id] = record;
        }
        _manageRecordCacheSize();
      }
      
      _logDebug('成功獲取 ${records.length} 個訓練記錄');
      return records;
    } catch (e) {
      _logError('獲取訓練記錄失敗: $e');
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
      
      _logDebug('從數據庫獲取記錄: $recordId');
      final docSnapshot = await _recordsRef.doc(recordId).get();
      if (!docSnapshot.exists) {
        _logDebug('記錄不存在: $recordId');
        return null;
      }
      
      final record = WorkoutRecord.fromFirestore(docSnapshot.data() as Map<String, dynamic>, recordId);
      
      // 更新緩存
      if (_cacheRecords) {
        _recordCache[recordId] = record;
        _manageRecordCacheSize();
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
      _logDebug('創建新的訓練記錄');
      final recordData = record.toJson();
      final docRef = await _recordsRef.add(recordData);
      
      // 獲取完整的記錄，包括自動生成的字段
      final newRecord = await getRecordById(docRef.id) ?? record;
      
      // 更新緩存
      if (_cacheRecords) {
        _recordCache[newRecord.id] = newRecord;
        _manageRecordCacheSize();
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
      await _recordsRef.doc(record.id).update(record.toJson());
      
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
      await _recordsRef.doc(recordId).delete();
      
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
      _logDebug('從模板 $templateId 創建訓練記錄');
      
      // 獲取模板詳情
      final template = await getTemplateById(templateId);
      if (template == null) {
        _logError('訓練模板不存在: $templateId');
        throw Exception('訓練模板不存在');
      }
      
      // 從模板創建記錄
      final templateData = template.toJson();
      final record = WorkoutRecord.fromWorkoutPlan(
        currentUserId!,
        templateId,
        templateData,
      );
      
      _logDebug('從模板成功創建記錄對象，準備保存到數據庫');
      
      // 保存記錄到數據庫
      return await createRecord(record);
    } catch (e) {
      _logError('從模板創建訓練記錄失敗: $e');
      rethrow;
    }
  }
  
  /// 確保服務已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      _logDebug('警告: 訓練計畫服務在初始化前被調用');
      // 在開發環境中自動初始化，但在其他環境拋出錯誤
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
      print('[WORKOUT] $message');
    }
  }
  
  /// 記錄錯誤信息
  void _logError(String message) {
    // 首先記錄到控制台（僅在調試模式）
    if (kDebugMode) {
      print('[WORKOUT ERROR] $message');
    }
    
    // 使用錯誤處理服務記錄錯誤
    _errorService.logError(message);
  }
} 