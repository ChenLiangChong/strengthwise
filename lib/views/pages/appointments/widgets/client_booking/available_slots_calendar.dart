import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../../services/interfaces/i_availability_slot_service.dart';

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
    return TableCalendar(
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(const Duration(days: 90)),
      focusedDay: focusedDay,
      selectedDayPredicate: (day) => isSameDay(day, selectedDay),
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      eventLoader: (day) {
        // 回傳該日期的可用時段數量（用於顯示標記）
        return _getSlotsForDay(day);
      },
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

