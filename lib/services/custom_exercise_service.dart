import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/custom_exercise_model.dart';
import 'interfaces/i_custom_exercise_service.dart';
import 'error_handling_service.dart';
import 'service_locator.dart' show Environment;

/// 自定義動作服務的Firebase實現
/// 
/// 提供用戶自定義動作的創建、讀取、更新、刪除等功能
/// 支持環境配置、緩存機制和統一錯誤處理
class CustomExerciseService implements ICustomExerciseService {
  // 依賴注入
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ErrorHandlingService _errorService;
  
  // 服務狀態
  bool _isInitialized = false;
  Environment _environment = Environment.development;
  
  // 服務配置
  bool _useCache = true;
  int _queryTimeout = 8; // 秒
  int _cacheDuration = 5; // 分鐘
  
  // 緩存
  List<CustomExercise>? _userExercisesCache;
  DateTime? _userExercisesCacheTime;
  final Map<String, CustomExercise> _exerciseCache = {};
  Timer? _cacheClearTimer;
  
  /// 創建服務實例
  /// 
  /// 允許注入自定義的Firestore和Auth實例，便於測試
  CustomExerciseService({
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
      
      // 設置緩存清理計時器（每小時）
      if (_useCache) {
        _setupCacheCleanupTimer();
      }
      
      _isInitialized = true;
      _logDebug('自定義動作服務初始化完成');
    } catch (e) {
      _logError('自定義動作服務初始化失敗: $e');
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
      _userExercisesCache = null;
      _userExercisesCacheTime = null;
      _exerciseCache.clear();
      
      _isInitialized = false;
      _logDebug('自定義動作服務資源已釋放');
    } catch (e) {
      _logError('釋放自定義動作服務資源時發生錯誤: $e');
    }
  }
  
  /// 根據環境配置服務
  void configureForEnvironment(Environment environment) {
    _environment = environment;
    
    switch (environment) {
      case Environment.development:
        // 開發環境設置
        _useCache = true;
        _queryTimeout = 12; // 較長的超時時間，便於調試
        _cacheDuration = 10; // 較長的緩存時間，便於開發
        _logDebug('自定義動作服務配置為開發環境');
        break;
      case Environment.testing:
        // 測試環境設置
        _useCache = false; // 測試需要實時數據，不使用緩存
        _queryTimeout = 6;
        _cacheDuration = 2;
        _logDebug('自定義動作服務配置為測試環境');
        break;
      case Environment.production:
        // 生產環境設置
        _useCache = true;
        _queryTimeout = 8;
        _cacheDuration = 5;
        _logDebug('自定義動作服務配置為生產環境');
        break;
    }
  }
  
