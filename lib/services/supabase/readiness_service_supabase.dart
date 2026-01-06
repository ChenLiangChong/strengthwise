import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strengthwise/models/readiness/daily_readiness_model.dart';
import 'package:strengthwise/services/interfaces/i_readiness_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/utils/datetime_utils.dart';

/// 課前問卷服務 Supabase 實作
class ReadinessServiceSupabase implements IReadinessService {
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;

  /// 資料表名稱
  static const String _tableName = 'daily_readiness';

  /// 查詢欄位（避免 SELECT *）
  static const String _selectFields = '''
    id,
    user_id,
    appointment_id,
    session_note_id,
    log_date,
    readiness_score,
    traffic_light,
    metrics,
    created_at,
    updated_at
  ''';

  ReadinessServiceSupabase(
    this._supabase,
    this._errorService,
  );

  @override
  Future<DailyReadinessModel?> getByAppointmentId(String appointmentId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select(_selectFields)
          .eq('appointment_id', appointmentId)
          .maybeSingle();

      if (response == null) return null;
      return DailyReadinessModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '取得預約問卷失敗: $e',
        type: 'ReadinessServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<DailyReadinessModel?> getByUserAndDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final dateStr = DateTimeUtils.formatToDateOnly(date);
      final response = await _supabase
          .from(_tableName)
          .select(_selectFields)
          .eq('user_id', userId)
          .eq('log_date', dateStr)
          .maybeSingle();

      if (response == null) return null;
      return DailyReadinessModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '取得用戶日期問卷失敗: $e',
        type: 'ReadinessServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<List<DailyReadinessModel>> getRecentByUser(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select(_selectFields)
          .eq('user_id', userId)
          .order('log_date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) =>
              DailyReadinessModel.fromSupabase(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorService.logError(
        '取得用戶問卷歷史失敗: $e',
        type: 'ReadinessServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<DailyReadinessModel> createReadiness(
    DailyReadinessModel readiness,
  ) async {
    try {
      // 計算分數和紅綠燈
      final calculated = calculateReadinessScore(readiness.metrics);
      final score = calculated['score'] as int;
      final trafficLight = calculated['trafficLight'] as TrafficLight;

      // 更新模型
      final toInsert = readiness.copyWith(
        readinessScore: score,
        trafficLight: trafficLight,
      );

      final response = await _supabase
          .from(_tableName)
          .insert(toInsert.toSupabase())
          .select(_selectFields)
          .single();

      return DailyReadinessModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '建立問卷失敗: $e',
        type: 'ReadinessServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<DailyReadinessModel> updateReadiness(
    DailyReadinessModel readiness,
  ) async {
    try {
      // 重新計算分數和紅綠燈
      final calculated = calculateReadinessScore(readiness.metrics);
      final score = calculated['score'] as int;
      final trafficLight = calculated['trafficLight'] as TrafficLight;

      final toUpdate = readiness.copyWith(
        readinessScore: score,
        trafficLight: trafficLight,
      );

      final response = await _supabase
          .from(_tableName)
          .update(toUpdate.toSupabase())
          .eq('id', readiness.id)
          .select(_selectFields)
          .single();

      return DailyReadinessModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '更新問卷失敗: $e',
        type: 'ReadinessServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<DailyReadinessModel?> getClientReadiness({
    required String coachId,
    required String clientId,
    String? appointmentId,
  }) async {
    try {
      // RLS 會自動驗證 coaching_relationships

      if (appointmentId != null) {
        return await getByAppointmentId(appointmentId);
      }

      // 取得學員最近的問卷
      final list = await getRecentByUser(clientId, limit: 1);
      return list.isNotEmpty ? list.first : null;
    } catch (e) {
      _errorService.logError(
        '教練取得學員問卷失敗: $e',
        type: 'ReadinessServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, DailyReadinessModel?>> batchGetLatestReadiness(
    List<String> clientIds,
  ) async {
    if (clientIds.isEmpty) return {};

    try {
      // 使用 RPC 或子查詢取得每位學員的最新問卷
      // 這裡使用簡單方法：取得所有問卷然後在記憶體中分組
      final response = await _supabase
          .from(_tableName)
          .select(_selectFields)
          .inFilter('user_id', clientIds)
          .order('log_date', ascending: false);

      final result = <String, DailyReadinessModel?>{};

      // 初始化所有 clientId 為 null
      for (final clientId in clientIds) {
        result[clientId] = null;
      }

      // 只保留每位學員的最新問卷
      for (final json in response as List) {
        final readiness =
            DailyReadinessModel.fromSupabase(json as Map<String, dynamic>);
        if (result[readiness.userId] == null) {
          result[readiness.userId] = readiness;
        }
      }

      return result;
    } catch (e) {
      _errorService.logError(
        '批次取得學員問卷失敗: $e',
        type: 'ReadinessServiceError',
      );
      rethrow;
    }
  }

  /// 計算準備度分數和紅綠燈狀態
  ///
  /// 基於 Hooper Index 權重計算：
  /// - 睡眠品質：30%
  /// - 睡眠時數：10%（轉換為 1-5 分）
  /// - 肌肉痠痛：25%
  /// - 心理壓力：20%
  /// - 能量水平：15%
  ///
  /// 紅綠燈判定：
  /// - 🟢 GREEN：總分 ≥ 70
  /// - 🟡 AMBER：50 ≤ 總分 < 70
  /// - 🔴 RED：總分 < 50 或任一指標 = 1
  @override
  Map<String, dynamic> calculateReadinessScore(ReadinessMetrics metrics) {
    // 睡眠時數轉換為 1-5 分
    final sleepHoursScore = _convertSleepHoursToScore(metrics.sleepHours);

    // 權重計算（每項 1-5 分 × 權重 × 20 = 0-100）
    final score = (metrics.sleepQuality * 0.30 * 20 +
            sleepHoursScore * 0.10 * 20 +
            metrics.soreness * 0.25 * 20 +
            metrics.stress * 0.20 * 20 +
            metrics.energyLevel * 0.15 * 20)
        .round();

    // 紅綠燈判定
    TrafficLight trafficLight;

    // 任一指標 = 1 直接紅燈
    if (metrics.sleepQuality == 1 ||
        metrics.soreness == 1 ||
        metrics.stress == 1 ||
        metrics.energyLevel == 1 ||
        metrics.sleepHours < 4) {
      trafficLight = TrafficLight.red;
    } else if (score >= 70) {
      trafficLight = TrafficLight.green;
    } else if (score >= 50) {
      trafficLight = TrafficLight.amber;
    } else {
      trafficLight = TrafficLight.red;
    }

    return {
      'score': score,
      'trafficLight': trafficLight,
    };
  }

  /// 將睡眠時數轉換為 1-5 分
  ///
  /// - ≤4hr: 1 分
  /// - 4-5hr: 2 分
  /// - 5-6hr: 3 分
  /// - 6-8hr: 4 分
  /// - ≥8hr: 5 分
  int _convertSleepHoursToScore(double hours) {
    if (hours <= 4) return 1;
    if (hours <= 5) return 2;
    if (hours <= 6) return 3;
    if (hours <= 8) return 4;
    return 5;
  }
}
