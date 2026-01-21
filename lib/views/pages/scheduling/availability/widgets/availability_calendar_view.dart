import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:strengthwise/models/client_availability_model.dart';
import 'package:strengthwise/views/shared/calendar/calendar_widgets.dart';
import 'package:strengthwise/views/pages/scheduling/availability/unified_slot_card.dart';

/// 學員時間偏好行事曆視圖
///
/// 功能：
/// - 顯示行事曆
/// - 標記已有時段（優先級圖示）
/// - 點擊時段編輯/刪除
class AvailabilityCalendarView extends StatefulWidget {
  final List<ClientAvailabilityModel> slots;
  final Function(ClientAvailabilityModel)? onSlotTap;
  final Function(ClientAvailabilityModel)? onSlotDelete;
  final Function(DateTime)? onDaySelected; // ⭐ 新增：日期選中回調

  const AvailabilityCalendarView({
    Key? key,
    required this.slots,
    this.onSlotTap,
    this.onSlotDelete,
    this.onDaySelected, // ⭐ 新增
  }) : super(key: key);

  @override
  State<AvailabilityCalendarView> createState() =>
      _AvailabilityCalendarViewState();
}

class _AvailabilityCalendarViewState extends State<AvailabilityCalendarView> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  /// 獲取指定日期的時段
  List<ClientAvailabilityModel> _getSlotsForDay(DateTime day) {
    return widget.slots.where((slot) {
      final slotDate = slot.startTime; // ⭐ 已經是本地時間
      return slotDate.year == day.year &&
          slotDate.month == day.month &&
          slotDate.day == day.day;
    }).toList();
  }

  /// 獲取優先級圖標數據
  IconData _getPriorityIconData(AvailabilityPriority priority) {
    switch (priority) {
      case AvailabilityPriority.preferred:
        return Icons.star;
      case AvailabilityPriority.avoid:
        return Icons.cancel;
      case AvailabilityPriority.available:
        return Icons.check_circle;
    }
  }

  /// 獲取優先級顏色
  Color _getPriorityColor(AvailabilityPriority priority) {
    switch (priority) {
      case AvailabilityPriority.preferred:
        return Colors.amber;
      case AvailabilityPriority.avoid:
        return Colors.red;
      case AvailabilityPriority.available:
        return Colors.green;
    }
  }

  /// 格式化時間範圍
  String _formatTimeRange(ClientAvailabilityModel slot) {
    final start = slot.startTime; // ⭐ 已經是本地時間
    final end = slot.endTime; // ⭐ 已經是本地時間

    return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - '
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final selectedDaySlots = _selectedDay != null
        ? _getSlotsForDay(_selectedDay!)
        : <ClientAvailabilityModel>[];

    // 準備標記數據（按日期分組）
    final Map<DateTime, List<ClientAvailabilityModel>> slotsByDate = {};
    for (final slot in widget.slots) {
      // 標準化日期（移除時間部分）
      final slotLocal = slot.startTime; // ⭐ 已經是本地時間
      final date = DateTime(slotLocal.year, slotLocal.month, slotLocal.day);
      slotsByDate.putIfAbsent(date, () => []).add(slot);
    }

    return UnifiedCalendar(
      focusedDay: _focusedDay,
      selectedDay: _selectedDay ?? _focusedDay,
      format: _calendarFormat,
      layers: [
        // 標記層：顯示已有時段
        MarkerLayer(
          markerProvider: (day) {
            // ⭐ 標準化日期（與 slotsByDate 的 key 格式一致）
            final normalizedDay = DateTime(day.year, day.month, day.day);
            final daySlots = slotsByDate[normalizedDay] ?? [];
            return daySlots.map((slot) {
              return CalendarMarker(
                color: _getPriorityColor(slot.priority),
                tooltip: _formatTimeRange(slot),
                data: slot,
              );
            }).toList();
          },
          maxMarkers: 3,
        ),
      ],
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        // ⭐ 回調選中日期變更
        widget.onDaySelected?.call(selectedDay);
      },
      onFormatChanged: (format) {
        setState(() => _calendarFormat = format);
      },
      onPageChanged: (focusedDay) {
        setState(() => _focusedDay = focusedDay);
      },

      // 底部：選定日期的時段列表
      bottomSheet: selectedDaySlots.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 64,
                    color:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '此日期無時段',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '點擊右下角按鈕新增時段',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: selectedDaySlots.length,
              itemBuilder: (context, index) {
                final slot = selectedDaySlots[index];
                return UnifiedSlotCard(
                  timeRange: _formatTimeRange(slot),
                  icon: _getPriorityIconData(slot.priority),
                  iconColor: _getPriorityColor(slot.priority),
                  subtitle: slot.notes,
                  onTap: widget.onSlotTap != null
                      ? () => widget.onSlotTap!(slot)
                      : null,
                  onDelete: widget.onSlotDelete != null
                      ? () => widget.onSlotDelete!(slot)
                      : null,
                );
              },
            ),
    );
  }
}
