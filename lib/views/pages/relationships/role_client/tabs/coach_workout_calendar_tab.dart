// ✅ v3.6: MVVM 重構 - 移除 Service 直接調用
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:strengthwise/controllers/coach_management_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_workout_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/models/workout_record/workout_record.dart';
import 'package:strengthwise/views/shared/calendar/calendar_widgets.dart';
import 'package:strengthwise/views/pages/workout/execution/workout_execution_page.dart';

/// 教練訓練行事曆 Tab（學員端）
///
/// 核心功能：
/// 1. 顯示該教練指派的訓練計畫
/// 2. 點擊訓練 → 執行頁面
class CoachWorkoutCalendarTab extends StatefulWidget {
  final String coachId;
  final String clientId;
  final UserModel coach;

  const CoachWorkoutCalendarTab({
    super.key,
    required this.coachId,
    required this.clientId,
    required this.coach,
  });

  @override
  State<CoachWorkoutCalendarTab> createState() =>
      _CoachWorkoutCalendarTabState();
}

class _CoachWorkoutCalendarTabState extends State<CoachWorkoutCalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  // ⭐ v3.6: MVVM 重構 - 透過 Controller
  late final IWorkoutController _workoutController;

  @override
  void initState() {
    super.initState();
    _workoutController = serviceLocator<IWorkoutController>();
    // 初始化時載入當月數據
    _loadMonthData(_focusedDay);
  }

  /// 載入當月數據（帶快取清除）⭐
  Future<void> _loadMonthData(DateTime month, {bool clearCache = false}) async {
    if (clearCache) {
      // ⭐ v3.6: 透過 Controller 清除快取
      _workoutController.clearUserPlansCache(widget.clientId);
    }
    
    final controller = context.read<CoachManagementController>();
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    // 載入該教練指派的訓練計畫（等待完成）
    await controller.loadCoachWorkouts(
      widget.clientId,
      widget.coachId,
      startDate: firstDay,
      endDate: lastDay,
    );
  }

  /// 查看/執行訓練計畫
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
    return Consumer<CoachManagementController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // 提示卡片
            _buildInfoCard(),

            // 統一行事曆組件（包裹 RefreshIndicator）⭐
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadMonthData(_focusedDay, clearCache: true),  // ⭐ 返回 Future
                child: UnifiedCalendar(
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  format: _calendarFormat,
                
                // 標記層：訓練計畫
                layers: [
                  MarkerLayer(
                    markerProvider: (day) {
                      final workouts = controller.getWorkoutsForDate(day);
                      return workouts.map((w) => CalendarMarker(
                        color: w.completed ? Colors.green : Colors.blue,
                        tooltip: w.title,
                        data: w,
                      )).toList();
                    },
                  ),
                ],
                
                // 交互回調
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
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
              ),  // UnifiedCalendar 結束
            ),  // RefreshIndicator 結束
          ),  // Expanded 結束
          ],
        );
      },
    );
  }

  /// 提示卡片
  Widget _buildInfoCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '這裡顯示 ${widget.coach.displayName ?? '教練'} 為您安排的訓練計畫',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: 14,
              ),
            ),
          ),
          // ⭐ 刷新按鈕
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.primary),
            onPressed: () => _loadMonthData(_focusedDay, clearCache: true),  // ⭐ 清除快取
            tooltip: '刷新',
          ),
        ],
      ),
    );
  }

  /// 建立訓練列表
  Widget _buildWorkoutList(CoachManagementController controller) {
    final workouts = controller.getWorkoutsForDate(_selectedDay);

    if (workouts.isEmpty) {
      // ⭐ 修復：使用 Center + SingleChildScrollView 避免溢出
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '該日期無訓練計畫',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
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
        Text(
          '訓練計畫',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...workouts.map((workout) => _buildWorkoutCard(workout)),
      ],
    );
  }

  /// 訓練卡片
  Widget _buildWorkoutCard(WorkoutRecord workout) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: workout.completed
              ? Colors.green
              : colorScheme.primaryContainer,
          child: Icon(
            workout.completed ? Icons.check : Icons.fitness_center,
            color: workout.completed ? Colors.white : colorScheme.primary,
          ),
        ),
        title: Text(
          workout.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${workout.exerciseRecords.length} 個動作 · '
              '${workout.completed ? '已完成' : '待執行'}',
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 14,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '由 ${widget.coach.displayName ?? '教練'} 安排',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _viewWorkout(workout),
      ),
    );
  }
}

