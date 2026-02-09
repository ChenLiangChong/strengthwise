import 'package:strengthwise/models/app_version_config.dart';

/// App 配置服務介面
///
/// 從 Supabase app_config 表讀取遠端配置
/// 功能：
/// 1. 取得 App 版本配置（版本號、更新連結）
/// 2. 快取上一次成功的配置（離線降級）
/// 3. 管理用戶已忽略的更新版本
abstract class IAppConfigService {
  /// 取得 App 版本配置
  ///
  /// 1. 優先從 Supabase 取得最新配置
  /// 2. 網路失敗時返回本地快取的配置
  /// 3. 完全無資料時返回 null
  Future<AppVersionConfig?> getVersionConfig();

  /// 取得目前 App 版本號（從 package_info_plus 取得）
  Future<String> getCurrentAppVersion();

  /// 檢查用戶是否已忽略此版本的更新提示
  Future<bool> isUpdateDismissed(String version);

  /// 記錄用戶已忽略此版本的更新
  Future<void> dismissUpdate(String version);
}
