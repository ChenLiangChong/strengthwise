import 'package:flutter/material.dart';
import 'package:strengthwise/controllers/coaching_relationship_controller.dart';
import 'package:strengthwise/services/service_locator.dart';

/// 輸入邀請碼對話框（學員專用）
class InputInviteCodeDialog extends StatefulWidget {
  final String traineeId;

  const InputInviteCodeDialog({
    super.key,
    required this.traineeId,
  });

  @override
  State<InputInviteCodeDialog> createState() => _InputInviteCodeDialogState();
}

class _InputInviteCodeDialogState extends State<InputInviteCodeDialog> {
  late final TextEditingController _codeController;
  late final GlobalKey<FormState> _formKey;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
    });

    final code = _codeController.text.trim();

    // 使用 CoachingRelationshipController
    final controller = serviceLocator<CoachingRelationshipController>();

    final success = await controller.useInviteCode(
      code: code,
      traineeId: widget.traineeId,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      // 顯示錯誤訊息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? '綁定失敗'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.vpn_key, size: 24),
          SizedBox(width: 8),
          Text('輸入邀請碼'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '請輸入教練提供的 6 位邀請碼',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              enabled: !_isSubmitting,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontFamily: 'Courier New',
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'A1B2C3',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '請輸入邀請碼';
                }
                if (value.trim().length != 6) {
                  return '邀請碼必須是 6 位';
                }
                return null;
              },
              onFieldSubmitted: (_) => _handleSubmit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('確認'),
        ),
      ],
    );
  }
}

