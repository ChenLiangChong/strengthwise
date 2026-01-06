// ✅ 已響應式改造 (Phase 0) - 頁面殼，內容由 Content 處理
// ✅ v3.1 重構：使用 WorkoutExecutionContent
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'workout_execution_content.dart';

/// 訓練執行頁面
///
/// v3.1 重構：
/// - 頁面殼（Scaffold + AppBar + FAB）
/// - 實際內容由 WorkoutExecutionContent 提供
/// - WorkoutExecutionContent 可內嵌到 Session Mode
class WorkoutExecutionPage extends StatefulWidget {
  final String workoutRecordId;

  const WorkoutExecutionPage({
    super.key,
    required this.workoutRecordId,
  });

  @override
  State<WorkoutExecutionPage> createState() => _WorkoutExecutionPageState();
}

class _WorkoutExecutionPageState extends State<WorkoutExecutionPage> {
  /// Content 的 GlobalKey，用於訪問內部狀態
  final GlobalKey<WorkoutExecutionContentState> _contentKey = GlobalKey();

  /// 取得 Content State
  WorkoutExecutionContentState? get _contentState => _contentKey.currentState;

  /// 完成訓練
  Future<void> _completeTraining() async {
    final contentState = _contentState;
    if (contentState == null) return;

    final success = await contentState.completeTraining();
    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final contentState = _contentState;
        if (contentState == null) {
          if (context.mounted) Navigator.of(context).pop(true);
          return;
        }

        final controller = contentState.controller;
        final showTimerUI = controller.shouldShowTimerUI();
        final isInProgress = controller.isInProgress;

        // 如果顯示計時 UI 且進行中，暫停訓練並提示
        if (showTimerUI && isInProgress) {
          await contentState.pauseTraining();
          if (context.mounted) {
            NotificationUtils.showInfo(
              context,
              '訓練已暫停，計時將保存。可隨時返回繼續訓練。',
            );
          }
        }
        // 如果有未保存的更改且可以編輯，自動保存
        else if (controller.isDataChanged && controller.canEdit()) {
          await contentState.saveWorkoutRecord();
        }

        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Builder(
            builder: (context) {
              final contentState = _contentState;
              if (contentState == null) return const Text('訓練');
              return Text(contentState.controller.getPlanTitle());
            },
          ),
          actions: [
            Builder(
              builder: (context) {
                final contentState = _contentState;
                if (contentState == null) return const SizedBox.shrink();

                final controller = contentState.controller;
                final showTimerUI = controller.shouldShowTimerUI();
                final isPending = controller.isPending;
                final isCompleted = controller.isCompleted;

                // 準備模式下不顯示按鈕
                if (showTimerUI && isPending) {
                  return const SizedBox.shrink();
                }

                return IconButton(
                  icon: Icon(isCompleted ? Icons.check : Icons.save),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _completeTraining();
                  },
                  tooltip: isCompleted ? '完成' : '保存並離開',
                );
              },
            ),
          ],
        ),
        body: WorkoutExecutionContent(
          key: _contentKey,
          workoutRecordId: widget.workoutRecordId,
          showInlineAddButton: false, // 使用 FAB
          onLoaded: () {
            // 載入完成後刷新 AppBar
            setState(() {});
          },
          onDataChanged: () {
            // 資料變更後刷新 AppBar
            setState(() {});
          },
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final contentState = _contentState;
            if (contentState == null) return const SizedBox.shrink();

            final controller = contentState.controller;
            final exerciseRecords = controller.getExerciseRecords();
            final showTimerUI = controller.shouldShowTimerUI();
            final isPending = controller.isPending;

            // 不顯示 FAB 的條件
            if (!controller.canEdit()) return const SizedBox.shrink();
            if (exerciseRecords.isEmpty) return const SizedBox.shrink();
            if (showTimerUI && isPending) return const SizedBox.shrink();

            return FloatingActionButton(
              heroTag: 'workout_execution_fab',
              onPressed: () => contentState.addNewExercise(),
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }
}
