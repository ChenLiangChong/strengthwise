/// 統計數據序列化擴展
///
/// 為所有統計相關的 model 類添加 JSON 序列化支持
/// 用於 Hive 本地持久化

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
import 'statistics_data.dart';

// ==================== TimeRange ====================

extension TimeRangeJson on TimeRange {
  String toJsonString() => name;

  static TimeRange fromJsonString(String value) {
    return TimeRange.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TimeRange.week,
    );
  }
}

// ==================== TrainingFrequency ====================

extension TrainingFrequencyJson on TrainingFrequency {
  Map<String, dynamic> toJson() => {
        'scheduledWorkouts': scheduledWorkouts,
        'totalWorkouts': totalWorkouts,
        'completedWorkouts': completedWorkouts,
        'partialWorkouts': partialWorkouts,
        'trainingDays': trainingDays,
        'totalHours': totalHours,
        'averageHours': averageHours,
        'consecutiveDays': consecutiveDays,
        'comparisonValue': comparisonValue,
      };

  static TrainingFrequency fromJson(Map<String, dynamic> json) =>
      TrainingFrequency(
        scheduledWorkouts: json['scheduledWorkouts'] ?? 0,
        totalWorkouts: json['totalWorkouts'] ?? 0,
        completedWorkouts: json['completedWorkouts'] ?? 0,
        partialWorkouts: json['partialWorkouts'] ?? 0,
        trainingDays: json['trainingDays'] ?? 0,
        totalHours: (json['totalHours'] ?? 0).toDouble(),
        averageHours: (json['averageHours'] ?? 0).toDouble(),
        consecutiveDays: json['consecutiveDays'] ?? 0,
        comparisonValue: json['comparisonValue'] ?? 0,
      );
}

// ==================== TrainingVolumePoint ====================

extension TrainingVolumePointJson on TrainingVolumePoint {
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'totalVolume': totalVolume,
        'totalSets': totalSets,
        'workoutCount': workoutCount,
      };

  static TrainingVolumePoint fromJson(Map<String, dynamic> json) =>
      TrainingVolumePoint(
        date: DateTime.parse(json['date']),
        totalVolume: (json['totalVolume'] ?? 0).toDouble(),
        totalSets: json['totalSets'] ?? 0,
        workoutCount: json['workoutCount'] ?? 0,
      );
}

// ==================== BodyPartStats ====================

extension BodyPartStatsJson on BodyPartStats {
  Map<String, dynamic> toJson() => {
        'bodyPart': bodyPart,
        'totalVolume': totalVolume,
        'workoutCount': workoutCount,
        'exerciseCount': exerciseCount,
        'percentage': percentage,
      };

  static BodyPartStats fromJson(Map<String, dynamic> json) => BodyPartStats(
        bodyPart: json['bodyPart'] ?? '',
        totalVolume: (json['totalVolume'] ?? 0).toDouble(),
        workoutCount: json['workoutCount'] ?? 0,
        exerciseCount: json['exerciseCount'] ?? 0,
        percentage: (json['percentage'] ?? 0).toDouble(),
      );
}

// ==================== SpecificMuscleStats ====================

extension SpecificMuscleStatsJson on SpecificMuscleStats {
  Map<String, dynamic> toJson() => {
        'specificMuscle': specificMuscle,
        'totalVolume': totalVolume,
        'workoutCount': workoutCount,
        'percentage': percentage,
      };

  static SpecificMuscleStats fromJson(Map<String, dynamic> json) =>
      SpecificMuscleStats(
        specificMuscle: json['specificMuscle'] ?? '',
        totalVolume: (json['totalVolume'] ?? 0).toDouble(),
        workoutCount: json['workoutCount'] ?? 0,
        percentage: (json['percentage'] ?? 0).toDouble(),
      );
}

// ==================== TrainingTypeStats ====================

extension TrainingTypeStatsJson on TrainingTypeStats {
  Map<String, dynamic> toJson() => {
        'trainingType': trainingType,
        'workoutCount': workoutCount,
        'percentage': percentage,
      };

  static TrainingTypeStats fromJson(Map<String, dynamic> json) =>
      TrainingTypeStats(
        trainingType: json['trainingType'] ?? '',
        workoutCount: json['workoutCount'] ?? 0,
        percentage: (json['percentage'] ?? 0).toDouble(),
      );
}

// ==================== EquipmentStats ====================

extension EquipmentStatsJson on EquipmentStats {
  Map<String, dynamic> toJson() => {
        'equipment': equipment,
        'usageCount': usageCount,
        'percentage': percentage,
      };

  static EquipmentStats fromJson(Map<String, dynamic> json) => EquipmentStats(
        equipment: json['equipment'] ?? '',
        usageCount: json['usageCount'] ?? 0,
        percentage: (json['percentage'] ?? 0).toDouble(),
      );
}

// ==================== PersonalRecord ====================

