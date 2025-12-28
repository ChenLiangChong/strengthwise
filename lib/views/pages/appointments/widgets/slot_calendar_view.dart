import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../models/availability_slot_model.dart';

/// 時段日曆視圖組件
///
/// 顯示月曆並標記有時段的日期
class SlotCalendarView extends StatelessWidget {
  final List<AvailabilitySlotModel> slots;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Function(AvailabilitySlotModel) onSlotTap;
  final VoidCallback? onAddSlotForSelectedDate; // 新增：點擊添加時段回調

  const SlotCalendarView({
    super.key,
    required this.slots,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onSlotTap,
    this.onAddSlotForSelectedDate,
  });

  /// 獲取當天的時段列表
  List<AvailabilitySlotModel> _getSlotsForDay(DateTime day) {
    return slots.where((slot) {
      // 將 UTC 時間轉為本地時間進行比較
      final slotDate = slot.startTime.toLocal();
      return slotDate.year == day.year &&
          slotDate.month == day.month &&
          slotDate.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 日曆
        TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: selectedDate,
          selectedDayPredicate: (day) => isSameDay(selectedDate, day),
          onDaySelected: (selectedDay, focusedDay) {
            onDateSelected(selectedDay);
          },
          eventLoader: _getSlotsForDay,
          calendarStyle: CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        const Divider(height: 1),
        // 當天時段列表
        Expanded(
          child: _buildDaySlotsList(),
        ),
      ],
    );
  }

  /// 建立當天時段列表
  Widget _buildDaySlotsList() {
    final daySlots = _getSlotsForDay(selectedDate);

    if (daySlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '該日期無時段',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '點擊下方按鈕添加可預約時段',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            if (onAddSlotForSelectedDate != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAddSlotForSelectedDate,
                icon: const Icon(Icons.add),
                label: const Text('快速添加時段'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: daySlots.length,
      itemBuilder: (context, index) {
        final slot = daySlots[index];
        return Card(
          child: ListTile(
            leading: Icon(
              slot.isRecurring ? Icons.repeat : Icons.event,
              color: slot.isRecurring ? Colors.blue : Colors.green,
            ),
            title: Text(slot.getTimeRangeString()),
            subtitle: slot.notes != null && slot.notes!.isNotEmpty
                ? Text(slot.notes!)
                : null,
            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
            onTap: () => onSlotTap(slot),
          ),
        );
      },
    );
  }
}

