// ✅ v3.1-B: 訓練行事曆 - Tab 分離（我的/教練）+ SpeedDial
// ✅ v3.5: AppEventBus 自動刷新
// ✅ v3.9: Realtime 訂閱（教練時段跨用戶更新）
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:strengthwise/utils/datetime_utils.dart';
import 'package:strengthwise/views/pages/workout/execution/plan_editor_page.dart';
import 'package:strengthwise/views/pages/workout/execution/workout_execution_page.dart';
import 'package:strengthwise/views/pages/scheduling/availability/widgets/availability_slot_editor_dialog.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/quick_add_slot_dialog.dart';
import 'package:strengthwise/models/client_availability_model.dart';
import 'package:strengthwise/views/pages/session/session_mode_page.dart';
import 'package:strengthwise/controllers/interfaces/i_booking_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_workout_controller.dart'; // ⭐ v3.5: MVVM
import 'package:strengthwise/controllers/interfaces/i_profile_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_event_bus_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_appointment_controller.dart'; // ⭐ v3.5: MVVM 重構
import 'package:strengthwise/controllers/interfaces/i_client_availability_controller.dart'; // ⭐ v3.5: MVVM
import 'package:strengthwise/controllers/interfaces/i_coaching_relationship_controller.dart'; // ⭐ v3.6: MVVM
import 'package:strengthwise/controllers/interfaces/i_availability_slot_controller.dart'; // ⭐ v3.6: MVVM
import 'package:strengthwise/controllers/interfaces/i_realtime_controller.dart'; // ⭐ v3.9
import 'package:strengthwise/controllers/booking_controller.dart';
import 'package:strengthwise/services/interfaces/i_availability_slot_service.dart'; // ⭐ 保留：類型定義
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/services/core/onboarding_service.dart';
import 'package:strengthwise/services/core/app_event_bus.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/models/appointment_model.dart';
import 'package:strengthwise/models/workout_record/workout_record.dart';
import 'package:strengthwise/views/pages/scheduling/booking/widgets/booking_calendar_view.dart';
import 'package:strengthwise/views/pages/scheduling/booking/widgets/booking_speed_dial.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/client_booking/booking_confirmation_dialog.dart';
import 'package:strengthwise/views/widgets/onboarding/coach_mark_helper.dart';
import 'package:strengthwise/views/widgets/current_page_provider.dart';

class BookingPage extends StatefulWidget {
  // 允許外部注入控制器以實現依賴注入
  final IBookingController? controller;

  /// ⭐ v3.9: 初始 Tab 索引（用於通知點擊導航）
  /// - 0: 🎓 我的（個人行事曆）
  /// - 1: 🏋️ 教練（教練身份）
  final int initialTabIndex;

