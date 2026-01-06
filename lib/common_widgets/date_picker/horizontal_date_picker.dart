import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 水平日期選擇器
///
/// 顯示一週的日期，支援左右滑動選擇日期。
/// 適用於預約系統的日期快速選擇。
class HorizontalDatePicker extends StatefulWidget {
  /// 當前選中的日期
  final DateTime selectedDate;

  /// 日期選擇回調
  final ValueChanged<DateTime> onDateSelected;

  /// 顯示天數（預設 7 天）
  final int daysToShow;

  /// 起始日期（預設今天）
  final DateTime? startDate;

  /// 最大可選日期
  final DateTime? maxDate;

  /// 最小可選日期
  final DateTime? minDate;

  /// 是否顯示月份標題
  final bool showMonthHeader;

  /// 日期標記（用於顯示有事件的日期）
  final Set<DateTime>? markedDates;

  const HorizontalDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.daysToShow = 7,
    this.startDate,
    this.maxDate,
    this.minDate,
    this.showMonthHeader = true,
    this.markedDates,
  });

  @override
  State<HorizontalDatePicker> createState() => _HorizontalDatePickerState();
}

class _HorizontalDatePickerState extends State<HorizontalDatePicker> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 月份標題（可選）
        if (widget.showMonthHeader)
          _buildMonthHeader(theme, colorScheme),

        const SizedBox(height: 8),

        // 日期列表
        SizedBox(
          height: 80,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, pageIndex) {
              return _buildWeekView(pageIndex, theme, colorScheme);
            },
          ),
        ),
      ],
    );
  }

  /// 月份標題
  Widget _buildMonthHeader(ThemeData theme, ColorScheme colorScheme) {
    final month = _getMonthFromPage(_currentPage);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 上一週
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > -52 ? _previousWeek : null, // 最多往前 52 週
            tooltip: '上一週',
          ),

          // 月份
          GestureDetector(
            onTap: _openFullCalendar,
            child: Row(
              children: [
                Text(
                  '${month.year} 年 ${month.month} 月',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),

          // 下一週
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < 52 ? _nextWeek : null, // 最多往後 52 週
            tooltip: '下一週',
          ),
        ],
      ),
    );
  }

  /// 一週的日期視圖
  Widget _buildWeekView(int pageIndex, ThemeData theme, ColorScheme colorScheme) {
    final startOfWeek = _getStartOfWeek(pageIndex);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.daysToShow, (index) {
        final date = startOfWeek.add(Duration(days: index));
        return _buildDateItem(date, theme, colorScheme);
      }),
    );
  }

  /// 單個日期項目
  Widget _buildDateItem(DateTime date, ThemeData theme, ColorScheme colorScheme) {
    final isSelected = _isSameDay(date, widget.selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    final isMarked = widget.markedDates?.any((d) => _isSameDay(d, date)) ?? false;
    final isDisabled = _isDateDisabled(date);

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onDateSelected(date);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 72,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : isToday
                  ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 星期
            Text(
              _getWeekdayShort(date.weekday),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimary
                    : isDisabled
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                        : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            // 日期
            Text(
              '${date.day}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? colorScheme.onPrimary
                    : isDisabled
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                        : colorScheme.onSurface,
              ),
            ),
            // 標記點（有事件）
            if (isMarked && !isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// 獲取指定頁面對應的週起始日
  DateTime _getStartOfWeek(int pageIndex) {
    final baseDate = widget.startDate ?? DateTime.now();
    final daysOffset = pageIndex * widget.daysToShow;
    final targetDate = baseDate.add(Duration(days: daysOffset));

    // 找到該週的週一
    final weekday = targetDate.weekday;
    return targetDate.subtract(Duration(days: weekday - 1));
  }

  /// 獲取指定頁面對應的月份
  DateTime _getMonthFromPage(int pageIndex) {
    final startOfWeek = _getStartOfWeek(pageIndex);
    // 取週中間的日期作為代表月份
    return startOfWeek.add(Duration(days: widget.daysToShow ~/ 2));
  }

  /// 頁面切換回調
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  /// 上一週
  void _previousWeek() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// 下一週
  void _nextWeek() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// 打開完整日曆
  Future<void> _openFullCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: widget.minDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: widget.maxDate ?? DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      widget.onDateSelected(picked);

      // 滾動到選中日期所在的週
      final baseDate = widget.startDate ?? DateTime.now();
      final daysDiff = picked.difference(baseDate).inDays;
      final targetPage = daysDiff ~/ widget.daysToShow;

      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 判斷日期是否被禁用
  bool _isDateDisabled(DateTime date) {
    if (widget.minDate != null && date.isBefore(widget.minDate!)) {
      return true;
    }
    if (widget.maxDate != null && date.isAfter(widget.maxDate!)) {
      return true;
    }
    return false;
  }

  /// 判斷是否為同一天
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 獲取星期縮寫
  String _getWeekdayShort(int weekday) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return weekdays[weekday - 1];
  }
}

