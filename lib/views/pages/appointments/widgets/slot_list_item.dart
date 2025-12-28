import 'package:flutter/material.dart';
import '../../../../models/availability_slot_model.dart';

/// 時段列表項目組件
class SlotListItem extends StatelessWidget {
  final AvailabilitySlotModel slot;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SlotListItem({
    super.key,
    required this.slot,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: slot.isRecurring 
              ? Colors.blue.withOpacity(0.2)
              : Colors.green.withOpacity(0.2),
          child: Icon(
            slot.isRecurring ? Icons.repeat : Icons.event,
            color: slot.isRecurring ? Colors.blue : Colors.green,
          ),
        ),
        title: Text(slot.getTimeRangeString()),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (slot.recurrenceRule != null)
              Text(slot.getRecurrenceDescription()),
            if (slot.notes != null && slot.notes!.isNotEmpty)
              Text(
                slot.notes!,
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}