extension PersonalRecordJson on PersonalRecord {
  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'maxWeight': maxWeight,
        'reps': reps,
        'achievedDate': achievedDate.toIso8601String(),
        'bodyPart': bodyPart,
        'isNew': isNew,
      };

  static PersonalRecord fromJson(Map<String, dynamic> json) => PersonalRecord(
        exerciseId: json['exerciseId'] ?? '',
        exerciseName: json['exerciseName'] ?? '',
        maxWeight: (json['maxWeight'] ?? 0).toDouble(),
        reps: json['reps'] ?? 0,
        achievedDate: DateTime.parse(json['achievedDate']),
        bodyPart: json['bodyPart'] ?? '',
        isNew: json['isNew'] ?? false,
      );
}

// ==================== StrengthProgressPoint ====================

extension StrengthProgressPointJson on StrengthProgressPoint {
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weight': weight,
        'reps': reps,
        'estimatedOneRM': estimatedOneRM,
        'isPR': isPR,
      };

  static StrengthProgressPoint fromJson(Map<String, dynamic> json) =>
      StrengthProgressPoint(
        date: DateTime.parse(json['date']),
        weight: (json['weight'] ?? 0).toDouble(),
        reps: json['reps'] ?? 0,
        estimatedOneRM: (json['estimatedOneRM'] ?? 0).toDouble(),
        isPR: json['isPR'] ?? false,
      );
}

// ==================== ExerciseStrengthProgress ====================

