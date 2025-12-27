/// 訓練量數據點（用於圖表）
class TrainingVolumePoint {
  final DateTime date;           // 日期
  final double totalVolume;      // 總訓練量（kg）
  final int totalSets;           // 總組數
  final int workoutCount;        // 訓練次數

  TrainingVolumePoint({
    required this.date,
    required this.totalVolume,
    required this.totalSets,
    required this.workoutCount,
  });

  /// 格式化日期顯示
  String get formattedDate {
    return '${date.month}/${date.day}';
  }

  @override
  String toString() => 'VolumePoint($formattedDate: ${totalVolume.toStringAsFixed(0)} kg)';
}

