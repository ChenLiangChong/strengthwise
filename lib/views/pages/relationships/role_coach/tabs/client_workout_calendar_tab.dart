import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:strengthwise/controllers/client_management_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/interfaces/i_workout_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/models/workout_record/workout_record.dart';
import 'package:strengthwise/models/client_availability_model.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/shared/calendar/calendar_widgets.dart';
import 'package:strengthwise/views/pages/workout/execution/plan_editor_page.dart';
import 'package:strengthwise/views/pages/workout/execution/workout_execution_page.dart';

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
  late final IAuthController _authController;
  late final IWorkoutService _workoutService; // ⭐ 添加服務
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _authController = serviceLocator<IAuthController>();
    _workoutService = serviceLocator<IWorkoutService>(); // ⭐ 初始化服務

    // 初始化時載入當月數據
    _loadMonthData(_focusedDay);
  }

  /// 載入當月數據
  void _loadMonthData(DateTime month) {
    final controller = context.read<ClientManagementController>();
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    if (kDebugMode) {
      print('[CLIENT_CALENDAR] 載入月份數據: ${month.year}-${month.month}');
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

  /// 創建訓練計畫（直接打開編輯器）⭐
  Future<void> _createWorkoutDirectly(
      DateTime date, ClientAvailabilityModel slot) async {
    final coachId = _authController.user?.uid;
    if (coachId == null) {
      NotificationUtils.showError(context, '無法獲取教練 ID');
      return;
    }

    // ⭐ v2.1: 預檢查時間是否重疊
    try {
      final overlappingWorkouts = await _workoutService.checkTimeOverlap(
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
        print('[CLIENT_WORKOUT_CALENDAR] 檢查時間重疊失敗: $e');
      }
      // 即使檢查失敗，也允許繼續（資料庫會在插入時再次檢查）
    }

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

  /// 查看/編輯訓練計畫
  void _viewWorkout(WorkoutRecord workout) {
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

  @override
  Widget build(BuildContext context) {
    // ⭐ 判斷當前主題模式
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<ClientManagementController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return UnifiedCalendar(
          focusedDay: _focusedDay,
          selectedDay: _selectedDay,
          format: _calendarFormat,

          // 疊加兩層：背景（時間偏好） + 標記（訓練）
          layers: [
            // Layer 1: 背景色（學員時間偏好）⭐
            BackgroundLayer(
              colorProvider: (day) {
                final prefs = controller.getAvailabilityForDate(day);
                
                if (kDebugMode && prefs.isNotEmpty) {
                  print('[CLIENT_CALENDAR] ${day.month}/${day.day} 有 ${prefs.length} 個偏好時段');
                }
                
                if (prefs.isEmpty) return null;

                // ⭐ 根據主題模式使用不同顏色
                if (prefs.any((p) => p.priority == AvailabilityPriority.preferred)) {
                  // 偏好時段：綠色
                  return isDarkMode 
                      ? const Color(0xFF10B981)  // 深色模式：翡翠綠
                      : const Color(0xFF86EFAC); // 淺色模式：更淡的綠色
                } else if (prefs.any((p) => p.priority == AvailabilityPriority.available)) {
                  // 可用時段：橙色
                  return isDarkMode
                      ? const Color(0xFFF97316)  // 深色模式：橙色
                      : const Color(0xFFFBBF24); // 淺色模式：更淡的黃橙色
                } else {
                  // 避免時段：紅色
                  return isDarkMode
                      ? const Color(0xFFEF4444)  // 深色模式：紅色
                      : const Color(0xFFFCA5A5); // 淺色模式：更淡的紅色
                }
              },
              opacity: isDarkMode ? 0.25 : 0.35,  // ⚡ 淺色模式稍微提高透明度
            ),

            // Layer 2: 標記點（訓練計畫）
            MarkerLayer(
              markerProvider: (day) {
                final workouts = controller.getWorkoutsForDate(day);
                return workouts
                    .map((w) => CalendarMarker(
                          color: Colors.blue,
                          tooltip: w.title,
                          data: w,
                        ))
                    .toList();
              },
              maxMarkers: 3,
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
  Widget _buildWorkoutList(ClientManagementController controller) {
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

  /// ⭐ 可用時段卡片（使用 UnifiedSlotCard 統一組件）
  Widget _buildAvailabilitySlotCard(ClientAvailabilityModel slot) {
    final startTime = TimeOfDay.fromDateTime(slot.startTime);
    final endTime = TimeOfDay.fromDateTime(slot.endTime);
    final timeRange = '${startTime.format(context)} - ${endTime.format(context)}';

    Color iconColor;
    IconData icon;
    String label;

    // ⭐ 統一使用明確的色值（與行事曆背景一致）
    switch (slot.priority) {
      case AvailabilityPriority.preferred:
        iconColor = const Color(0xFF10B981);  // 翡翠綠 (Emerald)
        icon = Icons.star;
        label = '偏好時段';
        break;
      case AvailabilityPriority.available:
        iconColor = const Color(0xFFF97316);  // 橙色 (Orange)
        icon = Icons.access_time;
        label = '可用時段';
        break;
      case AvailabilityPriority.avoid:
        iconColor = const Color(0xFFEF4444);  // 紅色 (Red)
        icon = Icons.warning;
        label = '避免時段';
        break;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),  // ⭐ 統一 12dp
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),  // ⭐ 統一 0.2 透明度
          child: Icon(icon, color: iconColor),
        ),
        title: Text(timeRange),  // ⭐ 使用 ListTile 默認樣式
        subtitle: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.add_circle,
          color: iconColor,
          size: 28,
        ),
        onTap: () => _createWorkoutDirectly(_selectedDay, slot),
      ),
    );
  }

  /// 訓練卡片
  Widget _buildWorkoutCard(WorkoutRecord workout) {
    final colorScheme = Theme.of(context).colorScheme;

    // ⭐ v2.1: 格式化時間範圍
    String timeInfo = '';
    if (workout.date.hour != 0 || workout.date.minute != 0) {
      final startTime = '${workout.date.hour.toString().padLeft(2, '0')}:'
          '${workout.date.minute.toString().padLeft(2, '0')}';

      if (workout.trainingEndTime != null) {
        final endTime =
            '${workout.trainingEndTime!.hour.toString().padLeft(2, '0')}:'
            '${workout.trainingEndTime!.minute.toString().padLeft(2, '0')}';
        final duration = workout.trainingEndTime!.difference(workout.date);
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
          '${workout.exerciseRecords.length} 個動作 · '
          '${workout.completed ? '已完成' : '待執行'}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _viewWorkout(workout),
      ),
    );
  }
}
