import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'workout/plan_editor_page.dart';
import 'workout/workout_execution_page.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // 行事曆控制
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // 訓練計畫類型
  final List<String> _planTypes = [
    '力量訓練',
    '有氧訓練',
    '肌肉塑形',
    '核心訓練',
    '全身訓練',
    '恢復訓練'
  ];
  
  String? _selectedPlanType;
  final String _planTitle = '';
  final String _planDescription = '';
  Map<DateTime, List<dynamic>> _events = {};
  List<dynamic> _selectedEvents = [];
  
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadWorkoutPlans();
  }
  
  // 加載訓練計畫數據
  Future<void> _loadWorkoutPlans() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('workoutRecords')
          .where('userId', isEqualTo: userId)
          .get();
      
      final events = <DateTime, List<dynamic>>{};
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final planData = {...data, 'id': doc.id}; // 添加文檔ID到數據中
        final scheduledDate = data['date'] as Timestamp;
        final dateTime = scheduledDate.toDate();
        final key = DateTime(dateTime.year, dateTime.month, dateTime.day);
        
        if (events[key] != null) {
          events[key]!.add(planData);
        } else {
          events[key] = [planData];
        }
      }
      
      setState(() {
        _events = events;
        _updateSelectedEvents();
      });
    } catch (e) {
      print('加載訓練計畫失敗: $e');
    }
  }
  
  // 更新選定日期的事件
  void _updateSelectedEvents() {
    if (_selectedDay != null) {
      final key = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      setState(() {
        _selectedEvents = _events[key] ?? [];
      });
    }
  }
  
  // 刪除訓練計畫
  Future<void> _deleteWorkoutPlan(String planId) async {
    try {
      await FirebaseFirestore.instance
          .collection('workoutRecords')
          .doc(planId)
          .delete();
      
      // 刷新計畫列表
      await _loadWorkoutPlans();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('訓練計畫已刪除')),
      );
    } catch (e) {
      print('刪除訓練計畫失敗: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('刪除失敗，請稍後再試')),
      );
    }
  }
  
  // 編輯訓練計畫
  Future<void> _editWorkoutPlan(String planId) async {
    if (_selectedDay == null) return;
    
    // 检查是否是过去的日期
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    
    if (selectedDate.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('無法編輯過去日期的訓練計畫'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PlanEditorPage(
          selectedDate: _selectedDay!,
          planId: planId,
        ),
      ),
    );
    
    if (result == true) {
      // 重新加載計畫
      await _loadWorkoutPlans();
    }
  }
  
  // 開啟訓練計畫編輯頁面
  Future<void> _navigateToPlanEditor() async {
    if (_selectedDay == null) return;
    
    // 检查是否是过去的日期
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    
    if (selectedDate.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('無法為過去的日期創建訓練計畫'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PlanEditorPage(
          selectedDate: _selectedDay!,
        ),
      ),
    );
    
    if (result == true) {
      // 重新加載計畫
      await _loadWorkoutPlans();
    }
  }
  
  // 查看計畫詳情
  void _viewPlanDetails(dynamic plan) {
    // 不論完成狀態，都進入訓練執行頁面
    _startWorkout(plan['id']);
  }
  
  // 切換計畫完成狀態
  Future<void> _togglePlanCompletion(String planId, bool currentStatus) async {
    try {
      // 獲取計畫數據以檢查日期
      final doc = await FirebaseFirestore.instance
          .collection('workoutRecords')
          .doc(planId)
          .get();
          
      if (!doc.exists) {
        throw Exception('找不到訓練計畫');
      }
      
      final planData = doc.data()!;
      
      // 檢查日期是否為過去或未來日期
      if (planData['date'] != null && planData['date'] is Timestamp) {
        final planTimestamp = planData['date'] as Timestamp;
        final planDate = planTimestamp.toDate();
        
        // 對比今日日期（僅考慮年月日）
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final planDateOnly = DateTime(planDate.year, planDate.month, planDate.day);
        
        if (planDateOnly.isBefore(todayDate)) {
          // 過去的訓練計畫不允許修改
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('無法修改過去的訓練記錄')),
          );
          return;
        }
        
        if (planDateOnly.isAfter(todayDate)) {
          // 未來的訓練計畫不允許修改
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('無法修改未來的訓練記錄，請在訓練當天進行操作')),
          );
          return;
        }
      }
      
      // 繼續更新計畫狀態
      await FirebaseFirestore.instance
          .collection('workoutRecords')
          .doc(planId)
          .update({
        'completed': !currentStatus,
      });
      
      // 刷新計畫列表
      await _loadWorkoutPlans();
    } catch (e) {
      print('更新計畫狀態失敗: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('更新狀態失敗，請稍後再試')),
      );
    }
  }
  
  // 開始執行訓練
  Future<void> _startWorkout(String planId) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutExecutionPage(
          workoutRecordId: planId,
        ),
      ),
    );
    
    if (result == true) {
      // 訓練完成後重新加載計畫
      await _loadWorkoutPlans();
    }
  }
  
  // 構建行事曆
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
          _updateSelectedEvents();
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      eventLoader: (day) {
        final key = DateTime(day.year, day.month, day.day);
        return _events[key] ?? [];
      },
      calendarStyle: const CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
  
  // 構建訓練計畫列表
  Widget _buildWorkoutPlans() {
    if (_selectedEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('這一天沒有訓練計畫'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _navigateToPlanEditor,
                icon: const Icon(Icons.add),
                label: const Text('添加訓練計畫'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedEvents.length,
          itemBuilder: (context, index) {
            final plan = _selectedEvents[index];
            final isCompleted = plan['completed'] ?? false;
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: ListTile(
                title: Text(
                  plan['title'] ?? '未命名計畫',
                  style: TextStyle(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan['description'] ?? '${plan['planType'] ?? "訓練計畫"}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (plan['exercises'] != null) 
                      Text(
                        '動作數量: ${(plan['exercises'] as List?)?.length ?? 0}個',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    // 添加訓練時間顯示
                    if (plan['trainingHour'] != null)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '訓練時間: ${(plan['trainingHour'] as int).toString().padLeft(2, '0')}:00',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 開始訓練按鈕
                    if (!isCompleted)
                      IconButton(
                        icon: const Icon(Icons.play_circle_filled, color: Colors.green),
                        tooltip: '開始訓練',
                        onPressed: () => _startWorkout(plan['id']),
                      ),
                    // 完成狀態切換
                    Builder(
                      builder: (context) {
                        // 判斷是否為過去或未來的日期
                        bool isPastDate = false;
                        bool isFutureDate = false;
                        bool isToday = false;
                        
                        if (plan['date'] != null && plan['date'] is Timestamp) {
                          final planTimestamp = plan['date'] as Timestamp;
                          final planDate = planTimestamp.toDate();
                          
                          // 對比今日日期
                          final today = DateTime.now();
                          final todayDate = DateTime(today.year, today.month, today.day);
                          final planDateOnly = DateTime(planDate.year, planDate.month, planDate.day);
                          
                          isPastDate = planDateOnly.isBefore(todayDate);
                          isFutureDate = planDateOnly.isAfter(todayDate);
                          isToday = planDateOnly.isAtSameMomentAs(todayDate);
                        }
                        
                        final canModify = isToday && !isPastDate && !isFutureDate;
                        
                        return IconButton(
                          icon: Icon(
                            isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                            color: isCompleted 
                              ? Colors.green 
                              : (isPastDate || isFutureDate ? Colors.grey.shade400 : Colors.grey),
                          ),
                          tooltip: isPastDate 
                              ? '無法修改過去的訓練' 
                              : (isFutureDate
                                  ? '無法修改未來的訓練'
                                  : (isCompleted ? '標記為未完成' : '標記為完成')),
                          onPressed: (isPastDate || isFutureDate) ? () {
                            String message = isPastDate 
                                ? '無法修改過去的訓練記錄' 
                                : '無法修改未來的訓練記錄，請在訓練當天進行操作';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          } : () => _togglePlanCompletion(plan['id'], isCompleted),
                        );
                      },
                    ),
                    // 編輯按鈕
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: '查看/編輯',
                      onPressed: () => _editWorkoutPlan(plan['id']),
                    ),
                    // 刪除按鈕
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: '刪除',
                      onPressed: () => _deleteWorkoutPlan(plan['id']),
                    ),
                  ],
                ),
                onTap: () => _viewPlanDetails(plan),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _navigateToPlanEditor,
            icon: const Icon(Icons.add),
            label: const Text('添加訓練計畫'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訓練行事曆'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '選擇日期',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildCalendar(),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    _selectedDay != null 
                        ? '${DateFormat('yyyy年MM月dd日').format(_selectedDay!)} 訓練計畫' 
                        : '訓練計畫',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedDay != null && DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)
                      .isAfter(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).subtract(const Duration(days: 1))))
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green, size: 28),
                      onPressed: _navigateToPlanEditor,
                    ),
                ],
              ),
            ),
            _buildWorkoutPlans(),
            const SizedBox(height: 30),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToPlanEditor,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
} 