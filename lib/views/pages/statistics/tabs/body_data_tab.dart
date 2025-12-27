import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/body_data_controller.dart';
import '../../../../controllers/interfaces/i_auth_controller.dart';
import '../../../../services/service_locator.dart';
import '../../../../services/interfaces/i_user_service.dart';
import '../../profile/body_data_page.dart';

/// 身體數據 Tab 頁面
///
/// 顯示體重、體脂、BMI 等身體數據趨勢
class BodyDataTab extends StatelessWidget {
  /// 用戶 ID
  final String userId;

  const BodyDataTab({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = serviceLocator<IAuthController>();
    
    return ChangeNotifierProvider(
      create: (_) =>
          serviceLocator<BodyDataController>()..loadRecords(userId),
      child: Consumer<BodyDataController>(
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
                      // 獲取當前用戶資料
                      final userService = serviceLocator<IUserService>();
                      final userProfile =
                          await userService.getCurrentUserProfile();

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
                      final user = authController.user;
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
        color: color.withOpacity(0.1),
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

