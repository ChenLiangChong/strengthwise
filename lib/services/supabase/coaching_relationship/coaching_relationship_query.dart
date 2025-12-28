import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/coaching_relationship_model.dart';

/// 教練-學員關係查詢邏輯
///
/// 負責所有與 coaching_relationships 表的查詢操作
class CoachingRelationshipQuery {
  final SupabaseClient _supabase;

  CoachingRelationshipQuery(this._supabase);

  /// 明確選擇的欄位（避免 SELECT *）
  static const String _selectFields = '''
    id,
    coach_id,
    client_id,
    status,
    notes,
    invited_at,
    accepted_at,
    created_at,
    updated_at
  ''';

  /// 查詢教練的學員關係
  ///
  /// [coachId] 教練 ID
  /// [status] 過濾狀態（可選）
  Future<List<CoachingRelationshipModel>> queryCoachClients(
    String coachId, {
    String? status,
  }) async {
    var query = _supabase
        .from('coaching_relationships')
        .select(_selectFields)
        .eq('coach_id', coachId);

    // 狀態過濾
    if (status != null) {
      query = query.eq('status', status);
    }

    final data = await query.order('created_at', ascending: false);

    return (data as List)
        .map((json) =>
            CoachingRelationshipModel.fromSupabase(json as Map<String, dynamic>))
        .toList();
  }

  /// 查詢學員的教練關係
  ///
  /// [clientId] 學員 ID
  /// [status] 過濾狀態（可選）
  Future<List<CoachingRelationshipModel>> queryClientCoaches(
    String clientId, {
    String? status,
  }) async {
    var query = _supabase
        .from('coaching_relationships')
        .select(_selectFields)
        .eq('client_id', clientId);

    if (status != null) {
      query = query.eq('status', status);
    }

    final data = await query.order('created_at', ascending: false);

    return (data as List)
        .map((json) =>
            CoachingRelationshipModel.fromSupabase(json as Map<String, dynamic>))
        .toList();
  }

  /// 檢查是否存在活躍關係
  ///
  /// [coachId] 教練 ID
  /// [clientId] 學員 ID
  Future<bool> checkActiveRelationship(
    String coachId,
    String clientId,
  ) async {
    final response = await _supabase
        .from('coaching_relationships')
        .select('id')
        .eq('coach_id', coachId)
        .eq('client_id', clientId)
        .eq('status', 'active')
        .maybeSingle();

    return response != null;
  }

  /// 獲取活躍學員數量
  ///
  /// [coachId] 教練 ID
  Future<int> getActiveClientCount(String coachId) async {
    final data = await _supabase
        .from('coaching_relationships')
        .select('id')
        .eq('coach_id', coachId)
        .eq('status', 'active');

    return (data as List).length;
  }

  /// 根據 ID 查詢單筆關係
  ///
  /// [relationshipId] 關係 ID
  Future<CoachingRelationshipModel?> queryById(String relationshipId) async {
    final response = await _supabase
        .from('coaching_relationships')
        .select(_selectFields)
        .eq('id', relationshipId)
        .maybeSingle();

    if (response == null) return null;

    return CoachingRelationshipModel.fromSupabase(response);
  }

  /// 查詢教練的學員 ID 列表（用於批量查詢用戶資料）
  ///
  /// [coachId] 教練 ID
  /// [status] 過濾狀態（可選）
  Future<List<String>> queryClientIds(
    String coachId, {
    String? status,
  }) async {
    var query = _supabase
        .from('coaching_relationships')
        .select('client_id')
        .eq('coach_id', coachId);

    if (status != null) {
      query = query.eq('status', status);
    }

    final data = await query;

    return (data as List)
        .map((json) => json['client_id'] as String)
        .toList();
  }
}

