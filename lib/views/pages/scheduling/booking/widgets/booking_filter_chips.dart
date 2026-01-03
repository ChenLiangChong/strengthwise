import 'package:flutter/material.dart';

/// 預約和訓練計劃過濾器元件
/// 
/// 提供三種過濾選項：
/// - 自主訓練
/// - 教練計劃
/// - 預約
class BookingFilterChips extends StatelessWidget {
  /// 是否顯示自主訓練
  final bool showSelfPlans;
  
  /// 是否顯示教練計劃
  final bool showTrainerPlans;
  
  /// 是否顯示預約
  final bool showBookings;
  
  /// 過濾器切換回調
  final void Function(String filterType) onToggle;
  
  const BookingFilterChips({
    super.key,
    required this.showSelfPlans,
    required this.showTrainerPlans,
    required this.showBookings,
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
          
          // 自主訓練過濾器
          FilterChip(
            label: const Text('自主訓練'),
            selected: showSelfPlans,
            onSelected: (_) => onToggle('self'),
            selectedColor: Theme.of(context).colorScheme.primaryContainer,
            checkmarkColor: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          
          // 教練計劃過濾器
          FilterChip(
            label: const Text('教練計劃'),
            selected: showTrainerPlans,
            onSelected: (_) => onToggle('trainer'),
            selectedColor: Colors.blue.withOpacity(0.2),
            checkmarkColor: Colors.blue,
          ),
          const SizedBox(width: 8),
          
          // 預約過濾器
          FilterChip(
            label: const Text('預約'),
            selected: showBookings,
            onSelected: (_) => onToggle('bookings'),
            selectedColor: Theme.of(context).colorScheme.secondaryContainer,
            checkmarkColor: Theme.of(context).colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}

