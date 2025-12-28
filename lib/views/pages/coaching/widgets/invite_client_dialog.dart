import 'package:flutter/material.dart';

/// 邀請學員 Dialog
class InviteClientDialog extends StatefulWidget {
  final Function(String clientId, String? notes) onInvite;

  const InviteClientDialog({
    super.key,
    required this.onInvite,
  });

  @override
  State<InviteClientDialog> createState() => _InviteClientDialogState();
}

class _InviteClientDialogState extends State<InviteClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _clientIdController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isInviting = false;

  @override
  void dispose() {
    _clientIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleInvite() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isInviting = true;
    });

    try {
      await widget.onInvite(
        _clientIdController.text.trim(),
        _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInviting = false;
        });

        // 提取友善的錯誤訊息
        String errorMessage = '邀請失敗';
        if (e.toString().contains('已存在綁定關係')) {
          errorMessage = '該學員已經在你的學員列表中了';
        } else if (e.toString().contains('not found') ||
            e.toString().contains('不存在')) {
          errorMessage = '找不到該學員，請確認 UUID 是否正確';
        } else {
          errorMessage = '邀請失敗: ${e.toString().replaceAll('Exception: ', '')}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_add),
          SizedBox(width: 12),
          Text('邀請學員'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 提示信息
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '輸入學員的用戶 ID 來建立綁定關係',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 學員 ID 輸入框
              TextFormField(
                controller: _clientIdController,
                decoration: const InputDecoration(
                  labelText: '學員 ID *',
                  hintText: '輸入學員的 UUID',
                  prefixIcon: Icon(Icons.fingerprint),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入學員 ID';
                  }
                  // 簡單的 UUID 格式驗證
                  if (!RegExp(
                          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
                      .hasMatch(value.trim().toLowerCase())) {
                    return '請輸入有效的 UUID 格式';
                  }
                  return null;
                },
                maxLines: 2,
                minLines: 1,
              ),

              const SizedBox(height: 12),

              // 快捷填入測試學員按鈕（開發專用）
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _clientIdController.text =
                            'd1798674-0b96-4c47-a7c7-ee20a5372a03';
                        _notesController.text = '測試學員 1 - 良朱 (charlie19960414)';
                      },
                      icon: const Icon(Icons.person, size: 18),
                      label:
                          const Text('測試帳號 1', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _clientIdController.text =
                            '1d7f5ed6-7759-4abc-9832-9db791e75e4f';
                        _notesController.text =
                            '測試學員 2 - Charlie (charlie8519960414)';
                      },
                      icon: const Icon(Icons.person, size: 18),
                      label:
                          const Text('測試帳號 2', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 說明文字
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.orange),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '開發測試：藍色=良朱帳號 | 綠色=Charlie帳號',
                        style: TextStyle(fontSize: 11, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 備註輸入框（選填）
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: '備註（選填）',
                  hintText: '例如：健身新手、需要減脂訓練',
                  prefixIcon: Icon(Icons.note_outlined),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                minLines: 2,
              ),

              const SizedBox(height: 16),

              // 說明文字
              Text(
                '💡 提示：學員接受邀請後，狀態會自動變為「活躍」',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // 取消按鈕
        TextButton(
          onPressed:
              _isInviting ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),

        // 邀請按鈕
        FilledButton.icon(
          onPressed: _isInviting ? null : _handleInvite,
          icon: _isInviting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(_isInviting ? '邀請中...' : '發送邀請'),
        ),
      ],
    );
  }
}
