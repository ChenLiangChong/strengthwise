import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/exercise/exercise.dart';
import 'package:strengthwise/models/exercise/exercise_mapper.dart';

/// ExerciseMapper 測試
///
/// P1 Models 層 - 10 個測試案例
void main() {
  group('ExerciseMapper', () {
    // =========================================================================
    // fromSupabase
    // =========================================================================
    group('fromSupabase', () {
      test('正確解析完整數據', () {
        final data = {
          'id': 'ex-001',
          'name': '臥推',
          'name_en': 'Bench Press',
          'body_parts': ['胸', '三頭'],
          'training_type': '肌肥大',
          'equipment': '槓鈴',
          'joint_type': '多關節',
          'level1': '推',
          'level2': '水平推',
          'body_part': '胸部',
          'created_at': '2024-01-01T00:00:00Z',
        };

        final exercise = ExerciseMapper.fromSupabase(data);
        expect(exercise.id, 'ex-001');
        expect(exercise.name, '臥推');
        expect(exercise.nameEn, 'Bench Press');
        expect(exercise.bodyParts, ['胸', '三頭']);
      });

      test('處理缺失欄位', () {
        final data = {'id': 'ex-001'};
        final exercise = ExerciseMapper.fromSupabase(data);
        expect(exercise.id, 'ex-001');
        expect(exercise.name, '');
        expect(exercise.bodyParts, isEmpty);
      });

      test('處理 null 值', () {
        final data = {
          'id': null,
          'name': null,
          'body_parts': null,
        };
        final exercise = ExerciseMapper.fromSupabase(data);
        expect(exercise.id, '');
        expect(exercise.name, '');
      });
    });

    // =========================================================================
    // fromJson
    // =========================================================================
    group('fromJson', () {
      test('正確解析 JSON', () {
        final json = {
          'id': 'ex-002',
          'name': '深蹲',
          'nameEn': 'Squat',
          'bodyParts': ['腿', '臀'],
          'type': '力量',
        };

        final exercise = ExerciseMapper.fromJson(json);
        expect(exercise.id, 'ex-002');
        expect(exercise.name, '深蹲');
        expect(exercise.nameEn, 'Squat');
      });

      test('處理 createdAt 時間戳', () {
        final timestamp = DateTime(2024, 1, 1).millisecondsSinceEpoch;
        final json = {
          'id': 'ex-003',
          'createdAt': timestamp,
        };

        final exercise = ExerciseMapper.fromJson(json);
        expect(exercise.createdAt.year, 2024);
      });
    });

    // =========================================================================
    // toJson
    // =========================================================================
    group('toJson', () {
      test('正確轉換為 JSON', () {
        final exercise = Exercise(
          id: 'ex-004',
          name: '硬舉',
          nameEn: 'Deadlift',
          bodyParts: ['背', '腿'],
          type: '力量',
          equipment: '槓鈴',
          jointType: '多關節',
          level1: '拉',
          level2: '硬舉',
          level3: '',
          level4: '',
          level5: '',
          description: '基礎重訓動作',
          videoUrl: '',
          apps: [],
          createdAt: DateTime(2024, 1, 1),
        );

        final json = ExerciseMapper.toJson(exercise);
        expect(json['id'], 'ex-004');
        expect(json['name'], '硬舉');
        expect(json['nameEn'], 'Deadlift');
        expect(json['bodyParts'], ['背', '腿']);
      });

      test('createdAt 轉為毫秒時間戳', () {
        final createdAt = DateTime(2024, 1, 1);
        final exercise = Exercise(
          id: 'ex-005',
          name: '測試',
          nameEn: 'Test',
          bodyParts: [],
          type: '',
          equipment: '',
          jointType: '',
          level1: '',
          level2: '',
          level3: '',
          level4: '',
          level5: '',
          description: '',
          videoUrl: '',
          apps: [],
          createdAt: createdAt,
        );

        final json = ExerciseMapper.toJson(exercise);
        expect(json['createdAt'], createdAt.millisecondsSinceEpoch);
      });
    });

    // =========================================================================
    // 往返轉換
    // =========================================================================
    group('往返轉換', () {
      test('toJson → fromJson 往返正確', () {
        final original = Exercise(
          id: 'ex-006',
          name: '引體向上',
          nameEn: 'Pull Up',
          bodyParts: ['背', '二頭'],
          type: '力量',
          equipment: '單槓',
          jointType: '多關節',
          level1: '拉',
          level2: '垂直拉',
          level3: '',
          level4: '',
          level5: '',
          description: '上肢拉動作',
          videoUrl: '',
          apps: [],
          createdAt: DateTime(2024, 6, 15),
        );

        final json = ExerciseMapper.toJson(original);
        final restored = ExerciseMapper.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.nameEn, original.nameEn);
        expect(restored.bodyParts, original.bodyParts);
      });
    });
  });
}
