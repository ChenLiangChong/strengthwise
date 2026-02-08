import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../models/favorite/favorite_exercise.dart'; // ⭐ v3.6: MVVM
import '../services/interfaces/i_exercise_service.dart';
import '../services/interfaces/i_favorites_service.dart'; // ⭐ v3.5: MVVM
import '../services/core/error_handling_service.dart';
import '../services/core/app_event_bus.dart'; // ⭐ v3.5: EventBus
import '../services/service_locator.dart' show serviceLocator;
import 'interfaces/i_exercise_controller.dart';
import 'interfaces/i_event_bus_controller.dart'; // ⭐ v3.5: EventBus
import 'exercise/exercise_cache_manager.dart';
import '../services/cache/exercise_preferences_service.dart';

/// 訓練動作控制器實現
/// 
/// 管理訓練動作數據的業務邏輯，提供數據驗證，錯誤處理和緩存功能
class ExerciseController extends ChangeNotifier implements IExerciseController {
  // 依賴注入
  final IExerciseService _service;
  final ErrorHandlingService _errorService;
  final ExercisePreferencesService _preferencesService;

  // 狀態管理
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // ⭐ v5.0: 偏好設定
  String _preferredBrowseMode = 'pattern';
  Set<String> _myEquipment = {};

  // 子模組
  late final ExerciseCacheManager _cacheManager;
  
  /// 正在載入數據
  @override
  bool get isLoading => _isLoading;
  
  /// 錯誤訊息
  @override
  String? get errorMessage => _errorMessage;
  
  /// 構造函數，支持依賴注入
  ExerciseController({
    IExerciseService? service,
    ErrorHandlingService? errorService,
    ExercisePreferencesService? preferencesService,
  }) :
    _service = service ?? serviceLocator<IExerciseService>(),
    _errorService = errorService ?? serviceLocator<ErrorHandlingService>(),
    _preferencesService = preferencesService ?? serviceLocator<ExercisePreferencesService>() {
    // 初始化子模組
    _cacheManager = ExerciseCacheManager();
    _initialize();
  }
  
  /// 初始化控制器（載入偏好設定）
  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      _setLoading(true);

      // ⭐ v5.0: 載入偏好設定
      _preferredBrowseMode = await _preferencesService.getBrowseMode();
      _myEquipment = await _preferencesService.getMyEquipment();

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
  
  /// 釋放資源
  @override
  void dispose() {
    _isInitialized = false;
    _cacheManager.clearAll();
    super.dispose();
  }
  
  @override
  void logDebug(String message) {
    _service.logDebug(message);
    _errorService.logError(message, type: 'Debug');
  }
  
