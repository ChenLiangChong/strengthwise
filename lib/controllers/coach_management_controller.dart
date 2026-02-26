import 'package:flutter/foundation.dart';
import '../services/interfaces/i_coaching_relationship_service.dart';
import '../services/interfaces/i_workout_service.dart';
import '../services/interfaces/i_user_service.dart';
import '../services/core/error_handling_service.dart';
import '../models/user/user_model.dart';
import '../models/workout_record/workout_record.dart';
import 'interfaces/i_coach_management_controller.dart';

/// 學員端教練管理控制器
///
/// 負責學員查看教練列表、查看教練指派的訓練等功能
class CoachManagementController extends ChangeNotifier implements ICoachManagementController {
  final ICoachingRelationshipService _relationshipService;
  final IWorkoutService _workoutService;
  final IUserService _userService;
  final ErrorHandlingService _errorService;

  CoachManagementController(
    this._relationshipService,
    this._workoutService,
    this._userService,
    this._errorService,
  );

  // ============================================================================
  // 狀態管理
  // ============================================================================

  bool _isLoading = false;
  String? _errorMessage;

  // 當前選中的教練
  UserModel? _selectedCoach;

  // 教練列表
  List<UserModel> _coaches = [];
  List<UserModel> _filteredCoaches = [];

  // 選中教練指派的訓練計畫
  List<WorkoutRecord> _coachWorkouts = [];

  // 搜尋關鍵字
  String _searchQuery = '';

  // ============================================================================
  // Getters
  // ============================================================================

  @override
  bool get isLoading => _isLoading;
  @override
  String? get errorMessage => _errorMessage;
  @override
  UserModel? get selectedCoach => _selectedCoach;
  @override
  List<UserModel> get coaches => _coaches;
  @override
  List<UserModel> get filteredCoaches => _filteredCoaches;
  @override
  List<WorkoutRecord> get coachWorkouts => _coachWorkouts;
  @override
  String get searchQuery => _searchQuery;

  // ============================================================================
  // 教練列表管理
  // ============================================================================

  /// 載入學員的教練列表
  @override
  Future<void> loadCoaches(String clientId, {bool forceRefresh = false}) async {
    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        debugPrint('[CoachManagementController] 🔄 載入教練列表，學員 ID: $clientId${forceRefresh ? '（強制刷新）' : ''}');
      }

      // 獲取教練關係列表（只載入 active 狀態）
      final relationships = await _relationshipService.getClientCoaches(
        clientId,
        status: 'active',
        forceRefresh: forceRefresh,
      );

      if (kDebugMode) {
        debugPrint('[CoachManagementController] 📋 查詢到 ${relationships.length} 個教練關係');
      }

      // 獲取教練詳細資訊
      final coachUsers = <UserModel>[];
      for (final relationship in relationships) {
        try {
          // ⭐ 跳過已刪除的教練（coachId 為 null）
          if (relationship.coachId == null) {
            if (kDebugMode) {
              debugPrint('[CoachManagementController] ⚠️ 教練已被刪除，跳過');
            }
            continue;
          }
          
          if (kDebugMode) {
            debugPrint('[CoachManagementController] 🔍 載入教練資料: ${relationship.coachId}');
          }
          
          final coach = await _userService.getUserProfile(relationship.coachId!);
          if (coach != null) {
            coachUsers.add(coach);
            if (kDebugMode) {
              debugPrint('[CoachManagementController] ✅ 教練資料載入成功: ${coach.displayName ?? coach.email}');
            }
          } else {
            if (kDebugMode) {
              debugPrint('[CoachManagementController] ⚠️ 教練資料不存在: ${relationship.coachId}');
            }
          }
        } catch (e) {
          _errorService.logError('載入教練資訊失敗: $e');
          if (kDebugMode) {
            debugPrint('[CoachManagementController] ❌ 載入教練資訊失敗: $e');
          }
        }
      }

      _coaches = coachUsers;
      _filteredCoaches = List.from(_coaches);
      
      if (kDebugMode) {
        debugPrint('[CoachManagementController] ✅ 教練列表更新完成，共 ${_coaches.length} 位教練');
      }
      
      notifyListeners();
    } catch (e) {
      _handleError('載入教練列表失敗', e);
      if (kDebugMode) {
        debugPrint('[CoachManagementController] ❌ 載入教練列表失敗: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// 搜尋教練
  @override
  void searchCoaches(String query) {
    _searchQuery = query.trim();

    if (_searchQuery.isEmpty) {
      _filteredCoaches = List.from(_coaches);
    } else {
      _filteredCoaches = _coaches.where((coach) {
        final name = (coach.displayName ?? '').toLowerCase();
        final email = coach.email.toLowerCase();
        final q = _searchQuery.toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    }

    notifyListeners();
  }

  /// 清除搜尋
  @override
  void clearSearch() {
    _searchQuery = '';
    _filteredCoaches = List.from(_coaches);
    notifyListeners();
  }

  // ============================================================================
  // 教練詳情管理
  // ============================================================================

  /// 選擇教練（進入詳情頁）
  @override
  Future<void> selectCoach(String coachId, String currentUserId) async {
    _setLoading(true);
    _clearError();

    try {
      // 載入教練基本資訊
      _selectedCoach = await _userService.getUserProfile(coachId);

      // 載入該教練指派的訓練計畫
      await loadCoachWorkouts(currentUserId, coachId);

      notifyListeners();
    } catch (e) {
      _handleError('載入教練資料失敗', e);
    } finally {
      _setLoading(false);
    }
  }

  /// 清除選中的教練
  @override
  void clearSelectedCoach() {
    _selectedCoach = null;
    _coachWorkouts = [];
    notifyListeners();
  }

  // ============================================================================
  // 訓練計畫管理
  // ============================================================================

  /// 載入該教練指派的訓練計畫
  @override
  Future<void> loadCoachWorkouts(
    String traineeId,
    String coachId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // ⭐ 重要：必須明確傳遞 userId，否則會查詢當前登入用戶的訓練！
      final allWorkouts = await _workoutService.getUserPlans(
        userId: traineeId,  // ⭐ 明確指定查詢的是學員的訓練計畫
        completed: null,  // 查詢所有（完成和未完成）
        limit: 100,
      );

      // 篩選出該教練創建的訓練
      _coachWorkouts = allWorkouts
          .where((w) => w.creatorId == coachId && (w.traineeId ?? w.userId) == traineeId)
          .toList();

      notifyListeners();
    } catch (e) {
      _errorService.logError('載入教練訓練計畫失敗: $e');
      rethrow;
    }
  }

  /// 根據日期查詢訓練計畫
  @override
  List<WorkoutRecord> getWorkoutsForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return _coachWorkouts.where((workout) {
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
    _errorService.logError('$message: $error', type: 'CoachManagementError');
    notifyListeners();
  }

  @override
  void dispose() {
    // 清理資源
    super.dispose();
  }
}

