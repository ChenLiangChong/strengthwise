import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'notification_config.dart';
import 'notification_helpers.dart';

/// 底部通知建構器（Material Design Snackbar）
class BottomNotificationBuilder {
  /// 顯示底部成功 Snackbar（膠囊形狀 + 玻璃擬態）
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
            // 勾選圖示（帶動畫）
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: NotificationConfig.iconSize,
            )
                .animate()
                .scale(
                  duration: NotificationConfig.scaleAnimationDuration,
                  curve: Curves.elasticOut,
                )
                .then()
                .shimmer(duration: NotificationConfig.shimmerDuration),
            const SizedBox(width: NotificationConfig.iconTextSpacing),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: NotificationConfig.contentFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(NotificationConfig.defaultBackgroundColor),
        behavior: SnackBarBehavior.floating,
        duration: duration ?? NotificationConfig.defaultDuration,
        margin: const EdgeInsets.only(
          bottom: NotificationConfig.defaultBottomMargin,
          left: NotificationConfig.horizontalPadding,
          right: NotificationConfig.horizontalPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NotificationConfig.defaultBorderRadius),
        ),
        elevation: 4,
        action: onAction != null
            ? SnackBarAction(
                label: actionLabel ?? '查看',
                textColor: Colors.white,
                onPressed: () {
                  NotificationHelpers.lightHaptic();
                  onAction();
                },
              )
            : null,
      ),
    );
  }

  /// 顯示底部資訊 Snackbar
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final isDark = NotificationHelpers.isDarkMode(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              size: NotificationConfig.iconSize,
            ),
            const SizedBox(width: NotificationConfig.iconTextSpacing),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  fontSize: NotificationConfig.contentFontSize,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? NotificationConfig.defaultDuration,
        margin: const EdgeInsets.only(
          bottom: NotificationConfig.defaultBottomMargin,
          left: NotificationConfig.horizontalPadding,
          right: NotificationConfig.horizontalPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NotificationConfig.defaultBorderRadius),
        ),
        elevation: 4,
        action: onAction != null
            ? SnackBarAction(
                label: actionLabel ?? '確定',
                textColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                onPressed: () {
                  NotificationHelpers.lightHaptic();
                  onAction();
                },
              )
            : null,
      ),
    );
  }

  /// 顯示可撤銷操作通知（強制底部，拇指熱區）
  static void showUndoableAction(
    BuildContext context,
    String message, {
    required VoidCallback onUndo,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: NotificationConfig.iconSize,
            ),
            const SizedBox(width: NotificationConfig.iconTextSpacing),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: NotificationConfig.contentFontSize,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(NotificationConfig.defaultBackgroundColor),
        behavior: SnackBarBehavior.floating,
        duration: duration ?? NotificationConfig.undoDuration,
        margin: const EdgeInsets.only(
          bottom: NotificationConfig.defaultBottomMargin,
          left: NotificationConfig.horizontalPadding,
          right: NotificationConfig.horizontalPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NotificationConfig.defaultBorderRadius),
        ),
        elevation: 4,
        action: SnackBarAction(
          label: '撤銷',
          textColor: Colors.white,
          onPressed: () {
            NotificationHelpers.lightHaptic();
            onUndo();
          },
        ),
      ),
    );
  }
}

