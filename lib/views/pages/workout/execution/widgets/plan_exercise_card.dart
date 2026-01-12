// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:strengthwise/models/workout_exercise_model.dart';
import 'package:strengthwise/models/tracking_mode.dart'; // v3.2+
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 計劃動作卡片（顯示和編輯）
///
/// 支援兩種模式：
/// - 計劃模式：編輯訓練計畫（原有功能）
/// - Session 模式：教練帶課時使用（打勾 + PREV）
class PlanExerciseCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;
  final VoidCallback onBatchEdit;
  final VoidCallback onDelete;
  final Function(int setIndex) onEditSet;
  final Function(int delta) onAdjustSets;

  // ============================================================
  // Session Mode 擴展參數
  // ============================================================

  /// 是否為 Session Mode（教練帶課模式）
  final bool isSessionMode;

  /// 已完成的組數索引（Session Mode）
  final Set<int>? completedSets;

  /// 完成某組的回調（Session Mode）
  final Function(int setIndex, bool completed)? onSetCompleted;

  /// 上次訓練記錄（PREV 幽靈數據）
  /// Map key 為 setIndex，value 為 { 'reps': int, 'weight': double }
  final Map<int, Map<String, dynamic>>? previousRecords;

  /// 是否唯讀（學員視角）
  final bool readOnly;

  /// 顯示動作歷史記錄回調
  final VoidCallback? onShowHistory;

  /// 是否可以打勾（時間限制）
  final bool canMarkSet;

  const PlanExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.onBatchEdit,
    required this.onDelete,
    required this.onEditSet,
    required this.onAdjustSets,
    // Session Mode 參數
    this.isSessionMode = false,
    this.completedSets,
    this.onSetCompleted,
    this.previousRecords,
    this.readOnly = false,
    this.onShowHistory,
    this.canMarkSet = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      key: Key(exercise.id),
      margin: EdgeInsets.symmetric(vertical: context.spacing.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: context.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 動作標題和操作按鈕
            _buildHeader(context, colorScheme),
            const Divider(height: 16),

            // 組數調整（僅計劃模式）
            if (!isSessionMode) _buildSetsAdjuster(context, colorScheme),

            // 組數標題（Session 模式）
            if (isSessionMode) _buildSessionSetsHeader(context, colorScheme),

            const SizedBox(height: 8),

            // 每組詳情
            _buildSetsList(context, colorScheme),

            // 休息時間和備註
            _buildFooter(context, colorScheme),
          ],
        ),
      ),
    );
  }

  /// 標題區域
  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: isSessionMode ? onShowHistory : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercise.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                    // Session 模式：顯示歷史記錄按鈕
                    if (isSessionMode && onShowHistory != null)
                      IconButton(
                        icon: const Icon(Icons.history),
                        iconSize: 20,
                        color: colorScheme.primary,
                        onPressed: onShowHistory,
                        tooltip: '查看歷史記錄',
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.equipment} | ${exercise.bodyParts.join(", ")}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
        // 計劃模式：操作按鈕
        if (!isSessionMode && !readOnly)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.copy),
                iconSize: 24,
                color: colorScheme.primary,
                onPressed: onBatchEdit,
                tooltip: '批量編輯',
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                iconSize: 24,
                color: colorScheme.error,
                onPressed: onDelete,
                tooltip: '刪除動作',
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// 組數調整（計劃模式）
  Widget _buildSetsAdjuster(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Text(
          '訓練組數',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          iconSize: 24,
          color: exercise.sets > 1
              ? colorScheme.error
              : colorScheme.onSurfaceVariant,
          onPressed: exercise.sets > 1 ? () => onAdjustSets(-1) : null,
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
        ),
        Text(
          '${exercise.sets} 組',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 24,
          color: exercise.sets < 10
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
          onPressed: exercise.sets < 10 ? () => onAdjustSets(1) : null,
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
        ),
      ],
    );
  }

  /// Session 模式組數標題
  Widget _buildSessionSetsHeader(BuildContext context, ColorScheme colorScheme) {
    final completed = completedSets?.length ?? 0;
    final total = exercise.sets;

    return Row(
      children: [
        Text(
          '訓練組數',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        // 進度指示
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: completed == total
                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                : colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$completed / $total 組',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w600,
              color: completed == total
                  ? const Color(0xFF10B981)
                  : colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// 每組列表
  Widget _buildSetsList(BuildContext context, ColorScheme colorScheme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exercise.sets,
      itemBuilder: (context, setIndex) {
        return _buildSetRow(context, colorScheme, setIndex);
      },
    );
  }

  /// 單組行
  /// v3.2+ 根據 trackingMode 顯示不同欄位
  Widget _buildSetRow(BuildContext context, ColorScheme colorScheme, int setIndex) {
    final trackingMode = exercise.trackingMode;
    
    // 獲取這一組的目標
    int targetReps;
    double targetWeight;
    int? targetTime;
    double? targetDistance;
    double? targetCalories;

    if (exercise.setTargets != null &&
        setIndex < exercise.setTargets!.length) {
      final target = exercise.setTargets![setIndex];
      targetReps = target['reps'] as int? ?? exercise.reps;
      targetWeight =
          (target['weight'] as num?)?.toDouble() ?? exercise.weight;
      targetTime = target['time'] as int? ?? exercise.time;
      targetDistance = (target['distance'] as num?)?.toDouble() ?? exercise.distance;
      targetCalories = (target['calories'] as num?)?.toDouble() ?? exercise.calories;
    } else {
      targetReps = exercise.reps;
      targetWeight = exercise.weight;
      targetTime = exercise.time;
      targetDistance = exercise.distance;
      targetCalories = exercise.calories;
    }

    final isCompleted = completedSets?.contains(setIndex) ?? false;

    // 獲取 PREV 數據
    final prevRecord = previousRecords?[setIndex];
    final hasPrev = prevRecord != null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF10B981).withValues(alpha: 0.08)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Session 模式：打勾框
          if (isSessionMode)
            _buildCheckbox(context, colorScheme, setIndex, isCompleted),

          // 組數圓圈
          CircleAvatar(
            radius: 16,
            backgroundColor:
                isCompleted ? const Color(0xFF10B981) : colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            child: isCompleted
                ? const Icon(Icons.check, size: 16)
                : Text(
                    '${setIndex + 1}',
                    style: const TextStyle(fontSize: 14),
                  ),
          ),
          const SizedBox(width: 12),

          // 目標數據（v3.2+ 根據 trackingMode 顯示）
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 當前目標
                Text(
                  _formatSetTarget(trackingMode, targetReps, targetWeight, targetTime, targetDistance, targetCalories),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w500,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                      ),
                ),
                // PREV 數據（幽靈文字）
                if (isSessionMode && hasPrev)
                  Text(
                    'PREV: ${_formatPrevRecord(trackingMode, prevRecord)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          fontFamily: 'JetBrains Mono',
                          fontStyle: FontStyle.italic,
                        ),
                  ),
              ],
            ),
          ),

          // 編輯按鈕
          if (!readOnly)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              iconSize: 20,
              color: colorScheme.primary,
              onPressed: () => onEditSet(setIndex),
              tooltip: '編輯',
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
        ],
      ),
    );
  }

  /// v3.2+ 根據追蹤模式格式化目標顯示
  String _formatSetTarget(
    TrackingMode mode,
    int reps,
    double weight,
    int? time,
    double? distance,
    double? calories,
  ) {
    switch (mode) {
      case TrackingMode.weightReps:
        return '$reps 次 × ${TrackingModeFormatter.formatWeight(weight)}';
      case TrackingMode.weightTime:
        return '${TrackingModeFormatter.formatWeight(weight)} × ${TrackingModeFormatter.formatTime(time ?? 0)}';
      case TrackingMode.repsOnly:
        return TrackingModeFormatter.formatReps(reps);
      case TrackingMode.timeOnly:
        return TrackingModeFormatter.formatTime(time ?? 0);
      case TrackingMode.repsTime:
        return '${TrackingModeFormatter.formatReps(reps)} × ${TrackingModeFormatter.formatTime(time ?? 0)}';
      case TrackingMode.distanceTime:
        return '${TrackingModeFormatter.formatDistance(distance ?? 0)} / ${TrackingModeFormatter.formatTime(time ?? 0)}';
      case TrackingMode.distanceOnly:
        return TrackingModeFormatter.formatDistance(distance ?? 0);
      case TrackingMode.calories:
        return TrackingModeFormatter.formatCalories(calories ?? 0);
    }
  }

  /// v3.2+ 根據追蹤模式格式化 PREV 記錄
  String _formatPrevRecord(TrackingMode mode, Map<String, dynamic> record) {
    switch (mode) {
      case TrackingMode.weightReps:
        return '${record['reps']} × ${record['weight']} kg';
      case TrackingMode.weightTime:
        final time = record['time'] as int? ?? 0;
        return '${record['weight']} kg × ${TrackingModeFormatter.formatTime(time)}';
      case TrackingMode.repsOnly:
        return '${record['reps']} 次';
      case TrackingMode.timeOnly:
        final time = record['time'] as int? ?? 0;
        return TrackingModeFormatter.formatTime(time);
      case TrackingMode.repsTime:
        final time = record['time'] as int? ?? 0;
        return '${record['reps']} 次 × ${TrackingModeFormatter.formatTime(time)}';
      case TrackingMode.distanceTime:
        final distance = (record['distance'] as num?)?.toDouble() ?? 0;
        final time = record['time'] as int? ?? 0;
        return '${TrackingModeFormatter.formatDistance(distance)} / ${TrackingModeFormatter.formatTime(time)}';
      case TrackingMode.distanceOnly:
        final distance = (record['distance'] as num?)?.toDouble() ?? 0;
        return TrackingModeFormatter.formatDistance(distance);
      case TrackingMode.calories:
        final calories = (record['calories'] as num?)?.toDouble() ?? 0;
        return TrackingModeFormatter.formatCalories(calories);
    }
  }

  /// 打勾框
  Widget _buildCheckbox(
    BuildContext context,
    ColorScheme colorScheme,
    int setIndex,
    bool isCompleted,
  ) {
    return Checkbox(
      value: isCompleted,
      onChanged: (readOnly || !canMarkSet)
          ? null
          : (value) {
              HapticFeedback.lightImpact();
              onSetCompleted?.call(setIndex, value ?? false);
            },
      activeColor: const Color(0xFF10B981),
      side: BorderSide(
        color: canMarkSet ? colorScheme.outline : colorScheme.outlineVariant,
        width: 2,
      ),
    );
  }

  /// 底部資訊
  Widget _buildFooter(BuildContext context, ColorScheme colorScheme) {
    if (exercise.restTime == 90 && exercise.notes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        if (exercise.restTime != 90)
          Text(
            '休息: ${exercise.restTime}秒',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        if (exercise.notes.isNotEmpty)
          Text(
            '備註: ${exercise.notes}',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}
