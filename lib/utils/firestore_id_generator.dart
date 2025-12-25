import 'dart:math';

/// 生成 Firestore 相容的 20 字符 ID
/// 
/// 用於在 Supabase 中生成與 Firestore 相容的文檔 ID
String generateFirestoreId() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random.secure();
  final buffer = StringBuffer();
  
  // 生成 20 個字符的隨機 ID（類似 Firestore）
  for (int i = 0; i < 20; i++) {
    buffer.write(chars[random.nextInt(chars.length)]);
  }
  
  return buffer.toString();
}

