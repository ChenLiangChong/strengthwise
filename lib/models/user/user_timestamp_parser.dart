/// 使用者時間戳解析工具
///
/// 提供統一的時間戳解析邏輯，支援多種格式
class UserTimestampParser {
  /// 解析時間戳記（支援多種格式）
  static DateTime? parse(dynamic timestamp) {
    if (timestamp == null) return null;
    
    if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is int) {
      // Unix 時間戳記（毫秒）
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      // ISO 8601 字串格式（Supabase 常用）
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return null;
      }
    } else if (timestamp.runtimeType.toString() == 'Timestamp') {
      // Timestamp 類型（向後相容 Firestore）
      return DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
    }
    
    return null;
  }
}

