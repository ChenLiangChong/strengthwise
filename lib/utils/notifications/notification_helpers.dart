import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 通知輔助工具類
class NotificationHelpers {
  /// 判斷是否使用頂部通知
  static bool shouldUseTopNotification(
    BuildContext context, {
    bool forceBottom = false,
  }) {
    if (forceBottom) return false;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Platform.isIOS || isKeyboardOpen;
  }

  /// 判斷是否為深色模式
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// 獲取成功色（適配深淺色模式）
  static Color getSuccessColor(BuildContext context, {double opacity = 0.9}) {
    return isDarkMode(context)
        ? const Color(0xFF81C784).withOpacity(opacity)
        : const Color(0xFF2E7D32).withOpacity(opacity);
  }

  /// 獲取錯誤色（適配深淺色模式）
  static Color getErrorColor(BuildContext context, {double opacity = 0.9}) {
    return isDarkMode(context)
        ? const Color(0xFFEF4444).withOpacity(opacity)
        : Theme.of(context).colorScheme.error;
  }

  /// 獲取主題色
  static Color getPrimaryColor(BuildContext context, {double opacity = 0.9}) {
    return Theme.of(context).colorScheme.primary.withOpacity(opacity);
  }

  /// 獲取成就色（適配深淺色模式）
  static Color getAchievementColor(BuildContext context) {
    return isDarkMode(context)
        ? const Color(0xFFFCD34D) // 金色（深色模式）
        : const Color(0xFFF59E0B); // 琥珀色（淺色模式）
  }

  /// 獲取成就陰影
  static BoxShadow getAchievementShadow(BuildContext context) {
    final color = getAchievementColor(context);
    return BoxShadow(
      color: color.withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 8),
    );
  }

  /// 輕度觸覺回饋
  static void lightHaptic() {
    HapticFeedback.lightImpact();
  }

  /// 中度觸覺回饋
  static void mediumHaptic() {
    HapticFeedback.mediumImpact();
  }

  /// 重度觸覺回饋
  static void heavyHaptic() {
    HapticFeedback.heavyImpact();
  }

  /// 成就觸覺回饋（雙重震動）
  static void achievementHaptic() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
    });
  }
}

