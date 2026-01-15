import 'package:flutter/foundation.dart';
import '../services/interfaces/i_coaching_relationship_service.dart';
import '../services/interfaces/i_workout_service.dart';
import '../services/interfaces/i_client_availability_service.dart';
import '../services/interfaces/i_user_service.dart';
import '../services/core/error_handling_service.dart';
import '../models/user/user_model.dart';
import '../models/workout_record/workout_record.dart';
import '../models/workout_record/exercise_record.dart';
import '../models/client_availability_model.dart';
import 'event_bus_controller.dart'; // ⭐ v3.5

/// 教練端學員管理控制器
///
/// 負責教練查看學員詳情、管理學員訓練計畫等功能
class ClientManagementController extends ChangeNotifier {
  final ICoachingRelationshipService _relationshipService;
  final IWorkoutService _workoutService;
  final IClientAvailabilityService _availabilityService;
  final IUserService _userService;
  final ErrorHandlingService _errorService;
  final EventBusController _eventBusController; // ⭐ v3.5

  ClientManagementController(
    this._relationshipService,
    this._workoutService,
    this._availabilityService,
    this._userService,
    this._errorService,
    this._eventBusController, // ⭐ v3.5
  );

  // ============================================================================
  // 狀態管理
  // ============================================================================

  bool _isLoading = false;
  String? _errorMessage;

  // 當前選中的學員
  UserModel? _selectedClient;

  // 學員列表（用於搜尋和篩選）
  List<UserModel> _clients = [];
  List<UserModel> _filteredClients = [];

  // 選中學員的訓練計畫
  List<WorkoutRecord> _clientWorkouts = [];

  // 選中學員的時間偏好
  List<ClientAvailabilityModel> _clientAvailability = [];

  // 搜尋關鍵字
  String _searchQuery = '';

  // ============================================================================
  // Getters
  // ============================================================================

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get selectedClient => _selectedClient;
  List<UserModel> get clients => _clients;
  List<UserModel> get filteredClients => _filteredClients;
  List<WorkoutRecord> get clientWorkouts => _clientWorkouts;
  List<ClientAvailabilityModel> get clientAvailability => _clientAvailability;
  String get searchQuery => _searchQuery;

  // ============================================================================
  // 學員列表管理
  // ============================================================================

  /// 載入教練的學員列表
  Future<void> loadClients(String coachId) async {
    _setLoading(true);
    _clearError();

    try {
      // 只載入 active 狀態的學員
      _clients = await _relationshipService.getCoachClientsWithDetails(
        coachId,
        status: 'active',
      );
      _filteredClients = List.from(_clients);
      notifyListeners();
    } catch (e) {
      _handleError('載入學員列表失敗', e);
    } finally {
      _setLoading(false);
    }
  }

