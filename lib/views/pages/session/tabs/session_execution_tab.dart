// ✅ 已響應式改造 (Phase 0) - Session 執行 Tab，子組件處理
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/interfaces/i_session_mode_controller.dart';
import 'package:strengthwise/models/workout_template_model.dart';
import 'package:strengthwise/views/pages/session/widgets/readiness_card.dart';
import 'package:strengthwise/views/pages/session/widgets/session_notes_section.dart';
import 'package:strengthwise/views/pages/workout/execution/template_management_page.dart';
import 'package:strengthwise/views/pages/workout/execution/plan_editor_page.dart';
import 'package:strengthwise/views/pages/workout/execution/workout_execution_content.dart';

/// 課程執行 Tab（v3.1 重構）
///
/// 使用 WorkoutExecutionContent 內嵌訓練執行功能：
/// - ReadinessCard: 學員狀態卡
/// - WorkoutExecutionContent: 訓練動作執行（複用）
/// - SessionNotesSection: 課程筆記
class SessionExecutionTab extends StatelessWidget {
  /// ⭐ v3.1: GlobalKey 用於讓外部調用 WorkoutExecutionContent 的方法
  final GlobalKey<WorkoutExecutionContentState>? workoutContentKey;

  const SessionExecutionTab({
    super.key,
    this.workoutContentKey,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ISessionModeController>(
      builder: (context, controller, child) {
        // 整個頁面都在 WorkoutExecutionContent 的滾動區域內
        return _buildWorkoutSection(context, controller);
      },
    );
  }

  /// 訓練計畫區域
  Widget _buildWorkoutSection(
    BuildContext context,
    ISessionModeController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // 共用的頂部 Widget：學員狀態卡
    final readinessCardWidget = Padding(
      padding: const EdgeInsets.all(16),
      child: ReadinessCard(readiness: controller.readiness),
    );

    if (!controller.hasWorkoutPlan || controller.workoutPlanId == null) {
      // 無訓練計畫：顯示空狀態 + 課程筆記（整個頁面可滾動）
      return SingleChildScrollView(
        child: Column(
          children: [
            // 學員狀態卡
            readinessCardWidget,
            // 空計畫狀態
            _buildEmptyPlanState(context, controller, colorScheme),
            const SizedBox(height: 16),
            // 課程筆記
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildNotesSection(context, controller),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    // 有訓練計畫：使用 WorkoutExecutionContent
    // ReadinessCard 在頂部，課程筆記在底部（訓練下面）
    return WorkoutExecutionContent(
      key: workoutContentKey, // ⭐ v3.1: 讓外部可調用方法
      workoutRecordId: controller.workoutPlanId!,
      showInlineAddButton: controller.isCoachMode, // 只有教練顯示新增按鈕
      // Session Mode 權限覆蓋
      overrideCanEdit: controller.canEditPlan,
      overrideCanMarkSet: controller.canMarkSet,
      // 教練顯示計時器（控制上課時長），學員不顯示
      overrideShowTimerUI: controller.isCoachMode,
      // ReadinessCard 放在滾動區域頂部
      headerWidgets: [readinessCardWidget],
      // 課程筆記放在滾動區域底部（訓練下面）
      footerWidgets: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildNotesSection(context, controller),
        ),
        const SizedBox(height: 32),
      ],
      onDataChanged: () {
        // 資料變更時可刷新 controller
      },
    );
  }

  /// 空訓練計畫狀態
  Widget _buildEmptyPlanState(
    BuildContext context,
    ISessionModeController controller,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '尚未建立訓練計畫',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            // 教練可編輯時顯示按鈕
            if (controller.canEditPlan)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () =>
                        _navigateToTemplateSelection(context, controller),
                    icon: const Icon(Icons.dashboard),
                    label: const Text('從模板建立'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _navigateToPlanEditor(context, controller),
                    icon: const Icon(Icons.add),
                    label: const Text('新增訓練計畫'),
                  ),
                ],
              )
            else if (controller.isCoachMode && !controller.isWithinEditWindow)
              // 教練模式但超過時間窗口
              Column(
                children: [
                  Text(
                    '訓練計畫已過編輯時間',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '你仍可編輯課程筆記',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                  ),
                ],
              )
            else
              // 學員模式
              Text(
                '等待教練建立訓練計畫',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  /// 課程筆記區塊
  Widget _buildNotesSection(
    BuildContext context,
    ISessionModeController controller,
  ) {
    return SessionNotesSection(
      initialSoap: controller.currentSoap,
      onSoapChanged: controller.updateSoap,
      readOnly: !controller.canEditNotes,
      visualElements: controller.visualElements, // ⭐ v3.1: 傳入照片/繪圖
      quickTags: controller.quickTags, // ⭐ v3.1: 傳入快速標籤
      onTagsChanged: controller.updateQuickTags, // ⭐ v3.1: 標籤變更回調
    );
  }

  /// 跳轉到模板選擇
  void _navigateToTemplateSelection(
    BuildContext context,
    ISessionModeController controller,
  ) {
    Navigator.push<WorkoutTemplate>(
      context,
      MaterialPageRoute(
        builder: (context) => const TemplateManagementPage(),
      ),
    ).then((selectedTemplate) {
      if (selectedTemplate != null) {
        Navigator.push(
          // ignore: use_build_context_synchronously - then callback 內使用
          context,
          MaterialPageRoute(
            builder: (context) => PlanEditorPage(
              selectedDate: controller.sessionStartTime,
              traineeId: controller.clientId,
              initialStartTime: controller.sessionStartTime,
              initialEndTime: controller.sessionEndTime,
              appointmentId: controller.appointmentId,
              initialTemplate: selectedTemplate,
            ),
          ),
        ).then((result) {
          if (result == true) {
            controller.refresh();
          }
        });
      }
    });
  }

  /// 跳轉到新增訓練計畫
  void _navigateToPlanEditor(
    BuildContext context,
    ISessionModeController controller,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanEditorPage(
          selectedDate: controller.sessionStartTime,
          traineeId: controller.clientId,
          initialStartTime: controller.sessionStartTime,
          initialEndTime: controller.sessionEndTime,
          appointmentId: controller.appointmentId,
        ),
      ),
    ).then((result) {
      if (result == true) {
        controller.refresh();
      }
    });
  }
}
