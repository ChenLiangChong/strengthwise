import 'time_range.dart';
import 'training_frequency.dart';
import 'training_volume.dart';
import 'body_part_stats.dart';
import 'training_type_stats.dart';
import 'equipment_stats.dart';
import 'personal_record.dart';
import 'strength_progress.dart';
import 'muscle_group_balance.dart';
import 'training_calendar.dart';
import 'completion_rate.dart';

/// 完整的統計數據
class StatisticsData {
  final TimeRange timeRange;                           // 時間範圍
  final TrainingFrequency frequency;                   // 訓練頻率
  final List<TrainingVolumePoint> volumeHistory;       // 訓練量歷史
  final List<BodyPartStats> bodyPartStats;             // 身體部位統計
  final Map<String, List<SpecificMuscleStats>> muscleDetails; // 特定肌群細節
  final List<TrainingTypeStats> trainingTypeStats;     // 訓練類型統計
  final List<EquipmentStats> equipmentStats;           // 器材統計
  final List<PersonalRecord> personalRecords;          // 個人記錄
  
  // 新增統計
  final List<ExerciseStrengthProgress> strengthProgress;  // 力量進步追蹤
  final MuscleGroupBalance? muscleGroupBalance;           // 肌群平衡分析
  final TrainingCalendarData? calendarData;               // 訓練日曆數據
  final CompletionRateStats? completionRate;              // 完成率統計

  StatisticsData({
    required this.timeRange,
    required this.frequency,
    required this.volumeHistory,
    required this.bodyPartStats,
    required this.muscleDetails,
    required this.trainingTypeStats,
    required this.equipmentStats,
    required this.personalRecords,
    this.strengthProgress = const [],
    this.muscleGroupBalance,
    this.calendarData,
    this.completionRate,
  });

  /// 創建空的統計數據
  factory StatisticsData.empty(TimeRange timeRange) {
    return StatisticsData(
      timeRange: timeRange,
      frequency: TrainingFrequency(
        totalWorkouts: 0,
        totalHours: 0,
        averageHours: 0,
        consecutiveDays: 0,
        comparisonValue: 0,
      ),
      volumeHistory: [],
      bodyPartStats: [],
      muscleDetails: {},
      trainingTypeStats: [],
      equipmentStats: [],
      personalRecords: [],
      strengthProgress: [],
      muscleGroupBalance: null,
      calendarData: null,
      completionRate: null,
    );
  }

  /// 是否有數據
  bool get hasData => frequency.totalWorkouts > 0;

  @override
  String toString() => 'StatisticsData(${timeRange.displayName}, ${frequency.totalWorkouts} workouts)';
}

