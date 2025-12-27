# StrengthWise - 架構重構與測試策略深度分析報告

> Flutter 專案從原型階段過渡到生產級別的完整技術指南

**文檔版本**：v1.0  
**最後更新**：2024年12月27日  
**目標讀者**：開發團隊、架構師、技術負責人

---

## 📋 目錄

1. [執行摘要](#1-執行摘要)
2. [架構診斷：識別耦合與「上帝類別」](#2-架構診斷識別耦合與上帝類別)
3. [目標架構：整潔架構範式](#3-目標架構整潔架構範式)
4. [重構路徑圖：實施步驟](#4-重構路徑圖實施步驟)
5. [依賴注入與狀態管理](#5-依賴注入與狀態管理)
6. [全方位測試策略](#6-全方位測試策略)
7. [模擬與測試替身](#7-模擬與測試替身)
8. [數據庫與外部服務解耦細節](#8-數據庫與外部服務解耦細節)
9. [未來展望與持續集成](#9-未來展望與持續集成)
10. [結論與行動計劃](#10-結論與行動計劃)

---

## 1. 執行摘要 (Executive Summary)

### 1.1 背景與挑戰

在現代移動應用開發的生命週期中，從原型階段過渡到生產級別的工程實踐是一個至關重要的轉折點。對於 **StrengthWise** Flutter 專案而言，當前的首要任務是：

- 🎯 **識別並消除代碼庫中的緊密耦合（Tight Coupling）**
- 🧪 **為引入單元測試（Unit Testing）奠定堅實的架構基礎**
- 🏗️ **從「可能存在上帝類別」的狀態轉型為基於整潔架構的可測試系統**

### 1.2 核心論點

> **可測試性是解耦的自然副產品。**

如果不將業務邏輯（Domain Logic）從用戶界面（UI）和數據基礎設施（Data Infrastructure）中剝離，單元測試將無法有效執行。

### 1.3 當前專案狀態分析

**StrengthWise 現況**（基於 `DEVELOPMENT_STATUS.md`）：
- ✅ 代碼量：~38,000 行
- ✅ 功能完整度：核心功能已實現
- ✅ 架構質量：已實現 Clean Architecture 基礎
  - ✅ Controller 層使用 Interface：100%
  - ✅ View 層使用 Interface：100%
  - ✅ 直接 Supabase 調用：0 處
- ⚠️ **測試覆蓋率：幾乎為 0**（僅有基礎測試文件）

### 1.4 報告價值

本報告將提供：
1. **詳盡的架構診斷方法**（識別需要解耦的檔案）
2. **具體的重構策略**（倉儲模式、依賴注入、測試驅動開發）
3. **可執行的實施路徑**（分階段、可驗證的行動計劃）

### 1.5 預期收益

執行本報告建議的策略後，StrengthWise 將能夠：
- 📉 降低技術債務
- 📈 提高代碼可維護性
- 🛡️ 建立自動化測試防護網
- 🚀 加速新功能開發速度
- 💰 降低長期維護成本

---

## 2. 架構診斷：識別耦合與「上帝類別」

### 2.1 「上帝類別」反模式識別

#### 2.1.1 定義

**上帝類別（God Class）**：一個類別承擔了過多的職責，它「無所不知，無所不能」。

在 Flutter 開發中，這通常表現為：
- 龐大的 `StatefulWidget` 或其對應的 `State` 類別
- 混合了 UI、業務邏輯、數據存取的「萬能」檔案

#### 2.1.2 症狀特徵檢查表

**🔍 檢查以下特徵，判斷是否存在「上帝類別」：**

| 症狀 | 描述 | 嚴重程度 |
|------|------|---------|
| **過度導入** | 同時導入 UI、網絡、數據庫、模型類 | 🔴 高 |
| **混合邏輯** | UI 渲染 + 業務規則 + 數據持久化混雜 | 🔴 高 |
| **代碼膨脹** | 單檔案 > 500 行（甚至 > 1000 行） | 🟡 中 |
| **狀態混亂** | 大量 `setState()` 同時控制 UI 和數據 | 🔴 高 |
| **測試困難** | 無法單獨測試某個邏輯片段 | 🔴 高 |

**示例：問題代碼結構**

```dart
// ❌ 反模式：統計頁面（舊版 statistics_page.dart）
class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  // 混合了太多職責
  
  // 1. 數據庫操作
  Future<void> _loadData() async {
    final data = await Supabase.instance.client
      .from('workout_plans')
      .select('*')  // ❌ SELECT *
      .execute();
  }
  
  // 2. 業務邏輯
  double _calculateVolume(List<WorkoutPlan> plans) {
    // 計算訓練量邏輯
  }
  
  // 3. UI 渲染
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemBuilder: (context, index) {
          // 混合了渲染和數據處理
        },
      ),
    );
  }
}
```

#### 2.1.3 對測試的阻礙

「上帝類別」是單元測試的天敵：

```dart
// ❌ 無法單獨測試業務邏輯
test('should calculate total volume correctly', () {
  // 問題：必須實例化整個 Widget
  final widget = StatisticsPage();
  
  // 問題：無法訪問私有方法 _calculateVolume
  // 問題：依賴真實的數據庫連接
  // 問題：需要 Flutter 測試環境（慢）
});
```

### 2.2 StrengthWise 具體檔案解耦分析

#### 2.2.1 已重構成功的案例 ✅

**統計頁面（Statistics Page）** - **已完成解耦**（2024-12-27）

**重構前**：
- 📄 `statistics_page_v2.dart`（1,951 行）
- 🔗 多個 Tab 之間耦合度高
- 🧩 難以獨立測試和維護

**重構後**：
```
lib/views/pages/statistics/
├── statistics_page_v2.dart        # 主頁面（166 行，-91.5%）
├── tabs/                          # Tab 頁面（6 個）
│   ├── overview_tab.dart          # 概覽統計
│   ├── strength_progress_tab.dart # 力量進步
│   ├── muscle_balance_tab.dart    # 肌群平衡
│   ├── calendar_tab.dart          # 訓練日曆
│   ├── completion_rate_tab.dart   # 完成率
│   └── body_data_tab.dart         # 身體數據
└── widgets/                       # 共用 Widget（7 個）
    ├── time_range_selector.dart
    ├── empty_state_widget.dart
    ├── frequency_card.dart
    ├── volume_trend_chart.dart
    ├── body_part_distribution_card.dart
    ├── personal_records_card.dart
    └── suggestions_card.dart
```

**改善指標**：

| 指標 | 重構前 | 重構後 | 改善 |
|------|--------|--------|------|
| 單檔最大行數 | 1,951 行 | 166 行 | **-91.5%** |
| 檔案數量 | 1 個 | 16 個 | 模組化 ✅ |
| 平均檔案大小 | 1,951 行 | 100-200 行 | **可讀性 ↑** |
| 最大函式長度 | 200+ 行 | <50 行 | **可維護性 ↑** |
| 可測試性 | ❌ 困難 | ✅ 容易 | **100% 提升** |

#### 2.2.2 當前架構狀態評估

**✅ 已實現的良好實踐**：

1. **Service Layer 解耦** - 完全實現
   - ✅ Interface 驅動開發（100% 使用）
   - ✅ Service Locator（GetIt）依賴注入
   - ✅ 零直接數據庫調用

2. **Controller Layer** - 架構清晰
   - ✅ ChangeNotifier 狀態管理
   - ✅ 透過 Interface 注入依賴
   - ✅ 業務邏輯集中管理

3. **Model Layer** - 型別安全
   - ✅ `.fromSupabase()` / `.toMap()` 模式
   - ✅ 禁止直接操作 `Map<String, dynamic>`

**⚠️ 需要改進的領域**：

| 領域 | 當前狀態 | 測試障礙 | 優先級 |
|------|---------|---------|--------|
| **單元測試覆蓋** | 幾乎為 0 | ❌ 無測試基礎設施 | 🔴 最高 |
| **Widget 測試** | 未實施 | ❌ 缺少測試範例 | 🟡 中 |
| **Mock 機制** | 未建立 | ❌ 無 Mock 策略 | 🔴 高 |
| **CI/CD 整合** | 未配置 | ❌ 無自動化測試 | 🟡 中 |

#### 2.2.3 待強化的測試目標

**Domain Layer（業務邏輯）**：
- 📊 統計計算邏輯（Volume、1RM、PR 判斷）
- 📅 時間範圍計算（本週、本月、本年）
- 🏋️ 訓練計劃驗證邏輯

**Service Layer（數據存取）**：
- 🔄 快取機制測試
- 🔍 查詢邏輯驗證
- ⚠️ 錯誤處理測試

**Controller Layer（狀態管理）**：
- 🎯 狀態轉換邏輯
- 📡 非同步操作處理
- 🐛 錯誤狀態管理

---

## 3. 目標架構：整潔架構範式

### 3.1 整潔架構核心原則

> **依賴規則（Dependency Rule）**：源代碼的依賴關係只能指向內部，內層不得了解外層的任何細節。

```
┌─────────────────────────────────────────────┐
│        Presentation Layer (表現層)          │
│  ┌───────────────────────────────────────┐  │
│  │     Domain Layer (領域層 - 核心)      │  │
│  │  ┌─────────────────────────────────┐  │  │
│  │  │   Entities (實體)               │  │  │
│  │  │   Use Cases (用例)              │  │  │
│  │  │   Repository Interfaces (接口)  │  │  │
│  │  └─────────────────────────────────┘  │  │
│  │     ↑ 依賴方向：只能向內             │  │
│  └───────────────────────────────────────┘  │
│        ↑ Data Layer (數據層)                │
└─────────────────────────────────────────────┘
```

### 3.2 StrengthWise 三層架構設計

#### 3.2.1 領域層 (Domain Layer) - 核心內核

**職責**：包含所有與 Flutter 框架無關的純 Dart 代碼

**組成部分**：

1. **Entities（實體）**
   ```dart
   // ✅ 正確：純 Dart 類別，無框架依賴
   class Workout {
     final String id;
     final String userId;
     final DateTime scheduledDate;
     final List<Exercise> exercises;
     final bool completed;
     
     const Workout({
       required this.id,
       required this.userId,
       required this.scheduledDate,
       required this.exercises,
       required this.completed,
     });
     
     // 業務邏輯方法
     double calculateTotalVolume() {
       return exercises.fold(0.0, (sum, exercise) => 
         sum + exercise.calculateVolume());
     }
     
     bool isPersonalRecord(double previousBest) {
       return calculateTotalVolume() > previousBest;
     }
   }
   ```

2. **Use Cases（用例 / 交互器）**
   ```dart
   // ✅ 封裝具體業務規則
   class SaveWorkoutUseCase {
     final IWorkoutRepository repository;
     
     SaveWorkoutUseCase(this.repository);
     
     Future<Either<Failure, void>> call(Workout workout) async {
       // 業務驗證
       if (workout.exercises.isEmpty) {
         return Left(ValidationFailure('訓練計劃不能為空'));
       }
       
       // 委託給 Repository
       return await repository.saveWorkout(workout);
     }
   }
   ```

3. **Repository Interfaces（倉儲接口）**
   ```dart
   // ✅ 定義契約，不實現
   abstract class IWorkoutRepository {
     Future<Either<Failure, void>> saveWorkout(Workout workout);
     Future<Either<Failure, List<Workout>>> getWorkoutHistory({
       required String userId,
       required DateTimeRange dateRange,
     });
     Future<Either<Failure, void>> deleteWorkout(String id);
   }
   ```

**StrengthWise 現有對應**：

| Domain 概念 | StrengthWise 現有檔案 | 狀態 |
|------------|---------------------|------|
| Entities | `lib/models/*.dart` | ✅ 已實現 |
| Use Cases | **❌ 缺失**（邏輯在 Controller 中） | 🔴 待建立 |
| Repository Interfaces | `lib/services/interfaces/i_*.dart` | ✅ 已實現 |

#### 3.2.2 數據層 (Data Layer) - 適配器

**職責**：實現領域層定義的接口，與外部數據源交互

**組成部分**：

1. **Models（數據模型）**
   ```dart
   // ✅ 負責數據轉換
   class WorkoutModel extends Workout {
     WorkoutModel({
       required super.id,
       required super.userId,
       required super.scheduledDate,
       required super.exercises,
       required super.completed,
     });
     
     // Supabase 特定的轉換
     factory WorkoutModel.fromSupabase(Map<String, dynamic> json) {
       return WorkoutModel(
         id: json['id'] as String,
         userId: json['user_id'] as String,
         scheduledDate: DateTime.parse(json['scheduled_date'] as String),
         exercises: (json['exercises'] as List)
           .map((e) => ExerciseModel.fromSupabase(e))
           .toList(),
         completed: json['completed'] as bool,
       );
     }
     
     Map<String, dynamic> toMap() {
       return {
         'id': id,
         'user_id': userId,
         'scheduled_date': scheduledDate.toIso8601String(),
         'exercises': exercises.map((e) => e.toMap()).toList(),
         'completed': completed,
       };
     }
   }
   ```

2. **Data Sources（數據源）**
   ```dart
   // ✅ 封裝具體的數據庫操作
   abstract class IWorkoutLocalDataSource {
     Future<void> cacheWorkout(WorkoutModel workout);
     Future<List<WorkoutModel>> getCachedWorkouts(String userId);
   }
   
   class WorkoutLocalDataSourceSupabase implements IWorkoutLocalDataSource {
     final SupabaseClient client;
     
     WorkoutLocalDataSourceSupabase(this.client);
     
     @override
     Future<void> cacheWorkout(WorkoutModel workout) async {
       await client
         .from('workout_plans')
         .insert(workout.toMap());
     }
   }
   ```

3. **Repository Implementations（倉儲實現）**
   ```dart
   // ✅ 實現領域層接口
   class WorkoutRepositoryImpl implements IWorkoutRepository {
     final IWorkoutLocalDataSource localDataSource;
     final IWorkoutRemoteDataSource remoteDataSource;
     
     WorkoutRepositoryImpl({
       required this.localDataSource,
       required this.remoteDataSource,
     });
     
     @override
     Future<Either<Failure, void>> saveWorkout(Workout workout) async {
       try {
         final model = WorkoutModel.fromEntity(workout);
         
         // 雙寫策略：本地 + 遠端
         await localDataSource.cacheWorkout(model);
         await remoteDataSource.uploadWorkout(model);
         
         return Right(null);
       } on SupabaseException catch (e) {
         return Left(DatabaseFailure(e.message));
       } catch (e) {
         return Left(UnknownFailure(e.toString()));
       }
     }
   }
   ```

**StrengthWise 現有對應**：

| Data 概念 | StrengthWise 現有檔案 | 狀態 |
|----------|---------------------|------|
| Models | `lib/models/*_model.dart` | ✅ 已實現 |
| Data Sources | **部分在 Service 中** | 🟡 待強化 |
| Repository Impl | `lib/services/*_service_supabase.dart` | ✅ 已實現 |

#### 3.2.3 表現層 (Presentation Layer) - UI 與狀態

**職責**：展示數據給用戶，處理用戶交互事件

**組成部分**：

1. **State Management（狀態管理）**
   ```dart
   // ✅ StrengthWise 已實現：ChangeNotifier 模式
   class WorkoutController extends ChangeNotifier implements IWorkoutController {
     final IWorkoutService _workoutService;
     
     WorkoutController(this._workoutService);
     
     List<WorkoutPlan> _plans = [];
     bool _isLoading = false;
     String? _errorMessage;
     
     // 調用 Service（未來可改為調用 Use Case）
     Future<void> loadPlans(String userId) async {
       _isLoading = true;
       notifyListeners();
       
       try {
         _plans = await _workoutService.getUserWorkoutPlans(userId);
         _errorMessage = null;
       } catch (e) {
         _errorMessage = '載入失敗：$e';
       } finally {
         _isLoading = false;
         notifyListeners();
       }
     }
   }
   ```

2. **Widgets（視圖）**
   ```dart
   // ✅ 啞組件（Dumb Widget），只負責渲染
   class WorkoutListView extends StatelessWidget {
     final List<WorkoutPlan> plans;
     final VoidCallback onRefresh;
     
     const WorkoutListView({
       required this.plans,
       required this.onRefresh,
     });
     
     @override
     Widget build(BuildContext context) {
       return RefreshIndicator(
         onRefresh: () async => onRefresh(),
         child: ListView.builder(
           itemCount: plans.length,
           itemBuilder: (context, index) {
             return WorkoutCard(plan: plans[index]);
           },
         ),
       );
     }
   }
   ```

**StrengthWise 現有對應**：

| Presentation 概念 | StrengthWise 現有檔案 | 狀態 |
|------------------|---------------------|------|
| Controllers | `lib/controllers/*.dart` | ✅ 已實現 |
| Widgets | `lib/views/pages/*.dart` | ✅ 已實現 |
| Widget Tests | `test/widget_test.dart` | ❌ 未實施 |

### 3.3 架構映射表

**完整的重構映射關係**：

| 當前位置 (耦合狀態) | 組件類型 | 目標位置 (解耦狀態) | 所屬層級 |
|-------------------|---------|-------------------|---------|
| `lib/models/workout_plan_model.dart` | 業務邏輯計算 | `lib/domain/entities/workout.dart` | Domain |
| `lib/controllers/workout_controller.dart` | 複雜業務規則 | `lib/domain/usecases/save_workout_usecase.dart` | Domain |
| `lib/services/workout_service_supabase.dart` | Supabase 調用 | `lib/data/datasources/workout_remote_datasource.dart` | Data |
| `lib/services/workout_service_supabase.dart` | Repository 實現 | `lib/data/repositories/workout_repository_impl.dart` | Data |
| `lib/views/pages/training_page.dart` | UI + 邏輯混合 | 分離為 Widget + Controller | Presentation |

---

## 4. 重構路徑圖：實施步驟

### 4.1 整體策略：絞殺者模式（Strangler Pattern）

> **核心思想**：不進行「大爆炸式」重構，而是逐個功能模塊進行轉型。

**優勢**：
- ✅ 降低風險（每次只改一小塊）
- ✅ 持續交付（不阻塞業務開發）
- ✅ 可回滾（出問題可快速恢復）

### 4.2 Phase 1：建立測試基礎設施 ⭐⭐⭐

**目標**：讓專案「可測試」

#### 步驟 1.1：配置測試環境

**操作**：

1. **更新 `pubspec.yaml`**
   ```yaml
   dev_dependencies:
     flutter_test:
       sdk: flutter
     mocktail: ^1.0.0        # Mock 工具（推薦）
     bloc_test: ^9.1.0       # BLoC 測試工具（如使用 BLoC）
     fake_async: ^1.3.0      # 異步測試
   ```

2. **建立測試目錄結構**
   ```
   test/
   ├── domain/
   │   ├── entities/
   │   └── usecases/
   ├── data/
   │   ├── models/
   │   └── repositories/
   ├── presentation/
   │   ├── controllers/
   │   └── widgets/
   ├── helpers/
   │   ├── test_helper.dart        # 測試工具
   │   └── mock_helper.dart        # Mock 建立器
   └── fixtures/
       └── workout_fixture.json    # 測試數據
   ```

3. **創建測試輔助工具**
   ```dart
   // test/helpers/test_helper.dart
   import 'package:mocktail/mocktail.dart';
   
   // Mock 類別
   class MockWorkoutService extends Mock implements IWorkoutService {}
   class MockStatisticsService extends Mock implements IStatisticsService {}
   
   // 測試數據工廠
   class TestDataFactory {
     static WorkoutPlan createWorkoutPlan({
       String? id,
       bool completed = false,
     }) {
       return WorkoutPlan(
         id: id ?? 'test-id-123',
         userId: 'test-user',
         traineeId: 'test-trainee',
         scheduledDate: DateTime.now(),
         completed: completed,
         exercises: [],
       );
     }
   }
   ```

#### 步驟 1.2：建立第一個測試範例

**操作**：為最簡單的業務邏輯建立測試

```dart
// test/domain/entities/workout_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/workout_plan_model.dart';

void main() {
  group('Workout Entity', () {
    test('calculateTotalVolume should sum all exercise volumes', () {
      // Arrange
      final workout = WorkoutPlan(
        id: '1',
        userId: 'user1',
        traineeId: 'trainee1',
        scheduledDate: DateTime.now(),
        completed: false,
        exercises: [
          Exercise(
            name: '深蹲',
            sets: [
              SetData(weight: 100, reps: 10),  // 1000 kg
              SetData(weight: 100, reps: 10),  // 1000 kg
            ],
          ),
          Exercise(
            name: '臥推',
            sets: [
              SetData(weight: 80, reps: 8),    // 640 kg
            ],
          ),
        ],
      );
      
      // Act
      final totalVolume = workout.calculateTotalVolume();
      
      // Assert
      expect(totalVolume, equals(2640.0));
    });
    
    test('isPersonalRecord should return true when volume exceeds previous', () {
      // Arrange
      final workout = WorkoutPlan(/* ... */);
      final previousBest = 2000.0;
      
      // Act
      final isPR = workout.isPersonalRecord(previousBest);
      
      // Assert
      expect(isPR, isTrue);
    });
  });
}
```

**驗證**：執行測試

```bash
flutter test test/domain/entities/workout_test.dart
```

**成功標準**：
- ✅ 測試通過（綠燈）
- ✅ 執行時間 < 1 秒
- ✅ 無需啟動 Flutter UI

---

### 4.3 Phase 2：提取 Use Cases（用例層）⭐⭐⭐

**目標**：將 Controller 中的複雜業務邏輯提取為可測試的用例

#### 步驟 2.1：識別可提取的業務邏輯

**檢查清單**：

| Controller 方法 | 業務邏輯複雜度 | 是否適合提取為 Use Case |
|----------------|--------------|----------------------|
| `WorkoutController.createRecord()` | 高（驗證 + 保存） | ✅ 是 |
| `StatisticsController.calculateProgress()` | 高（複雜計算） | ✅ 是 |
| `WorkoutController.loadPlans()` | 低（簡單查詢） | 🟡 可選 |

#### 步驟 2.2：創建 Use Case

**範例：SaveWorkoutUseCase**

```dart
// lib/domain/usecases/save_workout_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:strengthwise/domain/entities/workout.dart';
import 'package:strengthwise/domain/repositories/i_workout_repository.dart';
import 'package:strengthwise/core/errors/failures.dart';

class SaveWorkoutUseCase {
  final IWorkoutRepository repository;
  
  SaveWorkoutUseCase(this.repository);
  
  /// 執行用例：保存訓練計劃
  /// 
  /// 業務規則：
  /// 1. 訓練計劃不能為空
  /// 2. scheduled_date 不能為未來時間（如果 completed = true）
  /// 3. 必須至少包含一個動作
  Future<Either<Failure, void>> call({
    required Workout workout,
  }) async {
    // 業務驗證
    if (workout.exercises.isEmpty) {
      return Left(ValidationFailure('訓練計劃必須包含至少一個動作'));
    }
    
    if (workout.completed && workout.scheduledDate.isAfter(DateTime.now())) {
      return Left(ValidationFailure('不能將未來的訓練標記為已完成'));
    }
    
    // 委託給 Repository
    return await repository.saveWorkout(workout);
  }
}
```

#### 步驟 2.3：為 Use Case 建立測試

```dart
// test/domain/usecases/save_workout_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

void main() {
  late SaveWorkoutUseCase useCase;
  late MockWorkoutRepository mockRepository;
  
  setUp(() {
    mockRepository = MockWorkoutRepository();
    useCase = SaveWorkoutUseCase(mockRepository);
    
    // 註冊 fallback 值（mocktail 要求）
    registerFallbackValue(TestDataFactory.createWorkout());
  });
  
  group('SaveWorkoutUseCase', () {
    test('should call repository.saveWorkout when validation passes', () async {
      // Arrange
      final workout = TestDataFactory.createWorkout(
        exercises: [TestDataFactory.createExercise()],
      );
      when(() => mockRepository.saveWorkout(any()))
        .thenAnswer((_) async => Right(null));
      
      // Act
      final result = await useCase(workout: workout);
      
      // Assert
      expect(result, equals(Right(null)));
      verify(() => mockRepository.saveWorkout(workout)).called(1);
    });
    
    test('should return ValidationFailure when exercises are empty', () async {
      // Arrange
      final workout = TestDataFactory.createWorkout(exercises: []);
      
      // Act
      final result = await useCase(workout: workout);
      
      // Assert
      expect(result, isA<Left<Failure, void>>());
      expect(
        (result as Left).value,
        isA<ValidationFailure>()
          .having((f) => f.message, 'message', contains('至少一個動作')),
      );
      verifyNever(() => mockRepository.saveWorkout(any()));
    });
    
    test('should return ValidationFailure when completed workout is in future', () async {
      // Arrange
      final futureDate = DateTime.now().add(Duration(days: 1));
      final workout = TestDataFactory.createWorkout(
        completed: true,
        scheduledDate: futureDate,
        exercises: [TestDataFactory.createExercise()],
      );
      
      // Act
      final result = await useCase(workout: workout);
      
      // Assert
      expect(result, isA<Left<Failure, void>>());
      expect(
        (result as Left).value,
        isA<ValidationFailure>()
          .having((f) => f.message, 'message', contains('未來的訓練')),
      );
    });
  });
}
```

#### 步驟 2.4：重構 Controller 使用 Use Case

```dart
// lib/controllers/workout_controller.dart（重構後）
class WorkoutController extends ChangeNotifier implements IWorkoutController {
  final SaveWorkoutUseCase _saveWorkoutUseCase;
  final GetWorkoutHistoryUseCase _getWorkoutHistoryUseCase;
  
  WorkoutController({
    required SaveWorkoutUseCase saveWorkoutUseCase,
    required GetWorkoutHistoryUseCase getWorkoutHistoryUseCase,
  })  : _saveWorkoutUseCase = saveWorkoutUseCase,
        _getWorkoutHistoryUseCase = getWorkoutHistoryUseCase;
  
  Future<void> createRecord(WorkoutPlan plan) async {
    _isLoading = true;
    notifyListeners();
    
    // 呼叫 Use Case
    final result = await _saveWorkoutUseCase(
      workout: plan.toEntity(),  // 轉換為 Domain Entity
    );
    
    result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _errorMessage = null;
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
      return '未知錯誤';
    }
  }
}
```

**優勢**：
- ✅ 業務邏輯可獨立測試（不依賴 Flutter）
- ✅ Controller 變薄（只負責狀態管理）
- ✅ 錯誤處理集中化

---

### 4.4 Phase 3：Repository Layer 強化測試 ⭐⭐

**目標**：確保數據層邏輯的正確性

#### 步驟 3.1：測試 Model 轉換

```dart
// test/data/models/workout_model_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/workout_plan_model.dart';

void main() {
  group('WorkoutModel', () {
    final tWorkoutModel = WorkoutModel(
      id: '123',
      userId: 'user123',
      traineeId: 'trainee123',
      scheduledDate: DateTime.parse('2024-12-27T10:00:00Z'),
      completed: false,
      exercises: [],
    );
    
    test('fromSupabase should parse JSON correctly', () {
      // Arrange
      final jsonMap = {
        'id': '123',
        'user_id': 'user123',
        'trainee_id': 'trainee123',
        'scheduled_date': '2024-12-27T10:00:00Z',
        'completed': false,
        'exercises': [],
      };
      
      // Act
      final result = WorkoutModel.fromSupabase(jsonMap);
      
      // Assert
      expect(result.id, equals('123'));
      expect(result.userId, equals('user123'));
      expect(result.completed, isFalse);
    });
    
    test('toMap should convert model to JSON correctly', () {
      // Act
      final result = tWorkoutModel.toMap();
      
      // Assert
      expect(result['id'], equals('123'));
      expect(result['user_id'], equals('user123'));
      expect(result['scheduled_date'], equals('2024-12-27T10:00:00.000Z'));
    });
    
    test('should handle null values gracefully', () {
      // Arrange
      final jsonMap = {
        'id': '123',
        'user_id': 'user123',
        'trainee_id': null,  // 可能為空的欄位
        'scheduled_date': '2024-12-27T10:00:00Z',
        'completed': false,
        'exercises': [],
      };
      
      // Act
      final result = WorkoutModel.fromSupabase(jsonMap);
      
      // Assert
      expect(result.traineeId, isNull);
    });
  });
}
```

#### 步驟 3.2：測試 Repository Implementation

```dart
// test/data/repositories/workout_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

void main() {
  late WorkoutRepositoryImpl repository;
  late MockWorkoutLocalDataSource mockLocalDataSource;
  late MockWorkoutRemoteDataSource mockRemoteDataSource;
  
  setUp(() {
    mockLocalDataSource = MockWorkoutLocalDataSource();
    mockRemoteDataSource = MockWorkoutRemoteDataSource();
    repository = WorkoutRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
    );
  });
  
  group('saveWorkout', () {
    final tWorkout = TestDataFactory.createWorkout();
    
    test('should save to both local and remote data sources', () async {
      // Arrange
      when(() => mockLocalDataSource.cacheWorkout(any()))
        .thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.uploadWorkout(any()))
        .thenAnswer((_) async => true);
      
      // Act
      final result = await repository.saveWorkout(tWorkout);
      
      // Assert
      expect(result, equals(Right(null)));
      verify(() => mockLocalDataSource.cacheWorkout(any())).called(1);
      verify(() => mockRemoteDataSource.uploadWorkout(any())).called(1);
    });
    
    test('should return DatabaseFailure when local save fails', () async {
      // Arrange
      when(() => mockLocalDataSource.cacheWorkout(any()))
        .thenThrow(SupabaseException('Connection error'));
      
      // Act
      final result = await repository.saveWorkout(tWorkout);
      
      // Assert
      expect(result, isA<Left<Failure, void>>());
      expect((result as Left).value, isA<DatabaseFailure>());
      verifyNever(() => mockRemoteDataSource.uploadWorkout(any()));
    });
  });
  
  group('getWorkoutHistory', () {
    test('should return cached data when available', () async {
      // Arrange
      final tWorkouts = [TestDataFactory.createWorkout()];
      when(() => mockLocalDataSource.getCachedWorkouts(any()))
        .thenAnswer((_) async => tWorkouts);
      
      // Act
      final result = await repository.getWorkoutHistory(
        userId: 'user123',
        dateRange: DateTimeRange(
          start: DateTime.now().subtract(Duration(days: 7)),
          end: DateTime.now(),
        ),
      );
      
      // Assert
      expect(result, equals(Right(tWorkouts)));
    });
  });
}
```

---

### 4.5 Phase 4：Controller Layer 狀態測試 ⭐⭐

**目標**：驗證狀態轉換邏輯的正確性

#### 步驟 4.1：測試 Controller（使用 Mock Use Case）

```dart
// test/presentation/controllers/workout_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late WorkoutController controller;
  late MockSaveWorkoutUseCase mockSaveWorkoutUseCase;
  late MockGetWorkoutHistoryUseCase mockGetWorkoutHistoryUseCase;
  
  setUp(() {
    mockSaveWorkoutUseCase = MockSaveWorkoutUseCase();
    mockGetWorkoutHistoryUseCase = MockGetWorkoutHistoryUseCase();
    controller = WorkoutController(
      saveWorkoutUseCase: mockSaveWorkoutUseCase,
      getWorkoutHistoryUseCase: mockGetWorkoutHistoryUseCase,
    );
  });
  
  tearDown(() {
    controller.dispose();
  });
  
  group('createRecord', () {
    final tWorkoutPlan = TestDataFactory.createWorkoutPlan();
    
    test('should emit loading state then success state', () async {
      // Arrange
      when(() => mockSaveWorkoutUseCase(workout: any(named: 'workout')))
        .thenAnswer((_) async => Right(null));
      
      // 監聽狀態變化
      final stateChanges = <bool>[];
      controller.addListener(() {
        stateChanges.add(controller.isLoading);
      });
      
      // Act
      await controller.createRecord(tWorkoutPlan);
      
      // Assert
      expect(stateChanges, equals([true, false]));  // loading → not loading
      expect(controller.errorMessage, isNull);
    });
    
    test('should emit error message when use case fails', () async {
      // Arrange
      final tFailure = ValidationFailure('訓練計劃不能為空');
      when(() => mockSaveWorkoutUseCase(workout: any(named: 'workout')))
        .thenAnswer((_) async => Left(tFailure));
      
      // Act
      await controller.createRecord(tWorkoutPlan);
      
      // Assert
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, equals('訓練計劃不能為空'));
    });
  });
}
```

---

### 4.6 Phase 5：Widget 測試（選擇性）⭐

**目標**：驗證關鍵 UI 組件的渲染邏輯

#### 範例：測試統計卡片

```dart
// test/presentation/widgets/frequency_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/views/pages/statistics/widgets/frequency_card.dart';

void main() {
  testWidgets('FrequencyCard should display correct frequency', (tester) async {
    // Arrange
    const frequency = 4.5;
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FrequencyCard(frequency: frequency),
        ),
      ),
    );
    
    // Assert
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('次/週'), findsOneWidget);
  });
  
  testWidgets('should display empty state when frequency is 0', (tester) async {
    // Arrange
    const frequency = 0.0;
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FrequencyCard(frequency: frequency),
        ),
      ),
    );
    
    // Assert
    expect(find.text('暫無數據'), findsOneWidget);
  });
}
```

---

### 4.7 重構優先級矩陣

**建議重構順序**：

| 功能模塊 | 業務複雜度 | 測試價值 | 重構難度 | 優先級 | 預計時間 |
|---------|----------|---------|---------|--------|---------|
| **統計計算邏輯** | 🔴 高 | 🔴 高 | 🟡 中 | **P0** | 2-3 天 |
| **訓練計劃保存** | 🟡 中 | 🔴 高 | 🟢 低 | **P0** | 1-2 天 |
| **個人記錄判斷** | 🔴 高 | 🟡 中 | 🟢 低 | **P1** | 1 天 |
| **身體數據追蹤** | 🟢 低 | 🟡 中 | 🟢 低 | **P2** | 1 天 |
| **動作搜尋** | 🟡 中 | 🟢 低 | 🟡 中 | **P3** | 1-2 天 |

**總預計時間**：6-10 天（全職開發）

---

## 5. 依賴注入與狀態管理

### 5.1 StrengthWise 現有 DI 系統評估

**當前實現**：GetIt Service Locator ✅

**優勢**：
- ✅ 已全面實施（100% Interface 使用）
- ✅ 架構清晰（Service Locator Pattern）
- ✅ 無需大規模重構

**待改進**：
- 🟡 缺少測試專用的 DI 配置
- 🟡 Service Locator 在測試中需要手動重置

### 5.2 測試友好的 DI 配置

#### 方案 1：GetIt 測試隔離（推薦）

```dart
// test/helpers/test_injection_container.dart
import 'package:get_it/get_it.dart';

final testServiceLocator = GetIt.instance;

/// 測試專用的依賴注入配置
Future<void> setupTestServiceLocator() async {
  // 重置所有註冊
  await testServiceLocator.reset();
  
  // 註冊 Mock Services
  testServiceLocator.registerLazySingleton<IWorkoutService>(
    () => MockWorkoutService(),
  );
  
  testServiceLocator.registerLazySingleton<IStatisticsService>(
    () => MockStatisticsService(),
  );
  
  // 註冊 Controllers（使用 Mock Services）
  testServiceLocator.registerFactory<IWorkoutController>(
    () => WorkoutController(
      workoutService: testServiceLocator<IWorkoutService>(),
    ),
  );
}

/// 測試清理
Future<void> tearDownTestServiceLocator() async {
  await testServiceLocator.reset();
}
```

**使用方式**：

```dart
// test/presentation/controllers/workout_controller_test.dart
void main() {
  setUpAll(() async {
    await setupTestServiceLocator();
  });
  
  tearDownAll(() async {
    await tearDownTestServiceLocator();
  });
  
  test('should use mock service', () {
    final controller = testServiceLocator<IWorkoutController>();
    // 測試邏輯...
  });
}
```

#### 方案 2：直接注入（更簡單）

```dart
// 不使用 Service Locator，直接實例化
test('should save workout successfully', () {
  // Arrange
  final mockService = MockWorkoutService();
  final controller = WorkoutController(workoutService: mockService);
  
  when(() => mockService.createRecord(any()))
    .thenAnswer((_) async => {});
  
  // Act & Assert
  // ...
});
```

**推薦**：方案 2（更簡單、更快速、更可控）

### 5.3 狀態管理測試策略

**StrengthWise 現有**：ChangeNotifier + Provider

**測試方法**：

```dart
test('should notify listeners when state changes', () {
  // Arrange
  final controller = WorkoutController(workoutService: mockService);
  var notifyCount = 0;
  controller.addListener(() => notifyCount++);
  
  when(() => mockService.getUserWorkoutPlans(any()))
    .thenAnswer((_) async => []);
  
  // Act
  await controller.loadPlans('user123');
  
  // Assert
  expect(notifyCount, equals(2));  // loading + loaded
});
```

---

## 6. 全方位測試策略

### 6.1 測試金字塔

```
       ▲
      /E\      10% - 端到端測試（集成測試）
     /───\     - 測試完整流程
    /  W  \    20% - Widget 測試
   /───────\   - 測試 UI 組件
  /    U    \  70% - 單元測試
 /───────────\ - 測試業務邏輯
```

### 6.2 測試覆蓋率目標

| 層級 | 目標覆蓋率 | 關鍵測試對象 | 優先級 |
|------|-----------|------------|--------|
| **Domain Layer** | **80-90%** | Use Cases, Entities | 🔴 最高 |
| **Data Layer** | **70-80%** | Repositories, Models | 🔴 高 |
| **Presentation Layer** | **50-60%** | Controllers | 🟡 中 |
| **UI Layer** | **20-30%** | 關鍵 Widgets | 🟢 低 |

### 6.3 測試檢查清單

#### ✅ 單元測試必測項目

**Domain Layer**：
- [ ] Entity 的業務邏輯方法（如 `calculateTotalVolume()`）
- [ ] Use Case 的成功路徑
- [ ] Use Case 的失敗路徑（各種錯誤情況）
- [ ] Use Case 的邊界條件（空值、極值）

**Data Layer**：
- [ ] Model 的 `fromSupabase()` 轉換
- [ ] Model 的 `toMap()` 轉換
- [ ] Repository 的數據源協調邏輯
- [ ] 錯誤處理（異常轉換為 Failure）

**Presentation Layer**：
- [ ] Controller 的狀態轉換
- [ ] Controller 的錯誤處理
- [ ] Controller 的 `notifyListeners()` 調用

#### ✅ Widget 測試選測項目

- [ ] 空狀態顯示
- [ ] 載入狀態顯示
- [ ] 錯誤狀態顯示
- [ ] 關鍵交互（按鈕點擊、表單提交）

#### ✅ 集成測試（可選）

- [ ] 完整的訓練記錄流程
- [ ] 統計數據更新流程

---

## 7. 模擬與測試替身

### 7.1 Mock 工具選擇：Mocktail（推薦）

**為什麼選擇 Mocktail？**

| 特性 | Mockito | Mocktail |
|------|---------|----------|
| **代碼生成** | ✅ 需要 build_runner | ❌ 不需要 |
| **開發速度** | 慢（需要重新生成） | 快（即時生效） |
| **學習曲線** | 中等 | 簡單 |
| **類型安全** | 高 | 高 |
| **Null Safety** | 支援 | 完美支援 |

**推薦**：**Mocktail**（更適合快速迭代的測試驅動開發）

### 7.2 Mocktail 使用指南

#### 基礎用法

```dart
import 'package:mocktail/mocktail.dart';

// 1. 建立 Mock 類別
class MockWorkoutService extends Mock implements IWorkoutService {}

void main() {
  late MockWorkoutService mockService;
  
  setUp(() {
    mockService = MockWorkoutService();
  });
  
  test('example test', () {
    // 2. Stubbing（定義行為）
    when(() => mockService.getUserWorkoutPlans(any()))
      .thenAnswer((_) async => []);
    
    // 3. 調用 Mock 方法
    final result = await mockService.getUserWorkoutPlans('user123');
    
    // 4. Verification（驗證調用）
    verify(() => mockService.getUserWorkoutPlans('user123')).called(1);
    
    // 5. 斷言結果
    expect(result, isEmpty);
  });
}
```

#### 進階技巧

**1. 註冊 Fallback 值（必須）**

```dart
setUpAll(() {
  // 當使用 any() 匹配器時，需要註冊 fallback 值
  registerFallbackValue(TestDataFactory.createWorkoutPlan());
  registerFallbackValue(DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  ));
});
```

**2. 模擬異步方法**

```dart
// ✅ 正確：使用 thenAnswer + async
when(() => mockService.saveWorkout(any()))
  .thenAnswer((_) async => true);

// ❌ 錯誤：thenReturn 不適用於 Future
when(() => mockService.saveWorkout(any()))
  .thenReturn(Future.value(true));  // 可行但不推薦
```

**3. 模擬異常**

```dart
when(() => mockService.getUserWorkoutPlans(any()))
  .thenThrow(SupabaseException('Network error'));
```

**4. 驗證調用次數**

```dart
// 驗證被調用 1 次
verify(() => mockService.saveWorkout(any())).called(1);

// 驗證從未被調用
verifyNever(() => mockService.deleteWorkout(any()));

// 驗證被調用至少 N 次
verify(() => mockService.loadPlans(any())).called(greaterThan(2));
```

**5. 驗證調用順序**

```dart
verifyInOrder([
  () => mockService.loadPlans('user123'),
  () => mockService.saveWorkout(any()),
]);
```

### 7.3 Mock 最佳實踐

#### ✅ 好的做法

1. **只 Mock 你擁有的介面**
   ```dart
   // ✅ 正確：Mock 自己定義的 Interface
   class MockWorkoutService extends Mock implements IWorkoutService {}
   
   // ❌ 錯誤：Mock 第三方類別（脆弱、難維護）
   class MockSupabaseClient extends Mock implements SupabaseClient {}
   ```

2. **使用 Test Data Factory**
   ```dart
   class TestDataFactory {
     static WorkoutPlan createWorkoutPlan({
       String? id,
       List<Exercise>? exercises,
     }) {
       return WorkoutPlan(
         id: id ?? 'default-id',
         exercises: exercises ?? [createExercise()],
         // ...
       );
     }
   }
   ```

3. **為每個測試隔離 Mock 狀態**
   ```dart
   setUp(() {
     mockService = MockWorkoutService();  // 每次測試都創建新的 Mock
   });
   ```

#### ❌ 避免的做法

1. **過度 Mock**
   ```dart
   // ❌ 不要為簡單的數據類別建立 Mock
   class MockWorkoutPlan extends Mock implements WorkoutPlan {}  // 無意義
   
   // ✅ 直接使用真實的數據類別
   final plan = WorkoutPlan(/* ... */);
   ```

2. **Mock 實現細節**
   ```dart
   // ❌ 測試不應該知道內部實現
   verify(() => mockService.somePrivateMethod()).called(1);
   ```

---

## 8. 數據庫與外部服務解耦細節

### 8.1 Supabase 解耦策略

**StrengthWise 現狀**：已實現良好的解耦 ✅

**驗證**：
```bash
# 搜尋直接的 Supabase 調用（應該為 0）
grep -r "Supabase.instance.client" lib/views/
grep -r "Supabase.instance.client" lib/controllers/
```

**期望結果**：
```
# 應該只在 Service 層找到
lib/services/workout_service_supabase.dart
lib/services/statistics_service_supabase.dart
```

### 8.2 測試中的數據庫處理

#### 方案 1：Mock Service Layer（推薦）✅

```dart
// ✅ 推薦：完全不觸碰數據庫
test('should load workouts', () {
  final mockService = MockWorkoutService();
  final controller = WorkoutController(workoutService: mockService);
  
  when(() => mockService.getUserWorkoutPlans(any()))
    .thenAnswer((_) async => [TestDataFactory.createWorkoutPlan()]);
  
  await controller.loadPlans('user123');
  
  expect(controller.plans, hasLength(1));
});
```

#### 方案 2：內存數據庫（如需要）

```dart
// 如果確實需要測試 SQL 邏輯
setUpAll(() async {
  // 使用 sqflite_common_ffi 建立內存數據庫
  databaseFactory = databaseFactoryFfi;
  testDatabase = await databaseFactory.openDatabase(inMemoryDatabasePath);
});

test('should query workouts correctly', () async {
  // 測試複雜的 SQL 查詢邏輯
});

tearDownAll(() async {
  await testDatabase.close();
});
```

**StrengthWise 建議**：方案 1（已有良好的 Service 抽象，無需真實數據庫）

### 8.3 外部依賴 Mock 清單

| 依賴 | Mock 策略 | 測試範例 |
|------|----------|---------|
| **Supabase Client** | Mock Service Layer | ✅ `MockWorkoutService` |
| **SharedPreferences** | Mock 或 In-Memory | ✅ `MockCacheService` |
| **HTTP Client** | Mock 或 http_mock_adapter | 🟡 如有 API 調用 |
| **Local Notifications** | Mock | 🟡 如有通知功能 |

---

## 9. 未來展望與持續集成

### 9.1 CI/CD 測試自動化

#### 9.1.1 GitHub Actions 配置

```yaml
# .github/workflows/test.yml
name: Flutter Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Analyze code
        run: flutter analyze
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info
          fail_ci_if_error: true
```

#### 9.1.2 測試報告與覆蓋率

```bash
# 生成測試覆蓋率報告
flutter test --coverage

# 轉換為 HTML 報告（需要安裝 lcov）
genhtml coverage/lcov.info -o coverage/html

# 開啟報告
open coverage/html/index.html
```

**目標覆蓋率**：
- 🎯 **Phase 1**：30% 整體覆蓋率（Domain Layer 70%+）
- 🎯 **Phase 2**：50% 整體覆蓋率（Domain + Data 80%+）
- 🎯 **Phase 3**：60% 整體覆蓋率（全層級覆蓋）

### 9.2 測試驅動開發（TDD）實踐

#### 紅-綠-重構循環

```
1. 🔴 紅燈：寫一個失敗的測試
   ↓
2. 🟢 綠燈：寫最少的代碼讓測試通過
   ↓
3. 🔵 重構：優化代碼（測試保持通過）
   ↓
回到步驟 1
```

**範例：TDD 實作新功能**

```dart
// 1. 🔴 紅燈：寫測試（功能還不存在）
test('should calculate 1RM correctly', () {
  final exercise = Exercise(/* ... */);
  
  final oneRM = exercise.calculate1RM(weight: 100, reps: 10);
  
  expect(oneRM, closeTo(133.3, 0.1));  // ❌ 測試失敗（方法不存在）
});

// 2. 🟢 綠燈：實作功能
class Exercise {
  double calculate1RM({required double weight, required int reps}) {
    // Epley Formula
    return weight * (1 + reps / 30.0);
  }
}
// ✅ 測試通過

// 3. 🔵 重構：優化代碼
class Exercise {
  /// 計算最大單次重量（1RM）
  /// 
  /// 使用 Epley 公式：1RM = weight × (1 + reps / 30)
  double calculate1RM({required double weight, required int reps}) {
    if (reps <= 0 || weight <= 0) {
      throw ArgumentError('重量和次數必須大於 0');
    }
    return weight * (1 + reps / 30.0);
  }
}
```

### 9.3 技術債務管理

#### 重構檢查清單

**每週審查**：
- [ ] 是否有新增未測試的代碼？
- [ ] 是否有直接的數據庫調用（繞過 Service）？
- [ ] 是否有超過 300 行的檔案？
- [ ] 是否有重複的業務邏輯？

**每月審查**：
- [ ] 測試覆蓋率是否下降？
- [ ] CI 是否有失敗的測試？
- [ ] 是否有累積的 TODO 標記？

### 9.4 可維護性指標

| 指標 | 目標 | 測量方法 |
|------|------|---------|
| **測試覆蓋率** | 60%+ | `flutter test --coverage` |
| **單檔案行數** | < 300 行 | 代碼審查 |
| **圈複雜度** | < 10 | 靜態分析工具 |
| **重複代碼率** | < 5% | 代碼審查 |
| **CI 通過率** | 95%+ | GitHub Actions |

---

## 10. 結論與行動計劃

### 10.1 核心要點總結

> **StrengthWise 專案的解耦與重構，是從「代碼堆砌」走向「軟件工程」的必經之路。**

**關鍵成就**：
- ✅ StrengthWise 已具備良好的架構基礎（Clean Architecture 基礎完成）
- ✅ Service Layer 完全解耦（100% Interface 使用）
- ✅ 統計頁面重構成功（1,951 行 → 16 個模組化檔案）

**主要挑戰**：
- 🔴 測試覆蓋率幾乎為 0（技術債務風險）
- 🟡 缺少 Use Case 層（業務邏輯散落在 Controller 中）
- 🟡 未建立測試文化（無 TDD 實踐）

### 10.2 優先級行動計劃

#### Phase 1：建立測試基礎（Week 1）⭐⭐⭐

**目標**：讓專案「可測試」

- [ ] **Day 1-2**：配置測試環境
  - [ ] 安裝測試依賴（mocktail, bloc_test）
  - [ ] 建立測試目錄結構
  - [ ] 創建 Test Helper 工具

- [ ] **Day 3-5**：建立第一批測試
  - [ ] 為 `WorkoutPlan.calculateTotalVolume()` 建立測試
  - [ ] 為 `WorkoutModel` 轉換建立測試
  - [ ] 為 `WorkoutController` 建立測試

- [ ] **驗收標準**：
  - [ ] ✅ 至少 10 個測試通過
  - [ ] ✅ CI/CD 自動測試配置完成

#### Phase 2：提取 Use Cases（Week 2-3）⭐⭐⭐

**目標**：業務邏輯可獨立測試

- [ ] **Week 2**：核心 Use Cases
  - [ ] `SaveWorkoutUseCase`（+ 測試）
  - [ ] `CalculateStatisticsUseCase`（+ 測試）
  - [ ] `ValidateWorkoutUseCase`（+ 測試）

- [ ] **Week 3**：重構 Controllers
  - [ ] 重構 `WorkoutController` 使用 Use Cases
  - [ ] 重構 `StatisticsController` 使用 Use Cases
  - [ ] 更新所有相關測試

- [ ] **驗收標準**：
  - [ ] ✅ Domain Layer 測試覆蓋率 > 70%
  - [ ] ✅ 所有 Use Cases 有完整測試

#### Phase 3：全面測試覆蓋（Week 4-6）⭐⭐

**目標**：達到 60% 整體覆蓋率

- [ ] **Week 4**：Data Layer 測試
  - [ ] 所有 Model 轉換測試
  - [ ] Repository 測試

- [ ] **Week 5**：Presentation Layer 測試
  - [ ] 所有 Controller 測試
  - [ ] 關鍵 Widget 測試

- [ ] **Week 6**：測試優化
  - [ ] 修復所有失敗測試
  - [ ] 優化測試執行速度
  - [ ] 建立測試文檔

- [ ] **驗收標準**：
  - [ ] ✅ 整體測試覆蓋率 > 60%
  - [ ] ✅ CI 通過率 > 95%
  - [ ] ✅ 測試執行時間 < 30 秒

### 10.3 長期維護策略

**測試文化建立**：
1. **新功能必須包含測試**（Code Review 檢查項）
2. **Bug 修復必須先寫失敗測試**（回歸測試）
3. **每週審查測試覆蓋率**（防止下降）

**持續改進**：
1. **每月重構一個模塊**（降低技術債務）
2. **每季度架構審查**（識別新的耦合點）
3. **每年技術升級**（Flutter 版本、依賴更新）

### 10.4 投資回報（ROI）

**初期投資**：6-10 週（全職開發）

**長期收益**：
- 📉 **Bug 減少 50-70%**（測試防護網）
- ⏱️ **開發速度提升 30-50%**（代碼更易理解和修改）
- 💰 **維護成本降低 40-60%**（技術債務減少）
- 🚀 **新功能開發加速 2-3x**（可重用模塊增加）

### 10.5 最終寄語

> **重構不是一次性的任務，而是持續的實踐。**

StrengthWise 已經擁有堅實的架構基礎，現在需要的是：
1. **建立測試習慣**（從第一個測試開始）
2. **保持架構紀律**（不走捷徑）
3. **持續小步改進**（絞殺者模式）

**從今天開始，為每一個新功能寫測試，為每一個 Bug 修復寫測試，6 個月後，你會擁有一個健壯、可靠且易於擴展的應用。** 🚀

---

## 📚 參考資源

### Flutter 測試
- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)

### 整潔架構
- [Clean Architecture (Robert C. Martin)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture by Reso Coder](https://resocoder.com/flutter-clean-architecture-tdd/)

### Mock 與測試工具
- [Mocktail Documentation](https://pub.dev/packages/mocktail)
- [BLoC Testing](https://pub.dev/packages/bloc_test)

### 測試驅動開發
- [Test-Driven Development (Kent Beck)](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530)

---

**文檔維護**：請定期更新本文檔以反映專案的最新狀態和測試策略調整。

**最後更新**：2024年12月27日

