import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'calendar_layer.dart';
import 'layers/marker_layer.dart';

/// 統一行事曆組合器
///
/// 核心理念：
/// - 組合多個 Layer
/// - 統一管理交互
/// - 提供統一 API
///
/// 設計理念：
/// - 組合優於繼承
/// - 完全解耦
/// - 高度可擴展
///
/// 使用範例：
/// ```dart
/// UnifiedCalendar(
///   focusedDay: _focusedDay,
///   selectedDay: _selectedDay,
///   format: _calendarFormat,
///
///   layers: [
///     BackgroundLayer(colorProvider: ...),
///     MarkerLayer(markerProvider: ...),
///   ],
///
///   onDaySelected: (selectedDay, focusedDay) {
///     setState(() {
///       _selectedDay = selectedDay;
///       _focusedDay = focusedDay;
///     });
///   },
///
///   bottomSheet: _buildEventList(),
/// )
/// ```
class UnifiedCalendar extends StatelessWidget {
  /// 行事曆狀態（由 Controller 管理）
  final DateTime focusedDay;
  final DateTime selectedDay;
  final CalendarFormat format;

  /// 視覺化層（按順序疊加）
  ///
  /// Layer 疊加順序：
  /// 1. Layer[0]（最底層，通常是 BackgroundLayer）
  /// 2. Layer[1]
  /// 3. Layer[n]（最頂層）
  /// 4. 日期數字（永遠在最頂層）
  final List<CalendarLayer> layers;

  /// 交互回調
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final void Function(DateTime day)? onDayLongPress;
  final void Function(CalendarFormat format) onFormatChanged;
  final void Function(DateTime focusedDay) onPageChanged;

  /// 底部事件列表（可選）
  final Widget? bottomSheet;

  /// 行事曆樣式（可選）
  final CalendarStyle? calendarStyle;

  /// 標題樣式（可選）
  final HeaderStyle? headerStyle;

  /// 一週起始日
  final StartingDayOfWeek startingDayOfWeek;

  const UnifiedCalendar({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.format,
    required this.layers,
    required this.onDaySelected,
    this.onDayLongPress,
    required this.onFormatChanged,
    required this.onPageChanged,
    this.bottomSheet,
    this.calendarStyle,
    this.headerStyle,
    this.startingDayOfWeek = StartingDayOfWeek.monday,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 直接使用 TableCalendar（不用 CalendarCore）
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          calendarFormat: format,
          startingDayOfWeek: startingDayOfWeek,
          onDaySelected: onDaySelected,
          onFormatChanged: onFormatChanged,
          onPageChanged: onPageChanged,

          // ⭐ 自訂日期渲染（支援 BackgroundLayer）
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final isToday = isSameDay(day, DateTime.now());
              return _buildDayCell(context, day, isToday, false);
            },
            todayBuilder: (context, day, focusedDay) {
              return _buildDayCell(context, day, true, false);
            },
            selectedBuilder: (context, day, focusedDay) {
              final isToday = isSameDay(day, DateTime.now());
              return _buildDayCell(context, day, isToday, true);
            },
            outsideBuilder: (context, day, focusedDay) {
              final isToday = isSameDay(day, DateTime.now());
              return _buildDayCell(context, day, isToday, false,
                  isOutside: true);
            },
          ),

          // 使用預設樣式 + 標記（邊框式選中，不遮蓋標記點）
          calendarStyle: calendarStyle ??
              CalendarStyle(
                // 標記點配置
                markersMaxCount: 4,
                markerDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markerSize: 7,
                markersAnchor: 1.4,

                // 今天：淡背景（不干擾標記點）
                todayDecoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),

                // ⭐ 選中日期：邊框式（標記點完全清晰可見）
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                selectedTextStyle: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),

          headerStyle: headerStyle ??
              const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
              ),

          // 事件加載器（標記）
          eventLoader: (day) {
            final markers = <dynamic>[];
            for (final layer in layers) {
              if (layer is MarkerLayer) {
                final layerMarkers = layer.markerProvider(day);
                markers.addAll(layerMarkers);
              }
            }
            return markers;
          },
        ),

        // 分隔線
        if (bottomSheet != null) const Divider(height: 1),

        // 底部事件列表（包裹 SingleChildScrollView 確保可滾動）⭐
        if (bottomSheet != null)
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),  // ⭐ 始終可滾動
              child: SizedBox(
                height: 400,  // ⭐ 最小高度，確保有滾動空間
                child: bottomSheet!,
              ),
            ),
          ),
      ],
    );
  }

  /// 建立日期儲存格（支援 BackgroundLayer）
  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    bool isToday,
    bool isSelected, {
    bool isOutside = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // 1. 尋找 BackgroundLayer 並獲取背景色
    Color? backgroundColor;
    for (final layer in layers) {
      // ⚡ 使用鴨子類型：只要不是 MarkerLayer 就嘗試獲取背景
      if (layer is! MarkerLayer) {
        final layerWidget = layer.buildDay(context, day);
        if (layerWidget is Container &&
            layerWidget.decoration is BoxDecoration) {
          final decoration = layerWidget.decoration as BoxDecoration;
          backgroundColor = decoration.color;
          break;
        }
      }
    }

    // 2. 建立日期文字
    Widget dateText = Center(
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: isOutside
              ? colorScheme.onSurface.withOpacity(0.3)
              : colorScheme.onSurface,
          fontWeight:
              isToday || isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );

    // 3. 決定背景和邊框
    // - 未選中的今天：淡色圓形背景（僅在沒有 BackgroundLayer 時）
    // - 選中任何日期：圓形外框
    Color? finalBackgroundColor = backgroundColor;
    Border? border;
    
    if (isToday && !isSelected) {
      // ⭐ 未選中的今天：只有在沒有 BackgroundLayer 背景色時，才顯示今天的背景色
      if (backgroundColor == null) {
        finalBackgroundColor = colorScheme.primaryContainer.withOpacity(0.5);
      }
      // 如果已經有背景色（例如偏好時段），就保留它，不覆蓋
    } else if (isSelected) {
      // ⭐ 選中任何日期：圓形外框
      border = Border.all(color: colorScheme.primary, width: 2);
    }
    
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: finalBackgroundColor,
        shape: BoxShape.circle,
        border: border,
      ),
      child: dateText,
    );
  }
}
