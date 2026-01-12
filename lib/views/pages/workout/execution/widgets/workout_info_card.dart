// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 訓練執行頁面的資訊卡片
class WorkoutInfoCard extends StatelessWidget {
  final String planType;

  /// ⭐ v2.9.1: 訓練時間（null 時不顯示計時功能）
  final String? elapsedTime;
  final int exerciseCount;
  final int totalSets;
  final double totalVolume;
  final TextEditingController notesController;
  final ValueChanged<String> onNotesChanged;
  // ⭐ v2.9.1: 暫停/完成狀態支援
  final bool isPaused;
  final bool isCompleted;
  final VoidCallback? onResume;

  const WorkoutInfoCard({
    super.key,
    required this.planType,
    this.elapsedTime,
    required this.exerciseCount,
    required this.totalSets,
    required this.totalVolume,
    required this.notesController,
    required this.onNotesChanged,
    this.isPaused = false,
    this.isCompleted = false,
    this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: context.cardPadding,
      child: Padding(
        padding: context.cardPadding,
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
                        '訓練計畫類型:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(planType),
                    ],
                  ),
                ),
                // 訓練計時器（只有 elapsedTime 不為 null 時顯示）
                if (elapsedTime != null)
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ⭐ v2.9.1: 暫停狀態顯示
                          if (isPaused)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.pause_circle_filled,
                                size: 16,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          Text(
                            elapsedTime!,
                            style: isPaused
                                ? TextStyle(
                                    color: Theme.of(context).colorScheme.error)
                                : null,
                          ),
                        ],
                      ),
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
            // ⭐ v2.9.1: 只顯示完成狀態提示（繼續訓練按鈕移到頂部固定位置）
            if (isCompleted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '訓練完成！',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // 注意：「繼續訓練」按鈕已移至頁面頂部固定位置
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
