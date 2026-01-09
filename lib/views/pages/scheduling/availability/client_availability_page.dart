// ✅ 已響應式改造 (Phase 0) - AvailabilityCalendarView 組件處理
// ✅ v3.2: Coach Mark 引導
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:strengthwise/controllers/client_availability_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/models/client_availability_model.dart';
import 'package:strengthwise/services/core/onboarding_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/views/pages/scheduling/availability/widgets/availability_slot_editor_dialog.dart';
import 'package:strengthwise/views/pages/scheduling/availability/widgets/availability_calendar_view.dart';
import 'package:strengthwise/views/pages/scheduling/availability/availability_app_bar_builder.dart';
import 'package:strengthwise/views/pages/scheduling/availability/availability_dialogs.dart';
import 'package:strengthwise/views/pages/scheduling/availability/copy_week_slots_mixin.dart';
import 'package:strengthwise/common_widgets/loading/skeleton_loader.dart';
import 'package:strengthwise/views/widgets/onboarding/coach_mark_helper.dart';

/// 學員時間偏好設定頁面
///
/// 功能：
/// - 學員設定可訓練時段
/// - 教練查看學員時間偏好（只讀模式）
/// - 使用 TSTZRANGE 時間範圍
/// - 支援優先級（preferred/available/avoid）
/// - 支援週期性時段（RRULE）
class ClientAvailabilityPage extends StatefulWidget {
  /// 學員 ID（可選）
  /// - 如果提供：查看指定學員的時間偏好（教練模式）
  /// - 如果為 null：查看當前用戶的時間偏好（學員模式）
  final String? clientId;

  /// 學員名稱（可選，用於顯示標題）
  final String? clientName;

  /// 是否為查看模式（只讀）
  final bool isViewMode;

  /// 是否顯示 AppBar（嵌入 Tab 時設為 false）
  final bool showAppBar;

