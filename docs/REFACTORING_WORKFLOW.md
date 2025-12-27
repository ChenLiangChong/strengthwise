# StrengthWise - 重構與測試實施工作流程

> 分階段、可驗證的架構重構執行指南

**文檔版本**：v1.0  
**最後更新**：2024年12月27日  
**預計完成時間**：6-10 週（全職開發）

---

## 📋 工作流程概覽

```
Phase 1: 測試基礎設施 (Week 1)
    ↓
Phase 2: Use Case 提取 (Week 2-3)
    ↓
Phase 3: 全面測試覆蓋 (Week 4-6)
    ↓
Phase 4: 持續優化 (Ongoing)
```

---

## 🎯 Phase 1: 建立測試基礎設施（Week 1）

### 目標
- ✅ 讓專案「可測試」
- ✅ 建立第一批測試範例
- ✅ 配置 CI/CD 自動測試

### Day 1：環境配置

#### Task 1.1：安裝測試依賴

```bash
# 編輯 pubspec.yaml
flutter pub add mocktail --dev
flutter pub add fake_async --dev

# 如果使用 BLoC
flutter pub add bloc_test --dev

# 安裝依賴
flutter pub get
```

**驗證**：
```bash
flutter pub deps | grep mocktail
# 應該顯示：mocktail 1.0.x
```

#### Task 1.2：建立測試目錄結構

```bash
# 建立目錄
mkdir -p test/domain/entities
mkdir -p test/domain/usecases
mkdir -p test/data/models
mkdir -p test/data/repositories
mkdir -p test/presentation/controllers
mkdir -p test/presentation/widgets
mkdir -p test/helpers
mkdir -p test/fixtures
```

**驗證**：
```bash
tree test/
# 應該顯示完整的目錄結構
```

#### Task 1.3：創建測試輔助工具

創建 `test/helpers/test_helper.dart`：

```dart
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/services/interfaces/i_workout_service.dart';
import 'package:strengthwise/services/interfaces/i_statistics_service.dart';
import 'package:strengthwise/models/workout_plan_model.dart';
import 'package:strengthwise/models/exercise_model.dart';

// ============ Mock 類別 ============

class MockWorkoutService extends Mock implements IWorkoutService {}
class MockStatisticsService extends Mock implements IStatisticsService {}
class MockExerciseService extends Mock implements IExerciseService {}

// ============ 測試數據工廠 ============

class TestDataFactory {
  /// 創建測試用的訓練計劃
  static WorkoutPlan createWorkoutPlan({
    String? id,
    String? userId,
    String? traineeId,
    DateTime? scheduledDate,
    bool completed = false,
    List<Exercise>? exercises,
  }) {
    return WorkoutPlan(
      id: id ?? 'test-workout-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId ?? 'test-user-123',
      traineeId: traineeId ?? 'test-trainee-123',
      creatorId: userId ?? 'test-user-123',
      scheduledDate: scheduledDate ?? DateTime.now(),
      completed: completed,
      exercises: exercises ?? [createExercise()],
      notes: '測試備註',
      duration: 60,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 創建測試用的動作
  static Exercise createExercise({
    String? exerciseId,
    String? exerciseName,
    List<SetData>? sets,
  }) {
    return Exercise(
      exerciseId: exerciseId ?? 'test-exercise-123',
      exerciseName: exerciseName ?? '深蹲',
      sets: sets ?? [
        createSetData(weight: 100, reps: 10),
        createSetData(weight: 100, reps: 10),
      ],
      bodyPart: '腿部',
      equipment: '槓鈴',
    );
  }

  /// 創建測試用的組數據
  static SetData createSetData({
    double weight = 100,
    int reps = 10,
    int? duration,
    double? distance,
  }) {
    return SetData(
      weight: weight,
      reps: reps,
      duration: duration,
      distance: distance,
      completed: true,
    );
  }
}

// ============ 測試常量 ============

class TestConstants {
  static const String testUserId = 'test-user-123';
  static const String testTraineeId = 'test-trainee-123';
  static final DateTime testDate = DateTime(2024, 12, 27);
}
```

**驗證**：
```bash
flutter analyze test/helpers/test_helper.dart
# 應該沒有錯誤
```

---

### Day 2-3：建立第一批測試

