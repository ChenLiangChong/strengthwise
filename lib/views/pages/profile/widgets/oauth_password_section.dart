import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/profile_controller.dart';
import 'set_password_dialog.dart';

/// OAuth 用戶密碼設置區塊（Material 3）
/// 
/// 顯示登入方式說明和密碼設置/重設按鈕
class OAuthPasswordSection extends StatelessWidget {
  const OAuthPasswordSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final colorScheme = Theme.of(context).colorScheme;
    final userEmail = controller.userEmail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題
        Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '登入密碼',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),

        // 登入方式卡片
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '目前登入方式',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Email
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Google 登入標記
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Google 帳號登入',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 說明文字
        Text(
          '您可以為此帳號設置登入密碼，日後也能使用 Email + 密碼登入',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 16),

        // 設置/重設密碼按鈕（Material 3 OutlinedButton）
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await showDialog<bool>(
                context: context,
                builder: (dialogContext) => SetPasswordDialog(
                  controller: controller,
                ),
              );
              // 不需要額外通知，Dialog 內已處理
            },
            icon: const Icon(
              Icons.lock_outline,
              size: 18,
            ),
            label: const Text('設置/重設登入密碼'),
          ),
        ),
      ],
    );
  }
}

