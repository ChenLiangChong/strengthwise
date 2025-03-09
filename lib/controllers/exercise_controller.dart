import 'package:flutter/material.dart';

import 'dart:async';

import '../models/exercise_model.dart';

import '../services/interfaces/i_exercise_service.dart';

import '../services/error_handling_service.dart';

import '../services/service_locator.dart' show Environment, serviceLocator;

import 'interfaces/i_exercise_controller.dart';



/// 訓練動作控制器實現

/// 

/// 管理訓練動作數據的業務邏輯，提供數據驗證，錯誤處理和緩存功能

class ExerciseController extends ChangeNotifier implements IExerciseController {

  // 依賴注入

  final IExerciseService _service;

  final ErrorHandlingService _errorService;

  

  // 狀態管理

  bool _isLoading = false;

  String? _errorMessage;

  bool _isInitialized = false;

  

  // 數據緩存
  final Map<String, List<String>> _categoriesCache = {};

  final Map<String, List<Exercise>> _exercisesCache = {};

  List<String>? _exerciseTypes;

  List<String>? _bodyParts;

  final Map<String, Exercise> _exerciseDetailsCache = {};

  

  /// 正在載入數據

  bool get isLoading => _isLoading;

  

  /// 錯誤訊息

  String? get errorMessage => _errorMessage;

  

  /// 構造函數，支持依賴注入

  ExerciseController({

    IExerciseService? service,

    ErrorHandlingService? errorService,

  }) : 

    _service = service ?? serviceLocator<IExerciseService>(),

    _errorService = errorService ?? serviceLocator<ErrorHandlingService>() {

    _initialize();

  }

  

  /// 初始化控制器