#### Task 2.1：測試 Model 轉換

創建 `test/data/models/workout_plan_model_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/workout_plan_model.dart';
import '../../helpers/test_helper.dart';

void main() {
  group('WorkoutPlanModel', () {
    final tWorkoutPlan = TestDataFactory.createWorkoutPlan(
      id: 'test-123',
      userId: 'user-123',
      completed: false,
    );

    group('fromSupabase', () {
      test('應該正確解析 JSON 數據', () {
        // Arrange
        final jsonMap = {
          'id': 'test-123',
          'user_id': 'user-123',
          'trainee_id': 'trainee-123',
          'creator_id': 'user-123',
          'scheduled_date': '2024-12-27T10:00:00.000Z',
          'completed': false,
          'exercises': [],
          'notes': '測試備註',
          'duration': 60,
          'created_at': '2024-12-27T09:00:00.000Z',
          'updated_at': '2024-12-27T09:00:00.000Z',
        };

        // Act
        final result = WorkoutPlan.fromSupabase(jsonMap);

        // Assert
        expect(result.id, equals('test-123'));
        expect(result.userId, equals('user-123'));
        expect(result.completed, isFalse);
        expect(result.exercises, isEmpty);
      });

      test('應該處理空值欄位', () {
        // Arrange
        final jsonMap = {
          'id': 'test-123',
          'user_id': 'user-123',
          'trainee_id': null,  // 可能為空
          'creator_id': 'user-123',
          'scheduled_date': '2024-12-27T10:00:00.000Z',
          'completed': false,
          'exercises': [],
          'notes': null,  // 可能為空
          'duration': null,  // 可能為空
          'created_at': '2024-12-27T09:00:00.000Z',
          'updated_at': '2024-12-27T09:00:00.000Z',
        };

        // Act
        final result = WorkoutPlan.fromSupabase(jsonMap);

        // Assert
        expect(result.traineeId, isNull);
        expect(result.notes, isNull);
        expect(result.duration, isNull);
      });
    });

    group('toMap', () {
      test('應該正確轉換為 Map', () {
        // Act
        final result = tWorkoutPlan.toMap();

        // Assert
        expect(result['id'], equals(tWorkoutPlan.id));
        expect(result['user_id'], equals(tWorkoutPlan.userId));
        expect(result['completed'], equals(false));
        expect(result, containsKey('scheduled_date'));
      });

      test('轉換後應該可以重新解析', () {
        // Act
        final map = tWorkoutPlan.toMap();
        final reconstructed = WorkoutPlan.fromSupabase(map);

        // Assert
        expect(reconstructed.id, equals(tWorkoutPlan.id));
        expect(reconstructed.userId, equals(tWorkoutPlan.userId));
        expect(reconstructed.completed, equals(tWorkoutPlan.completed));
      });
    });
  });
}
```

**執行測試**：
```bash
flutter test test/data/models/workout_plan_model_test.dart
```

**驗收標準**：
- ✅ 所有測試通過（綠燈）
- ✅ 執行時間 < 2 秒
- ✅ 覆蓋 Model 的主要轉換方法

#### Task 2.2：測試業務邏輯

