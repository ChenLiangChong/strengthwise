import '../../models/readiness/daily_readiness_model.dart';

/// 課前問卷服務介面
///
/// 提供學員課前準備度問卷的查詢、建立與更新功能
abstract class IReadinessService {
  /// 取得指定預約的問卷
  ///
  /// [appointmentId] 預約 ID
  ///
  /// 返回問卷，若不存在則返回 null
  Future<DailyReadinessModel?> getByAppointmentId(String appointmentId);

  /// 取得指定用戶指定日期的問卷
  ///
  /// [userId] 用戶 ID
  /// [date] 日期
  ///
  /// 返回問卷，若不存在則返回 null
  Future<DailyReadinessModel?> getByUserAndDate(String userId, DateTime date);

  /// 取得用戶最近的問卷記錄
  ///
  /// [userId] 用戶 ID
  /// [limit] 最多返回筆數（預設 10）
  ///
  /// 返回問卷列表，按日期降序排列
  Future<List<DailyReadinessModel>> getRecentByUser(
    String userId, {
    int limit = 10,
  });

  /// 建立新問卷（學員提交時）
  ///
  /// [readiness] 問卷模型（包含 metrics）
  ///
  /// 返回包含計算後分數和紅綠燈的問卷
  Future<DailyReadinessModel> createReadiness(DailyReadinessModel readiness);

  /// 更新現有問卷
  ///
  /// [readiness] 問卷模型（必須包含 id）
  Future<DailyReadinessModel> updateReadiness(DailyReadinessModel readiness);

  /// 教練取得指定學員的問卷
  ///
  /// [coachId] 教練 ID（用於 RLS 驗證）
  /// [clientId] 學員 ID
  /// [appointmentId] 預約 ID（可選）
  ///
  /// 若指定 appointmentId，返回該預約的問卷
  /// 否則返回學員最近的問卷
  Future<DailyReadinessModel?> getClientReadiness({
    required String coachId,
    required String clientId,
    String? appointmentId,
  });

  /// 批次取得多位學員的最近問卷
  ///
  /// [clientIds] 學員 ID 列表
  ///
  /// 返回 Map，key 為 clientId，value 為問卷（可能為 null）
  Future<Map<String, DailyReadinessModel?>> batchGetLatestReadiness(
    List<String> clientIds,
  );

  /// 計算準備度分數和紅綠燈狀態
  ///
  /// [metrics] 詳細指標
  ///
  /// 返回 { 'score': int, 'trafficLight': TrafficLight }
  Map<String, dynamic> calculateReadinessScore(ReadinessMetrics metrics);
}

