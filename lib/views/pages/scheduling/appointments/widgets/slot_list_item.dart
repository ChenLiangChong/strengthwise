import 'package:flutter/material.dart';
import 'package:strengthwise/models/availability_slot_model.dart';
import 'package:strengthwise/views/pages/scheduling/availability/unified_slot_card.dart';

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
    return UnifiedSlotCard(
      timeRange: slot.getTimeRangeString(),
      icon: slot.isRecurring ? Icons.repeat : Icons.event,
      iconColor: slot.isRecurring ? Colors.blue : Colors.green,
      additionalInfo:
          slot.recurrenceRule != null ? slot.getRecurrenceDescription() : null,
      subtitle: slot.notes,
      onTap: onTap,
      onDelete: onDelete,
    );
  }
}
