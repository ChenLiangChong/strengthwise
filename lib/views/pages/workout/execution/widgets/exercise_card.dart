import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:strengthwise/common_widgets/time_picker/time_input_field.dart';
import 'package:strengthwise/models/tracking_mode.dart';
import 'package:strengthwise/themes/app_theme.dart';
import 'package:strengthwise/utils/notification_utils.dart'; // v3.7+: SnackBar 提示

/// 動作卡片數據模型
/// v3.2+ 新增 trackingMode 支援不同追蹤模式
class ExerciseCardData {
  final String exerciseId;
  final String exerciseName;
  final List<SetData> sets;
  final int? targetSets;
  final int? targetReps;
  final double? targetWeight;
  final TrackingMode trackingMode; // v3.2+

  ExerciseCardData({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.targetSets,
    this.targetReps,
    this.targetWeight,
    this.trackingMode = TrackingMode.weightReps, // v3.2+
  });
}

/// 組數數據模型
/// v3.2+ 新增 time, distance, calories 欄位
class SetData {
  final int setNumber;
  final double? weight;
  final int? reps;
  final int? time; // v3.2+ 秒
  final double? distance; // v3.2+ 公尺
  final double? calories; // v3.2+ 大卡
  final bool isCompleted;
  final String? previousData; // 上一組參考數據（如 "60x10"）

  SetData({
    required this.setNumber,
    this.weight,
    this.reps,
    this.time,
    this.distance,
    this.calories,
    this.isCompleted = false,
    this.previousData,
  });

  SetData copyWith({
    int? setNumber,
    double? weight,
    int? reps,
    int? time,
    double? distance,
    double? calories,
    bool? isCompleted,
    String? previousData,
  }) {
    return SetData(
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      time: time ?? this.time,
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
      isCompleted: isCompleted ?? this.isCompleted,
      previousData: previousData ?? this.previousData,
    );
  }
}

/// 訓練動作卡片
///
/// 使用卡片式佈局展示單個動作的所有組數
/// 包含動作名稱、組數列表、新增/減少組數按鈕
class ExerciseCard extends StatelessWidget {
  /// 動作數據
  final ExerciseCardData data;

  /// 是否可編輯
  final bool isEditable;

  /// 當前活動組（高亮顯示）
  final int? activeSetNumber;

  /// 組數數據更新回調
  /// v3.2+ 支援所有追蹤模式欄位
  final Function(
    int setNumber, {
    double? weight,
    int? reps,
    int? time,
    double? distance,
    double? calories,
  }) onSetUpdate;

  /// 組數完成狀態切換回調
  final Function(int setNumber) onSetComplete;

  /// 新增組數回調
  final VoidCallback onAddSet;

  /// ⭐ v2.9.1: 減少組數回調
  final VoidCallback? onRemoveSet;

  /// ⭐ v2.9.1: 刪除動作回調
  final VoidCallback? onDelete;

  /// ⭐ v2.9.1: 是否可以刪除（用於顯示刪除按鈕）
  final bool canDelete;

  /// ⭐ v2.9.1: 備註
  final String? note;

  /// ⭐ v2.9.1: 備註變更回調
  final Function(String)? onNoteChanged;

  /// ⭐ v3.4+: 是否為教練自訂動作（用於顯示「加入我的動作庫」按鈕）
  final bool isCoachCustomExercise;

  /// ⭐ v3.4+: 加入我的動作庫回調
  final VoidCallback? onAddToMyExercises;

