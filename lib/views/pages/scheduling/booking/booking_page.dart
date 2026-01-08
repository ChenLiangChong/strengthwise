// ✅ v3.1-B: 訓練行事曆 - Tab 分離（我的/教練）+ SpeedDial
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:strengthwise/utils/datetime_utils.dart';
import 'package:strengthwise/views/pages/workout/execution/plan_editor_page.dart';
import 'package:strengthwise/views/pages/workout/execution/workout_execution_page.dart';
import 'package:strengthwise/views/pages/scheduling/availability/client_availability_page.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/coach_slots_management_page.dart';
import 'package:strengthwise/views/pages/session/session_mode_page.dart';
import 'package:strengthwise/controllers/interfaces/i_booking_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/controllers/booking_controller.dart';
import 'package:strengthwise/controllers/profile_controller.dart';
import 'package:strengthwise/services/interfaces/i_workout_service.dart';
import 'package:strengthwise/services/interfaces/i_coaching_relationship_service.dart';
import 'package:strengthwise/services/interfaces/i_availability_slot_service.dart';
import 'package:strengthwise/services/interfaces/i_client_availability_service.dart';
import 'package:strengthwise/services/interfaces/i_appointment_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/models/client_availability_model.dart';
import 'package:strengthwise/models/appointment_model.dart';
import 'package:strengthwise/models/workout_record/workout_record.dart';
import 'package:strengthwise/views/pages/scheduling/booking/widgets/booking_calendar_view.dart';
import 'package:strengthwise/views/pages/scheduling/booking/widgets/booking_speed_dial.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/client_booking/booking_confirmation_dialog.dart';

class BookingPage extends StatefulWidget {
  // 允許外部注入控制器以實現依賴注入
  final IBookingController? controller;

