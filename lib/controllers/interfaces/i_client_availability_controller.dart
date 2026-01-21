import 'package:flutter/foundation.dart';
import '../../models/client_availability_model.dart';

/// 學員時間偏好控制器接口
///
/// 管理學員可運動時間的設定（雙向時間管理系統）
abstract class IClientAvailabilityController extends ChangeNotifier {
  // ==================== 狀態 Getters ====================

  /// 載入中狀態
  bool get isLoading;

  /// 錯誤訊息
  String? get errorMessage;

  /// 時間偏好列表
  List<ClientAvailabilityModel> get availabilities;

  /// 當前選中的時間偏好
  ClientAvailabilityModel? get selectedAvailability;

  // 統計資料
  int get totalCount;
  int get preferredCount;
  int get availableCount;
  int get avoidCount;

  // 衍生狀態
  bool get hasAvailabilities;
  bool get hasError;
  List<ClientAvailabilityModel> get preferredSlots;
  List<ClientAvailabilityModel> get avoidSlots;
  List<ClientAvailabilityModel> get recurringSlots;

  // ==================== 查詢功能 ====================

  /// 載入學員的時間偏好設定
  Future<void> loadClientAvailabilities({
    required String clientId,
    AvailabilityPriority? priority,
  });

  /// 載入指定日期範圍內的時間偏好
  Future<void> loadAvailabilitiesInRange({
    required String clientId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// 載入教練查看學員的時間偏好
  Future<void> loadClientAvailabilitiesForCoach({
    required String coachId,
    required String clientId,
  });

  /// 檢查時段衝突
  Future<bool> hasConflict({
    required String clientId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeId,
  });

  // ==================== CRUD 功能 ====================

  /// 創建時間偏好
  Future<ClientAvailabilityModel?> createAvailability(ClientAvailabilityModel availability);

  /// 更新時間偏好
  Future<ClientAvailabilityModel?> updateAvailability(ClientAvailabilityModel availability);

  /// 刪除時間偏好
  Future<bool> deleteAvailability(String id);

  /// 複製週時段
  Future<int> copyWeekAvailabilities({
    required String clientId,
    required DateTime sourceWeekStart,
    required DateTime targetWeekStart,
  });

  /// 批次創建週期性時段
  Future<List<ClientAvailabilityModel>> batchCreateRecurring({
    required ClientAvailabilityModel template,
    required List<DateTime> dates,
  });

  // ==================== 狀態管理 ====================

  void setSelectedAvailability(ClientAvailabilityModel? availability);
  void clearSelectedAvailability();
  void clearError();
  void reset();

  // ==================== MVVM 查詢方法 ====================

  /// 查詢教練視角下學員的時間偏好（直接返回結果）
  Future<List<ClientAvailabilityModel>> getClientAvailabilityForCoach({
    required String coachId,
    required String clientId,
  });
}
