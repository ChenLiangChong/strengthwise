import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:strengthwise/models/app_version_config.dart';
import 'package:strengthwise/services/interfaces/i_app_config_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';

/// App 配置服務實作
///
/// 使用 Supabase 讀取 app_config 表中的版本配置
/// 支援 SharedPreferences 離線快取
class AppConfigService implements IAppConfigService {
  final ErrorHandlingService _errorService;

  static const String _cacheKey = 'app_version_config_cache';
  static const String _dismissedVersionKey = 'dismissed_update_version';

  /// 記憶體快取
  AppVersionConfig? _cachedConfig;

  /// 運行時 App 版本（快取，避免重複讀取）
  String? _appVersion;

  AppConfigService({
    required ErrorHandlingService errorService,
  }) : _errorService = errorService;

  @override
  Future<AppVersionConfig?> getVersionConfig() async {
    try {
      final response = await Supabase.instance.client
          .from('app_config')
          .select('key, value, updated_at')
          .eq('key', 'app_version')
          .maybeSingle();

      if (response != null) {
        _cachedConfig = AppVersionConfig.fromSupabase(response);
        await _saveToLocalCache(_cachedConfig!);
        return _cachedConfig;
      }
    } catch (e) {
      _errorService.logError(
        '取得版本配置失敗，嘗試使用本地快取: $e',
        type: 'AppConfigServiceError',
      );
    }

    // 網路失敗時嘗試記憶體快取
    if (_cachedConfig != null) return _cachedConfig;

    // 最後嘗試本地快取
    return _loadFromLocalCache();
  }

  @override
  Future<String> getCurrentAppVersion() async {
    if (_appVersion != null) return _appVersion!;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      return _appVersion!;
    } catch (e) {
      _errorService.logError(
        '取得 App 版本號失敗: $e',
        type: 'AppConfigServiceError',
      );
      return '0.0.0';
    }
  }

  @override
  Future<bool> isUpdateDismissed(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_dismissedVersionKey) == version;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> dismissUpdate(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissedVersionKey, version);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppConfigService] 記錄忽略版本失敗: $e');
      }
    }
  }

  /// 儲存配置到 SharedPreferences
  Future<void> _saveToLocalCache(AppVersionConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(config.toMap()));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppConfigService] 快取版本配置失敗: $e');
      }
    }
  }

  /// 從 SharedPreferences 讀取配置
  Future<AppVersionConfig?> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr == null) return null;

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final value = data['value'] as Map<String, dynamic>?;
      if (value == null) return null;

      return AppVersionConfig(
        latestVersion: value['latest_version'] as String? ?? '0.0.0',
        updateUrlAndroid: value['update_url_android'] as String?,
        updateUrlIos: value['update_url_ios'] as String?,
        releaseNotes: value['release_notes'] as String?,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppConfigService] 讀取版本快取失敗: $e');
      }
      return null;
    }
  }
}
