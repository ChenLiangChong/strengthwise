/// 訓練目標
class TrainingGoals {
  /// 主要目標
  /// 'weight_loss' | 'muscle_gain' | 'performance' | 'health' | 'rehabilitation'
  final String primary;
  
  /// 目標體重變化（kg）
  final double? targetKg;
  
  /// 預期時程（月）
  final int? timeframeMonths;
  
  /// 補充說明
  final String? notes;

  const TrainingGoals({
    required this.primary,
    this.targetKg,
    this.timeframeMonths,
    this.notes,
  });

  factory TrainingGoals.fromJson(Map<String, dynamic> json) {
    return TrainingGoals(
      primary: json['primary'] as String,
      targetKg: json['target_kg'] != null 
          ? (json['target_kg'] as num).toDouble() 
          : null,
      timeframeMonths: json['timeframe_months'] as int?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary': primary,
      if (targetKg != null) 'target_kg': targetKg,
      if (timeframeMonths != null) 'timeframe_months': timeframeMonths,
      if (notes != null) 'notes': notes,
    };
  }

  /// 取得主要目標的中文標籤
  String get primaryLabel {
    switch (primary) {
      case 'weight_loss':
        return '減重減脂';
      case 'muscle_gain':
        return '增肌增重';
      case 'performance':
        return '運動表現';
      case 'health':
        return '健康維持';
      case 'rehabilitation':
        return '復健改善';
      default:
        return primary;
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer(primaryLabel);
    if (targetKg != null) {
      buffer.write('：${targetKg! > 0 ? '+' : ''}${targetKg}kg');
    }
    if (timeframeMonths != null) {
      buffer.write(' / $timeframeMonths個月');
    }
    return buffer.toString();
  }
}

