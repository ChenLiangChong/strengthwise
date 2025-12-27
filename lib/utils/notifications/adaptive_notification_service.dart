import 'dart:io';
import 'package:flutter/material.dart';
import 'notification_helpers.dart';
import 'top_notification_builder.dart';
import 'bottom_notification_builder.dart';

/// 情境自適應通知服務（2025 最佳實踐）
///
/// 根據以下因素自動選擇最佳通知位置與樣式：
/// 1. 鍵盤狀態（開啟時自動切換頂部）
/// 2. 平台差異（iOS 優先頂部動態島風格）
/// 3. 操作類型（高頻/撤銷/成就/系統）
/// 4. 深淺色模式適配
///
/// 設計文檔：docs/UI_UX_GUIDELINES.md
/// 最佳實踐：2025 年行動應用程式通知佈局研究報告
///
/// 架構：
/// - notification_config.dart: 配置常數
/// - notification_helpers.dart: 輔助工具
/// - top_notification_builder.dart: 頂部通知（動態島風格）
/// - bottom_notification_builder.dart: 底部通知（Material Design）
class AdaptiveNotificationService {
  /// 顯示成功通知（自適應位置）
  ///
  /// [context] 構建上下文
  /// [message] 通知訊息
  /// [duration] 顯示時長（預設 3 秒）
  /// [onAction] 操作回調（例如「查看」按鈕）
  /// [actionLabel] 操作按鈕文字
  /// [forceBottom] 強制使用底部 Snackbar（用於可撤銷操作）
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
    VoidCallback? onAction,
    String? actionLabel,
    bool forceBottom = false,
  }) {
    NotificationHelpers.lightHaptic();

    final useTopNotification = NotificationHelpers.shouldUseTopNotification(
      context,
      forceBottom: forceBottom,
    );

    if (useTopNotification) {
      // iOS 或鍵盤開啟：使用頂部動態島風格
      TopNotificationBuilder.showSuccess(context, message, duration: duration);
    } else {
      // Android 或強制底部：使用 Material Design Snackbar
      BottomNotificationBuilder.showSuccess(
        context,
        message,
        duration: duration,
        onAction: onAction,
        actionLabel: actionLabel,
      );
    }
  }

  /// 顯示錯誤通知（始終頂部，系統級）
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    NotificationHelpers.heavyHaptic();
    TopNotificationBuilder.showError(context, message, duration: duration);
  }

  /// 顯示資訊通知（自適應位置）
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    NotificationHelpers.lightHaptic();

    if (Platform.isIOS || MediaQuery.of(context).viewInsets.bottom > 0) {
      // iOS 或鍵盤開啟：使用頂部通知
      TopNotificationBuilder.showInfo(context, message, duration: duration);
    } else {
      // Android：使用底部 Snackbar
      BottomNotificationBuilder.showInfo(
        context,
        message,
        duration: duration,
        onAction: onAction,
        actionLabel: actionLabel,
      );
    }
  }

  /// 顯示警告通知（頂部，中度緊急）
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    NotificationHelpers.mediumHaptic();
    TopNotificationBuilder.showWarning(context, message, duration: duration);
  }

  /// 顯示可撤銷操作通知（強制底部，拇指熱區）
  ///
  /// 用於高風險操作（如刪除），必須位於底部方便快速撤銷
  static void showUndoableAction(
    BuildContext context,
    String message, {
    required VoidCallback onUndo,
    Duration? duration,
  }) {
    NotificationHelpers.mediumHaptic();
    BottomNotificationBuilder.showUndoableAction(
      context,
      message,
      onUndo: onUndo,
      duration: duration,
    );
  }

  /// 顯示成就通知（頂部大型 Banner，情感化設計）
  ///
  /// 用於重大成就（如打破個人紀錄），值得打斷心流
  static void showAchievement(
    BuildContext context,
    String title,
    String description, {
    IconData? icon,
    Duration? duration,
  }) {
    NotificationHelpers.achievementHaptic();
    TopNotificationBuilder.showAchievement(
      context,
      title,
      description,
      icon: icon,
      duration: duration,
    );
  }

  /// 顯示系統狀態通知（頂部 Sticky Pill，持續顯示）
  ///
  /// 用於網路斷線、同步中等系統級狀態
  /// 注意：此方法返回一個可關閉的控制器，需手動關閉
  static void showSystemStatus(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? color,
  }) {
    NotificationHelpers.mediumHaptic();
    TopNotificationBuilder.showSystemStatus(
      context,
      message,
      icon: icon,
      color: color,
    );
  }
}

