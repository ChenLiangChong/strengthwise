import '../../models/favorite_exercise_model.dart';

/// 收藏服務介面
/// 
/// 定義與收藏動作相關的所有操作
/// 使用 SharedPreferences 進行本地持久化儲存
abstract class IFavoritesService {
  /// 獲取使用者的所有收藏動作 ID
  /// 
  /// [userId] 使用者 ID
  /// 返回收藏的動作 ID 列表
  Future<List<String>> getFavoriteExerciseIds(String userId);

  /// 獲取使用者的所有收藏動作詳細資訊
  /// 
  /// [userId] 使用者 ID
  /// 返回收藏動作的完整資訊列表
  Future<List<FavoriteExercise>> getFavoriteExercises(String userId);

  /// 添加動作到收藏
  /// 
  /// [userId] 使用者 ID
  /// [exerciseId] 動作 ID
  /// [exerciseName] 動作名稱
  /// [bodyPart] 身體部位
  Future<void> addFavorite(
    String userId,
    String exerciseId,
    String exerciseName,
    String bodyPart,
  );

  /// 移除收藏動作
  /// 
  /// [userId] 使用者 ID
  /// [exerciseId] 要移除的動作 ID
  Future<void> removeFavorite(String userId, String exerciseId);

  /// 檢查動作是否已收藏
  /// 
  /// [userId] 使用者 ID
  /// [exerciseId] 動作 ID
  /// 返回 true 表示已收藏
  Future<bool> isFavorite(String userId, String exerciseId);

  /// 更新動作的最後查看時間
  /// 
  /// [userId] 使用者 ID
  /// [exerciseId] 動作 ID
  Future<void> updateLastViewedAt(String userId, String exerciseId);

  /// 清空使用者的所有收藏
  /// 
  /// [userId] 使用者 ID
  Future<void> clearFavorites(String userId);
}

