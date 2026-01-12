---
description: "測試策略與工作流程：單元測試、Widget 測試、驗收標準。適用於 test 目錄。"
globs: test/**/*.dart
alwaysApply: false
---

# 測試規範

<critical>
1. Service 層必須有單元測試
2. 測試必須使用 Given-When-Then 結構
3. 使用 Mock 隔離外部依賴
</critical>

## 📝 測試結構

```dart
test('應該正確計算訓練總量', () {
  // Arrange (Given)
  final records = [WorkoutRecord(weight: 100, reps: 5)];
  
  // Act (When)
  final totalVolume = calculator.calculateTotalVolume(records);
  
  // Assert (Then)
  expect(totalVolume, equals(500));
});
```

## 🔧 Mock 使用

```dart
class MockWorkoutService extends Mock implements IWorkoutService {}

test('Controller 應該載入訓練記錄', () async {
  final mockService = MockWorkoutService();
  when(() => mockService.getRecords())
      .thenAnswer((_) async => [mockRecord]);
  
  final controller = WorkoutController(workoutService: mockService);
  await controller.loadRecords();
  
  expect(controller.records.length, equals(1));
});
```

## ✅ 驗收標準

| 項目 | 目標值 |
|------|--------|
| 冷啟動 | < 200ms |
| 統計頁面 | < 5ms |
| 95% 查詢 | < 50ms |

詳見：`@docs/DEVELOPMENT_STATUS.md`