  /// 設置緩存清理計時器
  void _setupCacheCleanupTimer() {
    _cacheClearTimer?.cancel();
    // 每小時清理一次緩存
    _cacheClearTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _clearCache();
    });
  }
  
  /// 清除緩存
  void _clearCache() {
    _logDebug('清理自定義動作緩存');
    _userExercisesCache = null;
    _userExercisesCacheTime = null;
    _exerciseCache.clear();
  }
  
  // 獲取當前用戶ID
  String? get currentUserId {
    _ensureInitialized();
    return _auth.currentUser?.uid;
  }
  
  // 獲取自定義動作集合引用
  CollectionReference get _customExercisesRef => _firestore.collection('customExercises');
  
  @override
  Future<CustomExercise> addCustomExercise(String name) async {
    _ensureInitialized();
    
    if (currentUserId == null) {
      _logError('添加自定義動作失敗：沒有登入用戶');
      throw Exception('用戶未登入');
    }
    
    try {
      _logDebug('創建新的自定義動作: $name');
      final now = Timestamp.now();
      
      // 創建新的自定義動作
      final docRef = await _customExercisesRef.add({
        'name': name,
        'userId': currentUserId,
        'createdAt': now,
        'updatedAt': now, // 在Firestore中保存，但不在模型中使用
      }).timeout(
        Duration(seconds: _queryTimeout),
        onTimeout: () => throw TimeoutException('添加自定義動作超時'),
      );
      
      // 獲取新創建的動作文檔
      final doc = await docRef.get();
      final newExercise = CustomExercise.fromFirestore(doc);
      
      // 更新緩存
      if (_useCache) {
        // 更新單個緩存
        _exerciseCache[newExercise.id] = newExercise;
        
        // 更新列表緩存
        if (_userExercisesCache != null) {
          _userExercisesCache = [newExercise, ..._userExercisesCache!]; 
          _userExercisesCacheTime = DateTime.now();
        }
      }
      
      _logDebug('自定義動作創建成功: ${newExercise.id}');
      return newExercise;
    } catch (e) {
      _logError('添加自定義動作失敗: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<CustomExercise>> getUserCustomExercises() async {
    _ensureInitialized();
    
    if (currentUserId == null) {
      _logDebug('獲取自定義動作：沒有登入用戶');
      return [];
    }
    
    // 檢查緩存是否有效（如果啟用）
    if (_useCache && _userExercisesCache != null && _userExercisesCacheTime != null) {
      final cacheAge = DateTime.now().difference(_userExercisesCacheTime!);
      // 根據配置的時間檢查緩存是否有效
      if (cacheAge.inMinutes < _cacheDuration) {
        _logDebug('從緩存獲取自定義動作列表 (${_userExercisesCache!.length} 個動作)');
        return List.unmodifiable(_userExercisesCache!);
      }
    }
    
    try {
      _logDebug('從Firestore獲取自定義動作');
      final querySnapshot = await _customExercisesRef
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('獲取自定義動作列表超時'),
          );
      
      final exercises = querySnapshot.docs
          .map((doc) => CustomExercise.fromFirestore(doc))
          .toList();
      
      // 更新緩存
      if (_useCache) {
        _userExercisesCache = exercises;
        _userExercisesCacheTime = DateTime.now();
        
        // 同時更新單個動作緩存
        for (final exercise in exercises) {
          _exerciseCache[exercise.id] = exercise;
        }
      }
      
      _logDebug('成功獲取 ${exercises.length} 個自定義動作');
      return exercises;
    } catch (e) {
      _logError('獲取自定義動作失敗: $e');
      
      // 如果緩存可用但可能已過期，在發生錯誤時仍返回緩存數據
      if (_useCache && _userExercisesCache != null) {
        _logDebug('服務器獲取失敗，返回可能過期的緩存數據');
        return List.unmodifiable(_userExercisesCache!);
      }
      
      rethrow;
    }
  }
  
  @override
  Future<void> deleteCustomExercise(String exerciseId) async {
    _ensureInitialized();
    
    if (currentUserId == null) {
      _logError('刪除自定義動作失敗：沒有登入用戶');
      throw Exception('用戶未登入');
    }
    
    try {
      _logDebug('刪除自定義動作: $exerciseId');
      
      // 檢查權限，確保只有創建者能刪除
      final doc = await _customExercisesRef.doc(exerciseId).get()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('獲取自定義動作詳情超時'),
          );
          
      if (!doc.exists) {
        _logError('動作不存在: $exerciseId');
        throw Exception('動作不存在');
      }
      
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || data['userId'] != currentUserId) {
        _logError('無權刪除自定義動作: $exerciseId');
        throw Exception('無權刪除此動作');
      }
      
      await _customExercisesRef.doc(exerciseId).delete()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('刪除自定義動作超時'),
          );
      
      // 更新緩存
      if (_useCache) {
        _exerciseCache.remove(exerciseId);
        
        // 更新列表緩存
        if (_userExercisesCache != null) {
          _userExercisesCache = _userExercisesCache!
              .where((exercise) => exercise.id != exerciseId)
              .toList();
          _userExercisesCacheTime = DateTime.now();
        }
      }
      
      _logDebug('自定義動作刪除成功');
    } catch (e) {
      _logError('刪除自定義動作失敗: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> updateCustomExercise(String exerciseId, String newName) async {
    _ensureInitialized();
    
    if (currentUserId == null) {
      _logError('更新自定義動作失敗：沒有登入用戶');
      throw Exception('用戶未登入');
    }
    
    try {
      _logDebug('更新自定義動作: $exerciseId, 新名稱: $newName');
      
      // 檢查權限，確保只有創建者能更新
      final doc = await _customExercisesRef.doc(exerciseId).get()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('獲取自定義動作詳情超時'),
          );
          
      if (!doc.exists) {
        _logError('動作不存在: $exerciseId');
        throw Exception('動作不存在');
      }
      
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || data['userId'] != currentUserId) {
        _logError('無權更新自定義動作: $exerciseId');
        throw Exception('無權更新此動作');
      }
      
      final updateTime = Timestamp.now();
      await _customExercisesRef.doc(exerciseId).update({
        'name': newName,
        'updatedAt': updateTime,
      }).timeout(
        Duration(seconds: _queryTimeout),
        onTimeout: () => throw TimeoutException('更新自定義動作超時'),
      );
      
      // 更新緩存
      if (_useCache) {
        // 獲取舊的動作數據
        CustomExercise? oldExercise = _exerciseCache[exerciseId];
        
        if (oldExercise != null) {
          // 創建更新後的動作對象
          final updatedExercise = CustomExercise(
            id: oldExercise.id,
            name: newName,
            userId: oldExercise.userId,
            createdAt: oldExercise.createdAt,
          );
          
          // 更新單個緩存
          _exerciseCache[exerciseId] = updatedExercise;
          
          // 更新列表緩存
          if (_userExercisesCache != null) {
            _userExercisesCache = _userExercisesCache!
                .map((e) => e.id == exerciseId ? updatedExercise : e)
                .toList();
            _userExercisesCacheTime = DateTime.now();
          }
        }
      }
      
      _logDebug('自定義動作更新成功');
    } catch (e) {
      _logError('更新自定義動作失敗: $e');
      rethrow;
    }
  }
  
  /// 根據ID獲取自定義動作
  /// 
  /// 新增方法，方便獲取單個動作數據
  Future<CustomExercise?> getCustomExerciseById(String exerciseId) async {
    _ensureInitialized();
    
    if (currentUserId == null) {
      _logDebug('獲取自定義動作詳情：沒有登入用戶');
      return null;
    }
    
    // 檢查緩存
    if (_useCache && _exerciseCache.containsKey(exerciseId)) {
      _logDebug('從緩存獲取自定義動作: $exerciseId');
      return _exerciseCache[exerciseId];
    }
    
    try {
      _logDebug('從Firestore獲取自定義動作: $exerciseId');
      final docSnapshot = await _customExercisesRef.doc(exerciseId).get()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('獲取自定義動作詳情超時'),
          );
          
      if (!docSnapshot.exists) {
        _logDebug('自定義動作不存在: $exerciseId');
        return null;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>?;
      if (data == null || data['userId'] != currentUserId) {
        _logError('無權訪問此自定義動作: $exerciseId');
        throw Exception('無權訪問此動作');
      }
      
      final exercise = CustomExercise.fromFirestore(docSnapshot);
      
      // 更新緩存
      if (_useCache) {
        _exerciseCache[exerciseId] = exercise;
      }
      
      _logDebug('成功獲取自定義動作詳情: ${exercise.name}');
      return exercise;
    } catch (e) {
      _logError('獲取自定義動作詳情失敗: $e');
      return null;
    }
  }
  
  /// 確保服務已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      _logDebug('警告: 自定義動作服務在初始化前被調用');
      // 在開發環境中自動初始化，但在其他環境拋出錯誤
      if (_environment == Environment.development) {
        initialize();
      } else {
        throw StateError('自定義動作服務未初始化');
      }
    }
  }
  
  /// 記錄調試信息
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[CUSTOM EXERCISE] $message');
    }
  }
  
  /// 記錄錯誤信息
  void _logError(String message) {
    if (kDebugMode) {
      print('[CUSTOM EXERCISE ERROR] $message');
    }
    
    _errorService.logError(message);
  }
} 