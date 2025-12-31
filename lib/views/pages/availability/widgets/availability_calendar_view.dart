import 'package:flutter/material.dart';
import 'package:strengthwise/models/client_availability_model.dart';

/// 可用時段日曆視圖（簡化版）
/// 
/// 顯示時段的日曆視圖
class AvailabilityCalendarView extends StatelessWidget {
  final List<ClientAvailabilityModel> slots;
  final Function(ClientAvailabilityModel)? onSlotTap;
  final Function(ClientAvailabilityModel)? onSlotDelete;

  const AvailabilityCalendarView({
    Key? key,
    required this.slots,
    this.onSlotTap,
    this.onSlotDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: 實作完整的日曆視圖
    // 目前先使用簡化的列表視圖
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: _getPriorityIcon(slot.priority),
            title: Text(_formatTimeRange(slot)),
            subtitle: slot.notes != null ? Text(slot.notes!) : null,
            onTap: onSlotTap != null ? () => onSlotTap!(slot) : null,
            trailing: onSlotDelete != null
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => onSlotDelete!(slot),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _getPriorityIcon(AvailabilityPriority priority) {
    switch (priority) {
      case AvailabilityPriority.preferred:
        return const Icon(Icons.star, color: Colors.amber);
      case AvailabilityPriority.avoid:
        return const Icon(Icons.cancel, color: Colors.red);
      case AvailabilityPriority.available:
        return const Icon(Icons.check_circle, color: Colors.green);
    }
  }

  String _formatTimeRange(ClientAvailabilityModel slot) {
    final start = slot.startTime.toLocal();
    final end = slot.endTime.toLocal();
    
    return '${start.month}/${start.day} '
           '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - '
           '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }
}

