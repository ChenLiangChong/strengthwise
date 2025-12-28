# StrengthWise - 專案總覽

> 專案架構、技術棧、開發規範的完整說明

**最後更新**：2024年12月28日 - v2.0 Phase 2 進行中（85%）

---

## 📋 專案簡介

**StrengthWise** 是一個基於 Flutter 和 Supabase 開發的跨平台健身訓練追蹤應用。

### 當前定位
- **主要功能**：個人健身記錄工具（單機版 v1.0）
- **未來目標**：教練與學員的雙邊平台

### 核心價值
- 💪 簡單易用的訓練記錄
- 📊 清晰的進度追蹤和統計分析
- 🎯 個人化的訓練計劃和模板
- 📈 數據驅動的訓練優化
- 🏋️ 794 個專業動作資料庫

### 專案規模
```
總代碼量：~47,000 行（v2.0 Phase 2）
- Flutter/Dart：~43,700 行
- SQL/Migrations：~2,500 行
- Python 腳本：~2,000 行

核心功能：
- 頁面（Pages）：20+ 個
- 控制器（Controllers）：12+ 個（含子模組 43 個）
- 服務（Services）：25+ 個
- 數據模型（Models）：30+ 個
- UI 組件（Widgets）：68+ 個
```

---

## 🛠️ 技術棧

### 前端框架
```
Flutter (Dart SDK >=3.1.0, Flutter >=3.16.0)
├── 狀態管理：Provider (ChangeNotifier)
├── 依賴注入：GetIt (Service Locator Pattern)
├── 本地儲存：SharedPreferences
├── 圖表庫：fl_chart
├── 字體：Inter (UI) + JetBrains Mono (數據)
└── 設計系統：Material 3 + Kinetic Design
```

### 後端服務
```
Supabase (PostgreSQL)
├── Authentication   # Supabase Auth + Google Sign-In
├── Database         # PostgreSQL (14 個表格)
├── Storage          # 檔案儲存
├── Realtime         # 即時訂閱
└── Edge Functions   # 伺服器函數（計劃中）
```

**資料庫**：
- **類型**：Supabase PostgreSQL
- **表格數量**：14 個（核心表格）
- **動作資料**：794 個系統動作 + 用戶自訂動作
- **安全性**：Row Level Security (RLS)

**遷移歷史**：
- ✅ 2024-12-25：從 Firestore 完全遷移到 Supabase PostgreSQL
- ✅ 2024-12-26：自訂動作功能完整實作（`custom_exercises` 表格）
- ✅ 2024-12-27：Phase 1-3 效能優化完成（查詢效能提升 50-90%）
- ✅ 2024-12-28：v2.0 Phase 1 完成（教練學員系統）
- 🚧 2024-12-28：v2.0 Phase 2 進行中（預約系統 - 85%）
- ✅ 成本優勢：$25/月固定（vs Firestore $11-50/月增長）

---

## 🏗️ 架構設計

### MVVM + Clean Architecture（✅ 已完全實施）

```
┌─────────────────────────────────────┐
│   View Layer (UI)                   │  ← lib/views/
│   - Pages, Widgets, Screens         │
│   - 只負責顯示和用戶互動              │
│   - ✅ 100% 使用 Interface           │
└──────────────┬──────────────────────┘
               │ Provider/Consumer
┌──────────────▼──────────────────────┐
│   Controller Layer (ViewModel)      │  ← lib/controllers/
│   - Business Logic                  │
│   - State Management                │
│   - ChangeNotifier                  │
│   - ✅ 100% 透過 Interface 注入依賴  │
└──────────────┬──────────────────────┘
               │ Service Interface
┌──────────────▼──────────────────────┐
│   Service Layer (Repository)        │  ← lib/services/
│   - Data Access                     │
│   - Supabase Operations             │
│   - 實作 Interface 定義的方法        │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Model Layer                       │  ← lib/models/
│   - Data Models                     │
│   - fromSupabase() / toMap()        │
│   - Snake_case 轉換                 │
└─────────────────────────────────────┘
```

**架構優化完成**（2024-12-26）：
- ✅ View 層使用 Interface：100%
- ✅ Controller 層使用 Interface：100%
- ✅ 直接 Supabase 調用：0 處
- ✅ 完全符合 Clean Architecture 規範

### 依賴注入策略

所有服務透過 `service_locator.dart` 管理：

