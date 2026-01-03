import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// 純行事曆核心組件
///
/// 職責：
/// - 日期顯示
/// - 日期選擇
/// - 翻頁
///
/// 不包含：
/// - 業務邏輯
/// - 視覺化邏輯（由 dayBuilder 提供）
/// - 狀態管理（由父組件管理）
///
/// 設計理念：
/// - 完全解耦：只負責行事曆基礎功能
/// - 高度可定制：通過 dayBuilder 自定義日期單元格
/// - 無業務邏輯：純 UI 組件
class CalendarCore extends StatelessWidget {
  /// 聚焦日期
  final DateTime focusedDay;

  /// 選中日期
  final DateTime selectedDay;

  /// 行事曆格式
  final CalendarFormat format;

  /// 日期單元格構建器（核心擴展點）
  ///
  /// 參數：
  /// - context: BuildContext
  /// - day: 日期
  /// - isSelected: 是否選中
  /// - isToday: 是否今天
  final Widget Function(
    BuildContext context,
    DateTime day,
    bool isSelected,
    bool isToday,
  ) dayBuilder;

  /// 日期選擇回調
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;

  /// 格式變更回調
  final void Function(CalendarFormat format) onFormatChanged;

  /// 翻頁回調
  final void Function(DateTime focusedDay) onPageChanged;

  /// 行事曆樣式（可選）
  final CalendarStyle? calendarStyle;

  /// 標題樣式（可選）
  final HeaderStyle? headerStyle;

  /// 一週起始日
  final StartingDayOfWeek startingDayOfWeek;

  const CalendarCore({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.format,
    required this.dayBuilder,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
    this.calendarStyle,
    this.headerStyle,
    this.startingDayOfWeek = StartingDayOfWeek.monday,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      // 日期範圍
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: focusedDay,

      // 選中日期判斷
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),

      // 行事曆格式
      calendarFormat: format,

      // 一週起始日
      startingDayOfWeek: startingDayOfWeek,

      // 回調
      onDaySelected: onDaySelected,
      onFormatChanged: onFormatChanged,
      onPageChanged: onPageChanged,

      // 樣式
      calendarStyle: calendarStyle ?? _defaultCalendarStyle(context),
      headerStyle: headerStyle ?? _defaultHeaderStyle(),

      // 自定義日期單元格構建器
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          return dayBuilder(context, day, false, false);
        },
        selectedBuilder: (context, day, focusedDay) {
          return dayBuilder(context, day, true, false);
        },
        todayBuilder: (context, day, focusedDay) {
          return dayBuilder(context, day, false, true);
        },
      ),
    );
  }

  /// 預設行事曆樣式
  CalendarStyle _defaultCalendarStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CalendarStyle(
      // 今天樣式（更明顯的背景色）
      todayDecoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      todayTextStyle: TextStyle(
        color: colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.bold,
      ),

      // 選中樣式（更鮮明的顏色）
      selectedDecoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
      ),
      selectedTextStyle: TextStyle(
        color: colorScheme.onPrimary,
        fontWeight: FontWeight.bold,
      ),

      // 週末樣式
      weekendTextStyle: TextStyle(
        color: colorScheme.error,
      ),

      // 標記樣式（由 Layer 處理，這裡設為透明）
      markerDecoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      markersMaxCount: 0, // 標記由 Layer 處理
      
      // 單元格邊距
      cellMargin: const EdgeInsets.all(6),
      
      // 單元格對齊
      cellAlignment: Alignment.center,
    );
  }

  /// 預設標題樣式
  HeaderStyle _defaultHeaderStyle() {
    return const HeaderStyle(
      formatButtonVisible: true,
      titleCentered: true,
      formatButtonShowsNext: false,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
      formatButtonTextStyle: TextStyle(
        fontSize: 14,
      ),
      leftChevronIcon: Icon(Icons.chevron_left),
      rightChevronIcon: Icon(Icons.chevron_right),
    );
  }
}

