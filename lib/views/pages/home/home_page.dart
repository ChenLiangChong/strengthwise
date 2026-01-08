// ✅ 已響應式改造 (Phase 0)
// ✅ Phase 3.1-B: 首頁 UX 優化（今日行程 + 我的學員 + 快捷按鈕 + 可折疊）
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_statistics_controller.dart';
import 'package:strengthwise/services/interfaces/i_workout_service.dart';
import 'package:strengthwise/services/interfaces/i_user_service.dart';
import 'package:strengthwise/services/interfaces/i_appointment_service.dart';
import 'package:strengthwise/services/interfaces/i_coaching_relationship_service.dart';
import 'package:strengthwise/models/user_model.dart';
import 'package:strengthwise/models/appointment_model.dart';
import 'package:strengthwise/models/workout_record/workout_record.dart';
import 'package:intl/intl.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/views/pages/workout/execution/workout_execution_page.dart';
import 'package:strengthwise/views/pages/statistics/statistics_page_v2.dart';
import 'package:strengthwise/views/pages/dev/notification_test_page.dart'; // 通知測試頁面
import 'package:strengthwise/common_widgets/cards/quick_rebook_card.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/client_booking_page.dart';
import 'package:strengthwise/views/pages/scheduling/booking/widgets/training_plan_card.dart';
import 'package:strengthwise/views/pages/session/session_mode_page.dart';
import 'package:strengthwise/views/pages/readiness/readiness_form_page.dart';
import 'package:strengthwise/utils/responsive/responsive.dart'; // ⭐ 響應式框架
// ⭐ Phase 3.1-B: 快捷按鈕和可折疊區塊
import 'package:strengthwise/views/widgets/quick_action_bar.dart';
import 'package:strengthwise/views/widgets/collapsible_section.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/coach_hub_page.dart';
import 'package:strengthwise/views/pages/relationships/role_client/client_hub_page.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/coach_slots_management_page.dart';
import 'package:strengthwise/views/pages/scheduling/availability/client_availability_page.dart';
import 'package:strengthwise/views/pages/workout/execution/plan_editor_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final IAuthController _authController;
  late final IWorkoutService _workoutService;
  late final IUserService _userService;
  late final IAppointmentService _appointmentService;
  late final ICoachingRelationshipService _coachingService;

  // ⭐ Phase 3.1-B: 使用 WorkoutRecord 取代 Map
  List<WorkoutRecord> _todayPlans = [];
  bool _isLoadingPlans = true;
  UserModel? _userProfile; // ⭐ 完整的用戶資料

  // ⭐ v3.0 一鍵續約相關
  AppointmentModel? _lastAppointment;
  UserModel? _lastCoach;
  bool _isLoadingRebook = true;

  // ⭐ Phase 3.1-B: 教練視角 - 我的學員今日課程
  List<AppointmentModel> _todayCoachSessions = [];
  Map<String, UserModel> _studentProfiles = {}; // studentId -> UserModel
  bool _isLoadingCoachSessions = true;

  // ⭐ Phase 3.1-B: 教練視角 - 待確認預約
  List<AppointmentModel> _pendingAppointments = [];
  bool _isLoadingPending = true;

  // ⭐ Phase 3.1-B: 是否有綁定教練（用於快捷按鈕）
  bool _hasCoach = false;

  @override
  void initState() {
    super.initState();
    _authController = serviceLocator<IAuthController>();
    _workoutService = serviceLocator<IWorkoutService>();
    _userService = serviceLocator<IUserService>();
    _coachingService = serviceLocator<ICoachingRelationshipService>();
    _appointmentService = serviceLocator<IAppointmentService>();

    // ⚡ 優先載入首頁關鍵數據，完成後才預載入其他
    _initializeHomePage();
  }

  /// ⚡ 初始化首頁（優先級策略）
  ///
  /// 1. 立即載入首頁必需數據（最近訓練 + 今日計劃 + 用戶資料）
  /// 2. 首頁數據完成後，背景預載入統計（不阻塞）
  Future<void> _initializeHomePage() async {
    // 步驟 1：並行載入首頁必需數據
    await _loadCriticalDataInParallel();

    // 步驟 2：背景預載入統計（完全不阻塞用戶操作）
    if (mounted) {
      _preloadStatistics();
    }
  }

  /// ⚡ 並行載入關鍵數據
  ///
  /// Phase 3.1-B: 移除最近訓練，新增教練視角數據
  Future<void> _loadCriticalDataInParallel() async {
    // 並行執行並等待完成
    await Future.wait([
      _loadUserProfile(), // ⭐ 載入用戶資料
      _loadTodayPlans(), // ⭐ 今日行程（作為學員）
      _loadQuickRebookData(), // ⭐ v3.0 一鍵續約資料
      _checkHasCoach(), // ⭐ Phase 3.1-B: 檢查是否有綁定教練
    ], eagerError: false);

    // ⭐ Phase 3.1-B: 用戶資料載入後，根據身份載入教練數據
    if (kDebugMode) {
      print('[HomePage] 🔍 檢查教練身份：isCoach = ${_userProfile?.isCoach}');
      print('[HomePage] 🔍 檢查是否有教練：hasCoach = $_hasCoach');
    }
    if (_userProfile?.isCoach == true) {
      if (kDebugMode) {
        print('[HomePage] ✅ 用戶是教練，開始載入教練數據...');
      }
      await Future.wait([
        _loadTodayCoachSessions(), // 今日要教的課
        _loadPendingAppointments(), // 待確認預約
      ], eagerError: false);
    } else {
      if (kDebugMode) {
        print('[HomePage] ⏭️ 用戶不是教練，跳過教練數據載入');
      }
    }

    if (kDebugMode) {
      print('[HomePage] ✅ 首頁關鍵數據載入完成');
    }
  }

  /// ⭐ Phase 3.1-B: 檢查用戶是否有綁定教練
  Future<void> _checkHasCoach() async {
    try {
      final userId = _authController.user?.uid;
      if (userId == null) return;

      final coaches = await _coachingService.getClientCoaches(
        userId,
        status: 'active',
      );

      if (mounted) {
        setState(() {
          _hasCoach = coaches.isNotEmpty;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('[HomePage] ⚠️ 檢查教練綁定失敗: $e');
      }
    }
  }

  /// ⚡ 背景預載入統計數據（所有時間範圍）
  ///
  /// 真機效能足夠，預載入所有時間範圍（本週、本月、三個月、本年）
  Future<void> _preloadStatistics() async {
    // ⚡ 真機優化：首頁數據完成後立即預載入所有時間範圍
    // 使用 microtask 確保在下一個事件循環執行
    Future.microtask(() async {
      try {
        final user = _authController.user;
        if (user == null) return;

        final statisticsController = serviceLocator<IStatisticsController>();

        // ⚡ 完整初始化：預載入所有時間範圍（本週、本月、三個月、本年）
        await statisticsController.initialize(user.uid);

        if (kDebugMode) {
          print('[HomePage] ✅ 統計數據預載入完成（所有時間範圍）');
        }
      } catch (e) {
        // 預載入失敗不影響主頁面
        if (kDebugMode) {
          print('[HomePage] ⚠️ 統計數據預載入失敗: $e');
        }
      }
    });
  }

  /// ⭐ 載入用戶完整資料
  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    try {
      final userId = _authController.user?.uid;
      if (userId == null) {
        print('[HomePage] 用戶未登入');
        return;
      }

      print('[HomePage] 查詢用戶資料，userId: $userId');

      // 使用 UserService 查詢完整的用戶資料
      final profile = await _userService.getUserProfile(userId);

      if (!mounted) return;

      setState(() {
        _userProfile = profile;
      });

      print('[HomePage] ✅ 用戶資料載入完成：${profile?.displayName ?? profile?.email}');
    } catch (e) {
      if (!mounted) return;
      print('[HomePage] 載入用戶資料失敗: $e');
    }
  }

  /// ⭐ v3.0 載入一鍵續約資料
  ///
  /// 檢查學員是否有最近的已完成預約，用於顯示一鍵續約卡片
  Future<void> _loadQuickRebookData() async {
    if (!mounted) return;

    setState(() => _isLoadingRebook = true);

    try {
      final userId = _authController.user?.uid;
      if (userId == null) {
        setState(() => _isLoadingRebook = false);
        return;
      }

      // 1. 檢查用戶是否為學員
      final profile = await _userService.getUserProfile(userId);
      if (profile == null || !profile.isStudent) {
        setState(() => _isLoadingRebook = false);
        return;
      }

      // 2. 查詢最近一次已完成的預約
      final lastAppointment =
          await _appointmentService.getLastCompletedAppointment(userId);

      if (lastAppointment == null) {
        setState(() => _isLoadingRebook = false);
        return;
      }

      // 3. 查詢教練資訊
      final coachProfile =
          await _userService.getUserProfile(lastAppointment.coachId);

      if (!mounted) return;

      setState(() {
        _lastAppointment = lastAppointment;
        _lastCoach = coachProfile;
        _isLoadingRebook = false;
      });

      if (kDebugMode) {
        print('[HomePage] ✅ 一鍵續約資料載入完成：教練=${coachProfile?.displayName}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRebook = false);
      if (kDebugMode) {
        print('[HomePage] ⚠️ 載入一鍵續約資料失敗: $e');
      }
    }
  }

  // ⭐ Phase 3.1-B: 移除 _loadRecentWorkouts，歷史記錄改到行事曆查看

  /// ⭐ Phase 3.1-B: 載入今日行程（作為學員的課程 + 自主訓練）
  Future<void> _loadTodayPlans() async {
    if (!mounted) return;

    setState(() {
      _isLoadingPlans = true;
    });

    try {
      final userId = _authController.user?.uid;
      if (userId == null) {
        print('[HomePage] 用戶未登入');
        setState(() {
          _todayPlans = [];
          _isLoadingPlans = false;
        });
        return;
      }

      print('[HomePage] 查詢今日行程，userId: $userId');

      // 計算今天的日期範圍（00:00 到 23:59）
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // ⭐ Phase 3.1-B: 查詢今天的訓練計畫（包含上課、自主訓練、教練安排）
      final plans = await _workoutService.getUserPlans(
        startDate: today,
        endDate: tomorrow,
      );

      print('[HomePage] 查詢到 ${plans.length} 個今日行程');

      if (!mounted) return;

      setState(() {
        _todayPlans = plans;
        _isLoadingPlans = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingPlans = false;
      });
      print('[HomePage] 載入今日行程失敗: $e');
    }
  }

  /// ⭐ Phase 3.1-B: 載入今日要教的課（教練視角）
  Future<void> _loadTodayCoachSessions() async {
    if (!mounted) return;

    setState(() {
      _isLoadingCoachSessions = true;
    });

    try {
      final userId = _authController.user?.uid;
      if (userId == null) {
        if (kDebugMode) {
          print('[HomePage] ⚠️ 無法載入教練課程：userId 為 null');
        }
        setState(() => _isLoadingCoachSessions = false);
        return;
      }

      // 計算今天的日期範圍
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      if (kDebugMode) {
        print('[HomePage] 🔍 查詢教練課程：coachId=$userId');
        print('[HomePage] 🔍 日期範圍：$today ~ $tomorrow');
      }

      // 查詢今日已確認的預約（教練視角）
      final appointments = await _appointmentService.getCoachAppointments(
        coachId: userId,
        startDate: today,
        endDate: tomorrow,
        status: AppointmentStatus.confirmed,
      );

      if (kDebugMode) {
        print('[HomePage] 🔍 查詢結果：${appointments.length} 筆已確認預約');
        for (final apt in appointments) {
          print('[HomePage]   - ${apt.id}: ${apt.startTime} ~ ${apt.endTime}, status=${apt.status}');
        }
      }

      // 也查詢所有狀態的預約（debug 用）
      if (kDebugMode) {
        final allAppointments = await _appointmentService.getCoachAppointments(
          coachId: userId,
          startDate: today,
          endDate: tomorrow,
        );
        print('[HomePage] 🔍 今日所有狀態預約：${allAppointments.length} 筆');
        for (final apt in allAppointments) {
          print('[HomePage]   - ${apt.id}: status=${apt.status}');
        }
      }

      // 收集所有學員 ID
      final studentIds = appointments.map((a) => a.clientId).toSet();

      // 批量查詢學員資料
      final profiles = <String, UserModel>{};
      for (final studentId in studentIds) {
        final profile = await _userService.getUserProfile(studentId);
        if (profile != null) {
          profiles[studentId] = profile;
        }
      }

      if (!mounted) return;

      setState(() {
        _todayCoachSessions = appointments;
        _studentProfiles = profiles;
        _isLoadingCoachSessions = false;
      });

      if (kDebugMode) {
        print('[HomePage] ✅ 載入今日要教的課：${appointments.length} 堂');
      }
    } catch (e, stack) {
      if (!mounted) return;
      setState(() => _isLoadingCoachSessions = false);
      if (kDebugMode) {
        print('[HomePage] ⚠️ 載入今日要教的課失敗: $e');
        print('[HomePage] ⚠️ Stack: $stack');
      }
    }
  }

  /// ⭐ Phase 3.1-B: 載入待確認預約（教練視角）
  Future<void> _loadPendingAppointments() async {
    if (!mounted) return;

    setState(() {
      _isLoadingPending = true;
    });

    try {
      final userId = _authController.user?.uid;
      if (userId == null) {
        setState(() => _isLoadingPending = false);
        return;
      }

      // 查詢待確認的預約（status = 'requested'）
      final appointments = await _appointmentService.getCoachAppointments(
        coachId: userId,
        status: AppointmentStatus.requested,
      );

      // 收集所有學員 ID（可能與 _loadTodayCoachSessions 重複，但不影響）
      for (final appointment in appointments) {
        if (!_studentProfiles.containsKey(appointment.clientId)) {
          final profile =
              await _userService.getUserProfile(appointment.clientId);
          if (profile != null) {
            _studentProfiles[appointment.clientId] = profile;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _pendingAppointments = appointments;
        _isLoadingPending = false;
      });

      if (kDebugMode) {
        print('[HomePage] ✅ 載入待確認預約：${appointments.length} 個');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPending = false);
      if (kDebugMode) {
        print('[HomePage] ⚠️ 載入待確認預約失敗: $e');
      }
    }
  }

  // 跳轉到訓練執行頁面
  Future<void> _navigateToPlan(String planId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutExecutionPage(
          workoutRecordId: planId,
        ),
      ),
    );

    if (result == true) {
      // 重新載入數據
      _loadTodayPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _userProfile ?? _authController.user; // ⭐ 優先使用完整資料
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final now = DateTime.now();
    final hour = now.hour;

    String greeting;
    if (hour < 12) {
      greeting = '早安';
    } else if (hour < 18) {
      greeting = '午安';
    } else {
      greeting = '晚安';
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // ⭐ 刷新時清除快取
          final userId = _authController.user?.uid;
          if (userId != null) {
            _workoutService.clearUserPlansCache(userId);
          }

          // ⭐ Phase 3.1-B: 刷新今日行程
          await _loadTodayPlans();

          // 教練額外刷新
          if (_userProfile?.isCoach == true) {
            await Future.wait([
              _loadTodayCoachSessions(),
              _loadPendingAppointments(),
            ]);
          }
        },
        child: CustomScrollView(
          slivers: [
            // SliverAppBar with gradient background
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: brightness == Brightness.light
                  ? colorScheme.primary // 淺色模式：藍色
                  : null, // 深色模式：使用預設深色背景
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(
                  left: context.spacing.md,
                  bottom: context.spacing.md,
                ),
                title: Text(
                  'Strength Wise',
                  style: context.responsive.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: brightness == Brightness.light
                          ? [
                              colorScheme.primary,
                              colorScheme.primary.withOpacity(0.8),
                            ]
                          : [
                              colorScheme.surface,
                              colorScheme.surface.withOpacity(0.95),
                            ],
                    ),
                  ),
                  // ⭐ 限制文字縮放上限，防止系統超大字體導致溢出
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(
                        MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.3),
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.spacing.md,
                          0,
                          context.spacing.md,
                          64, // 底部間距，避免被標題遮擋
                        ),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '$greeting，${user?.displayName ?? user?.nickname ?? '健身愛好者'}',
                                  style: context.responsive.greeting,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  DateFormat('yyyy年MM月dd日 EEEE', 'zh_TW').format(now),
                                  style: context.responsive.date,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                // 📊 訓練統計
                IconButton(
                  icon: const Icon(Icons.bar_chart, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatisticsPageV2(),
                      ),
                    );
                  },
                  tooltip: '訓練統計',
                ),
                // 🔔 通知測試頁面
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationTestPage(),
                      ),
                    );
                  },
                  tooltip: '通知測試',
                ),
              ],
            ),
            // ⭐ v3.0 一鍵續約卡片（學員專用）
            if (_shouldShowQuickRebook())
              SliverToBoxAdapter(
                child: _buildQuickRebookCard(),
              ),
            // ⭐ Phase 3.1-B: 快捷操作按鈕列
            SliverToBoxAdapter(
              child: _buildQuickActions(),
            ),
            // ⭐ Phase 3.1-B: 今日行程（可折疊）
            SliverToBoxAdapter(
              child: _buildTodayScheduleCollapsible(),
            ),
            // ⭐ Phase 3.1-B: 我的學員（教練視角，可折疊）
            if (_userProfile?.isCoach == true)
              SliverToBoxAdapter(
                child: _buildMyStudentsCollapsible(),
              ),
            // 底部填充，避免被底部導航遮擋
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 24),
            ),
          ],
        ),
      ),
    );
  }

  /// ⭐ Phase 3.1-B: 快捷操作按鈕列
  ///
  /// 按鈕順序：
  /// - 教練+學員+有教練：我的教練 → 我的學員 → 設可訓練 → 設可上課 → 新訓練 → 統計
  /// - 教練+學員+無教練：我的學員 → 設可上課 → 新訓練 → 統計
  /// - 學員+有教練：我的教練 → 設可訓練 → 新訓練 → 統計
  /// - 學員：新訓練 → 統計
  Widget _buildQuickActions() {
    final List<QuickAction> actions = [];
    final isCoach = _userProfile?.isCoach == true;

    // 有教練 → 顯示「我的教練」
    if (_hasCoach) {
      actions.add(QuickAction(
        icon: Icons.person,
        label: '我的教練',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ClientHubPage(),
          ),
        ),
      ));
    }

    // 是教練 → 顯示「我的學員」
    if (isCoach) {
      actions.add(QuickAction(
        icon: Icons.groups,
        label: '我的學員',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CoachHubPage(),
          ),
        ),
      ));
    }

    // 有教練 → 顯示「設可訓練」
    if (_hasCoach) {
      actions.add(QuickAction(
        icon: Icons.event_available,
        label: '設可訓練',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ClientAvailabilityPage(),
          ),
        ),
      ));
    }

    // 是教練 → 顯示「設可上課」
    if (isCoach) {
      actions.add(QuickAction(
        icon: Icons.schedule,
        label: '設可上課',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CoachSlotsManagementPage(),
          ),
        ),
      ));
    }

    // 基礎按鈕（所有人）- 放在最後
    actions.add(QuickAction(
      icon: Icons.add_circle_outline,
      label: '新訓練',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlanEditorPage(
            selectedDate: DateTime.now(),
          ),
        ),
      ),
    ));

    actions.add(QuickAction(
      icon: Icons.bar_chart,
      label: '統計',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const StatisticsPageV2(),
        ),
      ),
    ));

    return Container(
      padding: context.cardPadding,
      child: QuickActionBar(
        actions: actions,
        title: '⚡ 快捷操作',
      ),
    );
  }

  /// ⭐ Phase 3.1-B: 今日行程（可折疊版）
  Widget _buildTodayScheduleCollapsible() {
    return Container(
      padding: context.cardPadding,
      child: CollapsibleSection(
        title: '📚 今日行程',
        icon: Icons.today,
        initiallyExpanded: true,
        trailing: _isLoadingPlans
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : _todayPlans.isNotEmpty
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_todayPlans.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                : null,
        child: _buildTodayScheduleContent(),
      ),
    );
  }

  /// ⭐ Phase 3.1-B: 今日行程內容
  Widget _buildTodayScheduleContent() {
    if (_isLoadingPlans) {
      return _buildLoadingSkeleton();
    }

    if (_todayPlans.isEmpty) {
      return _buildNoPlansToday();
    }

    return Column(
      children: _todayPlans.map((record) {
        return _buildScheduleCard(record);
      }).toList(),
    );
  }

  /// ⭐ Phase 3.1-B: 我的學員（可折疊版）
  Widget _buildMyStudentsCollapsible() {
    final totalCount =
        _todayCoachSessions.length + _pendingAppointments.length;

    return Container(
      padding: context.cardPadding,
      child: CollapsibleSection(
        title: '🏋️ 我的學員',
        icon: Icons.groups,
        initiallyExpanded: true,
        trailing: _isLoadingCoachSessions
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : totalCount > 0
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  )
                : null,
        child: _buildMyStudentsContent(),
      ),
    );
  }

  /// ⭐ Phase 3.1-B: 我的學員內容
  Widget _buildMyStudentsContent() {
    if (_isLoadingCoachSessions) {
      return _buildLoadingSkeleton();
    }

    if (_todayCoachSessions.isEmpty && _pendingAppointments.isEmpty) {
      return _buildNoStudentSessions();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 今日課程
        ..._todayCoachSessions.map((appointment) {
          return _buildCoachSessionCard(appointment);
        }),

        // 待確認預約
        if (_pendingAppointments.isNotEmpty) ...[
          SizedBox(height: context.spacing.md),
          _buildPendingSection(),
        ],
      ],
    );
  }

  /// ⭐ Phase 3.1-B: 今日行程區塊（作為學員）- 舊版，保留相容
  Widget _buildTodaySchedule() {
    return Container(
      padding: context.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題行（含刷新按鈕）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📚 今日行程',
                style: context.responsive.sectionTitle,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  final userId = _authController.user?.uid;
                  if (userId != null) {
                    _workoutService.clearUserPlansCache(userId);
                  }
                  await _loadTodayPlans();
                },
                tooltip: '刷新',
              ),
            ],
          ),
          SizedBox(height: context.spacing.md),
          _isLoadingPlans
              ? _buildLoadingSkeleton()
              : _todayPlans.isEmpty
                  ? _buildNoPlansToday()
                  : Column(
                      children: _todayPlans.map((plan) {
                        return _buildScheduleCard(plan);
                      }).toList(),
                    ),
        ],
      ),
    );
  }

  /// ⭐ Phase 3.1-B: 構建行程卡片（複用 TrainingPlanCard）
  Widget _buildScheduleCard(WorkoutRecord plan) {
    final userId = _authController.user?.uid;
    final hasAppointment =
        plan.appointmentId != null && plan.appointmentId!.isNotEmpty;

    // 判斷是否為上課（有 appointmentId）
    final isSession = hasAppointment;

    // 判斷是否顯示填問卷按鈕（課前 1 小時內）
    final showReadinessButton = isSession && _isWithinOneHourBefore(plan.date);

    // 轉換為 TrainingPlanCard 需要的 Map 格式
    final trainingData = {
      'id': plan.id,
      'title': plan.title,
      'description': plan.notes,
      'scheduled_date': plan.date.toIso8601String(),
      'exercises': plan.exerciseRecords
          .map((e) => {
                'exerciseName': e.exerciseName,
                'sets': e.sets.length,
                'completed': e.completed,
              })
          .toList(),
      'completed': plan.completed,
      'trainee_id': plan.traineeId ?? plan.userId,
      'creator_id': plan.creatorId,
      'appointment_id': plan.appointmentId,
      'isCoachView': false, // 學員視角
    };

    return TrainingPlanCard(
      training: trainingData,
      currentUserId: userId,
      // 上課類型：進入 Session Mode
      onEnterSession: isSession
          ? (planId, appointmentId) {
              _navigateToSession(planId, appointmentId, isCoachView: false);
            }
          : null,
      // 填問卷按鈕
      onFillReadiness: isSession
          ? (appointmentId) {
              _navigateToReadinessForm(appointmentId);
            }
          : null,
      showReadinessButton: showReadinessButton,
      // 自主訓練/教練安排：執行訓練
      onExecute: !isSession ? (planId) => _navigateToPlan(planId) : null,
      onEdit: (planId, date) {
        // TODO: 編輯訓練計畫
      },
      onDelete: (planId, title) {
        // TODO: 刪除訓練計畫
      },
    );
  }

  /// ⭐ Phase 3.1-B: 我的學員區塊（教練視角）
  Widget _buildMyStudentsSection() {
    return Container(
      padding: context.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Text(
            '🏋️ 我的學員',
            style: context.responsive.sectionTitle,
          ),
          SizedBox(height: context.spacing.md),

          // 今日要教的課
          if (_isLoadingCoachSessions)
            _buildLoadingSkeleton()
          else if (_todayCoachSessions.isEmpty && _pendingAppointments.isEmpty)
            _buildNoStudentSessions()
          else ...[
            // 今日課程
            ..._todayCoachSessions.map((appointment) {
              return _buildCoachSessionCard(appointment);
            }),

            // 待確認預約
            if (_pendingAppointments.isNotEmpty) ...[
              SizedBox(height: context.spacing.md),
              _buildPendingSection(),
            ],
          ],
        ],
      ),
    );
  }

  /// ⭐ Phase 3.1-B: 教練的課程卡片
  Widget _buildCoachSessionCard(AppointmentModel appointment) {
    final student = _studentProfiles[appointment.clientId];
    final studentName = student?.displayName ?? student?.email ?? '學員';

    // 查詢對應的訓練計畫
    // TODO: 需要關聯 appointment -> workout_plan

    return Card(
      margin: EdgeInsets.only(bottom: context.spacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          studentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}',
        ),
        trailing: FilledButton(
          onPressed: () {
            // 跳轉到 Session Mode（教練視角）
            _navigateToSessionByAppointment(appointment, isCoachView: true);
          },
          child: const Text('開始課程'),
        ),
      ),
    );
  }

  /// ⭐ Phase 3.1-B: 待確認預約區塊
  Widget _buildPendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.schedule, size: 18),
            const SizedBox(width: 4),
            Text(
              '待確認 (${_pendingAppointments.length})',
              style: context.responsive.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacing.sm),
        ..._pendingAppointments.map((appointment) {
          return _buildPendingCard(appointment);
        }),
      ],
    );
  }

  /// ⭐ Phase 3.1-B: 待確認預約卡片（inline 確認/拒絕）
  Widget _buildPendingCard(AppointmentModel appointment) {
    final student = _studentProfiles[appointment.clientId];
    final studentName = student?.displayName ?? student?.email ?? '學員';
    final dateStr = DateFormat('MM/dd HH:mm').format(appointment.startTime);

    return Card(
      margin: EdgeInsets.only(bottom: context.spacing.xs),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.md,
          vertical: context.spacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    dateStr,
                    style: context.responsive.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // 拒絕按鈕
            IconButton(
              icon: const Icon(Icons.close),
              color: Theme.of(context).colorScheme.error,
              onPressed: () => _rejectAppointment(appointment),
              tooltip: '拒絕',
            ),
            // 確認按鈕
            IconButton(
              icon: const Icon(Icons.check),
              color: Theme.of(context).colorScheme.primary,
              onPressed: () => _confirmAppointment(appointment),
              tooltip: '確認',
            ),
          ],
        ),
      ),
    );
  }

  /// 確認預約
  Future<void> _confirmAppointment(AppointmentModel appointment) async {
    try {
      await _appointmentService.confirmAppointment(appointment.id);
      // 刷新列表
      await _loadPendingAppointments();
      await _loadTodayCoachSessions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已確認預約')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('確認失敗: $e')),
        );
      }
    }
  }

  /// 拒絕預約
  Future<void> _rejectAppointment(AppointmentModel appointment) async {
    // 顯示確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('拒絕預約'),
        content: const Text('確定要拒絕此預約嗎？'),
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
            child: const Text('拒絕'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 使用 cancelAppointment 取消預約（拒絕 = 取消）
      final userId = _authController.user?.uid ?? '';
      await _appointmentService.cancelAppointment(
        appointmentId: appointment.id,
        cancelledBy: userId,
        reason: '教練拒絕預約',
      );
      // 刷新列表
      await _loadPendingAppointments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已拒絕預約')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拒絕失敗: $e')),
        );
      }
    }
  }

  /// 判斷是否在課前 1 小時內
  bool _isWithinOneHourBefore(DateTime scheduledDate) {
    final now = DateTime.now();
    final oneHourBefore = scheduledDate.subtract(const Duration(hours: 1));
    return now.isAfter(oneHourBefore) && now.isBefore(scheduledDate);
  }

  /// 格式化時間
  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// 跳轉到 Session Mode
  void _navigateToSession(String planId, String? appointmentId,
      {required bool isCoachView}) {
    if (appointmentId == null) return;

    // 需要查詢預約詳情來獲取必要參數
    _navigateToSessionByAppointmentId(appointmentId, isCoachView: isCoachView);
  }

  /// 通過預約 ID 跳轉到 Session Mode
  Future<void> _navigateToSessionByAppointmentId(String appointmentId,
      {required bool isCoachView}) async {
    try {
      final appointment =
          await _appointmentService.getAppointmentById(appointmentId);
      if (appointment == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('找不到預約資訊')),
          );
        }
        return;
      }

      _navigateToSessionByAppointment(appointment, isCoachView: isCoachView);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入失敗: $e')),
        );
      }
    }
  }

  /// 通過預約跳轉到 Session Mode
  void _navigateToSessionByAppointment(AppointmentModel appointment,
      {required bool isCoachView}) {
    final student = _studentProfiles[appointment.clientId];
    final studentName = student?.displayName ?? student?.email ?? '學員';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionModePage(
          appointmentId: appointment.id,
          clientId: appointment.clientId,
          clientName: studentName,
          sessionStartTime: appointment.startTime,
          sessionEndTime: appointment.endTime,
          isCoachMode: isCoachView,
        ),
      ),
    );
  }

  /// 跳轉到填問卷頁面
  void _navigateToReadinessForm(String? appointmentId) {
    if (appointmentId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadinessFormPage(
          appointmentId: appointmentId,
        ),
      ),
    );
  }

  /// 無學員課程的空狀態
  Widget _buildNoStudentSessions() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.spacing.lg),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          SizedBox(height: context.spacing.md),
          Text(
            '今天沒有要教的課',
            style: context.responsive.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// ⚡ 骨架屏（Loading 狀態）
  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(2, (index) {
        return Container(
          margin: EdgeInsets.only(bottom: context.spacing.sm + 4), // 12dp
          padding: context.cardPadding,
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題骨架
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: context.spacing.sm + 4), // 12dp
              // 內容骨架
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: context.spacing.sm),
              Container(
                width: 200,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// ⭐ v3.0 是否應該顯示一鍵續約卡片
  bool _shouldShowQuickRebook() {
    // 載入中不顯示
    if (_isLoadingRebook) return false;
    // 沒有最近預約不顯示
    if (_lastAppointment == null) return false;
    // 沒有教練資訊不顯示
    if (_lastCoach == null) return false;
    // 用戶必須是學員
    if (_userProfile == null) return false;
    if (!_userProfile!.isStudent) return false;
    return true;
  }

  /// ⭐ v3.0 構建一鍵續約卡片
  Widget _buildQuickRebookCard() {
    if (_lastAppointment == null || _lastCoach == null) {
      return const SizedBox.shrink();
    }

    // 從最近預約中提取偏好時段
    final startTime = _lastAppointment!.startTime;
    final preferredTime = TimeOfDay.fromDateTime(startTime);
    final dayOfWeek = startTime.weekday;

    final lastBooking = LastBookingInfo(
      coachId: _lastAppointment!.coachId,
      coachName: _lastCoach!.displayName ?? _lastCoach!.email,
      coachPhotoUrl: _lastCoach!.photoURL,
      preferredTime: preferredTime,
      durationMinutes: _lastAppointment!.endTime
          .difference(_lastAppointment!.startTime)
          .inMinutes,
      dayOfWeek: dayOfWeek,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.md,
        context.spacing.md,
        context.spacing.md,
        0,
      ),
      child: QuickRebookCard(
        lastBooking: lastBooking,
        onRebook: (suggestedDate, time) {
          // 跳轉到預約頁面
          // TODO: 未來可擴展 ClientBookingPage 支援預選教練和時段
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ClientBookingPage(),
            ),
          );
        },
        onViewMore: () {
          // 跳轉到預約頁面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ClientBookingPage(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoPlansToday() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.spacing.lg),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          SizedBox(height: context.spacing.md),
          Text(
            '今天還沒有安排訓練',
            style: context.responsive.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ⭐ Phase 3.1-B: 移除 _buildTodayPlanCard，改用 _buildScheduleCard（複用 TrainingPlanCard）
  // ⭐ Phase 3.1-B: 移除 _buildRecentWorkouts，歷史記錄改到行事曆查看
}
