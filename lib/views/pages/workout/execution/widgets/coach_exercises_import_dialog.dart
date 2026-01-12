import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:strengthwise/models/workout_record/exercise_record.dart';
import 'package:strengthwise/models/tracking_mode.dart';

/// 教練自訂動作批次匯入對話框
///
/// v3.4+ 儲存為模板時，檢測到教練自訂動作會彈出此對話框
/// 讓學員選擇要加入動作庫的動作
class CoachExercisesImportDialog extends StatefulWidget {
  /// 需要匯入的教練自訂動作列表
  final List<ExerciseRecord> coachExercises;

  /// 匯入回調（返回選中的動作列表）
  final Future<void> Function(List<ExerciseRecord> selectedExercises) onImport;

  const CoachExercisesImportDialog({
    super.key,
    required this.coachExercises,
    required this.onImport,
  });

  @override
  State<CoachExercisesImportDialog> createState() =>
      _CoachExercisesImportDialogState();
}

class _CoachExercisesImportDialogState
    extends State<CoachExercisesImportDialog> {
  late Set<String> _selectedIds;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    // 預設全選
    _selectedIds = widget.coachExercises.map((e) => e.exerciseId).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // 使用 Dialog 取代 AlertDialog，避免 IntrinsicWidth 計算問題
    // SizedBox 提供確定的寬度，ConstrainedBox 只約束高度
    final dialogWidth = min(screenWidth * 0.9, 400.0);
    
    return Dialog(
      child: SizedBox(
        width: dialogWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 標題
              Row(
                children: [
                  Icon(
                    Icons.download_outlined,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '需要加入動作庫',
                      style: textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 說明文字
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '此訓練包含教練的自訂動作，需要先加入你的動作庫才能儲存為模板。',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 全選/取消全選
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '選擇要加入的動作',
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _isImporting ? null : _toggleSelectAll,
                    child: Text(
                      _selectedIds.length == widget.coachExercises.length
                          ? '取消全選'
                          : '全選',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 動作列表（可滾動）
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.coachExercises.map((exercise) {
                      final isSelected =
                          _selectedIds.contains(exercise.exerciseId);
                      return _buildExerciseItem(
                          exercise, isSelected, colorScheme);
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 按鈕區域
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isImporting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: _isImporting || _selectedIds.isEmpty
                          ? null
                          : _handleImport,
                      child: _isImporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              '加入並繼續 (${_selectedIds.length})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 建立動作項目（使用簡單 Row 取代 ListTile）
  Widget _buildExerciseItem(
    ExerciseRecord exercise,
    bool isSelected,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isImporting
            ? null
            : () {
                setState(() {
                  if (isSelected) {
                    _selectedIds.remove(exercise.exerciseId);
                  } else {
                    _selectedIds.add(exercise.exerciseId);
                  }
                });
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // 圖示
              Icon(
                Icons.fitness_center,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              // 文字
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exerciseName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exercise.sets.length} 組 · ${exercise.trackingMode.displayName}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Checkbox（給固定寬度避免內在寬度計算問題）
              SizedBox(
                width: 48,
                height: 48,
                child: Checkbox(
                  value: isSelected,
                  onChanged: _isImporting
                      ? null
                      : (value) {
                          setState(() {
                            if (value == true) {
                              _selectedIds.add(exercise.exerciseId);
                            } else {
                              _selectedIds.remove(exercise.exerciseId);
                            }
                          });
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 全選/取消全選
  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == widget.coachExercises.length) {
        _selectedIds.clear();
      } else {
        _selectedIds = widget.coachExercises.map((e) => e.exerciseId).toSet();
      }
    });
  }

  /// 處理匯入
  Future<void> _handleImport() async {
    setState(() => _isImporting = true);

    try {
      // 篩選選中的動作
      final selectedExercises = widget.coachExercises
          .where((e) => _selectedIds.contains(e.exerciseId))
          .toList();

      await widget.onImport(selectedExercises);

      if (mounted) {
        Navigator.of(context).pop(true); // 返回 true 表示成功
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('匯入失敗: $e')),
        );
      }
    }
  }
}
