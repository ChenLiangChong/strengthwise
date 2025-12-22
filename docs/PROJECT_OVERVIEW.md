# StrengthWise - 專案總覽

> 專案的技術架構、開發規範、核心概念的完整說明

**最後更新**：2024年12月22日

---

## 📋 專案簡介

**StrengthWise** 是一個基於 Flutter 和 Firebase 開發的跨平台健身訓練追蹤應用。

### 當前定位
- **主要功能**：個人健身記錄工具（單機版）
- **未來目標**：教練與學員的雙邊平台

### 核心價值
- 💪 簡單易用的訓練記錄
- 📊 清晰的進度追蹤
- 🎯 個人化的訓練計劃
- 📈 數據驅動的訓練優化

---

## 🛠️ 技術棧

### 前端框架
```
Flutter (Dart SDK >=3.1.0, Flutter >=3.16.0)
├── 狀態管理：Provider (ChangeNotifier)
├── 依賴注入：GetIt (Service Locator Pattern)
├── 本地儲存：Hive、SharedPreferences
└── 圖表庫：fl_chart（計劃中）
```

### 後端服務
```
Firebase
├── Authentication   # Google Sign-In
├── Firestore       # NoSQL 資料庫
├── Storage         # 檔案儲存
├── Analytics       # 數據分析
├── Crashlytics     # 崩潰報告
└── Messaging       # 推送通知
```

---

## 🏗️ 架構設計

### MVVM + Clean Architecture

```
┌─────────────────────────────────────┐
│   View Layer (UI)                   │  ← lib/views/
│   - Pages, Widgets, Screens         │
│   - 只負責顯示和用戶互動              │
└──────────────┬──────────────────────┘
               │ Provider/Consumer
┌──────────────▼──────────────────────┐
│   Controller Layer (ViewModel)      │  ← lib/controllers/
│   - Business Logic                  │
│   - State Management                │
│   - ChangeNotifier                  │
└──────────────┬──────────────────────┘
               │ Service Interface
┌──────────────▼──────────────────────┐
│   Service Layer (Repository)        │  ← lib/services/
│   - Data Access                     │
│   - API Calls                       │
│   - Firestore Operations            │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Model Layer                       │  ← lib/models/
│   - Data Models                     │
│   - fromMap() / toMap()             │
└─────────────────────────────────────┘
```

### 依賴注入策略

所有服務透過 `service_locator.dart` 管理：

| 層級 | 註冊方式 | 生命週期 | 範例 |
|------|---------|----------|------|
| Service | `LazySingleton` | 首次使用時創建，全局共享 | `WorkoutService` |
| Controller | `Factory` | 每次請求創建新實例 | `WorkoutController` |
| Utility | `Singleton` | 立即創建，全局共享 | `ErrorHandlingService` |

---

## 📂 目錄結構

```
lib/
├── main.dart                    # 應用入口
├── firebase_options.dart        # Firebase 配置
│
├── models/                      # 資料模型
│   ├── user_model.dart          # 使用者
│   ├── workout_template_model.dart  # 訓練模板
│   ├── exercise_model.dart      # 運動動作
│   └── custom_exercise_model.dart   # 自訂動作
│
├── services/                    # 服務層
│   ├── interfaces/              # 服務介面
│   ├── service_locator.dart     # 依賴注入容器
│   ├── auth_wrapper.dart        # 認證服務
│   ├── workout_service.dart     # 訓練服務
│   ├── exercise_service.dart    # 運動庫服務
│   └── error_handling_service.dart  # 錯誤處理
│
├── controllers/                 # 控制器層
│   ├── interfaces/              # 控制器介面
│   ├── auth_controller.dart     # 認證控制
│   ├── workout_controller.dart  # 訓練控制
│   └── workout_execution_controller.dart  # 訓練執行
│
└── views/                       # UI 層
    ├── splash_screen.dart       # 啟動頁
    ├── login_page.dart          # 登入頁
    ├── main_home_page.dart      # 主頁（底部導航）
    └── pages/
        ├── home_page.dart       # 首頁（今日訓練、統計）
        ├── training_page.dart   # 訓練模板管理
        ├── booking_page.dart    # 行事曆/訓練計劃
        ├── records_page.dart    # 訓練記錄
        ├── profile_page.dart    # 個人資料
        ├── exercises_page.dart  # 運動庫
        └── workout/             # 訓練相關頁面
            ├── plan_editor_page.dart        # 計劃編輯
            ├── workout_execution_page.dart  # 訓練執行
            └── template_management_page.dart  # 模板管理
```

---

## ⚙️ 開發規範

### 1. 型別安全 ⭐⭐⭐

**必須**：所有 Firestore 操作透過 Model 類別

```dart
// ✅ 正確
final user = UserModel.fromMap(doc.data()!);
await firestore.collection('users').doc(uid).set(user.toMap());

// ❌ 錯誤
await firestore.collection('users').doc(uid).set({'name': 'John'});
```

### 2. 依賴注入

```dart
// ✅ 正確：透過 Service Locator 獲取
final workoutController = serviceLocator<IWorkoutController>();
final workoutService = serviceLocator<IWorkoutService>();

// ❌ 錯誤：直接 new
final controller = WorkoutController();  // 不建議
```

