import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../workout/plan_editor_page.dart';
import '../workout/workout_execution_page.dart';
import '../../../controllers/interfaces/i_booking_controller.dart';
import '../../../controllers/interfaces/i_auth_controller.dart';
import '../../../controllers/booking_controller.dart';
import '../../../services/interfaces/i_workout_service.dart';
import '../../../services/core/error_handling_service.dart';
import '../../../services/service_locator.dart';
import '../../../utils/notification_utils.dart';
import 'widgets/booking_calendar_view.dart';

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
  late final IWorkoutService _workoutService;
  late final IAuthController _authController;
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
    _workoutService = serviceLocator<IWorkoutService>();
    _authController = serviceLocator<IAuthController>();
    
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
          NotificationUtils.showError(context, '預約系統初始化失敗');
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
        // 暂时跳过 Firestore Timestamp（预约系统尚未迁移到 Supabase）
        if (dateTime != null && dateTime is String) {
          final date = DateTime.parse(dateTime);
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
    
    // ⚡ 優化：如果已有資料，不顯示載入動畫（避免閃爍）
    if (_trainings.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      // 使用 AuthController 的當前用戶 UID（已經是 Supabase UUID）
      final userId = _authController.user?.uid;
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      print('[BOOKING PAGE] 從 WorkoutService 載入訓練計劃，userId: $userId');
      
      // ⚡ 優化：使用 WorkoutService 的快取（limit 設定為較大值以獲取更多資料）
      // WorkoutService 內部有 3 小時快取機制，不會頻繁查詢資料庫
      final plans = await _workoutService.getUserPlans(limit: 100);
      
      print('[BOOKING PAGE] ✅ 查詢到 ${plans.length} 個訓練計劃（利用快取）');
      
      final trainings = <DateTime, List<Map<String, dynamic>>>{};
      
      // 處理所有訓練計劃（包括未完成和已完成的）
      for (var plan in plans) {
        final date = plan.date;
        final day = DateTime(date.year, date.month, date.day);
        
        if (trainings[day] == null) {
          trainings[day] = [];
        }
        
        trainings[day]!.add({
          'id': plan.id,
          'title': plan.title ?? '訓練計畫',
          'description': plan.notes,  // 使用 notes 而不是 description
          'scheduled_date': plan.date.toIso8601String(),
          'exercises': plan.exerciseRecords
              .map((e) => {
                    'exerciseName': e.exerciseName,
                    'sets': e.sets.length,
                    'completed': e.completed,  // 使用 completed 而不是 isCompleted
                  })
              .toList(),
          'completed': plan.completed,
          'planType': 'self',  // WorkoutRecord 沒有 planType，使用預設值
          'trainee_id': plan.userId,  // 使用 userId
          'creator_id': plan.userId,  // 使用 userId
          'dataType': 'plan',
        });
      }
      
      if (!mounted) return;
      
      setState(() {
        _trainings = trainings;
        _updateSelectedDayData();
        _isLoading = false;
      });
      
      print('[BOOKING PAGE] ⚡ 訓練計劃載入完成，共 ${trainings.length} 天有訓練（使用快取優化）');
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
        NotificationUtils.showSuccess(context, '預約已取消');
        _loadBookings();
      } else {
        NotificationUtils.showError(context, '取消預約失敗');
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
        NotificationUtils.showSuccess(context, '預約已確認');
        _loadBookings();
      } else {
        NotificationUtils.showError(context, '確認預約失敗');
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
  
  // 編輯訓練計劃
  Future<void> _editTrainingPlan(String planId, DateTime scheduledDate) async {
    if (!mounted) return;
    
    print('[BOOKING PAGE] 編輯訓練計劃: $planId');
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanEditorPage(
          planId: planId,
          selectedDate: scheduledDate,
        ),
      ),
    );
    
    if (result == true) {
      // 重新加載訓練計劃
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
      print('[BOOKING PAGE] 刪除訓練計畫: $planId');
      
      // 使用 WorkoutService 刪除記錄
      await _workoutService.deleteRecord(planId);
      
      if (mounted) {
        NotificationUtils.showSuccess(context, '訓練計畫已刪除');
        
        // 重新加載訓練計畫
        _loadTrainingPlans();
      }
    } catch (e) {
      print('[BOOKING PAGE] 刪除訓練計畫失敗: $e');
      
      if (mounted) {
        NotificationUtils.showError(context, '刪除失敗: $e');
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
              : BookingCalendarView(
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  calendarFormat: _calendarFormat,
                  trainings: _trainings,
                  bookings: _bookings,
                  selectedDayTrainings: _selectedDayTrainings,
                  selectedDayBookings: _selectedDayBookings,
                  currentUserId: _authController.user?.uid,
                  isCoachMode: false,
                  showSelfPlans: _showSelfPlans,
                  showTrainerPlans: _showTrainerPlans,
                  showBookings: _showBookings,
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
                  onToggleFilter: _toggleFilter,
                  onExecuteTraining: _executeTrainingPlan,
                  onEditTraining: _editTrainingPlan,
                  onDeleteTraining: _deleteTrainingPlan,
                  onCancelBooking: _cancelBooking,
                  onConfirmBooking: _confirmBooking,
                  onViewBookingDetails: () {
                    // TODO: 導航到課程詳情頁面
                  },
                ),
          
          // 教練模式 - 行事曆視圖
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : BookingCalendarView(
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  calendarFormat: _calendarFormat,
                  trainings: _trainings,
                  bookings: _bookings,
                  selectedDayTrainings: _selectedDayTrainings,
                  selectedDayBookings: _selectedDayBookings,
                  currentUserId: _authController.user?.uid,
                  isCoachMode: true,
                  showSelfPlans: _showSelfPlans,
                  showTrainerPlans: _showTrainerPlans,
                  showBookings: _showBookings,
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
                  onToggleFilter: _toggleFilter,
                  onExecuteTraining: _executeTrainingPlan,
                  onEditTraining: _editTrainingPlan,
                  onDeleteTraining: _deleteTrainingPlan,
                  onCancelBooking: _cancelBooking,
                  onConfirmBooking: _confirmBooking,
                  onViewBookingDetails: () {
                    // TODO: 導航到課程詳情頁面
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isCoachMode ? null : _createTrainingPlan,
        tooltip: '創建訓練計劃',
        child: const Icon(Icons.add),
      ),
    );
  }
} 