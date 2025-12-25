import 'package:flutter/material.dart';
import '../../../models/workout_template_model.dart';
import '../../../models/workout_record_model.dart';
import '../../../controllers/interfaces/i_workout_controller.dart';
import '../../../controllers/interfaces/i_auth_controller.dart';
import '../../../services/interfaces/i_workout_service.dart';
import '../../../services/error_handling_service.dart';
import '../../../services/service_locator.dart';
import 'template_editor_page.dart';

class TemplateManagementPage extends StatefulWidget {
  const TemplateManagementPage({super.key});

  @override
  State<TemplateManagementPage> createState() => _TemplateManagementPageState();
}

class _TemplateManagementPageState extends State<TemplateManagementPage> {
  late final IWorkoutController _workoutController;
  late final IWorkoutService _workoutService;
  late final IAuthController _authController;
  late final ErrorHandlingService _errorService;

  List<WorkoutTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 從服務定位器獲取依賴
    _workoutController = serviceLocator<IWorkoutController>();
    _workoutService = serviceLocator<IWorkoutService>();
    _authController = serviceLocator<IAuthController>();
    _errorService = serviceLocator<ErrorHandlingService>();

    _loadTemplates();
  }

  /// 載入模板列表
  /// 
  /// [forceRefresh] 是否強制重新載入，忽略緩存（預設 false）
  Future<void> _loadTemplates({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 使用控制器加載模板
      final templates = forceRefresh 
          ? await _workoutController.reloadTemplates()  // 強制重新載入
          : await _workoutController.loadUserTemplates();  // 可能使用緩存

      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _errorService.handleError(context, e);
      }
    }
  }

  Future<void> _duplicateTemplate(WorkoutTemplate template) async {
    try {
      // 顯示輸入對話框讓用戶修改新模板的名稱
      TextEditingController titleController =
          TextEditingController(text: '${template.title} - 副本');
      final newTitle = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('複製模板'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: '新模板名稱',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, titleController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('確定'),
            ),
          ],
        ),
      );

      if (newTitle == null || newTitle.isEmpty) return;

      // 創建新模板的副本
      final newTemplate = template.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: newTitle,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 使用控制器創建模板
      await _workoutController.createTemplate(newTemplate);

      // 強制重新載入模板列表（忽略緩存）
      await _loadTemplates(forceRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('模板複製成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        _errorService.handleError(context, e);
      }
    }
  }

  Future<void> _deleteTemplate(String templateId) async {
    try {
      // 使用控制器刪除模板
      final success = await _workoutController.deleteTemplate(templateId);

      if (success) {
        setState(() {
          _templates.removeWhere((template) => template.id == templateId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('模板已刪除')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _errorService.handleError(context, e);
      }
    }
  }

  // 直接從模板創建訓練計畫
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('模板已更新'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _createWorkoutRecordFromTemplate(
      WorkoutTemplate template) async {
    try {
      // 獲取當前日期（僅日期部分）
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 顯示日期選擇器，只允許選擇當天及未來的日期
      final selectedDate = await showDatePicker(
        context: context,
        initialDate: today,
        firstDate: today, // 修改為從當天開始
        lastDate: today.add(const Duration(days: 30)),
      );

      if (selectedDate == null) return;

      // 獲取當前用戶 ID
      final userId = _authController.user?.uid;
      if (userId == null) {
        throw Exception('未登入');
      }

      print('[TemplateManagement] 從模板創建訓練: ${template.title}，日期: $selectedDate');
      
      // 使用 WorkoutService 創建記錄（但需要手動設置日期）
      // 先從模板創建，然後更新日期
      final record = await _workoutService.createRecordFromTemplate(template.id);
      
      // 更新日期
      final updatedRecord = WorkoutRecord(
        id: record.id,
        workoutPlanId: record.workoutPlanId,
        userId: userId,
        date: selectedDate,
        exerciseRecords: record.exerciseRecords,
        notes: record.notes,
        completed: false,
        createdAt: record.createdAt,
        trainingTime: record.trainingTime,
      );
      
      await _workoutService.updateRecord(updatedRecord);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${selectedDate.month}月${selectedDate.day}日的訓練已安排')),
        );
      }
    } catch (e) {
      print('[TemplateManagement] 從模板創建訓練失敗: $e');
      if (mounted) {
        _errorService.handleError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訓練計劃模板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('模板已創建'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            tooltip: '新建模板',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.note_alt_outlined,
                        size: 64,
                        color: Color(0xFF94A3B8), // Slate-400
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '還沒有保存的模板',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // 返回上一頁
                          Navigator.of(context).pop();
                        },
                        child: const Text('返回'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(template.title),
                        subtitle: Text(
                          '${template.planType} - ${template.exercises.length} 個動作',
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'create_record',
                              child: Row(
                                children: [
                                  Icon(Icons.fitness_center,
                                      color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('安排訓練'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('編輯'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'duplicate',
                              child: Row(
                                children: [
                                  Icon(Icons.copy),
                                  SizedBox(width: 8),
                                  Text('複製'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('刪除',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            switch (value) {
                              case 'create_record':
                                await _createWorkoutRecordFromTemplate(
                                    template);
                                break;
                              case 'edit':
                                await _editTemplate(template);
                                break;
                              case 'duplicate':
                                await _duplicateTemplate(template);
                                break;
                              case 'delete':
                                await _deleteTemplate(template.id);
                                break;
                            }
                          },
                        ),
                        onTap: () {
                          // 返回選擇的模板（用於創建訓練計劃）
                          Navigator.pop(context, template);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
