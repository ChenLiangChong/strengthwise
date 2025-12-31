import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/client_availability_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/models/client_availability_model.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/views/pages/availability/widgets/availability_slot_editor_dialog.dart';
import 'package:strengthwise/views/pages/availability/widgets/availability_calendar_view.dart';
import 'package:strengthwise/views/pages/availability/widgets/availability_list_item.dart';

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
  
  const ClientAvailabilityPage({
    Key? key,
    this.clientId,
    this.clientName,
    this.isViewMode = false,
  }) : super(key: key);

  @override
  State<ClientAvailabilityPage> createState() => _ClientAvailabilityPageState();
}

class _ClientAvailabilityPageState extends State<ClientAvailabilityPage> {
  late final ClientAvailabilityController _controller;
  late final IAuthController _authController;
  
  // 視圖模式
  bool _isCalendarView = true;
  
  // 篩選條件
  AvailabilityPriority? _filterPriority;

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<ClientAvailabilityController>();
    _authController = serviceLocator<IAuthController>();
    _loadAvailability();
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

  /// 新增時段
  Future<void> _addSlot() async {
    final result = await showDialog<ClientAvailabilityModel>(
      context: context,
      builder: (context) => const AvailabilitySlotEditorDialog(),
    );
    
    if (result != null) {
      await _controller.createAvailability(result);
      _loadAvailability();
    }
  }

  /// 編輯時段
  Future<void> _editSlot(ClientAvailabilityModel slot) async {
    final result = await showDialog<ClientAvailabilityModel>(
      context: context,
      builder: (context) => AvailabilitySlotEditorDialog(slot: slot),
    );
    
    if (result != null) {
      await _controller.updateAvailability(result);
      _loadAvailability();
    }
  }

  /// 刪除時段
  Future<void> _deleteSlot(ClientAvailabilityModel slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除時段'),
        content: const Text('確定要刪除此時段嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.deleteAvailability(slot.id);
      _loadAvailability();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isViewMode && widget.clientName != null
                ? '${widget.clientName} 的可訓練時間'
                : '我的可訓練時間',
          ),
          actions: [
            // 視圖切換
            IconButton(
              icon: Icon(_isCalendarView
                  ? Icons.list_outlined
                  : Icons.calendar_today_outlined),
              onPressed: () {
                setState(() => _isCalendarView = !_isCalendarView);
              },
              tooltip: _isCalendarView ? '列表視圖' : '日曆視圖',
            ),
            // 篩選
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: '篩選優先級',
              onSelected: (value) {
                setState(() {
                  if (value == 'all') {
                    _filterPriority = null;
                  } else {
                    _filterPriority = AvailabilityPriority.values
                        .firstWhere((e) => e.name == value);
                  }
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'all',
                  child: Text('全部'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'preferred',
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 8),
                      Text('首選時段'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'available',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text('可訓練'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'avoid',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text('避免'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Consumer<ClientAvailabilityController>(
          builder: (context, controller, child) {
            // 載入中
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
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

            // 空狀態
            if (slots.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _filterPriority == null
                          ? '還沒有設定可訓練時間'
                          : '沒有符合條件的時段',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '設定你的可訓練時間，讓教練更容易安排課程',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (_filterPriority == null)
                      ElevatedButton.icon(
                        onPressed: _addSlot,
                        icon: const Icon(Icons.add),
                        label: const Text('新增時段'),
                      ),
                  ],
                ),
              );
            }

            // 內容視圖
            return RefreshIndicator(
              onRefresh: _loadAvailability,
              child: _isCalendarView
                  ? AvailabilityCalendarView(
                      slots: slots,
                      onSlotTap: widget.isViewMode ? null : _editSlot,
                      onSlotDelete: widget.isViewMode ? null : _deleteSlot,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: slots.length,
                      itemBuilder: (context, index) {
                        final slot = slots[index];
                        return AvailabilityListItem(
                          slot: slot,
                          onTap: widget.isViewMode ? null : () => _editSlot(slot),
                          onDelete: widget.isViewMode ? null : () => _deleteSlot(slot),
                        );
                      },
                    ),
            );
          },
        ),
        floatingActionButton: widget.isViewMode
            ? null
            : FloatingActionButton(
                onPressed: _addSlot,
                tooltip: '新增時段',
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}

