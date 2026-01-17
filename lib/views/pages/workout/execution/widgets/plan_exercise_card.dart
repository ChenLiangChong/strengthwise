// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:strengthwise/common_widgets/time_picker/time_input_field.dart';
import 'package:strengthwise/models/workout_exercise_model.dart';
import 'package:strengthwise/models/tracking_mode.dart'; // v3.2+
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/views/pages/workout/execution/widgets/set_edit_dialog.dart';

/// 計劃動作卡片（顯示和編輯）
///
/// 支援兩種模式：
/// - 計劃模式：編輯訓練計畫（原有功能）
/// - Session 模式：教練帶課時使用（打勾 + PREV）
class PlanExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;

  /// 批量更新所有組的預設目標值
  final Function(Map<String, dynamic> values) onBatchUpdate;
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
    required this.onBatchUpdate,
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
  State<PlanExerciseCard> createState() => _PlanExerciseCardState();
}

class _PlanExerciseCardState extends State<PlanExerciseCard> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _timeController;
  late TextEditingController _distanceController;
  late TextEditingController _caloriesController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(PlanExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 當 exercise 改變時，更新控制器（例如外部調整組數）
    if (oldWidget.exercise != widget.exercise) {
      _updateControllersIfNeeded();
    }
  }

  void _initControllers() {
    _repsController =
        TextEditingController(text: widget.exercise.reps.toString());
    _weightController =
        TextEditingController(text: widget.exercise.weight.toString());
    _timeController =
        TextEditingController(text: (widget.exercise.time ?? 0).toString());
    _distanceController =
        TextEditingController(text: (widget.exercise.distance ?? 0).toString());
    _caloriesController =
        TextEditingController(text: (widget.exercise.calories ?? 0).toString());
  }

  void _updateControllersIfNeeded() {
    // 只在值真正改變時更新（避免用戶輸入時被覆蓋）
    final currentReps = int.tryParse(_repsController.text) ?? 0;
    final currentWeight = double.tryParse(_weightController.text) ?? 0;

    if (currentReps != widget.exercise.reps) {
      _repsController.text = widget.exercise.reps.toString();
    }
    if (currentWeight != widget.exercise.weight) {
      _weightController.text = widget.exercise.weight.toString();
    }
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _timeController.dispose();
    _distanceController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  /// 當輸入欄位編輯完成時觸發批量更新
  void _onFieldEditingComplete() {
    final mode = widget.exercise.trackingMode;
    final values = <String, dynamic>{};

    if (mode.needsReps) {
      values['reps'] =
          int.tryParse(_repsController.text) ?? widget.exercise.reps;
    }
    if (mode.needsWeight) {
      values['weight'] =
          double.tryParse(_weightController.text) ?? widget.exercise.weight;
    }
    if (mode.needsTime) {
      values['time'] =
          int.tryParse(_timeController.text) ?? widget.exercise.time ?? 0;
    }
    if (mode.needsDistance) {
      values['distance'] = double.tryParse(_distanceController.text) ??
          widget.exercise.distance ??
          0;
    }
    if (mode.needsCalories) {
      values['calories'] = double.tryParse(_caloriesController.text) ??
          widget.exercise.calories ??
          0;
    }

    widget.onBatchUpdate(values);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final exercise = widget.exercise;
    final isEditable = !widget.isSessionMode && !widget.readOnly;

    return Card(
      key: Key(exercise.id),
      margin: EdgeInsets.symmetric(vertical: context.spacing.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 動作標題和操作按鈕
          _buildHeader(context, colorScheme),
          const Divider(height: 1),

          // 表頭（SET | KG | REPS 等）
          _buildTableHeader(context, colorScheme),

          // 每組列表
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSetsList(context, colorScheme),
          ),

          const SizedBox(height: 8),

          // 新增/減少組數按鈕（僅計劃模式）
          if (isEditable) _buildAddRemoveSetButtons(context, colorScheme),

          // 休息時間和備註
          _buildFooter(context, colorScheme),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 表頭（SET | KG | REPS 等）
  Widget _buildTableHeader(BuildContext context, ColorScheme colorScheme) {
    final mode = widget.exercise.trackingMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildHeaderCell(context, 'SET', width: 40),
          const SizedBox(width: 8),
          // 根據 trackingMode 顯示不同表頭
          ..._buildTrackingModeHeaders(context, mode),
        ],
      ),
    );
  }

  /// 根據追蹤模式構建表頭欄位
  List<Widget> _buildTrackingModeHeaders(
      BuildContext context, TrackingMode mode) {
    switch (mode) {
      case TrackingMode.weightReps:
        return [
          _buildHeaderCell(context, 'REPS', flex: 3),
          const SizedBox(width: 8),
          _buildHeaderCell(context, 'KG', flex: 3),
        ];
      case TrackingMode.weightTime:
        return [
          _buildHeaderCell(context, 'KG', flex: 3),
          const SizedBox(width: 8),
          _buildHeaderCell(context, 'TIME', flex: 3),
        ];
      case TrackingMode.repsOnly:
        return [
          _buildHeaderCell(context, 'REPS', flex: 6),
        ];
      case TrackingMode.timeOnly:
        return [
          _buildHeaderCell(context, 'TIME', flex: 6),
        ];
      case TrackingMode.repsTime:
        return [
          _buildHeaderCell(context, 'REPS', flex: 3),
          const SizedBox(width: 8),
          _buildHeaderCell(context, 'TIME', flex: 3),
        ];
      case TrackingMode.distanceTime:
        return [
          _buildHeaderCell(context, 'DIST', flex: 3),
          const SizedBox(width: 8),
          _buildHeaderCell(context, 'TIME', flex: 3),
        ];
      case TrackingMode.distanceOnly:
        return [
          _buildHeaderCell(context, 'DIST', flex: 6),
        ];
      case TrackingMode.calories:
        return [
          _buildHeaderCell(context, 'KCAL', flex: 6),
        ];
    }
  }

  /// 表頭單元格
  Widget _buildHeaderCell(BuildContext context, String text,
      {double? width, int? flex}) {
    final colorScheme = Theme.of(context).colorScheme;

    final cell = Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withOpacity(0.4),
          letterSpacing: 1,
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: cell);
    } else if (flex != null) {
      return Expanded(flex: flex, child: cell);
    }
    return cell;
  }

  /// 新增/減少組數按鈕
  Widget _buildAddRemoveSetButtons(
      BuildContext context, ColorScheme colorScheme) {
    final canRemove = widget.exercise.sets > 1;
    final canAdd = widget.exercise.sets < 10;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 新增按鈕
          Expanded(
            child: TextButton(
              onPressed: canAdd ? () => widget.onAdjustSets(1) : null,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('新增',
                      style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 減少按鈕
          Expanded(
            child: TextButton(
              onPressed: canRemove ? () => widget.onAdjustSets(-1) : null,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                backgroundColor:
                    colorScheme.error.withOpacity(canRemove ? 0.1 : 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove,
                      size: 18,
                      color: canRemove
                          ? colorScheme.error
                          : colorScheme.error.withOpacity(0.3)),
                  const SizedBox(width: 4),
                  Text('減少',
                      style: TextStyle(
                          color: canRemove
                              ? colorScheme.error
                              : colorScheme.error.withOpacity(0.3),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 標題區域
  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    final exercise = widget.exercise;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 動作名稱與備註
          Expanded(
            child: GestureDetector(
              onTap: widget.isSessionMode ? widget.onShowHistory : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exercise.equipment} | ${exercise.bodyParts.join(", ")}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
          ),
          // Session 模式：顯示歷史記錄按鈕
          if (widget.isSessionMode && widget.onShowHistory != null)
            IconButton(
              icon: const Icon(Icons.history),
              iconSize: 20,
              color: colorScheme.primary,
              onPressed: widget.onShowHistory,
              tooltip: '查看歷史記錄',
            ),
          // 計劃模式：批量編輯和刪除按鈕
          if (!widget.isSessionMode && !widget.readOnly) ...[
            // 批量編輯按鈕（一次設定所有組的預設值）
            IconButton(
              icon: const Icon(Icons.edit_note),
              iconSize: 24,
              color: colorScheme.primary,
              onPressed: _showBatchEditDialog,
              tooltip: '批量編輯',
            ),
            // 刪除按鈕
            IconButton(
              icon: const Icon(Icons.delete_outline),
              iconSize: 24,
              color: colorScheme.error.withOpacity(0.7),
              onPressed: widget.onDelete,
              tooltip: '刪除動作',
            ),
          ],
        ],
      ),
    );
  }

  /// 顯示批量編輯對話框
  void _showBatchEditDialog() async {
    final exercise = widget.exercise;
    final mode = exercise.trackingMode;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BatchSetEditDialog(
        initialReps: exercise.reps,
        initialWeight: exercise.weight,
        initialTime: exercise.time,
        initialDistance: exercise.distance,
        initialCalories: exercise.calories,
        trackingMode: mode,
      ),
    );

    if (result != null) {
      widget.onBatchUpdate(result);
    }
  }

  /// 每組列表
  Widget _buildSetsList(BuildContext context, ColorScheme colorScheme) {
    final exercise = widget.exercise;
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
  /// v3.2+ 根據 trackingMode 顯示不同欄位，計劃模式下直接顯示可編輯欄位
  Widget _buildSetRow(
      BuildContext context, ColorScheme colorScheme, int setIndex) {
    final exercise = widget.exercise;
    final trackingMode = exercise.trackingMode;

    // 獲取這一組的目標
    int targetReps;
    double targetWeight;
    int? targetTime;
    double? targetDistance;
    double? targetCalories;

    if (exercise.setTargets != null && setIndex < exercise.setTargets!.length) {
      final target = exercise.setTargets![setIndex];
      targetReps = target['reps'] as int? ?? exercise.reps;
      targetWeight = (target['weight'] as num?)?.toDouble() ?? exercise.weight;
      targetTime = target['time'] as int? ?? exercise.time;
      targetDistance =
          (target['distance'] as num?)?.toDouble() ?? exercise.distance;
      targetCalories =
          (target['calories'] as num?)?.toDouble() ?? exercise.calories;
    } else {
      targetReps = exercise.reps;
      targetWeight = exercise.weight;
      targetTime = exercise.time;
      targetDistance = exercise.distance;
      targetCalories = exercise.calories;
    }

    final isCompleted = widget.completedSets?.contains(setIndex) ?? false;

    // 獲取 PREV 數據
    final prevRecord = widget.previousRecords?[setIndex];
    final hasPrev = prevRecord != null;
    final isEditable = !widget.isSessionMode && !widget.readOnly;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // SET 組數（固定寬度）
          SizedBox(
            width: 40,
            child: Center(
              child: isCompleted
                  ? Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.check,
                          size: 16, color: Colors.white),
                    )
                  : Text(
                      '${setIndex + 1}',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),

          // 根據 trackingMode 構建輸入欄位（使用 Expanded flex）
          ..._buildTrackingModeInputFields(
            context,
            colorScheme,
            trackingMode,
            setIndex,
            isEditable,
            targetReps,
            targetWeight,
            targetTime,
            targetDistance,
            targetCalories,
          ),

          // Session 模式：打勾框
          if (widget.isSessionMode) ...[
            const SizedBox(width: 8),
            _buildCheckbox(context, colorScheme, setIndex, isCompleted),
          ],
        ],
      ),
    );
  }

  /// 根據 trackingMode 構建輸入欄位（使用 Expanded flex，與 ExerciseCard 相同）
  List<Widget> _buildTrackingModeInputFields(
    BuildContext context,
    ColorScheme colorScheme,
    TrackingMode mode,
    int setIndex,
    bool isEditable,
    int targetReps,
    double targetWeight,
    int? targetTime,
    double? targetDistance,
    double? targetCalories,
  ) {
    switch (mode) {
      case TrackingMode.weightReps:
        return [
          Expanded(
            flex: 3,
            child: _buildNumberInputField(
              context,
              colorScheme,
              setIndex,
              'reps',
              value: targetReps.toString(),
              hintText: 'reps',
              isEditable: isEditable,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _buildNumberInputField(
              context,
              colorScheme,
              setIndex,
              'weight',
              value: targetWeight.toString(),
              hintText: 'kg',
              isEditable: isEditable,
              isDecimal: true,
            ),
          ),
        ];
      case TrackingMode.weightTime:
        return [
          Expanded(
            flex: 3,
            child: _buildNumberInputField(
              context,
              colorScheme,
              setIndex,
              'weight',
              value: targetWeight.toString(),
              hintText: 'kg',
              isEditable: isEditable,
              isDecimal: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _buildTimeInputField(
              context,
              colorScheme,
              setIndex,
              value: targetTime,
              isEditable: isEditable,
            ),
          ),
        ];
      case TrackingMode.repsOnly:
        return [
          Expanded(
            flex: 6,
            child: _buildNumberInputField(
              context,
              colorScheme,
              setIndex,
              'reps',
              value: targetReps.toString(),
              hintText: 'reps',
              isEditable: isEditable,
            ),
          ),
        ];
      case TrackingMode.timeOnly:
        return [
          Expanded(
            flex: 6,
            child: _buildTimeInputField(
              context,
              colorScheme,
              setIndex,
              value: targetTime,
              isEditable: isEditable,
            ),
          ),
        ];
      case TrackingMode.repsTime:
        return [
          Expanded(
            flex: 3,
            child: _buildNumberInputField(
              context,
              colorScheme,
              setIndex,
              'reps',
              value: targetReps.toString(),
              hintText: 'reps',
              isEditable: isEditable,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _buildTimeInputField(
              context,
              colorScheme,
              setIndex,
              value: targetTime,
              isEditable: isEditable,
            ),
          ),
        ];
      case TrackingMode.distanceTime:
        return [
          Expanded(
            flex: 3,
            child: _buildNumberInputField(
              context,
              colorScheme,
              setIndex,
              'distance',
              value: (targetDistance ?? 0).toString(),
              hintText: 'm',
              isEditable: isEditable,
              isDecimal: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _buildTimeInputField(
              context,
              colorScheme,
              setIndex,
              value: targetTime,
              isEditable: isEditable,
            ),
          ),
        ];
      case TrackingMode.distanceOnly:
        return [
          Expanded(
            flex: 6,
            child: _buildNumberInputField(
              context,
              colorScheme,
              setIndex,
              'distance',
              value: (targetDistance ?? 0).toString(),
              hintText: 'm',
              isEditable: isEditable,
              isDecimal: true,
            ),
          ),
        ];
      case TrackingMode.calories:
        return [
          Expanded(
            flex: 6,
            child: _buildNumberInputField(
              context,
              colorScheme,
              setIndex,
              'calories',
              value: (targetCalories ?? 0).toString(),
              hintText: 'kcal',
              isEditable: isEditable,
              isDecimal: true,
            ),
          ),
        ];
    }
  }

  /// 構建數字輸入框（與 ExerciseCard 相同樣式）
  Widget _buildNumberInputField(
    BuildContext context,
    ColorScheme colorScheme,
    int setIndex,
    String fieldKey, {
    required String value,
    required String hintText,
    required bool isEditable,
    bool isDecimal = false,
  }) {
    return TextFormField(
      initialValue: value,
      enabled: isEditable,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'JetBrains Mono',
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 14,
          color: colorScheme.onSurface.withOpacity(0.3),
        ),
        filled: true,
        fillColor: isEditable
            ? colorScheme.surface
            : colorScheme.surface.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 8,
        ),
      ),
      onChanged: (newValue) {
        if (isDecimal) {
          _updateSetTarget(setIndex, fieldKey, double.tryParse(newValue) ?? 0);
        } else {
          _updateSetTarget(setIndex, fieldKey, int.tryParse(newValue) ?? 0);
        }
      },
    );
  }

  /// 更新單組的目標值
  void _updateSetTarget(int setIndex, String key, dynamic value) {
    // 通過 onEditSet 回調傳遞更新
    // 這裡需要修改 onEditSet 的簽名以支援直接傳遞值
    // 或者使用新的回調
    final currentTarget = <String, dynamic>{};
    final exercise = widget.exercise;

    // 從現有 setTargets 獲取或使用預設值
    if (exercise.setTargets != null && setIndex < exercise.setTargets!.length) {
      currentTarget.addAll(exercise.setTargets![setIndex]);
    } else {
      final mode = exercise.trackingMode;
      if (mode.needsReps) currentTarget['reps'] = exercise.reps;
      if (mode.needsWeight) currentTarget['weight'] = exercise.weight;
      if (mode.needsTime) currentTarget['time'] = exercise.time ?? 0;
      if (mode.needsDistance) {
        currentTarget['distance'] = exercise.distance ?? 0;
      }
      if (mode.needsCalories) {
        currentTarget['calories'] = exercise.calories ?? 0;
      }
    }

    // 更新指定的欄位
    currentTarget[key] = value;

    // 通過 onBatchUpdate 傳遞完整的更新資訊
    // 由於我們需要知道是哪一組，需要擴展回調
    widget.onBatchUpdate({'setIndex': setIndex, ...currentTarget});
  }

  /// ⭐ v3.7+: 時間輸入欄位（mm:ss 格式）
  Widget _buildTimeInputField(
    BuildContext context,
    ColorScheme colorScheme,
    int setIndex, {
    required int? value,
    required bool isEditable,
  }) {
    return TimeInputField(
      value: value,
      enabled: isEditable,
      onChanged: (seconds) {
        _updateSetTarget(setIndex, 'time', seconds ?? 0);
      },
      minWidth: 60,
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
      onChanged: (widget.readOnly || !widget.canMarkSet)
          ? null
          : (value) {
              HapticFeedback.lightImpact();
              widget.onSetCompleted?.call(setIndex, value ?? false);
            },
      activeColor: const Color(0xFF10B981),
      side: BorderSide(
        color: widget.canMarkSet
            ? colorScheme.outline
            : colorScheme.outlineVariant,
        width: 2,
      ),
    );
  }

  /// 底部資訊
  Widget _buildFooter(BuildContext context, ColorScheme colorScheme) {
    final exercise = widget.exercise;
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