  const BookingPage({
    super.key,
    this.controller,
    this.initialTabIndex = 0,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage>
    with SingleTickerProviderStateMixin {
  late final IBookingController _controller;
  late final IWorkoutController _workoutController; // ⭐ v3.5: MVVM
  late final IAuthController _authController;
  late final IProfileController _profileController;
  late final ICoachingRelationshipController
      _relationshipController; // ⭐ v3.6: MVVM
  late final IAvailabilitySlotController _slotController; // ⭐ v3.6: MVVM
  late final IClientAvailabilityController
      _clientAvailabilityController; // ⭐ v3.5: MVVM
  late final IEventBusController _eventBusController; // ⭐ v3.5
  late final IAppointmentController _appointmentController; // ⭐ v3.5: MVVM 重構
  late final IRealtimeController _realtimeController; // ⭐ v3.9
  final ErrorHandlingService _errorService =
      serviceLocator<ErrorHandlingService>();

  // ⭐ v3.5: 事件訂閱
  StreamSubscription<AppEvent>? _eventSubscription;
  StreamSubscription<AppEvent>? _availabilitySubscription; // ⭐ v3.9: 時段事件訂閱

  // ⭐ v3.9: Realtime 訂閱 ID 列表
  final List<String> _coachSlotSubscriptionIds = []; // 教練時段
  final List<String> _clientAvailabilitySubscriptionIds = []; // 學員可訓練時間

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
  Map<String, String> _clientNames = {}; // ⭐ v3.1.1: 學員 ID -> 名稱 映射

  // 行事曆相關狀態
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // ⭐ v3.1-B: Tab 1「我的」數據
  Map<DateTime, List<Map<String, dynamic>>> _myTrainings =
      {}; // trainee_id = userId
  List<Map<String, dynamic>> _selectedDayMyTrainings = [];
  Map<DateTime, List<AvailabilitySlotWithBooking>> _coachSlots = {}; // 教練可上課時段
  List<AvailabilitySlotWithBooking> _selectedDayCoachSlots = [];

  // ⭐ v3.1-B: Tab 2「教練」數據
  Map<DateTime, List<Map<String, dynamic>>> _coachTrainings =
      {}; // creator_id = userId, trainee_id != userId, has appointment_id
  List<Map<String, dynamic>> _selectedDayCoachTrainings = [];
  Map<DateTime, List<ClientAvailabilityModel>> _clientAvailability =
      {}; // 學員可訓練時段
  List<ClientAvailabilityModel> _selectedDayClientAvailability = [];
  // ⭐ v3.9: 教練自己的可上課時段（Tab 1 顯示）
  Map<DateTime, List<AvailabilitySlotWithBooking>> _mySlots = {};
  List<AvailabilitySlotWithBooking> _selectedDayMySlots = [];

  // 舊變數（保留相容性）
  Map<DateTime, List<Map<String, dynamic>>> _trainings = {};
  List<Map<String, dynamic>> _selectedDayTrainings = [];
  Map<DateTime, List<Map<String, dynamic>>> _bookings = {};
  List<Map<String, dynamic>> _selectedDayBookings = [];

  // 訓練計劃過濾
  bool _showSelfPlans = true; // 顯示自主訓練計劃
  bool _showTrainerPlans = true; // 顯示教練創建的計劃
  bool _showSessionPlans = true; // ⭐ v3.1: 顯示上課（有 appointmentId）

  // ⭐ v3.2: Coach Mark 引導
  final GlobalKey _fabKey = GlobalKey();
  bool _coachMarkShown = false;
  bool _coachTabCoachMarkShown = false; // 教練 Tab 的引導

  @override
  void initState() {
    super.initState();

    // 使用注入的控制器或創建新的控制器
    _controller = widget.controller ?? BookingController();
    _workoutController = serviceLocator<IWorkoutController>(); // ⭐ v3.5: MVVM
    _authController = serviceLocator<IAuthController>();
    _profileController = serviceLocator<IProfileController>();
    _relationshipController =
        serviceLocator<ICoachingRelationshipController>(); // ⭐ v3.6: MVVM
    _slotController =
        serviceLocator<IAvailabilitySlotController>(); // ⭐ v3.6: MVVM
    _clientAvailabilityController =
        serviceLocator<IClientAvailabilityController>(); // ⭐ v3.5: MVVM
    _eventBusController = serviceLocator<IEventBusController>(); // ⭐ v3.5
    _appointmentController =
        serviceLocator<IAppointmentController>(); // ⭐ v3.5: MVVM 重構
    _realtimeController = serviceLocator<IRealtimeController>(); // ⭐ v3.9

    // ⭐ v3.5: 訂閱行事曆相關事件
    _eventSubscription = _eventBusController.calendarEvents.listen(_onAppEvent);

    // ⭐ v3.9: 訂閱時段變更事件（Realtime DELETE 用 EventBus 通知）
    _availabilitySubscription =
        _eventBusController.availabilityEvents.listen(_onAvailabilityEvent);

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
                // debugPrint('[BOOKING PAGE] 控制器初始化超時(8秒)，強制繼續');
              }
            })
          ]);
        } catch (e) {
          // debugPrint('[BOOKING PAGE] 等待控制器初始化時發生錯誤: $e');
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

        // ⭐ v3.2: 檢查 Coach Mark 引導
        _checkCoachMark();
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
      // ⭐ v3.6: 透過 Controller 查詢
      final coaches = await _relationshipController
          .getClientCoachesWithRelationship(userId);
      _hasCoach = coaches.isNotEmpty;
      _coachIds = coaches
          .where((c) => c.user != null)
          .map((c) => c.user!.uid) // Safe: filtered by where
          .toList();
      _coachNames = {
        for (var c in coaches)
          if (c.user != null)
            c.user!.uid: c.user!.displayName ?? c.user!.email
      };

      // ⭐ v3.9: 訂閱所有教練的時段 Realtime（教練修改時學員即時看到）
      _subscribeToCoachSlotsRealtime();

      // debugPrint(
      //     '[BOOKING PAGE] 🔍 用戶身份載入：isCoach=$_isCoach, hasCoach=$_hasCoach, coachIds=${_coachIds.length}個');

      // 如果是教練，載入學員列表
      // ⭐ v3.6: 透過 Controller 查詢
      if (_isCoach) {
        final clients = await _relationshipController
            .getCoachClientsWithRelationship(userId);
        _clientIds = clients
            .where((c) => c.user != null)
            .map((c) => c.user!.uid) // Safe: filtered by where
            .toList();
        // ⭐ v3.1.1: 建立學員名稱映射
        _clientNames = {
          for (var c in clients)
            if (c.user != null)
              c.user!.uid: c.user!.displayName ?? c.user!.email
        };

        // ⭐ v3.9: 訂閱所有學員的可訓練時間 Realtime
        _subscribeToClientAvailabilityRealtime();
      }

      // 初始化 TabController（只有教練才有兩個 Tab）
      if (mounted) {
        setState(() {
          final tabController = TabController(
            length: _isCoach ? 2 : 1,
            vsync: this,
            initialIndex: _isCoach ? widget.initialTabIndex.clamp(0, 1) : 0,
          );
          _tabController = tabController;
          _currentTabIndex = tabController.index;
          tabController.addListener(_onTabChanged);
        });
      }
    } catch (e) {
      // debugPrint('[BOOKING PAGE] 載入用戶身份失敗: $e');
    }
  }

  void _onTabChanged() {
    final tabController = _tabController;
    if (tabController != null && mounted) {
      setState(() {
        _currentTabIndex = tabController.index;
        _updateSelectedDayData();
      });

      // ⭐ v3.2: 切換到教練 Tab 時檢查是否需要顯示引導
      if (_currentTabIndex == 1 && !_coachTabCoachMarkShown) {
        _checkCoachTabCoachMark();
      }
    }
  }

  // ⭐ v3.2: 檢查教練 Tab 的 Coach Mark
  Future<void> _checkCoachTabCoachMark() async {
    if (_coachTabCoachMarkShown) return;

    final onboardingService = serviceLocator<OnboardingService>();
    final shouldShow = await onboardingService.shouldShowCoachMark(
      OnboardingService.keyBookingPageCoachTab,
    );

    if (shouldShow && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentTabIndex == 1) {
          _showCoachTabCoachMark();
        }
      });
    }
  }

  // ⭐ v3.2: 顯示教練 Tab 的引導
  void _showCoachTabCoachMark() {
    if (_coachTabCoachMarkShown) return;
    _coachTabCoachMarkShown = true;

    final targets = <TargetFocus>[];

    if (_fabKey.currentContext != null) {
      targets.add(
        CoachMarkHelper.createTarget(
          key: _fabKey,
          title: '教練視角',
          description: '這裡查看你教的課和學員時段\n\n點擊「+」可以：\n• 幫學員新增訓練計劃\n• 設定可上課時間',
          contentAlign: ContentAlign.top,
        ),
      );
    }

    if (targets.isNotEmpty) {
      CoachMarkHelper.show(
        context: context,
        targets: targets,
      );
    }
  }

  /// ⭐ v3.1-B: 載入所有必要數據
  Future<void> _loadAllData() async {
    // debugPrint(
    //     '[BOOKING PAGE] 🔄 _loadAllData: hasCoach=$_hasCoach, coachIds=${_coachIds.length}個, isCoach=$_isCoach, clientIds=${_clientIds.length}個');

    final futures = <Future>[];

    // 1. 載入訓練計劃（分 Tab 1 和 Tab 2）
    futures.add(_loadTrainingPlans());

    // 2. Tab 1：如果有教練，載入所有教練的可上課時段
    if (_hasCoach && _coachIds.isNotEmpty) {
      // debugPrint('[BOOKING PAGE] ✅ 將載入 ${_coachIds.length} 位教練的可上課時段');
      futures.add(_loadCoachSlots());
    } else {
      // debugPrint(
      //     '[BOOKING PAGE] ⚠️ 跳過載入教練時段：hasCoach=$_hasCoach, coachIds=${_coachIds.length}個');
    }

    // 3. Tab 2：如果是教練，載入學員可訓練時段
    if (_isCoach && _clientIds.isNotEmpty) {
      // debugPrint('[BOOKING PAGE] ✅ 將載入學員可訓練時段');
      futures.add(_loadClientAvailability());
    } else {
      // debugPrint(
      //     '[BOOKING PAGE] ⚠️ 跳過載入學員時段：isCoach=$_isCoach, clientIds=${_clientIds.length}');
    }

    // 4. Tab 2：如果是教練，載入自己的可上課時段（從 Controller）
    if (_isCoach) {
      futures.add(_loadMySlots());
    }

    // 5. 載入預約數據（保留相容性）
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

      // 載入每個教練的時段
      for (final coachId in _coachIds) {
        // ⭐ v3.6: 透過 Controller 查詢
        final slots = await _slotController.getAvailableSlots(
          coachId: coachId,
          startDate: startDate,
          endDate: endDate,
        );

        for (var slot in slots) {
          // 只顯示未被預約的時段
          if (slot.isBooked) continue;

          final date = slot.slot.startTime;
          final day = DateTime(date.year, date.month, date.day);

          if (slotsByDate[day] == null) {
            slotsByDate[day] = [];
          }
          slotsByDate[day]!.add(slot);
        }
      }

      // if (bookedCount > 0) {
      //   debugPrint('[BOOKING PAGE]   ⚠️ 已過濾 $bookedCount 個已預約時段');
      // }

      if (mounted) {
        setState(() {
          _coachSlots = slotsByDate;
          _updateSelectedDayData();
        });
      }

      // debugPrint(
      //     '[BOOKING PAGE] ✅ 載入 ${_coachIds.length} 位教練時段完成，共 $totalSlots 個時段，可預約 ${slotsByDate.values.fold(0, (sum, list) => sum + list.length)} 個');
      // 顯示時段分佈
      // for (var entry in slotsByDate.entries) {
      //   debugPrint(
      //       '[BOOKING PAGE]   📅 ${entry.key}: ${entry.value.length} 個時段');
      // }
    } catch (e) {
      // debugPrint('[BOOKING PAGE] ❌ 載入教練時段失敗: $e');
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
      // ⭐ v3.6: 透過 Controller 查詢
      for (var clientId in _clientIds) {
        final availability =
            await _clientAvailabilityController.getClientAvailabilityForCoach(
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

      // debugPrint('[BOOKING PAGE] ✅ 載入學員可訓練時段完成，共 ${allAvailability.length} 天');
      // 顯示時段分佈
      // for (var entry in allAvailability.entries) {
      //   debugPrint(
      //       '[BOOKING PAGE]   📅 ${entry.key}: ${entry.value.length} 個時段');
      // }
    } catch (e) {
      // debugPrint('[BOOKING PAGE] ❌ 載入學員可訓練時段失敗: $e');
    }
  }

  /// ⭐ v3.9: 載入教練自己的可上課時段（Tab 1 顯示，避免重複創建）
  Future<void> _loadMySlots() async {
    final userId = _authController.user?.uid;
    if (userId == null) return;

    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 2, 0); // 載入兩個月

      // 透過 Controller 載入（帶預約狀態）
      final slots = await _slotController.getAvailableSlots(
        coachId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      // 按日期分組（過濾掉已被預約的時段）
      final slotsByDate = <DateTime, List<AvailabilitySlotWithBooking>>{};
      for (var slot in slots) {
        // ⭐ v3.9: 已被預約的不顯示
        if (slot.isBooked) continue;

        final date = slot.slot.startTime;
        final day = DateTime(date.year, date.month, date.day);

        if (slotsByDate[day] == null) {
          slotsByDate[day] = [];
        }
        slotsByDate[day]!.add(slot);
      }

      if (mounted) {
        setState(() {
          _mySlots = slotsByDate;
          _updateSelectedDayData();
        });
      }

      if (kDebugMode) {
        debugPrint('[BOOKING PAGE] ✅ 載入自己的時段完成，共 ${slots.length} 個時段');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BOOKING PAGE] ❌ 載入自己的時段失敗: $e');
      }
    }
  }

  // ⭐ v3.2: 當頁面變為可見時檢查 Coach Mark
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 當頁面變為當前頁面時，檢查 Coach Mark
    if (CurrentPageProvider.isCurrentPage(context, 1) && !_coachMarkShown) {
      _checkCoachMark();
    }
  }

  // ⭐ v3.2: 檢查是否顯示 Coach Mark
  Future<void> _checkCoachMark() async {
    if (_coachMarkShown) return;

    // ⭐ 檢查是否是當前頁面（BookingPage 是 index 1）
    if (!CurrentPageProvider.isCurrentPage(context, 1)) return;

    final onboardingService = serviceLocator<OnboardingService>();
    final shouldShow = await onboardingService.shouldShowCoachMark(
      OnboardingService.keyBookingPage,
    );

    if (shouldShow && mounted) {
      // 延遲顯示，確保 UI 已渲染
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && CurrentPageProvider.isCurrentPage(context, 1)) {
          _showCoachMark();
        }
      });
    }
  }

  // ⭐ v3.2: 顯示 Coach Mark 引導
  void _showCoachMark() {
    if (_coachMarkShown) return;
    _coachMarkShown = true;

    final targets = <TargetFocus>[];

    // 高亮 FAB（主要操作入口）
    if (_fabKey.currentContext != null) {
      targets.add(
        CoachMarkHelper.createTarget(
          key: _fabKey,
          title: '訓練行事曆',
          description: _isCoach
              ? '這裡顯示你的訓練計劃和教練可以上課的時段\n\n點擊「+」可以：\n• 新增訓練計劃\n• 設定可訓練時間\n\n切換「教練」Tab 可查看學員時段'
              : '這裡顯示你的訓練計劃和教練可以上課的時段\n\n點擊「+」可以：\n• 新增訓練計劃\n• 設定可訓練時間',
          contentAlign: ContentAlign.top,
        ),
      );
    }

    if (targets.isNotEmpty) {
      CoachMarkHelper.show(
        context: context,
        targets: targets,
      );
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _eventSubscription?.cancel(); // ⭐ v3.5
    _availabilitySubscription?.cancel(); // ⭐ v3.9
    // ⭐ v3.9: 取消所有 Realtime 訂閱
    _unsubscribeFromCoachSlotsRealtime();
    _unsubscribeFromClientAvailabilityRealtime();
    super.dispose();
  }

  /// ⭐ v3.9: 訂閱所有教練的時段 Realtime
  void _subscribeToCoachSlotsRealtime() {
    // 先清理舊訂閱
    _unsubscribeFromCoachSlotsRealtime();

    // 訂閱每個教練的時段
    for (final coachId in _coachIds) {
      final subscriptionId = _realtimeController.subscribeToCoachSlots(
        coachId: coachId,
        onUpdate: _onCoachSlotRealtimeUpdate,
      );
      _coachSlotSubscriptionIds.add(subscriptionId);
    }

    if (kDebugMode && _coachSlotSubscriptionIds.isNotEmpty) {
      debugPrint(
          '[BookingPage] 🔴 訂閱 ${_coachSlotSubscriptionIds.length} 個教練時段 Realtime');
    }
  }

  /// ⭐ v3.9: 取消所有教練時段 Realtime 訂閱
  void _unsubscribeFromCoachSlotsRealtime() {
    for (final id in _coachSlotSubscriptionIds) {
      _realtimeController.unsubscribe(id);
    }
    _coachSlotSubscriptionIds.clear();
  }

  /// ⭐ v3.9: 訂閱所有學員的可訓練時間 Realtime
  void _subscribeToClientAvailabilityRealtime() {
    // 先清理舊訂閱
    _unsubscribeFromClientAvailabilityRealtime();

    // 訂閱每個學員的可訓練時間
    for (final clientId in _clientIds) {
      final subscriptionId = _realtimeController.subscribeToClientAvailability(
        clientId: clientId,
        onUpdate: _onClientAvailabilityRealtimeUpdate,
      );
      _clientAvailabilitySubscriptionIds.add(subscriptionId);
    }

    if (kDebugMode && _clientAvailabilitySubscriptionIds.isNotEmpty) {
      debugPrint(
          '[BookingPage] 🔴 訂閱 ${_clientAvailabilitySubscriptionIds.length} 個學員可訓練時間 Realtime');
    }
  }

  /// ⭐ v3.9: 取消所有學員可訓練時間 Realtime 訂閱
  void _unsubscribeFromClientAvailabilityRealtime() {
    for (final id in _clientAvailabilitySubscriptionIds) {
      _realtimeController.unsubscribe(id);
    }
    _clientAvailabilitySubscriptionIds.clear();
  }

  /// ⭐ v3.9: 教練時段 Realtime 更新回調（INSERT 事件）
  void _onCoachSlotRealtimeUpdate() {
    if (!mounted) return;
    if (kDebugMode) {
      debugPrint('[BookingPage] ⚡ Realtime INSERT: 教練時段更新');
    }
    _loadCoachSlots();
  }

  /// ⭐ v3.9: 學員可訓練時間 Realtime 更新回調（INSERT/UPDATE 事件）
  void _onClientAvailabilityRealtimeUpdate() {
    if (!mounted) return;
    if (kDebugMode) {
      debugPrint('[BookingPage] ⚡ Realtime INSERT/UPDATE: 學員可訓練時間更新');
    }
    _loadClientAvailability();
  }

  /// ⭐ v3.9: EventBus 時段事件回調（DELETE 事件透過 EventBus - 增量處理）
  void _onAvailabilityEvent(AppEvent event) {
    if (!mounted) return;
    final userId = _authController.user?.uid;

    // 教練時段刪除事件 - 增量刪除
    if (event.type == AppEventType.availabilitySlotDeleted) {
      final deletedId = event.entityId;

      // 刪除「我的教練們」的時段（Tab 0）
      if (deletedId != null && _coachIds.contains(event.userId)) {
        if (kDebugMode) {
          debugPrint('[BookingPage] ⚡ EventBus DELETE: 教練時段刪除 id=$deletedId');
        }
        _removeCoachSlotById(deletedId);
      }

      // 刪除「我自己」的時段（Tab 1）
      if (deletedId != null && event.userId == userId) {
        if (kDebugMode) {
          debugPrint('[BookingPage] ⚡ EventBus DELETE: 我的時段刪除 id=$deletedId');
        }
        _removeMySlotById(deletedId);
      }
    }

    // 教練時段新增事件 - 重新載入
    if (event.type == AppEventType.availabilitySlotCreated) {
      // 我自己新增的時段（Tab 1）- 重新載入
      if (event.userId == userId && _isCoach) {
        if (kDebugMode) {
          debugPrint('[BookingPage] ⚡ EventBus INSERT: 我的時段新增');
        }
        _loadMySlots();
      }
      // 教練新增的時段（Tab 0）- 已有 Realtime 處理
    }

    // 學員可訓練時間刪除事件 - 增量刪除
    if (event.type == AppEventType.clientAvailabilityDeleted) {
      final deletedId = event.entityId;
      if (deletedId != null && _clientIds.contains(event.userId)) {
        if (kDebugMode) {
          debugPrint(
              '[BookingPage] ⚡ EventBus DELETE: 學員可訓練時間刪除 id=$deletedId');
        }
        _removeClientAvailabilityById(deletedId);
      }
    }
  }

  /// ⭐ v3.9: 增量刪除教練時段（Tab 0 用）
  void _removeCoachSlotById(String slotId) {
    bool removed = false;

    for (final date in _coachSlots.keys) {
      final slots = _coachSlots[date];
      if (slots != null) {
        final before = slots.length;
        slots.removeWhere((slot) => slot.slot.id == slotId);
        if (slots.length < before) {
          removed = true;
        }
      }
    }

    if (removed && mounted) {
      setState(() {
        _updateSelectedDayData();
      });
      if (kDebugMode) {
        debugPrint('[BookingPage] ✅ 增量刪除教練時段完成');
      }
    }
  }

  /// ⭐ v3.9: 增量刪除我自己的時段（Tab 1 用）
  void _removeMySlotById(String slotId) {
    bool removed = false;

    for (final date in _mySlots.keys) {
      final slots = _mySlots[date];
      if (slots != null) {
        final before = slots.length;
        slots.removeWhere((slot) => slot.slot.id == slotId);
        if (slots.length < before) {
          removed = true;
        }
      }
    }

    if (removed && mounted) {
      setState(() {
        _updateSelectedDayData();
      });
      if (kDebugMode) {
        debugPrint('[BookingPage] ✅ 增量刪除我的時段完成');
      }
    }
  }

  /// ⭐ v3.9: 增量刪除學員可訓練時間
  void _removeClientAvailabilityById(String availabilityId) {
    bool removed = false;

    for (final date in _clientAvailability.keys) {
      final availabilities = _clientAvailability[date];
      if (availabilities != null) {
        final before = availabilities.length;
        availabilities.removeWhere((a) => a.id == availabilityId);
        if (availabilities.length < before) {
          removed = true;
        }
      }
    }

    if (removed && mounted) {
      setState(() {
        _updateSelectedDayData();
      });
      if (kDebugMode) {
        debugPrint('[BookingPage] ✅ 增量刪除學員可訓練時間完成');
      }
    }
  }

  /// ⭐ v3.5: 處理 AppEventBus 事件
  void _onAppEvent(AppEvent event) {
    if (!mounted) {
      debugPrint('[BOOKING_PAGE] ⚠️ 頁面已 unmounted，忽略事件: ${event.type}');
      return;
    }

    debugPrint(
        '[BOOKING_PAGE] 📥 收到事件: ${event.type}, entityId: ${event.entityId}');

    // ⭐ 清除快取後再刷新（確保從資料庫讀取最新數據）
    // ⭐ v3.6: 透過 Controller 操作
    final userId = _authController.user?.uid;
    if (userId != null) {
      _workoutController.clearUserPlansCache(userId);
      debugPrint('[BOOKING_PAGE] 🧹 已清除用戶快取，準備重新載入...');
    }

    // 刷新行事曆數據
    _loadTrainingPlans();
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
    // debugPrint('[BOOKING PAGE] 🔄 重新載入數據（清除快取）');

    try {
      // 先清除當前用戶的訓練計劃快取
      // ⭐ v3.6: 透過 Controller 操作
      final userId = _authController.user?.uid;
      if (userId != null) {
        _workoutController.clearUserPlansCache(userId);
      }

      // ⭐ v3.1-B: 重新載入所有數據
      await _loadAllData();

      if (mounted) {
        NotificationUtils.showSuccess(context, '數據已更新');
      }
    } catch (e) {
      // debugPrint('[BOOKING PAGE] ❌ 重新載入失敗: $e');
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

      // debugPrint('[BOOKING PAGE] 從 WorkoutService 載入訓練計劃，userId: $userId');

      // ⚡ 優化：使用 WorkoutController 的快取和 limit 設定（較大值以獲取全部資料）
      // WorkoutService 內部有 3 小時快取機制，避免頻繁查詢資料庫
      // 必須確保傳入 userId，確保查詢的是當前用戶的訓練計劃
      // ⭐ v3.6: 透過 Controller 查詢
      final userPlans = await _workoutController.getUserPlans(
        userId: userId, // 必須確保用戶 ID
      );

      // debugPrint('[BOOKING PAGE] ✅ 查詢到 ${userPlans.length} 筆用戶訓練計劃');

      // ⭐ v3.1-B: 如果是教練，額外載入為學員創建的訓練計劃（Tab 2 用）
      // ⭐ v3.6: 透過 Controller 查詢
      List<WorkoutRecord> coachCreatedPlans = [];
      if (_isCoach && _clientIds.isNotEmpty) {
        coachCreatedPlans = await _workoutController.getCoachCreatedPlans(
          coachId: userId,
          clientIds: _clientIds,
          limit: 100,
        );
        // debugPrint('[BOOKING PAGE] ✅ 查詢到 ${coachCreatedPlans.length} 筆教練創建的計劃');
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

      // debugPrint('[BOOKING PAGE] ✅ 合併後共 ${plans.length} 筆訓練計劃');

      // ⭐ v3.1 修復：查詢「只有預約沒有訓練計畫」的課程
      // 收集已有訓練計畫的 appointment IDs
      final plansWithAppointment = plans
          .map((p) => p.appointmentId)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet();

      // Tab 1「我的」：查詢學員的已確認預約
      // ⭐ v3.6: 透過 Controller 查詢
      List<AppointmentModel> mySessionsWithoutPlan = [];
      final myAppointments = await _appointmentController.getClientAppointments(
        clientId: userId,
        status: AppointmentStatus.confirmed,
      );
      mySessionsWithoutPlan = myAppointments
          .where((a) => !plansWithAppointment.contains(a.id))
          .toList();
      // debugPrint(
      //     '[BOOKING PAGE] ✅ Tab1 沒有訓練計畫的預約：${mySessionsWithoutPlan.length} 筆');

      // Tab 2「教練」：查詢教練的已確認預約
      // ⭐ v3.6: 透過 Controller 查詢
      List<AppointmentModel> coachSessionsWithoutPlan = [];
      if (_isCoach) {
        final coachAppointments =
            await _appointmentController.getCoachAppointments(
          coachId: userId,
          status: AppointmentStatus.confirmed,
        );
        coachSessionsWithoutPlan = coachAppointments
            .where((a) => !plansWithAppointment.contains(a.id))
            .toList();
        // debugPrint(
        //     '[BOOKING PAGE] ✅ Tab2 沒有訓練計畫的預約：${coachSessionsWithoutPlan.length} 筆');
      }

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
        // debugPrint('[BOOKING PAGE] 📋 計劃 ${plan.id}: '
        //     'creator=$creatorId, trainee=$traineeId, appointmentId=${plan.appointmentId}, '
        //     'planType=$planType, isCoachSession=$isCoachSession');

        // ⭐ v3.1.1: 如果是上課類型，覆蓋標題為「XXX 的課程」格式
        if (planType == 'session') {
          // Tab 1「我的」視角（學員）：顯示教練名稱
          if (traineeId == userId) {
            final coachName = _coachNames[creatorId] ?? '教練';
            planData['title'] = '與 $coachName 的課程';
          }
        }

        if (isCoachSession) {
          // Tab 2「教練」視角：顯示學員名稱
          final studentName = _clientNames[traineeId] ?? '學員';
          planData['title'] = '$studentName 的課程';

          if (coachTrainings[day] == null) coachTrainings[day] = [];
          coachTrainings[day]!.add(planData);
        }
      }

      // ⭐ v3.1 修復：加入「只有預約沒有訓練計畫」的課程到 Tab 1
      for (var appointment in mySessionsWithoutPlan) {
        final day = DateTime(
          appointment.startTime.year,
          appointment.startTime.month,
          appointment.startTime.day,
        );

        final coachName = _coachNames[appointment.coachId] ?? '教練';
        final sessionData = _buildSessionOnlyData(
          appointment: appointment,
          displayName: coachName,
          isCoachView: false,
        );

        if (myTrainings[day] == null) myTrainings[day] = [];
        myTrainings[day]!.add(sessionData);

        // 也加入 allTrainings
        if (allTrainings[day] == null) allTrainings[day] = [];
        allTrainings[day]!.add(sessionData);
      }

      // ⭐ v3.1 修復：加入「只有預約沒有訓練計畫」的課程到 Tab 2
      for (var appointment in coachSessionsWithoutPlan) {
        final day = DateTime(
          appointment.startTime.year,
          appointment.startTime.month,
          appointment.startTime.day,
        );

        // 獲取學員名稱
        // ⭐ v3.6: 透過 ProfileController 查詢
        String studentName = '學員';
        try {
          final profile =
              await _profileController.getUserProfileById(appointment.clientId);
          studentName = profile?.displayName ?? profile?.email ?? '學員';
        } catch (e) {
          // debugPrint('[BOOKING PAGE] 載入學員資料失敗: ${appointment.clientId}');
        }

        final sessionData = _buildSessionOnlyData(
          appointment: appointment,
          displayName: studentName,
          isCoachView: true,
        );

        if (coachTrainings[day] == null) coachTrainings[day] = [];
        coachTrainings[day]!.add(sessionData);

        // 也加入 allTrainings
        if (allTrainings[day] == null) allTrainings[day] = [];
        allTrainings[day]!.add(sessionData);
      }

      if (!mounted) return;

      setState(() {
        _trainings = allTrainings;
        _myTrainings = myTrainings;
        _coachTrainings = coachTrainings;
        _updateSelectedDayData();
        _isLoading = false;
      });

      // debugPrint(
      //     '[BOOKING PAGE] ✅ 訓練計劃載入完成：Tab1=${myTrainings.length}天，Tab2=${coachTrainings.length}天');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // debugPrint('[BOOKING PAGE] 載入訓練計劃失敗: $e');
    }
  }

  /// ⭐ v3.1 修復：構建「只有預約沒有訓練計畫」的課程數據
  Map<String, dynamic> _buildSessionOnlyData({
    required AppointmentModel appointment,
    required String displayName,
    required bool isCoachView,
  }) {
    final timeStr =
        '${_formatTimeOnly(appointment.startTime)} - ${_formatTimeOnly(appointment.endTime)}';

    return {
      'id': 'session_${appointment.id}', // 使用 session_ 前綴區分
      'title': isCoachView ? '$displayName 的課程' : '與 $displayName 的課程',
      'description': '教練尚未建立訓練計畫',
      'scheduled_date': DateTimeUtils.formatToUtcIso(appointment.startTime),
      'trainingEndTime': DateTimeUtils.formatToUtcIso(appointment.endTime),
      'exercises': <Map<String, dynamic>>[],
      'completed': false,
      'planType': 'session',
      'trainee_id': appointment.clientId,
      'creator_id': appointment.coachId,
      'appointment_id': appointment.id,
      'dataType': 'session_only', // 標記為「只有預約」
      'isCoachView': isCoachView,
      'time_display': timeStr,
    };
  }

  /// 格式化時間（只顯示時:分）
  String _formatTimeOnly(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
    // ⭐ v3.9: 我自己的可上課時段
    _selectedDayMySlots = _mySlots[selectedDay] ?? [];

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

    // debugPrint('[BOOKING PAGE] 📅 更新選定日數據：$selectedDay');
    // debugPrint('[BOOKING PAGE]   - 我的訓練：${_selectedDayMyTrainings.length}');
    // debugPrint('[BOOKING PAGE]   - 教練時段：${_selectedDayCoachSlots.length}');
    // debugPrint(
    //     '[BOOKING PAGE]   - 教練Tab訓練：${_selectedDayCoachTrainings.length}');
    // debugPrint(
    //     '[BOOKING PAGE]   - 學員可訓練：${_selectedDayClientAvailability.length}');
    // 檢查 coachSlots 的 keys
    // if (_coachSlots.isNotEmpty) {
    //   debugPrint(
    //       '[BOOKING PAGE]   - coachSlots keys: ${_coachSlots.keys.toList()}');
    //   debugPrint(
    //       '[BOOKING PAGE]   - 查找 key: $selectedDay, 找到: ${_coachSlots.containsKey(selectedDay)}');
    // }
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

  // ⭐ v3.1.1: 設定可訓練時間（直接彈出對話框）
  Future<void> _setTrainableTime() async {
    final result = await showDialog<ClientAvailabilityModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AvailabilitySlotEditorDialog(
        selectedDate: _selectedDay, // 使用當前選中的日期
      ),
    );

    if (result != null && mounted) {
      try {
        // ⭐ v3.5: 透過 Controller 創建可訓練時段
        final created =
            await _clientAvailabilityController.createAvailability(result);
        if (!mounted) return;
        if (created != null) {
          NotificationUtils.showSuccess(context, '可訓練時段已新增');
          // 重新載入數據
          await _loadAllData();
        } else {
          NotificationUtils.showError(
              context, _clientAvailabilityController.errorMessage ?? '新增失敗');
        }
      } catch (e) {
        if (mounted) {
          NotificationUtils.showError(context, '新增失敗: $e');
        }
      }
    }
  }

  // ⭐ v3.1.1: 設定可上課時間（直接彈出對話框）
  Future<void> _setAvailableTime() async {
    final userId = _authController.user?.uid;
    if (userId == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuickAddSlotDialog(
        coachId: userId,
        selectedDate: _selectedDay, // 使用當前選中的日期
      ),
    );

    if (result == true && mounted) {
      NotificationUtils.showSuccess(context, '可上課時段已新增');
      // 創建成功後重新載入數據
      await _loadAllData();
    }
  }

  // ⭐ v3.1-B: 幫學員新增訓練（TODO: 需要選擇學員）
  void _createTrainingForStudent() {
    // TODO: 顯示學員選擇器，然後跳轉到 PlanEditorPage
    NotificationUtils.showInfo(context, '功能開發中：請先在學員詳情頁為學員新增訓練');
  }

  // ⭐ v3.1-B: 預約教練時段
  // ⭐ v3.5: MVVM 重構 - 透過 Controller 操作，事件由 Controller 自動發布
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

      // ⭐ v3.5: 透過 Controller 創建預約（Controller 會自動發布事件）
      final success =
          await _appointmentController.createAppointment(appointment);

      if (!success) {
        throw Exception(_appointmentController.errorMessage ?? '預約失敗');
      }

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
      // ⭐ v3.6: 透過 Controller 查詢
      final appointment =
          await _appointmentController.getAppointmentById(appointmentId);

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

      // ⭐ v3.1.1: 根據視角獲取對應名稱
      // 教練視角：顯示學員名稱
      // 學員視角：顯示教練名稱
      String displayName = '';
      if (isCoachMode) {
        // 教練視角：從 _clientNames 或重新查詢
        displayName = _clientNames[appointment.clientId] ?? '學員';
        if (displayName == '學員') {
          // 如果快取中沒有，嘗試重新查詢
          // ⭐ v3.6: 透過 Controller 查詢
          final clients = await _relationshipController
              .getCoachClientsWithRelationship(userId!);
          final client = clients
              .where((c) => c.user?.uid == appointment.clientId)
              .firstOrNull;
          displayName =
              client?.user?.displayName ?? client?.user?.email ?? '學員';
        }
      } else {
        // 學員視角：從 _coachNames 獲取教練名稱
        displayName = _coachNames[appointment.coachId] ?? '教練';
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionModePage(
            appointmentId: appointmentId,
            clientId: appointment.clientId,
            clientName: displayName, // ⭐ v3.1.1: 使用正確的名稱
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

    // debugPrint('[BOOKING PAGE] 編輯訓練計劃: $planId');

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
      // ⭐ v3.5: 透過 Controller 刪除訓練記錄（Controller 會自動發布事件）
      final success = await _workoutController.deleteRecord(planId);

      if (mounted) {
        if (success) {
          NotificationUtils.showSuccess(context, '訓練計畫已刪除');
        } else {
          NotificationUtils.showError(
              context, _workoutController.errorMessage ?? '刪除失敗，請稍後再試');
        }
        // 不需要手動 _loadTrainingPlans()，EventBus 會自動觸發刷新
      }
    } catch (e) {
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
      // ⭐ v3.1.1: SpeedDial（根據身份和 Tab 顯示不同選項）
      floatingActionButton: BookingSpeedDial(
        key: _fabKey, // ⭐ v3.2: Coach Mark 引導用
        onAddTraining: _createTrainingPlan,
        onSetTrainableTime: _hasCoach ? _setTrainableTime : null, // ⭐ 直接彈對話框
        onAddTrainingForStudent: _isCoach && _currentTabIndex == 1
            ? _createTrainingForStudent
            : null,
        onSetAvailableTime: _isCoach && _currentTabIndex == 1
            ? _setAvailableTime
            : null, // ⭐ 直接彈對話框
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
        // Tab 0：顯示「我的教練們」的可上課時段
        // Tab 1：顯示「我自己」的可上課時段（⭐ v3.9）
        coachSlots: isCoachTab ? _mySlots : _coachSlots,
        selectedDayCoachSlots:
            isCoachTab ? _selectedDayMySlots : _selectedDayCoachSlots,
        clientAvailability: isCoachTab ? _clientAvailability : null,
        selectedDayClientAvailability:
            isCoachTab ? _selectedDayClientAvailability : null,
        coachNames: _coachNames,
        clientNames: _clientNames, // ⭐ v3.1.1: 學員名稱映射
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
        // ⭐ v3.9: 我的時段操作回調
        onEditMySlot: _editMySlot,
        onDeleteMySlot: _deleteMySlot,
      ),
    );
  }

  // ⭐ v3.9: 編輯我的時段（彈出編輯對話框）
  Future<void> _editMySlot(AvailabilitySlotWithBooking slot) async {
    final userId = _authController.user?.uid;
    if (userId == null) return;

    // 彈出編輯對話框
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => QuickAddSlotDialog(
        coachId: userId,
        selectedDate: slot.slot.startTime,
        existingSlot: slot.slot, // ⭐ 傳入現有時段進入編輯模式
      ),
    );

    // EventBus 會自動刷新，但如果返回 true 也手動刷新一下
    if (result == true && mounted) {
      await _loadMySlots();
    }
  }

  // ⭐ v3.9: 刪除我的時段
  Future<void> _deleteMySlot(AvailabilitySlotWithBooking slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除時段'),
        content: Text(
          '確定要刪除 ${_formatTime(slot.slot.startTime)} - ${_formatTime(slot.slot.endTime)} 的時段嗎？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // 透過 Controller 刪除
        final success = await _slotController.deleteSlot(slot.slot.id);
        if (success && mounted) {
          NotificationUtils.showSuccess(context, '時段已刪除');
          // ⭐ v3.9: 立即執行增量刪除（不只依賴 EventBus）
          _removeMySlotById(slot.slot.id);
        } else if (mounted) {
          NotificationUtils.showError(
            context,
            _slotController.errorMessage ?? '刪除失敗',
          );
        }
      } catch (e) {
        if (mounted) {
          NotificationUtils.showError(context, '刪除失敗: $e');
        }
      }
    }
  }

  // 格式化時間
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
