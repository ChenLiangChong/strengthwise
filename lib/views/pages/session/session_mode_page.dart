// ✅ 已響應式改造 (Phase 0) - 通過 Tab 子組件處理
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:strengthwise/controllers/session_mode_controller.dart';
import 'package:strengthwise/controllers/drawing_controller.dart';
import 'package:strengthwise/controllers/session_note_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/interfaces/i_drawing_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/views/pages/session/tabs/session_execution_tab.dart';
import 'package:strengthwise/views/pages/workout/execution/workout_execution_content.dart';
import 'package:strengthwise/views/pages/session/tabs/session_statistics_tab.dart';
import 'package:strengthwise/views/pages/session/tabs/health_assessment_tab.dart';
import 'package:strengthwise/views/pages/session/widgets/session_speed_dial.dart';
import 'package:strengthwise/views/pages/notes/drawing_canvas_page.dart';
import 'package:strengthwise/views/pages/notes/widgets/photo_picker_sheet.dart';
import 'package:strengthwise/views/pages/readiness/readiness_form_page.dart';
import 'dart:io';

/// Session Mode 頁面
///
/// 教練帶學員上課時的專屬模式，包含：
/// - Tab 1: 課程執行（訓練動作、學員筆記、計時器）
/// - Tab 2: 近期統計（7 天訓練總覽）
/// - Tab 3: 健康評估（教練偏好部位）
///
/// ⭐ v3.1: 學員也可以進入，但只能查看和填問卷
class SessionModePage extends StatelessWidget {
  /// 預約 ID
  final String appointmentId;

  /// 學員 ID
  final String clientId;

  /// 學員名稱
  final String clientName;

  /// 課程開始時間
  final DateTime sessionStartTime;

  /// 課程結束時間
  final DateTime sessionEndTime;

  /// 訓練計畫 ID（可選）
  final String? workoutPlanId;

  /// 是否為教練模式 ⭐ v3.1
  ///
  /// - true: 教練端，可編輯訓練計畫、打勾、寫筆記
  /// - false: 學員端，只能查看和填問卷
  final bool isCoachMode;

  const SessionModePage({
    super.key,
    required this.appointmentId,
    required this.clientId,
    required this.clientName,
    required this.sessionStartTime,
    required this.sessionEndTime,
    this.workoutPlanId,
    this.isCoachMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SessionModeController(
        appointmentId: appointmentId,
        clientId: clientId,
        clientName: clientName,
        sessionStartTime: sessionStartTime,
        sessionEndTime: sessionEndTime,
        workoutPlanId: workoutPlanId,
        isCoachMode: isCoachMode,
      ),
      child: _SessionModeContent(isCoachMode: isCoachMode),
    );
  }
}

/// Session Mode 內容
class _SessionModeContent extends StatefulWidget {
  final bool isCoachMode;

  const _SessionModeContent({required this.isCoachMode});

  @override
  State<_SessionModeContent> createState() => _SessionModeContentState();
}

