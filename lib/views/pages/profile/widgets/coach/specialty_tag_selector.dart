import 'package:flutter/material.dart';
import 'package:strengthwise/models/coach_profile/coach_specialty.dart';

/// 專長標籤選擇器
/// 
/// 支援：
/// 1. 預定義標籤（分類顯示）
/// 2. 自定義標籤（custom: 前綴）
/// 3. 最多選擇 8 個標籤
class SpecialtyTagSelector extends StatefulWidget {
  /// 已選擇的標籤
  final List<String> selectedTags;

  /// 標籤變更回調
  final ValueChanged<List<String>> onChanged;

  /// 最大標籤數
  final int maxTags;

  const SpecialtyTagSelector({
    super.key,
    required this.selectedTags,
    required this.onChanged,
    this.maxTags = 8,
  });

  @override
  State<SpecialtyTagSelector> createState() => _SpecialtyTagSelectorState();
}

class _SpecialtyTagSelectorState extends State<SpecialtyTagSelector> {
  final _customTagController = TextEditingController();
  bool _showCustomInput = false;

  @override
  void dispose() {
    _customTagController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    final newTags = List<String>.from(widget.selectedTags);
    
    if (newTags.contains(tag)) {
      newTags.remove(tag);
    } else if (newTags.length < widget.maxTags) {
      newTags.add(tag);
    }
    
    widget.onChanged(newTags);
  }

  void _addCustomTag() {
    final label = _customTagController.text.trim();
    if (label.isEmpty) return;

    final customValue = CoachSpecialty.createCustomValue(label);
    
    if (!widget.selectedTags.contains(customValue) &&
        widget.selectedTags.length < widget.maxTags) {
      final newTags = [...widget.selectedTags, customValue];
      widget.onChanged(newTags);
      _customTagController.clear();
      setState(() => _showCustomInput = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題與計數
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '專長領域',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.selectedTags.length}/${widget.maxTags}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: widget.selectedTags.isEmpty
                    ? colorScheme.error
                    : colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 已選標籤
        if (widget.selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedTags.map((tag) {
              return Chip(
                label: Text(CoachSpecialty.getLabel(tag)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _toggleTag(tag),
                backgroundColor: colorScheme.primaryContainer,
                labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // 分類顯示預定義標籤
        ...SpecialtyCategory.values.map((category) {
          return _CategorySection(
            category: category,
            selectedTags: widget.selectedTags,
            onToggle: _toggleTag,
            isDisabled: widget.selectedTags.length >= widget.maxTags,
          );
        }),

        const SizedBox(height: 16),

        // 自定義標籤
        if (_showCustomInput)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customTagController,
                  decoration: InputDecoration(
                    hintText: '輸入自定義專長',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (_) => _addCustomTag(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addCustomTag,
                icon: const Icon(Icons.check),
                color: colorScheme.primary,
              ),
              IconButton(
                onPressed: () {
                  setState(() => _showCustomInput = false);
                  _customTagController.clear();
                },
                icon: const Icon(Icons.close),
              ),
            ],
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.selectedTags.length >= widget.maxTags
                  ? null
                  : () => setState(() => _showCustomInput = true),
              icon: const Icon(Icons.add),
              label: const Text('新增自定義專長'),
            ),
          ),
      ],
    );
  }
}

/// 專長分類區塊
class _CategorySection extends StatelessWidget {
  final SpecialtyCategory category;
  final List<String> selectedTags;
  final ValueChanged<String> onToggle;
  final bool isDisabled;

  const _CategorySection({
    required this.category,
    required this.selectedTags,
    required this.onToggle,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            category.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: category.specialties.map((specialty) {
            final isSelected = selectedTags.contains(specialty.value);
            final canSelect = !isDisabled || isSelected;

            return FilterChip(
              label: Text(specialty.label),
              selected: isSelected,
              onSelected: canSelect
                  ? (_) => onToggle(specialty.value)
                  : null,
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.onPrimaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }
}

