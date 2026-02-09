import 'package:strengthwise/utils/datetime_utils.dart';

/// App 版本配置 Model
///
/// 從 Supabase app_config 表中 key='app_version' 的 JSONB 值解析
class AppVersionConfig {
  /// 最新版本
  final String latestVersion;

  /// Android 更新連結
  final String? updateUrlAndroid;

  /// iOS 更新連結
  final String? updateUrlIos;

  /// 更新說明
  final String? releaseNotes;

  /// 配置更新時間
  final DateTime? updatedAt;

  const AppVersionConfig({
    required this.latestVersion,
    this.updateUrlAndroid,
    this.updateUrlIos,
    this.releaseNotes,
    this.updatedAt,
  });

  /// 從 Supabase app_config 資料轉換
  ///
  /// [row] 為 app_config 表的完整行，包含 key, value, updated_at
  factory AppVersionConfig.fromSupabase(Map<String, dynamic> row) {
    final value = row['value'] as Map<String, dynamic>;
    return AppVersionConfig(
      latestVersion: value['latest_version'] as String? ?? '0.0.0',
      updateUrlAndroid: value['update_url_android'] as String?,
      updateUrlIos: value['update_url_ios'] as String?,
      releaseNotes: value['release_notes'] as String?,
      updatedAt: row['updated_at'] != null
          ? DateTimeUtils.parseIsoTimestamp(row['updated_at'])
          : null,
    );
  }

  /// 轉換為 Map
  Map<String, dynamic> toMap() {
    return {
      'key': 'app_version',
      'value': {
        'latest_version': latestVersion,
        'update_url_android': updateUrlAndroid,
        'update_url_ios': updateUrlIos,
        'release_notes': releaseNotes,
      },
    };
  }

  @override
  String toString() =>
      'AppVersionConfig(latest: $latestVersion)';
}
