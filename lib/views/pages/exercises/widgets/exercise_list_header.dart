import 'package:flutter/material.dart';

/// 動作列表頭部 Widget
///
/// 顯示選擇路徑和動作數量
class ExerciseListHeader extends StatelessWidget {
  final String selectionPath;
  final int exerciseCount;

  const ExerciseListHeader({
    super.key,
    required this.selectionPath,
    required this.exerciseCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectionPath,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '符合條件的訓練動作 ($exerciseCount):',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

