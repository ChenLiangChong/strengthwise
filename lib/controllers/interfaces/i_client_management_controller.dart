import 'package:flutter/foundation.dart';
import '../../models/user/user_model.dart';
import '../../models/workout_record/workout_record.dart';
import '../../models/client_availability_model.dart';

/// 教練端學員管理控制器接口
///
/// 負責教練查看學員詳情、管理學員訓練計畫等功能
abstract class IClientManagementController extends ChangeNotifier {
  // ==================== 狀態 Getters ====================

  /// 載入中狀態
  bool get isLoading;

  /// 錯誤訊息
  String? get errorMessage;

  /// 當前選中的學員
  UserModel? get selectedClient;

  /// 學員列表
  List<UserModel> get clients;

  /// 篩選後的學員列表
  List<UserModel> get filteredClients;

  /// 選中學員的訓練計畫
  List<WorkoutRecord> get clientWorkouts;

  /// 選中學員的時間偏好
  List<ClientAvailabilityModel> get clientAvailability;

  /// 搜尋關鍵字
  String get searchQuery;

  // ==================== 學員列表管理 ====================

  /// 載入教練的學員列表
  Future<void> loadClients(String coachId);

  /// 搜尋學員
  void searchClients(String query);

  /// 清除搜尋
  void clearSearch();

  // ==================== 學員詳情管理 ====================

  /// 選擇學員（進入詳情頁）
  Future<void> selectClient(String clientId);

  /// 清除選中的學員
  void clearSelectedClient();

  // ==================== 訓練計畫管理 ====================

  /// 載入學員的訓練計畫
  Future<void> loadClientWorkouts(String clientId, {DateTime? startDate, DateTime? endDate});

  /// 教練為學員創建訓練計畫
  Future<bool> createWorkoutForClient({
    required String coachId,
    required String clientId,
    required DateTime scheduledDate,
    required String title,
    String? notes,
    List<Map<String, dynamic>>? exercises,
  });

  /// 更新訓練計畫
  Future<bool> updateWorkout(WorkoutRecord workout);

  /// 刪除訓練計畫
  Future<bool> deleteWorkout(String workoutId);

  // ==================== 時間偏好管理 ====================

  /// 載入學員的時間偏好
  Future<void> loadClientAvailability(String clientId, {DateTime? startDate, DateTime? endDate});

  /// 增量刪除學員可訓練時間（本地）
  bool removeClientAvailabilityById(String availabilityId);

  /// 根據日期查詢時間偏好
  List<ClientAvailabilityModel> getAvailabilityForDate(DateTime date);

  /// 根據日期查詢訓練計畫
  List<WorkoutRecord> getWorkoutsForDate(DateTime date);
}
