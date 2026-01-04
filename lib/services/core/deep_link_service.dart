import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Deep Link 處理服務
/// 
/// 職責：
/// - 處理 Email 確認連結
/// - 處理密碼重置連結
/// - 處理其他 Deep Link
class DeepLinkService {
  static DeepLinkService? _instance;
  static DeepLinkService get instance {
    _instance ??= DeepLinkService._();
    return _instance!;
  }

  DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;
  bool _isInitialized = false;

  /// 初始化 Deep Link 監聽
  Future<void> initialize() async {
    if (_isInitialized) {
      _logDebug('Deep Link 服務已初始化');
      return;
    }

    try {
      // 處理 App 啟動時的初始連結（用戶點擊郵件連結啟動 App）
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleDeepLink(initialUri);
      }

      // 監聽後續的 Deep Link（App 已在背景運行）
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) {
          _logDebug('收到 Deep Link: $uri');
          _handleDeepLink(uri);
        },
        onError: (error) {
          _logError('Deep Link 處理錯誤: $error');
        },
      );

      _isInitialized = true;
      _logDebug('✅ Deep Link 服務初始化完成');
    } catch (e) {
      _logError('Deep Link 服務初始化失敗: $e');
    }
  }

  /// 處理 Deep Link
  Future<void> _handleDeepLink(Uri uri) async {
    try {
      _logDebug('處理 Deep Link: ${uri.toString()}');

      // 檢查是否為 Supabase Auth 回調
      if (uri.host == 'login-callback') {
        // 提取 fragment 中的參數（Supabase 使用 fragment 傳遞 token）
        final fragmentParams = uri.fragment.split('&');
        final Map<String, String> params = {};
        
        for (final param in fragmentParams) {
          final parts = param.split('=');
          if (parts.length == 2) {
            params[parts[0]] = Uri.decodeComponent(parts[1]);
          }
        }

        // 檢查是否包含 access_token（Email 確認成功）
        if (params.containsKey('access_token')) {
          _logDebug('✅ Email 確認成功，處理認證');
          
          // Supabase SDK 會自動處理這個 token，我們只需要通知用戶
          // 認證狀態會透過 AuthStateChange 事件自動更新
        } else if (params.containsKey('error')) {
          _logError('❌ Email 確認失敗: ${params['error']}');
        }
      }
    } catch (e) {
      _logError('處理 Deep Link 失敗: $e');
    }
  }

  /// 清理資源
  Future<void> dispose() async {
    await _linkSubscription?.cancel();
    _linkSubscription = null;
    _isInitialized = false;
    _logDebug('Deep Link 服務已清理');
  }

  /// 偵錯日誌
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[DEEP_LINK_SERVICE] $message');
    }
  }

  /// 錯誤日誌
  void _logError(String message) {
    if (kDebugMode) {
      print('[DEEP_LINK_SERVICE ERROR] $message');
    }
  }
}