創建 `test/domain/entities/workout_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_helper.dart';

void main() {
  group('Workout Entity Business Logic', () {
    group('calculateTotalVolume', () {
      test('應該正確計算訓練總量', () {
        // Arrange
        final workout = TestDataFactory.createWorkoutPlan(
          exercises: [
            TestDataFactory.createExercise(
              sets: [
                TestDataFactory.createSetData(weight: 100, reps: 10),  // 1000
                TestDataFactory.createSetData(weight: 100, reps: 10),  // 1000
              ],
            ),
            TestDataFactory.createExercise(
              exerciseName: '臥推',
              sets: [
                TestDataFactory.createSetData(weight: 80, reps: 8),  // 640
              ],
            ),
          ],
        );

        // Act
        final totalVolume = workout.calculateTotalVolume();

        // Assert
        expect(totalVolume, equals(2640.0));
      });

      test('空訓練計劃應該返回 0', () {
        // Arrange
        final workout = TestDataFactory.createWorkoutPlan(exercises: []);

        // Act
        final totalVolume = workout.calculateTotalVolume();

        // Assert
        expect(totalVolume, equals(0.0));
      });

      test('應該忽略未完成的組', () {
        // Arrange
        final workout = TestDataFactory.createWorkoutPlan(
          exercises: [
            Exercise(
              exerciseId: '1',
              exerciseName: '深蹲',
              sets: [
                SetData(weight: 100, reps: 10, completed: true),   // 計入
                SetData(weight: 100, reps: 10, completed: false),  // 不計入
              ],
            ),
          ],
        );

        // Act
        final totalVolume = workout.calculateTotalVolume();

        // Assert
        expect(totalVolume, equals(1000.0));
      });
    });

    group('isPersonalRecord', () {
      test('當訓練量超過歷史最佳時應該返回 true', () {
        // Arrange
        final workout = TestDataFactory.createWorkoutPlan(
          exercises: [
            TestDataFactory.createExercise(
              sets: [
                TestDataFactory.createSetData(weight: 100, reps: 10),
                TestDataFactory.createSetData(weight: 100, reps: 10),
              ],
            ),
          ],
        );
        final previousBest = 1500.0;

        // Act
        final isPR = workout.isPersonalRecord(previousBest);

        // Assert
        expect(isPR, isTrue);
        expect(workout.calculateTotalVolume(), greaterThan(previousBest));
      });

      test('當訓練量未超過歷史最佳時應該返回 false', () {
        // Arrange
        final workout = TestDataFactory.createWorkoutPlan(
          exercises: [
            TestDataFactory.createExercise(
              sets: [
                TestDataFactory.createSetData(weight: 50, reps: 10),
              ],
            ),
          ],
        );
        final previousBest = 1000.0;

        // Act
        final isPR = workout.isPersonalRecord(previousBest);

        // Assert
        expect(isPR, isFalse);
      });
    });
  });
}
```

**執行測試**：
```bash
flutter test test/domain/entities/workout_test.dart
```

#### Task 2.3：測試 Controller

創建 `test/presentation/controllers/workout_controller_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/controllers/workout_controller.dart';
import '../../helpers/test_helper.dart';

void main() {
  late WorkoutController controller;
  late MockWorkoutService mockService;

  setUp(() {
    mockService = MockWorkoutService();
    controller = WorkoutController(mockService);

    // 註冊 fallback 值
    registerFallbackValue(TestDataFactory.createWorkoutPlan());
  });

  tearDown(() {
    controller.dispose();
  });

  group('WorkoutController', () {
    group('loadPlans', () {
      test('應該載入訓練計劃列表', () async {
        // Arrange
        final testPlans = [
          TestDataFactory.createWorkoutPlan(id: '1'),
          TestDataFactory.createWorkoutPlan(id: '2'),
        ];
        when(() => mockService.getUserWorkoutPlans(any()))
          .thenAnswer((_) async => testPlans);

        // Act
        await controller.loadPlans(TestConstants.testUserId);

        // Assert
        expect(controller.plans, hasLength(2));
        expect(controller.isLoading, isFalse);
        expect(controller.errorMessage, isNull);
        verify(() => mockService.getUserWorkoutPlans(TestConstants.testUserId))
          .called(1);
      });

      test('載入時應該設置 isLoading 狀態', () async {
        // Arrange
        when(() => mockService.getUserWorkoutPlans(any()))
          .thenAnswer((_) async {
            await Future.delayed(Duration(milliseconds: 100));
            return [];
          });

        final loadingStates = <bool>[];
        controller.addListener(() {
          loadingStates.add(controller.isLoading);
        });

        // Act
        await controller.loadPlans(TestConstants.testUserId);

        // Assert
        expect(loadingStates, equals([true, false]));
      });

      test('載入失敗時應該設置錯誤訊息', () async {
        // Arrange
        when(() => mockService.getUserWorkoutPlans(any()))
          .thenThrow(Exception('網絡錯誤'));

        // Act
        await controller.loadPlans(TestConstants.testUserId);

        // Assert
        expect(controller.isLoading, isFalse);
        expect(controller.errorMessage, isNotNull);
        expect(controller.errorMessage, contains('錯誤'));
      });
    });

    group('createRecord', () {
      test('應該成功創建訓練記錄', () async {
        // Arrange
        final testPlan = TestDataFactory.createWorkoutPlan();
        when(() => mockService.createRecord(any()))
          .thenAnswer((_) async => {});

        // Act
        await controller.createRecord(testPlan);

        // Assert
        expect(controller.errorMessage, isNull);
        verify(() => mockService.createRecord(testPlan)).called(1);
      });

      test('創建失敗時應該顯示錯誤', () async {
        // Arrange
        final testPlan = TestDataFactory.createWorkoutPlan();
        when(() => mockService.createRecord(any()))
          .thenThrow(Exception('保存失敗'));

        // Act
        await controller.createRecord(testPlan);

        // Assert
        expect(controller.errorMessage, isNotNull);
      });
    });
  });
}
```

