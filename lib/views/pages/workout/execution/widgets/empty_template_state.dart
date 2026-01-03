import 'package:flutter/material.dart';

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
            color: Color(0xFF94A3B8), // Slate-400
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

