import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/service_locator.dart';
import '../../../controllers/availability_slot_controller.dart';
import '../../../controllers/interfaces/i_auth_controller.dart';
import '../../../models/availability_slot_model.dart';
import 'widgets/slot_calendar_view.dart';
import 'widgets/add_slot_dialog.dart';
import 'widgets/quick_add_slot_dialog.dart';
import 'widgets/slot_list_item.dart';
import 'widgets/slot_filter_bar.dart';
import 'widgets/empty_slot_state.dart';
import 'widgets/slot_details_sheet.dart';
import 'widgets/error_state_view.dart';

/// 教練時段管理頁面（Phase 2）
///
/// 功能：
/// - 查看和管理教練的可用時段
/// - 創建單次時段或週期性時段
/// - 批量操作（複製週時段、批量刪除）
/// - 日曆視圖和列表視圖切換
///
/// 架構：完全解耦（透過 serviceLocator + Controller + 小組件）
class CoachSlotsManagementPage extends StatefulWidget {
  const CoachSlotsManagementPage({super.key});

  @override
  State<CoachSlotsManagementPage> createState() =>
      _CoachSlotsManagementPageState();
}

class _CoachSlotsManagementPageState extends State<CoachSlotsManagementPage> {
  late final AvailabilitySlotController _slotController;
  late final IAuthController _authController;

  String? _currentUserId;
  bool _isCalendarView = true; // true: 日曆視圖, false: 列表視圖
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

    if (_currentUserId != null) {
      await _loadSlots();
    } else {
      _showError('無法獲取當前用戶 ID');
    }
  }

  /// 載入時段列表
  Future<void> _loadSlots() async {
    if (_currentUserId == null) return;

    if (_selectedFilter == 'all') {
      // 載入當月所有時段
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      await _slotController.loadCoachSlots(
        _currentUserId!,
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      // 載入週期性或單次時段
      await _slotController.loadSlotsByType(_currentUserId!);
    }
  }

  /// 顯示新增時段對話框
  Future<void> _showAddSlotDialog() async {
    if (_currentUserId == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddSlotDialog(
        coachId: _currentUserId!,
        initialDate: _selectedDate,
      ),
    );

    if (result == true && mounted) {
      _showSuccess('時段創建成功');
      await _loadSlots();
    }
  }

  /// 顯示快速新增時段對話框（點擊日曆日期）
  Future<void> _showQuickAddSlotDialog() async {
    if (_currentUserId == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => QuickAddSlotDialog(
        coachId: _currentUserId!,
        selectedDate: _selectedDate,
      ),
    );

    if (result == true && mounted) {
      _showSuccess('時段創建成功');
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
  Future<void> _copyWeekSlots() async {
    if (_currentUserId == null) return;

    final confirmed = await _showConfirmDialog(
      title: '複製週時段',
      content: '將本週的時段複製到下一週？',
      confirmText: '確認',
    );

    if (confirmed == true) {
      final now = DateTime.now();
      final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
      final nextWeekStart = thisWeekStart.add(const Duration(days: 7));

      final count = await _slotController.copyWeekSlots(
        coachId: _currentUserId!,
        sourceWeekStart: thisWeekStart,
        targetWeekStart: nextWeekStart,
      );

      if (mounted) {
        if (count > 0) {
          _showSuccess('已複製 $count 個時段到下週');
          await _loadSlots();
        } else {
          _showError('複製失敗或沒有時段可複製');
        }
      }
    }
  }

  /// 顯示時段詳情
  void _showSlotDetails(AvailabilitySlotModel slot) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SlotDetailsSheet(
        slot: slot,
        onDelete: () => _deleteSlot(slot.id),
      ),
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddSlotDialog,
          icon: const Icon(Icons.add),
          label: const Text('新增時段'),
        ),
      ),
    );
  }

  /// 建立 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('時段管理'),
      actions: [
        // 視圖切換按鈕
        IconButton(
          icon: Icon(_isCalendarView ? Icons.list : Icons.calendar_month),
          tooltip: _isCalendarView ? '列表視圖' : '日曆視圖',
          onPressed: () {
            setState(() {
              _isCalendarView = !_isCalendarView;
            });
          },
        ),
        // 複製週時段按鈕
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
              child: _isCalendarView
                  ? SlotCalendarView(
                      slots: _getFilteredSlots(controller),
                      selectedDate: _selectedDate,
                      onDateSelected: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      onSlotTap: _showSlotDetails,
                      onAddSlotForSelectedDate: _showQuickAddSlotDialog,
                    )
                  : (controller.slots.isEmpty
                      ? EmptySlotState(onAddSlot: _showAddSlotDialog)
                      : _buildListView(controller)),
            ),
          ],
        );
      },
    );
  }

  /// 建立列表視圖
  Widget _buildListView(AvailabilitySlotController controller) {
    final slots = _getFilteredSlots(controller);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        return SlotListItem(
          slot: slot,
          onTap: () => _showSlotDetails(slot),
          onDelete: () => _deleteSlot(slot.id),
        );
      },
    );
  }
}
