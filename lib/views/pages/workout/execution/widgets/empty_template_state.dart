import 'package:flutter/material.dart';
import 'package:strengthwise/themes/app_theme.dart';

/// 空模板狀態顯示
class EmptyTemplateState extends StatelessWidget {
  final VoidCallback onBackPressed;

  const EmptyTemplateState({
    super.key,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.note_alt_outlined,
            size: 64,
            color: AppTheme.slate400,
          ),
          const SizedBox(height: 16),
          Text(
            '還沒有保存的模板',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onBackPressed,
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
}