### 3. 錯誤處理

```dart
try {
  await _workoutService.createTemplate(template);
} catch (e) {
  // 統一使用 ErrorHandlingService
  _errorService.logError('建立訓練模板失敗: $e', 
                         type: 'WorkoutControllerError');
  _handleError('建立訓練模板失敗', e);
}
```

### 4. 狀態管理

```dart
// Controller 繼承 ChangeNotifier
class WorkoutController extends ChangeNotifier {
  void updateState() {
    // 修改狀態
    notifyListeners();  // 通知 UI 更新
  }
}

// UI 使用 Provider/Consumer
Consumer<WorkoutController>(
  builder: (context, controller, child) {
    return Text(controller.data);
  },
)
```

### 5. 註解規範

```dart
/// 建立新的訓練模板
/// 
/// [template] 訓練模板資料
/// 返回建立的模板 ID
Future<String> createTemplate(WorkoutTemplate template) async {
  // 驗證模板資料
  if (template.exercises.isEmpty) {
    throw Exception('訓練模板不能為空');
  }
  
  // 保存到 Firestore
  final docRef = await _firestore
      .collection('workoutTemplates')
      .add(template.toMap());
  
  return docRef.id;
}
```

**規範**：
- ✅ 公共方法使用 Dart Doc 註解（`///`）
- ✅ 關鍵業務邏輯加繁體中文註解
- ✅ 所有 UI 文字使用繁體中文

### 6. 命名規範

```dart
// 變數命名：駝峰式
final userName = 'Charlie';
final workoutPlanId = '123';

// 私有變數：底線開頭
final _userId = 'abc';
final _isLoading = false;

// 常數：全大寫蛇形
const MAX_WORKOUT_DURATION = 7200;
const DEFAULT_REST_TIME = 60;

// 類別：帕斯卡命名
class WorkoutController extends ChangeNotifier {}
class UserModel {}
```

---

## 🚨 重要約定

### 資料庫操作

1. **統一使用 workoutPlans 集合**
   ```
   workoutPlans (統一集合)
   ├── completed: false  → 未完成的訓練計劃
   └── completed: true   → 已完成的訓練記錄
   ```

2. **Model 必須有的方法**
   ```dart
   class MyModel {
     // 從 Firestore 數據創建
     factory MyModel.fromMap(Map<String, dynamic> map) { ... }
     
     // 轉換為 Firestore 格式
     Map<String, dynamic> toMap() { ... }
   }
   ```

3. **查詢訓練計劃時的欄位**
   ```dart
   // 必須同時查詢這兩個欄位（向後相容）
   .where('traineeId', isEqualTo: userId)  // 受訓者
   .where('creatorId', isEqualTo: userId)  // 創建者
   ```

### 不破壞現有功能

- ⚠️ 修改代碼前先測試現有功能
- ⚠️ 小步提交，每次確保可編譯
- ⚠️ 使用 git 分支開發新功能

---

## 🔍 常見問題排查

### 服務未初始化
```dart
// 檢查 main() 是否呼叫
await setupServiceLocator();

// 檢查服務是否註冊
print(serviceLocator.isRegistered<IWorkoutService>());
```

### 權限錯誤
- 檢查 `firestore.rules`
- 確認 Firebase Console 的安全規則

### 型別轉換錯誤
```dart
// ✅ 使用 Model 的 fromMap
final user = UserModel.fromMap(doc.data()!);

// ❌ 直接轉換
final user = doc.data() as UserModel;  // 會出錯
```

### 狀態不更新
```dart
// 確保呼叫 notifyListeners()
setState(() {
  _data = newData;
});
notifyListeners();  // ← 必須
```

---

## 📚 相關文檔

- `DEVELOPMENT_STATUS.md` - 當前開發進度和下一步計劃
- `DATABASE_DESIGN.md` - Firestore 資料庫結構設計
- `STATISTICS_IMPLEMENTATION.md` - 統計功能實作指南

---

## 💡 開發流程

### 新增功能的標準流程

1. **設計 Model**
   - 創建 `lib/models/new_model.dart`
   - 實作 `fromMap()` 和 `toMap()`

2. **創建 Service 介面**
   - 創建 `lib/services/interfaces/i_new_service.dart`
   - 定義 CRUD 方法

3. **實作 Service**
   - 創建 `lib/services/new_service.dart`
   - 實作 Firestore 操作

4. **註冊服務**
   - 在 `service_locator.dart` 註冊
   ```dart
   serviceLocator.registerLazySingleton<INewService>(
     () => NewService()
   );
   ```

5. **創建 Controller**
   - 創建 `lib/controllers/new_controller.dart`
   - 繼承 `ChangeNotifier`
   - 實作業務邏輯

6. **建立 UI**
   - 創建 `lib/views/pages/new_page.dart`
   - 使用 `Provider` 監聽狀態

7. **測試**
   - 功能測試
   - 確保不破壞現有功能

---

**這份文檔是專案的技術基礎，所有開發者都應該先閱讀！**

