import 'package:flutter/material.dart';

/// 時段篩選器組件
/// 
/// 提供三種篩選選項：全部、週期性、單次
class SlotFilterBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const SlotFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('全部', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('週期性', 'recurring'),
          const SizedBox(width: 8),
          _buildFilterChip('單次', 'oneTime'),
        ],
      ),
    );
  }

  /// 建立單個篩選器
  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => onFilterChanged(value),
    );
  }
}

