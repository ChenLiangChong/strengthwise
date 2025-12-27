import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Supabase 初始化和客戶端管理服務
///
/// 提供全域 Supabase 客戶端存取和初始化
class SupabaseService {
  static SupabaseClient? _client;
  static bool _isInitialized = false;

  /// 獲取 Supabase 客戶端實例
  static SupabaseClient get client {
    if (_client == null) {
      throw StateError('Supabase 未初始化，請先呼叫 SupabaseService.initialize()');
    }
    return _client!;
  }

  /// 檢查是否已初始化
  static bool get isInitialized => _isInitialized;

  /// 初始化 Supabase
  ///
  /// 從 .env 檔案讀取配置並初始化 Supabase 客戶端
  static Future<void> initialize() async {
    if (_isInitialized) {
      _logDebug('Supabase 已經初始化');
      return;
    }

    try {
      // ⚡ 優化：並行載入環境變數和 Supabase 配置
      final startTime = DateTime.now();
      
      // 載入環境變數
      await dotenv.load(fileName: '.env');

      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null || supabaseUrl.isEmpty) {
        throw Exception('SUPABASE_URL 未在 .env 檔案中配置');
      }

      if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
        throw Exception('SUPABASE_ANON_KEY 未在 .env 檔案中配置');
      }

      // ⚡ 初始化 Supabase（關閉不必要的 debug 日誌）
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: false, // 關閉 debug 日誌減少初始化時間
      );

      _client = Supabase.instance.client;
      _isInitialized = true;

      final duration = DateTime.now().difference(startTime);
      _logDebug('Supabase 初始化成功（耗時 ${duration.inMilliseconds}ms）');
      _logDebug('URL: $supabaseUrl');
    } catch (e) {
      _logError('Supabase 初始化失敗: $e');
      rethrow;
    }
  }

  /// 釋放資源
  static Future<void> dispose() async {
    try {
      // Supabase Flutter SDK 會自動管理資源
      _client = null;
      _isInitialized = false;
      _logDebug('Supabase 資源已釋放');
    } catch (e) {
      _logError('釋放 Supabase 資源時發生錯誤: $e');
    }
  }

  /// 記錄除錯資訊
  static void _logDebug(String message) {
    // ⚡ 生產模式關閉日誌以提升效能
    if (kDebugMode) {
      // 只記錄關鍵訊息
      if (message.contains('成功') || message.contains('失敗')) {
        print('[SUPABASE] $message');
      }
    }
  }

  /// 記錄錯誤資訊
  static void _logError(String message) {
    if (kDebugMode) {
      print('[SUPABASE ERROR] $message');
    }
  }
}
