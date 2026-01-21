import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/body_data_record.dart';

import '../../mocks/mock_services.dart';

/// BodyDataService 測試
///
/// P1 優先級 - 15 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockBodyDataService mockService;

  // 測試用的模型資料
  final testRecord = BodyDataRecord(
    id: 'body-001',
    userId: 'user-001',
    weight: 70.5,
    bodyFat: 18.5,
    muscleMass: 32.0,
    recordDate: DateTime(2026, 1, 15),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockBodyDataService();
  });

  group('IBodyDataService', () {
    // =========================================================================
    // createRecord
    // =========================================================================
    group('createRecord', () {
      test('正常建立身體數據記錄', () async {
        // Arrange
        when(() => mockService.createRecord(any()))
            .thenAnswer((_) async => testRecord);

        // Act
        final result = await mockService.createRecord(testRecord);

        // Assert
        expect(result.id, 'body-001');
        expect(result.weight, 70.5);
      });

      test('建立記錄後返回完整資料', () async {
        // Arrange
        when(() => mockService.createRecord(any()))
            .thenAnswer((_) async => testRecord);

        // Act
        final result = await mockService.createRecord(testRecord);

        // Assert
        expect(result.bodyFat, 18.5);
        expect(result.muscleMass, 32.0);
      });
    });

    // =========================================================================
    // updateRecord
    // =========================================================================
    group('updateRecord', () {
      test('正常更新記錄', () async {
        // Arrange
        when(() => mockService.updateRecord(any()))
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.updateRecord(testRecord);

        // Assert
        expect(result, isTrue);
      });

      test('記錄不存在時更新失敗', () async {
        // Arrange
        when(() => mockService.updateRecord(any()))
            .thenAnswer((_) async => false);

        // Act
        final result = await mockService.updateRecord(testRecord);

        // Assert
        expect(result, isFalse);
      });
    });

    // =========================================================================
    // deleteRecord
    // =========================================================================
    group('deleteRecord', () {
      test('正常刪除記錄', () async {
        // Arrange
        when(() => mockService.deleteRecord('body-001'))
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.deleteRecord('body-001');

        // Assert
        expect(result, isTrue);
      });

      test('記錄不存在時刪除失敗', () async {
        // Arrange
        when(() => mockService.deleteRecord('not-exist'))
            .thenAnswer((_) async => false);

        // Act
        final result = await mockService.deleteRecord('not-exist');

        // Assert
        expect(result, isFalse);
      });
    });

    // =========================================================================
    // getUserRecords
    // =========================================================================
    group('getUserRecords', () {
      test('正常獲取用戶記錄', () async {
        // Arrange
        when(() => mockService.getUserRecords(userId: 'user-001'))
            .thenAnswer((_) async => [testRecord]);

        // Act
        final result = await mockService.getUserRecords(userId: 'user-001');

        // Assert
        expect(result.length, 1);
        expect(result[0].userId, 'user-001');
      });

      test('按日期範圍篩選', () async {
        // Arrange
        when(() => mockService.getUserRecords(
              userId: 'user-001',
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).thenAnswer((_) async => [testRecord]);

        // Act
        final result = await mockService.getUserRecords(
          userId: 'user-001',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
        );

        // Assert
        expect(result, isNotEmpty);
      });

      test('空記錄返回空列表', () async {
        // Arrange
        when(() => mockService.getUserRecords(userId: 'new-user'))
            .thenAnswer((_) async => []);

        // Act
        final result = await mockService.getUserRecords(userId: 'new-user');

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // getLatestRecord
    // =========================================================================
    group('getLatestRecord', () {
      test('正常獲取最新記錄', () async {
        // Arrange
        when(() => mockService.getLatestRecord('user-001'))
            .thenAnswer((_) async => testRecord);

        // Act
        final result = await mockService.getLatestRecord('user-001');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'body-001');
      });

      test('無記錄時返回 null', () async {
        // Arrange
        when(() => mockService.getLatestRecord('new-user'))
            .thenAnswer((_) async => null);

        // Act
        final result = await mockService.getLatestRecord('new-user');

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // getRecordByDate
    // =========================================================================
    group('getRecordByDate', () {
      test('正常獲取指定日期記錄', () async {
        // Arrange
        when(() => mockService.getRecordByDate(
              'user-001',
              DateTime(2026, 1, 15),
            )).thenAnswer((_) async => testRecord);

        // Act
        final result = await mockService.getRecordByDate(
          'user-001',
          DateTime(2026, 1, 15),
        );

        // Assert
        expect(result, isNotNull);
      });

      test('該日期無記錄返回 null', () async {
        // Arrange
        when(() => mockService.getRecordByDate(
              'user-001',
              DateTime(2026, 1, 1),
            )).thenAnswer((_) async => null);

        // Act
        final result = await mockService.getRecordByDate(
          'user-001',
          DateTime(2026, 1, 1),
        );

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // getAverageWeight
    // =========================================================================
    group('getAverageWeight', () {
      test('正常計算平均體重', () async {
        // Arrange
        when(() => mockService.getAverageWeight(
              userId: 'user-001',
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).thenAnswer((_) async => 70.0);

        // Act
        final result = await mockService.getAverageWeight(
          userId: 'user-001',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
        );

        // Assert
        expect(result, 70.0);
      });

      test('無記錄時返回 null', () async {
        // Arrange
        when(() => mockService.getAverageWeight(
              userId: 'new-user',
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).thenAnswer((_) async => null);

        // Act
        final result = await mockService.getAverageWeight(
          userId: 'new-user',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
        );

        // Assert
        expect(result, isNull);
      });
    });
  });
}
