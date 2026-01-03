import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:strengthwise/services/interfaces/i_availability_slot_service.dart';
import 'package:strengthwise/views/shared/calendar/calendar_widgets.dart';

/// 可用時段日曆組件
class AvailableSlotsCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<AvailabilitySlotWithBooking> availableSlots;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;

  const AvailableSlotsCalendar({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.availableSlots,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedCalendar(
      focusedDay: focusedDay,
      selectedDay: selectedDay,
      format: CalendarFormat.month,
      
      // 標記層：可用時段
      layers: [
        MarkerLayer(
          markerProvider: (day) {
            final slots = _getSlotsForDay(day);
            return slots.map((slot) => CalendarMarker(
              color: Theme.of(context).colorScheme.primary,
              tooltip: '${slots.length} 個可用時段',
              data: slot,
            )).toList();
          },
        ),
      ],
      
      // 交互回調
      onDaySelected: onDaySelected,
      onFormatChanged: (_) {}, // 固定月曆格式
      onPageChanged: onPageChanged,
      
      startingDayOfWeek: StartingDayOfWeek.monday,
      
      // 隱藏格式切換按鈕
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }

  List<AvailabilitySlotWithBooking> _getSlotsForDay(DateTime day) {
    return availableSlots.where((slot) {
      final slotDate = DateTime(
        slot.slot.startTime.year,
        slot.slot.startTime.month,
        slot.slot.startTime.day,
      );
      final checkDate = DateTime(day.year, day.month, day.day);
      return slotDate == checkDate && !slot.isBooked;
    }).toList();
  }
}

