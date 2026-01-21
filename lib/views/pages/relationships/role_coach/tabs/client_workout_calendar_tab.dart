// ✅ v3.6: MVVM 重構 - 移除 Service 直接調用
// ✅ v3.9: Realtime + EventBus 訂閱（學員可訓練時間跨用戶更新）
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:strengthwise/controllers/interfaces/i_client_management_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_workout_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_realtime_controller.dart'; // ⭐ v3.9
import 'package:strengthwise/controllers/interfaces/i_event_bus_controller.dart'; // ⭐ v3.9
import 'package:strengthwise/services/core/app_event_bus.dart'; // ⭐ v3.9
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/models/workout_record/workout_record.dart';
import 'package:strengthwise/models/client_availability_model.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/shared/calendar/calendar_widgets.dart';
import 'package:strengthwise/views/pages/workout/execution/plan_editor_page.dart';
import 'package:strengthwise/views/pages/workout/execution/workout_execution_page.dart';
import 'package:strengthwise/views/pages/session/session_mode_page.dart'; // ⭐ v3.1: Session Mode

/// 學員訓練行事曆 Tab（教練端）
///
/// 核心功能：
/// 1. 顯示學員時間偏好（背景色）
/// 2. 顯示訓練計畫
/// 3. 點擊日期創建訓練
class ClientWorkoutCalendarTab extends StatefulWidget {
  final String clientId;
  final UserModel client;

  const ClientWorkoutCalendarTab({
    super.key,
    required this.clientId,
    required this.client,
  });

  @override
  State<ClientWorkoutCalendarTab> createState() =>
      _ClientWorkoutCalendarTabState();
}

class _ClientWorkoutCalendarTabState extends State<ClientWorkoutCalendarTab> {
  // ⭐ v3.6: MVVM 重構 - 全部透過 Controller
  late final IAuthController _authController;
  late final IWorkoutController _workoutController;
  late final IRealtimeController _realtimeController; // ⭐ v3.9
  
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // ⭐ v3.9: Realtime 訂閱 ID
  String? _realtimeSubscriptionId;
  
  // ⭐ v3.9: EventBus 訂閱（DELETE 事件）
  late final IEventBusController _eventBusController;
  StreamSubscription<AppEvent>? _availabilitySubscription;

  @override
  void initState() {
    super.initState();
    _authController = serviceLocator<IAuthController>();
    _workoutController = serviceLocator<IWorkoutController>();
    _realtimeController = serviceLocator<IRealtimeController>(); // ⭐ v3.9
    _eventBusController = serviceLocator<IEventBusController>(); // ⭐ v3.9

    // 初始化時載入當月數據
    _loadMonthData(_focusedDay);
    
    // ⭐ v3.9: 訂閱學員可訓練時間變更（Realtime + EventBus）
    _realtimeSubscriptionId = _realtimeController.subscribeToClientAvailability(
      clientId: widget.clientId,
      onUpdate: _onRealtimeUpdate,
    );
    _availabilitySubscription = _eventBusController.availabilityEvents.listen(_onAvailabilityEvent);
  }
  
  /// ⭐ v3.9: Realtime 更新回調（INSERT/UPDATE 事件）
  void _onRealtimeUpdate() {
    if (!mounted) return;
    if (kDebugMode) {
      debugPrint('[ClientCalendarTab] ⚡ Realtime INSERT/UPDATE: 學員偏好更新');
    }
    _loadMonthData(_focusedDay);
  }
  
  /// ⭐ v3.9: EventBus 時段事件回調（DELETE 事件 - 增量刪除）
  void _onAvailabilityEvent(AppEvent event) {
    if (!mounted) return;
    
    if (event.type == AppEventType.clientAvailabilityDeleted) {
      final deletedId = event.entityId;
      if (deletedId != null && event.userId == widget.clientId) {
        if (kDebugMode) {
          debugPrint('[ClientCalendarTab] ⚡ EventBus DELETE: 學員偏好刪除 id=$deletedId');
        }
        // ⭐ v3.9: 增量刪除，不需要全量刷新
        final controller = context.read<IClientManagementController>();
        controller.removeClientAvailabilityById(deletedId);
      }
    }
  }