  const BookingPage({
    super.key,
    this.controller,
  });

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage>
    with SingleTickerProviderStateMixin {
  late final IBookingController _controller;
  late final IWorkoutService _workoutService;
  late final IAuthController _authController;
  late final ProfileController _profileController;
  late final ICoachingRelationshipService _relationshipService;
  late final IAvailabilitySlotService _slotService;
  late final IClientAvailabilityService _clientAvailabilityService;
  late final IAppointmentService _appointmentService;
  final ErrorHandlingService _errorService =
      serviceLocator<ErrorHandlingService>();

  bool _isLoading = true;
  bool _isInitialized = false;

  // ⭐ v3.1-B: Tab 控制器
  TabController? _tabController;
  int _currentTabIndex = 0;

  // ⭐ v3.1-B: 用戶身份
  bool _isCoach = false;
  bool _hasCoach = false;
  List<String> _coachIds = []; // 我的教練 ID 列表（Tab 1 用）
  Map<String, String> _coachNames = {}; // 教練 ID -> 名稱 映射（預約 Dialog 用）
  List<String> _clientIds = []; // 我的學員 ID 列表（Tab 2 用）

  // 行事曆相關狀態
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // ⭐ v3.1-B: Tab 1「我的」數據
  Map<DateTime, List<Map<String, dynamic>>> _myTrainings = {}; // trainee_id = userId
  List<Map<String, dynamic>> _selectedDayMyTrainings = [];
  Map<DateTime, List<AvailabilitySlotWithBooking>> _coachSlots = {}; // 教練可上課時段
  List<AvailabilitySlotWithBooking> _selectedDayCoachSlots = [];

  // ⭐ v3.1-B: Tab 2「教練」數據
  Map<DateTime, List<Map<String, dynamic>>> _coachTrainings = {}; // creator_id = userId, trainee_id != userId, has appointment_id
  List<Map<String, dynamic>> _selectedDayCoachTrainings = [];
  Map<DateTime, List<ClientAvailabilityModel>> _clientAvailability = {}; // 學員可訓練時段
  List<ClientAvailabilityModel> _selectedDayClientAvailability = [];

  // 舊變數（保留相容性）
  Map<DateTime, List<Map<String, dynamic>>> _trainings = {};
  List<Map<String, dynamic>> _selectedDayTrainings = [];
  Map<DateTime, List<Map<String, dynamic>>> _bookings = {};
  List<Map<String, dynamic>> _selectedDayBookings = [];

  // 訓練計劃過濾
  bool _showSelfPlans = true; // 顯示自主訓練計劃
  bool _showTrainerPlans = true; // 顯示教練創建的計劃
  bool _showSessionPlans = true; // ⭐ v3.1: 顯示上課（有 appointmentId）

  @override
  void initState() {
    super.initState();

    // 使用注入的控制器或創建新的控制器
    _controller = widget.controller ?? BookingController();
    _workoutService = serviceLocator<IWorkoutService>();
    _authController = serviceLocator<IAuthController>();
    _profileController = serviceLocator<ProfileController>();
    _relationshipService = serviceLocator<ICoachingRelationshipService>();
    _slotService = serviceLocator<IAvailabilitySlotService>();
    _clientAvailabilityService = serviceLocator<IClientAvailabilityService>();
    _appointmentService = serviceLocator<IAppointmentService>();

    // 確保控制器已初始化後載入數據
    _safeInitialize();
  }

  Future<void> _safeInitialize() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 添加初始化超時保護
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
                debugPrint('[BOOKING PAGE] 控制器初始化超時(8秒)，強制繼續');
              }
            })
          ]);
        } catch (e) {
          debugPrint('[BOOKING PAGE] 等待控制器初始化時發生錯誤: $e');
          // 繼續執行，不要中斷頁面顯示
        }
      }

      // ⭐ v3.1-B: 載入用戶身份
      await _loadUserIdentity();

      // 無論控制器是否完全初始化，都標記為已初始化並嘗試載入數據
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });

        // ⭐ v3.1-B: 載入所有必要數據
        await _loadAllData();
      }
    } catch (e) {
      // 確保頁面總是顯示，即使初始化完全失敗
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = true; // 即使失敗也設為已初始化以顯示頁面
          _bookings = {};
        });

        // 嘗試顯示錯誤，但不讓它阻止頁面顯示
        try {
          _errorService.handleError(
            context,
            '預約系統初始化失敗: ${e.toString()}',
            customMessage: '預約載入失敗',
          );
        } catch (_) {
          // 即使錯誤處理失敗也繼續顯示頁面
          NotificationUtils.showError(context, '預約系統初始化失敗');
        }
      }
    }
  }

  /// ⭐ v3.1-B: 載入用戶身份（isCoach, hasCoach）和相關 ID
  Future<void> _loadUserIdentity() async {
    try {
      // 載入 Profile
      await _profileController.loadUserProfile();
      final profile = _profileController.userProfile;

      if (profile != null) {
        _isCoach = profile.isCoach;
      }

      final userId = _authController.user?.uid;
      if (userId == null) return;

      // 檢查是否有教練，並保存所有教練資訊
      final coaches =
          await _relationshipService.getClientCoachesWithRelationship(userId);
      _hasCoach = coaches.isNotEmpty;
      _coachIds = coaches
          .where((c) => c.user != null)
          .map((c) => c.user!.uid)
          .toList();
      _coachNames = {
        for (var c in coaches.where((c) => c.user != null))
          c.user!.uid: c.user!.displayName ?? c.user?.email ?? '未知教練'
      };

      debugPrint('[BOOKING PAGE] 🔍 用戶身份載入：isCoach=$_isCoach, hasCoach=$_hasCoach, coachIds=${_coachIds.length}個');

      // 如果是教練，載入學員列表
      if (_isCoach) {
        final clients =
            await _relationshipService.getCoachClientsWithRelationship(userId);
        _clientIds =
            clients.where((c) => c.user != null).map((c) => c.user!.uid).toList();
      }

      // 初始化 TabController（只有教練才有兩個 Tab）
      if (mounted) {
        setState(() {
          _tabController = TabController(
            length: _isCoach ? 2 : 1,
            vsync: this,
          );
          _tabController!.addListener(_onTabChanged);
        });
      }
    } catch (e) {
      debugPrint('[BOOKING PAGE] 載入用戶身份失敗: $e');
    }
  }

  void _onTabChanged() {
    if (_tabController != null && mounted) {
      setState(() {
        _currentTabIndex = _tabController!.index;
        _updateSelectedDayData();
      });
    }
  }

  /// ⭐ v3.1-B: 載入所有必要數據
  Future<void> _loadAllData() async {
    debugPrint('[BOOKING PAGE] 🔄 _loadAllData: hasCoach=$_hasCoach, coachIds=${_coachIds.length}個, isCoach=$_isCoach, clientIds=${_clientIds.length}個');

    final futures = <Future>[];

    // 1. 載入訓練計劃（分 Tab 1 和 Tab 2）
    futures.add(_loadTrainingPlans());

    // 2. Tab 1：如果有教練，載入所有教練的可上課時段
    if (_hasCoach && _coachIds.isNotEmpty) {
      debugPrint('[BOOKING PAGE] ✅ 將載入 ${_coachIds.length} 位教練的可上課時段');
      futures.add(_loadCoachSlots());
    } else {
      debugPrint('[BOOKING PAGE] ⚠️ 跳過載入教練時段：hasCoach=$_hasCoach, coachIds=${_coachIds.length}個');
    }

    // 3. Tab 2：如果是教練，載入學員可訓練時段
    if (_isCoach && _clientIds.isNotEmpty) {
      debugPrint('[BOOKING PAGE] ✅ 將載入學員可訓練時段');
      futures.add(_loadClientAvailability());
    } else {
      debugPrint('[BOOKING PAGE] ⚠️ 跳過載入學員時段：isCoach=$_isCoach, clientIds=${_clientIds.length}');
    }

    // 4. 載入預約數據（保留相容性）
    futures.add(_loadBookings());

    await Future.wait(futures);
  }

  /// ⭐ v3.1-B: 載入所有教練的可上課時段（Tab 1 用）
  Future<void> _loadCoachSlots() async {
    if (_coachIds.isEmpty) return;

    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 2, 0); // 載入兩個月

      // 按日期分組（合併所有教練的時段）
      final slotsByDate = <DateTime, List<AvailabilitySlotWithBooking>>{};
      int totalSlots = 0;
      int bookedCount = 0;

      // 載入每個教練的時段
      for (final coachId in _coachIds) {
        final coachName = _coachNames[coachId] ?? '未知教練';
        debugPrint('[BOOKING PAGE] 📋 載入教練 $coachName ($coachId) 的時段...');

        final slots = await _slotService.getAvailableSlots(
          coachId: coachId,
          startDate: startDate,
          endDate: endDate,
        );

        totalSlots += slots.length;

        for (var slot in slots) {
          final date = slot.slot.startTime;
          final day = DateTime(date.year, date.month, date.day);

          debugPrint('[BOOKING PAGE]   🕐 [$coachName] ${slot.slot.startTime} - ${slot.slot.endTime}, isBooked=${slot.isBooked}');

          // 只顯示未被預約的時段
          if (slot.isBooked) {
            bookedCount++;
            continue;
          }

          if (slotsByDate[day] == null) {
            slotsByDate[day] = [];
          }
          slotsByDate[day]!.add(slot);
        }
      }

      if (bookedCount > 0) {
        debugPrint('[BOOKING PAGE]   ⚠️ 已過濾 $bookedCount 個已預約時段');
      }

      if (mounted) {
        setState(() {
          _coachSlots = slotsByDate;
          _updateSelectedDayData();
        });
      }

      debugPrint('[BOOKING PAGE] ✅ 載入 ${_coachIds.length} 位教練時段完成，共 $totalSlots 個時段，可預約 ${slotsByDate.values.fold(0, (sum, list) => sum + list.length)} 個');
      // 顯示時段分佈
      for (var entry in slotsByDate.entries) {
        debugPrint('[BOOKING PAGE]   📅 ${entry.key}: ${entry.value.length} 個時段');
      }
    } catch (e) {
      debugPrint('[BOOKING PAGE] ❌ 載入教練時段失敗: $e');
    }
  }

  /// ⭐ v3.1-B: 載入學員可訓練時段（Tab 2 用）
  Future<void> _loadClientAvailability() async {
    if (_clientIds.isEmpty) return;

    final userId = _authController.user?.uid;
    if (userId == null) return;

    try {
      final allAvailability = <DateTime, List<ClientAvailabilityModel>>{};

      // 載入所有學員的可訓練時段
      for (var clientId in _clientIds) {
        final availability =
            await _clientAvailabilityService.getClientAvailabilityForCoach(
          coachId: userId,
          clientId: clientId,
        );

        for (var slot in availability) {
          final date = slot.startTime;
          final day = DateTime(date.year, date.month, date.day);

          if (allAvailability[day] == null) {
            allAvailability[day] = [];
          }
          allAvailability[day]!.add(slot);
        }
      }

      if (mounted) {
        setState(() {
          _clientAvailability = allAvailability;
          _updateSelectedDayData();
        });
      }

      debugPrint('[BOOKING PAGE] ✅ 載入學員可訓練時段完成，共 ${allAvailability.length} 天');
      // 顯示時段分佈
      for (var entry in allAvailability.entries) {
        debugPrint('[BOOKING PAGE]   📅 ${entry.key}: ${entry.value.length} 個時段');
      }
    } catch (e) {
      debugPrint('[BOOKING PAGE] ❌ 載入學員可訓練時段失敗: $e');
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    if (!mounted || !_isInitialized) return;

    try {
      // 統一載入使用者所有預約
      final bookings = await _controller.loadUserBookings();

      if (!mounted) return;

      // 將預約按日期分組
      final bookingsByDate = <DateTime, List<Map<String, dynamic>>>{};

      for (var booking in bookings) {
        final dateTime = booking['dateTime'];
        // 同时跳過 Firestore Timestamp（預约系统已經移到 Supabase）
        if (dateTime != null && dateTime is String) {
          final date = DateTimeUtils.parseIsoTimestamp(dateTime); // 用統一工具類
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
      });
    } catch (e) {
      if (!mounted) return;

      _errorService.handleLoadingError(context, e);
    }
  }

  // 載入訓練計劃數據，根據新的資料結構
  /// 重新載入數據（清除快取）
  Future<void> _refreshData() async {
    debugPrint('[BOOKING PAGE] 🔄 重新載入數據（清除快取）');

    try {
      // 先清除當前用戶的訓練計劃快取
      final userId = _authController.user?.uid;
      if (userId != null) {
        _workoutService.clearUserPlansCache(userId);
      }

      // ⭐ v3.1-B: 重新載入所有數據
      await _loadAllData();

      if (mounted) {
        NotificationUtils.showSuccess(context, '數據已更新');
      }
    } catch (e) {
      debugPrint('[BOOKING PAGE] ❌ 重新載入失敗: $e');
      if (mounted) {
        NotificationUtils.showError(context, '重新失敗');
      }
    }
  }

  Future<void> _loadTrainingPlans() async {
    if (!mounted) return;

    // ⚡ 優化：只有已初始化時不顯示載入指示器（避免閃爍）
    if (_trainings.isEmpty && _myTrainings.isEmpty) {
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

      debugPrint('[BOOKING PAGE] 從 WorkoutService 載入訓練計劃，userId: $userId');

      // ⚡ 優化：使用 WorkoutService 的快取和 limit 設定（較大值以獲取全部資料）
      // WorkoutService 內部有 3 小時快取機制，避免頻繁查詢資料庫
      // 必須確保傳入 userId，確保查詢的是當前用戶的訓練計劃
      final userPlans = await _workoutService.getUserPlans(
        userId: userId, // 必須確保用戶 ID
        limit: 100,
      );

      debugPrint('[BOOKING PAGE] ✅ 查詢到 ${userPlans.length} 筆用戶訓練計劃');

      // ⭐ v3.1-B: 如果是教練，額外載入為學員創建的訓練計劃（Tab 2 用）
      List<WorkoutRecord> coachCreatedPlans = [];
      if (_isCoach && _clientIds.isNotEmpty) {
        coachCreatedPlans = await _workoutService.getCoachCreatedPlans(
          coachId: userId,
          clientIds: _clientIds,
          limit: 100,
        );
        debugPrint('[BOOKING PAGE] ✅ 查詢到 ${coachCreatedPlans.length} 筆教練創建的計劃');
      }

      // 合併兩個列表（去重）
      final planIds = <String>{};
      final plans = <WorkoutRecord>[];
      for (final plan in [...userPlans, ...coachCreatedPlans]) {
        if (!planIds.contains(plan.id)) {
          planIds.add(plan.id);
          plans.add(plan);
        }
      }

      debugPrint('[BOOKING PAGE] ✅ 合併後共 ${plans.length} 筆訓練計劃');

      // ⭐ v3.1-B: 分離 Tab 1 和 Tab 2 的訓練數據
      final myTrainings = <DateTime, List<Map<String, dynamic>>>{}; // Tab 1
      final coachTrainings = <DateTime, List<Map<String, dynamic>>>{}; // Tab 2
      final allTrainings = <DateTime, List<Map<String, dynamic>>>{}; // 相容舊版

      // 處理所有訓練計劃（包括已完成和已排定）
      for (var plan in plans) {
        // ⚠️ 重要：使用 UTC 日期作為鍵，避免時區轉換問題
        final date = plan.date; // UTC 時間
        final day = DateTime(date.year, date.month, date.day); // UTC 日期

        final planData = {
          'id': plan.id,
          'title': plan.title.isEmpty ? '訓練計畫' : plan.title,
          'description': plan.notes,
          'scheduled_date':
              DateTimeUtils.formatToUtcIso(plan.date), // 將本地時間轉為 UTC
          'trainingEndTime': plan.trainingEndTime != null
              ? DateTimeUtils.formatToUtcIso(plan.trainingEndTime!)
              : null,
          'exercises': plan.exerciseRecords
              .map((e) => {
                    'exerciseName': e.exerciseName,
                    'sets': e.sets.length,
                    'completed': e.completed,
                  })
              .toList(),
          'completed': plan.completed,
          'planType': _getPlanType(
            appointmentId: plan.appointmentId,
            creatorId: plan.creatorId,
            traineeId: plan.traineeId,
          ),
          'trainee_id': plan.traineeId ?? plan.userId,
          'creator_id': plan.creatorId ?? plan.userId,
          'appointment_id': plan.appointmentId,
          'dataType': 'plan',
        };

        final traineeId = plan.traineeId ?? plan.userId;
        final creatorId = plan.creatorId ?? plan.userId;

        // 放入 allTrainings（相容舊版）
        if (allTrainings[day] == null) allTrainings[day] = [];
        allTrainings[day]!.add(planData);

        // ⭐ v3.1-B: 判斷屬於哪個 Tab
        // Tab 1「我的」：trainee_id = userId（我是學員）
        if (traineeId == userId) {
          if (myTrainings[day] == null) myTrainings[day] = [];
          myTrainings[day]!.add(planData);
        }

        // Tab 2「教練」：creator_id = userId && trainee_id != userId && 有 appointment_id
        // （只顯示上課課程，不顯示普通訓練計畫）
        final isCoachSession = creatorId == userId &&
            traineeId != userId &&
            plan.appointmentId != null;

        final planType = planData['planType'] as String;
        debugPrint('[BOOKING PAGE] 📋 計劃 ${plan.id}: '
            'creator=$creatorId, trainee=$traineeId, appointmentId=${plan.appointmentId}, '
            'planType=$planType, isCoachSession=$isCoachSession');

        if (isCoachSession) {
          if (coachTrainings[day] == null) coachTrainings[day] = [];
          coachTrainings[day]!.add(planData);
        }
      }

      if (!mounted) return;

      setState(() {
        _trainings = allTrainings;
        _myTrainings = myTrainings;
        _coachTrainings = coachTrainings;
        _updateSelectedDayData();
        _isLoading = false;
      });

      debugPrint(
          '[BOOKING PAGE] ✅ 訓練計劃載入完成：Tab1=${myTrainings.length}天，Tab2=${coachTrainings.length}天');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      debugPrint('[BOOKING PAGE] 載入訓練計劃失敗: $e');
    }
  }

  // ⭐ v3.1-B: 更新選定日數據（根據當前 Tab）
  void _updateSelectedDayData() {
    final selectedDay =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

    // Tab 1「我的」數據
    final myTrainings = _myTrainings[selectedDay] ?? [];
    _selectedDayMyTrainings = myTrainings.where((training) {
      final planType = training['planType'] as String? ?? '';
      if (planType == 'self' && !_showSelfPlans) return false;
      if (planType == 'trainer' && !_showTrainerPlans) return false;
      if (planType == 'session' && !_showSessionPlans) return false;
      return true;
    }).toList();
    // 教練可上課時段
    _selectedDayCoachSlots = _coachSlots[selectedDay] ?? [];

    // Tab 2「教練」數據
    _selectedDayCoachTrainings = _coachTrainings[selectedDay] ?? [];
    // 學員可訓練時段
    _selectedDayClientAvailability = _clientAvailability[selectedDay] ?? [];

    // 舊變數（相容性）
    final allTrainings = _trainings[selectedDay] ?? [];
    _selectedDayTrainings = allTrainings.where((training) {
      final planType = training['planType'] as String? ?? '';
      if (planType == 'self' && !_showSelfPlans) return false;
      if (planType == 'trainer' && !_showTrainerPlans) return false;
      if (planType == 'session' && !_showSessionPlans) return false;
      return true;
    }).toList();
    _selectedDayBookings = _bookings[selectedDay] ?? [];

    debugPrint('[BOOKING PAGE] 📅 更新選定日數據：$selectedDay');
    debugPrint('[BOOKING PAGE]   - 我的訓練：${_selectedDayMyTrainings.length}');
    debugPrint('[BOOKING PAGE]   - 教練時段：${_selectedDayCoachSlots.length}');
    debugPrint('[BOOKING PAGE]   - 教練Tab訓練：${_selectedDayCoachTrainings.length}');
    debugPrint('[BOOKING PAGE]   - 學員可訓練：${_selectedDayClientAvailability.length}');
    // 檢查 coachSlots 的 keys
    if (_coachSlots.isNotEmpty) {
      debugPrint('[BOOKING PAGE]   - coachSlots keys: ${_coachSlots.keys.toList()}');
      debugPrint('[BOOKING PAGE]   - 查找 key: $selectedDay, 找到: ${_coachSlots.containsKey(selectedDay)}');
    }
  }

  /// ⭐ v3.1: 判斷訓練類型
  ///
  /// 優先級：session > trainer > self
  String _getPlanType({
    String? appointmentId,
    String? creatorId,
    String? traineeId,
  }) {
    // 有 appointmentId → 上課
    if (appointmentId != null && appointmentId.isNotEmpty) {
      return 'session';
    }
    // creatorId != traineeId → 教練安排
    if (creatorId != null && traineeId != null && creatorId != traineeId) {
      return 'trainer';
    }
    // 其他 → 自主
    return 'self';
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
        case 'session':
          _showSessionPlans = !_showSessionPlans;
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

  // 創建新訓練計劃
  Future<void> _createTrainingPlan() async {
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanEditorPage(
          selectedDate: _selectedDay,
          // 個人創建：不預設值，讓用戶自由選擇
        ),
      ),
    );

    if (result == true) {
      // 如果成功創建了計劃，重新載入數據
      _loadTrainingPlans();
    }
  }

  // ⭐ v3.1-B: 設定可訓練時間
  void _navigateToTrainableTime() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClientAvailabilityPage(),
      ),
    );
  }

  // ⭐ v3.1-B: 設定可上課時間
  void _navigateToAvailableTime() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CoachSlotsManagementPage(),
      ),
    );
  }

  // ⭐ v3.1-B: 幫學員新增訓練（TODO: 需要選擇學員）
  void _createTrainingForStudent() {
    // TODO: 顯示學員選擇器，然後跳轉到 PlanEditorPage
    NotificationUtils.showInfo(context, '功能開發中：請先在學員詳情頁為學員新增訓練');
  }

  // ⭐ v3.1-B: 預約教練時段
  Future<void> _bookCoachSlot(AvailabilitySlotWithBooking slot) async {
    final coachId = slot.slot.coachId;
    final coachName = _coachNames[coachId] ?? '教練';

    // 顯示確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => BookingConfirmationDialog(
        slot: slot,
        coachName: coachName,
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final userId = _authController.user?.uid;
      if (userId == null) return;

      // 創建預約 Model
      final appointment = AppointmentModel(
        id: '', // 由服務端生成
        coachId: coachId,
        clientId: userId,
        startTime: slot.slot.startTime,
        endTime: slot.slot.endTime,
        status: AppointmentStatus.requested,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _appointmentService.createAppointment(appointment);

      if (mounted) {
        NotificationUtils.showSuccess(context, '預約申請已送出，等待教練確認');
        _loadAllData(); // 重新載入數據
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(context, '預約失敗: $e');
      }
    }
  }

  // ⭐ v3.1-B: 選擇學員可訓練時段 → 新增訓練計畫
  Future<void> _selectClientSlot(ClientAvailabilityModel slot) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanEditorPage(
          selectedDate: slot.startTime,
          traineeId: slot.clientId,
          initialStartTime: slot.startTime,
          initialEndTime: slot.endTime,
        ),
      ),
    );

    if (result == true) {
      _loadAllData(); // 重新載入數據
    }
  }

  // ⭐ v3.1-B: 進入 Session Mode
  Future<void> _enterSession(String planId, String appointmentId) async {
    try {
      // 查詢預約詳情
      final appointment =
          await _appointmentService.getAppointmentById(appointmentId);

      if (appointment == null) {
        if (mounted) {
          NotificationUtils.showError(context, '找不到預約資訊');
        }
        return;
      }

      if (!mounted) return;

      // 判斷是教練還是學員
      final userId = _authController.user?.uid;
      final isCoachMode = appointment.coachId == userId;

      // 獲取學員名稱
      String clientName = '學員';
      if (isCoachMode) {
        // 從學員列表中找名稱
        final clients =
            await _relationshipService.getCoachClientsWithRelationship(userId!);
        final client =
            clients.where((c) => c.user?.uid == appointment.clientId).firstOrNull;
        clientName = client?.user?.displayName ?? client?.user?.email ?? '學員';
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionModePage(
            appointmentId: appointmentId,
            clientId: appointment.clientId,
            clientName: clientName,
            sessionStartTime: appointment.startTime,
            sessionEndTime: appointment.endTime,
            isCoachMode: isCoachMode,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(context, '載入預約資訊失敗: $e');
      }
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
      // 如果訓練計劃有更改，重新載入數據
      _loadTrainingPlans();
    }
  }

  // 編輯訓練計劃
  Future<void> _editTrainingPlan(String planId, DateTime scheduledDate) async {
    if (!mounted) return;

    debugPrint('[BOOKING PAGE] 編輯訓練計劃: $planId');

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
      // 重新載入訓練計劃
      _loadTrainingPlans();
    }
  }

  // 刪除訓練計畫
  // ⭐ v2.9.1: 前端權限檢查，避免觸發 RLS 刪除失敗
  Future<void> _deleteTrainingPlan(String planId, String planTitle) async {
    if (!mounted) return;

    // ⭐ v2.9.1: 從快取的訓練計劃中找到這個計劃並檢查創建者
    final currentUserId = _authController.user?.uid;
    final plan = _selectedDayTrainings.firstWhere(
      (p) => p['id'] == planId,
      orElse: () => {},
    );

    if (plan.isEmpty) {
      NotificationUtils.showError(context, '找不到訓練計劃');
      return;
    }

    final creatorId = plan['creator_id'] as String?;
    final traineeId = plan['trainee_id'] as String?;

    // ⭐ v2.9.1 TRN-2: 權限檢查 - 只有創建者可以刪除
    // 如果 creatorId 存在且不等於當前用戶，阻止刪除
    // 如果 creatorId 不存在則回退，基於 traineeId 判斷（自己創建的可以刪除）
    final effectiveCreatorId = creatorId ?? traineeId;
    if (effectiveCreatorId != null && effectiveCreatorId != currentUserId) {
      NotificationUtils.showWarning(
        context,
        '無法刪除教練安排的訓練計劃，如需調整請聯繫教練',
      );
      return;
    }

    // 顯示確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 修復：禁止點擊旁邊關閉
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
      debugPrint('[BOOKING PAGE] 刪除訓練計畫: $planId');

      // 使用 WorkoutService 刪除記錄
      final success = await _workoutService.deleteRecord(planId);

      if (mounted) {
        if (success) {
          NotificationUtils.showSuccess(context, '訓練計畫已刪除');
        } else {
          NotificationUtils.showError(context, '刪除失敗，請稍後再試');
        }

        // 重新載入訓練計畫
        _loadTrainingPlans();
      }
    } catch (e) {
      debugPrint('[BOOKING PAGE] 刪除訓練計畫失敗: $e');

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
        // ⭐ v3.1-B: TabBar（只有教練才有兩個 Tab）
        bottom: _isCoach && _tabController != null
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '🎓 我的'),
                  Tab(text: '🏋️ 教練'),
                ],
              )
            : null,
        actions: [
          // 重新載入按鈕
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新載入',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isCoach && _tabController != null
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCalendarContent(isCoachTab: false),
                    _buildCalendarContent(isCoachTab: true),
                  ],
                )
              : _buildCalendarContent(isCoachTab: false),
      // ⭐ v3.1-B: SpeedDial（根據身份和 Tab 顯示不同選項）
      floatingActionButton: BookingSpeedDial(
        onAddTraining: _createTrainingPlan,
        onSetTrainableTime: _hasCoach ? _navigateToTrainableTime : null,
        onAddTrainingForStudent:
            _isCoach && _currentTabIndex == 1 ? _createTrainingForStudent : null,
        onSetAvailableTime:
            _isCoach && _currentTabIndex == 1 ? _navigateToAvailableTime : null,
        showTrainableTime: _hasCoach && _currentTabIndex == 0,
        isCoachTab: _isCoach && _currentTabIndex == 1,
      ),
    );
  }

  /// 構建行事曆內容
  Widget _buildCalendarContent({required bool isCoachTab}) {
    // ⭐ v3.1-B: 根據 Tab 選擇正確的數據
    final trainings = isCoachTab ? _coachTrainings : _myTrainings;
    final selectedDayTrainings =
        isCoachTab ? _selectedDayCoachTrainings : _selectedDayMyTrainings;

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: BookingCalendarView(
        focusedDay: _focusedDay,
        selectedDay: _selectedDay,
        calendarFormat: _calendarFormat,
        trainings: trainings,
        bookings: _bookings,
        selectedDayTrainings: selectedDayTrainings,
        selectedDayBookings: _selectedDayBookings,
        currentUserId: _authController.user?.uid,
        isCoachMode: isCoachTab,
        showSelfPlans: _showSelfPlans,
        showTrainerPlans: _showTrainerPlans,
        showSessionPlans: _showSessionPlans,
        // ⭐ v3.1-B: 傳遞時段數據
        coachSlots: isCoachTab ? null : _coachSlots,
        selectedDayCoachSlots: isCoachTab ? null : _selectedDayCoachSlots,
        clientAvailability: isCoachTab ? _clientAvailability : null,
        selectedDayClientAvailability:
            isCoachTab ? _selectedDayClientAvailability : null,
        coachNames: _coachNames,
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
        // ⭐ v3.1-B: 新回調
        onBookCoachSlot: _bookCoachSlot,
        onSelectClientSlot: _selectClientSlot,
        onEnterSession: _enterSession,
      ),
    );
  }
}
