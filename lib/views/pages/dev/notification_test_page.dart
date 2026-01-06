// ✅ 已響應式改造 (Phase 0) - 開發測試頁，無需特殊處理
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/notifications/adaptive_notification_service.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/common_widgets/common/rest_timer_overlay.dart';

/// 通知系統測試頁面
///
/// 用於驗證各種通知場景的視覺效果與互動
///
/// 使用方式：在 main.dart 路由表中添加此頁面，或直接 Navigator.push()
class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  final _textController = TextEditingController();
  bool _isKeyboardTest = false;

  @override
  void dispose() {
    _textController.dispose();
    RestTimerOverlay.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知系統測試（2025 更新）'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 標題
          Text(
            '基礎通知（NotificationUtils）',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // 測試成功通知
          _buildTestButton(
            context,
            '✅ 成功通知（基礎版）',
            '記錄已儲存',
            () {
              NotificationUtils.showSuccess(context, '記錄已儲存');
            },
          ),

          // 測試錯誤通知
          _buildTestButton(
            context,
            '❌ 錯誤通知（基礎版）',
            '網路連線失敗',
            () {
              NotificationUtils.showError(context, '網路連線失敗，請檢查網路設定');
            },
          ),

          // 測試資訊通知
          _buildTestButton(
            context,
            'ℹ️ 資訊通知（基礎版）',
            '資料已同步',
            () {
              NotificationUtils.showInfo(context, '資料已同步到雲端');
            },
          ),

          // 測試警告通知
          _buildTestButton(
            context,
            '⚠️ 警告通知（基礎版）',
            '記憶體不足',
            () {
              NotificationUtils.showWarning(context, '記憶體不足，請清理緩存');
            },
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // 進階通知標題
          Text(
            '進階通知（AdaptiveNotificationService）',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // 測試成功通知（自適應）
          _buildTestButton(
            context,
            '✅ 成功通知（自適應）',
            'iOS 會顯示頂部，Android 顯示底部',
            () {
              AdaptiveNotificationService.showSuccess(
                context,
                '訓練記錄已儲存',
              );
            },
          ),

          // 可撤銷操作
          _buildTestButton(
            context,
            '🔙 可撤銷操作',
            '刪除後 7 秒內可撤銷',
            () {
              AdaptiveNotificationService.showUndoableAction(
                context,
                '已刪除訓練記錄',
                onUndo: () {
                  NotificationUtils.showSuccess(context, '已恢復訓練記錄');
                },
              );
            },
            color: Colors.red[700],
          ),

          // 重大成就
          _buildTestButton(
            context,
            '🏆 重大成就通知',
            '頂部大型 Banner + 金色',
            () {
              AdaptiveNotificationService.showAchievement(
                context,
                '🎉 突破紀錄',
                '你的推舉重量突破個人紀錄！120kg',
                icon: Icons.emoji_events_rounded,
              );
            },
            color: Colors.amber[700],
          ),

          // 系統狀態
          _buildTestButton(
            context,
            '🌐 系統狀態通知',
            '頂部 Sticky（持續顯示）',
            () {
              AdaptiveNotificationService.showSystemStatus(
                context,
                '網路已斷線',
                icon: Icons.cloud_off_outlined,
                color: const Color(0xFFEF4444),
              );
            },
            color: Colors.orange[700],
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // 休息計時器區塊
          Text(
            '休息計時器（靈動島風格）',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // 30 秒計時
          _buildTestButton(
            context,
            '⏱️ 30 秒休息計時',
            '頂部靈動島式倒數動畫',
            () {
              RestTimerOverlay.show(
                context,
                durationInSeconds: 30,
                onComplete: () {
                  AdaptiveNotificationService.showSuccess(
                    context,
                    '休息結束！準備開始下一組',
                  );
                },
              );
            },
            color: Colors.blue[700],
          ),

          // 90 秒計時
          _buildTestButton(
            context,
            '⏱️ 90 秒休息計時',
            '標準休息時長',
            () {
              RestTimerOverlay.show(
                context,
                durationInSeconds: 90,
                onComplete: () {
                  AdaptiveNotificationService.showAchievement(
                    context,
                    '休息結束',
                    '準備好開始下一組了嗎？💪',
                    icon: Icons.fitness_center,
                  );
                },
              );
            },
            color: Colors.blue[700],
          ),

          // 停止計時器
          _buildTestButton(
            context,
            '⏹️ 停止計時器',
            '立即停止當前計時',
            () {
              if (RestTimerOverlay.isRunning) {
                RestTimerOverlay.hide();
                NotificationUtils.showInfo(context, '已停止計時器');
              } else {
                NotificationUtils.showWarning(context, '目前沒有執行中的計時器');
              }
            },
            color: Colors.grey[700],
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // 鍵盤測試標題
          Text(
            '鍵盤自適應測試',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            '點擊下方輸入框後，再點擊「測試」按鈕\n通知會自動移動到頂部（避開鍵盤）',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // 輸入框
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: '輸入任意內容（測試鍵盤）',
              hintText: '點擊此處喚出鍵盤...',
            ),
            onTap: () {
              setState(() {
                _isKeyboardTest = true;
              });
            },
          ),

          const SizedBox(height: 16),

          // 鍵盤測試按鈕
          ElevatedButton.icon(
            onPressed: () {
              if (_isKeyboardTest &&
                  MediaQuery.of(context).viewInsets.bottom > 0) {
                AdaptiveNotificationService.showError(
                  context,
                  '驗證錯誤：此欄位為必填',
                );
              } else {
                NotificationUtils.showWarning(
                  context,
                  '請先點擊上方輸入框喚出鍵盤',
                );
              }
            },
            icon: const Icon(Icons.keyboard),
            label: const Text('測試鍵盤自適應'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // 說明卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '測試提示',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. 觀察深淺色模式下的色彩變化\n'
                    '2. 注意觸覺回饋（不同類型強度差異）\n'
                    '3. iOS 設備會優先顯示頂部通知\n'
                    '4. 底部通知不會遮擋底部導航欄\n'
                    '5. 圓角形狀符合 24px',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 80), // 預留底部
        ],
      ),
    );
  }

  /// 構建測試按鈕
  Widget _buildTestButton(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (color ?? Theme.of(context).colorScheme.primary)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.touch_app,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onPressed,
      ),
    );
  }
}