| 層級 | 註冊方式 | 生命週期 | 範例 |
|------|---------|----------|------|
| Service | `LazySingleton` | 首次使用時創建，全局共享 | `WorkoutServiceSupabase` |
| Controller | `Factory` | 每次請求創建新實例 | `WorkoutController` |
| Utility | `Singleton` | 立即創建，全局共享 | `ErrorHandlingService` |

**重要**：必須透過 Interface 使用服務（依賴反轉原則）✅

```dart
// ✅ 正確：透過 Interface
final workoutService = serviceLocator<IWorkoutService>();
final authController = serviceLocator<IAuthController>();

// ✅ 正確：使用新增的 getUserPlans 方法
final plans = await workoutService.getUserPlans(
  completed: false,
  startDate: today,
  endDate: tomorrow,
);

// ❌ 錯誤：直接使用實作類別
final workoutService = WorkoutServiceSupabase(); // 違反依賴注入

// ❌ 錯誤：View 層直接使用 Supabase
await Supabase.instance.client.from('workout_plans').select();
```

**架構驗證**（2024-12-26）：
- ✅ 所有 Controller 都透過 Interface 注入依賴
- ✅ 所有 View 都透過 Interface 使用服務
- ✅ 零直接 Supabase 調用
- ✅ 零直接 Service 實作調用

---

## 📂 目錄結構

```
lib/
├── main.dart                    # 應用入口
│
├── models/                      # 資料模型
│   ├── user_model.dart          # 使用者
│   ├── workout_record_model.dart  # 訓練記錄
│   ├── workout_template_model.dart  # 訓練模板
│   ├── exercise_model.dart      # 運動動作
│   └── custom_exercise_model.dart   # 自訂動作
│
├── services/                    # 服務層
│   ├── interfaces/              # 服務介面（必須）
│   │   ├── i_auth_service.dart
│   │   ├── i_workout_service.dart
│   │   └── ...
│   ├── service_locator.dart     # 依賴注入容器
│   ├── auth_service_supabase.dart  # Supabase Auth
│   ├── workout_service_supabase.dart  # 訓練服務
│   ├── exercise_service_supabase.dart  # 運動庫服務
│   ├── statistics_service_supabase.dart  # 統計服務
│   └── error_handling_service.dart  # 錯誤處理
│
├── controllers/                 # 控制器層
│   ├── interfaces/              # 控制器介面（必須）
│   ├── auth_controller.dart     # 認證控制
│   ├── workout_controller.dart  # 訓練控制
│   └── workout_execution_controller.dart  # 訓練執行
│
├── views/                       # UI 層
│   ├── splash_screen.dart       # 啟動頁
│   ├── login_page.dart          # 登入頁
│   ├── main_home_page.dart      # 主頁（底部導航）
│   └── pages/
│       ├── home_page.dart       # 首頁（今日訓練、統計）
│       ├── training_page.dart   # 訓練模板管理
│       ├── booking_page.dart    # 行事曆/訓練計劃
│       ├── profile_page.dart    # 個人資料
│       ├── statistics_page_v2.dart  # 統計分析（主頁面）
│       ├── statistics/          # 統計頁面模組（2024-12-27 新增）
│       │   ├── tabs/            # 6 個獨立 Tab 頁面
│       │   └── widgets/         # 7 個共用 Widget
│       ├── exercises_page.dart  # 運動庫
│       └── workout/             # 訓練相關頁面
│           ├── plan_editor_page.dart        # 計劃編輯
│           ├── workout_execution_page.dart  # 訓練執行
│           └── template_management_page.dart  # 模板管理
│
├── themes/                      # 主題系統
│   └── app_theme.dart           # Material 3 主題
│
└── utils/                       # 工具類
    └── firestore_id_generator.dart  # ID 生成器

migrations/                      # Supabase SQL 遷移
├── 001_create_core_tables.sql
├── 002_create_user_tables.sql
├── 003_create_notes_table.sql
└── 004_create_booking_tables.sql

docs/                            # 文檔
├── DATABASE_SUPABASE.md         # 資料庫設計 ⭐
├── DEVELOPMENT_STATUS.md        # 開發狀態
├── UI_UX_GUIDELINES.md          # UI/UX 規範
└── ...
```

---

## ⚙️ 開發規範

### 1. 型別安全 ⭐⭐⭐

