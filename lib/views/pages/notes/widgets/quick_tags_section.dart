// ✅ v3.1: 快速標籤區塊（公用元件）
import 'package:flutter/material.dart';

/// 快速標籤區塊
///
/// 公用元件，可在以下頁面復用：
/// - SessionNoteEditorPage（編輯課程筆記）
/// - SessionNotesSection（Session Mode 課程筆記區塊）
class QuickTagsSection extends StatelessWidget {
  /// 可選標籤列表
  final List<String> availableTags;

  /// 已選標籤列表
  final List<String> selectedTags;

  /// 標籤選擇變更回調
  final ValueChanged<List<String>>? onTagsChanged;

  /// 是否唯讀
  final bool readOnly;

  /// 是否顯示標題
  final bool showTitle;

  /// 預設可用標籤
  static const List<String> defaultTags = [
    '首次評估',
    '進步顯著',
    '需要調整',
    '狀態良好',
    '需要追蹤',
    '特殊狀況',
  ];

  const QuickTagsSection({
    super.key,
    this.availableTags = defaultTags,
    required this.selectedTags,
    this.onTagsChanged,
    this.readOnly = false,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Row(
            children: [
              Icon(Icons.label, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '快速標籤',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (selectedTags.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${selectedTags.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableTags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: readOnly
                  ? null
                  : (selected) {
                      final newTags = List<String>.from(selectedTags);
                      if (selected) {
                        newTags.add(tag);
                      } else {
                        newTags.remove(tag);
                      }
                      onTagsChanged?.call(newTags);
                    },
            );
          }).toList(),
        ),
      ],
    );
  }
}

