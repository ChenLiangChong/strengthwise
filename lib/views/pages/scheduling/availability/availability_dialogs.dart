import 'package:flutter/material.dart';

/// 時段管理相關的對話框工具類
class AvailabilityDialogs {
  /// 顯示確認對話框
  ///
  /// 返回 `true` 表示確認，`false` 表示取消
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = '確認',
    String cancelText = '取消',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          isDestructive
              ? TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: Text(confirmText),
                )
              : ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirmText),
                ),
        ],
      ),
    );

    return result ?? false;
  }

  /// 顯示刪除時段確認對話框
  static Future<bool> showDeleteConfirmDialog(BuildContext context) {
    return showConfirmDialog(
      context: context,
      title: '刪除時段',
      content: '確定要刪除此時段嗎？',
      confirmText: '刪除',
      isDestructive: true,
    );
  }

  /// 顯示複製週時段確認對話框
  static Future<bool> showCopyWeekConfirmDialog(BuildContext context) {
    return showConfirmDialog(
      context: context,
      title: '複製週時段',
      content: '將本週的時段複製到下一週？',
      confirmText: '確認',
    );
  }

  /// 顯示成功訊息
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 顯示錯誤訊息
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
