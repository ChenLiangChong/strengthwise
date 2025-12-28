import 'package:flutter/material.dart';

/// 空狀態組件 - 當教練還沒有學員時顯示
class EmptyClientsState extends StatelessWidget {
  final VoidCallback onInviteClient;

  const EmptyClientsState({
    super.key,
    required this.onInviteClient,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              '還沒有學員',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              '開始邀請學員，管理他們的訓練計劃',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onInviteClient,
              icon: const Icon(Icons.person_add),
              label: const Text('邀請學員'),
            ),
          ],
        ),
      ),
    );
  }
}

