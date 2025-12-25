import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 統一的通知工具類（基礎版本）
///
/// 提供符合 UI/UX 規範的通知顯示方式
/// 注意：建議使用 AdaptiveNotificationService 以獲得更好的自適應體驗
///
/// 相關文檔：
/// - lib/utils/adaptive_notification_service.dart（進階版）
/// - docs/UI_UX_GUIDELINES.md
class NotificationUtils {
  /// 顯示成功通知（浮動，不遮擋底部）
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    // 添加觸覺回饋
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        // 灰色透明背景 + 白字
        backgroundColor: const Color(0xCC424242), // 灰色 70% 透明度
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 3),
        margin: const EdgeInsets.only(
          bottom: 80, // 避免遮擋底部導航欄
          left: 16,
          right: 16,
        ),
        // 膠囊形狀（圓角 24）
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 4,
        action: onAction != null
            ? SnackBarAction(
                label: actionLabel ?? '查看',
                textColor: Colors.white,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onAction();
                },
              )
            : null,
      ),
    );
  }

  /// 顯示錯誤通知（固定在底部，紅色背景）
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    // 添加觸覺回饋（重度震動）
    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        // 紅色透明背景 + 白字
        backgroundColor: const Color(0xCCEF4444), // 紅色 80% 透明度
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 4),
        margin: const EdgeInsets.only(
          bottom: 80,
          left: 16,
          right: 16,
        ),
        // 膠囊形狀
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 4,
      ),
    );
  }

  /// 顯示資訊通知（浮動,主題色背景）
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    // 添加觸覺回饋
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 3),
        margin: const EdgeInsets.only(
          bottom: 80,
          left: 16,
          right: 16,
        ),
        // 膠囊形狀
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 4,
        action: onAction != null
            ? SnackBarAction(
                label: actionLabel ?? '確定',
                textColor: Colors.white,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onAction();
                },
              )
            : null,
      ),
    );
  }

  /// 顯示警告通知（浮動，警告色背景）
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    // 添加觸覺回饋（中度震動）
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        // 橙色透明背景 + 白字
        backgroundColor: const Color(0xCCF97316), // 橙色 80% 透明度
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 3),
        margin: const EdgeInsets.only(
          bottom: 80,
          left: 16,
          right: 16,
        ),
        // 膠囊形狀
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 4,
      ),
    );
  }
}