  const ExerciseCard({
    required this.data,
    required this.isEditable,
    this.activeSetNumber,
    required this.onSetUpdate,
    required this.onSetComplete,
    required this.onAddSet,
    this.onRemoveSet,
    this.onDelete,
    this.canDelete = false,
    this.note,
    this.onNoteChanged,
    this.isCoachCustomExercise = false, // v3.4+
    this.onAddToMyExercises, // v3.4+
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: AppTheme.spacingSm,
        horizontal: AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(
          color: AppTheme.isDarkMode(context)
              ? Colors.transparent
              : colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: AppTheme.isDarkMode(context)
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========================================
          // 卡片標題列
          // ========================================
          _buildCardHeader(context),

          const Divider(height: 1),

          // ========================================
          // 表頭（Set | Previous | kg | Reps | ✓）
          // ========================================
          _buildTableHeader(context),

          // ========================================
          // 組數列表
          // ========================================
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
            ),
            child: Column(
              // ⭐ 效能優化：添加 Key 避免不必要的重建
              children: data.sets.map((set) {
                return SetInputRow(
                  key: ValueKey('set_${data.exerciseId}_${set.setNumber}'),
                  setNumber: set.setNumber,
                  weight: set.weight,
                  reps: set.reps,
                  time: set.time, // v3.2+
                  distance: set.distance, // v3.2+
                  calories: set.calories, // v3.2+
                  trackingMode: data.trackingMode, // v3.2+
                  previousData: set.previousData,
                  isCompleted: set.isCompleted,
                  isActive: set.setNumber == activeSetNumber,
                  isEditable: isEditable,
                  onUpdate: (
                      {double? weight,
                      int? reps,
                      int? time,
                      double? distance,
                      double? calories}) {
                    onSetUpdate(
                      set.setNumber,
                      weight: weight,
                      reps: reps,
                      time: time,
                      distance: distance,
                      calories: calories,
                    );
                  },
                  onComplete: () {
                    onSetComplete(set.setNumber);
                  },
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppTheme.spacingSm),

          // ========================================
          // 新增組數按鈕
          // ========================================
          if (isEditable) _buildAddSetButton(context),

          const SizedBox(height: AppTheme.spacingSm),
        ],
      ),
    );
  }

  /// 構建卡片標題列
  Widget _buildCardHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 動作名稱與備註
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.exerciseName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (data.targetSets != null || data.targetReps != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _buildTargetText(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                // ⭐ v2.9.1: 備註輸入框（直接在卡片內編輯）
                if (isEditable && onNoteChanged != null) ...[
                  const SizedBox(height: 8),
                  _NoteInputField(
                    initialNote: note ?? '',
                    onNoteChanged: onNoteChanged!,
                  ),
                ] else if (note != null && note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.notes,
                        size: 14,
                        color: colorScheme.primary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          note!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary.withValues(alpha: 0.8),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ⭐ v3.4+: 加入我的動作庫按鈕（教練自訂動作顯示）
          if (isCoachCustomExercise && onAddToMyExercises != null)
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: colorScheme.primary.withValues(alpha: 0.8),
              ),
              onPressed: onAddToMyExercises,
              tooltip: '加入我的動作庫',
              iconSize: 22,
            ),

          // ⭐ v2.9.1: 刪除按鈕（只有創建者可見，直接調用回調，確認由外層處理）
          if (canDelete && onDelete != null)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: colorScheme.error.withValues(alpha: 0.7),
              ),
              onPressed: onDelete,
              tooltip: '刪除動作',
            ),
        ],
      ),
    );
  }

  /// 構建目標文字
  String _buildTargetText() {
    final parts = <String>[];

    if (data.targetSets != null) {
      parts.add('${data.targetSets} 組');
    }
    if (data.targetReps != null) {
      parts.add('${data.targetReps} 次');
    }
    if (data.targetWeight != null) {
      parts.add('${data.targetWeight} kg');
    }

    return parts.isEmpty ? '' : '目標：${parts.join(' • ')}';
  }

  /// 構建表頭
  /// v3.2+ 根據 trackingMode 顯示不同表頭
  Widget _buildTableHeader(BuildContext context) {
    // ⭐ v4.3: timeOnly 模式縮減 PREV 寬度，讓 TIME 輸入框有更多空間
    final prevWidth = data.trackingMode == TrackingMode.timeOnly ? 48.0 : 60.0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          _buildHeaderCell(context, 'SET', width: 40),
          const SizedBox(width: AppTheme.spacingSm),
          _buildHeaderCell(context, 'PREV', width: prevWidth),
          const SizedBox(width: AppTheme.spacingSm),
          // v3.2+ 根據 trackingMode 顯示不同欄位
          ..._buildTrackingModeHeaders(context),
          const SizedBox(width: AppTheme.spacingSm),
          const SizedBox(width: 40), // Checkmark 空位
        ],
      ),
    );
  }

  /// v3.2+ 根據追蹤模式構建表頭欄位
  /// ⭐ v4.3: 優化 Time 相關模式的對齊
  List<Widget> _buildTrackingModeHeaders(BuildContext context) {
    switch (data.trackingMode) {
      case TrackingMode.weightReps:
        return [
          _buildHeaderCell(context, 'KG', flex: 3),
          const SizedBox(width: AppTheme.spacingSm),
          _buildHeaderCell(context, 'REPS', flex: 3),
        ];
      case TrackingMode.weightTime:
        // ⭐ v4.3: 雙行佈局 - 表頭只顯示 KG，TIME 在第二行
        return [
          _buildHeaderCell(context, 'KG', flex: 6),
        ];
      case TrackingMode.repsOnly:
        return [
          _buildHeaderCell(context, 'REPS', flex: 6),
        ];
      case TrackingMode.timeOnly:
        // ⭐ v4.3: 五列結構 - TIME | 空佔位1(Timer) | 空佔位2(Checkbox)
        return [
          _buildHeaderCell(context, 'TIME', flex: 6),
          const SizedBox(width: AppTheme.spacingSm),
          const SizedBox(width: 40), // Timer 按鈕空位
        ];
      case TrackingMode.repsTime:
        // ⭐ v4.3: 雙行佈局 - 表頭只顯示 REPS，TIME 在第二行
        return [
          _buildHeaderCell(context, 'REPS', flex: 6),
        ];
      case TrackingMode.distanceTime:
        // ⭐ v4.3: 雙行佈局 - 表頭只顯示 DIST，TIME 在第二行
        return [
          _buildHeaderCell(context, 'DIST', flex: 6),
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

  /// 構建表頭單元格
  Widget _buildHeaderCell(
    BuildContext context,
    String text, {
    double? width,
    int? flex,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final textWidget = Center(
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withValues(alpha: 0.4),
          letterSpacing: 1,
        ),
      ),
    );

    // 根據參數決定使用固定寬度或彈性寬度
    if (width != null) {
      return SizedBox(width: width, child: textWidget);
    } else if (flex != null) {
      return Expanded(flex: flex, child: textWidget);
    }
    return textWidget;
  }

  /// ⭐ v2.9.1: 構建組數操作按鈕（新增在左，減少在右）
  Widget _buildAddSetButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canRemove = onRemoveSet != null && data.sets.length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: Row(
        children: [
          // 新增組數按鈕（左邊）
          Expanded(
            child: TextButton(
              onPressed: onAddSet,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '新增',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 減少組數按鈕（右邊）
          if (canRemove) ...[
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: TextButton(
                onPressed: onRemoveSet,
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  backgroundColor: colorScheme.error.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.remove,
                      size: 18,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '減少',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ⭐ v2.9.1: 備註輸入框
class _NoteInputField extends StatefulWidget {
  final String initialNote;
  final Function(String) onNoteChanged;

  const _NoteInputField({
    required this.initialNote,
    required this.onNoteChanged,
  });

  @override
  State<_NoteInputField> createState() => _NoteInputFieldState();
}

class _NoteInputFieldState extends State<_NoteInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // 失去焦點時保存
    if (!_focusNode.hasFocus && _controller.text != widget.initialNote) {
      widget.onNoteChanged(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
          ),
      decoration: InputDecoration(
        hintText: '添加備註...',
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
          fontStyle: FontStyle.italic,
          fontSize: 12,
        ),
        prefixIcon: Icon(
          Icons.notes,
          size: 16,
          color: colorScheme.primary.withValues(alpha: 0.7),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 0),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.primary,
          ),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      maxLines: 2,
      minLines: 1,
      textInputAction: TextInputAction.done,
      onSubmitted: (value) {
        if (value != widget.initialNote) {
          widget.onNoteChanged(value);
        }
      },
    );
  }
}

/// 訓練組數輸入列
///
/// 用於輸入每組的重量和次數，並標記完成狀態
/// 整合 JetBrains Mono 字體以確保數字對齊
/// v3.2+ 支援多元追蹤模式
class SetInputRow extends StatefulWidget {
  /// 組數序號（1, 2, 3...）
  final int setNumber;

  /// 當前重量值（kg）
  final double? weight;

  /// 當前次數值
  final int? reps;

  /// v3.2+ 當前時間值（秒）
  final int? time;

  /// v3.2+ 當前距離值（公尺）
  final double? distance;

  /// v3.2+ 當前卡路里值（大卡）
  final double? calories;

  /// v3.2+ 追蹤模式
  final TrackingMode trackingMode;

  /// 上一組的參考數據（用於顯示）
  final String? previousData;

  /// 是否已完成
  final bool isCompleted;

  /// 是否為當前活動組（高亮顯示）
  final bool isActive;

  /// 是否可編輯（過去的訓練不可編輯）
  final bool isEditable;

  /// 數據更新回調（v3.2+ 支援所有欄位）
  final Function(
      {double? weight,
      int? reps,
      int? time,
      double? distance,
      double? calories}) onUpdate;

  /// 完成狀態切換回調
  final VoidCallback onComplete;

  const SetInputRow({
    required this.setNumber,
    this.weight,
    this.reps,
    this.time,
    this.distance,
    this.calories,
    this.trackingMode = TrackingMode.weightReps,
    this.previousData,
    this.isCompleted = false,
    this.isActive = false,
    this.isEditable = true,
    required this.onUpdate,
    required this.onComplete,
    super.key,
  });

  @override
  State<SetInputRow> createState() => _SetInputRowState();
}

class _SetInputRowState extends State<SetInputRow> {
  // 通用控制器：根據 trackingMode 可能使用不同欄位
  late TextEditingController
      _field1Controller; // weight, reps, time, distance, calories
  late TextEditingController _field2Controller; // reps, time（雙欄位模式）
  late FocusNode _field1FocusNode;
  late FocusNode _field2FocusNode;

  // ⭐ v3.7+: 運動倒數計時器狀態
  Timer? _setTimer;
  bool _isTimerRunning = false;
  int _remainingSeconds = 0;
  int _elapsedSeconds = 0; // 已消耗時間（用於動態調整）

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  /// v3.2+ 根據追蹤模式初始化控制器
  void _initControllers() {
    _field1FocusNode = FocusNode();
    _field2FocusNode = FocusNode();

    switch (widget.trackingMode) {
      case TrackingMode.weightReps:
        _field1Controller = TextEditingController(
          text: widget.weight != null ? _formatNumber(widget.weight!) : '',
        );
        _field2Controller = TextEditingController(
          text: widget.reps?.toString() ?? '',
        );
        break;
      case TrackingMode.weightTime:
        _field1Controller = TextEditingController(
          text: widget.weight != null ? _formatNumber(widget.weight!) : '',
        );
        _field2Controller = TextEditingController(
          text: widget.time?.toString() ?? '',
        );
        break;
      case TrackingMode.repsOnly:
        _field1Controller = TextEditingController(
          text: widget.reps?.toString() ?? '',
        );
        _field2Controller = TextEditingController();
        break;
      case TrackingMode.timeOnly:
        _field1Controller = TextEditingController(
          text: widget.time?.toString() ?? '',
        );
        _field2Controller = TextEditingController();
        break;
      case TrackingMode.repsTime:
        _field1Controller = TextEditingController(
          text: widget.reps?.toString() ?? '',
        );
        _field2Controller = TextEditingController(
          text: widget.time?.toString() ?? '',
        );
        break;
      case TrackingMode.distanceTime:
        _field1Controller = TextEditingController(
          text: widget.distance != null ? _formatNumber(widget.distance!) : '',
        );
        _field2Controller = TextEditingController(
          text: widget.time?.toString() ?? '',
        );
        break;
      case TrackingMode.distanceOnly:
        _field1Controller = TextEditingController(
          text: widget.distance != null ? _formatNumber(widget.distance!) : '',
        );
        _field2Controller = TextEditingController();
        break;
      case TrackingMode.calories:
        _field1Controller = TextEditingController(
          text: widget.calories != null ? _formatNumber(widget.calories!) : '',
        );
        _field2Controller = TextEditingController();
        break;
    }
  }

  @override
  void didUpdateWidget(SetInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 當外部數據更新時，同步更新控制器
    // 只有當值真的改變且當前輸入框沒有焦點時才更新
    switch (widget.trackingMode) {
      case TrackingMode.weightReps:
        if (widget.weight != oldWidget.weight && !_field1FocusNode.hasFocus) {
          _field1Controller.text =
              widget.weight != null ? _formatNumber(widget.weight!) : '';
        }
        if (widget.reps != oldWidget.reps && !_field2FocusNode.hasFocus) {
          _field2Controller.text = widget.reps?.toString() ?? '';
        }
        break;
      case TrackingMode.weightTime:
        if (widget.weight != oldWidget.weight && !_field1FocusNode.hasFocus) {
          _field1Controller.text =
              widget.weight != null ? _formatNumber(widget.weight!) : '';
        }
        if (widget.time != oldWidget.time && !_field2FocusNode.hasFocus) {
          _field2Controller.text = widget.time?.toString() ?? '';
        }
        break;
      case TrackingMode.repsOnly:
        if (widget.reps != oldWidget.reps && !_field1FocusNode.hasFocus) {
          _field1Controller.text = widget.reps?.toString() ?? '';
        }
        break;
      case TrackingMode.timeOnly:
        if (widget.time != oldWidget.time && !_field1FocusNode.hasFocus) {
          _field1Controller.text = widget.time?.toString() ?? '';
        }
        break;
      case TrackingMode.repsTime:
        if (widget.reps != oldWidget.reps && !_field1FocusNode.hasFocus) {
          _field1Controller.text = widget.reps?.toString() ?? '';
        }
        if (widget.time != oldWidget.time && !_field2FocusNode.hasFocus) {
          _field2Controller.text = widget.time?.toString() ?? '';
        }
        break;
      case TrackingMode.distanceTime:
        if (widget.distance != oldWidget.distance &&
            !_field1FocusNode.hasFocus) {
          _field1Controller.text =
              widget.distance != null ? _formatNumber(widget.distance!) : '';
        }
        if (widget.time != oldWidget.time && !_field2FocusNode.hasFocus) {
          _field2Controller.text = widget.time?.toString() ?? '';
        }
        break;
      case TrackingMode.distanceOnly:
        if (widget.distance != oldWidget.distance &&
            !_field1FocusNode.hasFocus) {
          _field1Controller.text =
              widget.distance != null ? _formatNumber(widget.distance!) : '';
        }
        break;
      case TrackingMode.calories:
        if (widget.calories != oldWidget.calories &&
            !_field1FocusNode.hasFocus) {
          _field1Controller.text =
              widget.calories != null ? _formatNumber(widget.calories!) : '';
        }
        break;
    }

    // ⭐ v3.7+: 處理 time 變化，動態調整計時器
    if (widget.trackingMode.needsTime && widget.time != oldWidget.time) {
      _handleTimeChange(widget.time);
    }

    // ⭐ v3.7+: 如果取消完成狀態，重置計時器
    if (oldWidget.isCompleted && !widget.isCompleted) {
      _remainingSeconds = 0;
      _elapsedSeconds = 0;
    }
  }

  /// 格式化數字，移除不必要的小數點和零
  String _formatNumber(double value) {
    // 如果是整數，直接返回整數字符串
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    // 如果有小數，保留最多 2 位小數，並移除尾部的 0
    return value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  @override
  void dispose() {
    _setTimer?.cancel(); // ⭐ v3.7+: 清理計時器
    _field1Controller.dispose();
    _field2Controller.dispose();
    _field1FocusNode.dispose();
    _field2FocusNode.dispose();
    super.dispose();
  }

  // ==================== v3.7+: 運動倒數計時器 ====================

  /// 獲取當前設定的目標時間（秒）
  int get _targetSeconds => widget.time ?? 0;

  /// 開始計時
  void _startTimer() {
    if (_targetSeconds <= 0) {
      NotificationUtils.showWarning(context, '請先設定時間');
      return;
    }

    // 如果是暫停後繼續，使用剩餘時間；否則使用目標時間
    if (_remainingSeconds <= 0) {
      _remainingSeconds = _targetSeconds;
      _elapsedSeconds = 0;
    }

    setState(() {
      _isTimerRunning = true;
    });

    _setTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;
        _elapsedSeconds++;

        if (_remainingSeconds <= 0) {
          _onTimerComplete();
        }
      });
    });
  }

  /// 暫停計時
  void _pauseTimer() {
    _setTimer?.cancel();
    _setTimer = null;
    setState(() {
      _isTimerRunning = false;
    });
  }

  /// 計時完成
  void _onTimerComplete() {
    _setTimer?.cancel();
    _setTimer = null;

    setState(() {
      _isTimerRunning = false;
      _remainingSeconds = 0;
    });

    // 震動提醒（連續震動）
    _vibrateOnComplete();

    // 自動打勾完成
    HapticFeedback.mediumImpact();
    widget.onComplete();
  }

  /// 震動提醒（1 秒連續震動）
  Future<void> _vibrateOnComplete() async {
    for (int i = 0; i < 5; i++) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  /// 切換計時器狀態
  void _toggleTimer() {
    if (_isTimerRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  /// 當外部 time 值改變時，動態調整計時器
  ///
  /// ⭐ v3.7+: 計時中修改時間會自動暫停，避免在 build 中呼叫 setState
  void _handleTimeChange(int? newTime) {
    if (!_isTimerRunning && _remainingSeconds == 0 && _elapsedSeconds == 0) {
      // 未開始計時，不需要處理
      return;
    }

    // 計時中修改時間 → 暫停計時器，讓用戶輸入完後手動繼續
    if (_isTimerRunning) {
      _setTimer?.cancel();
      _setTimer = null;
      _isTimerRunning = false;
    }

    final newTarget = newTime ?? 0;
    if (newTarget <= 0) {
      // 時間被清空，重置計時器狀態
      _remainingSeconds = 0;
      _elapsedSeconds = 0;
      return;
    }

    // 動態調整剩餘時間 = 新目標 - 已消耗時間
    final newRemaining = newTarget - _elapsedSeconds;
    if (newRemaining <= 0) {
      // 已經超過新目標時間，重置為 0（用戶需要手動打勾或重新開始）
      _remainingSeconds = 0;
    } else {
      _remainingSeconds = newRemaining;
    }
  }

  /// 格式化秒數為 mm:ss
  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// 構建計時按鈕（只顯示播放/暫停圖標）
  Widget _buildTimerButton(BuildContext context, ColorScheme colorScheme) {
    final isRunning = _isTimerRunning;
    final isPaused = !isRunning && _remainingSeconds > 0 && _elapsedSeconds > 0;

    return SizedBox(
      width: 40,
      height: AppTheme.minTouchTarget,
      child: Center(
        child: GestureDetector(
          onTap: widget.isEditable ? _toggleTimer : null,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isRunning
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : isPaused
                      ? colorScheme.tertiary.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isRunning
                    ? colorScheme.primary
                    : isPaused
                        ? colorScheme.tertiary
                        : colorScheme.outline.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                isRunning ? Icons.pause : Icons.play_arrow,
                color: isRunning
                    ? colorScheme.primary
                    : isPaused
                        ? colorScheme.tertiary
                        : colorScheme.onSurfaceVariant,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ⭐ v3.7+: 構建倒數計時器進度條（顯示在 set row 下方）
  Widget _buildCountdownBar(BuildContext context, ColorScheme colorScheme) {
    final targetSeconds = widget.time ?? 0;
    if (targetSeconds <= 0) return const SizedBox.shrink();

    final progress = targetSeconds > 0
        ? (_elapsedSeconds / targetSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 40, top: 4, bottom: 8),
      child: Column(
        children: [
          // 進度條
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                _isTimerRunning ? colorScheme.primary : colorScheme.tertiary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 倒數時間
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isTimerRunning ? Icons.timer : Icons.timer_outlined,
                size: 14,
                color: _isTimerRunning
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatTime(_remainingSeconds)} / ${_formatTime(targetSeconds)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _isTimerRunning
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 是否顯示倒數計時器（計時中或暫停中）
  bool get _showCountdown {
    return widget.trackingMode.needsTime &&
        !widget.isCompleted &&
        (_isTimerRunning || (_remainingSeconds > 0 && _elapsedSeconds > 0));
  }

  /// ⭐ v4.3: 是否為複合時間模式（需要顯示獨立的 TIME 行）
  bool get _isCompositeTimeMode {
    return widget.trackingMode == TrackingMode.repsTime ||
        widget.trackingMode == TrackingMode.weightTime ||
        widget.trackingMode == TrackingMode.distanceTime;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditable = widget.isEditable && !widget.isCompleted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ========================================
        // Set 資料行（主內容）
        // ========================================
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
          child: Row(
            children: [
              // ========================================
              // 組數序號（佔 15%）
              // ========================================
              SizedBox(
                width: 40,
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.surface,
                      shape: BoxShape.circle,
                      border: widget.isActive
                          ? Border.all(color: colorScheme.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.setNumber}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14,
                          fontWeight: widget.isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: widget.isActive
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(
                                  alpha: widget.isCompleted ? 0.4 : 0.7,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppTheme.spacingSm),

              // ========================================
              // 上一組參考數據（固定寬度，保持對齊）
              // ⭐ v4.3: timeOnly 模式縮減寬度，讓 TIME 輸入框有更多空間
              // ========================================
              SizedBox(
                width: widget.trackingMode == TrackingMode.timeOnly ? 48 : 60,
                child: Center(
                  child: widget.previousData != null
                      ? Text(
                          widget.previousData!,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        )
                      : Text(
                          '-',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.2),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),

              // ========================================
              // v3.2+ 根據追蹤模式顯示輸入欄位
              // ⭐ v4.3: Timer 按鈕已移入 _buildTrackingModeInputs
              // ========================================
              ..._buildTrackingModeInputs(context, isEditable),

              const SizedBox(width: AppTheme.spacingSm),

              // ========================================
              // 完成勾選按鈕（佔 15%）
              // ========================================
              SizedBox(
                width: 40,
                height: AppTheme.minTouchTarget,
                child: Center(
                  child: GestureDetector(
                    onTap: widget.isEditable
                        ? () {
                            // ⭐ v3.7+: 如果計時中，先停止計時
                            if (_isTimerRunning) {
                              _pauseTimer();
                            }
                            // 觸覺回饋
                            HapticFeedback.mediumImpact();
                            widget.onComplete();
                          }
                        : null,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.isCompleted
                            ? AppTheme.successLight
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: widget.isCompleted
                            ? null
                            : Border.all(
                                color: colorScheme.outline,
                                width: 2,
                              ),
                      ),
                      child: widget.isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // ========================================
        // ⭐ v4.3: TIME 行（只有複合時間模式才顯示）
        // 結構：[空40] | TIME標題60 | TIME輸入 | Timer40
        // ========================================
        if (_isCompositeTimeMode)
          Padding(
            padding: const EdgeInsets.only(
              top: AppTheme.spacingXs,
              bottom: AppTheme.spacingXs,
            ),
            child: Row(
              children: [
                // 對應 SET 的空間
                const SizedBox(width: 40),
                const SizedBox(width: AppTheme.spacingSm),
                // TIME 標題（對應 PREV 位置）
                SizedBox(
                  width: 60,
                  child: Center(
                    child: Text(
                      'TIME',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                // TIME 輸入框（對應主輸入框位置）
                Expanded(
                  flex: 6,
                  child: _buildTimeInputForCompositeMode(context, isEditable),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                // Timer 按鈕（對應 Checkbox 位置）
                SizedBox(
                  width: 40,
                  child: widget.isCompleted
                      ? const SizedBox.shrink()
                      : Center(
                          child: _buildTimerButton(context, colorScheme),
                        ),
                ),
              ],
            ),
          ),
        // ========================================
        // ⭐ v3.7+: 倒數計時器（顯示在 set row 下方）
        // ========================================
        if (_showCountdown) _buildCountdownBar(context, colorScheme),
      ],
    );
  }

  /// v3.2+ 根據追蹤模式構建輸入欄位
  List<Widget> _buildTrackingModeInputs(BuildContext context, bool isEditable) {
    switch (widget.trackingMode) {
      case TrackingMode.weightReps:
        return [
          Expanded(
            flex: 3,
            child: _buildNumberInput(
              controller: _field1Controller,
              focusNode: _field1FocusNode,
              hintText: 'kg',
              enabled: isEditable,
              isCompleted: widget.isCompleted,
              onChanged: (value) {
                widget.onUpdate(
                  weight: double.tryParse(value),
                  reps: int.tryParse(_field2Controller.text),
                );
              },
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_field2FocusNode),
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            flex: 3,
            child: _buildNumberInput(
              controller: _field2Controller,
              focusNode: _field2FocusNode,
              hintText: 'reps',
              enabled: isEditable,
              isCompleted: widget.isCompleted,
              onChanged: (value) {
                widget.onUpdate(
                  weight: double.tryParse(_field1Controller.text),
                  reps: int.tryParse(value),
                );
              },
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              textInputAction: TextInputAction.done,
            ),
          ),
        ];
      case TrackingMode.weightTime:
        // ⭐ v4.3: 只返回主輸入框，TIME 行在 build 方法中單獨處理
        return [
          Expanded(
            flex: 6,
            child: _buildNumberInput(
              controller: _field1Controller,
              focusNode: _field1FocusNode,
              hintText: 'kg',
              enabled: isEditable,
              isCompleted: widget.isCompleted,
              onChanged: (value) {
                widget.onUpdate(
                  weight: double.tryParse(value),
                  time: int.tryParse(_field2Controller.text),
                );
              },
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_field2FocusNode),
              textInputAction: TextInputAction.next,
            ),
          ),
        ];
      case TrackingMode.repsOnly:
        return [
          Expanded(
            flex: 6,
            child: _buildNumberInput(
              controller: _field1Controller,
              focusNode: _field1FocusNode,
              hintText: 'reps',
              enabled: isEditable,
              isCompleted: widget.isCompleted,
              onChanged: (value) {
                widget.onUpdate(reps: int.tryParse(value));
              },
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              textInputAction: TextInputAction.done,
            ),
          ),
        ];
      case TrackingMode.timeOnly:
        // ⭐ v4.3: 簡化結構 - TIME 輸入框佔滿空間 + Timer 按鈕在 Checkbox 前
        final colorScheme = Theme.of(context).colorScheme;
        return [
          Expanded(
            flex: 6,
            child: TimeInputField(
              value: widget.time,
              onChanged: (seconds) {
                _field1Controller.text = seconds?.toString() ?? '';
                widget.onUpdate(time: seconds);
              },
              enabled: isEditable,
              isCompleted: widget.isCompleted,
              focusNode: _field1FocusNode,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          // Timer 按鈕（在 Checkbox 前面）
          if (!widget.isCompleted) _buildTimerButton(context, colorScheme),
        ];
      case TrackingMode.repsTime:
        // ⭐ v4.3: 只返回主輸入框，TIME 行在 build 方法中單獨處理
        return [
          Expanded(
            flex: 6,
            child: _buildNumberInput(
              controller: _field1Controller,
              focusNode: _field1FocusNode,
              hintText: 'reps',
              enabled: isEditable,
              isCompleted: widget.isCompleted,
              onChanged: (value) {
                widget.onUpdate(
                  reps: int.tryParse(value),
                  time: int.tryParse(_field2Controller.text),
                );
              },
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_field2FocusNode),
              textInputAction: TextInputAction.next,
            ),
          ),
        ];
      case TrackingMode.distanceTime:
        // ⭐ v4.3: 只返回主輸入框，TIME 行在 build 方法中單獨處理
        return [
          Expanded(
            flex: 6,
            child: _buildNumberInput(
              controller: _field1Controller,
              focusNode: _field1FocusNode,
              hintText: 'm',
              enabled: isEditable,
              isCompleted: widget.isCompleted,
              onChanged: (value) {
                widget.onUpdate(
                  distance: double.tryParse(value),
                  time: int.tryParse(_field2Controller.text),
                );
              },
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_field2FocusNode),
              textInputAction: TextInputAction.next,
            ),
          ),
        ];
      case TrackingMode.distanceOnly:
        return [
          Expanded(
            flex: 6,
            child: _buildNumberInput(
              controller: _field1Controller,
              focusNode: _field1FocusNode,
              hintText: 'm',
              enabled: isEditable,
              isCompleted: widget.isCompleted,
              onChanged: (value) {
                widget.onUpdate(distance: double.tryParse(value));
              },
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              textInputAction: TextInputAction.done,
            ),
          ),
        ];
      case TrackingMode.calories:
        return [
          Expanded(
            flex: 6,
            child: _buildNumberInput(
              controller: _field1Controller,
              focusNode: _field1FocusNode,
              hintText: 'kcal',
              enabled: isEditable,
              isCompleted: widget.isCompleted,
              onChanged: (value) {
                widget.onUpdate(calories: double.tryParse(value));
              },
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              textInputAction: TextInputAction.done,
            ),
          ),
        ];
    }
  }

  /// ⭐ v4.3: 構建複合時間模式的 TIME 輸入框
  Widget _buildTimeInputForCompositeMode(
      BuildContext context, bool isEditable) {
    return TimeInputField(
      value: widget.time,
      onChanged: (seconds) {
        _field2Controller.text = seconds?.toString() ?? '';
        // 根據不同的複合模式更新對應的欄位
        switch (widget.trackingMode) {
          case TrackingMode.repsTime:
            widget.onUpdate(
              reps: int.tryParse(_field1Controller.text),
              time: seconds,
            );
          case TrackingMode.weightTime:
            widget.onUpdate(
              weight: double.tryParse(_field1Controller.text),
              time: seconds,
            );
          case TrackingMode.distanceTime:
            widget.onUpdate(
              distance: double.tryParse(_field1Controller.text),
              time: seconds,
            );
          default:
            widget.onUpdate(time: seconds);
        }
      },
      enabled: isEditable,
      isCompleted: widget.isCompleted,
      focusNode: _field2FocusNode,
    );
  }

  /// 構建數字輸入框
  Widget _buildNumberInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required bool enabled,
    required bool isCompleted,
    required Function(String) onChanged,
    required Function(String) onSubmitted,
    required TextInputAction textInputAction,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      textInputAction: textInputAction,
      inputFormatters: [
        // 只允許數字和小數點
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: GoogleFonts.jetBrainsMono(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: isCompleted
            ? colorScheme.onSurface.withValues(alpha: 0.5)
            : colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          color: colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        filled: true,
        fillColor: enabled
            ? (AppTheme.isDarkMode(context)
                ? colorScheme.surface.withValues(alpha: 0.5)
                : colorScheme.surface)
            : colorScheme.surface.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
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
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
    );
  }
}
