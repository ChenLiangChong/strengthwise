import 'package:flutter/material.dart';

/// 時段空狀態組件
/// 
/// 當教練尚未設定任何時段時顯示
class EmptySlotState extends StatelessWidget {
  final VoidCallback onAddSlot;

  const EmptySlotState({
    super.key,
    required this.onAddSlot,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '尚未設定時段',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '點擊下方按鈕新增可預約時段',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddSlot,
            icon: const Icon(Icons.add),
            label: const Text('新增時段'),
          ),
        ],
      ),
    );
  }
}

