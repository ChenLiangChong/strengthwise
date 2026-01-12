import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/session_mode_controller.dart';
import 'package:strengthwise/models/health_assessment/health_assessment_model.dart';
import 'package:strengthwise/models/coach_display_preferences_model.dart';
import 'package:strengthwise/models/coach_assessment_note_model.dart';
import 'package:strengthwise/models/injury_coach_note_model.dart'; // ⭐ v3.4
import 'package:strengthwise/services/interfaces/i_health_assessment_service.dart';
import 'package:strengthwise/services/interfaces/i_coach_display_preferences_service.dart';
import 'package:strengthwise/services/interfaces/i_coach_assessment_note_service.dart';
import 'package:strengthwise/services/interfaces/i_injury_coach_note_service.dart'; // ⭐ v3.4
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/views/pages/profile/health_assessment_detail_page.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/widgets/health_assessment_summary_card.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/widgets/empty_health_assessment_card.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/health_assessment_page.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/coach_display_preferences_page.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/common_widgets/loading/skeleton_loader.dart';

/// 健康評估 Tab
///
/// 複用現有的 HealthAssessmentSummaryCard，顯示教練偏好的學員資訊
class HealthAssessmentTab extends StatefulWidget {
  const HealthAssessmentTab({super.key});

  @override
  State<HealthAssessmentTab> createState() => _HealthAssessmentTabState();
}

class _HealthAssessmentTabState extends State<HealthAssessmentTab> {
  late final IHealthAssessmentService _healthAssessmentService;
  late final ICoachDisplayPreferencesService _preferencesService;
  late final ICoachAssessmentNoteService _assessmentNoteService;
  late final IInjuryCoachNoteService _injuryNoteService; // ⭐ v3.4
  late final IAuthController _authController;

  HealthAssessmentModel? _healthAssessment;
  CoachDisplayPreferencesModel? _displayPreferences;
  CoachAssessmentNoteModel? _coachNote;
  Map<String, List<InjuryCoachNoteModel>> _injuryCoachNotes = {}; // ⭐ v3.4
  bool _isLoading = true;

  /// 取得當前用戶 ID（教練 ID）
  String? get _coachId => _authController.user?.uid;

