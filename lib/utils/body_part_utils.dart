import 'package:flutter/material.dart';

/// 身體部位工具類別
///
/// 提供身體部位相關的顏色、圖標等工具方法
class BodyPartUtils {
  /// 根據身體部位返回顏色
  static Color getBodyPartColor(BuildContext context, String bodyPart) {
    if (bodyPart.contains('胸')) return Colors.red;
    if (bodyPart.contains('背')) return Colors.blue;
    if (bodyPart.contains('腿')) return Theme.of(context).colorScheme.secondary;
    if (bodyPart.contains('肩')) return Theme.of(context).colorScheme.primary;
    if (bodyPart.contains('手')) return Theme.of(context).colorScheme.primary;
    if (bodyPart.contains('核心') || bodyPart.contains('腹')) return Colors.teal;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// 根據身體部位返回圖標
  static IconData getBodyPartIcon(String bodyPart) {
    switch (bodyPart) {
      case '胸部':
        return Icons.self_improvement;
      case '背部':
        return Icons.accessibility_new;
      case '腿部':
        return Icons.directions_run;
      case '肩部':
        return Icons.sports_gymnastics;
      case '手臂':
        return Icons.back_hand;
      case '核心':
        return Icons.sports_martial_arts;
      default:
        return Icons.fitness_center;
    }
  }

  /// 建立身體部位標籤
  static Widget buildBodyPartTag(BuildContext context, String bodyPart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: getBodyPartColor(context, bodyPart).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        bodyPart,
        style: TextStyle(
          fontSize: 11,
          color: getBodyPartColor(context, bodyPart),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