extension ExerciseStrengthProgressJson on ExerciseStrengthProgress {
  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'bodyPart': bodyPart,
        'history': history.map((p) => p.toJson()).toList(),
        'currentMax': currentMax,
        'previousMax': previousMax,
        'progressPercentage': progressPercentage,
        'totalSets': totalSets,
        'averageWeight': averageWeight,
      };

  static ExerciseStrengthProgress fromJson(Map<String, dynamic> json) =>
      ExerciseStrengthProgress(
        exerciseId: json['exerciseId'] ?? '',
        exerciseName: json['exerciseName'] ?? '',
        bodyPart: json['bodyPart'] ?? '',
        history: (json['history'] as List<dynamic>?)
                ?.map((e) => StrengthProgressPointJson.fromJson(
                    Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        currentMax: (json['currentMax'] ?? 0).toDouble(),
        previousMax: (json['previousMax'] ?? 0).toDouble(),
        progressPercentage: (json['progressPercentage'] ?? 0).toDouble(),
        totalSets: json['totalSets'] ?? 0,
        averageWeight: (json['averageWeight'] ?? 0).toDouble(),
      );
}

// ==================== MuscleGroupBalanceStats ====================

extension MuscleGroupBalanceStatsJson on MuscleGroupBalanceStats {
  Map<String, dynamic> toJson() => {
        'category': category.name,
        'totalVolume': totalVolume,
        'workoutCount': workoutCount,
        'exerciseCount': exerciseCount,
        'percentage': percentage,
        'topExercises': topExercises,
      };

  static MuscleGroupBalanceStats fromJson(Map<String, dynamic> json) =>
      MuscleGroupBalanceStats(
        category: MuscleGroupCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => MuscleGroupCategory.other,
        ),
        totalVolume: (json['totalVolume'] ?? 0).toDouble(),
        workoutCount: json['workoutCount'] ?? 0,
        exerciseCount: json['exerciseCount'] ?? 0,
        percentage: (json['percentage'] ?? 0).toDouble(),
        topExercises: (json['topExercises'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

// ==================== MuscleGroupBalance ====================

extension MuscleGroupBalanceJson on MuscleGroupBalance {
  Map<String, dynamic> toJson() => {
        'stats': stats.map((s) => s.toJson()).toList(),
        'isPushPullBalanced': isPushPullBalanced,
        'pushPullRatio': pushPullRatio,
        'balanceStatus': balanceStatus,
        'recommendations': recommendations,
      };

  static MuscleGroupBalance fromJson(Map<String, dynamic> json) =>
      MuscleGroupBalance(
        stats: (json['stats'] as List<dynamic>?)
                ?.map((e) => MuscleGroupBalanceStatsJson.fromJson(
                    Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        isPushPullBalanced: json['isPushPullBalanced'] ?? true,
        pushPullRatio: (json['pushPullRatio'] ?? 1.0).toDouble(),
        balanceStatus: json['balanceStatus'] ?? '',
        recommendations: (json['recommendations'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

// ==================== TrainingCalendarDay ====================

extension TrainingCalendarDayJson on TrainingCalendarDay {
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'hasWorkout': hasWorkout,
        'workoutCount': workoutCount,
        'totalVolume': totalVolume,
        'intensity': intensity,
        'bodyParts': bodyParts,
      };

  static TrainingCalendarDay fromJson(Map<String, dynamic> json) =>
      TrainingCalendarDay(
        date: DateTime.parse(json['date']),
        hasWorkout: json['hasWorkout'] ?? false,
        workoutCount: json['workoutCount'] ?? 0,
        totalVolume: (json['totalVolume'] ?? 0).toDouble(),
        intensity: json['intensity'] ?? 0,
        bodyParts: (json['bodyParts'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

// ==================== TrainingCalendarData ====================

extension TrainingCalendarDataJson on TrainingCalendarData {
  Map<String, dynamic> toJson() => {
        'days': days.map((d) => d.toJson()).toList(),
        'maxStreak': maxStreak,
        'currentStreak': currentStreak,
        'averageVolume': averageVolume,
        'totalRestDays': totalRestDays,
      };

  static TrainingCalendarData fromJson(Map<String, dynamic> json) =>
      TrainingCalendarData(
        days: (json['days'] as List<dynamic>?)
                ?.map((e) => TrainingCalendarDayJson.fromJson(
                    Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        maxStreak: json['maxStreak'] ?? 0,
        currentStreak: json['currentStreak'] ?? 0,
        averageVolume: (json['averageVolume'] ?? 0).toDouble(),
        totalRestDays: json['totalRestDays'] ?? 0,
      );
}

// ==================== CompletionRateStats ====================

extension CompletionRateStatsJson on CompletionRateStats {
  Map<String, dynamic> toJson() => {
        'totalPlannedSets': totalPlannedSets,
        'completedSets': completedSets,
        'failedSets': failedSets,
        'completionRate': completionRate,
        'incompleteExercises': incompleteExercises,
        'weakPoints': weakPoints,
      };

  static CompletionRateStats fromJson(Map<String, dynamic> json) =>
      CompletionRateStats(
        totalPlannedSets: json['totalPlannedSets'] ?? 0,
        completedSets: json['completedSets'] ?? 0,
        failedSets: json['failedSets'] ?? 0,
        completionRate: (json['completionRate'] ?? 0).toDouble(),
        incompleteExercises:
            (json['incompleteExercises'] as Map<String, dynamic>?)
                    ?.map((k, v) => MapEntry(k, v as int)) ??
                {},
        weakPoints: (json['weakPoints'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

// ==================== StatisticsData ====================

extension StatisticsDataJson on StatisticsData {
  Map<String, dynamic> toJson() => {
        'timeRange': timeRange.toJsonString(),
        'frequency': frequency.toJson(),
        'volumeHistory': volumeHistory.map((v) => v.toJson()).toList(),
        'bodyPartStats': bodyPartStats.map((b) => b.toJson()).toList(),
        'muscleDetails': muscleDetails
            .map((k, v) => MapEntry(k, v.map((s) => s.toJson()).toList())),
        'trainingTypeStats': trainingTypeStats.map((t) => t.toJson()).toList(),
        'equipmentStats': equipmentStats.map((e) => e.toJson()).toList(),
        'personalRecords': personalRecords.map((p) => p.toJson()).toList(),
        'strengthProgress': strengthProgress.map((s) => s.toJson()).toList(),
        'muscleGroupBalance': muscleGroupBalance?.toJson(),
        'calendarData': calendarData?.toJson(),
        'completionRate': completionRate?.toJson(),
      };

  static StatisticsData fromJson(Map<String, dynamic> json) => StatisticsData(
        timeRange: TimeRangeJson.fromJsonString(json['timeRange'] ?? 'week'),
        frequency: TrainingFrequencyJson.fromJson(
            Map<String, dynamic>.from(json['frequency'] ?? {})),
        volumeHistory: (json['volumeHistory'] as List<dynamic>?)
                ?.map((e) => TrainingVolumePointJson.fromJson(
                    Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        bodyPartStats: (json['bodyPartStats'] as List<dynamic>?)
                ?.map((e) =>
                    BodyPartStatsJson.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        muscleDetails: (json['muscleDetails'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(
                    k,
                    (v as List<dynamic>)
                        .map((s) => SpecificMuscleStatsJson.fromJson(
                            Map<String, dynamic>.from(s)))
                        .toList())) ??
            {},
        trainingTypeStats: (json['trainingTypeStats'] as List<dynamic>?)
                ?.map((e) => TrainingTypeStatsJson.fromJson(
                    Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        equipmentStats: (json['equipmentStats'] as List<dynamic>?)
                ?.map((e) =>
                    EquipmentStatsJson.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        personalRecords: (json['personalRecords'] as List<dynamic>?)
                ?.map((e) =>
                    PersonalRecordJson.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        strengthProgress: (json['strengthProgress'] as List<dynamic>?)
                ?.map((e) => ExerciseStrengthProgressJson.fromJson(
                    Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        muscleGroupBalance: json['muscleGroupBalance'] != null
            ? MuscleGroupBalanceJson.fromJson(
                Map<String, dynamic>.from(json['muscleGroupBalance']))
            : null,
        calendarData: json['calendarData'] != null
            ? TrainingCalendarDataJson.fromJson(
                Map<String, dynamic>.from(json['calendarData']))
            : null,
        completionRate: json['completionRate'] != null
            ? CompletionRateStatsJson.fromJson(
                Map<String, dynamic>.from(json['completionRate']))
            : null,
      );
}
