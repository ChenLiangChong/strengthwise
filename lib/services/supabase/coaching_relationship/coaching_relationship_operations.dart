import 'package:supabase_flutter/supabase_flutter.dart';
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
  /// [notes] 備註
  Future<CoachingRelationshipModel> createRelationship({
    required String coachId,
    required String clientId,
    String status = 'pending',
    String? notes,
  }) async {
    // 檢查是否已存在關係
    final existing = await _supabase
        .from('coaching_relationships')
        .select('id')
        .eq('coach_id', coachId)
        .eq('client_id', clientId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('該學員已存在綁定關係');
    }

    // 創建新關係
    final now = DateTime.now().toIso8601String();
    final data = {
      'coach_id': coachId,
      'client_id': clientId,
      'status': status,
      'notes': notes,
      'invited_at': now,
      'created_at': now,
      'updated_at': now,
    };

    final response = await _supabase
        .from('coaching_relationships')
        .insert(data)
        .select()
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
      'updated_at': DateTime.now().toIso8601String(),
    };

    // 如果狀態為 active，記錄接受時間
    if (status == 'active' && acceptedAt != null) {
      data['accepted_at'] = acceptedAt.toIso8601String();
    }

    await _supabase
        .from('coaching_relationships')
        .update(data)
        .eq('id', relationshipId);
  }

  /// 更新備註
  ///
  /// [relationshipId] 關係 ID
  /// [notes] 新備註內容
  Future<void> updateNotes({
    required String relationshipId,
    required String notes,
  }) async {
    await _supabase.from('coaching_relationships').update({
      'notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', relationshipId);
  }

  /// 刪除關係
  ///
  /// [relationshipId] 關係 ID
  Future<void> deleteRelationship(String relationshipId) async {
    await _supabase
        .from('coaching_relationships')
        .delete()
        .eq('id', relationshipId);
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
    await _supabase.from('coaching_relationships').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('coach_id', coachId).inFilter('client_id', clientIds);
  }
}

