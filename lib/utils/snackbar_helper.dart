import 'package:flutter/material.dart';

/// SnackBar 統一樣式管理
/// 
/// 解決 SnackBar 被底部導航欄遮擋的問題
class SnackBarHelper {
  /// 顯示成功訊息
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.primary,
      icon: Icons.check_circle,
    );
  }

  /// 顯示錯誤訊息
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.error,
      icon: Icons.error,
    );
  }

  /// 顯示警告訊息
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
    );
  }

  /// 顯示一般訊息
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      icon: Icons.info,
    );
  }

  /// 內部方法：顯示 SnackBar
  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        margin: const EdgeInsets.only(
          bottom: 80, // 避開底部導航欄（56dp 高度 + 24dp 間距）
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

