import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 動作搜尋列
///
/// 支援中英文即時搜尋，含清除按鈕。
/// Debounce 由父層處理。
class ExerciseSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  /// 自訂內邊距（預設使用響應式 pagePadding）
  final EdgeInsetsGeometry? padding;

  const ExerciseSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: context.pagePadding.left,
            vertical: context.spacing.sm,
          ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: '搜尋動作...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              );
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerLowest,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
