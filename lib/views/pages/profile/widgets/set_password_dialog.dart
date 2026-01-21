import 'package:flutter/material.dart';
import '../../../../controllers/interfaces/i_profile_controller.dart';
import '../../../../utils/notification_utils.dart';

/// 設置密碼對話框（為 OAuth 用戶啟用 Email 登入）
/// Material 3 設計
class SetPasswordDialog extends StatefulWidget {
  final IProfileController controller;
  
  const SetPasswordDialog({
    super.key,
    required this.controller,
  });

  @override
  State<SetPasswordDialog> createState() => _SetPasswordDialogState();
}

class _SetPasswordDialogState extends State<SetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final success = await widget.controller.setPasswordForOAuthUser(
      _passwordController.text,
    );

    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });

    if (success) {
      NotificationUtils.showSuccess(
        context,
        '密碼設置成功！\n您現在可以使用 Email 登入',
      );
      Navigator.of(context).pop(true);
    } else {
      // 檢查是否是相同密碼錯誤
      final errorMsg = widget.controller.errorMessage ?? '';
      if (errorMsg.contains('same_password') || 
          errorMsg.contains('New password should be different')) {
        NotificationUtils.showError(
          context,
          '密碼不能與舊密碼相同\n請輸入一個新密碼',
        );
      } else {
        NotificationUtils.showError(
          context,
          errorMsg.isNotEmpty ? errorMsg : '密碼設置失敗，請稍後再試',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('設置登入密碼'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '設置密碼後，您就可以使用 Email + 密碼登入',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              // 新密碼
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '新密碼 *',
                  border: const OutlineInputBorder(),
                  helperText: '至少 6 個字符',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入密碼';
                  }
                  if (value.length < 6) {
                    return '密碼長度至少需要 6 個字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 確認密碼
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: '確認密碼 *',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請再次輸入密碼';
                  }
                  if (value != _passwordController.text) {
                    return '兩次輸入的密碼不一致';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleSetPassword,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('設置密碼'),
        ),
      ],
    );
  }
}

