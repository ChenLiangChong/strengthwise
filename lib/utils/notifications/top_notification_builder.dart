import 'package:flutter/material.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'notification_config.dart';
import 'notification_helpers.dart';

/// 頂部通知建構器（動態島風格）
class TopNotificationBuilder {
  /// 顯示頂部成功通知
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    ElegantNotification.success(
      title: const Text(
        '成功',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: NotificationConfig.titleFontSize,
        ),
      ),
      description: Text(
        message,
        style: const TextStyle(fontSize: NotificationConfig.contentFontSize),
      ),
      position: Alignment.topRight,
      animation: AnimationType.fromTop,
      width: MediaQuery.of(context).size.width - NotificationConfig.defaultWidth,
      toastDuration: duration ?? NotificationConfig.defaultDuration,
      borderRadius: BorderRadius.circular(NotificationConfig.defaultBorderRadius),
      background: NotificationHelpers.getSuccessColor(context),
    ).show(context);
  }

  /// 顯示頂部錯誤通知
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    ElegantNotification.error(
      title: const Text(
        '錯誤',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: NotificationConfig.titleFontSize,
        ),
      ),
      description: Text(
        message,
        style: const TextStyle(fontSize: NotificationConfig.contentFontSize),
      ),
      position: Alignment.topRight,
      animation: AnimationType.fromTop,
      width: MediaQuery.of(context).size.width - NotificationConfig.defaultWidth,
      toastDuration: duration ?? NotificationConfig.errorDuration,
      borderRadius: BorderRadius.circular(NotificationConfig.defaultBorderRadius),
      background: NotificationHelpers.getErrorColor(context),
    ).show(context);
  }

  /// 顯示頂部資訊通知
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    ElegantNotification.info(
      title: const Text(
        '提示',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: NotificationConfig.titleFontSize,
        ),
      ),
      description: Text(
        message,
        style: const TextStyle(fontSize: NotificationConfig.contentFontSize),
      ),
      position: Alignment.topRight,
      animation: AnimationType.fromTop,
      width: MediaQuery.of(context).size.width - NotificationConfig.defaultWidth,
      toastDuration: duration ?? NotificationConfig.defaultDuration,
      borderRadius: BorderRadius.circular(NotificationConfig.defaultBorderRadius),
      background: NotificationHelpers.getPrimaryColor(context),
    ).show(context);
  }

  /// 顯示頂部警告通知
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    final warningColor = Theme.of(context).colorScheme.tertiary.withOpacity(0.9);

    ElegantNotification(
      title: const Text(
        '警告',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: NotificationConfig.titleFontSize,
        ),
      ),
      description: Text(
        message,
        style: const TextStyle(fontSize: NotificationConfig.contentFontSize),
      ),
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.white,
        size: 28,
      ),
      position: Alignment.topRight,
      animation: AnimationType.fromTop,
      width: MediaQuery.of(context).size.width - NotificationConfig.defaultWidth,
      toastDuration: duration ?? NotificationConfig.defaultDuration,
      borderRadius: BorderRadius.circular(NotificationConfig.defaultBorderRadius),
      background: warningColor,
    ).show(context);
  }

  /// 顯示成就通知（頂部大型 Banner）
  static void showAchievement(
    BuildContext context,
    String title,
    String description, {
    IconData? icon,
    Duration? duration,
  }) {
    final isDark = NotificationHelpers.isDarkMode(context);
    final achievementColor = NotificationHelpers.getAchievementColor(context);

    ElegantNotification(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: NotificationConfig.achievementTitleFontSize,
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
        ),
      ),
      description: Text(
        description,
        style: TextStyle(
          fontSize: NotificationConfig.achievementContentFontSize,
          color: isDark 
              ? const Color(0xFF334155) 
              : Colors.white.withOpacity(0.9),
        ),
      ),
      icon: Icon(
        icon ?? Icons.emoji_events_rounded,
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        size: NotificationConfig.largeIconSize,
      ),
      position: Alignment.topCenter,
      animation: AnimationType.fromTop,
      width: MediaQuery.of(context).size.width - NotificationConfig.defaultWidth,
      toastDuration: duration ?? NotificationConfig.achievementDuration,
      borderRadius: BorderRadius.circular(NotificationConfig.defaultBorderRadius),
      background: achievementColor,
      shadow: NotificationHelpers.getAchievementShadow(context),
    ).show(context);
  }

  /// 顯示系統狀態通知（頂部 Sticky Pill）
  static void showSystemStatus(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? color,
  }) {
    final statusColor = color ?? const Color(NotificationConfig.systemStatusColor);

    ElegantNotification(
      title: Text(
        message,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: NotificationConfig.systemFontSize,
          color: Colors.white,
        ),
      ),
      description: const Text(''), // 必需參數
      icon: Icon(
        icon ?? Icons.cloud_off_outlined,
        color: Colors.white,
        size: NotificationConfig.systemIconSize,
      ),
      position: Alignment.topCenter,
      animation: AnimationType.fromTop,
      width: MediaQuery.of(context).size.width * NotificationConfig.systemWidth,
      toastDuration: NotificationConfig.systemDuration,
      borderRadius: BorderRadius.circular(20),
      background: statusColor.withOpacity(0.95),
      height: NotificationConfig.systemHeight,
      showProgressIndicator: false,
    ).show(context);
  }
}

