import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/injury_coach_note_model.dart';

/// InjuryCoachNoteModel 測試
void main() {
  group('InjuryCoachNoteModel', () {
    final testCreatedAt = DateTime(2026, 1, 14, 10, 0, 0);
    final testUpdatedAt = DateTime(2026, 1, 14, 12, 0, 0);

    InjuryCoachNoteModel createTestModel() {
      return InjuryCoachNoteModel(
        id: 'note-001',
        coachId: 'coach-001',
        clientId: 'client-001',
        injurySite: '肩膀',
        note: '建議避免過頭推動作',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );
    }

    group('建構函式', () {
      test('應該正確建立實例', () {
        final model = createTestModel();

        expect(model.id, 'note-001');
        expect(model.coachId, 'coach-001');
        expect(model.clientId, 'client-001');
        expect(model.injurySite, '肩膀');
        expect(model.note, '建議避免過頭推動作');
        expect(model.createdAt, testCreatedAt);
        expect(model.updatedAt, testUpdatedAt);
      });
    });

    group('fromSupabase', () {
      test('應該正確解析 Supabase JSON', () {
        final json = {
          'id': 'note-001',
          'coach_id': 'coach-001',
          'client_id': 'client-001',
          'injury_site': '膝蓋',
          'note': '跑步時要注意',
          'created_at': '2026-01-14T10:00:00.000Z',
          'updated_at': '2026-01-14T12:00:00.000Z',
        };

        final model = InjuryCoachNoteModel.fromSupabase(json);

        expect(model.id, 'note-001');
        expect(model.coachId, 'coach-001');
        expect(model.clientId, 'client-001');
        expect(model.injurySite, '膝蓋');
        expect(model.note, '跑步時要注意');
      });
    });

    group('toSupabase', () {
      test('應該正確轉換為 Supabase 格式', () {
        final model = createTestModel();
        final json = model.toSupabase();

        expect(json['id'], 'note-001');
        expect(json['coach_id'], 'coach-001');
        expect(json['client_id'], 'client-001');
        expect(json['injury_site'], '肩膀');
        expect(json['note'], '建議避免過頭推動作');
      });

      test('不應該包含時間戳記（由資料庫處理）', () {
        final model = createTestModel();
        final json = model.toSupabase();

        expect(json.containsKey('created_at'), isFalse);
        expect(json.containsKey('updated_at'), isFalse);
      });
    });

    group('copyWith', () {
      test('應該複製並修改指定欄位', () {
        final original = createTestModel();
        final copied = original.copyWith(note: '新的備註內容');

        expect(copied.id, original.id);
        expect(copied.note, '新的備註內容');
      });

      test('未指定的欄位應該保持原值', () {
        final original = createTestModel();
        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.coachId, original.coachId);
        expect(copied.clientId, original.clientId);
        expect(copied.injurySite, original.injurySite);
        expect(copied.note, original.note);
      });
    });

    group('equality', () {
      test('相同內容應該相等', () {
        final model1 = createTestModel();
        final model2 = InjuryCoachNoteModel(
          id: 'note-001',
          coachId: 'coach-001',
          clientId: 'client-001',
          injurySite: '肩膀',
          note: '建議避免過頭推動作',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(model1, equals(model2));
      });

      test('不同 id 應該不相等', () {
        final model1 = createTestModel();
        final model2 = model1.copyWith(id: 'note-002');

        expect(model1, isNot(equals(model2)));
      });

      test('不同 note 應該不相等', () {
        final model1 = createTestModel();
        final model2 = model1.copyWith(note: '不同的備註');

        expect(model1, isNot(equals(model2)));
      });
    });

    group('hashCode', () {
      test('相同物件的 hashCode 應該相同', () {
        final model1 = createTestModel();
        final model2 = InjuryCoachNoteModel(
          id: 'note-001',
          coachId: 'coach-001',
          clientId: 'client-001',
          injurySite: '肩膀',
          note: '建議避免過頭推動作',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(model1.hashCode, equals(model2.hashCode));
      });
    });

    group('toString', () {
      test('應該返回可讀的字串', () {
        final model = createTestModel();
        final str = model.toString();

        expect(str, contains('coach-001'));
        expect(str, contains('client-001'));
        expect(str, contains('肩膀'));
      });
    });
  });
}