  /// 載入當月數據
  void _loadMonthData(DateTime month) {
    final controller = context.read<IClientManagementController>();
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    if (kDebugMode) {
      debugPrint('[CLIENT_CALENDAR] 載入月份數據: ${month.year}-${month.month}');
    }

    // 載入訓練計畫和時間偏好
    controller.loadClientWorkouts(
      widget.clientId,
      startDate: firstDay,
      endDate: lastDay,
    );
    controller.loadClientAvailability(
      widget.clientId,
      startDate: firstDay,
      endDate: lastDay,
    );
  }

  @override
  void dispose() {
    // ⭐ v3.9: 取消訂閱
    final subscriptionId = _realtimeSubscriptionId;
    if (subscriptionId != null) {
      _realtimeController.unsubscribe(subscriptionId);
    }
    _availabilitySubscription?.cancel();
    super.dispose();
  }

  /// 創建訓練計畫（直接打開編輯器）⭐
  Future<void> _createWorkoutDirectly(
      DateTime date, ClientAvailabilityModel slot) async {
    final coachId = _authController.user?.uid;
    if (coachId == null) {
      NotificationUtils.showError(context, '無法獲取教練 ID');
      return;
    }

    // ⭐ v2.1: 預檢查時間是否重疊
    // ⭐ v3.6: 透過 Controller 操作
    try {
      final overlappingWorkouts = await _workoutController.checkTimeOverlap(
        traineeId: widget.clientId,
        startTime: slot.startTime,
        endTime: slot.endTime,
      );

      if (overlappingWorkouts.isNotEmpty && mounted) {
        // 顯示警告對話框
        final shouldContinue = await showDialog<bool>(
          context: context,
          barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
          builder: (context) => AlertDialog(
            title: const Text('時間衝突'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('該時段已有以下訓練計畫：'),
                const SizedBox(height: 12),
                ...overlappingWorkouts.map((workout) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '• ${workout.title}\n  ${TimeOfDay.fromDateTime(workout.trainingTime!).format(context)} - '
                        '${TimeOfDay.fromDateTime(workout.trainingEndTime ?? workout.trainingTime!.add(const Duration(hours: 1))).format(context)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    )),
                const SizedBox(height: 12),
                const Text(
                  '請選擇其他時段',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('確定'),
              ),
            ],
          ),
        );

        if (shouldContinue != true) return;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CLIENT_WORKOUT_CALENDAR] 檢查時間重疊失敗: $e');
      }
      // 即使檢查失敗，也允許繼續（資料庫會在插入時再次檢查）
    }

    if (!mounted) return;

    // 直接導航到訓練編輯頁面
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanEditorPage(
          selectedDate: date,
          planType: 'trainer',
          traineeId: widget.clientId, // ⭐ 指派給學員
          initialStartTime: slot.startTime, // ⭐ 已經是本地時間（Model 已轉換）
          initialEndTime: slot.endTime, // ⭐ 已經是本地時間（Model 已轉換）
        ),
      ),
    );

    if (result == true && mounted) {
      NotificationUtils.showSuccess(context, '訓練計畫已創建');
      // 重新載入數據
      _loadMonthData(_focusedDay);
    } else if (result is String && mounted) {
      // ⭐ v2.1: 處理創建失敗（時間重疊錯誤）
      if (result.contains('訓練時間重疊')) {
        NotificationUtils.showError(context, result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<IClientManagementController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return UnifiedCalendar(
          focusedDay: _focusedDay,
          selectedDay: _selectedDay,
          format: _calendarFormat,

          // ⭐ v3.1.1: 改用點點標記（與 booking page 一致）
          layers: [
            // 標記點（訓練計畫 + 學員偏好時段）
            MarkerLayer(
              markerProvider: (day) {
                final markers = <CalendarMarker>[];

                // 訓練計畫（🔵 藍色）
                final workouts = controller.getWorkoutsForDate(day);
                for (var w in workouts) {
                  markers.add(CalendarMarker(
                    color: colorScheme.primary,
                    tooltip: w.title,
                    data: {'type': 'workout', 'workout': w},
                  ));
                }

                // 學員偏好時段（🟢 綠色 = 首選，🟠 橘色 = 可訓練）
                final prefs = controller.getAvailabilityForDate(day);
                for (var p in prefs) {
                  final isPreferred =
                      p.priority == AvailabilityPriority.preferred;
                  markers.add(CalendarMarker(
                    color: isPreferred ? Colors.green : Colors.orange,
                    tooltip: isPreferred ? '首選時段' : '可訓練時段',
                    data: {'type': 'availability', 'slot': p},
                  ));
                }

                // 排序：藍 → 綠 → 橘
                markers.sort((a, b) {
                  int colorOrder(Color c) {
                    if (c == colorScheme.primary) return 0;
                    if (c == Colors.green) return 1;
                    if (c == Colors.orange) return 2;
                    return 3;
                  }

                  return colorOrder(a.color).compareTo(colorOrder(b.color));
                });

                return markers;
              },
              maxMarkers: 5,
            ),
          ],

          // 交互回調
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });

            // ⭐ 移除自動彈窗：只更新選中日期，不觸發任何操作
            // 新增訓練的唯一入口：底部「學員偏好時段」卡片的 + 按鈕
          },

          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },

          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
            _loadMonthData(focusedDay);
          },

          // 底部訓練列表
          bottomSheet: _buildWorkoutList(controller),
        );
      },
    );
  }

  /// 建立訓練列表
  Widget _buildWorkoutList(IClientManagementController controller) {
    final workouts = controller.getWorkoutsForDate(_selectedDay);
    final availability = controller.getAvailabilityForDate(_selectedDay);

    if (workouts.isEmpty && availability.isEmpty) {
      // ⭐ 沒有訓練也沒有偏好時段
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '學員未設定此日期的偏好時段',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '請聯絡學員設定可訓練時間',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 已有的訓練計畫
        if (workouts.isNotEmpty) ...[
          Text(
            '訓練計畫',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...workouts.map((workout) => _buildWorkoutCard(workout)),
          const SizedBox(height: 16),
        ],

        // ⭐ 可用時段（顯示所有，讓教練知道還有哪些時段可以安排）
        if (availability.isNotEmpty) ...[
          Text(
            '學員偏好時段',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...availability.map((slot) => _buildAvailabilitySlotCard(slot)),
        ],
      ],
    );
  }

  /// ⭐ v3.1.1: 可用時段卡片（與 booking page 統一風格）
  Widget _buildAvailabilitySlotCard(ClientAvailabilityModel slot) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeStr =
        '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}';

    // 根據 priority 決定顏色和標籤
    final isPreferred = slot.priority == AvailabilityPriority.preferred;
    final slotColor = isPreferred ? Colors.green : Colors.orange;
    final priorityLabel = isPreferred ? '⭐ 首選' : '可訓練';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: slotColor.withValues(alpha: 0.05),
      child: InkWell(
        onTap: () => _createWorkoutDirectly(_selectedDay, slot),
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
              // 圖標
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
                          timeStr,
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
                    Builder(builder: (context) {
                      final notes = slot.notes;
                      if (notes != null && notes.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              notes,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
              // 新增訓練按鈕
              FilledButton.tonal(
                onPressed: () => _createWorkoutDirectly(_selectedDay, slot),
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

  /// 格式化時間
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// 訓練卡片
  /// ⭐ v2.9.1: 添加編輯/刪除功能
  Widget _buildWorkoutCard(WorkoutRecord workout) {
    final colorScheme = Theme.of(context).colorScheme;
    final authController = serviceLocator<IAuthController>();
    final currentUserId = authController.user?.uid;

    // ⭐ 判斷是否可以刪除（只有創建者可以刪除，且不能是過去的訓練）
    final isPast =
        workout.date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    final isCreator = workout.creatorId == currentUserId;
    final canDelete = isCreator && !isPast;

    // ⭐ v2.1: 格式化時間範圍
    String timeInfo = '';
    if (workout.date.hour != 0 || workout.date.minute != 0) {
      final startTime = '${workout.date.hour.toString().padLeft(2, '0')}:'
          '${workout.date.minute.toString().padLeft(2, '0')}';

      final trainingEndTime = workout.trainingEndTime;
      if (trainingEndTime != null) {
        final endTime =
            '${trainingEndTime.hour.toString().padLeft(2, '0')}:'
            '${trainingEndTime.minute.toString().padLeft(2, '0')}';
        final duration = trainingEndTime.difference(workout.date);
        final hours = duration.inHours;
        final minutes = duration.inMinutes % 60;

        String durationStr = '';
        if (hours > 0) {
          durationStr = '$hours 小時';
          if (minutes > 0) {
            durationStr += ' $minutes 分鐘';
          }
        } else {
          durationStr = '$minutes 分鐘';
        }

        timeInfo = '$startTime - $endTime ($durationStr) · ';
      } else {
        timeInfo = '$startTime · ';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              workout.completed ? Colors.green : colorScheme.primaryContainer,
          child: Icon(
            workout.completed ? Icons.check : Icons.fitness_center,
            color: workout.completed ? Colors.white : colorScheme.primary,
          ),
        ),
        title: Text(
          workout.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$timeInfo' // ⭐ v2.1: 顯示時間範圍
          '${workout.appointmentId != null ? '教練課程 · ' : ''}' // ⭐ v3.1: 顯示課程類型
          '${workout.exerciseRecords.length} 個動作 · '
          '${workout.completed ? '已完成' : '待執行'}',
        ),
        // ⭐ v2.9.1: 刪除按鈕（只有創建者可見）
        trailing: canDelete
            ? IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error.withValues(alpha: 0.7),
                ),
                onPressed: () => _confirmDeleteWorkout(workout),
                tooltip: '刪除訓練',
              )
            : null,
        onTap: () => _viewWorkout(workout),
      ),
    );
  }

  /// ⭐ v2.9.1: 確認刪除訓練
  void _confirmDeleteWorkout(WorkoutRecord workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除訓練'),
        content: Text('確定要刪除「${workout.title}」嗎？此操作不能撤銷。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteWorkout(workout);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  /// ⭐ v2.9.1: 執行刪除訓練
  /// ⭐ v3.5: MVVM 重構 - 透過 Controller 操作，事件由 Controller 自動發布
  Future<void> _deleteWorkout(WorkoutRecord workout) async {
    try {
      // ⭐ v3.5: 透過 Controller 刪除訓練記錄（Controller 會自動發布事件）
      final success = await _workoutController.deleteRecord(workout.id);

      if (!success) {
        throw Exception(_workoutController.errorMessage ?? '刪除失敗');
      }

      if (mounted) {
        NotificationUtils.showSuccess(context, '訓練計畫已刪除');
        // 重新載入數據
        _loadMonthData(_focusedDay);
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(context, '刪除失敗: $e');
      }
    }
  }

  /// 查看/編輯訓練計畫
  void _viewWorkout(WorkoutRecord workout) {
    if (workout.appointmentId != null) {
      // ⭐ v3.1: 如果是課程，跳轉到 Session Mode
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionModePage(
            appointmentId: workout.appointmentId!,
            clientId: widget.clientId,
            clientName: widget.client.displayName ?? widget.client.email,
            sessionStartTime: workout.trainingTime ?? workout.date,
            sessionEndTime: workout.trainingEndTime ??
                workout.date.add(const Duration(hours: 1)),
            workoutPlanId: workout.workoutPlanId,
            isCoachMode: true,
          ),
        ),
      ).then((_) {
        // 返回時重新載入數據
        _loadMonthData(_focusedDay);
      });
    } else {
      // 一般訓練：跳轉到執行頁面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutExecutionPage(
            workoutRecordId: workout.id,
          ),
        ),
      ).then((_) {
        // 返回時重新載入數據
        _loadMonthData(_focusedDay);
      });
    }
  }
}