  @override
  Future<Exercise?> getExerciseById(String exerciseId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      // 檢查緩存
      if (_cacheManager.hasExerciseDetails(exerciseId)) {
        return _cacheManager.getExerciseDetails(exerciseId);
      }
      
      // 從服務獲取數據
      _setLoading(true);
      clearError();
      final exercise = await _service.getExerciseById(exerciseId);
      
      if (exercise != null) {
        _cacheManager.setExerciseDetails(exerciseId, exercise);
      }
      
      _setLoading(false);
      return exercise;
    } catch (e) {
      _handleError('獲取動作詳情失敗', e);
      return null;
    }
  }

  // =========================================================================
  // ⭐ v3.5: 收藏功能（MVVM 重構）
  // =========================================================================

  /// 添加動作到收藏
  @override
  Future<bool> addFavorite({
    required String userId,
    required String exerciseId,
    required String exerciseName,
    required String bodyPart,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final favoritesService = serviceLocator<IFavoritesService>();
      await favoritesService.addFavorite(userId, exerciseId, exerciseName, bodyPart);

      // ⭐ v3.5: 發布收藏新增事件
      final eventBusController = serviceLocator<IEventBusController>();
      eventBusController.publish(AppEvent(
        type: AppEventType.favoriteAdded,
        entityId: exerciseId,
        userId: userId,
        timestamp: DateTime.now(),
        metadata: {'exerciseName': exerciseName, 'bodyPart': bodyPart},
      ));

      _setLoading(false);
      return true;
    } catch (e) {
      _handleError('添加收藏失敗', e);
      return false;
    }
  }

  /// 移除收藏動作
  @override
  Future<bool> removeFavorite({
    required String userId,
    required String exerciseId,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final favoritesService = serviceLocator<IFavoritesService>();
      await favoritesService.removeFavorite(userId, exerciseId);

      // ⭐ v3.5: 發布收藏移除事件
      final eventBusController = serviceLocator<IEventBusController>();
      eventBusController.publish(AppEvent(
        type: AppEventType.favoriteRemoved,
        entityId: exerciseId,
        userId: userId,
        timestamp: DateTime.now(),
      ));

      _setLoading(false);
      return true;
    } catch (e) {
      _handleError('移除收藏失敗', e);
      return false;
    }
  }

  /// 檢查動作是否已收藏
  /// ⭐ MVVM 重構：View 層透過 Controller 查詢
  @override
  Future<bool> isFavorite(String userId, String exerciseId) async {
    try {
      final favoritesService = serviceLocator<IFavoritesService>();
      return await favoritesService.isFavorite(userId, exerciseId);
    } catch (e) {
      _handleError('檢查收藏狀態失敗', e);
      return false;
    }
  }

  /// 獲取用戶收藏的動作 ID 列表
  /// ⭐ MVVM 重構：View 層透過 Controller 查詢
  @override
  Future<List<String>> getFavoriteExerciseIds(String userId) async {
    try {
      final favoritesService = serviceLocator<IFavoritesService>();
      return await favoritesService.getFavoriteExerciseIds(userId);
    } catch (e) {
      _handleError('獲取收藏列表失敗', e);
      return [];
    }
  }

  /// 獲取用戶收藏的動作列表（含詳細資訊）
  /// ⭐ v3.6 MVVM 重構：View 層透過 Controller 查詢
  @override
  Future<List<FavoriteExercise>> getFavoriteExercises(String userId) async {
    try {
      final favoritesService = serviceLocator<IFavoritesService>();
      return await favoritesService.getFavoriteExercises(userId);
    } catch (e) {
      _handleError('獲取收藏動作列表失敗', e);
      return [];
    }
  }

  // =========================================================================
  // ⭐ v5.0: 進階搜尋與篩選
  // =========================================================================

  /// v5.0 進階搜尋（支援多維度篩選）
  @override
  Future<List<Exercise>> searchExercisesAdvanced({
    String? query,
    List<String>? movementPatterns,
    List<String>? pplTags,
    List<String>? excludePplTags,
    String? primaryMuscle,
    String? equipment,
    Set<String>? equipmentSet,
    bool? isExplosive,
    String? difficultyLevel,
    String? mechanicsType,
    int limit = 50,
  }) async {
    if (!_isInitialized) await _initialize();

    try {
      return await _service.searchExercisesAdvanced(
        query: query,
        movementPatterns: movementPatterns,
        pplTags: pplTags,
        excludePplTags: excludePplTags,
        primaryMuscle: primaryMuscle,
        equipment: equipment,
        equipmentSet: equipmentSet,
        isExplosive: isExplosive,
        difficultyLevel: difficultyLevel,
        mechanicsType: mechanicsType,
        limit: limit,
      );
    } catch (e) {
      _handleError('進階搜尋失敗', e);
      return [];
    }
  }

  /// 獲取動作模式參照資料（含快取）
  @override
  Future<List<Map<String, String>>> getMovementPatterns() async {
    if (!_isInitialized) await _initialize();

    try {
      final cached = _cacheManager.getRefData('movementPatterns');
      if (cached != null) return cached;

      final data = await _service.getMovementPatterns();
      _cacheManager.setRefData('movementPatterns', data);
      return data;
    } catch (e) {
      _handleError('獲取動作模式失敗', e);
      return [];
    }
  }

  /// 獲取肌肉群參照資料（含快取）
  @override
  Future<List<Map<String, String>>> getMuscleGroups() async {
    if (!_isInitialized) await _initialize();

    try {
      final cached = _cacheManager.getRefData('muscleGroups');
      if (cached != null) return cached;

      final data = await _service.getMuscleGroups();
      _cacheManager.setRefData('muscleGroups', data);
      return data;
    } catch (e) {
      _handleError('獲取肌肉群失敗', e);
      return [];
    }
  }

  /// 獲取器材參照資料（含快取）
  @override
  Future<List<Map<String, String>>> getEquipmentList() async {
    if (!_isInitialized) await _initialize();

    try {
      final cached = _cacheManager.getRefData('equipment');
      if (cached != null) return cached;

      final data = await _service.getEquipmentList();
      _cacheManager.setRefData('equipment', data);
      return data;
    } catch (e) {
      _handleError('獲取器材列表失敗', e);
      return [];
    }
  }

  // =========================================================================
  // ⭐ v5.0: 偏好設定
  // =========================================================================

  @override
  String get preferredBrowseMode => _preferredBrowseMode;

  @override
  Set<String> get myEquipment => _myEquipment;

  @override
  Future<void> setPreferredBrowseMode(String mode) async {
    _preferredBrowseMode = mode;
    notifyListeners();
    await _preferencesService.setBrowseMode(mode);
  }

  @override
  Future<void> setMyEquipment(Set<String> equipment) async {
    _myEquipment = equipment;
    notifyListeners();
    await _preferencesService.setMyEquipment(equipment);
  }
}
