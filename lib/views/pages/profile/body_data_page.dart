import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../controllers/body_data_controller.dart';
import '../../../services/service_locator.dart';
import '../../../models/body_data_record.dart';
import '../../../models/user_model.dart';
import '../../../utils/notification_utils.dart';
import 'widgets/latest_body_data_card.dart';
import 'widgets/weight_trend_chart.dart';
import 'widgets/bmi_trend_chart.dart';
import 'widgets/body_data_records_list.dart';

/// 身體數據頁面
/// 顯示體重、體脂、BMI 等身體指標的歷史趨勢
class BodyDataPage extends StatefulWidget {
  final UserModel? userProfile;

  const BodyDataPage({super.key, this.userProfile});

  @override
  State<BodyDataPage> createState() => _BodyDataPageState();
}

class _BodyDataPageState extends State<BodyDataPage> {
  late final BodyDataController _controller;
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<BodyDataController>();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.userProfile != null) {
      await _controller.loadRecords(
        widget.userProfile!.uid,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ChangeNotifierProvider<BodyDataController>.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('身體數據'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showDateRangePicker,
              tooltip: '篩選日期範圍',
            ),
          ],
        ),
        body: Consumer<BodyDataController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                    const SizedBox(height: 16),
                    Text(controller.error!, style: textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('重試'),
                    ),
                  ],
                ),
              );
            }

            if (!controller.hasRecords) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monitor_weight_outlined, size: 64, color: colorScheme.outline),
                    const SizedBox(height: 16),
                    Text('尚未有身體數據記錄', style: textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('點擊下方按鈕開始記錄', style: textTheme.bodyMedium),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 最新數據卡片
                LatestBodyDataCard(record: controller.latestRecord!),
                const SizedBox(height: 16),
                // 體重趨勢圖表
                WeightTrendChart(records: controller.records),
                const SizedBox(height: 16),
                // BMI 趨勢圖表
                if (controller.records.any((r) => r.bmi != null))
                  BMITrendChart(records: controller.records),
                const SizedBox(height: 16),
                // 歷史記錄列表
                BodyDataRecordsList(
                  records: controller.records,
                  onDelete: _deleteRecord,
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddRecordDialog(),
          icon: const Icon(Icons.add),
          label: const Text('新增記錄'),
        ),
      ),
    );
  }


  /// 顯示新增記錄對話框
  Future<void> _showAddRecordDialog() async {
    if (widget.userProfile == null) return;

    final weightController = TextEditingController();
    final bodyFatController = TextEditingController();
    final muscleMassController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增身體數據'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: '體重 (kg)',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyFatController,
                decoration: const InputDecoration(
                  labelText: '體脂率 (%)',
                  prefixIcon: Icon(Icons.water_drop_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: muscleMassController,
                decoration: const InputDecoration(
                  labelText: '肌肉量 (kg)',
                  prefixIcon: Icon(Icons.fitness_center_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: '備註（選填）',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('新增'),
          ),
        ],
      ),
    );

    if (result == true && weightController.text.isNotEmpty) {
      final weight = double.tryParse(weightController.text);
      if (weight == null) {
        NotificationUtils.showError(context, '請輸入有效的體重數值');
        return;
      }

      final bodyFat = bodyFatController.text.isNotEmpty ? double.tryParse(bodyFatController.text) : null;
      final muscleMass = muscleMassController.text.isNotEmpty ? double.tryParse(muscleMassController.text) : null;

      final success = await _controller.createRecord(
        userId: widget.userProfile!.uid,
        recordDate: selectedDate,
        weight: weight,
        bodyFat: bodyFat,
        muscleMass: muscleMass,
        heightCm: widget.userProfile!.height,
        notes: notesController.text.isEmpty ? null : notesController.text,
      );

      if (mounted) {
        if (success) {
          HapticFeedback.lightImpact();
          NotificationUtils.showSuccess(context, '成功新增身體數據記錄');
        } else {
          NotificationUtils.showError(context, '新增記錄失敗');
        }
      }
    }

    weightController.dispose();
    bodyFatController.dispose();
    muscleMassController.dispose();
    notesController.dispose();
  }

  /// 刪除記錄
  Future<void> _deleteRecord(BodyDataRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除記錄'),
        content: Text('確定要刪除 ${_formatDate(record.recordDate)} 的記錄嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _controller.deleteRecord(record.id);
      if (mounted) {
        if (success) {
          HapticFeedback.heavyImpact();
          NotificationUtils.showSuccess(context, '已刪除記錄');
        } else {
          NotificationUtils.showError(context, '刪除記錄失敗');
        }
      }
    }
  }

  /// 顯示日期範圍選擇器
  Future<void> _showDateRangePicker() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          DateTimeRange(start: _selectedStartDate, end: _selectedEndDate),
    );

    if (dateRange != null) {
      setState(() {
        _selectedStartDate = dateRange.start;
        _selectedEndDate = dateRange.end;
      });
      _loadData();
    }
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}