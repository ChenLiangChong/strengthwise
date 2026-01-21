import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/interfaces/i_body_data_controller.dart';
import '../../../../controllers/interfaces/i_auth_controller.dart';
import '../../../../controllers/interfaces/i_profile_controller.dart'; // ⭐ v3.6: MVVM
import '../../../../services/service_locator.dart';
import '../../profile/body_data_page.dart';

/// 身體數據 Tab 頁面
///
/// 顯示體重、體脂、BMI 等身體數據趨勢
class BodyDataTab extends StatefulWidget {
  /// 用戶 ID
  final String userId;

  const BodyDataTab({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<BodyDataTab> createState() => _BodyDataTabState();
}

class _BodyDataTabState extends State<BodyDataTab> {
  late final IBodyDataController _bodyDataController;
  late final IAuthController _authController;

  @override
  void initState() {
    super.initState();
    _bodyDataController = serviceLocator<IBodyDataController>();
    _authController = serviceLocator<IAuthController>();

    // ⭐ 使用 addPostFrameCallback 確保 context 已就緒
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _bodyDataController.loadRecords(widget.userId);
      }
    });
  }

  @override
  void didUpdateWidget(covariant BodyDataTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ⭐ 當 userId 變更時重新載入
    if (oldWidget.userId != widget.userId) {
      _bodyDataController.loadRecords(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⭐ 使用 .value 避免 dispose singleton（BodyDataController 是 LazySingleton）
    return ChangeNotifierProvider.value(
      value: _bodyDataController,
      child: Consumer<IBodyDataController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.monitor_weight_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '還沒有身體數據記錄',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '開始記錄體重、體脂等數據，追蹤身體變化',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BodyDataPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('新增記錄'),
                  ),
                ],
              ),
            );
          }

          // 有數據時，顯示簡化的趨勢
          final latest = controller.records.first;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 最新數據卡片
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '最新記錄 - ${_formatDate(latest.recordDate)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDataItem(
                                context,
                                '體重',
                                '${latest.weight.toStringAsFixed(1)} kg',
                                Icons.monitor_weight,
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            if (latest.bodyFat != null)
                              Expanded(
                                child: _buildDataItem(
                                  context,
                                  '體脂率',
                                  '${latest.bodyFat!.toStringAsFixed(1)}%',
                                  Icons.water_drop,
                                  Colors.orange,
                                ),
                              ),
                          ],
                        ),
                        if (latest.bmi != null || latest.muscleMass != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (latest.bmi != null)
                                Expanded(
                                  child: _buildDataItem(
                                    context,
                                    'BMI',
                                    latest.bmi!.toStringAsFixed(1),
                                    Icons.analytics,
                                    Colors.blue,
                                  ),
                                ),
                              if (latest.muscleMass != null)
                                Expanded(
                                  child: _buildDataItem(
                                    context,
                                    '肌肉量',
                                    '${latest.muscleMass!.toStringAsFixed(1)} kg',
                                    Icons.fitness_center,
                                    Colors.green,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 查看詳細記錄按鈕
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // ⭐ v3.6: MVVM 重構 - 透過 Controller 獲取
                      final profileController = serviceLocator<IProfileController>();
                      final userProfile =
                          await profileController.getCurrentUserProfile();

                      if (!context.mounted) return;

                      // 導航並等待返回
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BodyDataPage(userProfile: userProfile),
                        ),
                      );

                      // 返回後重新載入數據
                      final user = _authController.user;
                      if (user != null) {
                        controller.loadRecords(user.uid);
                      }
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('查看詳細記錄'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 構建數據項
  Widget _buildDataItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}
