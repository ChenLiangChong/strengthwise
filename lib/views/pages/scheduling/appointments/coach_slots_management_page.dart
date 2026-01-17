// ✅ 已響應式改造 (Phase 0) - SlotCalendarView 組件處理
// ✅ v3.2: Coach Mark 引導
// ✅ v3.9: Realtime + EventBus 訂閱（學員查看教練時段）
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/services/core/onboarding_service.dart';
import 'package:strengthwise/controllers/availability_slot_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/controllers/appointment_controller.dart';
import 'package:strengthwise/controllers/event_bus_controller.dart'; // ⭐ v3.5
import 'package:strengthwise/controllers/realtime_controller.dart'; // ⭐ v3.9
import 'package:strengthwise/services/core/app_event_bus.dart'; // ⭐ v3.9
import 'package:strengthwise/models/availability_slot_model.dart';
import 'package:strengthwise/models/appointment_model.dart';
import 'package:strengthwise/services/interfaces/i_availability_slot_service.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/slot_calendar_view.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/slot_editor_dialog.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/slot_filter_bar.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/error_state_view.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/client_booking/booking_confirmation_dialog.dart';
import 'package:strengthwise/views/pages/scheduling/availability/copy_week_slots_mixin.dart';
import 'package:strengthwise/common_widgets/loading/skeleton_loader.dart';
import 'package:strengthwise/views/widgets/onboarding/coach_mark_helper.dart';

/// 教練時段管理頁面（Phase 2）
///
/// 功能：
/// - 視覺化管理教練的可用時段（日曆視圖）
/// - 創建單次時段或週期性時段
/// - 快捷操作（複製週時段）
///
/// 架構：完全解耦，使用 serviceLocator + Controller + 小組件
class CoachSlotsManagementPage extends StatefulWidget {
  /// Phase 4C: 可選的教練 ID（學員查看特定教練的時段）
  final String? coachId;

  /// Phase 4C: 是否為查看模式（學員只能查看，不能編輯）
  final bool isViewMode;

  const CoachSlotsManagementPage({
    super.key,
    this.coachId,
    this.isViewMode = false,
  });

  @override
  State<CoachSlotsManagementPage> createState() =>
      _CoachSlotsManagementPageState();
}

