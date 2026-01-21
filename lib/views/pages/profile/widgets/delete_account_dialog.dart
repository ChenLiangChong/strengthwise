import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/interfaces/i_delete_account_controller.dart';

/// 刪除帳號確認對話框
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  bool _confirmChecked = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = context.watch<IDeleteAccountController>();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.error),
          const SizedBox(width: 8),
          const Text('刪除帳號'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 警告文字
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '此操作無法復原！',
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 刪除說明
            const Text(
              '刪除帳號後：',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              icon: Icons.delete_forever,
              text: '您的訓練記錄將被永久刪除',
              color: colorScheme.error,
            ),
            _buildInfoItem(
              icon: Icons.people_outline,
              text: '所有教練學員關係將被解除',
              color: colorScheme.error,
            ),
            _buildInfoItem(
              icon: Icons.event_busy,
              text: '所有預約記錄將被刪除',
              color: colorScheme.error,
            ),
            _buildInfoItem(
              icon: Icons.notes,
              text: '您的私人筆記將被刪除',
              color: colorScheme.error,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.check_circle_outline,
              text: '您的自訂動作會保留',
              color: colorScheme.primary,
            ),
            _buildInfoItem(
              icon: Icons.check_circle_outline,
              text: '您為學員建立的訓練會保留',
              color: colorScheme.primary,
            ),
            _buildInfoItem(
              icon: Icons.check_circle_outline,
              text: '您的共享課程筆記會保留',
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),

            // 確認勾選框
            CheckboxListTile(
              value: _confirmChecked,
              onChanged: controller.isDeleting
                  ? null
                  : (value) {
                      setState(() {
                        _confirmChecked = value ?? false;
                      });
                    },
              title: const Text(
                '我了解此操作無法復原',
                style: TextStyle(fontSize: 14),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),

            // 錯誤訊息
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.errorMessage!,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // 取消按鈕
        TextButton(
          onPressed: controller.isDeleting
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('取消'),
        ),

        // 刪除按鈕
        FilledButton(
          onPressed: (!_confirmChecked || controller.isDeleting)
              ? null
              : () async {
                  final success = await controller.deleteAccount();
                  if (mounted) {
                    // ignore: use_build_context_synchronously - mounted 已檢查
                    Navigator.of(context).pop(success);
                  }
                },
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: controller.isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('刪除帳號'),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

