import 'package:flutter/material.dart';

/// 訓練計劃過濾器元件
/// 
/// ⭐ v3.1 提供三種過濾選項：
/// - 🏃 自主訓練
/// - 📋 教練安排
/// - 📍 上課（Session Mode 關聯）
class BookingFilterChips extends StatelessWidget {
  /// 是否顯示自主訓練
  final bool showSelfPlans;
  
  /// 是否顯示教練計劃
  final bool showTrainerPlans;
  
  /// ⭐ v3.1: 是否顯示上課（有 appointmentId 的訓練）
  final bool showSessionPlans;
  
  /// 過濾器切換回調
  final void Function(String filterType) onToggle;
  
  const BookingFilterChips({
    super.key,
    required this.showSelfPlans,
    required this.showTrainerPlans,
    required this.showSessionPlans,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Text(
            '過濾：',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          
          // 🏃 自主訓練過濾器
          FilterChip(
            label: const Text('🏃 自主'),
            selected: showSelfPlans,
            onSelected: (_) => onToggle('self'),
            selectedColor: Theme.of(context).colorScheme.primaryContainer,
            checkmarkColor: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          
          // 📋 教練安排過濾器
          FilterChip(
            label: const Text('📋 教練安排'),
            selected: showTrainerPlans,
            onSelected: (_) => onToggle('trainer'),
            selectedColor: Theme.of(context).colorScheme.tertiaryContainer,
            checkmarkColor: Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(width: 8),
          
          // 📍 上課過濾器 ⭐ v3.1
          FilterChip(
            label: const Text('📍 上課'),
            selected: showSessionPlans,
            onSelected: (_) => onToggle('session'),
            selectedColor: Theme.of(context).colorScheme.errorContainer,
            checkmarkColor: Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }
}
