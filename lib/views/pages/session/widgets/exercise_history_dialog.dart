// ✅ 已響應式改造 (Phase 0)
// ✅ v3.6: MVVM 重構 - 移除 Service 直接調用
import 'package:flutter/material.dart';
import 'package:strengthwise/models/exercise_history_record.dart';
import 'package:strengthwise/controllers/interfaces/i_workout_controller.dart'; // ⭐ v3.6: MVVM
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 動作歷史記錄對話框
///
/// 顯示指定動作的最近訓練記錄，用於 Session Mode 查看歷史
class ExerciseHistoryDialog extends StatefulWidget {
  /// 動作 ID
  final String exerciseId;

  /// 動作名稱
  final String exerciseName;

  /// 用戶 ID
  final String userId;

  const ExerciseHistoryDialog({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    required this.userId,
  });

  /// 顯示對話框
  static Future<void> show({
    required BuildContext context,
    required String exerciseId,
    required String exerciseName,
    required String userId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ExerciseHistoryDialog(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        userId: userId,
      ),
    );
  }

  @override
  State<ExerciseHistoryDialog> createState() => _ExerciseHistoryDialogState();
}

class _ExerciseHistoryDialogState extends State<ExerciseHistoryDialog> {
  late final IWorkoutController _workoutController; // ⭐ v3.6: MVVM
  List<ExerciseHistoryRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _workoutController = serviceLocator<IWorkoutController>(); // ⭐ v3.6: MVVM
    _loadHistory();
  }

  /// ⭐ v3.6: 透過 Controller 查詢
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final records = await _workoutController.getExerciseHistory(
        userId: widget.userId,
        exerciseId: widget.exerciseId,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // 拖曳指示器
            Container(
              margin: EdgeInsets.symmetric(vertical: context.spacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 標題
            Padding(
              padding: context.cardPadding,
              child: Row(
                children: [
                  Icon(Icons.history, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exerciseName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '最近 ${_records.length} 次訓練記錄',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 內容
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _records.isEmpty
                      ? _buildEmptyState(colorScheme)
                      : _buildRecordsList(scrollController, colorScheme),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '尚無訓練記錄',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(
    ScrollController scrollController,
    ColorScheme colorScheme,
  ) {
    return ListView.separated(
      controller: scrollController,
      padding: context.cardPadding,
      itemCount: _records.length,
      separatorBuilder: (_, __) => SizedBox(height: context.spacing.sm),
      itemBuilder: (context, index) {
        final record = _records[index];
        return _buildRecordCard(record, colorScheme, index == 0);
      },
    );
  }

  Widget _buildRecordCard(
    ExerciseHistoryRecord record,
    ColorScheme colorScheme,
    bool isLatest,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: context.cardPadding,
      decoration: BoxDecoration(
        color: isLatest
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLatest ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期和標籤
          Row(
            children: [
              Text(
                record.formattedDate,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: context.spacing.sm),
              if (isLatest)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '最近',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              // 總訓練量
              Text(
                '${record.totalVolume.toStringAsFixed(0)} kg',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 每組數據
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: record.sets.asMap().entries.map((entry) {
              final setIndex = entry.key;
              final set = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${setIndex + 1}: ${set.reps}×${set.weight}kg',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    color: colorScheme.onSurface,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