  const ClientAvailabilityPage({
    Key? key,
    this.clientId,
    this.clientName,
    this.isViewMode = false,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  State<ClientAvailabilityPage> createState() => _ClientAvailabilityPageState();
}

class _ClientAvailabilityPageState extends State<ClientAvailabilityPage>
    with CopyWeekSlotsMixin {
  late final ClientAvailabilityController _controller;
  late final IAuthController _authController;

  // 篩選條件
  AvailabilityPriority? _filterPriority;

  // ⭐ 追蹤選中的日期
  DateTime _selectedDate = DateTime.now();

  // ⭐ v3.2: Coach Mark 引導
  final GlobalKey _fabKey = GlobalKey();
  bool _coachMarkShown = false;

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<ClientAvailabilityController>();
    _authController = serviceLocator<IAuthController>();
    _loadAvailability();

    // ⭐ v3.2: 檢查 Coach Mark（只在非查看模式下顯示）
    if (!widget.isViewMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkCoachMark();
      });
    }
  }

  // ⭐ v3.2: 檢查是否顯示 Coach Mark
  Future<void> _checkCoachMark() async {
    if (_coachMarkShown || widget.isViewMode) return;

    final onboardingService = serviceLocator<OnboardingService>();
    final shouldShow = await onboardingService.shouldShowCoachMark(
      OnboardingService.keyClientAvailability,
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
          title: '可訓練時間',
          description: '在這裡設定你方便訓練的時段\n\n教練可以看到你的時間偏好\n幫你安排訓練計畫',
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

  /// 載入可用時段
  Future<void> _loadAvailability() async {
    // 決定要查看誰的時間偏好
    final targetClientId = widget.clientId ?? _authController.user?.uid;
    if (targetClientId == null) return;

    await _controller.loadClientAvailabilities(
      clientId: targetClientId,
    );
  }

  /// 新增時段（指定日期）
  Future<void> _addSlotForDate(DateTime date) async {
    final result = await showDialog<ClientAvailabilityModel>(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
      builder: (context) => AvailabilitySlotEditorDialog(
        selectedDate: date, // ⭐ 必填參數
      ),
    );

    if (result != null) {
      await _controller.createAvailability(result);
      _loadAvailability();
    }
  }

  /// 新增時段（當前選中日期）
  Future<void> _addSlot() async {
    await _addSlotForDate(_selectedDate); // ⭐ 使用選中的日期
  }

  /// 編輯時段
  Future<void> _editSlot(ClientAvailabilityModel slot) async {
    final result = await showDialog<ClientAvailabilityModel>(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
      builder: (context) => AvailabilitySlotEditorDialog(
        slot: slot,
        selectedDate: slot.startTime, // ⭐ 使用時段的日期
      ),
    );

    if (result != null) {
      await _controller.updateAvailability(result);
      _loadAvailability();
    }
  }

  /// 刪除時段
  Future<void> _deleteSlot(ClientAvailabilityModel slot) async {
    final confirmed =
        await AvailabilityDialogs.showDeleteConfirmDialog(context);

    if (confirmed) {
      await _controller.deleteAvailability(slot.id);
      _loadAvailability();
    }
  }

  /// 複製週時段（使用 Mixin）
  Future<void> _copyWeekSlots() async {
    final targetClientId = widget.clientId ?? _authController.user?.uid;
    if (targetClientId == null) return;

    await copyWeekSlots(
      userId: targetClientId,
      copyOperation: ({
        required userId,
        required sourceWeekStart,
        required targetWeekStart,
      }) =>
          _controller.copyWeekAvailabilities(
        clientId: userId,
        sourceWeekStart: sourceWeekStart,
        targetWeekStart: targetWeekStart,
      ),
      onSuccess: _loadAvailability,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: widget.showAppBar
            ? AvailabilityAppBarBuilder.build(
                title: widget.isViewMode && widget.clientName != null
                    ? '${widget.clientName} 的可訓練時間'
                    : '我的可訓練時間',
                onCopyWeek: widget.isViewMode ? null : _copyWeekSlots,
                onRefresh: _loadAvailability,
                showCopyButton: !widget.isViewMode,
                filterOptions: const [
                  FilterOption(value: 'all', label: '全部'),
                  FilterOption(
                    value: 'preferred',
                    label: '首選時段',
                    icon: Icons.star,
                    iconColor: Colors.amber,
                  ),
                  FilterOption(
                    value: 'available',
                    label: '可訓練',
                    icon: Icons.check_circle,
                    iconColor: Colors.green,
                  ),
                  FilterOption(
                    value: 'avoid',
                    label: '避免',
                    icon: Icons.cancel,
                    iconColor: Colors.red,
                  ),
                ],
                onFilterChanged: (value) {
                  setState(() {
                    if (value == 'all') {
                      _filterPriority = null;
                    } else {
                      _filterPriority = AvailabilityPriority.values
                          .firstWhere((e) => e.name == value);
                    }
                  });
                },
              )
            : null, // ⭐ 嵌入 Tab 時不顯示 AppBar
        body: Consumer<ClientAvailabilityController>(
          builder: (context, controller, child) {
            // ⚡ 載入中使用骨架屏
            if (controller.isLoading) {
              return const SkeletonSlotCalendar();
            }

            // 錯誤
            if (controller.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64),
                    const SizedBox(height: 16),
                    Text(controller.errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAvailability,
                      child: const Text('重試'),
                    ),
                  ],
                ),
              );
            }

            // 過濾時段
            final slots = _filterPriority == null
                ? controller.availabilities
                : controller.availabilities
                    .where((s) => s.priority == _filterPriority)
                    .toList();

            // 始終顯示行事曆（即使沒有時段）
            return RefreshIndicator(
              onRefresh: _loadAvailability,
              child: AvailabilityCalendarView(
                slots: slots,
                onSlotTap: widget.isViewMode ? null : _editSlot,
                onSlotDelete: widget.isViewMode ? null : _deleteSlot,
                onDaySelected: (selectedDay) {
                  // ⭐ 追蹤選中日期
                  setState(() {
                    _selectedDate = selectedDay;
                  });
                },
              ),
            );
          },
        ),
        floatingActionButton: widget.isViewMode
            ? null
            : FloatingActionButton(
                key: _fabKey, // ⭐ v3.2: Coach Mark 引導用
                heroTag: 'client_availability_fab', // ⭐ 防止 Hero tag 衝突
                onPressed: _addSlot,
                tooltip: '新增時段',
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}
