import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:strengthwise/models/availability_slot_model.dart';
import 'package:strengthwise/views/shared/calendar/calendar_widgets.dart';
import 'package:strengthwise/views/pages/scheduling/availability/unified_slot_card.dart';

/// 時段日曆視圖組件
///
/// 顯示月曆並標記有時段的日期
class SlotCalendarView extends StatelessWidget {
  final List<AvailabilitySlotModel> slots;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Function(AvailabilitySlotModel) onSlotTap;
  final Function(String slotId)? onSlotDelete; // 刪除時段回調
  final VoidCallback? onAddSlotForSelectedDate; // 新增：點擊添加時段回調

  const SlotCalendarView({
    super.key,
    required this.slots,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onSlotTap,
    this.onSlotDelete,
    this.onAddSlotForSelectedDate,
  });

  /// 獲取當天的時段列表
  List<AvailabilitySlotModel> _getSlotsForDay(DateTime day) {
    return slots.where((slot) {
      final slotDate = slot.startTime; // ⭐ 已經是本地時間
      return slotDate.year == day.year &&
          slotDate.month == day.month &&
          slotDate.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedCalendar(
      focusedDay: selectedDate,
      selectedDay: selectedDate,
      format: CalendarFormat.month,

      // 標記層：時段
      layers: [
        MarkerLayer(
          markerProvider: (day) {
            final daySlots = _getSlotsForDay(day);
            return daySlots
                .map((slot) => CalendarMarker(
                      color: slot.isRecurring ? Colors.blue : Colors.green,
                      tooltip: slot.getTimeRangeString(),
                      data: slot,
                    ))
                .toList();
          },
          maxMarkers: 3,
        ),
      ],

      // 交互回調
      onDaySelected: (selectedDay, focusedDay) {
        onDateSelected(selectedDay);
      },
      onFormatChanged: (_) {}, // 固定月曆格式
      onPageChanged: (_) {}, // 不處理翻頁

      // 隱藏格式切換按鈕
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),

      // 底部時段列表
      bottomSheet: _buildDaySlotsList(),
    );
  }

  /// 建立當天時段列表
  Widget _buildDaySlotsList() {
    final daySlots = _getSlotsForDay(selectedDate);

    if (daySlots.isEmpty) {
      // ⭐ 修復：使用 SingleChildScrollView 包裹 Column，避免溢出
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
        return UnifiedSlotCard(
          timeRange: slot.getTimeRangeString(),
          icon: slot.isRecurring ? Icons.repeat : Icons.event,
          iconColor: slot.isRecurring ? Colors.blue : Colors.green,
          additionalInfo: slot.recurrenceRule != null
              ? slot.getRecurrenceDescription()
              : null,
          subtitle: slot.notes,
          onTap: () => onSlotTap(slot),
          onDelete: onSlotDelete != null ? () => onSlotDelete!(slot.id) : null,
        );
      },
    );
  }
}
