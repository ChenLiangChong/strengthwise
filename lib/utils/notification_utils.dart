import 'package:flutter/material.dart';

/// 統一的通知工具類
/// 
/// 提供符合 UI/UX 規範的通知顯示方式
class NotificationUtils {
  /// 顯示成功通知（浮動，不遮擋底部）
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.onSecondary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 2),
        margin: const EdgeInsets.only(
          bottom: 80, // 避免遮擋底部導航欄
          left: 16,
          right: 16,
        ),
        action: onAction != null
            ? SnackBarAction(
                label: actionLabel ?? '查看',
                textColor: Theme.of(context).colorScheme.onSecondary,
                onPressed: onAction,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onError,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onError,
                    ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.fixed,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// 顯示資訊通知（浮動，主題色背景）
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 2),
        margin: const EdgeInsets.only(
          bottom: 80,
          left: 16,
          right: 16,
        ),
        action: onAction != null
            ? SnackBarAction(
                label: actionLabel ?? '確定',
                textColor: Theme.of(context).colorScheme.onPrimary,
                onPressed: onAction,
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
    final warningColor = Theme.of(context).colorScheme.tertiary;
    final onWarningColor = Theme.of(context).colorScheme.onTertiary;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: onWarningColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onWarningColor,
                    ),
              ),
            ),
          ],
        ),
        backgroundColor: warningColor,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 2),
        margin: const EdgeInsets.only(
          bottom: 80,
          left: 16,
          right: 16,
        ),
      ),
    );
  }
}