class _SessionModeContentState extends State<_SessionModeContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// ⭐ v3.1: GlobalKey 用於調用 WorkoutExecutionContent 的方法
  final GlobalKey<WorkoutExecutionContentState> _workoutContentKey =
      GlobalKey<WorkoutExecutionContentState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<SessionModeController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: _buildTitle(controller),
            actions: [
              // ⭐ v3.1: 學員模式顯示填問卷按鈕
              if (!widget.isCoachMode)
                IconButton(
                  onPressed: () =>
                      _navigateToReadinessForm(context, controller),
                  icon: const Icon(Icons.assignment_outlined),
                  tooltip: '填寫課前問卷',
                ),
              // 結束課程按鈕（僅教練可見）
              if (widget.isCoachMode)
                IconButton(
                  onPressed: controller.canEndSession
                      ? () => _showEndSessionDialog(context, controller)
                      : null,
                  icon: const Icon(Icons.stop_circle_outlined),
                  tooltip: '結束課程',
                  style: IconButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.fitness_center),
                  text: '課程執行',
                ),
                Tab(
                  icon: Icon(Icons.insights),
                  text: '近期統計',
                ),
                Tab(
                  icon: Icon(Icons.medical_information),
                  text: '健康評估',
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // ⭐ v3.1.1: 課程已完成提示橫幅（從 controller 讀取狀態）
              if (controller.isSessionCompleted)
                _buildSessionCompletedBanner(context, controller),
              // Tab 內容
              Expanded(
                child: Stack(
                  children: [
                    TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: 課程執行
                        SessionExecutionTab(
                          workoutContentKey: _workoutContentKey,
                        ),
                        // Tab 2: 近期統計
                        const SessionStatisticsTab(),
                        // Tab 3: 健康評估
                        const HealthAssessmentTab(),
                      ],
                    ),
                    // ⭐ v3.1: 展開式 FAB（僅教練可見）
                    if (widget.isCoachMode)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: SessionSpeedDial(
                          onPhoto: () => _handlePhoto(context, controller),
                          onDrawing: (templateType) => _navigateToDrawingCanvas(
                              context, controller, templateType),
                          onAddExercise: () => _handleAddExercise(context),
                          showAddExercise: controller.hasWorkoutPlan,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 標題（顯示學員名稱和課程時間）
  Widget _buildTitle(SessionModeController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          controller.clientName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          _formatSessionTime(controller),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  /// 格式化課程時間
  String _formatSessionTime(SessionModeController controller) {
    final start = controller.sessionStartTime;
    final end = controller.sessionEndTime;
    return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - '
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }

  /// ⭐ v3.1.1: 課程已完成提示橫幅
  Widget _buildSessionCompletedBanner(
    BuildContext context,
    SessionModeController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final remainingMinutes = controller.remainingEditMinutes;
    final isExpired = remainingMinutes <= 0;

    // 根據角色和時間狀態決定提示文字
    String message;
    if (widget.isCoachMode) {
      if (isExpired) {
        message = '課程已完成';
      } else {
        // 格式化剩餘時間
        String timeText;
        if (remainingMinutes >= 60) {
          final hours = remainingMinutes ~/ 60;
          final mins = remainingMinutes % 60;
          timeText = mins > 0 ? '$hours 小時 $mins 分鐘' : '$hours 小時';
        } else {
          timeText = '$remainingMinutes 分鐘';
        }
        message = '課程已完成，您仍然可以在 $timeText 內編輯訓練計畫';
      }
    } else {
      // 學員端
      message = '課程已完成';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 20,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// 結束課程對話框
  Future<void> _showEndSessionDialog(
    BuildContext context,
    SessionModeController controller,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('結束課程'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('確定要結束這堂課程嗎？'),
            const SizedBox(height: 16),
            // SOAP 筆記狀態
            _buildSoapStatus(controller, colorScheme),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('繼續編輯筆記'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            child: const Text('確定結束'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await controller.endSession();

      if (context.mounted) {
        // ⭐ v3.1.1: SOAP 未填寫完畢時，彈窗提醒
        final soapStatus = controller.soapStatus;
        final allFilled = soapStatus.values.every((filled) => filled);

        if (!allFilled) {
          final goToSoap = await _showSoapReminderDialog(context);
          if (goToSoap == true && context.mounted) {
            // 切換到 Session 執行 Tab（SOAP 在那裡）
            // 不離開頁面，讓教練填寫
            return;
          }
        }

        if (context.mounted) {
          Navigator.of(context).pop(true); // 返回上一頁
        }
      }
    }
  }

  /// ⭐ v3.1.1: SOAP 提醒彈窗
  Future<bool?> _showSoapReminderDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.note_alt_outlined, size: 48),
        title: const Text('課程已結束'),
        content: const Text(
          'SOAP 筆記尚未填寫完畢，要現在填寫嗎？\n\n'
          '填寫 SOAP 有助於追蹤學員進度和課程記錄。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('稍後填寫'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('現在填寫'),
          ),
        ],
      ),
    );
  }

  /// SOAP 填寫狀態
  Widget _buildSoapStatus(
    SessionModeController controller,
    ColorScheme colorScheme,
  ) {
    final soapStatus = controller.soapStatus;
    final allFilled = soapStatus.values.every((filled) => filled);

    if (allFilled) {
      return Row(
        children: [
          Icon(Icons.check_circle, color: const Color(0xFF10B981), size: 20),
          const SizedBox(width: 8),
          const Text('SOAP 筆記已填寫完成'),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1), // Warning
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber,
                  color: const Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 8),
              const Text('SOAP 筆記尚未填寫完成'),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildSoapChip('主觀', soapStatus['subjective'] ?? false),
              _buildSoapChip('客觀', soapStatus['objective'] ?? false),
              _buildSoapChip('評估', soapStatus['assessment'] ?? false),
              _buildSoapChip('計畫', soapStatus['plan'] ?? false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoapChip(String label, bool filled) {
    return Chip(
      label: Text(label),
      avatar: Icon(
        filled ? Icons.check : Icons.close,
        size: 16,
        color: filled ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      ),
      backgroundColor: filled
          ? const Color(0xFF10B981).withValues(alpha: 0.1) // Success
          : const Color(0xFFEF4444).withValues(alpha: 0.1), // Error
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  /// ⭐ v3.1: 處理照相功能
  Future<void> _handlePhoto(
    BuildContext context,
    SessionModeController controller,
  ) async {
    // 確認有 Session Note
    if (controller.sessionNoteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請先建立課程筆記'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 顯示照片選擇器
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => const PhotoPickerSheet(),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final noteController = serviceLocator<SessionNoteController>();
      final authController = serviceLocator<IAuthController>();

      if (authController.user == null) {
        throw Exception('用戶未登入');
      }

      // 上傳照片
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('正在上傳照片...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final url = await noteController.uploadPhoto(
        coachId: authController.user!.uid,
        clientId: controller.clientId,
        file: file,
      );

      if (url != null && context.mounted) {
        // ⭐ v3.1: 將照片添加到 session_notes.visual_elements
        await controller.addPhotoToNote(url);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('照片已添加到課程筆記'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[SESSION_MODE] 照片處理失敗: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('照片處理失敗: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// ⭐ v3.1: 處理新增動作
  void _handleAddExercise(BuildContext context) {
    // ⭐ v3.1: 透過 GlobalKey 調用 WorkoutExecutionContent 的新增動作方法
    final state = _workoutContentKey.currentState;
    if (state != null) {
      state.addNewExercise();
    } else {
      // 如果尚未初始化（例如沒有訓練計畫），顯示提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請先創建訓練計畫'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 導航到繪圖畫布
  void _navigateToDrawingCanvas(
    BuildContext context,
    SessionModeController controller,
    String templateType,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider<DrawingController>(
          create: (_) => DrawingController(
            serviceLocator<IDrawingService>(),
            serviceLocator<ErrorHandlingService>(),
          ),
          child: DrawingCanvasPage(
            sessionNoteId: controller.sessionNoteId!,
            templateType: templateType,
          ),
        ),
      ),
    );
  }

  /// 導航到課前問卷填寫頁面 ⭐ v3.1
  void _navigateToReadinessForm(
    BuildContext context,
    SessionModeController controller,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadinessFormPage(
          appointmentId: controller.appointmentId,
          coachName: controller.clientName, // 學員視角：顯示教練名稱
          sessionTime: controller.sessionStartTime,
        ),
      ),
    );
  }
}
