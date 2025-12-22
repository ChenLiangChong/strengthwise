import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'workout/plan_editor_page.dart';
import 'workout/workout_execution_page.dart';
import '../../controllers/interfaces/i_booking_controller.dart';
import '../../controllers/booking_controller.dart';
import '../../services/error_handling_service.dart';
import '../../services/service_locator.dart';

class BookingPage extends StatefulWidget {
  // 允許外部注入控制器，實現依賴注入
  final IBookingController? controller;
  
  const BookingPage({
    super.key,
    this.controller,
  });

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> with SingleTickerProviderStateMixin {
  late final IBookingController _controller;
  final ErrorHandlingService _errorService = serviceLocator<ErrorHandlingService>();
  
  late TabController _tabController;
  
  List<Map<String, dynamic>> _userBookings = [];
  List<Map<String, dynamic>> _coachBookings = [];
  bool _isLoading = true;
  bool _isCoachMode = false;
  bool _isInitialized = false;
  
  // 行事曆相關變數
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // 訓練計劃相關變數
  Map<DateTime, List<Map<String, dynamic>>> _trainings = {};
  List<Map<String, dynamic>> _selectedDayTrainings = [];
  
  // 預約相關變數
  Map<DateTime, List<Map<String, dynamic>>> _bookings = {};
  List<Map<String, dynamic>> _selectedDayBookings = [];
  
  // 訓練計劃過濾
  bool _showSelfPlans = true;  // 顯示自主訓練計劃
  bool _showTrainerPlans = true;  // 顯示教練創建的計劃
  bool _showBookings = true;  // 顯示預約

  @override
  void initState() {
    super.initState();
    
    // 使用注入的控制器或創建新的控制器
    _controller = widget.controller ?? BookingController();
    
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // 確保控制器已初始化後再載入數據
    _safeInitialize();
    
    // 載入訓練計劃數據
    _loadTrainingPlans();
  }
  
  Future<void> _safeInitialize() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 添加更堅固的超時保護
      bool initializationComplete = false;
      
      // 等待控制器初始化，但設置絕對超時
      if (_controller is BookingController) {
        try {
          await Future.any<void>([
            (_controller as BookingController).initialized.then((_) {
              initializationComplete = true;
            }),
            Future.delayed(const Duration(seconds: 8), () {
              if (!initializationComplete) {
                print('[BOOKING PAGE] 控制器初始化超時(8秒)，強制繼續');
              }
            })
          ]);
        } catch (e) {
          print('[BOOKING PAGE] 等待控制器初始化時發生錯誤: $e');
          // 繼續執行，不要中斷界面顯示
        }
      }
      
      // 無論控制器是否完全初始化，都標記為已初始化並嘗試加載數據
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        
        // 嘗試載入預約數據，但使用 try-catch 確保即使載入失敗也不會阻止界面顯示
        try {
          _loadBookings();
        } catch (e) {
          print('[BOOKING PAGE] 初始加載預約失敗: $e');
          // 顯示空列表
          setState(() {
            _userBookings = [];
            _coachBookings = [];
          });
        }
      }
    } catch (e) {
      // 確保界面總是顯示，即使初始化完全失敗
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = true; // 即使失敗也設為已初始化，避免卡住界面
          _userBookings = [];
          _coachBookings = [];
        });
        
        // 嘗試顯示錯誤，但不讓它阻止界面顯示
        try {
          _errorService.handleError(
            context, 
            '預約系統無法正常啟動: ${e.toString()}', 
            customMessage: '初始化失敗',
          );
        } catch (_) {
          // 即使錯誤處理失敗也繼續顯示界面
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('預約系統初始化失敗'))
          );
        }
      }
    }
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _isCoachMode = _tabController.index == 1;
      });
      if (_isInitialized) {
        _loadBookings();
        _loadTrainingPlans();
      }
    }
  }
  
  Future<void> _loadBookings() async {
    if (!mounted || !_isInitialized) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      List<Map<String, dynamic>> bookings;
      
      if (_isCoachMode) {
        bookings = await _controller.loadCoachBookings();
      } else {
        bookings = await _controller.loadUserBookings();
      }
      
      if (!mounted) return;
      
      // 將預約按日期分組
      final bookingsByDate = <DateTime, List<Map<String, dynamic>>>{};
      
      for (var booking in bookings) {
        final dateTime = booking['dateTime'];
        if (dateTime != null && dateTime is Timestamp) {
          final date = dateTime.toDate();
          final day = DateTime(date.year, date.month, date.day);
          
          if (bookingsByDate[day] == null) {
            bookingsByDate[day] = [];
          }
          
          bookingsByDate[day]!.add(booking);
        }
      }
      
      setState(() {
        if (_isCoachMode) {
          _coachBookings = bookings;
        } else {
          _userBookings = bookings;
        }
        _bookings = bookingsByDate;
        _updateSelectedDayData();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      _errorService.handleLoadingError(context, e);
    }
  }
  
  // 載入訓練計劃數據，根據新的集合結構
  Future<void> _loadTrainingPlans() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // 獲取所有該用戶的訓練計劃（包括自主計劃和教練分配的計劃）
      final snapshot = await FirebaseFirestore.instance
          .collection('workoutPlans')
          .where('traineeId', isEqualTo: userId) // 查詢指派給該用戶的計劃
          .get();
      
      final trainings = <DateTime, List<Map<String, dynamic>>>{};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['dataType'] = 'plan'; // 標記數據類型為訓練計劃
        
        // 使用 scheduledDate 替代舊的 date 字段
        if (data['scheduledDate'] is Timestamp) {
          final timestamp = data['scheduledDate'] as Timestamp;
          final date = timestamp.toDate();
          final day = DateTime(date.year, date.month, date.day);
          
          if (trainings[day] == null) {
            trainings[day] = [];
          }
          
          trainings[day]!.add(data);
        }
      }
      
      // 再獲取當前用戶作為教練創建的訓練計劃
      if (_isCoachMode) {
        final coachSnapshot = await FirebaseFirestore.instance
            .collection('workoutPlans')
            .where('creatorId', isEqualTo: userId) // 查詢用戶作為教練創建的計劃
            .where('planType', isEqualTo: 'trainer') // 只獲取教練創建的計劃
            .get();
            
        for (var doc in coachSnapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          data['isCoachView'] = true; // 標記該計劃是以教練身份查看
          data['dataType'] = 'plan'; // 標記數據類型為訓練計劃
          
          if (data['scheduledDate'] is Timestamp) {
            final timestamp = data['scheduledDate'] as Timestamp;
            final date = timestamp.toDate();
            final day = DateTime(date.year, date.month, date.day);
            
            if (trainings[day] == null) {
              trainings[day] = [];
            }
            
            // 避免重複添加（如果該計劃已經在第一個查詢中加入）
            if (!trainings[day]!.any((plan) => plan['id'] == doc.id)) {
              trainings[day]!.add(data);
            }
          }
        }
      }
      
      if (!mounted) return;
      
      setState(() {
        _trainings = trainings;
        _updateSelectedDayData();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      print('[BOOKING PAGE] 載入訓練計劃失敗: $e');
    }
  }
  
  
  // 更新選定日期的數據
  void _updateSelectedDayData() {
    final selectedDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    
    // 獲取所有選定日期的訓練計劃
    final allTrainings = _trainings[selectedDay] ?? [];
    
    // 應用訓練計劃過濾器
    _selectedDayTrainings = allTrainings.where((training) {
      final planType = training['planType'] as String? ?? '';
      
      if (planType == 'self' && !_showSelfPlans) {
        return false;
      }
      
      if (planType == 'trainer' && !_showTrainerPlans) {
        return false;
      }
      
      return true;
    }).toList();
    
    // 獲取選定日期的預約
    _selectedDayBookings = _showBookings 
        ? (_bookings[selectedDay] ?? [])
        : [];
  }
  
  // 切換過濾器
  void _toggleFilter(String filterType) {
    setState(() {
      switch (filterType) {
        case 'self':
          _showSelfPlans = !_showSelfPlans;
          break;
        case 'trainer':
          _showTrainerPlans = !_showTrainerPlans;
          break;
        case 'bookings':
          _showBookings = !_showBookings;
          break;
      }
      _updateSelectedDayData();
    });
  }
  
  Future<void> _createBooking() async {
    // TODO: 實現創建預約的邏輯
  }
  
  Future<void> _cancelBooking(String bookingId) async {
    try {
      final success = await _controller.cancelBooking(bookingId);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('預約已取消')),
        );
        _loadBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('取消預約失敗')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      _errorService.handleError(context, e, customMessage: '取消預約失敗');
    }
  }
  
  Future<void> _confirmBooking(String bookingId) async {
    try {
      final success = await _controller.confirmBooking(bookingId);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('預約已確認')),
        );
        _loadBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('確認預約失敗')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      _errorService.handleError(context, e, customMessage: '確認預約失敗');
    }
  }
  
  // 創建新的訓練計劃
  Future<void> _createTrainingPlan() async {
    if (!mounted) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanEditorPage(
          selectedDate: _selectedDay,
          planType: _isCoachMode ? 'trainer' : 'self', // 根據當前模式設置計劃類型
        ),
      ),
    );
    
    if (result == true) {
      // 如果成功創建了計劃，重新載入數據
      _loadTrainingPlans();
    }
  }
  
  // 執行訓練計劃
  Future<void> _executeTrainingPlan(String planId) async {
    if (!mounted) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutExecutionPage(
          workoutRecordId: planId,
        ),
      ),
    );
    
    if (result == true) {
      // 如果訓練計劃有更新，重新載入數據
      _loadTrainingPlans();
    }
  }
  
  // 刪除訓練計畫
  Future<void> _deleteTrainingPlan(String planId, String planTitle) async {
    if (!mounted) return;
    
    // 顯示確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除訓練計畫'),
        content: Text('確定要刪除「$planTitle」嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    
    if (confirmed != true || !mounted) return;
    
    try {
      // 刪除 workoutPlans 集合中的訓練計畫
      await FirebaseFirestore.instance
          .collection('workoutPlans')
          .doc(planId)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('訓練計畫已刪除')),
        );
        
        // 重新加載訓練計畫
        _loadTrainingPlans();
      }
    } catch (e) {
      print('[BOOKING PAGE] 刪除訓練計畫失敗: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刪除失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('行事曆'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '我的行事曆'),
            Tab(text: '教練模式'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 學生模式 - 行事曆視圖
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildCalendarView(isCoachMode: false),
          
          // 教練模式 - 行事曆視圖
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildCalendarView(isCoachMode: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isCoachMode ? null : _createTrainingPlan,
        tooltip: '創建訓練計劃',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  // 構建行事曆視圖
  Widget _buildCalendarView({required bool isCoachMode}) {
    return Column(
      children: [
        // 行事曆部分
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          eventLoader: (day) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            
            // 合併該日的所有數據：訓練計劃、訓練記錄和預約
            final allEvents = <Map<String, dynamic>>[];
            
            // 添加訓練計劃
            if (_showSelfPlans || _showTrainerPlans) {
              final plans = _trainings[normalizedDay] ?? [];
              for (var plan in plans) {
                final planType = plan['planType'] as String? ?? '';
                if ((planType == 'self' && _showSelfPlans) || 
                    (planType == 'trainer' && _showTrainerPlans)) {
                  allEvents.add(plan);
                }
              }
            }
            
            
            // 添加預約
            if (_showBookings) {
              final bookings = _bookings[normalizedDay] ?? [];
              allEvents.addAll(bookings);
            }
            
            return allEvents;
          },
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _updateSelectedDayData();
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
          calendarStyle: CalendarStyle(
            markersMaxCount: 4,
            markerDecoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.green.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        const Divider(height: 1),
        
        // 過濾器
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Text('過濾：', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('自主訓練'),
                selected: _showSelfPlans,
                onSelected: (_) => _toggleFilter('self'),
                selectedColor: Colors.green.withOpacity(0.2),
                checkmarkColor: Colors.green,
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('教練計劃'),
                selected: _showTrainerPlans,
                onSelected: (_) => _toggleFilter('trainer'),
                selectedColor: Colors.blue.withOpacity(0.2),
                checkmarkColor: Colors.blue,
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('預約'),
                selected: _showBookings,
                onSelected: (_) => _toggleFilter('bookings'),
                selectedColor: Colors.orange.withOpacity(0.2),
                checkmarkColor: Colors.orange,
              ),
            ],
          ),
        ),
        
        // 選定日期的數據列表
        Expanded(
          child: _buildSelectedDayList(isCoachMode),
        ),
      ],
    );
  }
  
  // 構建選定日期的列表，包含訓練計劃和預約
  Widget _buildSelectedDayList(bool isCoachMode) {
    // 合併所有選定日期的數據
    final List<Map<String, dynamic>> allItems = [];
    
    // 添加訓練計劃（已統一，不再需要單獨的訓練記錄）
    allItems.addAll(_selectedDayTrainings);
    
    // 添加預約
    allItems.addAll(_selectedDayBookings);
    
    if (allItems.isEmpty) {
      return _buildEmptyState(
        '今日沒有活動',
        '點擊右下角按鈕創建訓練計劃',
        Icons.calendar_today,
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        
        // 根據數據類型構建不同的卡片
        if (item.containsKey('status')) { // 預約有status字段
          return _buildBookingCard(item, isUserMode: !isCoachMode);
        } else {
          return _buildTrainingCard(item);
        }
      },
    );
  }
  
  // 構建訓練記錄卡片
  Widget _buildWorkoutRecordCard(Map<String, dynamic> record) {
    final title = record['title'] ?? '未命名訓練';
    final exercises = record['exercises'] as List<dynamic>? ?? [];
    final completed = record['completed'] as bool? ?? false;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: InkWell(
        onTap: () {
          // 點擊查看訓練記錄詳情
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutExecutionPage(
                workoutRecordId: record['id'],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '已完成訓練',
                      style: TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  // 刪除按鈕
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red,
                    onPressed: () => _deleteTrainingPlan(record['id'], title),
                    tooltip: '刪除訓練記錄',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.fitness_center, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${exercises.length} 個動作',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  // 點擊查看訓練記錄詳情
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutExecutionPage(
                        workoutRecordId: record['id'],
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple,
                ),
                child: const Text('查看訓練記錄'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 構建訓練計劃卡片，根據新集合結構
  Widget _buildTrainingCard(Map<String, dynamic> training) {
    final title = training['title'] ?? '未命名訓練';
    final description = training['description'] ?? '';
    final planType = training['planType'] as String? ?? 'self';
    final exercises = training['exercises'] as List<dynamic>? ?? [];
    final completed = training['completed'] as bool? ?? false;
    final isCoachView = training['isCoachView'] as bool? ?? false;
    
    // 顯示計劃是由誰創建的信息（僅對教練計劃顯示）
    final traineeId = training['traineeId'] as String?;
    final creatorId = training['creatorId'] as String?;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    String timeInfo = '全天';
    if (training['scheduledDate'] != null) {
      final timestamp = training['scheduledDate'] as Timestamp;
      final time = timestamp.toDate();
      
      // 只顯示時間部分，如果有
      if (time.hour != 0 || time.minute != 0) {
        timeInfo = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
    }
    
    // 根據完成狀態和計劃類型設置顏色和文字
    Color typeColor;
    String typeText;
    
    if (completed) {
      // 已完成的訓練顯示紫色「已完成」標籤
      typeColor = Colors.purple;
      typeText = '已完成';
    } else {
      // 未完成的訓練根據類型顯示
      typeColor = planType == 'self' ? Colors.green : Colors.blue;
      typeText = planType == 'self' ? '自主訓練' : '教練計劃';
    }
    
    // 計算進度
    int totalExercises = exercises.length;
    int completedExercises = exercises.where((e) => e['completed'] == true).length;
    double progress = totalExercises > 0 ? completedExercises / totalExercises : 0.0;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: InkWell(
        onTap: () => _executeTrainingPlan(training['id']),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      typeText,
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  // 刪除按鈕
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red,
                    onPressed: () => _deleteTrainingPlan(training['id'], title),
                    tooltip: '刪除訓練計畫',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    timeInfo,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.fitness_center, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${exercises.length} 個動作',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              
              // 顯示教練/學員信息（如果是教練計劃）
              if (planType == 'trainer' && !isCoachView && userId == traineeId) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '教練安排的計劃',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
              
              // 如果是教練查看學員的計劃
              if (isCoachView && userId == creatorId) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '已分配給學員',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
              
              // 進度條
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(
                  completed ? Colors.green : Colors.orange,
                ),
              ),
              
              // 顯示完成狀態
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    completed ? '已完成' : '進行中: $completedExercises/$totalExercises',
                    style: TextStyle(
                      color: completed ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _executeTrainingPlan(training['id']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: typeColor,
                    ),
                    child: Text(completed ? '查看訓練' : '開始訓練'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildBookingCard(Map<String, dynamic> booking, {required bool isUserMode}) {
    final bookingId = booking['id'] ?? '';
    final status = booking['status'] ?? 'pending';
    final dateTime = booking['dateTime'];
    final coachName = booking['coachName'] ?? '未知教練';
    final userName = booking['userName'] ?? '未知用戶';
    final course = booking['course'] ?? '個人訓練';
    
    // 格式化日期時間
    String formattedDateTime = '未知時間';
    if (dateTime != null) {
      final date = dateTime.toDate();
      formattedDateTime = '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    
    // 狀態顏色
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusText = '已確認';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = '已取消';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = '已完成';
        break;
      default:
        statusColor = Colors.orange;
        statusText = '待確認';
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    course,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  formattedDateTime,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  isUserMode ? '教練: $coachName' : '學生: $userName',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'pending' && isUserMode)
                  TextButton(
                    onPressed: () => _cancelBooking(bookingId),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('取消預約'),
                  ),
                
                if (status == 'pending' && !isUserMode)
                  TextButton(
                    onPressed: () => _confirmBooking(bookingId),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                    child: const Text('確認預約'),
                  ),
                
                if (status == 'confirmed')
                  OutlinedButton(
                    onPressed: () {
                      // TODO: 導航到課程詳情頁面
                    },
                    child: const Text('查看詳情'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 