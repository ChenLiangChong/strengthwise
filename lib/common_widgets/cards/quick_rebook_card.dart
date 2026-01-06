import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 上次預約資訊
class LastBookingInfo {
  final String coachId;
  final String coachName;
  final String? coachPhotoUrl;
  final TimeOfDay preferredTime;
  final int durationMinutes;
  final int dayOfWeek; // 1-7（週一到週日）

  const LastBookingInfo({
    required this.coachId,
    required this.coachName,
    this.coachPhotoUrl,
    required this.preferredTime,
    this.durationMinutes = 60,
    required this.dayOfWeek,
  });
}

/// 一鍵續約卡片
///
/// 根據用戶的上次預約記錄，提供快速續約功能。
/// 適用於學員首頁或預約頁面。
class QuickRebookCard extends StatelessWidget {
  /// 上次預約資訊
  final LastBookingInfo lastBooking;

  /// 續約回調（返回建議的下次日期）
  final void Function(DateTime suggestedDate, TimeOfDay time)? onRebook;

  /// 查看更多時段回調
  final VoidCallback? onViewMore;

  /// 是否顯示摺疊版本
  final bool compact;

  const QuickRebookCard({
    super.key,
    required this.lastBooking,
    this.onRebook,
    this.onViewMore,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (compact) {
      return _buildCompactVersion(theme, colorScheme);
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.3),
              colorScheme.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題列
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.replay,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '繼續與 ${lastBooking.coachName} 訓練',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '快速預約同一時段',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 建議時段
              _buildSuggestedSlot(theme, colorScheme),

              const SizedBox(height: 16),

              // 操作按鈕
              Row(
                children: [
                  if (onViewMore != null)
                    TextButton(
                      onPressed: onViewMore,
                      child: const Text('查看更多時段'),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      final suggestedDate = _getNextSuggestedDate();
                      onRebook?.call(suggestedDate, lastBooking.preferredTime);
                    },
                    icon: const Icon(Icons.flash_on, size: 18),
                    label: const Text('一鍵預約'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 緊湊版本（用於列表中）
  Widget _buildCompactVersion(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          final suggestedDate = _getNextSuggestedDate();
          onRebook?.call(suggestedDate, lastBooking.preferredTime);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 教練頭像
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage: lastBooking.coachPhotoUrl != null
                    ? NetworkImage(lastBooking.coachPhotoUrl!)
                    : null,
                child: lastBooking.coachPhotoUrl == null
                    ? Icon(Icons.person, color: colorScheme.primary, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              // 資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '與 ${lastBooking.coachName} 續約',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_getWeekdayName(lastBooking.dayOfWeek)} ${_formatTime(lastBooking.preferredTime)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // 箭頭
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 建議時段區塊
  Widget _buildSuggestedSlot(ThemeData theme, ColorScheme colorScheme) {
    final suggestedDate = _getNextSuggestedDate();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          // 教練頭像
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: lastBooking.coachPhotoUrl != null
                ? NetworkImage(lastBooking.coachPhotoUrl!)
                : null,
            child: lastBooking.coachPhotoUrl == null
                ? Icon(Icons.person, color: colorScheme.primary, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(suggestedDate),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatTime(lastBooking.preferredTime)} (${lastBooking.durationMinutes} 分鐘)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 推薦標籤
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '推薦',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 計算下次建議日期（根據上次預約的星期幾）
  DateTime _getNextSuggestedDate() {
    final now = DateTime.now();
    final currentWeekday = now.weekday;
    final targetWeekday = lastBooking.dayOfWeek;

    int daysToAdd;
    if (targetWeekday > currentWeekday) {
      daysToAdd = targetWeekday - currentWeekday;
    } else {
      daysToAdd = 7 - currentWeekday + targetWeekday;
    }

    // 如果是今天且時間還沒過，就用今天
    if (daysToAdd == 0 || daysToAdd == 7) {
      final nowMinutes = now.hour * 60 + now.minute;
      final targetMinutes = lastBooking.preferredTime.hour * 60 +
          lastBooking.preferredTime.minute;
      if (nowMinutes < targetMinutes - 60) {
        // 提前 1 小時內不建議
        return now;
      }
      daysToAdd = 7;
    }

    return now.add(Duration(days: daysToAdd));
  }

  String _formatDate(DateTime date) {
    final weekday = _getWeekdayName(date.weekday);
    return '${date.month}/${date.day} ($weekday)';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getWeekdayName(int weekday) {
    const names = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];
    return names[weekday - 1];
  }
}

