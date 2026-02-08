import 'package:flutter/material.dart';
import 'package:strengthwise/models/exercise/exercise_labels.dart';

/// PPL 快捷篩選 chips（多選）
///
/// 7 個水平捲動的 FilterChip：
/// 全部、推、拉、腿、核心、活動度、有氧
///
/// v5.0: 改為多選模式，可同時選擇多個 PPL 標籤
class ExercisePplChips extends StatelessWidget {
  /// 目前選中的 PPL tags，空集合表示「全部」
  final Set<String> selected;

  /// 選擇回調，傳入更新後的 PPL tag 集合
  final ValueChanged<Set<String>> onSelect;

  /// 使用 Wrap 排列（sidebar 模式），預設 false（水平捲動）
  final bool useWrap;

  const ExercisePplChips({
    super.key,
    required this.selected,
    required this.onSelect,
    this.useWrap = false,
  });

  static final _pplOptions = [
    const _PplOption(label: '全部', value: null, icon: Icons.apps),
    ...ExerciseLabels.ppl.entries.map((e) => _PplOption(
          label: e.value.$1,
          value: e.key,
          icon: _pplIcons[e.key] ?? Icons.label,
        )),
  ];

  static const _pplIcons = <String, IconData>{
    'push': Icons.arrow_upward,
    'pull': Icons.arrow_downward,
    'legs': Icons.directions_walk,
    'core': Icons.shield,
    'mobility': Icons.self_improvement,
    'cardio': Icons.favorite,
  };

  void _onChipTap(String? value) {
    if (value == null) {
      // 「全部」→ 清空選擇
      onSelect({});
    } else {
      // Toggle：已選→移除，未選→加入
      final updated = Set<String>.from(selected);
      if (updated.contains(value)) {
        updated.remove(value);
      } else {
        updated.add(value);
      }
      onSelect(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (useWrap) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _pplOptions.map((option) {
            final isSelected = option.value == null
                ? selected.isEmpty
                : selected.contains(option.value);
            return FilterChip(
              avatar: Icon(
                option.icon,
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              label: Text(option.label),
              selected: isSelected,
              onSelected: (_) => _onChipTap(option.value),
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.primary,
              showCheckmark: option.value != null,
            );
          }).toList(),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: _pplOptions.map((option) {
          final isSelected = option.value == null
              ? selected.isEmpty
              : selected.contains(option.value);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                option.icon,
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              label: Text(option.label),
              selected: isSelected,
              onSelected: (_) => _onChipTap(option.value),
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.primary,
              showCheckmark: option.value != null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PplOption {
  final String label;
  final String? value;
  final IconData icon;

  const _PplOption({
    required this.label,
    required this.value,
    required this.icon,
  });
}
