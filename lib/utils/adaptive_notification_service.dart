import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    // 添加觸覺回饋（輕微震動）
    HapticFeedback.lightImpact();

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final useTopNotification = !forceBottom && (Platform.isIOS || isKeyboardOpen);

    if (useTopNotification) {
      // iOS 或鍵盤開啟：使用頂部動態島風格
      _showTopSuccessNotification(context, message, duration);
    } else {
      // Android 或強制底部：使用 Material Design Snackbar
      _showBottomSuccessSnackbar(
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
    // 添加觸覺回饋（重度震動）
    HapticFeedback.heavyImpact();

    ElegantNotification.error(
      title: const Text(
        '錯誤',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      description: Text(
        message,
        style: const TextStyle(fontSize: 14),
      ),
      position: Alignment.topRight,
      animation: AnimationType.fromTop,
      width: MediaQuery.of(context).size.width - 32,
      toastDuration: duration ?? const Duration(seconds: 4),
      // 圓角膠囊形狀
      borderRadius: BorderRadius.circular(24),
      // 玻璃擬態效果（深色模式適配）
      background: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFEF4444).withOpacity(0.9)
          : Theme.of(context).colorScheme.error,
    ).show(context);
  }

  /// 顯示資訊通知（自適應位置）
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    // 添加觸覺回饋（輕微震動）
    HapticFeedback.lightImpact();

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    if (Platform.isIOS || isKeyboardOpen) {
      // iOS 或鍵盤開啟：使用頂部通知
      ElegantNotification.info(
        title: const Text(
          '提示',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        description: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        position: Alignment.topRight,
        animation: AnimationType.fromTop,
        width: MediaQuery.of(context).size.width - 32,
        toastDuration: duration ?? const Duration(seconds: 3),
        borderRadius: BorderRadius.circular(24),
        background: Theme.of(context).colorScheme.primary.withOpacity(0.9),
      ).show(context);
    } else {
      // Android：使用底部 Snackbar
      _showBottomInfoSnackbar(
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
    // 添加觸覺回饋（中度震動）
    HapticFeedback.mediumImpact();

    final warningColor = Theme.of(context).colorScheme.tertiary;

    ElegantNotification(
      title: const Text(
        '警告',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      description: Text(
        message,
        style: const TextStyle(fontSize: 14),
      ),
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.white,
        size: 28,
      ),
      position: Alignment.topRight,
      animation: AnimationType.fromTop,
      width: MediaQuery.of(context).size.width - 32,
      toastDuration: duration ?? const Duration(seconds: 3),
      borderRadius: BorderRadius.circular(24),
      background: warningColor.withOpacity(0.9),
    ).show(context);
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
    // 添加觸覺回饋（中度震動）
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.delete_outline,
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
        // 灰色透明背景 + 白字
        backgroundColor: const Color(0xCC424242), // 灰色 70% 透明度
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 7), // 延長以便操作
        margin: const EdgeInsets.only(
          bottom: 80, // 避開底部導航欄
          left: 16,
          right: 16,
        ),
        // 膠囊形狀
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        // 玻璃擬態效果
        elevation: 4,
        action: SnackBarAction(
          label: '撤銷',
          textColor: Colors.white,
          onPressed: () {
            HapticFeedback.lightImpact();
            onUndo();
          },
        ),
      ),
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
    // 添加觸覺回饋（重度震動 + 連續兩次）
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    ElegantNotification(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
        ),
      ),
      description: Text(
        description,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? const Color(0xFF334155) : Colors.white.withOpacity(0.9),
        ),
      ),
      icon: Icon(
        icon ?? Icons.emoji_events_rounded,
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        size: 32,
      ),
      position: Alignment.topCenter,
      animation: AnimationType.fromTop,
      width: MediaQuery.of(context).size.width - 32,
      toastDuration: duration ?? const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(24),
      // 金色/品牌色背景
      background: isDark
          ? const Color(0xFFFCD34D) // 金色（深色模式）
          : const Color(0xFFF59E0B), // 琥珀色（淺色模式）
      // 微陰影
      shadow: BoxShadow(
        color: (isDark ? const Color(0xFFFCD34D) : const Color(0xFFF59E0B))
            .withOpacity(0.3),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ).show(context);
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
    // 添加觸覺回饋（中度震動）
    HapticFeedback.mediumImpact();

    final statusColor = color ?? const Color(0xFFF59E0B); // 預設警告色

    ElegantNotification(
      title: Text(
        message,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      description: const Text(''), // 必需參數（空白）
      icon: Icon(
        icon ?? Icons.cloud_off_outlined,
        color: Colors.white,
        size: 20,
      ),
      position: Alignment.topCenter,
      animation: AnimationType.fromTop,
      width: MediaQuery.of(context).size.width * 0.6, // 窄版膠囊
      toastDuration: const Duration(seconds: 999), // 極長時間（需手動關閉）
      borderRadius: BorderRadius.circular(20),
      background: statusColor.withOpacity(0.95),
      height: 48, // 較矮的條狀
      showProgressIndicator: false,
    ).show(context);
  }

  // ---------------------------------------------------------------------------
  // 私有輔助方法
  // ---------------------------------------------------------------------------

  /// 頂部成功通知（動態島風格）
  static void _showTopSuccessNotification(
    BuildContext context,
    String message,
    Duration? duration,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ElegantNotification.success(
      title: const Text(
        '成功',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      description: Text(
        message,
        style: const TextStyle(fontSize: 14),
      ),
      position: Alignment.topRight,
      animation: AnimationType.fromTop,
      width: MediaQuery.of(context).size.width - 32,
      toastDuration: duration ?? const Duration(seconds: 3),
      borderRadius: BorderRadius.circular(24),
      // 成功色適配（深淺色模式）
      background: isDark
          ? const Color(0xFF81C784).withOpacity(0.9) // 低飽和度粉綠
          : const Color(0xFF2E7D32).withOpacity(0.9), // 標準深綠
    ).show(context);
  }

  /// 底部成功 Snackbar（膠囊形狀 + 玻璃擬態）
  static void _showBottomSuccessSnackbar(
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
            // 路徑追蹤動畫的勾選圖示
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            )
                .animate()
                .scale(duration: 300.ms, curve: Curves.elasticOut)
                .then()
                .shimmer(duration: 500.ms),
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
          bottom: 80, // 避開底部導航欄
          left: 16,
          right: 16,
        ),
        // 膠囊形狀（圓角 24）
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        // 玻璃擬態效果
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

  /// 底部資訊 Snackbar
  static void _showBottomInfoSnackbar(
    BuildContext context,
    String message, {
    Duration? duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 4,
        action: onAction != null
            ? SnackBarAction(
                label: actionLabel ?? '確定',
                textColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onAction();
                },
              )
            : null,
      ),
    );
  }
}

