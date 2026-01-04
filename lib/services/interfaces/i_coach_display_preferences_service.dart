import '../../models/coach_display_preferences_model.dart';

/// 教練顯示偏好服務介面
/// 
/// 管理教練在學員詳情頁的顯示偏好設定
abstract class ICoachDisplayPreferencesService {
  /// 取得指定教練的顯示偏好
  /// 
  /// [coachId] 教練 ID
  /// 
  /// 若不存在則返回預設偏好
  Future<CoachDisplayPreferencesModel> getPreferences(String coachId);

  /// 更新顯示偏好
  /// 
  /// [preferences] 偏好模型
  /// 
  /// 使用 UPSERT 操作（不存在則插入，存在則更新）
  Future<void> updatePreferences(CoachDisplayPreferencesModel preferences);

  /// 重置為預設偏好
  /// 
  /// [coachId] 教練 ID
  Future<void> resetToDefault(String coachId);
}

