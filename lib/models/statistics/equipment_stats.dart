/// 器材類別統計
class EquipmentStats {
  final String equipment;        // 器材名稱
  final int usageCount;          // 使用次數
  final double percentage;       // 佔比

  EquipmentStats({
    required this.equipment,
    required this.usageCount,
    required this.percentage,
  });

  /// 格式化百分比顯示
  String get formattedPercentage {
    return '${(percentage * 100).toStringAsFixed(0)}%';
  }

  @override
  String toString() => 'EquipmentStats($equipment: $usageCount 次)';
}

