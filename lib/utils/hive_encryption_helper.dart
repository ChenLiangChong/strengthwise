import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Hive 加密輔助工具
///
/// 使用 flutter_secure_storage 安全儲存 Hive 加密金鑰，
/// 確保本地快取資料加密存放。
///
/// 用法：
/// ```dart
/// await HiveEncryptionHelper.initialize();
/// final box = await HiveEncryptionHelper.openBox('cache_name');
/// ```
class HiveEncryptionHelper {
  static const String _secureStorageKey = 'hive_encryption_key';
  static HiveAesCipher? _cipher;
  static bool _isInitialized = false;

  /// 初始化加密金鑰
  ///
  /// 從 flutter_secure_storage 讀取既有金鑰，若不存在則生成並儲存。
  /// 必須在開啟任何 Hive Box 之前呼叫。
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const secureStorage = FlutterSecureStorage();

      // 嘗試讀取既有金鑰
      String? encodedKey = await secureStorage.read(key: _secureStorageKey);

      if (encodedKey == null) {
        // 生成新的 256-bit 加密金鑰
        final key = _generateSecureKey();
        encodedKey = base64Url.encode(key);

        // 安全儲存金鑰
        await secureStorage.write(key: _secureStorageKey, value: encodedKey);

        if (kDebugMode) {
          debugPrint('[HIVE_ENCRYPTION] 已生成並儲存新的加密金鑰');
        }
      }

      final key = base64Url.decode(encodedKey);
      _cipher = HiveAesCipher(key);
      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('[HIVE_ENCRYPTION] 加密金鑰初始化完成');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HIVE_ENCRYPTION] 加密初始化失敗: $e，降級為無加密模式');
      }
      // 加密初始化失敗時降級為無加密模式（不影響 App 啟動）
      _isInitialized = true;
      _cipher = null;
    }
  }

  /// 生成安全的 256-bit 金鑰
  static List<int> _generateSecureKey() {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }

  /// 開啟加密的 Hive Box
  ///
  /// 如果加密金鑰可用則使用加密，否則降級為無加密。
  /// 如果加密 Box 無法開啟（例如金鑰更換），會自動刪除舊 Box 並重建。
  static Future<Box> openBox(String name) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await Hive.openBox(
        name,
        encryptionCipher: _cipher,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HIVE_ENCRYPTION] Box "$name" 開啟失敗: $e，嘗試重建');
      }

      // 加密金鑰不匹配或 Box 損壞，刪除後重建
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {
        // 刪除失敗忽略
      }

      return await Hive.openBox(
        name,
        encryptionCipher: _cipher,
      );
    }
  }
}