  Future<void> _initialize() async {

    if (_isInitialized) return;

    

    try {

      _setLoading(true);

      

      // 確保服務已初始化

      if (_service.runtimeType.toString().contains('ExerciseService')) {

        await Future.microtask(() async {

          // 可能的初始化代碼，取決於服務實現

        });

      }

      

      // 預載入常用數據

      _exerciseTypes = await _service.getExerciseTypes();

      _bodyParts = await _service.getBodyParts();

      

      _isInitialized = true;

      _setLoading(false);

    } catch (e) {

      _handleError('初始化訓練動作控制器失敗', e);

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

    _errorService.logError('$message: $error', type: 'ExerciseControllerError');

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

  

  /// 清除特定類型的緩存

  void clearCache(String cacheType) {

    switch (cacheType) {

      case 'all':

        _categoriesCache.clear();

        _exercisesCache.clear();

        _exerciseTypes = null;

        _bodyParts = null;

        _exerciseDetailsCache.clear();

        logDebug('已清除所有緩存');

        break;

      case 'categories':

        _categoriesCache.clear();

        logDebug('已清除分類緩存');

        break;

      case 'exercises':

        _exercisesCache.clear();

        logDebug('已清除運動緩存');

        break;

      case 'details':

        _exerciseDetailsCache.clear();

        logDebug('已清除詳情緩存');

        break;

    }

  }

  

  /// 清除特定層級的分類緩存

  /// 

  /// 在用戶選擇條件變化時使用，確保獲取最新的分類數據

  void clearLevelCache(int level) {

    // 找出並清除所有與該層級相關的緩存

    List<String> keysToRemove = [];

    

    for (var key in _categoriesCache.keys) {

      // 使用新的緩存鍵格式匹配

      // 格式：'level{level}_{type}_{bodyPart}_{level1}_{level2}_{level3}_{level4}'

      if (key.startsWith('level$level')) {

        keysToRemove.add(key);

      }

    }

    

    for (var key in keysToRemove) {

      _categoriesCache.remove(key);

    }

    

    logDebug('已清除Level$level相關的${keysToRemove.length}個緩存項');

  }

  

  /// 當選擇條件變化時清除受影響的緩存

  /// 

  /// [changedSelection] 可以是 'type', 'bodyPart', 'level1' 等

  void clearCacheOnSelectionChange(String changedSelection) {

    switch (changedSelection) {

      case 'type':

      case 'bodyPart':

        // 訓練類型或身體部位變化時，清除所有層級緩存和運動緩存

        clearCache('categories');

        clearCache('exercises');

        logDebug('選擇$changedSelection已變化，清除所有分類和運動緩存');

        break;

      case 'level1':

        // level1變化時，清除level2及以上層級和運動緩存

        clearLevelCache(2);

        clearLevelCache(3);

        clearLevelCache(4);

        clearLevelCache(5);

        clearCache('exercises');

        logDebug('選擇level1已變化，清除level2+和運動緩存');

        break;

      case 'level2':

        // level2變化時，清除level3及以上層級和運動緩存

        clearLevelCache(3);

        clearLevelCache(4);

        clearLevelCache(5);

        clearCache('exercises');

        logDebug('選擇level2已變化，清除level3+和運動緩存');

        break;

      case 'level3':

        // level3變化時，清除level4及以上層級和運動緩存

        clearLevelCache(4);

        clearLevelCache(5);

        clearCache('exercises');

        logDebug('選擇level3已變化，清除level4+和運動緩存');

        break;

      case 'level4':

        // level4變化時，清除level5和運動緩存

        clearLevelCache(5);

        clearCache('exercises');

        logDebug('選擇level4已變化，清除level5和運動緩存');

        break;

      case 'level5':

        // level5變化時，只清除運動緩存

        clearCache('exercises');

        logDebug('選擇level5已變化，清除運動緩存');

        break;

    }

  }

  

  /// 釋放資源

  @override

  void dispose() {

    _isInitialized = false;

    clearCache('all');

    super.dispose();

  }

  

  @override

  void logDebug(String message) {

    _service.logDebug(message);

    _errorService.logError(message, type: 'Debug');

  }

  

  @override

  Future<List<String>> loadExerciseTypes() async {

    if (!_isInitialized) await _initialize();

    

    try {

      if (_exerciseTypes == null) {

        _setLoading(true);

        clearError();

        _exerciseTypes = await _service.getExerciseTypes();

        _setLoading(false);

      }

      return _exerciseTypes ?? [];

    } catch (e) {

      _handleError('載入訓練類型失敗', e);

      return [];

    }

  }

  

  @override

  Future<List<String>> loadBodyParts() async {

    if (!_isInitialized) await _initialize();

    

    try {

      if (_bodyParts == null) {

        _setLoading(true);

        clearError();

        _bodyParts = await _service.getBodyParts();

        _setLoading(false);

      }

      return _bodyParts ?? [];

    } catch (e) {

      _handleError('載入身體部位失敗', e);

      return [];

    }

  }

  

  @override

  Future<List<String>> loadCategories({

    required int level,

    String? selectedType,

    String? selectedBodyPart,

    String? selectedLevel1,

    String? selectedLevel2,

    String? selectedLevel3,

    String? selectedLevel4,

  }) async {

    if (!_isInitialized) await _initialize();

    

    try {

      // 構建過濾器Map，提高代碼可維護性

      final filters = <String, String>{};

      

      // 始終添加訓練類型和身體部位過濾條件（如果有提供）

      // 這些是基本條件，確保返回的分類同時滿足這兩個條件

      if (selectedType != null && selectedType.isNotEmpty) {

        filters['type'] = selectedType;

        logDebug('添加基本查詢條件: type=$selectedType');

      } else if (level == 1) { // level1查詢必須指定訓練類型

        throw ArgumentError('載入Level1分類時，訓練類型為必選項');

      }

      

      if (selectedBodyPart != null && selectedBodyPart.isNotEmpty) {

        // 注意：這裡我們使用bodyPart作為鍵，服務層應該理解這是需要使用arrayContains來查詢

        filters['bodyPart'] = selectedBodyPart;

        logDebug('添加基本查詢條件: bodyParts包含$selectedBodyPart');

      } else if (level == 1) { // level1查詢必須指定身體部位

        throw ArgumentError('載入Level1分類時，身體部位為必選項');

      }

      

      // 根據當前要查詢的層級，添加所有前置層級的條件

      if (level >= 2 && selectedLevel1 != null && selectedLevel1.isNotEmpty) {

        filters['level1'] = selectedLevel1;

        logDebug('添加層級條件: level1=$selectedLevel1');

      }

      

      if (level >= 3 && selectedLevel2 != null && selectedLevel2.isNotEmpty) {

        filters['level2'] = selectedLevel2;

        logDebug('添加層級條件: level2=$selectedLevel2');

      }

      

      if (level >= 4 && selectedLevel3 != null && selectedLevel3.isNotEmpty) {

        filters['level3'] = selectedLevel3;

        logDebug('添加層級條件: level3=$selectedLevel3');

      }

      

      if (level >= 5 && selectedLevel4 != null && selectedLevel4.isNotEmpty) {

        filters['level4'] = selectedLevel4;

        logDebug('添加層級條件: level4=$selectedLevel4');

      }

      

      // 生成與服務層一致的緩存鍵

      // 格式：'level{level}_{type}_{bodyPart}_{level1}_{level2}_{level3}_{level4}'

      final typeValue = selectedType ?? '';

      final bodyPartValue = selectedBodyPart ?? '';

      final level1Value = (level >= 2 && selectedLevel1 != null) ? selectedLevel1 : '';

      final level2Value = (level >= 3 && selectedLevel2 != null) ? selectedLevel2 : '';

      final level3Value = (level >= 4 && selectedLevel3 != null) ? selectedLevel3 : '';

      final level4Value = (level >= 5 && selectedLevel4 != null) ? selectedLevel4 : '';

      

      final cacheKey = 'level${level}_${typeValue}_${bodyPartValue}_${level1Value}_${level2Value}_${level3Value}_${level4Value}';

      logDebug('使用與服務層一致的緩存鍵: $cacheKey');

      

      // 清除緩存以確保獲取最新數據

      clearCache('categories');

      logDebug('已清除分類緩存，確保獲取最新數據');

      

      // 從服務獲取數據

      _setLoading(true);

      clearError();

      logDebug('從服務查詢Level$level分類');

      final categories = await _service.getCategoriesByLevel(level, filters);

      

      // 驗證結果是否符合條件

      logDebug('查詢到 ${categories.length} 個Level$level分類，需要同時滿足type=$selectedType和bodyPart=$selectedBodyPart');

      

      // 儲存到緩存

      _categoriesCache[cacheKey] = categories;

      

      _setLoading(false);

      

      return categories;

    } catch (e) {

      _handleError('載入分類失敗', e);

      return [];

    }

  }

  

  @override

  Future<List<Exercise>> loadFinalExercises({

    String? selectedType,

    String? selectedBodyPart,

    String? selectedLevel1,

    String? selectedLevel2,

    String? selectedLevel3,

    String? selectedLevel4,

    String? selectedLevel5,

  }) async {

    try {

      // 確保訓練類型和身體部位都已選擇

      if (selectedType == null || selectedType.isEmpty) {

        throw ArgumentError('訓練類型為必選項');

      }

      

      if (selectedBodyPart == null || selectedBodyPart.isEmpty) {

        throw ArgumentError('身體部位為必選項');

      }

      

      logDebug('開始載入最終動作');

      logDebug('條件: type=$selectedType, bodyPart=$selectedBodyPart');

      logDebug('層級: L1=${selectedLevel1 ?? "無"}, L2=${selectedLevel2 ?? "無"}, L3=${selectedLevel3 ?? "無"}, L4=${selectedLevel4 ?? "無"}, L5=${selectedLevel5 ?? "無"}');

      

      // 構建過濾條件Map

      final filters = <String, String>{

        'type': selectedType,

        'bodyPart': selectedBodyPart,

      };

      

      // 添加所有層級條件

      if (selectedLevel1 != null && selectedLevel1.isNotEmpty) {

        filters['level1'] = selectedLevel1;

        logDebug('添加條件: level1=$selectedLevel1');

      }

      

      if (selectedLevel2 != null && selectedLevel2.isNotEmpty) {

        filters['level2'] = selectedLevel2;

        logDebug('添加條件: level2=$selectedLevel2');

      }

      

      if (selectedLevel3 != null && selectedLevel3.isNotEmpty) {

        filters['level3'] = selectedLevel3;

        logDebug('添加條件: level3=$selectedLevel3');

      }

      

      if (selectedLevel4 != null && selectedLevel4.isNotEmpty) {

        filters['level4'] = selectedLevel4;

        logDebug('添加條件: level4=$selectedLevel4');

      }

      

      if (selectedLevel5 != null && selectedLevel5.isNotEmpty) {

        filters['level5'] = selectedLevel5;

        logDebug('添加條件: level5=$selectedLevel5');

      }

      

      // 生成與服務層一致的緩存鍵

      // 格式：'exercises_{type}_{bodyPart}_{level1}_{level2}_{level3}_{level4}_{level5}'

      final level1Value = selectedLevel1 ?? '';

      final level2Value = selectedLevel2 ?? '';

      final level3Value = selectedLevel3 ?? '';

      final level4Value = selectedLevel4 ?? '';

      final level5Value = selectedLevel5 ?? '';

      

      final cacheKey = 'exercises_${selectedType}_${selectedBodyPart}_${level1Value}_${level2Value}_${level3Value}_${level4Value}_${level5Value}';

      logDebug('使用與服務層一致的緩存鍵: $cacheKey');

      

      // 檢查緩存

      if (_exercisesCache.containsKey(cacheKey)) {

        logDebug('從緩存返回最終動作, 數量: ${_exercisesCache[cacheKey]!.length}');

        return _exercisesCache[cacheKey]!;

      }

      

      // 使用服務層方法獲取數據

      _setLoading(true);

      clearError();

      final exercises = await _service.getExercisesByFilters(filters);

      

      // 緩存結果

      if (exercises.isNotEmpty) {

        _exercisesCache[cacheKey] = exercises;

      }

      

      logDebug('查詢到 ${exercises.length} 個最終動作');

      _setLoading(false);

      

      return exercises;

    } catch (e) {

      _handleError('載入最終動作失敗', e);

      rethrow;

    }

  }

  

  @override

  Future<Exercise?> getExerciseById(String exerciseId) async {

    if (!_isInitialized) await _initialize();

    

    try {

      // 檢查緩存

      if (_exerciseDetailsCache.containsKey(exerciseId)) {

        return _exerciseDetailsCache[exerciseId];

      }

      

      // 從服務獲取數據

      _setLoading(true);

      clearError();

      final exercise = await _service.getExerciseById(exerciseId);

      

      if (exercise != null) {

        _exerciseDetailsCache[exerciseId] = exercise;

      }

      

      _setLoading(false);

      return exercise;

    } catch (e) {

      _handleError('獲取動作詳情失敗', e);

      return null;

    }

  }

} 