**執行測試**：
```bash
flutter test test/presentation/controllers/workout_controller_test.dart
```

---

### Day 4-5：配置 CI/CD

#### Task 4.1：創建 GitHub Actions 工作流

創建 `.github/workflows/test.yml`：

```yaml
name: Flutter Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 15

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v3

      - name: ☕ Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: 🐦 Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'
          cache: true

      - name: 📦 Install dependencies
        run: flutter pub get

      - name: 🔍 Verify dependencies
        run: flutter pub deps

      - name: 📊 Analyze code
        run: flutter analyze

      - name: 🧪 Run tests with coverage
        run: flutter test --coverage

      - name: 📈 Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info
          fail_ci_if_error: false

      - name: 📝 Generate coverage report
        run: |
          sudo apt-get install -y lcov
          genhtml coverage/lcov.info -o coverage/html

      - name: 📦 Archive coverage report
        uses: actions/upload-artifact@v3
        with:
          name: coverage-report
          path: coverage/html
```

**驗證**：
```bash
# 推送到 GitHub 後檢查 Actions 是否執行
git add .github/workflows/test.yml
git commit -m "feat: 新增 CI/CD 自動測試"
git push
```

#### Task 4.2：本地測試覆蓋率檢查

創建 `scripts/run_tests_with_coverage.sh`：

```bash
#!/bin/bash

# 執行測試並生成覆蓋率報告
flutter test --coverage

# 檢查是否成功生成覆蓋率文件
if [ ! -f "coverage/lcov.info" ]; then
  echo "❌ 覆蓋率文件生成失敗"
  exit 1
fi

# 生成 HTML 報告（需要安裝 lcov）
if command -v genhtml &> /dev/null; then
  genhtml coverage/lcov.info -o coverage/html
  echo "✅ 覆蓋率報告已生成：coverage/html/index.html"
  
  # 自動開啟報告（macOS）
  if [[ "$OSTYPE" == "darwin"* ]]; then
    open coverage/html/index.html
  fi
else
  echo "⚠️  請安裝 lcov 以生成 HTML 報告：sudo apt-get install lcov"
fi

# 顯示覆蓋率摘要
echo ""
echo "📊 測試覆蓋率摘要："
lcov --summary coverage/lcov.info 2>&1 | tail -n 4
```

**賦予執行權限**：
```bash
chmod +x scripts/run_tests_with_coverage.sh
```

**執行**：
```bash
./scripts/run_tests_with_coverage.sh
```

---

### Week 1 驗收標準

**完成檢查清單**：

- [ ] ✅ 安裝所有測試依賴（mocktail, fake_async）
- [ ] ✅ 建立完整的測試目錄結構
- [ ] ✅ 創建測試輔助工具（TestDataFactory, Mocks）
- [ ] ✅ 完成至少 10 個測試用例
  - [ ] Model 轉換測試（至少 5 個）
  - [ ] 業務邏輯測試（至少 3 個）
  - [ ] Controller 測試（至少 2 個）
- [ ] ✅ 所有測試通過（綠燈）
- [ ] ✅ CI/CD 自動測試配置完成
- [ ] ✅ 本地可生成覆蓋率報告

**關鍵指標**：
- ✅ 測試執行時間：< 5 秒
- ✅ 測試覆蓋率：> 20%（初始目標）
- ✅ CI 通過率：100%

---

## 🎯 Phase 2: Use Case 提取（Week 2-3）

### 目標
- ✅ 提取核心業務邏輯為獨立的 Use Cases
- ✅ 為所有 Use Cases 建立完整測試
- ✅ 重構 Controllers 使用 Use Cases

### Week 2：建立 Use Case 層

#### Task 5.1：定義 Use Case 基礎架構

