import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:strengthwise/views/shared/calendar/calendar_widgets.dart';
import 'package:strengthwise/services/interfaces/i_availability_slot_service.dart';
import 'package:strengthwise/models/client_availability_model.dart';
import 'booking_filter_chips.dart';
import 'training_plan_card.dart';

/// 訓練行事曆視圖元件
///
/// ⭐ v3.1-B: 支援 Tab 分離顯示
/// - Tab 1「我的」：我的訓練 + 教練可上課時段
/// - Tab 2「教練」：我要教的課 + 學員可訓練時段
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

  /// 是否為教練模式（Tab 2）
  final bool isCoachMode;

  /// 過濾器狀態
  final bool showSelfPlans;
  final bool showTrainerPlans;
  final bool showSessionPlans;

  // ⭐ v3.1-B: 新增時段數據
  /// 教練可上課時段（Tab 1 用）
  final Map<DateTime, List<AvailabilitySlotWithBooking>>? coachSlots;

  /// 選定日期的教練可上課時段
  final List<AvailabilitySlotWithBooking>? selectedDayCoachSlots;

  /// 學員可訓練時段（Tab 2 用）
  final Map<DateTime, List<ClientAvailabilityModel>>? clientAvailability;

  /// 選定日期的學員可訓練時段
  final List<ClientAvailabilityModel>? selectedDayClientAvailability;

  /// 教練 ID -> 名稱映射（多教練支援）
  final Map<String, String> coachNames;

  /// ⭐ v3.1.1: 學員 ID -> 名稱映射
  final Map<String, String> clientNames;

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

  // ⭐ v3.1-B: 新增回調
  /// 預約教練時段回調
  final void Function(AvailabilitySlotWithBooking slot)? onBookCoachSlot;

  /// 點擊學員可訓練時段回調（導航到新增訓練）
  final void Function(ClientAvailabilityModel slot)? onSelectClientSlot;

  /// 進入 Session Mode 回調
  final void Function(String planId, String appointmentId)? onEnterSession;

  // ⭐ v3.9: 我的可上課時段操作回調
  /// 編輯我的時段回調
  final void Function(AvailabilitySlotWithBooking slot)? onEditMySlot;

  /// 刪除我的時段回調
  final void Function(AvailabilitySlotWithBooking slot)? onDeleteMySlot;

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
    this.coachSlots,
    this.selectedDayCoachSlots,
    this.clientAvailability,
    this.selectedDayClientAvailability,
    this.coachNames = const {},
    this.clientNames = const {}, // ⭐ v3.1.1
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
    this.onBookCoachSlot,
    this.onSelectClientSlot,
    this.onEnterSession,
    this.onEditMySlot,
    this.onDeleteMySlot,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return UnifiedCalendar(
      focusedDay: focusedDay,
      selectedDay: selectedDay,
      format: calendarFormat,

      // ⭐ v3.1-B: 標記層 - 根據 Tab 顯示不同顏色
      layers: [
        MarkerLayer(
          markerProvider: (day) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            final markers = <CalendarMarker>[];

            // 訓練標記
            final plans = trainings[normalizedDay] ?? [];
            // if (plans.isNotEmpty) {
            //   debugPrint(
            //       '[CALENDAR MARKER] 📅 $normalizedDay: ${plans.length} 個計劃');
            // }
            for (var plan in plans) {
              final planType = plan['planType'] as String? ?? '';

              bool shouldShow = false;
              Color markerColor = colorScheme.primary;

              switch (planType) {
                case 'self':
                  shouldShow = showSelfPlans;
                  markerColor = colorScheme.primary; // 🔵 藍色
                  break;
                case 'trainer':
                  shouldShow = showTrainerPlans;
                  markerColor = colorScheme.primary; // 🔵 藍色
                  break;
                case 'session':
                  shouldShow = showSessionPlans;
                  markerColor = Colors.orange; // 🟠 橘色
                  // debugPrint(
                  //     '[CALENDAR MARKER]   🟠 session 計劃: ${plan['title']}, showSessionPlans=$showSessionPlans');
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

            // ⭐ v3.1-B / v3.9: 教練可上課時段（🟢 綠色）
            // Tab 0：顯示「我的教練們」的可上課時段
            // Tab 1：顯示「我自己」的可上課時段
            final coachSlotsMap = coachSlots;
            if (coachSlotsMap != null) {
              final slots = coachSlotsMap[normalizedDay] ?? [];
              for (var slot in slots) {
                markers.add(CalendarMarker(
                  color: Colors.green, // 🟢 綠色
                  tooltip: isCoachMode ? '我的可上課時段' : '教練可上課',
                  data: {'type': 'coachSlot', 'slot': slot},
                ));
              }
            }

            // ⭐ v3.1.1: Tab 2 - 學員可訓練時段（區分 preferred/available）
            final clientAvailabilityMap = clientAvailability;
            if (isCoachMode && clientAvailabilityMap != null) {
              final slots = clientAvailabilityMap[normalizedDay] ?? [];
              // if (slots.isNotEmpty) {
              //   debugPrint(
              //       '[CALENDAR MARKER] 🟡 $normalizedDay: ${slots.length} 個學員可訓練時段');
              // }
              for (var slot in slots) {
                // ⭐ v3.1.1: 根據 priority 區分顏色
                // preferred = 綠色，available = 橘色
                final isPreferred =
                    slot.priority == AvailabilityPriority.preferred;
                markers.add(CalendarMarker(
                  color: isPreferred ? Colors.green : Colors.orange,
                  tooltip: isPreferred ? '首選時段' : '可訓練時段',
                  data: {'type': 'clientSlot', 'slot': slot},
                ));
              }
            }

            // ⭐ v3.1-B: 排序讓同顏色點點放在一起（藍 → 橙 → 綠 → 黃）
            markers.sort((a, b) {
              int colorOrder(Color c) {
                if (c == colorScheme.primary) return 0; // 藍色
                if (c == Colors.orange) return 1; // 橙色
                if (c == Colors.green) return 2; // 綠色
                if (c == Colors.amber) return 3; // 黃色
                return 4;
              }

              return colorOrder(a.color).compareTo(colorOrder(b.color));
            });

            // if (markers.isNotEmpty) {
            //   final colorSummary = markers.map((m) {
            //     if (m.color == Colors.orange) return '🟠';
            //     if (m.color == Colors.green) return '🟢';
            //     if (m.color == Colors.amber) return '🟡';
            //     return '🔵';
            //   }).join(' ');
            //   debugPrint(
            //       '[CALENDAR MARKER] 📍 $normalizedDay 最終標記: $colorSummary');
            // }
            return markers;
          },
          maxMarkers: 5,
        ),
      ],

      // 交互回調
      onDaySelected: onDaySelected,
      onFormatChanged: onFormatChanged,
      onPageChanged: onPageChanged,

      // 底部：過濾器 + 列表
      bottomSheet: Column(
        children: [
          // 過濾器（只在 Tab 1 顯示）
          if (!isCoachMode)
            BookingFilterChips(
              showSelfPlans: showSelfPlans,
              showTrainerPlans: showTrainerPlans,
              showSessionPlans: showSessionPlans,
              onToggle: onToggleFilter,
            ),

          const Divider(height: 1),

          // 選定日期的數據列表
          Expanded(
            child: _buildDayContent(context),
          ),
        ],
      ),
    );
  }

  /// ⭐ v3.1-B: 構建選定日期的內容
  Widget _buildDayContent(BuildContext context) {
    if (isCoachMode) {
      return _buildCoachTabContent(context);
    } else {
      return _buildMyTabContent(context);
    }
  }

  /// Tab 1「我的」內容
  Widget _buildMyTabContent(BuildContext context) {
    final hasTrainings = selectedDayTrainings.isNotEmpty;
    final coachSlotsList = selectedDayCoachSlots;
    final hasCoachSlots = coachSlotsList != null && coachSlotsList.isNotEmpty;

    if (!hasTrainings && !hasCoachSlots) {
      return _buildEmptyState(context, '今天沒有安排');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 訓練計劃卡片（複用 TrainingPlanCard）
        if (hasTrainings) ...[
          _buildSectionTitle(context, '📚 訓練計劃', selectedDayTrainings.length),
          const SizedBox(height: 8),
          ...selectedDayTrainings.map((training) => _buildTrainingPlanCard(
                context,
                training,
                isCoachView: false,
              )),
        ],

        // 教練可上課時段
        if (hasCoachSlots) ...[
          if (hasTrainings) const SizedBox(height: 16),
          _buildSectionTitle(
              context, '🟢 教練可上課時段', coachSlotsList.length),
          const SizedBox(height: 8),
          ...coachSlotsList.map((slot) => _buildCoachSlotCard(
                context,
                slot,
              )),
        ],
      ],
    );
  }

  /// Tab 2「教練」內容
  Widget _buildCoachTabContent(BuildContext context) {
    final hasTrainings = selectedDayTrainings.isNotEmpty;
    final clientSlotsList = selectedDayClientAvailability;
    final hasClientSlots = clientSlotsList != null && clientSlotsList.isNotEmpty;
    // ⭐ v3.9: 我的可上課時段
    final mySlotsList = selectedDayCoachSlots;
    final hasMySlots = mySlotsList != null && mySlotsList.isNotEmpty;

    if (!hasTrainings && !hasClientSlots && !hasMySlots) {
      return _buildEmptyState(context, '今天沒有課程');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ⭐ v3.9: 我的可上課時段（最上方顯示）
        if (hasMySlots) ...[
          _buildSectionTitle(
              context, '🟢 我的可上課時段', mySlotsList.length),
          const SizedBox(height: 8),
          ...mySlotsList.map((slot) => _buildMySlotCard(
                context,
                slot,
              )),
        ],

        // 我要教的課（複用 TrainingPlanCard）
        if (hasTrainings) ...[
          if (hasMySlots) const SizedBox(height: 16),
          _buildSectionTitle(context, '📚 我的學員訓練', selectedDayTrainings.length),
          const SizedBox(height: 8),
          ...selectedDayTrainings.map((training) => _buildTrainingPlanCard(
                context,
                training,
                isCoachView: true,
              )),
        ],

        // 學員可訓練時段
        if (hasClientSlots) ...[
          if (hasTrainings || hasMySlots) const SizedBox(height: 16),
          _buildSectionTitle(
              context, '🟡 學員可訓練時段', clientSlotsList.length),
          const SizedBox(height: 8),
          ...clientSlotsList.map((slot) => _buildClientSlotCard(
                context,
                slot,
              )),
        ],
      ],
    );
  }

  /// 區塊標題
  Widget _buildSectionTitle(BuildContext context, String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  /// ⭐ v3.1-B: 複用 TrainingPlanCard
  Widget _buildTrainingPlanCard(
    BuildContext context,
    Map<String, dynamic> training, {
    required bool isCoachView,
  }) {
    final appointmentId = training['appointment_id'] as String?;
    final planType = training['planType'] as String? ?? 'self';
    final isSession = planType == 'session';

    // ⭐ v3.1-B: 把 isCoachView 注入到 training 中供 TrainingPlanCard 使用
    final trainingData = Map<String, dynamic>.from(training);
    trainingData['isCoachView'] = isCoachView;

    // ⭐ v3.1.1: 獲取教練/學員名稱
    final traineeId = training['trainee_id'] as String?;
    final creatorId = training['creator_id'] as String?;
    // 教練視角顯示學員名稱，學員視角顯示教練名稱
    final studentName =
        isCoachView && traineeId != null ? clientNames[traineeId] : null;
    final coachDisplayName =
        !isCoachView && creatorId != null ? coachNames[creatorId] : null;

    return TrainingPlanCard(
      training: trainingData,
      currentUserId: currentUserId,
      studentName: studentName, // ⭐ v3.1.1
      coachName: coachDisplayName, // ⭐ v3.1.1
      // ⭐ v3.1-B: 進入 Session Mode
      onEnterSession: isSession && appointmentId != null
          ? (pId, aId) {
              if (onEnterSession != null && aId != null) {
                onEnterSession!(pId, aId);
              }
            }
          : null,
      // 執行訓練
      onExecute: !isSession
          ? (pId) {
              if (onExecuteTraining != null) {
                onExecuteTraining!(pId);
              }
            }
          : null,
      // 編輯
      onEdit: (pId, date) {
        if (onEditTraining != null) {
          onEditTraining!(pId, date);
        }
      },
      // 刪除
      onDelete: (pId, title) {
        if (onDeleteTraining != null) {
          onDeleteTraining!(pId, title);
        }
      },
    );
  }

  /// 教練可上課時段卡片
  Widget _buildCoachSlotCard(
    BuildContext context,
    AvailabilitySlotWithBooking slot,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final startTime = slot.slot.startTime;
    final endTime = slot.slot.endTime;
    final timeStr = '${_formatTime(startTime)} - ${_formatTime(endTime)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.green.withValues(alpha: 0.05),
      child: InkWell(
        onTap: () {
          if (onBookCoachSlot != null) {
            onBookCoachSlot!(slot);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 綠色指示器
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // 時鐘圖標
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.schedule, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              // 內容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coachNames[slot.slot.coachId] ?? '教練',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              // 預約按鈕
              FilledButton(
                onPressed: () {
                  if (onBookCoachSlot != null) {
                    onBookCoachSlot!(slot);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text('預約'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ⭐ v3.9: 我的可上課時段卡片（教練 Tab 用）
  /// 顯示編輯/刪除按鈕
  Widget _buildMySlotCard(
    BuildContext context,
    AvailabilitySlotWithBooking slot,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final startTime = slot.slot.startTime;
    final endTime = slot.slot.endTime;
    final timeStr = '${_formatTime(startTime)} - ${_formatTime(endTime)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.green.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 綠色指示器
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // 時鐘圖標
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.schedule,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // 內容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeStr,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '可接受預約',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            // 編輯按鈕
            IconButton(
              icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
              onPressed:
                  onEditMySlot != null ? () => onEditMySlot!(slot) : null,
              tooltip: '編輯',
              visualDensity: VisualDensity.compact,
            ),
            // 刪除按鈕
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              onPressed:
                  onDeleteMySlot != null ? () => onDeleteMySlot!(slot) : null,
              tooltip: '刪除',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  /// 學員可訓練時段卡片
  /// ⭐ v3.1.1: 根據 priority 區分顏色（preferred=綠色，available=橘色）
  Widget _buildClientSlotCard(
    BuildContext context,
    ClientAvailabilityModel slot,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final startTime = slot.startTime;
    final endTime = slot.endTime;
    final timeStr = '${_formatTime(startTime)} - ${_formatTime(endTime)}';
    // ⭐ v3.1.1: 使用 clientNames 映射獲取學員名稱
    final clientName = clientNames[slot.clientId] ?? '學員';

    // ⭐ v3.1.1: 根據 priority 決定顏色和標籤
    final isPreferred = slot.priority == AvailabilityPriority.preferred;
    final slotColor = isPreferred ? Colors.green : Colors.orange;
    final priorityLabel = isPreferred ? '⭐ 首選' : '可訓練';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: slotColor.withValues(alpha: 0.05),
      child: InkWell(
        onTap: () {
          if (onSelectClientSlot != null) {
            onSelectClientSlot!(slot);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 顏色指示器
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: slotColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // 人物圖標
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: slotColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPreferred ? Icons.star : Icons.schedule,
                  color: slotColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // 內容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          clientName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        // 優先級標籤
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: slotColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            priorityLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: slotColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              // 新增訓練按鈕
              FilledButton.tonal(
                onPressed: () {
                  if (onSelectClientSlot != null) {
                    onSelectClientSlot!(slot);
                  }
                },
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text('新增訓練'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 空狀態
  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// 格式化時間
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