**必須**：所有資料庫操作透過 Model 類別

```dart
// ✅ 正確（Supabase）
final record = WorkoutRecord.fromSupabase(data);
await workoutService.createRecord(record);

// ❌ 錯誤：直接操作資料庫
await supabase.from('workout_plans').insert({'title': 'Test'});
```

### 2. 依賴注入 ⭐⭐⭐

```dart
// ✅ 正確：透過 Service Locator 和 Interface
final workoutController = serviceLocator<IWorkoutController>();
final workoutService = serviceLocator<IWorkoutService>();

// ❌ 錯誤：直接 new
final controller = WorkoutController();  // 不建議
final service = WorkoutServiceSupabase();  // 違反依賴反轉
```

### 3. 錯誤處理 ⭐⭐

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

### 5. 註解規範 ⭐⭐

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
  
  // 保存到 Supabase
  final response = await _supabase
      .from('workout_templates')
      .insert(template.toMap())
      .select()
      .single();
  
  return response['id'] as String;
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

### Supabase 資料庫操作

1. **統一使用 workout_plans 表格**
   ```
   workout_plans (PostgreSQL 表格)
   ├── completed: false  → 未完成的訓練計劃
   └── completed: true   → 已完成的訓練記錄
   ```

2. **Model 必須有的方法**
   ```dart
   class MyModel {
     // 從 Supabase 數據創建（處理 snake_case）
     factory MyModel.fromSupabase(Map<String, dynamic> json) { ... }
     
     // 轉換為 Supabase 格式（camelCase → snake_case）
     Map<String, dynamic> toMap() { ... }
   }
   ```

3. **查詢訓練計劃時的欄位**
   ```dart
   // Supabase 使用 snake_case
   .eq('trainee_id', userId)  // 受訓者
   .eq('creator_id', userId)  // 創建者
   ```

4. **ID 生成邏輯**
   ```dart
   // Firestore 相容 ID（20 字符）
   import 'package:strengthwise/utils/firestore_id_generator.dart';
   
   final id = generateFirestoreId();  // 例如：0A5921MGWAyUv7fXcA29
   ```

### 不破壞現有功能

- ⚠️ 修改代碼前先測試現有功能
- ⚠️ 小步提交，每次確保可編譯
- ⚠️ 使用 git 分支開發新功能

---

## ✅ 已完成功能（v1.0）

### **1. 核心訓練功能**
- ✅ 訓練計劃創建和管理
- ✅ 訓練模板系統（5 個默認模板）
- ✅ 訓練執行和記錄
- ✅ 每組單獨編輯（setTargets 支持）
- ✅ 時間權限控制（過去/今天/未來）

### **2. 動作資料庫**
- ✅ 794 個專業動作（Supabase PostgreSQL）
- ✅ 5 層分類系統（訓練類型 → 身體部位 → 特定肌群 → 器材類別 → 動作）
- ✅ 自訂動作功能
- ✅ 階層式動作選擇器

### **3. 統計分析系統**（~5,180 行代碼）⭐⭐⭐
- ✅ 訓練頻率統計（本週/本月/全年訓練次數）
- ✅ 訓練量趨勢圖表（使用 fl_chart）
- ✅ 身體部位分布分析（餅狀圖）
- ✅ 個人記錄（PR）追蹤（力量進步完整功能）
- ✅ 力量進步曲線（折線圖）
- ✅ 肌群平衡分析（訓練頻率雷達圖）
- ✅ 訓練日曆熱力圖（7x5 熱力圖）
- ✅ 完成率統計（每週訓練完成情況）
- ✅ 收藏動作管理（快速選擇常用動作）
- ✅ 身體數據追蹤（體重/體脂/BMI/肌肉量，2024-12-26 新增）
- ✅ **統計頁面解耦重構**（1,951 行 → 16 個模組化元件，2024-12-27 新增）⭐

**統計功能架構**（2024-12-27 重構後）：

