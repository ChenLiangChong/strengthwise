/// 收藏動作模型
///
/// 用於管理使用者收藏的健身動作
/// 儲存方式：SharedPreferences（本地持久化）
class FavoriteExercise {
  final String exerciseId;       // 動作 ID
  final String exerciseName;     // 動作名稱
  final String bodyPart;         // 身體部位
  final DateTime addedAt;        // 添加時間
  final DateTime? lastViewedAt;  // 最後查看時間

  /// 創建一個收藏動作實例
  FavoriteExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.bodyPart,
    required this.addedAt,
    this.lastViewedAt,
  });

  /// 從 Map 創建對象（用於 SharedPreferences）
  factory FavoriteExercise.fromMap(Map<String, dynamic> map) {
    return FavoriteExercise(
      exerciseId: map['exerciseId'] as String,
      exerciseName: map['exerciseName'] as String,
      bodyPart: map['bodyPart'] as String,
      addedAt: DateTime.parse(map['addedAt'] as String),
      lastViewedAt: map['lastViewedAt'] != null 
          ? DateTime.parse(map['lastViewedAt'] as String)
          : null,
    );
  }

  /// 轉換為 Map（用於 SharedPreferences）
  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'bodyPart': bodyPart,
      'addedAt': addedAt.toIso8601String(),
      'lastViewedAt': lastViewedAt?.toIso8601String(),
    };
  }

  /// 創建一個本對象的副本，並可選擇性地修改某些屬性
  FavoriteExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    String? bodyPart,
    DateTime? addedAt,
    DateTime? lastViewedAt,
  }) {
    return FavoriteExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      bodyPart: bodyPart ?? this.bodyPart,
      addedAt: addedAt ?? this.addedAt,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
    );
  }

  @override
  String toString() => 'FavoriteExercise(id: $exerciseId, name: $exerciseName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteExercise && other.exerciseId == exerciseId;
  }

  @override
  int get hashCode => exerciseId.hashCode;
}

/// 有訓練記錄的動作（用於分類導航）
class ExerciseWithRecord {
  final String exerciseId;       // 動作 ID
  final String exerciseName;     // 動作名稱
  final String bodyPart;         // 身體部位
  final String trainingType;     // 訓練類型（重訓、有氧、伸展等）
  final DateTime lastTrainingDate; // 最後訓練日期
  final double maxWeight;        // 最大重量
  final int totalSets;           // 總組數
  final bool isFavorite;         // 是否已收藏

  ExerciseWithRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.bodyPart,
    required this.trainingType,
    required this.lastTrainingDate,
    required this.maxWeight,
    required this.totalSets,
    this.isFavorite = false,
  });

  /// 格式化最後訓練日期
  String get formattedLastTrainingDate {
    final now = DateTime.now();
    final difference = now.difference(lastTrainingDate).inDays;
    
    if (difference == 0) {
      return '今天';
    } else if (difference == 1) {
      return '昨天';
    } else if (difference < 7) {
      return '$difference 天前';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks 週前';
    } else {
      final months = (difference / 30).floor();
      return '$months 個月前';
    }
  }

  /// 格式化最大重量
  String get formattedMaxWeight {
    return '${maxWeight.toStringAsFixed(1)} kg';
  }

  @override
  String toString() => 'ExerciseWithRecord($exerciseName: $formattedMaxWeight)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseWithRecord && other.exerciseId == exerciseId;
  }

  @override
  int get hashCode => exerciseId.hashCode;
}

