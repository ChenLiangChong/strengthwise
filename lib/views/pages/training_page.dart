import 'package:flutter/material.dart';
import '../../models/workout_template_model.dart';
import '../../models/workout_record_model.dart';
import '../../controllers/interfaces/i_workout_controller.dart';
import '../../controllers/interfaces/i_auth_controller.dart';
import '../../services/interfaces/i_workout_service.dart';
import '../../services/error_handling_service.dart';
import '../../services/service_locator.dart';
import '../../utils/notification_utils.dart';
import 'workout/template_editor_page.dart';

/// 訓練模板管理中心
/// 
/// 功能：
/// - 顯示所有已保存的訓練模板
/// - 快速從模板創建訓練計劃
/// - 編輯和刪除模板
class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  late final IWorkoutController _workoutController;
  late final IWorkoutService _workoutService;
  late final IAuthController _authController;
  late final ErrorHandlingService _errorService;
  
  List<WorkoutTemplate> _templates = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _workoutController = serviceLocator<IWorkoutController>();
    _workoutService = serviceLocator<IWorkoutService>();
    _authController = serviceLocator<IAuthController>();
    _errorService = serviceLocator<ErrorHandlingService>();
    _loadTemplates();
  }
  
  /// 載入所有模板
  /// 載入模板列表
  /// 
  /// [forceRefresh] 是否強制重新載入，忽略緩存（預設 false）
  Future<void> _loadTemplates({bool forceRefresh = false}) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // 使用控制器加載模板
      final templates = forceRefresh 
          ? await _workoutController.reloadTemplates()  // 強制重新載入
          : await _workoutController.loadUserTemplates();  // 可能使用緩存
      
      if (mounted) {
        setState(() {
          _templates = templates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _errorService.handleError(context, e);
      }
    }
  }
  
  /// 從模板快速創建今日訓練
  Future<void> _createTodayPlanFromTemplate(WorkoutTemplate template) async {
    try {
      final userId = _authController.user?.uid;
      if (userId == null) {
        throw Exception('未登入');
      }
      
      print('[TrainingPage] 從模板創建今日訓練: ${template.title}');
      
      // 使用 WorkoutService 的 createRecordFromTemplate 方法
      await _workoutService.createRecordFromTemplate(template.id);
      
      if (mounted) {
        // 使用統一的成功通知（浮動，不會完全遮擋底部內容）
        NotificationUtils.showSuccess(
          context,
          '已創建今日訓練：${template.title}',
          onAction: () {
            // 切換到行事曆頁面
            DefaultTabController.of(context).animateTo(1); // 假設行事曆是第2個 tab
          },
          actionLabel: '查看',
        );
        
        // 可選：短暫延遲後自動跳轉到行事曆
        // 取消註解以啟用自動跳轉
        // Future.delayed(const Duration(milliseconds: 1500), () {
        //   if (mounted) {
        //     DefaultTabController.of(context).animateTo(1);
        //   }
        // });
      }
    } catch (e) {
      print('[TrainingPage] 創建今日訓練失敗: $e');
      if (mounted) {
        _errorService.handleError(context, e);
      }
    }
  }
  
  /// 從模板創建自訂日期的訓練
  Future<void> _createScheduledPlanFromTemplate(WorkoutTemplate template) async {
    try {
      final userId = _authController.user?.uid;
      if (userId == null) {
        throw Exception('未登入');
      }
      
      // 顯示日期選擇器
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final selectedDate = await showDatePicker(
        context: context,
        initialDate: today,
        firstDate: today,
        lastDate: today.add(const Duration(days: 90)),
        helpText: '選擇訓練日期',
      );
      
      if (selectedDate == null) return;
      
      print('[TrainingPage] 從模板創建訓練: ${template.title}，日期: $selectedDate');
      
      // 使用 WorkoutService 創建記錄（但需要手動設置日期）
      // 先從模板創建，然後更新日期
      final record = await _workoutService.createRecordFromTemplate(template.id);
      
      // 更新日期
      final updatedRecord = WorkoutRecord(
        id: record.id,
        workoutPlanId: record.workoutPlanId,
        userId: userId,
        title: record.title,
        date: selectedDate,
        exerciseRecords: record.exerciseRecords,
        notes: record.notes,
        completed: false,
        createdAt: record.createdAt,
        trainingTime: record.trainingTime,
      );
      
      await _workoutService.updateRecord(updatedRecord);
      
      if (mounted) {
        NotificationUtils.showSuccess(
          context,
          '已安排 ${selectedDate.month}/${selectedDate.day} 的訓練：${template.title}',
        );
      }
    } catch (e) {
      if (mounted) {
        _errorService.handleError(context, e);
      }
    }
  }
  
  /// 刪除模板
  /// 編輯模板
  Future<void> _editTemplate(WorkoutTemplate template) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateEditorPage(template: template),
      ),
    );

    if (result == true) {
      // 強制重新載入模板列表（忽略緩存）
      await _loadTemplates(forceRefresh: true);
      
      if (mounted) {
        NotificationUtils.showSuccess(context, '模板已更新');
      }
    }
  }
  
  Future<void> _deleteTemplate(WorkoutTemplate template) async {
    // 確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除模板'),
        content: Text('確定要刪除「${template.title}」嗎？'),
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
    
    if (confirmed != true) return;
    
    try {
      final success = await _workoutController.deleteTemplate(template.id);
      
      if (success) {
        setState(() {
          _templates.removeWhere((t) => t.id == template.id);
        });
        
        if (mounted) {
          NotificationUtils.showSuccess(context, '模板已刪除');
        }
      }
    } catch (e) {
      if (mounted) {
        _errorService.handleError(context, e);
      }
    }
  }
  
  /// 顯示模板操作選單
  void _showTemplateMenu(WorkoutTemplate template) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today, color: Colors.green),
              title: const Text('創建今日訓練'),
              onTap: () {
                Navigator.pop(context);
                _createTodayPlanFromTemplate(template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: const Text('選擇日期創建'),
              onTap: () {
                Navigator.pop(context);
                _createScheduledPlanFromTemplate(template);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('編輯模板'),
              onTap: () {
                Navigator.pop(context);
                _editTemplate(template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('刪除模板'),
              onTap: () {
                Navigator.pop(context);
                _deleteTemplate(template);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// 創建新模板
  Future<void> _createNewTemplate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TemplateEditorPage(),
      ),
    );
    
    if (result == true) {
      // 強制重新載入模板列表（忽略緩存）
      await _loadTemplates(forceRefresh: true);
      
      if (mounted) {
        NotificationUtils.showSuccess(context, '模板已創建');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訓練模板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTemplates,
            tooltip: '重新載入',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadTemplates,
                  child: _buildTemplateList(),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewTemplate,
        tooltip: '新模板',
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  /// 建構空狀態視圖
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            '還沒有訓練模板',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '創建模板後可以快速安排訓練',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _createNewTemplate,
            icon: const Icon(Icons.add),
            label: const Text('創建第一個模板'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 建構模板列表
  Widget _buildTemplateList() {
    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 96, // 增加底部填充，避免被 FAB 遮擋
      ),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];
        return _buildTemplateCard(template);
      },
    );
  }
  
  /// 建構模板卡片
  Widget _buildTemplateCard(WorkoutTemplate template) {
    final exerciseCount = template.exercises.length;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showTemplateMenu(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 圖標
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 標題和描述
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (template.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            template.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 更多按鈕
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showTemplateMenu(template),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 訓練類型和動作數量
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.category,
                    label: template.planType,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.format_list_numbered,
                    label: '$exerciseCount 個動作',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 快速操作按鈕
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _createTodayPlanFromTemplate(template),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('今日訓練'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _createScheduledPlanFromTemplate(template),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('選擇日期'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 建構信息標籤
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 