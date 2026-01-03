import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/controllers/availability_slot_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/models/availability_slot_model.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/slot_calendar_view.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/slot_editor_dialog.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/slot_filter_bar.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/error_state_view.dart';
import 'package:strengthwise/views/pages/scheduling/availability/copy_week_slots_mixin.dart';

/// 教練時段管理頁面（Phase 2）
///
/// 功能：
/// - 查看和管理教練的可用時段（日曆視圖）
/// - 創建單次時段或週期性時段
/// - 批量操作（複製週時段）
///
/// 架構：完全解耦（透過 serviceLocator + Controller + 小組件）
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

  String? _currentUserId;
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'all'; // all, recurring, oneTime

  @override
  void initState() {
    super.initState();
    _slotController = serviceLocator<AvailabilitySlotController>();
    _authController = serviceLocator<IAuthController>();
    _initializeAndLoad();
  }

  @override
  void dispose() {
    _slotController.clearAll();
    super.dispose();
  }

  // ==========================================================================
  // 數據載入與操作
  // ==========================================================================

  /// 初始化並載入數據
  Future<void> _initializeAndLoad() async {
    _currentUserId = _authController.user?.uid;

    // ⭐ Phase 4C: 使用 coachId（學員查看教練時段）或 currentUserId（教練管理自己的時段）
    final targetCoachId = widget.coachId ?? _currentUserId;

    if (targetCoachId != null) {
      await _loadSlots();
    } else {
      _showError('無法獲取教練 ID');
    }
  }

  /// 載入時段列表
  Future<void> _loadSlots() async {
    // ⭐ Phase 4C: 使用 coachId（學員查看教練時段）或 currentUserId（教練管理自己的時段）
    final targetCoachId = widget.coachId ?? _currentUserId;
    if (targetCoachId == null) return;

    if (_selectedFilter == 'all') {
      // 載入當月所有時段
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      await _slotController.loadCoachSlots(
        targetCoachId, // ⭐ 使用目標教練 ID
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      // 載入週期性或單次時段
      await _slotController.loadSlotsByType(targetCoachId); // ⭐ 使用目標教練 ID
    }
  }

  /// 顯示新增時段對話框（統一使用 QuickAddSlotDialog）
  /// 顯示新增/編輯時段對話框
  Future<void> _showSlotEditor({AvailabilitySlotModel? slot}) async {
    if (_currentUserId == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
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

  /// 複製本週時段到下一週
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
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
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
                onPressed: () => _showSlotEditor(),
                icon: const Icon(Icons.add),
                label: const Text('新增時段'),
              ),
        // ⭐ 修復：為 FAB 預留底部空間
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  /// 建立 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false, // ⭐ 移除返回按鈕（TabBar 子頁面不需要）
      title: const Text('時段管理'),
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

  /// 建立 Body
  Widget _buildBody() {
    return Consumer<AvailabilitySlotController>(
      builder: (context, controller, child) {
        // 載入中
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
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
            // 篩選器（只在有時段時顯示）
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
            // 內容區域
            Expanded(
              child: Padding(
                // ⭐ 修復：為日曆視圖添加底部 padding，避免被 FAB 遮擋
                padding: const EdgeInsets.only(bottom: 80),
                child: SlotCalendarView(
                  slots: _getFilteredSlots(controller),
                  selectedDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  onSlotTap: (slot) => _showSlotEditor(slot: slot),
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
