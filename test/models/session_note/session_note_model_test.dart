import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/session_note/session_note_model.dart';
import 'package:strengthwise/models/session_note/soap_note_model.dart';
import 'package:strengthwise/models/session_note/visual_element_model.dart';

/// SessionNoteModel 測試
///
/// P1 優先級 - 8 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md #P1
void main() {
  group('SessionNoteModel', () {
    // 測試用的 Supabase 格式 JSON
    final validSupabaseJson = {
      'id': 'note-001',
      'title': '第一堂訓練',
      'client_id': 'client-001',
      'coach_id': 'coach-001',
      'coach_name': '王教練',
      'client_name': '李學員',
      'appointment_id': 'apt-001',
      'workout_log_id': 'log-001',
      'content': {
        'soap': {
          'subjective': '學員表示昨晚睡眠不好',
          'objective': '深蹲動作角度不足',
          'assessment': '需要加強髖關節活動度',
          'plan': '下次課程增加活動度訓練',
        },
        'visual_elements': [
          {
            'type': 'text',
            'value': '重點筆記',
          }
        ],
        'quick_tags': ['深蹲', '活動度'],
        'follow_up_date': '2025-12-20T00:00:00.000Z',
      },
      'visibility': 'shared',
      'hidden_by_client': false,
      'hidden_by_coach': false,
      'created_at': '2025-12-15T09:00:00.000Z',
      'updated_at': '2025-12-15T10:00:00.000Z',
    };

    // =========================================================================
    // P1-95: fromSupabase
    // =========================================================================
    group('fromSupabase', () {
      test('正確解析完整 Supabase 格式', () {
        // Act
        final model = SessionNoteModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.id, 'note-001');
        expect(model.title, '第一堂訓練');
        expect(model.clientId, 'client-001');
        expect(model.coachId, 'coach-001');
        expect(model.coachName, '王教練');
        expect(model.clientName, '李學員');
        expect(model.appointmentId, 'apt-001');
        expect(model.visibility, 'shared');
        expect(model.hiddenByClient, isFalse);
        expect(model.hiddenByCoach, isFalse);
      });

      test('正確解析 SOAP 內容', () {
        // Act
        final model = SessionNoteModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.soap, isNotNull);
        expect(model.soap!.subjective, '學員表示昨晚睡眠不好');
        expect(model.soap!.objective, '深蹲動作角度不足');
        expect(model.soap!.assessment, '需要加強髖關節活動度');
        expect(model.soap!.plan, '下次課程增加活動度訓練');
      });

      test('正確解析視覺元素', () {
        // Act
        final model = SessionNoteModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.visualElements.length, 1);
        expect(model.visualElements[0], isA<TextElementModel>());
      });

      test('正確解析 quickTags', () {
        // Act
        final model = SessionNoteModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.quickTags, ['深蹲', '活動度']);
      });

      test('空 content 使用預設值', () {
        // Arrange
        final json = <String, dynamic>{
          'id': 'note-002',
          'title': '空筆記',
          'created_at': '2025-12-15T09:00:00.000Z',
          'updated_at': '2025-12-15T10:00:00.000Z',
          'content': <String, dynamic>{},
        };

        // Act
        final model = SessionNoteModel.fromSupabase(json);

        // Assert
        expect(model.soap, isNull);
        expect(model.visualElements, isEmpty);
        expect(model.quickTags, isEmpty);
        expect(model.visibility, 'shared');
      });
    });

    // =========================================================================
    // P1-96: toSupabase
    // =========================================================================
    group('toSupabase', () {
      test('正確轉換為 Supabase 格式', () {
        // Arrange
        final model = SessionNoteModel.fromSupabase(validSupabaseJson);

        // Act
        final map = model.toSupabase();

        // Assert
        expect(map['title'], '第一堂訓練');
        expect(map['client_id'], 'client-001');
        expect(map['coach_id'], 'coach-001');
        expect(map['visibility'], 'shared');
        expect(map['content'], isA<Map>());
      });

      test('includeId=false 不包含 id', () {
        // Arrange
        final model = SessionNoteModel.fromSupabase(validSupabaseJson);

        // Act
        final map = model.toSupabase(includeId: false);

        // Assert
        expect(map.containsKey('id'), isFalse);
      });

      test('正確序列化 SOAP 到 content', () {
        // Arrange
        final model = SessionNoteModel.fromSupabase(validSupabaseJson);

        // Act
        final map = model.toSupabase();
        final content = map['content'] as Map<String, dynamic>;

        // Assert
        expect(content['soap'], isNotNull);
        expect(content['quick_tags'], ['深蹲', '活動度']);
      });
    });

    // =========================================================================
    // P1-97: copyWith
    // =========================================================================
    group('copyWith', () {
      test('複製並修改標題', () {
        // Arrange
        final model = SessionNoteModel.fromSupabase(validSupabaseJson);

        // Act
        final updated = model.copyWith(title: '更新的標題');

        // Assert
        expect(updated.title, '更新的標題');
        expect(updated.id, model.id);
      });

      test('複製並修改 visibility', () {
        // Arrange
        final model = SessionNoteModel.fromSupabase(validSupabaseJson);

        // Act
        final updated = model.copyWith(visibility: 'private');

        // Assert
        expect(updated.visibility, 'private');
        expect(updated.isPrivate, isTrue);
      });

      test('複製並修改 hidden 狀態', () {
        // Arrange
        final model = SessionNoteModel.fromSupabase(validSupabaseJson);

        // Act
        final updated = model.copyWith(
          hiddenByClient: true,
          hiddenByCoach: true,
        );

        // Assert
        expect(updated.hiddenByClient, isTrue);
        expect(updated.hiddenByCoach, isTrue);
      });
    });

    // =========================================================================
    // P1-99: visibility getters
    // =========================================================================
    group('visibility getters', () {
      test('isPrivate 正確判斷', () {
        // Arrange
        final json = Map<String, dynamic>.from(validSupabaseJson);
        json['visibility'] = 'private';
        final model = SessionNoteModel.fromSupabase(json);

        // Assert
        expect(model.isPrivate, isTrue);
        expect(model.isShared, isFalse);
      });

      test('isShared 正確判斷', () {
        // Act
        final model = SessionNoteModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.isShared, isTrue);
        expect(model.isPrivate, isFalse);
      });
    });

    // =========================================================================
    // P1-100: isEmpty
    // =========================================================================
    group('isEmpty', () {
      test('有 SOAP 內容不為空', () {
        // Act
        final model = SessionNoteModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.isEmpty, isFalse);
      });

      test('無內容為空', () {
        // Arrange
        final emptyJson = <String, dynamic>{
          'id': 'note-empty',
          'title': '空筆記',
          'created_at': '2025-12-15T09:00:00.000Z',
          'updated_at': '2025-12-15T10:00:00.000Z',
          'content': <String, dynamic>{},
        };
        final model = SessionNoteModel.fromSupabase(emptyJson);

        // Assert
        expect(model.isEmpty, isTrue);
      });
    });

    // =========================================================================
    // P1-101: hasVisualElements
    // =========================================================================
    group('hasVisualElements', () {
      test('有視覺元素', () {
        // Act
        final model = SessionNoteModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.hasVisualElements, isTrue);
      });

      test('無視覺元素', () {
        // Arrange - 創建完整的新 JSON
        final json = <String, dynamic>{
          'id': 'note-003',
          'title': '無視覺元素筆記',
          'content': <String, dynamic>{},
          'created_at': '2025-12-15T09:00:00.000Z',
          'updated_at': '2025-12-15T10:00:00.000Z',
        };
        final model = SessionNoteModel.fromSupabase(json);

        // Assert
        expect(model.hasVisualElements, isFalse);
      });
    });
  });

  group('SoapNoteModel', () {
    // =========================================================================
    // P1-103: fromJson
    // =========================================================================
    group('fromJson', () {
      test('正確解析 JSON', () {
        // Arrange
        final json = {
          'subjective': '主觀描述',
          'objective': '客觀觀察',
          'assessment': '評估分析',
          'plan': '計劃建議',
        };

        // Act
        final soap = SoapNoteModel.fromJson(json);

        // Assert
        expect(soap.subjective, '主觀描述');
        expect(soap.objective, '客觀觀察');
        expect(soap.assessment, '評估分析');
        expect(soap.plan, '計劃建議');
      });

      test('缺少值使用預設值', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final soap = SoapNoteModel.fromJson(json);

        // Assert
        expect(soap.subjective, isNull);
        expect(soap.objective, isNull);
        expect(soap.assessment, isNull);
        expect(soap.plan, isNull);
      });
    });

    // =========================================================================
    // P1-104: toJson
    // =========================================================================
    group('toJson', () {
      test('正確序列化', () {
        // Arrange
        const soap = SoapNoteModel(
          subjective: 'S',
          objective: 'O',
          assessment: 'A',
          plan: 'P',
        );

        // Act
        final json = soap.toJson();

        // Assert
        expect(json['subjective'], 'S');
        expect(json['objective'], 'O');
        expect(json['assessment'], 'A');
        expect(json['plan'], 'P');
      });
    });

    // =========================================================================
    // P1-105: copyWith
    // =========================================================================
    group('copyWith', () {
      test('複製並修改', () {
        // Arrange
        const soap = SoapNoteModel(
          subjective: '原始',
          objective: null,
          assessment: null,
          plan: null,
        );

        // Act
        final updated = soap.copyWith(subjective: '更新');

        // Assert
        expect(updated.subjective, '更新');
      });
    });

    // =========================================================================
    // P1-106: isEmpty
    // =========================================================================
    group('isEmpty', () {
      test('有內容不為空', () {
        // Arrange
        const soap = SoapNoteModel(
          subjective: '有內容',
          objective: null,
          assessment: null,
          plan: null,
        );

        // Assert
        expect(soap.isEmpty, isFalse);
      });

      test('全空為空', () {
        // Arrange
        const soap = SoapNoteModel(
          subjective: null,
          objective: null,
          assessment: null,
          plan: null,
        );

        // Assert
        expect(soap.isEmpty, isTrue);
      });
    });
  });
}
