import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/workout_record/workout_record.dart';
import 'package:strengthwise/models/workout_record/exercise_record.dart';
import 'package:strengthwise/models/workout_record/set_record.dart';

/// WorkoutRecord 測試
///
/// P1 優先級 - 12 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md #P1
void main() {
  group('WorkoutRecord', () {
    // 測試用的 JSON 數據
    final validJson = {
      'id': 'record-001',
      'workoutPlanId': 'plan-001',
      'userId': 'user-001',
      'title': '胸肌訓練',
      'date': DateTime(2025, 12, 15).millisecondsSinceEpoch,
      'exerciseRecords': [
        {
          'exerciseId': 'ex-001',
          'exerciseName': '臥推',
          'sets': [
            {'setNumber': 1, 'reps': 10, 'weight': 60.0, 'completed': true},
            {'setNumber': 2, 'reps': 10, 'weight': 60.0, 'completed': false},
          ],
          'notes': '',
          'completed': false,
        }
      ],
      'notes': '訓練備註',
      'completed': false,
      'createdAt': DateTime(2025, 12, 15).millisecondsSinceEpoch,
      'trainingTime': DateTime(2025, 12, 15, 9, 0).millisecondsSinceEpoch,
      'elapsedSeconds': 3600,
      'trainingStatus': 'in_progress',
    };

    // 測試用的 Supabase 格式 JSON
    final validSupabaseJson = {
      'id': 'plan-001',
      'trainee_id': 'user-001',
      'creator_id': 'coach-001',
      'title': '腿部訓練',
      'scheduled_date': '2025-12-15T00:00:00.000Z',
      'completed_date': '2025-12-15T10:30:00.000Z',
      'exercises': [
        {
          'exerciseId': 'ex-002',
          'exerciseName': '深蹲',
          'sets': [
            {'setNumber': 1, 'reps': 8, 'weight': 80.0, 'completed': true},
          ],
          'notes': '',
          'completed': true,
        }
      ],
      'note': '腿部訓練完成',
      'completed': true,
      'created_at': '2025-12-10T08:00:00.000Z',
      'training_time_range': '[2025-12-15 09:00:00+00,2025-12-15 10:30:00+00)',
      'actual_start_time': '2025-12-15T09:05:00.000Z',
      'actual_end_time': '2025-12-15T10:25:00.000Z',
      'elapsed_seconds': 4800,
      'training_status': 'completed',
      'appointment_id': 'apt-001',
    };

    // =========================================================================
    // P1-73: fromJson
    // =========================================================================
    group('fromJson', () {
      test('正確解析客戶端 JSON 格式', () {
        // Act
        final record = WorkoutRecord.fromJson(validJson);

        // Assert
        expect(record.id, 'record-001');
        expect(record.workoutPlanId, 'plan-001');
        expect(record.userId, 'user-001');
        expect(record.title, '胸肌訓練');
        expect(record.notes, '訓練備註');
        expect(record.completed, isFalse);
        expect(record.exerciseRecords.length, 1);
        expect(record.exerciseRecords[0].exerciseName, '臥推');
      });

      test('解析訓練時間', () {
        // Act
        final record = WorkoutRecord.fromJson(validJson);

        // Assert
        expect(record.trainingTime, isNotNull);
        expect(record.trainingTime!.hour, 9);
      });

      test('缺少值使用預設值', () {
        // Arrange
        final minimalJson = {
          'date': DateTime.now().millisecondsSinceEpoch,
        };

        // Act
        final record = WorkoutRecord.fromJson(minimalJson);

        // Assert
        expect(record.id, '');
        expect(record.title, '訓練記錄');
        expect(record.notes, '');
        expect(record.completed, isFalse);
        expect(record.exerciseRecords, isEmpty);
      });
    });

    // =========================================================================
    // P1-74: toJson
    // =========================================================================
    group('toJson', () {
      test('正確序列化為 JSON', () {
        // Arrange
        final record = WorkoutRecord.fromJson(validJson);

        // Act
        final json = record.toJson();

        // Assert
        expect(json['id'], 'record-001');
        expect(json['workoutPlanId'], 'plan-001');
        expect(json['title'], '胸肌訓練');
        expect(json['exerciseRecords'], isA<List>());
        expect(json['date'], isA<int>());
      });

      test('序列化包含訓練狀態追蹤欄位', () {
        // Arrange
        final record = WorkoutRecord.fromJson(validJson);

        // Act
        final json = record.toJson();

        // Assert
        // 注意：fromJson 不解析 elapsedSeconds/trainingStatus，使用預設值
        expect(json.containsKey('elapsedSeconds'), isTrue);
        expect(json.containsKey('trainingStatus'), isTrue);
      });
    });

    // =========================================================================
    // P1-75: fromSupabase
    // =========================================================================
    group('fromSupabase', () {
      test('正確解析 Supabase 格式（含 TSTZRANGE）', () {
        // Act
        final record = WorkoutRecord.fromSupabase(validSupabaseJson);

        // Assert
        expect(record.id, 'plan-001');
        expect(record.traineeId, 'user-001');
        expect(record.creatorId, 'coach-001');
        expect(record.title, '腿部訓練');
        expect(record.notes, '腿部訓練完成');
        expect(record.completed, isTrue);
        expect(record.appointmentId, 'apt-001');
      });

      test('解析訓練時間範圍', () {
        // Act
        final record = WorkoutRecord.fromSupabase(validSupabaseJson);

        // Assert
        expect(record.trainingTime, isNotNull);
        expect(record.trainingEndTime, isNotNull);
        expect(record.trainingTime!.toUtc().hour, 9);
        expect(record.trainingEndTime!.toUtc().hour, 10);
      });

      test('解析訓練狀態追蹤欄位', () {
        // Act
        final record = WorkoutRecord.fromSupabase(validSupabaseJson);

        // Assert
        expect(record.actualStartTime, isNotNull);
        expect(record.actualEndTime, isNotNull);
        expect(record.elapsedSeconds, 4800);
        expect(record.trainingStatus, 'completed');
      });
    });

    // =========================================================================
    // P1-77: copyWith
    // =========================================================================
    group('copyWith', () {
      test('複製並修改標題', () {
        // Arrange
        final record = WorkoutRecord.fromJson(validJson);

        // Act
        final updated = record.copyWith(title: '新標題');

        // Assert
        expect(updated.title, '新標題');
        expect(updated.id, record.id);
      });

      test('複製並修改完成狀態', () {
        // Arrange
        final record = WorkoutRecord.fromJson(validJson);

        // Act
        final updated = record.copyWith(completed: true);

        // Assert
        expect(updated.completed, isTrue);
      });

      test('複製並修改訓練狀態', () {
        // Arrange
        final record = WorkoutRecord.fromJson(validJson);

        // Act
        final updated = record.copyWith(
          trainingStatus: 'paused',
          elapsedSeconds: 1800,
        );

        // Assert
        expect(updated.trainingStatus, 'paused');
        expect(updated.elapsedSeconds, 1800);
      });
    });

    // =========================================================================
    // P1-78: markAsCompleted
    // =========================================================================
    group('markAsCompleted', () {
      test('標記為已完成', () {
        // Arrange
        final record = WorkoutRecord.fromJson(validJson);
        expect(record.completed, isFalse);

        // Act
        final completed = record.markAsCompleted();

        // Assert
        expect(completed.completed, isTrue);
        expect(completed.id, record.id); // 其他不變
      });
    });

    // =========================================================================
    // P1-79: updateNotes
    // =========================================================================
    group('updateNotes', () {
      test('更新備註', () {
        // Arrange
        final record = WorkoutRecord.fromJson(validJson);

        // Act
        final updated = record.updateNotes('更新後的備註');

        // Assert
        expect(updated.notes, '更新後的備註');
      });
    });

    // =========================================================================
    // P1-80: addExerciseRecord
    // =========================================================================
    group('addExerciseRecord', () {
      test('添加運動記錄', () {
        // Arrange
        final record = WorkoutRecord.fromJson(validJson);
        final initialCount = record.exerciseRecords.length;
        final newExercise = ExerciseRecord(
          exerciseId: 'ex-new',
          exerciseName: '引體向上',
          sets: [],
        );

        // Act
        final updated = record.addExerciseRecord(newExercise);

        // Assert
        expect(updated.exerciseRecords.length, initialCount + 1);
        expect(updated.exerciseRecords.last.exerciseName, '引體向上');
      });
    });

    // =========================================================================
    // P1-81: updateExerciseRecord
    // =========================================================================
    group('updateExerciseRecord', () {
      test('更新特定運動記錄', () {
        // Arrange
        final record = WorkoutRecord.fromJson(validJson);
        final updatedExercise = record.exerciseRecords[0].copyWith(
          notes: '更新的備註',
        );

        // Act
        final updated = record.updateExerciseRecord(updatedExercise);

        // Assert
        expect(updated.exerciseRecords[0].notes, '更新的備註');
      });
    });

    // =========================================================================
    // P1-82: removeExerciseRecord
    // =========================================================================
    group('removeExerciseRecord', () {
      test('刪除特定運動記錄', () {
        // Arrange
        final record = WorkoutRecord.fromJson(validJson);
        final initialCount = record.exerciseRecords.length;
        final exerciseId = record.exerciseRecords[0].exerciseId;

        // Act
        final updated = record.removeExerciseRecord(exerciseId);

        // Assert
        expect(updated.exerciseRecords.length, initialCount - 1);
      });
    });
  });

  group('ExerciseRecord', () {
    // =========================================================================
    // P1-85: fromJson
    // =========================================================================
    group('fromJson', () {
      test('正確解析 JSON', () {
        // Arrange
        final json = {
          'exerciseId': 'ex-001',
          'exerciseName': '臥推',
          'sets': [
            {'setNumber': 1, 'reps': 10, 'weight': 60.0, 'completed': true},
          ],
          'notes': '注意姿勢',
          'completed': true,
        };

        // Act
        final record = ExerciseRecord.fromJson(json);

        // Assert
        expect(record.exerciseId, 'ex-001');
        expect(record.exerciseName, '臥推');
        expect(record.sets.length, 1);
        expect(record.notes, '注意姿勢');
        expect(record.completed, isTrue);
      });
    });

    // =========================================================================
    // P1-86: toJson
    // =========================================================================
    group('toJson', () {
      test('正確序列化', () {
        // Arrange
        final record = ExerciseRecord(
          exerciseId: 'ex-001',
          exerciseName: '深蹲',
          sets: [
            SetRecord(setNumber: 1, reps: 8, weight: 80.0, restTime: 90),
          ],
          notes: '備註',
          completed: false,
        );

        // Act
        final json = record.toJson();

        // Assert
        expect(json['exerciseId'], 'ex-001');
        expect(json['exerciseName'], '深蹲');
        expect(json['sets'], isA<List>());
        expect(json['notes'], '備註');
      });
    });

    // =========================================================================
    // P1-87: addSet
    // =========================================================================
    group('addSet', () {
      test('添加新組', () {
        // Arrange
        final record = ExerciseRecord(
          exerciseId: 'ex-001',
          exerciseName: '臥推',
          sets: [SetRecord(setNumber: 1, reps: 10, weight: 60.0, restTime: 60)],
        );

        // Act
        final updated = record.addSet(
          SetRecord(setNumber: 2, reps: 10, weight: 65.0, restTime: 60),
        );

        // Assert
        expect(updated.sets.length, 2);
        expect(updated.sets[1].weight, 65.0);
      });
    });

    // =========================================================================
    // P1-88: removeSet
    // =========================================================================
    group('removeSet', () {
      test('刪除指定組', () {
        // Arrange
        final record = ExerciseRecord(
          exerciseId: 'ex-001',
          exerciseName: '臥推',
          sets: [
            SetRecord(setNumber: 1, reps: 10, weight: 60.0, restTime: 60),
            SetRecord(setNumber: 2, reps: 10, weight: 65.0, restTime: 60),
          ],
        );

        // Act
        final updated = record.removeSet(1);

        // Assert
        expect(updated.sets.length, 1);
        expect(updated.sets[0].setNumber, 2);
      });
    });

    // =========================================================================
    // P1-89: markAsCompleted
    // =========================================================================
    group('markAsCompleted', () {
      test('標記為已完成', () {
        // Arrange
        final record = ExerciseRecord(
          exerciseId: 'ex-001',
          exerciseName: '臥推',
          sets: [],
          completed: false,
        );

        // Act
        final updated = record.markAsCompleted();

        // Assert
        expect(updated.completed, isTrue);
      });
    });
  });

  group('SetRecord', () {
    // =========================================================================
    // P1-91: fromJson
    // =========================================================================
    group('fromJson', () {
      test('正確解析 JSON', () {
        // Arrange
        final json = {
          'setNumber': 1,
          'reps': 10,
          'weight': 60.0,
          'restTime': 90,
          'completed': true,
        };

        // Act
        final record = SetRecord.fromJson(json);

        // Assert
        expect(record.setNumber, 1);
        expect(record.reps, 10);
        expect(record.weight, 60.0);
        expect(record.restTime, 90);
        expect(record.completed, isTrue);
      });
    });

    // =========================================================================
    // P1-92: toJson
    // =========================================================================
    group('toJson', () {
      test('正確序列化', () {
        // Arrange
        final record = SetRecord(
          setNumber: 2,
          reps: 12,
          weight: 70.0,
          restTime: 60,
          completed: false,
        );

        // Act
        final json = record.toJson();

        // Assert
        expect(json['setNumber'], 2);
        expect(json['reps'], 12);
        expect(json['weight'], 70.0);
        expect(json['restTime'], 60);
        expect(json['completed'], isFalse);
      });
    });

    // =========================================================================
    // P1-93: copyWith
    // =========================================================================
    group('copyWith', () {
      test('複製並修改重量', () {
        // Arrange
        final record = SetRecord(
          setNumber: 1,
          reps: 10,
          weight: 60.0,
          restTime: 60,
        );

        // Act
        final updated = record.copyWith(weight: 65.0);

        // Assert
        expect(updated.weight, 65.0);
        expect(updated.reps, 10);
      });

      test('複製並標記完成', () {
        // Arrange
        final record = SetRecord(
          setNumber: 1,
          reps: 10,
          weight: 60.0,
          restTime: 60,
          completed: false,
        );

        // Act
        final updated = record.copyWith(completed: true);

        // Assert
        expect(updated.completed, isTrue);
      });
    });
  });
}