  @override
  void initState() {
    super.initState();
    _healthAssessmentService = serviceLocator<IHealthAssessmentService>();
    _preferencesService = serviceLocator<ICoachDisplayPreferencesService>();
    _assessmentNoteService = serviceLocator<ICoachAssessmentNoteService>();
    _injuryNoteService = serviceLocator<IInjuryCoachNoteService>(); // ⭐ v3.4
    _authController = serviceLocator<IAuthController>();

    // 延遲載入，等待 context 可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final controller = context.read<SessionModeController>();
    final clientId = controller.clientId;
    final currentUserId = _coachId;
    final isCoachMode = controller.isCoachMode;

    debugPrint('🏥 HealthAssessmentTab._loadData');
    debugPrint('   clientId: $clientId');
    debugPrint('   currentUserId: $currentUserId');
    debugPrint('   isCoachMode: $isCoachMode');

    if (currentUserId == null) {
      debugPrint('   ⚠️ currentUserId is null, aborting load');
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 學員模式：取自己的評估；教練模式：取學員的評估
      final targetUserId = isCoachMode ? clientId : currentUserId;
      debugPrint('   📥 Loading health assessment for: $targetUserId');

      final assessment =
          await _healthAssessmentService.getCurrentAssessment(targetUserId);
      debugPrint('   📊 Assessment result: ${assessment?.id ?? "null"}');

      // 教練模式才載入偏好和備註
      CoachDisplayPreferencesModel? preferences;
      CoachAssessmentNoteModel? note;

      if (isCoachMode) {
        final futures = <Future>[];
        futures.add(_preferencesService.getPreferences(currentUserId).then((p) {
          preferences = p;
        }));

        if (assessment != null) {
          futures.add(_assessmentNoteService
              .getNote(coachId: currentUserId, assessmentId: assessment.id)
              .then((n) {
            note = n;
          }));
        }

        await Future.wait(futures);
      }

      // ⭐ v3.4: 載入傷病教練備註（教練和學員都載入）
      Map<String, List<InjuryCoachNoteModel>> injuryNotes = {};
      if (assessment != null) {
        try {
          injuryNotes = await _injuryNoteService.getNotesForClient(
            clientId: assessment.userId,
          );
          debugPrint('   💬 Loaded injury notes: ${injuryNotes.length} sites');
        } catch (e) {
          debugPrint('   ⚠️ Failed to load injury notes: $e');
        }
      }

      if (mounted) {
        setState(() {
          _healthAssessment = assessment;
          _displayPreferences = preferences;
          _coachNote = note;
          _injuryCoachNotes = injuryNotes; // ⭐ v3.4
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('❌ 載入健康評估失敗: $e');
        debugPrint('   Stack: $stack');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // ⚡ 使用骨架屏取代轉圈
      return const SkeletonSessionMode();
    }

    final controller = context.read<SessionModeController>();
    final isCoachMode = controller.isCoachMode;

    // 標題：教練看學員名，學員看自己
    final title = isCoachMode
        ? '${controller.clientName} 的健康評估'
        : '我的健康評估';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 標題
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // 健康評估卡片（複用現有組件）
          if (_healthAssessment != null)
            HealthAssessmentSummaryCard(
              assessment: _healthAssessment!,
              preferences: _displayPreferences,
              coachNote: _coachNote,
              injuryCoachNotes: _injuryCoachNotes, // ⭐ v3.4: 傷病教練備註
              onViewFull: () => _navigateToDetail(),
              // 教練可編輯，學員只能查看
              onEdit: isCoachMode ? () => _navigateToEdit(controller) : null,
              onConfigurePreferences: isCoachMode ? _navigateToPreferences : null,
              onCoachNoteChanged: isCoachMode ? (note) => _saveCoachNote(note) : null,
              isClientView: !isCoachMode, // 學員模式 = 客戶視角
            )
          else
            // 空狀態
            _buildEmptyState(controller, isCoachMode),
        ],
      ),
    );
  }

  /// 空狀態：區分教練和學員
  Widget _buildEmptyState(SessionModeController controller, bool isCoachMode) {
    if (isCoachMode) {
      // 教練可以建立評估
      return EmptyHealthAssessmentCard(
        onCreateTap: () => _navigateToCreate(controller),
      );
    } else {
      // 學員看到提示
      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '尚未建立健康評估',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '教練會為你建立健康評估問卷',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }
  }

  /// 查看詳細評估
  void _navigateToDetail() {
    if (_healthAssessment == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthAssessmentDetailPage(
          assessment: _healthAssessment!,
        ),
      ),
    );
  }

  /// 編輯健康評估
  void _navigateToEdit(SessionModeController controller) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthAssessmentPage(
          clientId: controller.clientId,
          clientName: controller.clientName,
          existingAssessment: _healthAssessment,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadData(); // 重新載入
      }
    });
  }

  /// 新建健康評估
  void _navigateToCreate(SessionModeController controller) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthAssessmentPage(
          clientId: controller.clientId,
          clientName: controller.clientName,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  /// 設定顯示偏好
  void _navigateToPreferences() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CoachDisplayPreferencesPage(),
      ),
    ).then((_) {
      _loadData(); // 重新載入偏好設定
    });
  }

  /// 儲存教練備註
  Future<void> _saveCoachNote(String note) async {
    final coachId = _coachId;
    if (coachId == null || _healthAssessment == null) return;

    try {
      await _assessmentNoteService.upsertNote(
        coachId: coachId,
        assessmentId: _healthAssessment!.id,
        notes: note,
      );

      if (mounted) {
        NotificationUtils.showSuccess(context, '備註已儲存');
        _loadData(); // 重新載入
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(context, '儲存備註失敗: $e');
      }
    }
  }
}
