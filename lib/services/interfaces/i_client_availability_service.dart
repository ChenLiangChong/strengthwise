import 'package:strengthwise/models/client_availability_model.dart';

/// Client Availability Service Interface
/// 
/// Phase 3: 雙向時間管理系統
/// 定義學員時間偏好相關操作的接口
abstract class IClientAvailabilityService {
  // ==================== 查詢方法 ====================

  /// 取得學員的時間偏好列表
  Future<List<ClientAvailabilityModel>> getClientAvailability({
    required String clientId,
    AvailabilityPriority? priority,
  });

  /// 取得單筆時間偏好
  Future<ClientAvailabilityModel?> getAvailabilityById(String id);

  /// 取得指定日期範圍內的學員時間偏好
  Future<List<ClientAvailabilityModel>> getAvailabilityInRange({
    required String clientId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// 教練查看學員的時間偏好（需 active relationship）
  Future<List<ClientAvailabilityModel>> getClientAvailabilityForCoach({
    required String coachId,
    required String clientId,
  });

  // ==================== CRUD 操作 ====================

  /// 創建時間偏好
  Future<ClientAvailabilityModel> createAvailability(
    ClientAvailabilityModel availability,
  );

  /// 更新時間偏好
  Future<ClientAvailabilityModel> updateAvailability(
    ClientAvailabilityModel availability,
  );

  /// 刪除時間偏好
  Future<void> deleteAvailability(String id);

  /// 批量創建時間偏好（例如：一次設定整週的時段）
  Future<List<ClientAvailabilityModel>> batchCreateAvailability(
    List<ClientAvailabilityModel> availabilities,
  );

  // ==================== 輔助方法 ====================

  /// 檢查時間範圍是否衝突
  /// 
  /// 返回 true 表示有衝突
  Future<bool> hasConflict({
    required String clientId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeId, // 更新時排除自己
  });

  /// 取得最佳訓練時段建議（依優先級排序）
  Future<List<ClientAvailabilityModel>> getPreferredTimeSlots({
    required String clientId,
    required DateTime date,
  });
}

