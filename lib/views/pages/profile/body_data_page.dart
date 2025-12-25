import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../controllers/body_data_controller.dart';
import '../../../services/service_locator.dart';
import '../../../models/body_data_record.dart';
import '../../../models/user_model.dart';
import '../../../utils/notification_utils.dart';

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
                _buildLatestDataCard(controller.latestRecord!),
                const SizedBox(height: 16),
                // 體重趨勢圖表
                _buildWeightChart(controller.records),
                const SizedBox(height: 16),
                // BMI 趨勢圖表
                if (controller.records.any((r) => r.bmi != null))
                  _buildBMIChart(controller.records),
                const SizedBox(height: 16),
                // 歷史記錄列表
                _buildRecordsList(controller.records),
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

  /// 最新數據卡片
  Widget _buildLatestDataCard(BodyDataRecord record) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('最新記錄', style: textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDataItem(
                    icon: Icons.monitor_weight_outlined,
                    label: '體重',
                    value: '${record.weight.toStringAsFixed(1)} kg',
                    color: colorScheme.primary,
                  ),
                ),
                if (record.bodyFat != null)
                  Expanded(
                    child: _buildDataItem(
                      icon: Icons.water_drop_outlined,
                      label: '體脂率',
                      value: '${record.bodyFat!.toStringAsFixed(1)}%',
                      color: colorScheme.secondary,
                    ),
                  ),
              ],
            ),
            if (record.bmi != null || record.muscleMass != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (record.bmi != null)
                    Expanded(
                      child: _buildDataItem(
                        icon: Icons.straighten_outlined,
                        label: 'BMI',
                        value: record.bmi!.toStringAsFixed(1),
                        color: _getBMIColor(record.bmi!),
                        subtitle: record.getBMICategory(),
                      ),
                    ),
                  if (record.muscleMass != null)
                    Expanded(
                      child: _buildDataItem(
                        icon: Icons.fitness_center_outlined,
                        label: '肌肉量',
                        value: '${record.muscleMass!.toStringAsFixed(1)} kg',
                        color: colorScheme.tertiary,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 數據項目
  Widget _buildDataItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, style: textTheme.bodySmall?.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(value, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  /// 體重趨勢圖表
  Widget _buildWeightChart(List<BodyDataRecord> records) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 按日期升序排列
    final sortedRecords = List<BodyDataRecord>.from(records)
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

    final spots = sortedRecords
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.weight))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('體重趨勢', style: textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}kg', style: textTheme.bodySmall);
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// BMI 趨勢圖表
  Widget _buildBMIChart(List<BodyDataRecord> records) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final sortedRecords = List<BodyDataRecord>.from(records.where((r) => r.bmi != null))
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

    final spots = sortedRecords
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.bmi!))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BMI 趨勢', style: textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toStringAsFixed(1), style: textTheme.bodySmall);
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: colorScheme.secondary,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.secondary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 歷史記錄列表
  Widget _buildRecordsList(List<BodyDataRecord> records) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('歷史記錄', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final record = records[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${record.weight.toInt()}'),
                  ),
                  title: Text('${record.weight.toStringAsFixed(1)} kg'),
                  subtitle: Text(_formatDate(record.recordDate)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (record.bmi != null)
                        Chip(
                          label: Text('BMI ${record.bmi!.toStringAsFixed(1)}'),
                          backgroundColor: _getBMIColor(record.bmi!).withOpacity(0.2),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteRecord(record),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
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
      initialDateRange: DateTimeRange(start: _selectedStartDate, end: _selectedEndDate),
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

  /// 根據 BMI 值獲取顏色
  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 24) return Colors.green;
    if (bmi < 27) return Colors.orange;
    return Colors.red;
  }
}

