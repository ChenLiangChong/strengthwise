import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strengthwise/utils/datetime_utils.dart';
import '../../../models/coaching_relationship_model.dart';

/// 教練-學員關係 CRUD 操作
///
/// 負責創建、更新、刪除操作
class CoachingRelationshipOperations {
  final SupabaseClient _supabase;

  CoachingRelationshipOperations(this._supabase);

  /// 創建新關係（邀請學員）
  ///
  /// [coachId] 教練 ID
  /// [clientId] 學員 ID
  /// [status] 初始狀態（預設 'pending'）
  Future<CoachingRelationshipModel> createRelationship({
    required String coachId,
    required String clientId,
    String status = 'pending',
  }) async {
    // ⭐ 檢查是否已存在關係
    final existing = await _supabase
        .from('coaching_relationships')
        .select('id, status')
        .eq('coach_id', coachId)
        .eq('client_id', clientId)
        .maybeSingle();

    if (existing != null) {
      final existingStatus = existing['status'] as String?;
      final existingId = existing['id'] as String;

      // 如果是 active 關係，不允許重複綁定
      if (existingStatus == 'active') {
        throw Exception('該學員已存在有效的綁定關係');
      }

      // ⭐ 如果是 archived 關係，重新激活（更新狀態為 active）
      if (existingStatus == 'archived') {
        final now = DateTimeUtils.formatToUtcIso(DateTime.now());

        // 執行 UPDATE 操作
        await _supabase.from('coaching_relationships').update({
          'status': 'active',
          'invited_at': now,
          'accepted_at': now,
          'updated_at': now,
        }).eq('id', existingId);

        // 重新查詢完整資料
        final response = await _supabase
            .from('coaching_relationships')
            .select(
                'id, coach_id, client_id, coach_name, client_name, status, invited_at, accepted_at, created_at, updated_at')
            .eq('id', existingId)
            .single();

        return CoachingRelationshipModel.fromSupabase(response);
      }
    }

    // 創建新關係
    final now = DateTimeUtils.formatToUtcIso(DateTime.now());
    final data = {
      'coach_id': coachId,
      'client_id': clientId,
      'status': status,
      'invited_at': now,
      'created_at': now,
      'updated_at': now,
    };

    final response = await _supabase
        .from('coaching_relationships')
        .insert(data)
        .select(
            'id, coach_id, client_id, coach_name, client_name, status, invited_at, accepted_at, created_at, updated_at')
        .single();

    return CoachingRelationshipModel.fromSupabase(response);
  }

  /// 更新關係狀態
  ///
  /// [relationshipId] 關係 ID
  /// [status] 新狀態
  /// [acceptedAt] 接受時間（可選，當狀態為 active 時設置）
  Future<void> updateStatus({
    required String relationshipId,
    required String status,
    DateTime? acceptedAt,
  }) async {
    final data = <String, dynamic>{
      'status': status,
      'updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
    };

    // 如果狀態為 active，記錄接受時間
    if (status == 'active' && acceptedAt != null) {
      data['accepted_at'] = DateTimeUtils.formatToUtcIso(acceptedAt);
    }

    await _supabase
        .from('coaching_relationships')
        .update(data)
        .eq('id', relationshipId);
  }

  /// 刪除關係（軟刪除：更新狀態為 archived）
  ///
  /// [relationshipId] 關係 ID
  /// ⚠️ 不直接刪除記錄，改為歸檔，以便保留歷史數據
  Future<void> deleteRelationship(String relationshipId) async {
    await _supabase.from('coaching_relationships').update({
      'status': 'archived',
      'updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
    }).eq('id', relationshipId);
  }

  /// 批量更新狀態（歸檔舊關係）
  ///
  /// [coachId] 教練 ID
  /// [clientIds] 學員 ID 列表
  /// [status] 目標狀態
  Future<void> batchUpdateStatus({
    required String coachId,
    required List<String> clientIds,
    required String status,
  }) async {
    await _supabase
        .from('coaching_relationships')
        .update({
          'status': status,
          'updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
        })
        .eq('coach_id', coachId)
        .inFilter('client_id', clientIds);
  }
}
