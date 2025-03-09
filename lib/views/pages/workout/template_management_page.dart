import 'package:flutter/material.dart';
import '../../../models/workout_template_model.dart';
import '../../../controllers/interfaces/i_workout_controller.dart';
import '../../../services/error_handling_service.dart';
import '../../../services/service_locator.dart';

class TemplateManagementPage extends StatefulWidget {
  const TemplateManagementPage({super.key});

  @override
  State<TemplateManagementPage> createState() => _TemplateManagementPageState();
}

class _TemplateManagementPageState extends State<TemplateManagementPage> {
  late final IWorkoutController _workoutController;
  late final ErrorHandlingService _errorService;
  
  List<WorkoutTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // 從服務定位器獲取依賴
    _workoutController = serviceLocator<IWorkoutController>();
    _errorService = serviceLocator<ErrorHandlingService>();
    
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 使用控制器加載模板
      final templates = await _workoutController.loadUserTemplates();
      
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
      TextEditingController titleController = TextEditingController(text: '${template.title} - 副本');
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

      // 重新加載模板列表
      await _loadTemplates();

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

  // 直接從模板創建訓練記錄
  Future<void> _createWorkoutRecordFromTemplate(WorkoutTemplate template) async {
    try {
      // 獲取當前日期（僅日期部分）
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // 顯示日期選擇器，只允許選擇當天及未來的日期
      final selectedDate = await showDatePicker(
        context: context,
        initialDate: today,
        firstDate: today,  // 修改為從當天開始
        lastDate: today.add(const Duration(days: 30)),
      );
      
      if (selectedDate == null) return;
      
      // 使用控制器從模板創建訓練記錄
      // 首先創建包含日期的WorkoutRecord對象
      final record = await _workoutController.createRecordFromTemplate(template.id);
      
      // 使用特定日期更新記錄
      final updatedRecord = record.copyWith(
        date: selectedDate,
      );
      
      // 更新記錄
      await _workoutController.updateRecord(updatedRecord);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedDate.month}月${selectedDate.day}日的訓練已安排')),
        );
      }
    } catch (e) {
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
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '還沒有保存的模板',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
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
                                  Icon(Icons.fitness_center, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('安排訓練'),
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
                                  Text('刪除', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            switch (value) {
                              case 'create_record':
                                await _createWorkoutRecordFromTemplate(template);
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
                          // 返回選擇的模板
                          Navigator.pop(context, template);
                        },
                      ),
                    );
                  },
                ),
    );
  }
} 