創建 `lib/core/usecases/usecase.dart`：

```dart
import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Use Case 基礎介面
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// 無參數的 Use Case
abstract class UseCaseNoParams<Type> {
  Future<Either<Failure, Type>> call();
}
```

創建 `lib/core/errors/failures.dart`：

```dart
/// 失敗的基礎類別
abstract class Failure {
  final String message;
  const Failure(this.message);
}

/// 數據庫錯誤
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

/// 驗證錯誤
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// 網絡錯誤
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// 未知錯誤
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
```

**安裝依賴**：
```yaml
dependencies:
  dartz: ^0.10.1
```

#### Task 5.2：創建核心 Use Cases

**Use Case 1: SaveWorkoutUseCase**

創建 `lib/domain/usecases/save_workout_usecase.dart`：

```dart
import 'package:dartz/dartz.dart';
import '../../core/usecases/usecase.dart';
import '../../core/errors/failures.dart';
import '../../models/workout_plan_model.dart';
import '../../services/interfaces/i_workout_service.dart';

/// 保存訓練計劃的用例
class SaveWorkoutUseCase implements UseCase<void, SaveWorkoutParams> {
  final IWorkoutService _workoutService;

  SaveWorkoutUseCase(this._workoutService);

  @override
  Future<Either<Failure, void>> call(SaveWorkoutParams params) async {
    // 業務驗證
    final validationResult = _validateWorkout(params.workout);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // 執行保存
    try {
      await _workoutService.createRecord(params.workout);
      return Right(null);
    } catch (e) {
      return Left(UnknownFailure('保存訓練計劃失敗：$e'));
    }
  }

  /// 驗證訓練計劃
  ValidationFailure? _validateWorkout(WorkoutPlan workout) {
    if (workout.exercises.isEmpty) {
      return ValidationFailure('訓練計劃必須包含至少一個動作');
    }

    if (workout.completed && workout.scheduledDate.isAfter(DateTime.now())) {
      return ValidationFailure('不能將未來的訓練標記為已完成');
    }

    // 檢查是否所有動作都有至少一組
    for (final exercise in workout.exercises) {
      if (exercise.sets.isEmpty) {
        return ValidationFailure('動作「${exercise.exerciseName}」必須包含至少一組');
      }
    }

    return null;
  }
}

/// 參數類別
class SaveWorkoutParams {
  final WorkoutPlan workout;

  const SaveWorkoutParams({required this.workout});
}
```

**測試**：創建 `test/domain/usecases/save_workout_usecase_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:strengthwise/domain/usecases/save_workout_usecase.dart';
import 'package:strengthwise/core/errors/failures.dart';
import '../../helpers/test_helper.dart';

void main() {
  late SaveWorkoutUseCase useCase;
  late MockWorkoutService mockService;

  setUp(() {
    mockService = MockWorkoutService();
    useCase = SaveWorkoutUseCase(mockService);

    registerFallbackValue(TestDataFactory.createWorkoutPlan());
  });

  group('SaveWorkoutUseCase', () {
    final tWorkout = TestDataFactory.createWorkoutPlan(
      exercises: [TestDataFactory.createExercise()],
    );

    test('應該在驗證通過時調用 service.createRecord', () async {
      // Arrange
      when(() => mockService.createRecord(any()))
        .thenAnswer((_) async => {});

      // Act
      final result = await useCase(SaveWorkoutParams(workout: tWorkout));

      // Assert
      expect(result, equals(Right(null)));
      verify(() => mockService.createRecord(tWorkout)).called(1);
    });

    test('當訓練計劃為空時應該返回 ValidationFailure', () async {
      // Arrange
      final emptyWorkout = TestDataFactory.createWorkoutPlan(exercises: []);

      // Act
      final result = await useCase(SaveWorkoutParams(workout: emptyWorkout));

      // Assert
      expect(result, isA<Left<Failure, void>>());
      expect(
        (result as Left).value,
        isA<ValidationFailure>()
          .having((f) => f.message, 'message', contains('至少一個動作')),
      );
      verifyNever(() => mockService.createRecord(any()));
    });

    test('當標記未來訓練為已完成時應該返回 ValidationFailure', () async {
      // Arrange
      final futureWorkout = TestDataFactory.createWorkoutPlan(
        completed: true,
        scheduledDate: DateTime.now().add(Duration(days: 1)),
        exercises: [TestDataFactory.createExercise()],
      );

      // Act
      final result = await useCase(SaveWorkoutParams(workout: futureWorkout));

      // Assert
      expect(result, isA<Left<Failure, void>>());
      expect(
        (result as Left).value,
        isA<ValidationFailure>()
          .having((f) => f.message, 'message', contains('未來的訓練')),
      );
    });

    test('當動作沒有組數時應該返回 ValidationFailure', () async {
      // Arrange
      final workoutWithEmptySets = TestDataFactory.createWorkoutPlan(
        exercises: [
          Exercise(
            exerciseId: '1',
            exerciseName: '深蹲',
            sets: [],  // 空的組數
          ),
        ],
      );

      // Act
      final result = await useCase(
        SaveWorkoutParams(workout: workoutWithEmptySets),
      );

      // Assert
      expect(result, isA<Left<Failure, void>>());
      expect(
        (result as Left).value,
        isA<ValidationFailure>()
          .having((f) => f.message, 'message', contains('至少一組')),
      );
    });

    test('當 service 拋出異常時應該返回 UnknownFailure', () async {
      // Arrange
      when(() => mockService.createRecord(any()))
        .thenThrow(Exception('數據庫錯誤'));

      // Act
      final result = await useCase(SaveWorkoutParams(workout: tWorkout));

      // Assert
      expect(result, isA<Left<Failure, void>>());
      expect((result as Left).value, isA<UnknownFailure>());
    });
  });
}
```

