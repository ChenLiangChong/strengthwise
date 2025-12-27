import 'dart:math';

/// ID 生成器
/// 
/// 負責生成 Firestore 兼容格式的 ID
class WorkoutIdGenerator {
  /// 生成 Firestore 兼容格式的 ID
  static String generateFirestoreId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    final buffer = StringBuffer();

    // 生成 20 個字符的隨機 ID（類似 Firestore）
    for (int i = 0; i < 20; i++) {
      buffer.write(chars[random.nextInt(chars.length)]);
    }

    return buffer.toString();
  }
}