```
統計頁面 (StatisticsPageV2)
├── 主頁面（166 行，僅負責 TabBar 導航）
│
├── 6 個獨立 Tab 頁面（lib/views/pages/statistics/tabs/）
│   ├── overview_tab.dart              # 概覽統計
│   ├── strength_progress_tab.dart     # 力量進步
│   ├── muscle_balance_tab.dart        # 肌群平衡
│   ├── calendar_tab.dart              # 訓練日曆
│   ├── completion_rate_tab.dart       # 完成率
│   └── body_data_tab.dart             # 身體數據
│
└── 7 個共用 Widget（lib/views/pages/statistics/widgets/）
    ├── time_range_selector.dart       # 時間範圍選擇器
    ├── empty_state_widget.dart        # 空狀態提示
    ├── frequency_card.dart            # 訓練頻率卡片
    ├── volume_trend_chart.dart        # 訓練量趨勢圖
    ├── body_part_distribution_card.dart  # 肌群分布
    ├── personal_records_card.dart     # 個人記錄
    └── suggestions_card.dart          # 訓練建議

統計服務 (StatisticsServiceSupabase)
├── getTrainingFrequency() - 訓練頻率統計
├── getVolumeHistory() - 訓練量歷史
├── getBodyPartDistribution() - 身體部位分布
├── getPersonalRecords() - 個人最佳記錄
├── getTrainingCalendar() - 訓練日曆數據
├── 多時間範圍快取（5 分鐘）
└── 首頁背景預載入（秒開優化）
```

**重構成果**（2024-12-27）：
- 📄 單檔行數：1,951 → 166 行（-91.5%）
- 📂 模組化：1 個大檔案 → 16 個小元件
- 📊 可讀性：⭐⭐ → ⭐⭐⭐⭐⭐
- 🔧 可維護性：⭐⭐ → ⭐⭐⭐⭐⭐
- ⚡ 效能：秒開（預載入 + 快取）

**技術實作**：

| 功能 | 技術棧 | 說明 |
|------|--------|------|
| 圖表渲染 | `fl_chart: ^0.66.0` | 折線圖、餅狀圖、雷達圖 |
| 數據聚合 | Supabase 查詢 + Dart 計算 | 訓練量計算：`Σ(重量 × 次數 × 組數)` |
| 快取策略 | 5 分鐘快取 | 減少資料庫查詢，提升載入速度 |
| PR 計算 | 客戶端邏輯 | 遍歷所有 sets 找出最大重量 |
| 熱力圖 | 自訂 GridView | 7 列 × 5 行，顏色深淺表示訓練量 |

**驗收標準**（已達成）：

- ✅ 數據準確性：訓練次數、訓練量、PR 記錄正確
- ✅ 性能要求：統計頁面載入時間 < 2 秒（5 分鐘快取）
- ✅ 用戶體驗：UI 美觀易讀（Week 2 UI 重構）
- ✅ 錯誤處理：無數據時顯示空狀態，支援重新載入

---

### **4. 身體數據功能**（2024-12-26 新增）⭐⭐
- ✅ Model → Service → Controller → UI 完整架構
- ✅ 體重/體脂/BMI/肌肉量記錄
- ✅ 趨勢圖表（使用 fl_chart）
- ✅ CRUD 功能完整（新增/編輯/刪除）
- ✅ 單位轉換（公制/英制）
- ✅ 資料庫遷移腳本（`migrations/004_create_body_data_table.sql`）
- ✅ 整合到個人資料頁面和統計頁面

**實作規模**：新增 1,235 行代碼，0 個 linter 錯誤

---

### **5. UI/UX 設計**（Kinetic Design System）
- ✅ Material 3 設計語言
- ✅ 深色/淺色/系統模式切換
- ✅ Titanium Blue 配色方案
- ✅ Inter + JetBrains Mono 字體
- ✅ 8 點網格系統
- ✅ 觸覺回饋和微動畫

### **6. 技術架構**
- ✅ MVVM + Clean Architecture
- ✅ 依賴注入（GetIt）
- ✅ 狀態管理（Provider）
- ✅ Supabase 後端（PostgreSQL + Auth）
- ✅ Row Level Security (RLS)
- ✅ 錯誤處理和日誌系統

---

## 📚 相關文檔

### 核心文檔
- **[DATABASE_SUPABASE.md](DATABASE_SUPABASE.md)** - Supabase PostgreSQL 資料庫設計 ⭐
- **[DATABASE_OPTIMIZATION_GUIDE.md](DATABASE_OPTIMIZATION_GUIDE.md)** - 資料庫優化指南（雙語系統 + 效能優化）⭐
- **[DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)** - 開發狀態和下一步計劃
- **[UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md)** - UI/UX 設計規範
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Release APK 構建與 Google Sign-In 配置

