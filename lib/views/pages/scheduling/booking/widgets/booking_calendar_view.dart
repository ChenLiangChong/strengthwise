import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:strengthwise/views/shared/calendar/calendar_widgets.dart';
import 'booking_filter_chips.dart';
import 'booking_day_list.dart';

/// 訓練行事曆視圖元件
///
/// ⭐ v3.1: 三種訓練類型過濾
/// - 🏃 自主訓練
/// - 📋 教練安排
/// - 📍 上課（Session Mode）
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
  final bool showSessionPlans; // ⭐ v3.1: 上課

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
    required this.showSessionPlans,
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
    return UnifiedCalendar(
      focusedDay: focusedDay,
      selectedDay: selectedDay,
      format: calendarFormat,

      // 標記層：訓練 + 預約
      layers: [
        MarkerLayer(
          markerProvider: (day) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            final markers = <CalendarMarker>[];

            // 訓練標記（三種類型）
            final plans = trainings[normalizedDay] ?? [];
            for (var plan in plans) {
              final planType = plan['planType'] as String? ?? '';
              
              // ⭐ v3.1: 根據過濾器和類型決定是否顯示
              bool shouldShow = false;
              Color markerColor = Colors.blue;
              
              switch (planType) {
                case 'self':
                  shouldShow = showSelfPlans;
                  markerColor = Theme.of(context).colorScheme.primary;
                  break;
                case 'trainer':
                  shouldShow = showTrainerPlans;
                  markerColor = Theme.of(context).colorScheme.tertiary;
                  break;
                case 'session':
                  shouldShow = showSessionPlans;
                  markerColor = Theme.of(context).colorScheme.error;
                  break;
              }
              
              if (shouldShow) {
                markers.add(CalendarMarker(
                  color: markerColor,
                  tooltip: plan['title'] as String? ?? '',
                  data: plan,
                ));
              }
            }

            // 預約標記（總是顯示）
            final dayBookings = bookings[normalizedDay] ?? [];
            markers.addAll(dayBookings.map((b) => CalendarMarker(
                  color: Colors.green,
                  tooltip: b['coachName'] as String? ?? '',
                  data: b,
                )));

            return markers;
          },
          maxMarkers: 4,
        ),
      ],

      // 交互回調
      onDaySelected: onDaySelected,
      onFormatChanged: onFormatChanged,
      onPageChanged: onPageChanged,

      // 底部：過濾器 + 列表
      bottomSheet: Column(
        children: [
          // 過濾器
          BookingFilterChips(
            showSelfPlans: showSelfPlans,
            showTrainerPlans: showTrainerPlans,
            showSessionPlans: showSessionPlans,
            onToggle: onToggleFilter,
          ),

          const Divider(height: 1),

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
      ),
    );
  }
}