**執行測試**：
```bash
flutter test test/domain/usecases/save_workout_usecase_test.dart
```

---

### Week 2 其他 Use Cases

#### Task 5.3：創建更多 Use Cases

**優先級順序**：

1. **GetWorkoutHistoryUseCase** ⭐⭐⭐
   - 獲取訓練歷史
   - 過濾邏輯（日期範圍、完成狀態）

2. **CalculateStatisticsUseCase** ⭐⭐⭐
   - 計算訓練統計（頻率、訓練量、PR）
   - 時間範圍處理

3. **DeleteWorkoutUseCase** ⭐⭐
   - 刪除訓練計劃
   - 權限檢查

4. **UpdateWorkoutUseCase** ⭐⭐
   - 更新訓練計劃
   - 驗證邏輯

**每個 Use Case 的開發流程**：
1. 寫測試（TDD 紅燈）
2. 實作 Use Case（TDD 綠燈）
3. 重構優化（TDD 重構）
4. 文檔註解

---

### Week 3：重構 Controllers

#### Task 6.1：更新 WorkoutController

**重構前**：
```dart
class WorkoutController extends ChangeNotifier {
  final IWorkoutService _workoutService;
  
  Future<void> createRecord(WorkoutPlan plan) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _workoutService.createRecord(plan);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '保存失敗：$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

**重構後**：
```dart
class WorkoutController extends ChangeNotifier {
  final SaveWorkoutUseCase _saveWorkoutUseCase;
  final GetWorkoutHistoryUseCase _getWorkoutHistoryUseCase;
  
  WorkoutController({
    required SaveWorkoutUseCase saveWorkoutUseCase,
    required GetWorkoutHistoryUseCase getWorkoutHistoryUseCase,
  })  : _saveWorkoutUseCase = saveWorkoutUseCase,
        _getWorkoutHistoryUseCase = getWorkoutHistoryUseCase;
  
  Future<void> createRecord(WorkoutPlan plan) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    final result = await _saveWorkoutUseCase(
      SaveWorkoutParams(workout: plan),
    );
    
    result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _isLoading = false;
        notifyListeners();
        // 重新載入列表
        refreshRecords();
      },
    );
  }
  
  String _mapFailureToMessage(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.message;
    } else if (failure is DatabaseFailure) {
      return '數據庫錯誤：${failure.message}';
    } else {
      return '發生未知錯誤';
    }
  }
}
```

#### Task 6.2：更新依賴注入配置

修改 `lib/utils/service_locator.dart`：

```dart
import 'package:get_it/get_it.dart';

// Use Cases
import '../domain/usecases/save_workout_usecase.dart';
import '../domain/usecases/get_workout_history_usecase.dart';

