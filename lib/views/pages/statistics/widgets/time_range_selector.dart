// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import '../../../../models/statistics_model.dart';

/// 時間範圍選擇器組件
///
/// 用於統計頁面的時間範圍切換（週、月、三個月、年）
///
/// 響應式設計：
/// - 響應式間距
class TimeRangeSelector extends StatelessWidget {
  /// 當前選中的時間範圍
  final TimeRange currentRange;

  /// 時間範圍改變回調
  final ValueChanged<TimeRange> onRangeChanged;

  const TimeRangeSelector({
    Key? key,
    required this.currentRange,
    required this.onRangeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.spacing.sm),
      child: Wrap(
        spacing: context.spacing.sm,
        runSpacing: context.spacing.xs,
        children: TimeRange.values.map((range) {
          final isSelected = currentRange == range;
          return ChoiceChip(
            label: Text(range.displayName),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                onRangeChanged(range);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

