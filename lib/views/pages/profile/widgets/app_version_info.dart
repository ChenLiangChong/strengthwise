import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/services/interfaces/i_app_config_service.dart';
import 'package:strengthwise/models/app_version_config.dart';
import 'package:strengthwise/utils/version_utils.dart';

/// App 版本資訊元件
///
/// 顯示在「我的」頁面底部：
/// - 正常狀態：灰色小字顯示當前版本號
/// - 有新版本：文字提示 + 可點擊的「前往更新」連結
class AppVersionInfo extends StatefulWidget {
  const AppVersionInfo({super.key});

  @override
  State<AppVersionInfo> createState() => _AppVersionInfoState();
}

class _AppVersionInfoState extends State<AppVersionInfo> {
  String? _currentVersion;
  AppVersionConfig? _config;
  bool _hasUpdate = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  /// 載入版本資訊
  Future<void> _loadVersionInfo() async {
    try {
      final service = serviceLocator<IAppConfigService>();

      final currentVersion = await service.getCurrentAppVersion();
      if (!mounted) return;
      setState(() => _currentVersion = currentVersion);

      final config = await service.getVersionConfig();
      if (!mounted || config == null) return;

      final hasUpdate =
          VersionUtils.hasUpdate(currentVersion, config.latestVersion);
      bool dismissed = false;
      if (hasUpdate) {
        dismissed = await service.isUpdateDismissed(config.latestVersion);
      }

      if (!mounted) return;
      setState(() {
        _config = config;
        _hasUpdate = hasUpdate;
        _dismissed = dismissed;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppVersionInfo] 載入版本資訊失敗: $e');
      }
    }
  }

  /// 忽略此版本的更新
  Future<void> _dismissUpdate() async {
    if (_config == null) return;

    try {
      final service = serviceLocator<IAppConfigService>();
      await service.dismissUpdate(_config!.latestVersion);
      if (mounted) {
        setState(() => _dismissed = true);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppVersionInfo] 忽略更新失敗: $e');
      }
    }
  }

  /// 開啟對應平台的商店頁面
  Future<void> _openStore() async {
    if (_config == null) return;

    String? url;
    if (!kIsWeb && Platform.isIOS) {
      url = _config!.updateUrlIos;
    } else {
      url = _config!.updateUrlAndroid;
    }

    if (url == null || url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppVersionInfo] 開啟商店失敗: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final baseStyle = textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    // 版本號尚未載入
    if (_currentVersion == null) return const SizedBox.shrink();

    // 有新版本且未忽略
    final showUpdate = _hasUpdate && !_dismissed && _config != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 更新提示行
        if (showUpdate)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text.rich(
              TextSpan(
                style: baseStyle,
                children: [
                  TextSpan(
                    text: '有新版本 v${_config!.latestVersion} 可用  ',
                  ),
                  TextSpan(
                    text: '前往更新',
                    style: baseStyle?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = _openStore,
                  ),
                  const TextSpan(text: '  '),
                  TextSpan(
                    text: '忽略',
                    style: baseStyle?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = _dismissUpdate,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // 版本號（永遠顯示）
        Text(
          'v$_currentVersion',
          style: baseStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
