import 'package:flutter/material.dart';
import 'package:strengthwise/models/exercise/exercise_labels.dart';

/// 篩選器狀態
class FilterState {
  /// 已選器材（多選）
  final Set<String> selectedEquipment;
  final String? difficultyLevel;
  final String? mechanicsType;
  final bool? isExplosive;

  const FilterState({
    this.selectedEquipment = const {},
    this.difficultyLevel,
    this.mechanicsType,
    this.isExplosive,
  });

  /// 是否有啟用的篩選器
  bool get hasActiveFilters =>
      selectedEquipment.isNotEmpty ||
      difficultyLevel != null ||
      mechanicsType != null ||
      isExplosive != null;

  FilterState copyWith({
    Set<String>? selectedEquipment,
    String? Function()? difficultyLevel,
    String? Function()? mechanicsType,
    bool? Function()? isExplosive,
  }) {
    return FilterState(
      selectedEquipment: selectedEquipment ?? this.selectedEquipment,
      difficultyLevel:
          difficultyLevel != null ? difficultyLevel() : this.difficultyLevel,
      mechanicsType:
          mechanicsType != null ? mechanicsType() : this.mechanicsType,
      isExplosive: isExplosive != null ? isExplosive() : this.isExplosive,
    );
  }
}

/// 內嵌篩選器列
///
/// 收合狀態：顯示「篩選」按鈕 + 已啟用 chips（可逐一移除）
/// 展開狀態：器材/難度/類型/爆發力完整篩選控件
class ExerciseFiltersBar extends StatefulWidget {
  /// 目前的篩選狀態
  final FilterState currentFilters;

  /// 器材選項列表
  final List<Map<String, String>> equipmentOptions;

  /// 篩選變更回調
  final ValueChanged<FilterState> onFilterChanged;

  /// 始終展開（sidebar 模式），預設 false（可收合的 inline 模式）
  final bool alwaysExpanded;

  const ExerciseFiltersBar({
    super.key,
    required this.currentFilters,
    required this.equipmentOptions,
    required this.onFilterChanged,
    this.alwaysExpanded = false,
  });

  @override
  State<ExerciseFiltersBar> createState() => _ExerciseFiltersBarState();
}

class _ExerciseFiltersBarState extends State<ExerciseFiltersBar> {
  bool _isExpanded = false;

  void _updateFilter(FilterState newState) {
    widget.onFilterChanged(newState);
  }

  void _removeFilter(String field, [String? equipmentId]) {
    final current = widget.currentFilters;
    switch (field) {
      case 'equipment':
        if (equipmentId != null) {
          final updated = Set<String>.from(current.selectedEquipment)
            ..remove(equipmentId);
          _updateFilter(current.copyWith(selectedEquipment: updated));
        } else {
          _updateFilter(current.copyWith(selectedEquipment: {}));
        }
        break;
      case 'difficulty':
        _updateFilter(current.copyWith(difficultyLevel: () => null));
        break;
      case 'mechanics':
        _updateFilter(current.copyWith(mechanicsType: () => null));
        break;
      case 'explosive':
        _updateFilter(current.copyWith(isExplosive: () => null));
        break;
    }
  }

  String _getEquipmentName(String id) {
    final match = widget.equipmentOptions.cast<Map<String, String>?>().firstWhere(
          (e) => e?['id'] == id,
          orElse: () => null,
        );
    return match?['nameZh'] ?? id;
  }

  String _getDifficultyLabel(String id) =>
      ExerciseLabels.resolve(ExerciseLabels.difficulty, id);

  String _getMechanicsLabel(String id) =>
      ExerciseLabels.resolve(ExerciseLabels.mechanics, id);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filters = widget.currentFilters;

    // sidebar 模式：始終展開，不顯示收合控件
    if (widget.alwaysExpanded) {
      return _buildExpandedSection(colorScheme);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 收合列：篩選按鈕 + 已啟用 chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 篩選按鈕
                ActionChip(
                  avatar: Icon(
                    _isExpanded ? Icons.expand_less : Icons.tune,
                    size: 18,
                    color: filters.hasActiveFilters
                        ? colorScheme.primary
                        : null,
                  ),
                  label: Text(
                    _isExpanded ? '收合' : '篩選',
                    style: filters.hasActiveFilters
                        ? TextStyle(color: colorScheme.primary)
                        : null,
                  ),
                  onPressed: () =>
                      setState(() => _isExpanded = !_isExpanded),
                ),
                const SizedBox(width: 8),

                // 已啟用 chips：器材（多選）
                ...filters.selectedEquipment.map((id) => _ActiveFilterChip(
                  label: _getEquipmentName(id),
                  onRemove: () => _removeFilter('equipment', id),
                )),
                if (filters.difficultyLevel != null)
                  _ActiveFilterChip(
                    label: _getDifficultyLabel(filters.difficultyLevel!),
                    onRemove: () => _removeFilter('difficulty'),
                  ),
                if (filters.mechanicsType != null)
                  _ActiveFilterChip(
                    label: _getMechanicsLabel(filters.mechanicsType!),
                    onRemove: () => _removeFilter('mechanics'),
                  ),
                if (filters.isExplosive == true)
                  _ActiveFilterChip(
                    label: '爆發力',
                    onRemove: () => _removeFilter('explosive'),
                  ),
              ],
            ),
          ),
        ),

        // 展開區域（限高，內容可捲動）
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: SingleChildScrollView(
              child: _buildExpandedSection(colorScheme),
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildExpandedSection(ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    final filters = widget.currentFilters;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 器材
          Text('器材', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.equipmentOptions.map((item) {
              final id = item['id'] ?? '';
              final name = item['nameZh'] ?? id;
              final isSelected = filters.selectedEquipment.contains(id);
              return FilterChip(
                label: Text(name),
                selected: isSelected,
                onSelected: (_) {
                  final updated = Set<String>.from(filters.selectedEquipment);
                  if (isSelected) {
                    updated.remove(id);
                  } else {
                    updated.add(id);
                  }
                  _updateFilter(filters.copyWith(selectedEquipment: updated));
                },
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.primary,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 難度
          Text('難度', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ExerciseLabels.difficulty.entries.map((entry) {
              final isSelected = filters.difficultyLevel == entry.key;
              return ChoiceChip(
                label: Text(entry.value.$1),
                selected: isSelected,
                onSelected: (_) {
                  _updateFilter(filters.copyWith(
                    difficultyLevel: () => isSelected ? null : entry.key,
                  ));
                },
                selectedColor: colorScheme.primaryContainer,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 動作類型
          Text('動作類型', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ExerciseLabels.mechanics.entries.map((entry) {
              final isSelected = filters.mechanicsType == entry.key;
              return ChoiceChip(
                label: Text(entry.value.$1),
                selected: isSelected,
                onSelected: (_) {
                  _updateFilter(filters.copyWith(
                    mechanicsType: () => isSelected ? null : entry.key,
                  ));
                },
                selectedColor: colorScheme.primaryContainer,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // 爆發力
          CheckboxListTile(
            title: const Text('僅顯示爆發力動作'),
            subtitle: const Text('瞬發上搏、跳躍等爆發性動作'),
            value: filters.isExplosive ?? false,
            onChanged: (value) {
              _updateFilter(filters.copyWith(
                isExplosive: () => (value == true) ? true : null,
              ));
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
    );
  }
}

/// 已啟用篩選 chip（帶移除按鈕）
class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveFilterChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(
        label: Text(label),
        onDeleted: onRemove,
        deleteIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
