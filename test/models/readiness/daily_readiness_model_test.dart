import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/readiness/daily_readiness_model.dart';

/// DailyReadinessModel 測試
///
/// P1 優先級 - 8 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md #P1
void main() {
  group('DailyReadinessModel', () {
    // 測試用的 Supabase 格式 JSON
    final validSupabaseJson = {
      'id': 'readiness-001',
      'user_id': 'user-001',
      'appointment_id': 'apt-001',
      'session_note_id': 'note-001',
      'log_date': '2025-12-15T00:00:00.000Z',
      'readiness_score': 75,
      'traffic_light': 'GREEN',
      'metrics': {
        'sleep_quality': 4,
        'sleep_hours': 7.5,
        'soreness': 3,
        'stress': 4,
        'energy_level': 5,
        'notes': '今天感覺不錯',
      },
      'created_at': '2025-12-15T08:00:00.000Z',
      'updated_at': '2025-12-15T08:00:00.000Z',
    };

    // =========================================================================
    // P1-51: fromSupabase
    // =========================================================================
    group('fromSupabase', () {
      test('正確解析 Supabase 格式', () {
        // Act
        final model = DailyReadinessModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.id, 'readiness-001');
        expect(model.userId, 'user-001');
        expect(model.appointmentId, 'apt-001');
        expect(model.sessionNoteId, 'note-001');
        expect(model.readinessScore, 75);
        expect(model.trafficLight, TrafficLight.green);
      });

      test('正確解析 metrics', () {
        // Act
        final model = DailyReadinessModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.metrics.sleepQuality, 4);
        expect(model.metrics.sleepHours, 7.5);
        expect(model.metrics.soreness, 3);
        expect(model.metrics.stress, 4);
        expect(model.metrics.energyLevel, 5);
        expect(model.metrics.notes, '今天感覺不錯');
      });

      test('空 metrics 使用預設值', () {
        // Arrange
        final json = Map<String, dynamic>.from(validSupabaseJson);
        json['metrics'] = null;

        // Act
        final model = DailyReadinessModel.fromSupabase(json);

        // Assert
        expect(model.metrics.sleepQuality, 3); // 預設值
        expect(model.metrics.sleepHours, 7.0); // 預設值
      });
    });

    // =========================================================================
    // P1-52: toSupabase
    // =========================================================================
    group('toSupabase', () {
      test('正確轉換為 Supabase 格式', () {
        // Arrange
        final model = DailyReadinessModel.fromSupabase(validSupabaseJson);

        // Act
        final map = model.toSupabase();

        // Assert
        expect(map['user_id'], 'user-001');
        expect(map['readiness_score'], 75);
        expect(map['traffic_light'], 'GREEN');
        expect(map['metrics'], isA<Map>());
        expect(map.containsKey('id'), isFalse);
      });

      test('toSupabaseWithId 包含 id', () {
        // Arrange
        final model = DailyReadinessModel.fromSupabase(validSupabaseJson);

        // Act
        final map = model.toSupabaseWithId();

        // Assert
        expect(map['id'], 'readiness-001');
      });
    });

    // =========================================================================
    // P1-53: copyWith
    // =========================================================================
    group('copyWith', () {
      test('複製並修改分數', () {
        // Arrange
        final model = DailyReadinessModel.fromSupabase(validSupabaseJson);

        // Act
        final updated = model.copyWith(readinessScore: 80);

        // Assert
        expect(updated.readinessScore, 80);
        expect(updated.id, model.id);
      });

      test('複製並修改紅綠燈', () {
        // Arrange
        final model = DailyReadinessModel.fromSupabase(validSupabaseJson);

        // Act
        final updated = model.copyWith(trafficLight: TrafficLight.amber);

        // Assert
        expect(updated.trafficLight, TrafficLight.amber);
      });
    });

    // =========================================================================
    // P1-54: isSubmitted
    // =========================================================================
    group('isSubmitted', () {
      test('有分數表示已提交', () {
        // Act
        final model = DailyReadinessModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.isSubmitted, isTrue);
      });

      test('無分數表示未提交', () {
        // Arrange
        final json = Map<String, dynamic>.from(validSupabaseJson);
        json['readiness_score'] = null;

        // Act
        final model = DailyReadinessModel.fromSupabase(json);

        // Assert
        expect(model.isSubmitted, isFalse);
      });
    });

    // =========================================================================
    // P1-55: needsAttention
    // =========================================================================
    group('needsAttention', () {
      test('紅燈需要關注', () {
        // Arrange
        final json = Map<String, dynamic>.from(validSupabaseJson);
        json['traffic_light'] = 'RED';

        // Act
        final model = DailyReadinessModel.fromSupabase(json);

        // Assert
        expect(model.needsAttention, isTrue);
      });

      test('低分需要關注', () {
        // Arrange
        final json = Map<String, dynamic>.from(validSupabaseJson);
        json['readiness_score'] = 40;
        json['traffic_light'] = 'AMBER';

        // Act
        final model = DailyReadinessModel.fromSupabase(json);

        // Assert
        expect(model.needsAttention, isTrue);
      });

      test('綠燈高分不需要關注', () {
        // Act
        final model = DailyReadinessModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.needsAttention, isFalse);
      });
    });
  });

  // TrafficLight 和 ReadinessMetrics 已在 traffic_light_test.dart 測試
}
