import 'package:flutter/material.dart';

/// 訓練執行頁面的資訊卡片
class WorkoutInfoCard extends StatelessWidget {
  final String planType;
  final String elapsedTime;
  final int exerciseCount;
  final int totalSets;
  final double totalVolume;
  final TextEditingController notesController;
  final ValueChanged<String> onNotesChanged;

  const WorkoutInfoCard({
    super.key,
    required this.planType,
    required this.elapsedTime,
    required this.exerciseCount,
    required this.totalSets,
    required this.totalVolume,
    required this.notesController,
    required this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '訓練類型:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(planType),
                    ],
                  ),
                ),
                // 訓練計時器
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '訓練時間:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(elapsedTime),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '運動數量:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text('$exerciseCount 個運動, $totalSets 組'),
                    ],
                  ),
                ),
                // 總訓練量
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '總訓練量:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text('${totalVolume.toStringAsFixed(1)} kg'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 備註輸入框
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: '訓練備註',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: onNotesChanged,
            ),
          ],
        ),
      ),
    );
  }
}