class _CoachSlotsManagementPageState extends State<CoachSlotsManagementPage>
    with CopyWeekSlotsMixin {
  late final AvailabilitySlotController _slotController;
  late final IAuthController _authController;
  late final AppointmentController _appointmentController;
  late final EventBusController _eventBusController; // ⭐ v3.5
  late final RealtimeController _realtimeController; // ⭐ v3.9

  String? _currentUserId;
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'all'; // all, recurring, oneTime
  
  // ⭐ v3.2: Coach Mark 引導
  final GlobalKey _fabKey = GlobalKey();
  bool _coachMarkShown = false;
  
  // ⭐ v3.9: Realtime 訂閱 ID（學員查看教練時段時使用）
  String? _realtimeSubscriptionId;
  
  // ⭐ v3.9: EventBus 訂閱（DELETE 事件）
  StreamSubscription<AppEvent>? _availabilitySubscription;

  @override
  void initState() {
    super.initState();
    _slotController = serviceLocator<AvailabilitySlotController>();
    _authController = serviceLocator<IAuthController>();
    _appointmentController = serviceLocator<AppointmentController>();
    _eventBusController = serviceLocator<EventBusController>(); // ⭐ v3.5
    _realtimeController = serviceLocator<RealtimeController>(); // ⭐ v3.9
    _initializeAndLoad();
    
    // ⭐ v3.9: 學員查看教練時段 → 訂閱 Realtime + EventBus
    _subscribeRealtimeIfNeeded();
    _subscribeEventBusIfNeeded();
    
    // ⭐ v3.2: 檢查 Coach Mark 引導
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCoachMark();
    });
  }
  
  /// ⭐ v3.9: 如果是學員查看教練時段，訂閱 Realtime
  void _subscribeRealtimeIfNeeded() {
    // 只有學員查看模式（isViewMode=true 且有 coachId）才需要 Realtime
    if (widget.isViewMode && widget.coachId != null) {
      if (kDebugMode) {
        debugPrint('[CoachSlotsPage] 🔴 訂閱教練時段 Realtime: ${widget.coachId}');
      }
      _realtimeSubscriptionId = _realtimeController.subscribeToCoachSlots(
        coachId: widget.coachId!,
        onUpdate: _onRealtimeUpdate,
      );
    }
  }
  
  /// ⭐ v3.9: Realtime 更新回調（INSERT 事件）
  void _onRealtimeUpdate() {
    if (!mounted) return;
    if (kDebugMode) {
      debugPrint('[CoachSlotsPage] ⚡ Realtime INSERT: 教練時段更新');
    }
    _loadSlots();
  }
  
  /// ⭐ v3.9: 訂閱 EventBus（DELETE 事件）
  void _subscribeEventBusIfNeeded() {
    if (widget.isViewMode && widget.coachId != null) {
      _availabilitySubscription = _eventBusController.availabilityEvents.listen(_onAvailabilityEvent);
    }
  }
  
  /// ⭐ v3.9: EventBus 時段事件回調（DELETE 事件 - 增量刪除）
  void _onAvailabilityEvent(AppEvent event) {
    if (!mounted) return;
    
    if (event.type == AppEventType.availabilitySlotDeleted) {
      final deletedId = event.entityId;
      if (deletedId != null && event.userId == widget.coachId) {
        if (kDebugMode) {
          debugPrint('[CoachSlotsPage] ⚡ EventBus DELETE: 教練時段刪除 id=$deletedId');
        }
        // ⭐ v3.9: 增量刪除，不需要全量刷新
        _slotController.removeSlotById(deletedId);
      }
    }
  }
  
  // ⭐ v3.2: 檢查是否顯示 Coach Mark
  Future<void> _checkCoachMark() async {
    if (_coachMarkShown || widget.isViewMode) return;
    
    final onboardingService = serviceLocator<OnboardingService>();
    final shouldShow = await onboardingService.shouldShowCoachMark(
      OnboardingService.keyCoachSlots,
    );
    
    if (shouldShow && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showCoachMark();
      });
    }
  }
  
  // ⭐ v3.2: 顯示 Coach Mark 引導
  void _showCoachMark() {
    if (_coachMarkShown) return;
    _coachMarkShown = true;
    
    final targets = <TargetFocus>[];
    
    if (_fabKey.currentContext != null) {
      targets.add(
        CoachMarkHelper.createTarget(
          key: _fabKey,
          title: '可上課時段',
          description: '設定你可以上課的時間\n學員可以在這些時段預約',
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
    // ⭐ v3.9: 取消訂閱
    if (_realtimeSubscriptionId != null) {
      _realtimeController.unsubscribe(_realtimeSubscriptionId!);
    }
    _availabilitySubscription?.cancel();
    _slotController.clearAll();
    super.dispose();
  }

  // ==========================================================================
  // 資料載入邏輯
  // ==========================================================================

  /// 初始化並載入資料
  Future<void> _initializeAndLoad() async {
    _currentUserId = _authController.user?.uid;

    // ⭐ Phase 4C: 使用 coachId（學員查看教練時段）或 currentUserId（教練管理自己的時段）
    final targetCoachId = widget.coachId ?? _currentUserId;

    if (targetCoachId != null) {
      await _loadSlots();
    } else {
      _showError('找不到教練 ID');
    }
  }

  /// 載入時段列表
  Future<void> _loadSlots() async {
    // ⭐ Phase 4C: 使用 coachId（學員查看教練時段）或 currentUserId（教練管理自己的時段）
    final targetCoachId = widget.coachId ?? _currentUserId;
    if (targetCoachId == null) return;

    if (_selectedFilter == 'all') {
      // 載入所有時段
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      await _slotController.loadCoachSlots(
        targetCoachId, // 使用目標教練 ID
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      // 載入週期性或單次時段
      await _slotController.loadSlotsByType(targetCoachId); // 使用目標教練 ID
    }
  }

  /// 顯示新增時段對話框（統一使用 QuickAddSlotDialog）
  /// 顯示新增/編輯時段對話框
  Future<void> _showSlotEditor({AvailabilitySlotModel? slot}) async {
    if (_currentUserId == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 修復：禁止點擊旁邊關閉
      builder: (context) => SlotEditorDialog(
        coachId: _currentUserId!,
        slot: slot,
        selectedDate: slot?.startTime ?? _selectedDate,
      ),
    );

    if (result == true && mounted) {
      _showSuccess(slot == null ? '時段創建成功' : '時段更新成功');
      await _loadSlots();
    }
  }

  /// ⭐ 學員預約對話框（T-04 修復）
  Future<void> _showBookingDialog(AvailabilitySlotModel slot) async {
    if (_currentUserId == null || widget.coachId == null) return;

    // 將 AvailabilitySlotModel 轉換為 AvailabilitySlotWithBooking
    final slotWithBooking = AvailabilitySlotWithBooking(
      slot: slot,
      isBooked: false, // 學員點擊的都是可預約的時段
    );

    // 顯示預約確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BookingConfirmationDialog(
        slot: slotWithBooking,
        coachName: '教練', // TODO: 可從 widget 傳入教練名稱
      ),
    );

    if (confirmed == true && mounted) {
      await _createBooking(slot);
    }
  }

  /// ⭐ 創建預約（T-04 修復）
  Future<void> _createBooking(AvailabilitySlotModel slot) async {
    try {
      if (_currentUserId == null || widget.coachId == null) {
        throw Exception('未登入或未選擇教練');
      }

      final success = await _appointmentController.createAppointment(
        AppointmentModel(
          id: '', // 由後端生成
          coachId: widget.coachId!,
          clientId: _currentUserId!,
          startTime: slot.startTime,
          endTime: slot.endTime,
          status: AppointmentStatus.requested,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (mounted) {
        if (success) {
          // ⭐ v3.5: 發布預約創建事件（觸發首頁、行事曆自動刷新）
          _eventBusController.publishAppointmentCreated(
            appointmentId: '', // 實際 ID 由後端生成
            coachId: widget.coachId!,
            clientId: _currentUserId!,
          );
          _showSuccess('預約成功！等待教練確認');
          await _loadSlots();
        } else {
          _showError('預約失敗，請稍後再試');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('創建預約失敗：$e');
      }
    }
  }

  /// 刪除時段
  Future<void> _deleteSlot(String slotId) async {
    final confirmed = await _showConfirmDialog(
      title: '確認刪除',
      content: '確定要刪除這個時段嗎？',
      confirmText: '刪除',
      isDestructive: true,
    );

    if (confirmed == true) {
      final success = await _slotController.deleteSlot(slotId);
      if (success && mounted) {
        _showSuccess('時段已刪除');
      } else if (mounted && _slotController.errorMessage != null) {
        _showError(_slotController.errorMessage!);
      }
    }
  }

  /// 複製本週時段到下週
  /// 複製週時段（使用 Mixin）
  Future<void> _copyWeekSlots() async {
    if (_currentUserId == null) return;

    await copyWeekSlots(
      userId: _currentUserId!,
      copyOperation: ({
        required userId,
        required sourceWeekStart,
        required targetWeekStart,
      }) =>
          _slotController.copyWeekSlots(
        coachId: userId,
        sourceWeekStart: sourceWeekStart,
        targetWeekStart: targetWeekStart,
      ),
      onSuccess: _loadSlots,
    );
  }

  // ==========================================================================
  // UI 輔助方法
  // ==========================================================================

  /// 獲取篩選後的時段
  List<AvailabilitySlotModel> _getFilteredSlots(
      AvailabilitySlotController controller) {
    switch (_selectedFilter) {
      case 'recurring':
        return controller.recurringSlots;
      case 'oneTime':
        return controller.oneTimeSlots;
      default:
        return controller.slots;
    }
  }

  /// 顯示確認對話框
  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // 修復：禁止點擊旁邊關閉
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// 顯示錯誤訊息
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 顯示成功訊息
  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ==========================================================================
  // UI 構建
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AvailabilitySlotController>.value(
      value: _slotController,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: widget.isViewMode
            ? null
            : FloatingActionButton.extended(
                key: _fabKey, // ⭐ v3.2: Coach Mark 引導用
                heroTag: 'coach_slots_fab', // ⭐ 防止 Hero tag 衝突
                onPressed: () => _showSlotEditor(),
                icon: const Icon(Icons.add),
                label: const Text('新增時段'),
              ),
        // 修復：為 FAB 預留底部空間
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  /// 建構 AppBar
  /// ⭐ v3.1.1: 修復返回按鈕和標題顯示
  PreferredSizeWidget _buildAppBar() {
    // 標題根據模式不同
    final title = widget.isViewMode ? '教練可上課時段' : '設定可上課時段';

    return AppBar(
      // ⭐ 修復：讓系統自動顯示返回按鈕（當有 Navigator 堆疊時）
      automaticallyImplyLeading: true,
      title: Text(title),
      actions: [
        // 複製週時段按鈕
        if (!widget.isViewMode)
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: '複製週時段',
            onPressed: _copyWeekSlots,
          ),
        // 更多選單
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'refresh') {
              _loadSlots();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('重新載入'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 建構 Body
  Widget _buildBody() {
    return Consumer<AvailabilitySlotController>(
      builder: (context, controller, child) {
        // ⚡ 載入中使用骨架屏
        if (controller.isLoading) {
          return const SkeletonSlotCalendar();
        }

        // 錯誤狀態
        if (controller.errorMessage != null) {
          return ErrorStateView(
            errorMessage: controller.errorMessage!,
            onRetry: _loadSlots,
          );
        }

        // 顯示內容（無論是否有時段，都顯示日曆/列表視圖）
        return Column(
          children: [
            // 篩選欄（只在有時段時顯示）
            if (controller.slots.isNotEmpty) ...[
              SlotFilterBar(
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  _loadSlots();
                },
              ),
              const Divider(height: 1),
            ],
            // 內容區塊
            Expanded(
              child: Padding(
                // 修復：為日曆視圖添加底部 padding，避免被 FAB 遮擋
                padding: const EdgeInsets.only(bottom: 80),
                child: SlotCalendarView(
                  slots: _getFilteredSlots(controller),
                  selectedDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  // ⭐ T-04 修復：學員點擊時段顯示預約對話框，教練點擊顯示編輯對話框
                  onSlotTap: (slot) => widget.isViewMode
                      ? _showBookingDialog(slot)
                      : _showSlotEditor(slot: slot),
                  onSlotDelete: widget.isViewMode ? null : _deleteSlot,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