### 已歸檔文檔（參考用）
- `docs/archive/` - 已完成階段性任務或已過時的文檔

---

## 🔍 常見問題排查

### 服務未初始化
```dart
// 檢查 main() 是否呼叫
await setupServiceLocator();

// 檢查服務是否註冊
print(serviceLocator.isRegistered<IWorkoutService>());
```

### 型別轉換錯誤
```dart
// ✅ 使用 Model 的 fromSupabase
final user = UserModel.fromSupabase(data);

// ❌ 直接轉換
final user = data as UserModel;  // 會出錯
```

### 狀態不更新
```dart
// 確保呼叫 notifyListeners()
setState(() {
  _data = newData;
});
notifyListeners();  // ← 必須
```

### Snake_case 轉換問題
```dart
// Supabase 使用 snake_case，Dart 使用 camelCase
factory UserModel.fromSupabase(Map<String, dynamic> json) {
  return UserModel(
    uid: json['id'] as String,  // id → uid
    displayName: json['display_name'] as String?,  // snake_case → camelCase
    isCoach: json['is_coach'] as bool? ?? false,
  );
}
```

---

## 💡 開發流程

### 新增功能的標準流程

1. **設計 Model**
   - 創建 `lib/models/new_model.dart`
   - 實作 `fromSupabase()` 和 `toMap()`

2. **創建 Service 介面**
   - 創建 `lib/services/interfaces/i_new_service.dart`
   - 定義 CRUD 方法

3. **實作 Service**
   - 創建 `lib/services/new_service_supabase.dart`
   - 實作 Supabase 操作

4. **註冊服務**
   - 在 `service_locator.dart` 註冊
   ```dart
   serviceLocator.registerLazySingleton<INewService>(
     () => NewServiceSupabase()
   );
   ```

5. **創建 Controller**
   - 創建 `lib/controllers/new_controller.dart`
   - 繼承 `ChangeNotifier`
   - 透過 Interface 注入依賴

6. **建立 UI**
   - 創建 `lib/views/pages/new_page.dart`
   - 使用 `Provider` 監聽狀態
   - 透過 Interface 使用服務

7. **測試**
   - 功能測試
   - 確保不破壞現有功能

---

## 📚 相關文檔

### 核心文檔
- **[DATABASE_SUPABASE.md](DATABASE_SUPABASE.md)** - Supabase PostgreSQL 資料庫設計 ⭐
- **[DATABASE_OPTIMIZATION_GUIDE.md](DATABASE_OPTIMIZATION_GUIDE.md)** - 資料庫優化指南（雙語系統 + 效能優化）⭐
- **[DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)** - 開發狀態和下一步計劃
- **[UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md)** - UI/UX 設計規範
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Release APK 構建與 Google Sign-In 配置

### 已歸檔文檔（參考用）
- `docs/archived/` - 已完成階段性任務或已過時的文檔

---

## 🎉 里程碑

**2024年12月26日（深夜）** - 資料庫雙語系統 100% 完成 🎊

**核心成就**：
- 🌐 805 筆記錄完整中英雙語支援（794+8+3）
- 📊 符合 NSCA、ACSM 國際標準
- 🏗️ 五階層分類架構完善
- 🗄️ 資料庫精簡至 8 個核心表格
- 📚 文檔整合完成（6 個核心文檔）

**2024年12月26日** - 架構優化完成 🎊

**核心成就**：
- 🏗️ 完全符合 Clean Architecture 規範
- 🔌 100% 使用依賴反轉原則（Interface）
- 🎨 統一通知系統（NotificationUtils）
- 🐛 修復所有架構違規（5 個文件）
- ✅ Flutter analyze：0 個錯誤

**2024年12月25日** - StrengthWise 單機版 v1.0 完成 🎊

**核心成就**：
- 📱 完整的個人健身記錄應用
- 📊 專業級統計分析系統（~5,180 行）
- 💪 794 個專業動作資料庫
- 🎯 直觀的訓練計劃管理
- ⚡ 響應式 Material 3 UI/UX
- 🗄️ Supabase PostgreSQL 後端

**代碼統計**：
- 總代碼量：~15,000 行
- 核心功能：12 個頁面、8 個控制器、15+ 服務
- 數據模型：20+ 個 Model 類別
- 開發週期：~2 周（集中開發）

---

**這份文檔是專案的技術基礎，所有開發者都應該先閱讀！**
