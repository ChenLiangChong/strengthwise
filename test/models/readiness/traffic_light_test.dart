import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/readiness/daily_readiness_model.dart';

/// TrafficLight（紅綠燈枚舉）與 ReadinessMetrics 測試
///
/// P0 優先級 - 8 個測試案例（紅綠燈算法）
/// 參考：docs/planning/TESTING_STRATEGY.md #P0
void main() {
  group('TrafficLight', () {
    // =========================================================================
    // P0-47: fromString - 字串解析
    // =========================================================================
    group('fromString', () {
      test('解析 "RED" 為 TrafficLight.red', () {
        // Act
        final result = TrafficLight.fromString('RED');

        // Assert
        expect(result, TrafficLight.red);
      });

      test('解析 "AMBER" 為 TrafficLight.amber', () {
        // Act
        final result = TrafficLight.fromString('AMBER');

        // Assert
        expect(result, TrafficLight.amber);
      });

      test('解析 "GREEN" 為 TrafficLight.green', () {
        // Act
        final result = TrafficLight.fromString('GREEN');

        // Assert
        expect(result, TrafficLight.green);
      });

      // P0-48: null 處理
      test('null 輸入返回 null', () {
        // Act
        final result = TrafficLight.fromString(null);

        // Assert
        expect(result, isNull);
      });

      // P0-49: invalid 處理
      test('無效字串返回預設值 amber', () {
        // Act
        final result = TrafficLight.fromString('INVALID');

        // Assert
        expect(result, TrafficLight.amber);
      });

      test('大小寫不敏感（green → GREEN）', () {
        // Act
        final result = TrafficLight.fromString('green');

        // Assert
        expect(result, TrafficLight.green);
      });

      test('大小寫不敏感（Amber → AMBER）', () {
        // Act
        final result = TrafficLight.fromString('Amber');

        // Assert
        expect(result, TrafficLight.amber);
      });
    });

    // =========================================================================
    // P0-50: getter - label 和 emoji
    // =========================================================================
    group('getters', () {
      test('red 的 value 為 "RED"', () {
        expect(TrafficLight.red.value, 'RED');
      });

      test('amber 的 value 為 "AMBER"', () {
        expect(TrafficLight.amber.value, 'AMBER');
      });

      test('green 的 value 為 "GREEN"', () {
        expect(TrafficLight.green.value, 'GREEN');
      });

      test('red 的 label 為 "需關注"', () {
        expect(TrafficLight.red.label, '需關注');
      });

      test('amber 的 label 為 "稍注意"', () {
        expect(TrafficLight.amber.label, '稍注意');
      });

      test('green 的 label 為 "狀態良好"', () {
        expect(TrafficLight.green.label, '狀態良好');
      });

      test('red 的 emoji 為 🔴', () {
        expect(TrafficLight.red.emoji, '🔴');
      });

      test('amber 的 emoji 為 🟡', () {
        expect(TrafficLight.amber.emoji, '🟡');
      });

      test('green 的 emoji 為 🟢', () {
        expect(TrafficLight.green.emoji, '🟢');
      });
    });
  });

  group('ReadinessMetrics', () {
    // =========================================================================
    // P0-41-46: 序列化與反序列化
    // =========================================================================
    group('fromJson', () {
      test('正確解析完整 JSON', () {
        // Arrange
        final json = {
          'sleep_quality': 4,
          'sleep_hours': 7.5,
          'soreness': 3,
          'stress': 4,
          'energy_level': 5,
          'notes': '感覺不錯',
        };

        // Act
        final result = ReadinessMetrics.fromJson(json);

        // Assert
        expect(result.sleepQuality, 4);
        expect(result.sleepHours, 7.5);
        expect(result.soreness, 3);
        expect(result.stress, 4);
        expect(result.energyLevel, 5);
        expect(result.notes, '感覺不錯');
      });

      test('缺少值使用預設值', () {
        // Arrange - 空 JSON
        final json = <String, dynamic>{};

        // Act
        final result = ReadinessMetrics.fromJson(json);

        // Assert - 使用預設值
        expect(result.sleepQuality, 3);
        expect(result.sleepHours, 7.0);
        expect(result.soreness, 3);
        expect(result.stress, 3);
        expect(result.energyLevel, 3);
        expect(result.notes, isNull);
      });

      test('notes 可為 null', () {
        // Arrange
        final json = {
          'sleep_quality': 4,
          'sleep_hours': 7.0,
          'soreness': 4,
          'stress': 4,
          'energy_level': 4,
          // notes 未提供
        };

        // Act
        final result = ReadinessMetrics.fromJson(json);

        // Assert
        expect(result.notes, isNull);
      });
    });

    group('toJson', () {
      test('正確序列化為 JSON', () {
        // Arrange
        const metrics = ReadinessMetrics(
          sleepQuality: 4,
          sleepHours: 7.5,
          soreness: 3,
          stress: 4,
          energyLevel: 5,
          notes: '測試備註',
        );

        // Act
        final result = metrics.toJson();

        // Assert
        expect(result['sleep_quality'], 4);
        expect(result['sleep_hours'], 7.5);
        expect(result['soreness'], 3);
        expect(result['stress'], 4);
        expect(result['energy_level'], 5);
        expect(result['notes'], '測試備註');
      });
    });

    group('copyWith', () {
      test('複製並修改單一屬性', () {
        // Arrange
        const original = ReadinessMetrics(
          sleepQuality: 3,
          sleepHours: 7.0,
          soreness: 3,
          stress: 3,
          energyLevel: 3,
        );

        // Act
        final result = original.copyWith(sleepQuality: 5);

        // Assert
        expect(result.sleepQuality, 5);
        expect(result.sleepHours, 7.0); // 未變
        expect(result.soreness, 3); // 未變
      });

      test('複製並修改多個屬性', () {
        // Arrange
        const original = ReadinessMetrics(
          sleepQuality: 3,
          sleepHours: 7.0,
          soreness: 3,
          stress: 3,
          energyLevel: 3,
        );

        // Act
        final result = original.copyWith(
          sleepQuality: 5,
          notes: '新備註',
        );

        // Assert
        expect(result.sleepQuality, 5);
        expect(result.notes, '新備註');
      });
    });

    group('empty factory', () {
      test('創建空的 ReadinessMetrics', () {
        // Act
        final result = ReadinessMetrics.empty();

        // Assert
        expect(result.sleepQuality, 3);
        expect(result.sleepHours, 7.0);
        expect(result.soreness, 3);
        expect(result.stress, 3);
        expect(result.energyLevel, 3);
        expect(result.notes, isNull);
      });
    });

    // =========================================================================
    // 權重相關屬性（如果有）
    // =========================================================================
    group('validation', () {
      test('所有指標都在有效範圍內', () {
        // Arrange - 最小值
        const metricsMin = ReadinessMetrics(
          sleepQuality: 1,
          sleepHours: 3,
          soreness: 1,
          stress: 1,
          energyLevel: 1,
        );

        // Assert
        expect(metricsMin.sleepQuality, greaterThanOrEqualTo(1));
        expect(metricsMin.sleepQuality, lessThanOrEqualTo(5));

        // Arrange - 最大值
        const metricsMax = ReadinessMetrics(
          sleepQuality: 5,
          sleepHours: 12,
          soreness: 5,
          stress: 5,
          energyLevel: 5,
        );

        // Assert
        expect(metricsMax.sleepQuality, greaterThanOrEqualTo(1));
        expect(metricsMax.sleepQuality, lessThanOrEqualTo(5));
      });
    });
  });
}
