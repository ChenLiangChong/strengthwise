/// 追蹤模式枚舉
///
/// 定義不同訓練類型的記錄模式，用於決定 UI 顯示哪些輸入欄位
enum TrackingMode {
  /// 重量 & 次數（預設，重訓）
  /// 輸入：weight, reps
  /// 顯示：40kg × 10次
  weightReps,

  /// 重量 & 時間（農夫走路）
  /// 輸入：weight, time
  /// 顯示：40kg × 30秒
  weightTime,

  /// 僅次數（波比跳、跳箱）
  /// 輸入：reps
  /// 顯示：15次
  repsOnly,

  /// 僅時間（棒式、HIIT 間歇）
  /// 輸入：time
  /// 顯示：60秒
  timeOnly,

  /// 次數 & 時間（動態伸展：10次，每次5秒）
  /// 輸入：reps, time
  /// 顯示：10次 × 5秒
  repsTime,

  /// 距離 & 時間（跑步機、划船機）
  /// 輸入：distance, time
  /// 顯示：5000m / 25:00
  distanceTime,

  /// 僅距離（立定跳遠、投擲）
  /// 輸入：distance
  /// 顯示：2.5m
  distanceOnly,

  /// 卡路里（風扇車）
  /// 輸入：calories
  /// 顯示：200卡
  calories,
}

/// TrackingMode 擴展方法
extension TrackingModeExtension on TrackingMode {
  /// 轉換為資料庫儲存的字串格式（snake_case）
  String toJson() {
    switch (this) {
      case TrackingMode.weightReps:
        return 'weight_reps';
      case TrackingMode.weightTime:
        return 'weight_time';
      case TrackingMode.repsOnly:
        return 'reps_only';
      case TrackingMode.timeOnly:
        return 'time_only';
      case TrackingMode.repsTime:
        return 'reps_time';
      case TrackingMode.distanceTime:
        return 'distance_time';
      case TrackingMode.distanceOnly:
        return 'distance_only';
      case TrackingMode.calories:
        return 'calories';
    }
  }

  /// 從資料庫字串解析（snake_case）
  static TrackingMode fromJson(String? value) {
    switch (value) {
      case 'weight_reps':
        return TrackingMode.weightReps;
      case 'weight_time':
        return TrackingMode.weightTime;
      case 'reps_only':
        return TrackingMode.repsOnly;
      case 'time_only':
        return TrackingMode.timeOnly;
      case 'reps_time':
        return TrackingMode.repsTime;
      case 'distance_time':
        return TrackingMode.distanceTime;
      case 'distance_only':
        return TrackingMode.distanceOnly;
      case 'calories':
        return TrackingMode.calories;
      default:
        return TrackingMode.weightReps; // 預設值
    }
  }

  /// 取得顯示名稱（繁體中文）
  String get displayName {
    switch (this) {
      case TrackingMode.weightReps:
        return '重量 & 次數';
      case TrackingMode.weightTime:
        return '重量 & 時間';
      case TrackingMode.repsOnly:
        return '僅次數';
      case TrackingMode.timeOnly:
        return '僅時間';
      case TrackingMode.repsTime:
        return '次數 & 時間';
      case TrackingMode.distanceTime:
        return '距離 & 時間';
      case TrackingMode.distanceOnly:
        return '僅距離';
      case TrackingMode.calories:
        return '卡路里';
    }
  }

  /// 取得說明文字
  String get description {
    switch (this) {
      case TrackingMode.weightReps:
        return '適用於深蹲、臥推等重訓動作';
      case TrackingMode.weightTime:
        return '適用於農夫走路等負重持續動作';
      case TrackingMode.repsOnly:
        return '適用於波比跳、跳箱等徒手動作';
      case TrackingMode.timeOnly:
        return '適用於棒式、HIIT 間歇等計時動作';
      case TrackingMode.repsTime:
        return '適用於動態伸展等次數+持續時間動作';
      case TrackingMode.distanceTime:
        return '適用於跑步機、划船機等有氧運動';
      case TrackingMode.distanceOnly:
        return '適用於立定跳遠、投擲等距離動作';
      case TrackingMode.calories:
        return '適用於風扇車等卡路里導向運動';
    }
  }

  /// 是否需要重量欄位
  bool get needsWeight {
    return this == TrackingMode.weightReps || this == TrackingMode.weightTime;
  }

  /// 是否需要次數欄位
  bool get needsReps {
    return this == TrackingMode.weightReps ||
        this == TrackingMode.repsOnly ||
        this == TrackingMode.repsTime;
  }

  /// 是否需要時間欄位
  bool get needsTime {
    return this == TrackingMode.weightTime ||
        this == TrackingMode.timeOnly ||
        this == TrackingMode.repsTime ||
        this == TrackingMode.distanceTime;
  }

  /// 是否需要距離欄位
  bool get needsDistance {
    return this == TrackingMode.distanceTime ||
        this == TrackingMode.distanceOnly;
  }

  /// 是否需要卡路里欄位
  bool get needsCalories {
    return this == TrackingMode.calories;
  }

  /// 是否納入 Volume 統計和 PR 追蹤
  /// 只有 weight_reps 會納入統計
  bool get contributesToStats {
    return this == TrackingMode.weightReps;
  }
  
  /// v3.3+ 是否為重量導向的追蹤模式（顯示圖表和 PR）
  bool get isWeightBased {
    return this == TrackingMode.weightReps || this == TrackingMode.weightTime;
  }

  /// 取得輸入欄位列表
  List<String> get inputFields {
    switch (this) {
      case TrackingMode.weightReps:
        return ['weight', 'reps'];
      case TrackingMode.weightTime:
        return ['weight', 'time'];
      case TrackingMode.repsOnly:
        return ['reps'];
      case TrackingMode.timeOnly:
        return ['time'];
      case TrackingMode.repsTime:
        return ['reps', 'time'];
      case TrackingMode.distanceTime:
        return ['distance', 'time'];
      case TrackingMode.distanceOnly:
        return ['distance'];
      case TrackingMode.calories:
        return ['calories'];
    }
  }
}

/// 時間格式化工具
class TrackingModeFormatter {
  /// 將秒數格式化為顯示字串
  /// ≥60 秒顯示為 分:秒 格式，<60 秒顯示為 秒
  static String formatTime(int seconds) {
    if (seconds >= 60) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
    return '$seconds秒';
  }

  /// 將距離格式化為顯示字串
  /// ≥1000 m 顯示為 km，<1000 m 顯示為 m
  static String formatDistance(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      // 如果是整數公里，不顯示小數
      if (km == km.roundToDouble()) {
        return '${km.toInt()}km';
      }
      return '${km.toStringAsFixed(1)}km';
    }
    // 如果是整數公尺，不顯示小數
    if (meters == meters.roundToDouble()) {
      return '${meters.toInt()}m';
    }
    return '${meters.toStringAsFixed(0)}m';
  }

  /// 將卡路里格式化為顯示字串
  static String formatCalories(double kcal) {
    if (kcal == kcal.roundToDouble()) {
      return '${kcal.toInt()}卡';
    }
    return '${kcal.toStringAsFixed(1)}卡';
  }

  /// 將重量格式化為顯示字串
  static String formatWeight(double kg) {
    if (kg == kg.roundToDouble()) {
      return '${kg.toInt()}kg';
    }
    return '${kg.toStringAsFixed(1)}kg';
  }

  /// 將次數格式化為顯示字串
  static String formatReps(int reps) {
    return '$reps次';
  }
}