Future<void> setupServiceLocator() async {
  final sl = GetIt.instance;
  
  // ============ Use Cases ============
  sl.registerLazySingleton(() => SaveWorkoutUseCase(sl()));
  sl.registerLazySingleton(() => GetWorkoutHistoryUseCase(sl()));
  
  // ============ Controllers ============
  sl.registerFactory<IWorkoutController>(
    () => WorkoutController(
      saveWorkoutUseCase: sl(),
      getWorkoutHistoryUseCase: sl(),
    ),
  );
  
  // ... 其他註冊
}
```

---

### Week 2-3 驗收標準

**完成檢查清單**：

- [ ] ✅ 建立 Use Case 基礎架構（UseCase 介面、Failure 類別）
- [ ] ✅ 完成核心 Use Cases（至少 4 個）
  - [ ] SaveWorkoutUseCase + 測試
  - [ ] GetWorkoutHistoryUseCase + 測試
  - [ ] CalculateStatisticsUseCase + 測試
  - [ ] DeleteWorkoutUseCase + 測試
- [ ] ✅ 重構 Controllers 使用 Use Cases
- [ ] ✅ 更新依賴注入配置
- [ ] ✅ 所有測試通過

**關鍵指標**：
- ✅ Domain Layer 測試覆蓋率：> 70%
- ✅ Use Case 測試：100%（每個 Use Case 至少 5 個測試）
- ✅ 測試執行時間：< 10 秒

---

## 🎯 Phase 3: 全面測試覆蓋（Week 4-6）

### Week 4：Data Layer 測試

**目標**：完成所有 Model 和 Repository 的測試

#### 測試清單

- [ ] **Models（至少 8 個）**
  - [ ] WorkoutPlanModel
  - [ ] ExerciseModel
  - [ ] UserModel
  - [ ] StatisticsModel
  - [ ] BodyDataModel
  - [ ] ExerciseTypeModel
  - [ ] BodyPartModel
  - [ ] CustomExerciseModel

- [ ] **Repositories（至少 5 個）**
  - [ ] WorkoutServiceSupabase
  - [ ] StatisticsServiceSupabase
  - [ ] ExerciseServiceSupabase
  - [ ] UserServiceSupabase
  - [ ] BodyDataServiceSupabase

---

### Week 5：Presentation Layer 測試

**目標**：完成所有 Controller 和關鍵 Widget 的測試

#### 測試清單

- [ ] **Controllers（至少 10 個）**
  - [ ] WorkoutController
  - [ ] StatisticsController
  - [ ] ExerciseController
  - [ ] UserController
  - [ ] ProfileController
  - [ ] TrainingController
  - [ ] BodyDataController
  - [ ] NoteController
  - [ ] ExerciseTypeController
  - [ ] BodyPartController

- [ ] **Widgets（選擇性，至少 5 個關鍵 Widget）**
  - [ ] FrequencyCard
  - [ ] VolumeTrendChart
  - [ ] PersonalRecordsCard
  - [ ] EmptyStateWidget
  - [ ] TimeRangeSelector

---

### Week 6：測試優化與文檔

#### Task 10.1：測試優化

```bash
# 檢查慢速測試
flutter test --reporter=expanded | grep "ms$" | sort -k3 -n

# 優化策略：
# 1. 減少不必要的異步等待
# 2. 使用 fake_async 控制時間
# 3. 批量執行相似的測試
```

#### Task 10.2：建立測試文檔

創建 `docs/TESTING_GUIDE.md`：

```markdown
# StrengthWise - 測試指南

## 如何執行測試

### 執行所有測試
flutter test

### 執行特定測試
flutter test test/domain/usecases/save_workout_usecase_test.dart

### 執行測試並生成覆蓋率
./scripts/run_tests_with_coverage.sh

## 如何編寫測試

### 1. 使用 TestDataFactory
final workout = TestDataFactory.createWorkoutPlan();

### 2. 使用 Mock
final mockService = MockWorkoutService();
when(() => mockService.createRecord(any())).thenAnswer((_) async => {});

### 3. 驗證調用
verify(() => mockService.createRecord(any())).called(1);

