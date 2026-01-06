// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import '../../../../models/exercise_model.dart';

/// 動作列表項 Widget
///
/// 用於在動作列表中顯示單個動作的卡片
///
/// 響應式設計：
/// - 使用 Theme 文字樣式
/// - 響應式間距
class ExerciseListItem extends StatelessWidget {
  final Exercise exercise;
  final String? selectedBodyPart;
  final String? selectedSpecificMuscle;
  final String? selectedEquipmentCategory;
  final String? selectedEquipmentSubcategory;
  final VoidCallback onTap;
  final VoidCallback onSelect;

  const ExerciseListItem({
    super.key,
    required this.exercise,
    this.selectedBodyPart,
    this.selectedSpecificMuscle,
    this.selectedEquipmentCategory,
    this.selectedEquipmentSubcategory,
    required this.onTap,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = exercise.name;
    final infoParts = _buildInfoParts();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: context.spacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: context.cardPadding,
          child: Row(
            children: [
              // 左側：動作名稱和資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 動作名稱
                    Text(
                      displayName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // 底部資訊（肌群、器材）
                    if (infoParts.isNotEmpty) ...[
                      SizedBox(height: context.spacing.xs),
                      Text(
                        infoParts.join(' • '),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // 右側：操作按鈕
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.add_circle,
                      color: colorScheme.secondary,
                    ),
                    tooltip: '選擇此動作',
                    onPressed: onSelect,
                  ),
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 構建資訊標籤列表
  List<String> _buildInfoParts() {
    final infoParts = <String>[];

    // 肌群資訊
    if (selectedSpecificMuscle != null) {
      infoParts.add('肌群：$selectedSpecificMuscle');
    } else if (selectedBodyPart != null) {
      infoParts.add('部位：$selectedBodyPart');
    }

    // 器材資訊
    if (selectedEquipmentSubcategory != null) {
      infoParts.add('器材：$selectedEquipmentSubcategory');
    } else if (selectedEquipmentCategory != null) {
      infoParts.add('類別：$selectedEquipmentCategory');
    } else if (exercise.equipment.isNotEmpty) {
      infoParts.add('器材：${exercise.equipment}');
    } else {
      infoParts.add('器材：徒手');
    }

    return infoParts;
  }
}
