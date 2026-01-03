import 'package:flutter/material.dart';
import 'package:strengthwise/views/pages/scheduling/availability/availability_dialogs.dart';

/// 複製週時段功能的 Mixin
///
/// 統一學員時間偏好和教練時段管理的複製週時段邏輯
mixin CopyWeekSlotsMixin<T extends StatefulWidget> on State<T> {
  /// 複製週時段
  ///
  /// [userId] 用戶 ID（學員 ID 或教練 ID）
  /// [copyOperation] 實際的複製操作（返回複製數量）
  /// [onSuccess] 成功後的回調（例如重新載入資料）
  Future<void> copyWeekSlots({
    required String userId,
    required Future<int> Function({
      required String userId,
      required DateTime sourceWeekStart,
      required DateTime targetWeekStart,
    }) copyOperation,
    required VoidCallback onSuccess,
  }) async {
    // 顯示確認對話框
    final confirmed =
        await AvailabilityDialogs.showCopyWeekConfirmDialog(context);

    if (!confirmed) return;

    // 計算本週和下週的起始日期
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final nextWeekStart = thisWeekStart.add(const Duration(days: 7));

    try {
      // 執行複製操作
      final count = await copyOperation(
        userId: userId,
        sourceWeekStart: thisWeekStart,
        targetWeekStart: nextWeekStart,
      );

      // 顯示結果
      if (mounted) {
        if (count > 0) {
          AvailabilityDialogs.showSuccess(context, '已複製 $count 個時段到下週');
          onSuccess();
        } else {
          AvailabilityDialogs.showError(context, '複製失敗或沒有時段可複製');
        }
      }
    } catch (e) {
      if (mounted) {
        AvailabilityDialogs.showError(context, '複製週時段時發生錯誤：$e');
      }
    }
  }

  /// 獲取本週起始日期（週一）
  DateTime getThisWeekStart() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  /// 獲取下週起始日期（下週一）
  DateTime getNextWeekStart() {
    return getThisWeekStart().add(const Duration(days: 7));
  }
}
