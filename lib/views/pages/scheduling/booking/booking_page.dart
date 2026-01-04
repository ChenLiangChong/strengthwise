import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:strengthwise/utils/datetime_utils.dart';
import 'package:strengthwise/views/pages/workout/execution/plan_editor_page.dart';
import 'package:strengthwise/views/pages/workout/execution/workout_execution_page.dart';
import 'package:strengthwise/controllers/interfaces/i_booking_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/controllers/booking_controller.dart';
import 'package:strengthwise/services/interfaces/i_workout_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/pages/scheduling/booking/widgets/booking_calendar_view.dart';

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

class _BookingPageState extends State<BookingPage> {
  late final IBookingController _controller;
  late final IWorkoutService _workoutService;
  late final IAuthController _authController;
  final ErrorHandlingService _errorService =
      serviceLocator<ErrorHandlingService>();

  bool _isLoading = true;
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
  bool _showSelfPlans = true; // 顯示自主訓練計劃
  bool _showTrainerPlans = true; // 顯示教練創建的計劃
  bool _showBookings = true; // 顯示預約

  @override
  void initState() {
    super.initState();

    // 使用注入的控制器或創建新的控制器
    _controller = widget.controller ?? BookingController();
    _workoutService = serviceLocator<IWorkoutService>();
    _authController = serviceLocator<IAuthController>();

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
            _bookings = {};
          });
        }
      }
    } catch (e) {
      // 確保界面總是顯示，即使初始化完全失敗
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = true; // 即使失敗也設為已初始化，避免卡住界面
          _bookings = {};
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
    super.dispose();
  }

  Future<void> _loadBookings() async {
    if (!mounted || !_isInitialized) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 統一載入使用者的所有預約
      final bookings = await _controller.loadUserBookings();

      if (!mounted) return;

      // 將預約按日期分組
      final bookingsByDate = <DateTime, List<Map<String, dynamic>>>{};

      for (var booking in bookings) {
        final dateTime = booking['dateTime'];
        // 暂时跳过 Firestore Timestamp（预约系统尚未迁移到 Supabase）
        if (dateTime != null && dateTime is String) {
          final date = DateTimeUtils.parseIsoTimestamp(dateTime); // ⭐ 統一工具類
          final day = DateTime(date.year, date.month, date.day);

          if (bookingsByDate[day] == null) {
            bookingsByDate[day] = [];
          }

          bookingsByDate[day]!.add(booking);
        }
      }

      setState(() {
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
  /// 重新載入數據（清除快取）⭐
  Future<void> _refreshData() async {
    print('[BOOKING PAGE] 🔄 重新載入數據（清除快取）');

    try {
      // ⭐ 清除當前用戶的訓練計劃快取
      final userId = _authController.user?.uid;
      if (userId != null) {
        _workoutService.clearUserPlansCache(userId);
      }

      // 重新載入訓練計劃和預約
      await _loadTrainingPlans();
      await _loadBookings();

      if (mounted) {
        NotificationUtils.showSuccess(context, '數據已更新');
      }
    } catch (e) {
      print('[BOOKING PAGE] ❌ 重新載入失敗: $e');
      if (mounted) {
        NotificationUtils.showError(context, '更新失敗');
      }
    }
  }

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
      // ⭐ 明確傳遞 userId，確保查詢的是當前用戶的訓練計劃
      final plans = await _workoutService.getUserPlans(
        userId: userId, // ⭐ 明確指定用戶 ID
        limit: 100,
      );

      print('[BOOKING PAGE] ✅ 查詢到 ${plans.length} 個訓練計劃（利用快取）');

      final trainings = <DateTime, List<Map<String, dynamic>>>{};

      // 處理所有訓練計劃（包括未完成和已完成的）
      for (var plan in plans) {
        // ⭐ 重要：使用 UTC 日期分組，避免時區邊界問題
        // 例如：UTC 2026-01-01 23:00 → 本地 2026-01-02 07:00
        // 如果用本地日期分組，會顯示在錯誤的日期
        final date = plan.date; // UTC 時間
        final day = DateTime(date.year, date.month, date.day); // UTC 日期

        if (trainings[day] == null) {
          trainings[day] = [];
        }

        trainings[day]!.add({
          'id': plan.id,
          'title': plan.title.isEmpty ? '訓練計畫' : plan.title,
          'description': plan.notes,
          'scheduled_date':
              DateTimeUtils.formatToUtcIso(plan.date), // ⭐ 本地時間轉 UTC
          'trainingEndTime': plan.trainingEndTime != null
              ? DateTimeUtils.formatToUtcIso(plan.trainingEndTime!)
              : null, // ⭐ 本地時間轉 UTC
          'exercises': plan.exerciseRecords
              .map((e) => {
                    'exerciseName': e.exerciseName,
                    'sets': e.sets.length,
                    'completed': e.completed, // 使用 completed 而不是 isCompleted
                  })
              .toList(),
          'completed': plan.completed,
          // ⭐ v2.9.1 TRN-3: 根據 creatorId 判斷是自主訓練還是教練計畫
          'planType': (plan.creatorId != null &&
                  plan.traineeId != null &&
                  plan.creatorId != plan.traineeId)
              ? 'trainer'
              : 'self',
          'trainee_id': plan.traineeId ?? plan.userId,
          'creator_id': plan.creatorId ?? plan.userId,
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
    final selectedDay =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

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
    _selectedDayBookings = _showBookings ? (_bookings[selectedDay] ?? []) : [];
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
          // ⭐ 個人創建：不預設時間，讓用戶自由選擇
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
  // ⭐ v2.9.1: 前端權限檢查，避免依賴 RLS 靜默失敗
  Future<void> _deleteTrainingPlan(String planId, String planTitle) async {
    if (!mounted) return;

    // ⭐ v2.9.1: 先從快取的訓練資料中找到這個計畫，檢查創建者
    final currentUserId = _authController.user?.uid;
    final plan = _selectedDayTrainings.firstWhere(
      (p) => p['id'] == planId,
      orElse: () => {},
    );

    if (plan.isEmpty) {
      NotificationUtils.showError(context, '找不到訓練計畫');
      return;
    }

    final creatorId = plan['creator_id'] as String?;
    final traineeId = plan['trainee_id'] as String?;

    // ⭐ v2.9.1 TRN-2: 權限檢查 - 只有創建者可以刪除
    // 如果 creatorId 存在且不等於當前用戶，阻止刪除
    // 如果 creatorId 不存在（舊記錄），則用 traineeId 判斷（自己創建的可以刪）
    final effectiveCreatorId = creatorId ?? traineeId;
    if (effectiveCreatorId != null && effectiveCreatorId != currentUserId) {
      NotificationUtils.showWarning(
        context,
        '無法刪除教練安排的訓練計畫，如需調整請聯繫教練',
      );
      return;
    }

    // 顯示確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
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
      final success = await _workoutService.deleteRecord(planId);

      if (mounted) {
        if (success) {
          NotificationUtils.showSuccess(context, '訓練計畫已刪除');
        } else {
          NotificationUtils.showError(context, '刪除失敗，請稍後再試');
        }

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
        title: const Text('訓練行事曆'),
        actions: [
          // ⭐ 重新載入按鈕
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新載入',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: BookingCalendarView(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                calendarFormat: _calendarFormat,
                trainings: _trainings,
                bookings: _bookings,
                selectedDayTrainings: _selectedDayTrainings,
                selectedDayBookings: _selectedDayBookings,
                currentUserId: _authController.user?.uid,
                isCoachMode: false, // 統一視圖，不分教練/學員模式
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
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTrainingPlan,
        tooltip: '創建訓練計劃',
        child: const Icon(Icons.add),
      ),
    );
  }
}
