import 'package:flutter/foundation.dart';
import '../../models/user/user_model.dart';
import '../../models/workout_record/workout_record.dart';

/// 學員端教練管理控制器接口
///
/// 負責學員查看教練列表、查看教練指派的訓練等功能
abstract class ICoachManagementController extends ChangeNotifier {
  // ==================== 狀態 Getters ====================

  /// 載入中狀態
  bool get isLoading;

  /// 錯誤訊息
  String? get errorMessage;

  /// 當前選中的教練
  UserModel? get selectedCoach;

  /// 教練列表
  List<UserModel> get coaches;

  /// 篩選後的教練列表
  List<UserModel> get filteredCoaches;

  /// 選中教練指派的訓練計畫
  List<WorkoutRecord> get coachWorkouts;

  /// 搜尋關鍵字
  String get searchQuery;

  // ==================== 教練列表管理 ====================

  /// 載入學員的教練列表
  Future<void> loadCoaches(String clientId);

  /// 搜尋教練
  void searchCoaches(String query);

  /// 清除搜尋
  void clearSearch();

  // ==================== 教練詳情管理 ====================

  /// 選擇教練（進入詳情頁）
  Future<void> selectCoach(String coachId, String currentUserId);

  /// 清除選中的教練
  void clearSelectedCoach();

  // ==================== 訓練查詢 ====================

  /// 載入該教練指派的訓練計畫
  Future<void> loadCoachWorkouts(
    String traineeId,
    String coachId, {
    DateTime? startDate,
    DateTime? endDate,
  });

  /// 根據日期查詢訓練計畫
  List<WorkoutRecord> getWorkoutsForDate(DateTime date);
}