  /// 搜尋學員
  void searchClients(String query) {
    _searchQuery = query.trim();

    if (_searchQuery.isEmpty) {
      _filteredClients = List.from(_clients);
    } else {
      _filteredClients = _clients.where((client) {
        final name = (client.displayName ?? '').toLowerCase();
        final email = client.email.toLowerCase();
        final q = _searchQuery.toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    }

    notifyListeners();
  }

  /// 清除搜尋
  void clearSearch() {
    _searchQuery = '';
    _filteredClients = List.from(_clients);
    notifyListeners();
  }

  // ============================================================================
  // 學員詳情管理
  // ============================================================================

  /// 選擇學員（進入詳情頁）
  Future<void> selectClient(String clientId) async {
    _setLoading(true);
    _clearError();

    try {
      // 載入學員基本資訊
      _selectedClient = await _userService.getUserProfile(clientId);

      // 同時載入訓練計畫和時間偏好
      await Future.wait([
        loadClientWorkouts(clientId),
        loadClientAvailability(clientId),
      ]);

      notifyListeners();
    } catch (e) {
      _handleError('載入學員資料失敗', e);
    } finally {
      _setLoading(false);
    }
  }

  /// 清除選中的學員
  void clearSelectedClient() {
    _selectedClient = null;
    _clientWorkouts = [];
    _clientAvailability = [];
    notifyListeners();
  }

  // ============================================================================
  // 訓練計畫管理
  // ============================================================================

  /// 載入學員的訓練計畫
  Future<void> loadClientWorkouts(
    String clientId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // ⭐ 透過 Service 查詢，傳入 userId = clientId
      // 底層用 trainee_id 查詢，所以會查到該學員的所有訓練（自己創建 + 教練指派）
      _clientWorkouts = await _workoutService.getUserPlans(
        userId: clientId,  // ⭐ 指定學員 ID
        completed: null,   // 查詢所有（完成和未完成）
        startDate: startDate,
        endDate: endDate,
        limit: 100,
      );
      
      notifyListeners();
    } catch (e) {
      _errorService.logError('載入學員訓練計畫失敗: $e');
      rethrow;
    }
  }

  /// 教練為學員創建訓練計畫
  Future<bool> createWorkoutForClient({
    required String coachId,
    required String clientId,
    required DateTime scheduledDate,
    required String title,
    String? notes,
    List<Map<String, dynamic>>? exercises,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // 創建訓練計畫
      final workout = WorkoutRecord(
        id: '', // 由 Service 生成
        workoutPlanId: '', // 由 Service 生成
        userId: clientId, // 歷史遺留欄位
        traineeId: clientId, // 受訓者 ID
        creatorId: coachId, // 創建者 ID（教練）
        title: title,
        date: scheduledDate,
        completed: false,
        exerciseRecords: exercises
                ?.map((e) => ExerciseRecord.fromJson(e))
                .toList() ??
            [],
        notes: notes ?? '',
        createdAt: DateTime.now(),
      );

      await _workoutService.createRecord(workout);

      // ⭐ v3.5: 發布訓練創建事件（觸發首頁、行事曆自動刷新）
      _eventBusController.publishWorkoutCreated(
        workoutId: workout.workoutPlanId,
        userId: clientId,
      );

      // 重新載入訓練計畫
      await loadClientWorkouts(clientId);

      notifyListeners();
      return true;
    } catch (e) {
      _handleError('創建訓練計畫失敗', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新訓練計畫
  Future<bool> updateWorkout(WorkoutRecord workout) async {
    _setLoading(true);
    _clearError();

    try {
      await _workoutService.updateRecord(workout);

      // ⭐ v3.5: 發布訓練更新事件（觸發首頁、行事曆自動刷新）
      final traineeId = workout.traineeId ?? workout.userId;
      _eventBusController.publishWorkoutUpdated(
        workoutId: workout.workoutPlanId,
        userId: traineeId,
      );

      // 重新載入訓練計畫
      if (_selectedClient != null) {
        await loadClientWorkouts(_selectedClient!.uid);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _handleError('更新訓練計畫失敗', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 刪除訓練計畫
  Future<bool> deleteWorkout(String workoutId) async {
    _setLoading(true);
    _clearError();

    try {
      // ⭐ v3.5: 先取得 clientId 用於發布事件（刪除後無法取得）
      final clientId = _selectedClient?.uid;
      
      await _workoutService.deleteRecord(workoutId);

      // ⭐ v3.5: 發布訓練刪除事件（觸發首頁、行事曆自動刷新）
      if (clientId != null) {
        _eventBusController.publishWorkoutDeleted(
          workoutId: workoutId,
          userId: clientId,
        );
      }

      // 重新載入訓練計畫
      if (_selectedClient != null) {
        await loadClientWorkouts(_selectedClient!.uid);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _handleError('刪除訓練計畫失敗', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================================
  // 時間偏好管理
  // ============================================================================

  /// 載入學員的時間偏好
  Future<void> loadClientAvailability(
    String clientId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _clientAvailability = await _availabilityService.getClientAvailability(
        clientId: clientId,
      );
      
      if (kDebugMode) {
        print('[CLIENT_CONTROLLER] 載入學員時間偏好: ${_clientAvailability.length} 個時段');
        for (var avail in _clientAvailability) {
          print('[CLIENT_CONTROLLER]   ${avail.startTime} - ${avail.endTime} (${avail.priority.toString().split('.').last})');
        }
      }
      
      notifyListeners();
    } catch (e) {
      _errorService.logError('載入學員時間偏好失敗: $e');
      rethrow;
    }
  }

  /// 根據日期查詢時間偏好
  List<ClientAvailabilityModel> getAvailabilityForDate(DateTime date) {
    // ⚡ 只比較日期部分（忽略時分秒）
    final targetDate = DateTime(date.year, date.month, date.day);
    
    final results = _clientAvailability.where((availability) {
      final availabilityDate = DateTime(
        availability.startTime.year,
        availability.startTime.month,
        availability.startTime.day,
      );
      return availabilityDate == targetDate;
    }).toList();
    
    // ⭐ 只在有找到匹配時才打印（減少 log 噪音）
    if (kDebugMode && results.isNotEmpty) {
      print('[CLIENT_CONTROLLER] getAvailabilityForDate(${date.month}/${date.day}) 找到 ${results.length} 個偏好時段');
    }
    
    return results;
  }

  /// 根據日期查詢訓練計畫
  List<WorkoutRecord> getWorkoutsForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return _clientWorkouts.where((workout) {
      final workoutDate = DateTime(
        workout.date.year,
        workout.date.month,
        workout.date.day,
      );
      return workoutDate == targetDate;
    }).toList();
  }

  // ============================================================================
  // 私有方法
  // ============================================================================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _handleError(String message, dynamic error) {
    _errorMessage = message;
    _errorService.logError('$message: $error', type: 'ClientManagementError');
    notifyListeners();
  }

  @override
  void dispose() {
    // 清理資源
    super.dispose();
  }
}

