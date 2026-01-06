import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 時間段模型
class TimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAvailable;
  final bool isBooked;
  final String? label;
  final dynamic data; // 可附加任意數據

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    this.isBooked = false,
    this.label,
    this.data,
  });

  String get displayTime {
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }
}

/// 時間網格視圖
///
/// 以網格形式顯示可用時段，支援單選和多選。
/// 適用於預約系統的時段選擇。
class TimeGridView extends StatelessWidget {
  /// 時間段列表
  final List<TimeSlot> slots;

  /// 選中的時間段索引
  final int? selectedIndex;

  /// 選中回調
  final ValueChanged<int>? onSlotSelected;

  /// 每行顯示幾個時段
  final int crossAxisCount;

  /// 時段間距
  final double spacing;

  /// 是否顯示空狀態
  final bool showEmptyState;

  const TimeGridView({
    super.key,
    required this.slots,
    this.selectedIndex,
    this.onSlotSelected,
    this.crossAxisCount = 3,
    this.spacing = 8,
    this.showEmptyState = true,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty && showEmptyState) {
      return _buildEmptyState(context);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 2.5,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        return _TimeSlotItem(
          slot: slots[index],
          isSelected: selectedIndex == index,
          onTap: () {
            if (slots[index].isAvailable && !slots[index].isBooked) {
              HapticFeedback.selectionClick();
              onSlotSelected?.call(index);
            }
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            '今日無可用時段',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// 時間段項目組件
class _TimeSlotItem extends StatelessWidget {
  final TimeSlot slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeSlotItem({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isDisabled = !slot.isAvailable || slot.isBooked;

    Color backgroundColor;
    Color textColor;
    Color borderColor;

    if (isSelected) {
      backgroundColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
      borderColor = colorScheme.primary;
    } else if (slot.isBooked) {
      backgroundColor = colorScheme.errorContainer.withValues(alpha: 0.3);
      textColor = colorScheme.onSurfaceVariant;
      borderColor = colorScheme.errorContainer;
    } else if (!slot.isAvailable) {
      backgroundColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
      textColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
      borderColor = colorScheme.outlineVariant.withValues(alpha: 0.3);
    } else {
      backgroundColor = colorScheme.surface;
      textColor = colorScheme.onSurface;
      borderColor = colorScheme.outlineVariant;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                slot.displayTime,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (slot.label != null) ...[
                const SizedBox(height: 2),
                Text(
                  slot.label!,
                  style: TextStyle(
                    fontSize: 10,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
              if (slot.isBooked) ...[
                const SizedBox(height: 2),
                Text(
                  '已預約',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 時間段生成器
class TimeSlotGenerator {
  /// 生成一天的時間段
  ///
  /// [startHour] 開始小時（0-23）
  /// [endHour] 結束小時（0-23）
  /// [intervalMinutes] 每個時段的分鐘數
  /// [bookedSlots] 已預約的時段（用於標記）
  static List<TimeSlot> generateDaySlots({
    int startHour = 8,
    int endHour = 21,
    int intervalMinutes = 60,
    List<TimeSlot>? bookedSlots,
  }) {
    final slots = <TimeSlot>[];

    int currentHour = startHour;
    int currentMinute = 0;

    while (currentHour < endHour) {
      final startTime = TimeOfDay(hour: currentHour, minute: currentMinute);

      // 計算結束時間
      int endMinute = currentMinute + intervalMinutes;
      int endHourCalc = currentHour;
      while (endMinute >= 60) {
        endMinute -= 60;
        endHourCalc++;
      }

      if (endHourCalc > endHour) break;

      final endTime = TimeOfDay(hour: endHourCalc, minute: endMinute);

      // 檢查是否已預約
      final isBooked = bookedSlots?.any((booked) =>
          booked.startTime.hour == startTime.hour &&
          booked.startTime.minute == startTime.minute) ?? false;

      slots.add(TimeSlot(
        startTime: startTime,
        endTime: endTime,
        isAvailable: true,
        isBooked: isBooked,
      ));

      // 移動到下一個時段
      currentMinute += intervalMinutes;
      while (currentMinute >= 60) {
        currentMinute -= 60;
        currentHour++;
      }
    }

    return slots;
  }
}

