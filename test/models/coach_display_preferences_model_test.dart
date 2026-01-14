import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/coach_display_preferences_model.dart';

/// CoachDisplayPreferencesModel 測試
void main() {
  group('CoachDisplayPreferencesModel', () {
    final testDate = DateTime(2026, 1, 14, 10, 0, 0);

    group('建構函式', () {
      test('應該正確建立實例', () {
        final model = CoachDisplayPreferencesModel(
          coachId: 'coach-001',
          healthAssessmentFields: ['safety_screening', 'injuries'],
          updatedAt: testDate,
        );

        expect(model.coachId, 'coach-001');
        expect(model.healthAssessmentFields, ['safety_screening', 'injuries']);
        expect(model.updatedAt, testDate);
      });
    });

    group('defaultFields', () {
      test('預設欄位應該包含 5 個項目', () {
        expect(CoachDisplayPreferencesModel.defaultFields.length, 5);
      });

      test('預設欄位應該包含安全篩檢', () {
        expect(CoachDisplayPreferencesModel.defaultFields,
            contains('safety_screening'));
      });

      test('預設欄位應該包含傷病史', () {
        expect(
            CoachDisplayPreferencesModel.defaultFields, contains('injuries'));
      });
    });

    group('availableFields', () {
      test('應該有 11 個可用欄位', () {
        expect(CoachDisplayPreferencesModel.availableFields.length, 11);
      });

      test('每個欄位都有顯示名稱', () {
        for (final entry
            in CoachDisplayPreferencesModel.availableFields.entries) {
          expect(entry.key, isNotEmpty);
          expect(entry.value, isNotEmpty);
        }
      });
    });

    group('fromSupabase', () {
      test('應該正確解析 Supabase JSON', () {
        final json = {
          'coach_id': 'coach-001',
          'health_assessment_fields': ['safety_screening', 'training_goals'],
          'updated_at': '2026-01-14T10:00:00.000Z',
        };

        final model = CoachDisplayPreferencesModel.fromSupabase(json);

        expect(model.coachId, 'coach-001');
        expect(model.healthAssessmentFields.length, 2);
        expect(model.updatedAt.year, 2026);
      });

      test('欄位為 null 時應該使用預設值', () {
        final json = {
          'coach_id': 'coach-001',
          'health_assessment_fields': null,
          'updated_at': '2026-01-14T10:00:00.000Z',
        };

        final model = CoachDisplayPreferencesModel.fromSupabase(json);

        expect(model.healthAssessmentFields,
            CoachDisplayPreferencesModel.defaultFields);
      });
    });

    group('toSupabase', () {
      test('應該正確轉換為 Supabase 格式', () {
        final model = CoachDisplayPreferencesModel(
          coachId: 'coach-001',
          healthAssessmentFields: ['injuries'],
          updatedAt: testDate,
        );

        final json = model.toSupabase();

        expect(json['coach_id'], 'coach-001');
        expect(json['health_assessment_fields'], ['injuries']);
        expect(json['updated_at'], isNotNull);
      });
    });

    group('createDefault', () {
      test('應該創建預設偏好', () {
        final model = CoachDisplayPreferencesModel.createDefault('coach-001');

        expect(model.coachId, 'coach-001');
        expect(model.healthAssessmentFields,
            CoachDisplayPreferencesModel.defaultFields);
      });
    });

    group('isFieldEnabled', () {
      test('啟用的欄位應該返回 true', () {
        final model = CoachDisplayPreferencesModel(
          coachId: 'coach-001',
          healthAssessmentFields: ['safety_screening', 'injuries'],
          updatedAt: testDate,
        );

        expect(model.isFieldEnabled('safety_screening'), isTrue);
        expect(model.isFieldEnabled('injuries'), isTrue);
      });

      test('未啟用的欄位應該返回 false', () {
        final model = CoachDisplayPreferencesModel(
          coachId: 'coach-001',
          healthAssessmentFields: ['safety_screening'],
          updatedAt: testDate,
        );

        expect(model.isFieldEnabled('medications'), isFalse);
      });
    });

    group('copyWith', () {
      test('應該複製並修改指定欄位', () {
        final original = CoachDisplayPreferencesModel(
          coachId: 'coach-001',
          healthAssessmentFields: ['safety_screening'],
          updatedAt: testDate,
        );

        final copied = original.copyWith(
          healthAssessmentFields: ['injuries', 'medications'],
        );

        expect(copied.coachId, 'coach-001'); // 保持不變
        expect(copied.healthAssessmentFields, ['injuries', 'medications']);
      });

      test('未指定的欄位應該保持原值', () {
        final original = CoachDisplayPreferencesModel(
          coachId: 'coach-001',
          healthAssessmentFields: ['safety_screening'],
          updatedAt: testDate,
        );

        final copied = original.copyWith();

        expect(copied.coachId, original.coachId);
        expect(copied.healthAssessmentFields, original.healthAssessmentFields);
        expect(copied.updatedAt, original.updatedAt);
      });
    });

    group('toString', () {
      test('應該返回可讀的字串', () {
        final model = CoachDisplayPreferencesModel(
          coachId: 'coach-001',
          healthAssessmentFields: ['a', 'b', 'c'],
          updatedAt: testDate,
        );

        expect(model.toString(), contains('coach-001'));
        expect(model.toString(), contains('3'));
      });
    });
  });
}
