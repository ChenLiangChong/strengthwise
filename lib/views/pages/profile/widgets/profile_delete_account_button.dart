import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/interfaces/i_delete_account_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/pages/auth/login_page.dart';
import 'package:strengthwise/views/pages/profile/widgets/delete_account_dialog.dart';

/// 刪除帳號按鈕元件
class ProfileDeleteAccountButton extends StatelessWidget {
  const ProfileDeleteAccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showDeleteAccountDialog(context),
        icon: Icon(Icons.delete_forever, color: colorScheme.error),
        label: Text(
          '刪除帳號',
          style: TextStyle(color: colorScheme.error),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.error),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  /// 顯示刪除帳號確認對話框
  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    // 透過 serviceLocator 取得 Controller
    final controller = serviceLocator<IDeleteAccountController>();

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChangeNotifierProvider.value(
        value: controller,
        child: const DeleteAccountDialog(),
      ),
    );

    // 清理 Controller
    controller.dispose();

    if (success == true && context.mounted) {
      // 刪除成功，顯示訊息並跳轉到登入頁面
      NotificationUtils.showSuccess(
        context,
        '您的帳號已成功刪除',
      );

      // 延遲一下再跳轉，讓用戶看到訊息
      await Future.delayed(const Duration(milliseconds: 500));

      if (context.mounted) {
        // 跳轉到登入頁面（清除所有路由）
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }
}

