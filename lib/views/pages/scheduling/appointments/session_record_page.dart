// ✅ 已響應式改造 (Phase 0)
// ✅ v3.6: MVVM 重構 - 移除 Service 直接調用
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/models/appointment_model.dart';
import 'package:strengthwise/models/workout_record/workout_record.dart';
import 'package:strengthwise/models/session_note/session_note_model.dart';
import 'package:strengthwise/models/readiness/daily_readiness_model.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/controllers/interfaces/i_workout_controller.dart'; // ⭐ v3.6: MVVM
import 'package:strengthwise/controllers/interfaces/i_session_note_controller.dart'; // ⭐ v3.6: MVVM
import 'package:strengthwise/controllers/interfaces/i_appointment_controller.dart'; // ⭐ v3.6: MVVM
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/views/pages/session/widgets/readiness_card.dart';

/// 課程紀錄頁面（學員視角）⭐ v3.0
///
/// 讓學員在課後查看：
/// - 訓練記錄（動作、組數、重量）
/// - 課程筆記（若教練設為分享）
/// - 課前問卷結果
class SessionRecordPage extends StatefulWidget {
  /// 預約資訊
  final AppointmentModel appointment;

  const SessionRecordPage({
    super.key,
    required this.appointment,
  });

  @override
  State<SessionRecordPage> createState() => _SessionRecordPageState();
}

class _SessionRecordPageState extends State<SessionRecordPage> {
  // ⭐ v3.6: MVVM 重構 - 全部透過 Controller
  late final IWorkoutController _workoutController;
  late final ISessionNoteController _sessionNoteController;
  late final IAppointmentController _appointmentController;
  late final ErrorHandlingService _errorService;

  bool _isLoading = true;
  WorkoutRecord? _workoutRecord;
  SessionNoteModel? _sessionNote;
  DailyReadinessModel? _readiness;

  @override
  void initState() {
    super.initState();
    _workoutController = serviceLocator<IWorkoutController>();
    _sessionNoteController = serviceLocator<ISessionNoteController>();
    _appointmentController = serviceLocator<IAppointmentController>();
    _errorService = serviceLocator<ErrorHandlingService>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // ⭐ v3.6: 全部透過 Controller 查詢
      // 1. 載入訓練記錄
      if (widget.appointment.workoutPlanId != null) {
        _workoutRecord = await _workoutController.getRecordById(
          widget.appointment.workoutPlanId!,
        );
      }

      // 2. 載入課程筆記（只載入分享的）
      final notes = await _sessionNoteController.getNotesByAppointment(
        appointmentId: widget.appointment.id,
      );
      // 學員只能看到 visibility = 'shared' 的記錄（RLS 會過濾）
      if (notes.isNotEmpty) {
        _sessionNote = notes.first;
      }

      // 3. 載入課前問卷
      _readiness = await _appointmentController.getReadinessByAppointmentId(
        widget.appointment.id,
      );
    } catch (e) {
      if (mounted) {
        _errorService.handleError(context, e, customMessage: '載入課程紀錄失敗');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('課程紀錄'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: context.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 課程資訊卡
                        _buildSessionInfoCard(theme, colorScheme),

                        const SizedBox(height: 16),

                        // 課前問卷結果
                        if (_readiness != null) ...[
                          ReadinessCard(readiness: _readiness),
                          const SizedBox(height: 16),
                        ],

                        // 訓練記錄
                        _buildWorkoutSection(theme, colorScheme),

                        const SizedBox(height: 16),

                        // 課程筆記（共享的）
                        if (_sessionNote != null)
                          _buildNotesSection(theme, colorScheme),

                        // 空狀態
                        if (_workoutRecord == null && _sessionNote == null && _readiness == null)
                          _buildEmptyState(colorScheme),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  /// 課程資訊卡
  Widget _buildSessionInfoCard(ThemeData theme, ColorScheme colorScheme) {
    final apt = widget.appointment;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${apt.startTime.year}/${apt.startTime.month}/${apt.startTime.day}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '已完成',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  '${_formatTime(apt.startTime)} - ${_formatTime(apt.endTime)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${apt.durationMinutes} 分鐘',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 訓練記錄區塊
  Widget _buildWorkoutSection(ThemeData theme, ColorScheme colorScheme) {
    final workoutRecord = _workoutRecord;
    if (workoutRecord == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.fitness_center,
                size: 48,
                color: colorScheme.outlineVariant,
              ),
              const SizedBox(height: 12),
              Text(
                '此課程尚無訓練記錄',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final exerciseRecords = workoutRecord.exerciseRecords;

    // 計算統計數據
    final totalSets = exerciseRecords.fold<int>(
      0, (sum, e) => sum + e.sets.length,
    );
    final totalVolume = exerciseRecords.fold<double>(
      0, (sum, e) => sum + e.sets.fold<double>(
        0, (s, set) => s + (set.weight * set.reps),
      ),
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.fitness_center, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '訓練記錄',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${exerciseRecords.length} 個動作',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 統計數據
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  '總組數',
                  '$totalSets',
                  Icons.repeat,
                ),
                _buildStatItem(
                  context,
                  '總訓練量',
                  '${totalVolume.toStringAsFixed(0)} kg',
                  Icons.scale,
                ),
                _buildStatItem(
                  context,
                  '時長',
                  '${workoutRecord.elapsedSeconds ~/ 60} 分',
                  Icons.timer,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 動作列表
          ...exerciseRecords.map((exercise) => _buildExerciseItem(
            theme,
            colorScheme,
            exercise,
          )),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseItem(
    ThemeData theme,
    ColorScheme colorScheme,
    dynamic exercise,
  ) {
    // exercise 是 ExerciseRecord
    final name = exercise.exerciseName ?? '未知動作';
    final setsCount = exercise.sets.length;
    // 取第一組的 reps 和 weight 作為代表
    final firstSet = exercise.sets.isNotEmpty 
        ? exercise.sets.first 
        : null;
    final reps = firstSet?.reps ?? 0;
    final weight = firstSet?.weight ?? 0.0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(Icons.fitness_center, color: colorScheme.primary, size: 18),
      ),
      title: Text(name),
      subtitle: Text('$setsCount 組 × $reps 次 @ ${weight.toStringAsFixed(1)}kg'),
    );
  }

  /// 課程筆記區塊
  Widget _buildNotesSection(ThemeData theme, ColorScheme colorScheme) {
    final sessionNote = _sessionNote;
    if (sessionNote == null) return const SizedBox.shrink();

    final soap = sessionNote.soap;
    final subjective = soap?.subjective;
    final objective = soap?.objective;
    final assessment = soap?.assessment;
    final plan = soap?.plan;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '教練筆記',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // SOAP 格式顯示
            if (subjective != null && subjective.isNotEmpty)
              _buildSoapField(theme, 'S - 主觀', subjective),
            if (objective != null && objective.isNotEmpty)
              _buildSoapField(theme, 'O - 客觀', objective),
            if (assessment != null && assessment.isNotEmpty)
              _buildSoapField(theme, 'A - 評估', assessment),
            if (plan != null && plan.isNotEmpty)
              _buildSoapField(theme, 'P - 計劃', plan),
          ],
        ),
      ),
    );
  }

  Widget _buildSoapField(ThemeData theme, String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// 空狀態
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '此課程尚無相關紀錄',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '訓練記錄和筆記將在教練建立後顯示',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
