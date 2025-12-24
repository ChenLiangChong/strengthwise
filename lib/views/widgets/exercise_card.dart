import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../themes/app_theme.dart';
import 'set_input_row.dart';

/// 動作卡片數據模型
class ExerciseCardData {
  final String exerciseId;
  final String exerciseName;
  final List<SetData> sets;
  final int? targetSets;
  final int? targetReps;
  final double? targetWeight;

  ExerciseCardData({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.targetSets,
    this.targetReps,
    this.targetWeight,
  });
}

/// 組數數據模型
class SetData {
  final int setNumber;
  final double? weight;
  final int? reps;
  final bool isCompleted;
  final String? previousData; // 上一組參考數據（如 "60x10"）

  SetData({
    required this.setNumber,
    this.weight,
    this.reps,
    this.isCompleted = false,
    this.previousData,
  });

  SetData copyWith({
    int? setNumber,
    double? weight,
    int? reps,
    bool? isCompleted,
    String? previousData,
  }) {
    return SetData(
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
      previousData: previousData ?? this.previousData,
    );
  }
}

/// 訓練動作卡片
/// 
/// 使用卡片式佈局展示單個動作的所有組數
/// 包含動作名稱、組數列表、新增組數按鈕
class ExerciseCard extends StatelessWidget {
  /// 動作數據
  final ExerciseCardData data;
  
  /// 是否可編輯
  final bool isEditable;
  
  /// 當前活動組（高亮顯示）
  final int? activeSetNumber;
  
  /// 組數數據更新回調
  final Function(int setNumber, double? weight, int? reps) onSetUpdate;
  
  /// 組數完成狀態切換回調
  final Function(int setNumber) onSetComplete;
  
  /// 新增組數回調
  final VoidCallback onAddSet;
  
  /// 菜單按鈕點擊回調（替換動作、查看歷史等）
  final VoidCallback? onMenuTap;

  const ExerciseCard({
    required this.data,
    required this.isEditable,
    this.activeSetNumber,
    required this.onSetUpdate,
    required this.onSetComplete,
    required this.onAddSet,
    this.onMenuTap,
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
              : colorScheme.outline.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: AppTheme.isDarkMode(context)
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
              children: data.sets.map((set) {
                return SetInputRow(
                  setNumber: set.setNumber,
                  weight: set.weight,
                  reps: set.reps,
                  previousData: set.previousData,
                  isCompleted: set.isCompleted,
                  isActive: set.setNumber == activeSetNumber,
                  isEditable: isEditable,
                  onUpdate: (weight, reps) {
                    onSetUpdate(set.setNumber, weight, reps);
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
        children: [
          // 動作名稱
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
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // 菜單按鈕
          if (onMenuTap != null)
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: onMenuTap,
              color: colorScheme.onSurface.withOpacity(0.6),
              tooltip: '動作選項',
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
  Widget _buildTableHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          // Set
          SizedBox(
            width: 40,
            child: Center(
              child: Text(
                'SET',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.4),
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: AppTheme.spacingSm),
          
          // Previous
          SizedBox(
            width: 60,
            child: Center(
              child: Text(
                'PREV',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.4),
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: AppTheme.spacingSm),
          
          // kg
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                'KG',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.4),
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: AppTheme.spacingSm),
          
          // Reps
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                'REPS',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.4),
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: AppTheme.spacingSm),
          
          // Checkmark
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// 構建新增組數按鈕
  Widget _buildAddSetButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: TextButton(
        onPressed: onAddSet,
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
            Icon(
              Icons.add,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '新增組數',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

