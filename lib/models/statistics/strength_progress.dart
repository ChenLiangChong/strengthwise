import '../tracking_mode.dart';

/// 訓練進度數據點
/// v3.3+ 支援多元追蹤模式
class StrengthProgressPoint {
  final DateTime date;           // 日期
  final double weight;           // 重量（kg）
  final int reps;                // 次數
  final double estimatedOneRM;   // 估算 1RM
  final bool isPR;               // 是否為 PR
  
  // v3.3+ 新增欄位
  final int? time;               // 時間（秒）
  final double? distance;        // 距離（公尺）
  final double? calories;        // 卡路里（kcal）
  final TrackingMode trackingMode; // 追蹤模式

  StrengthProgressPoint({
    required this.date,
    required this.weight,
    required this.reps,
    required this.estimatedOneRM,
    this.isPR = false,
    // v3.3+ 新增
    this.time,
    this.distance,
    this.calories,
    this.trackingMode = TrackingMode.weightReps,
  });

  /// 格式化日期顯示
  String get formattedDate => '${date.month}/${date.day}';
  
  /// v3.3+ 格式化顯示值（根據 trackingMode）
  String get formattedValue {
    switch (trackingMode) {
      case TrackingMode.weightReps:
        return '${weight.toStringAsFixed(1)}kg × $reps';
      case TrackingMode.weightTime:
        return '${weight.toStringAsFixed(1)}kg × ${_formatTime(time ?? 0)}';
      case TrackingMode.repsOnly:
        return '$reps 次';
      case TrackingMode.timeOnly:
        return _formatTime(time ?? 0);
      case TrackingMode.repsTime:
        return '$reps 次 × ${_formatTime(time ?? 0)}';
      case TrackingMode.distanceTime:
        return '${_formatDistance(distance ?? 0)} / ${_formatTime(time ?? 0)}';
      case TrackingMode.distanceOnly:
        return _formatDistance(distance ?? 0);
      case TrackingMode.calories:
        return '${calories?.toStringAsFixed(0) ?? 0} kcal';
    }
  }
  
  /// 格式化時間（秒 → 分:秒）
  String _formatTime(int seconds) {
    if (seconds < 60) return '$seconds 秒';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
  
  /// 格式化距離（公尺 → m 或 km）
  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)}m';
    return '${(meters / 1000).toStringAsFixed(2)}km';
  }

  @override
  String toString() => 'StrengthPoint($formattedDate: $formattedValue)';
}

/// 動作訓練進度追蹤
/// v3.3+ 支援多元追蹤模式
class ExerciseStrengthProgress {
  final String exerciseId;                        // 動作 ID
  final String exerciseName;                      // 動作名稱
  final String bodyPart;                          // 身體部位
  final List<StrengthProgressPoint> history;      // 歷史記錄
  final double currentMax;                        // 當前最大重量
  final double previousMax;                       // 上期最大重量
  final double progressPercentage;                // 進步百分比
  final int totalSets;                            // 總組數
  final double averageWeight;                     // 平均重量
  
  // v3.3+ 新增
  final TrackingMode trackingMode;                // 追蹤模式

  ExerciseStrengthProgress({
    required this.exerciseId,
    required this.exerciseName,
    required this.bodyPart,
    required this.history,
    required this.currentMax,
    required this.previousMax,
    required this.progressPercentage,
    required this.totalSets,
    required this.averageWeight,
    // v3.3+ 新增
    this.trackingMode = TrackingMode.weightReps,
  });

  /// 是否有進步
  bool get hasProgress => progressPercentage > 0;
  
  /// v3.3+ 是否為重訓模式（顯示圖表和 PR）
  bool get isWeightBasedMode => 
      trackingMode == TrackingMode.weightReps || 
      trackingMode == TrackingMode.weightTime;

  /// 格式化進步百分比
  String get formattedProgress {
    if (progressPercentage == 0) return '持平';
    final sign = progressPercentage > 0 ? '+' : '';
    return '$sign${progressPercentage.toStringAsFixed(1)}%';
  }

  /// 格式化當前最大重量
  String get formattedCurrentMax => '${currentMax.toStringAsFixed(1)} kg';

  @override
  String toString() => 'StrengthProgress($exerciseName: $formattedProgress)';
}

