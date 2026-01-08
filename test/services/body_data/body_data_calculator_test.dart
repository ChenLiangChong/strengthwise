import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/body_data_record.dart';
import 'package:strengthwise/services/supabase/body_data/body_data_calculator.dart';

/// BodyDataCalculator 測試
///
/// P2 Services 層 - 8 個測試案例
void main() {
  group('BodyDataCalculator', () {
    late BodyDataCalculator calculator;
    final List<String> logs = [];

    setUp(() {
      logs.clear();
      calculator = BodyDataCalculator(
        logDebug: (msg) => logs.add('[DEBUG] $msg'),
        logError: (msg, [error]) => logs.add('[ERROR] $msg'),
      );
    });

    // =========================================================================
    // calculateAverageWeight
    // =========================================================================
    group('calculateAverageWeight', () {
      test('空列表返回 null', () async {
        final result = await calculator.calculateAverageWeight([]);
        expect(result, isNull);
      });

      test('單筆記錄返回該值', () async {
        final now = DateTime.now();
        final records = [
          BodyDataRecord(
              id: '1',
              userId: 'u1',
              weight: 70.0,
              recordDate: now,
              createdAt: now),
        ];
        final result = await calculator.calculateAverageWeight(records);
        expect(result, 70.0);
      });

      test('多筆記錄計算平均', () async {
        final now = DateTime.now();
        final records = [
          BodyDataRecord(
              id: '1',
              userId: 'u1',
              weight: 70.0,
              recordDate: now,
              createdAt: now),
          BodyDataRecord(
              id: '2',
              userId: 'u1',
              weight: 72.0,
              recordDate: now,
              createdAt: now),
          BodyDataRecord(
              id: '3',
              userId: 'u1',
              weight: 74.0,
              recordDate: now,
              createdAt: now),
        ];
        final result = await calculator.calculateAverageWeight(records);
        expect(result, closeTo(72.0, 0.01));
      });

      test('正確計算小數平均', () async {
        final now = DateTime.now();
        final records = [
          BodyDataRecord(
              id: '1',
              userId: 'u1',
              weight: 65.5,
              recordDate: now,
              createdAt: now),
          BodyDataRecord(
              id: '2',
              userId: 'u1',
              weight: 66.3,
              recordDate: now,
              createdAt: now),
        ];
        final result = await calculator.calculateAverageWeight(records);
        expect(result, closeTo(65.9, 0.01));
      });

      test('計算成功後記錄 log', () async {
        final now = DateTime.now();
        final records = [
          BodyDataRecord(
              id: '1',
              userId: 'u1',
              weight: 70.0,
              recordDate: now,
              createdAt: now),
        ];
        await calculator.calculateAverageWeight(records);
        expect(logs.any((log) => log.contains('DEBUG') && log.contains('平均體重')),
            isTrue);
      });
    });
  });
}
