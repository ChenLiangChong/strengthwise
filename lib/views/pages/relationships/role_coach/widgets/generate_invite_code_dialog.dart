import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:strengthwise/controllers/coaching_relationship_controller.dart';
import 'package:strengthwise/models/invite_code_model.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/services/service_locator.dart';

/// 生成邀請碼對話框（教練專用）
///
/// 功能：
/// - 生成 6 位邀請碼
/// - 顯示倒計時（5 分鐘）
/// - 複製功能
/// - 用完即刪，無需管理
class GenerateInviteCodeDialog extends StatefulWidget {
  final String coachId;

  const GenerateInviteCodeDialog({
    super.key,
    required this.coachId,
  });

  @override
  State<GenerateInviteCodeDialog> createState() =>
      _GenerateInviteCodeDialogState();
}

class _GenerateInviteCodeDialogState extends State<GenerateInviteCodeDialog> {
  InviteCodeModel? _inviteCode;
  bool _isGenerating = false;
  late final CoachingRelationshipController _controller;

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<CoachingRelationshipController>();
    _generateCode();
  }

  /// 生成邀請碼
  Future<void> _generateCode() async {
    setState(() {
      _isGenerating = true;
    });

    final inviteCode = await _controller.generateInviteCode(widget.coachId);

    if (inviteCode != null) {
      setState(() {
        _inviteCode = inviteCode;
        _isGenerating = false;
      });
    } else {
      if (mounted) {
        NotificationUtils.showError(
          context,
          _controller.errorMessage ?? '生成邀請碼失敗',
        );
        Navigator.of(context).pop();
      }
    }
  }

  /// 複製邀請碼
  void _copyCode() {
    if (_inviteCode == null) return;

    Clipboard.setData(ClipboardData(text: _inviteCode!.code));
    NotificationUtils.showSuccess(context, '邀請碼已複製');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.qr_code, size: 24),
          SizedBox(width: 8),
          Text('邀請碼'),
        ],
      ),
      content: _isGenerating
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 說明文字
                Text(
                  '分享此邀請碼給學員，有效期 5 分鐘',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // 邀請碼卡片
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // 邀請碼
                      SelectableText(
                        _inviteCode?.code ?? '',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                          letterSpacing: 8,
                          fontFamily: 'Courier New', // 等寬字體
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // 剩餘時間
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: colorScheme.onPrimaryContainer
                                .withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '剩餘：${_inviteCode?.remainingTimeText ?? ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimaryContainer
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 複製按鈕
                FilledButton.icon(
                  onPressed: _copyCode,
                  icon: const Icon(Icons.copy),
                  label: const Text('複製邀請碼'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 8),

                // 使用說明
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '使用說明',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. 將邀請碼分享給學員（口頭/截圖）\n'
                        '2. 學員在 App 中輸入邀請碼\n'
                        '3. 自動建立綁定關係',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('關閉'),
        ),
      ],
    );
  }
}

