import 'package:flutter/material.dart';
import '../../../../../services/interfaces/i_availability_slot_service.dart';

/// 時段列表視圖組件
class SlotListView extends StatelessWidget {
  final DateTime selectedDay;
  final List<AvailabilitySlotWithBooking> availableSlots;
  final Function(AvailabilitySlotWithBooking) onSlotTapped;

  const SlotListView({
    super.key,
    required this.selectedDay,
    required this.availableSlots,
    required this.onSlotTapped,
  });

  @override
  Widget build(BuildContext context) {
    final slotsForDay = _getSlotsForDay();

    if (slotsForDay.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: slotsForDay.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final slot = slotsForDay[index];
        return _buildSlotCard(context, slot);
      },
    );
  }

  List<AvailabilitySlotWithBooking> _getSlotsForDay() {
    return availableSlots.where((slot) {
      final slotDate = DateTime(
        slot.slot.startTime.year,
        slot.slot.startTime.month,
        slot.slot.startTime.day,
      );
      final checkDate = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
      );
      return slotDate == checkDate;
    }).toList()
      ..sort((a, b) => a.slot.startTime.compareTo(b.slot.startTime));
  }

  Widget _buildSlotCard(BuildContext context, AvailabilitySlotWithBooking slot) {
    final isBooked = slot.isBooked;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isBooked ? null : () => onSlotTapped(slot),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 時間顯示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isBooked
                      ? Colors.grey[200]
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _formatTime(slot.slot.startTime),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isBooked ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${slot.slot.durationMinutes} 分鐘',
                      style: TextStyle(
                        fontSize: 12,
                        color: isBooked ? Colors.grey : null,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // 狀態資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.slot.displayTimeRange,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isBooked ? Colors.grey : null,
                      ),
                    ),
                    if (slot.slot.notes != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        slot.slot.notes!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // 狀態標籤
              if (isBooked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '已預約',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '此日期無可預約時段',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '請選擇其他日期',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

