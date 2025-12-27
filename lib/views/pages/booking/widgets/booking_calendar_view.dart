import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'booking_filter_chips.dart';
import 'booking_day_list.dart';

/// 預約行事曆視圖元件
/// 
/// 包含：
/// - 行事曆（TableCalendar）
/// - 過濾器（BookingFilterChips）
/// - 選定日期的活動列表（BookingDayList）
class BookingCalendarView extends StatelessWidget {
  /// 聚焦的日期
  final DateTime focusedDay;
  
  /// 選定的日期
  final DateTime selectedDay;
  
  /// 行事曆格式
  final CalendarFormat calendarFormat;
  
  /// 訓練計劃數據（按日期分組）
  final Map<DateTime, List<Map<String, dynamic>>> trainings;
  
  /// 預約數據（按日期分組）
  final Map<DateTime, List<Map<String, dynamic>>> bookings;
  
  /// 選定日期的訓練計劃
  final List<Map<String, dynamic>> selectedDayTrainings;
  
  /// 選定日期的預約
  final List<Map<String, dynamic>> selectedDayBookings;
  
  /// 當前用戶 ID
  final String? currentUserId;
  
  /// 是否為教練模式
  final bool isCoachMode;
  
  /// 過濾器狀態
  final bool showSelfPlans;
  final bool showTrainerPlans;
  final bool showBookings;
  
  /// 日期選擇回調
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  
  /// 行事曆格式變更回調
  final void Function(CalendarFormat format) onFormatChanged;
  
  /// 頁面變更回調
  final void Function(DateTime focusedDay) onPageChanged;
  
  /// 過濾器切換回調
  final void Function(String filterType) onToggleFilter;
  
  /// 執行訓練計劃回調
  final void Function(String planId)? onExecuteTraining;
  
  /// 編輯訓練計劃回調
  final void Function(String planId, DateTime scheduledDate)? onEditTraining;
  
  /// 刪除訓練計劃回調
  final void Function(String planId, String planTitle)? onDeleteTraining;
  
  /// 取消預約回調
  final void Function(String bookingId)? onCancelBooking;
  
  /// 確認預約回調
  final void Function(String bookingId)? onConfirmBooking;
  
  /// 查看預約詳情回調
  final VoidCallback? onViewBookingDetails;
  
  const BookingCalendarView({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.trainings,
    required this.bookings,
    required this.selectedDayTrainings,
    required this.selectedDayBookings,
    this.currentUserId,
    required this.isCoachMode,
    required this.showSelfPlans,
    required this.showTrainerPlans,
    required this.showBookings,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
    required this.onToggleFilter,
    this.onExecuteTraining,
    this.onEditTraining,
    this.onDeleteTraining,
    this.onCancelBooking,
    this.onConfirmBooking,
    this.onViewBookingDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 行事曆部分
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDay,
          calendarFormat: calendarFormat,
          eventLoader: _eventLoader,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: onDaySelected,
          onFormatChanged: onFormatChanged,
          onPageChanged: onPageChanged,
          calendarStyle: CalendarStyle(
            markersMaxCount: 4,
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        const Divider(height: 1),
        
        // 過濾器
        BookingFilterChips(
          showSelfPlans: showSelfPlans,
          showTrainerPlans: showTrainerPlans,
          showBookings: showBookings,
          onToggle: onToggleFilter,
        ),
        
        // 選定日期的數據列表
        Expanded(
          child: BookingDayList(
            trainings: selectedDayTrainings,
            bookings: selectedDayBookings,
            currentUserId: currentUserId,
            isCoachMode: isCoachMode,
            onExecuteTraining: onExecuteTraining,
            onEditTraining: onEditTraining,
            onDeleteTraining: onDeleteTraining,
            onCancelBooking: onCancelBooking,
            onConfirmBooking: onConfirmBooking,
            onViewBookingDetails: onViewBookingDetails,
          ),
        ),
      ],
    );
  }
  
  /// 行事曆事件加載器
  /// 
  /// 根據過濾器狀態，返回指定日期的所有活動
  List<Map<String, dynamic>> _eventLoader(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final allEvents = <Map<String, dynamic>>[];
    
    // 添加訓練計劃
    if (showSelfPlans || showTrainerPlans) {
      final plans = trainings[normalizedDay] ?? [];
      for (var plan in plans) {
        final planType = plan['planType'] as String? ?? '';
        if ((planType == 'self' && showSelfPlans) || 
            (planType == 'trainer' && showTrainerPlans)) {
          allEvents.add(plan);
        }
      }
    }
    
    // 添加預約
    if (showBookings) {
      final dayBookings = bookings[normalizedDay] ?? [];
      allEvents.addAll(dayBookings);
    }
    
    return allEvents;
  }
}