## 測試覆蓋率目標
- Domain Layer: 80%+
- Data Layer: 70%+
- Presentation Layer: 60%+
```

---

### Week 4-6 驗收標準

**完成檢查清單**：

- [ ] ✅ 完成所有 Model 測試（至少 8 個）
- [ ] ✅ 完成所有 Repository 測試（至少 5 個）
- [ ] ✅ 完成所有 Controller 測試（至少 10 個）
- [ ] ✅ 完成關鍵 Widget 測試（至少 5 個）
- [ ] ✅ 測試執行時間優化（< 30 秒）
- [ ] ✅ 建立測試文檔
- [ ] ✅ CI 通過率 > 95%

**關鍵指標**：
- ✅ 整體測試覆蓋率：> 60%
- ✅ Domain Layer 覆蓋率：> 80%
- ✅ Data Layer 覆蓋率：> 70%
- ✅ Presentation Layer 覆蓋率：> 50%

---

## 🎯 Phase 4: 持續優化（Ongoing）

### 每日實踐

**開發新功能時**：
1. ✅ 先寫測試（TDD 紅燈）
2. ✅ 實作功能（TDD 綠燈）
3. ✅ 重構優化（TDD 重構）
4. ✅ 確保 CI 通過

**修復 Bug 時**：
1. ✅ 先寫失敗測試（重現 Bug）
2. ✅ 修復 Bug（測試通過）
3. ✅ 添加更多邊界測試

### 每週審查

**測試健康檢查**：
```bash
# 執行測試
flutter test

# 檢查覆蓋率
./scripts/run_tests_with_coverage.sh

# 檢查失敗測試
flutter test --reporter=json > test_results.json
cat test_results.json | jq '.[] | select(.result == "error")'
```

**問題清單**：
- [ ] 是否有失敗的測試？
- [ ] 覆蓋率是否下降？
- [ ] 測試執行時間是否變慢？
- [ ] 是否有新增未測試的代碼？

### 每月審查

**架構審查**：
- [ ] 是否有新的耦合點？
- [ ] 是否有繞過 Service 的直接調用？
- [ ] 是否有超過 300 行的檔案？
- [ ] 是否有重複的業務邏輯？

**重構候選**：
- [ ] 識別「氣味代碼」（Code Smells）
- [ ] 計劃下一個重構模塊
- [ ] 更新技術債務清單

---

## 📊 進度追蹤表

| Phase | 任務 | 狀態 | 預計時間 | 實際時間 | 備註 |
|-------|------|------|---------|---------|------|
| **Phase 1** | 測試基礎設施 | ⬜ 未開始 | 5 天 | - | - |
| 1.1 | 環境配置 | ⬜ | 1 天 | - | - |
| 1.2 | 第一批測試 | ⬜ | 2 天 | - | - |
| 1.3 | CI/CD 配置 | ⬜ | 2 天 | - | - |
| **Phase 2** | Use Case 提取 | ⬜ 未開始 | 10 天 | - | - |
| 2.1 | 基礎架構 | ⬜ | 2 天 | - | - |
| 2.2 | 核心 Use Cases | ⬜ | 5 天 | - | - |
| 2.3 | Controller 重構 | ⬜ | 3 天 | - | - |
| **Phase 3** | 全面測試覆蓋 | ⬜ 未開始 | 15 天 | - | - |
| 3.1 | Data Layer 測試 | ⬜ | 5 天 | - | - |
| 3.2 | Presentation 測試 | ⬜ | 5 天 | - | - |
| 3.3 | 測試優化 | ⬜ | 5 天 | - | - |
| **Phase 4** | 持續優化 | ⬜ 未開始 | 持續 | - | - |

**總預計時間**：30 天（約 6 週）

---

## 🔗 相關資源

### 文檔連結
- **[架構重構指南](ARCHITECTURE_REFACTORING_GUIDE.md)** - 完整的技術分析報告
- **[開發狀態](DEVELOPMENT_STATUS.md)** - 當前開發進度
- **[專案架構](PROJECT_OVERVIEW.md)** - 專案架構總覽

### 測試資源
- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mocktail Package](https://pub.dev/packages/mocktail)
- [BLoC Testing](https://pub.dev/packages/bloc_test)
- [Test-Driven Development Guide](https://resocoder.com/flutter-clean-architecture-tdd/)

---

**文檔維護**：請定期更新本文檔以反映實際的實施進度。

**最後更新**：2024年12月27日

