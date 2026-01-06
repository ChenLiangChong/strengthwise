import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 預約確認底部彈窗
///
/// 顯示預約詳情並讓用戶確認預約。
/// 使用 Material 3 BottomSheet 設計。
class BookingConfirmationSheet extends StatelessWidget {
  /// 教練名稱
  final String coachName;

  /// 日期
  final DateTime date;

  /// 開始時間
  final TimeOfDay startTime;

  /// 結束時間
  final TimeOfDay endTime;

  /// 備註（可選）
  final String? notes;

  /// 確認回調
  final VoidCallback onConfirm;

  /// 取消回調
  final VoidCallback? onCancel;

  /// 是否顯示載入狀態
  final bool isLoading;

  /// 教練頭像 URL（可選）
  final String? coachPhotoUrl;

  const BookingConfirmationSheet({
    super.key,
    required this.coachName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.notes,
    required this.onConfirm,
    this.onCancel,
    this.isLoading = false,
    this.coachPhotoUrl,
  });

  /// 顯示預約確認底部彈窗
  static Future<bool?> show({
    required BuildContext context,
    required String coachName,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    String? notes,
    String? coachPhotoUrl,
  }) async {
    bool confirmed = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isLoading = false;

            return BookingConfirmationSheet(
              coachName: coachName,
              date: date,
              startTime: startTime,
              endTime: endTime,
              notes: notes,
              coachPhotoUrl: coachPhotoUrl,
              isLoading: isLoading,
              onConfirm: () {
                setState(() => isLoading = true);
                confirmed = true;
                Navigator.of(context).pop();
              },
              onCancel: () {
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );

    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 拖曳把手
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 標題
          Row(
            children: [
              Icon(
                Icons.event_available,
                color: colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                '確認預約',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 教練資訊卡
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // 教練頭像
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: coachPhotoUrl != null
                      ? NetworkImage(coachPhotoUrl!)
                      : null,
                  child: coachPhotoUrl == null
                      ? Icon(
                          Icons.person,
                          color: colorScheme.primary,
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coachName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '健身教練',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 時間資訊
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                // 日期
                _buildInfoRow(
                  context,
                  icon: Icons.calendar_today,
                  label: '日期',
                  value: _formatDate(date),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: colorScheme.outlineVariant),
                const SizedBox(height: 12),
                // 時間
                _buildInfoRow(
                  context,
                  icon: Icons.access_time,
                  label: '時間',
                  value: _formatTimeRange(),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: colorScheme.outlineVariant),
                const SizedBox(height: 12),
                // 時長
                _buildInfoRow(
                  context,
                  icon: Icons.timer_outlined,
                  label: '時長',
                  value: '${_calculateDuration()} 分鐘',
                ),
              ],
            ),
          ),

          // 備註（如果有）
          if (notes != null && notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notes!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // 提示文字
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '預約後請等待教練確認',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 操作按鈕
          Row(
            children: [
              // 取消按鈕
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 16),
              // 確認按鈕
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          onConfirm();
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('確認預約'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final weekday = _getWeekdayName(date.weekday);
    return '${date.year}/${date.month}/${date.day} ($weekday)';
  }

  String _formatTimeRange() {
    final start =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  int _calculateDuration() {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes - startMinutes;
  }

  String _getWeekdayName(int weekday) {
    const names = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];
    return names[weekday - 1];
  }
}

