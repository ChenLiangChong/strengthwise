/// Firestore 相容 ID 生成器
class CustomExerciseIdGenerator {
  /// 生成 Firestore 相容 ID（20 字符）
  static String generate() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();
    
    for (int i = 0; i < 20; i++) {
      final index = ((random * (i + 1)) ^ (random >> i)) % chars.length;
      buffer.write(chars[index.abs() % chars.length]);
    }
    
    return buffer.toString();
  }
}

