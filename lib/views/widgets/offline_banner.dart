// ⚡ v3.1.1: 離線狀態 Banner
//
// 當網路斷線時顯示在頂部的提示橫幅
import 'package:flutter/material.dart';
import 'package:strengthwise/services/core/network_status_service.dart';

/// 離線狀態 Banner
///
/// 當網路斷線時，在頁面頂部顯示提示橫幅
/// 使用 AnimatedSlide + AnimatedOpacity 實現平滑的顯示/隱藏動畫
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({
    super.key,
    required this.child,
  });

  /// 子內容（通常是頁面主體）
  final Widget child;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  final NetworkStatusService _networkService = NetworkStatusService();

  @override
  void initState() {
    super.initState();
    // 初始化網路服務並監聽變化
    _networkService.initialize();
    _networkService.addListener(_onNetworkChanged);
  }

  @override
  void dispose() {
    _networkService.removeListener(_onNetworkChanged);
    super.dispose();
  }

  void _onNetworkChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = !_networkService.isOnline;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 離線提示 Banner（帶動畫）
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isOffline ? null : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isOffline ? 1.0 : 0.0,
            child: isOffline
                ? Material(
                    color: colorScheme.errorContainer,
                    child: SafeArea(
                      bottom: false,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.wifi_off,
                              size: 18,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '目前離線，部分功能可能無法使用',
                                style: TextStyle(
                                  color: colorScheme.onErrorContainer,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            // 重試按鈕
                            TextButton(
                              onPressed: () async {
                                await _networkService.checkConnectivity();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.onErrorContainer,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('重試'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        // 頁面主體
        Expanded(child: widget.child),
      ],
    );
  }
}

/// 網路錯誤重試 Widget
///
/// 當 API 請求失敗時顯示，提供重試按鈕
class NetworkErrorWidget extends StatelessWidget {
  const NetworkErrorWidget({
    super.key,
    required this.onRetry,
    this.message,
    this.icon,
  });

  /// 重試回調
  final VoidCallback onRetry;

  /// 自訂錯誤訊息
  final String? message;

  /// 自訂圖標
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.cloud_off,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? '無法連線，請檢查網路設定',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重試'),
            ),
          ],
        ),
      ),
    );
  }
}
