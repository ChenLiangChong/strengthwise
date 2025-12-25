# StrengthWise - AI Agent 開發指南

> AI 程式碼助手的完整開發指南

**最後更新**：2024年12月26日

---

## 📖 文檔導航

開始開發前，請先閱讀以下文檔：

1. **[docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md)** - 專案架構和技術棧（⭐ 必讀）
2. **[docs/DATABASE_SUPABASE.md](docs/DATABASE_SUPABASE.md)** - Supabase PostgreSQL 資料庫設計（⭐ 必讀）
3. **[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)** - 當前開發進度和下一步任務
4. **[docs/UI_UX_GUIDELINES.md](docs/UI_UX_GUIDELINES.md)** - UI/UX 設計規範

---

## 🚨 核心開發規則（必須遵守）

### 1. 不破壞現有功能 ⭐⭐⭐
- ✅ 修改代碼前先測試現有功能
- ✅ 小步提交，確保每次修改後應用可編譯
- ❌ 不要刪除或破壞現有功能

### 2. 型別安全 ⭐⭐⭐
- ✅ **必須**：所有資料庫操作透過 Model 類別的 `.fromSupabase()` 和 `.toMap()` 方法
- ❌ **禁止**：直接操作 `Map<String, dynamic>`

```dart
// ✅ 正確（Supabase）
final record = WorkoutRecord.fromSupabase(data);
await workoutService.createRecord(record);

// ❌ 錯誤
await supabase.from('workout_plans').insert({'title': 'Test'});
```

### 3. 依賴注入 ⭐⭐⭐
- ✅ **必須**：所有服務透過 `serviceLocator` 獲取
- ✅ **必須**：必須透過 Interface 使用服務（依賴反轉原則）
- ✅ 控制器透過建構函式注入依賴

```dart
// ✅ 正確：透過 Service Locator 和 Interface
final workoutController = serviceLocator<IWorkoutController>();
final workoutService = serviceLocator<IWorkoutService>();

// ❌ 錯誤：直接使用實作類別
final service = WorkoutServiceSupabase();  // 違反依賴反轉
```

### 4. 錯誤處理 ⭐⭐
- ✅ 統一使用 `ErrorHandlingService` 記錄錯誤
- ✅ 控制器層捕獲異常並轉換為友善訊息

```dart
try {
  await _workoutService.createTemplate(template);
} catch (e) {
  _errorService.logError('建立訓練模板失敗: $e', type: 'WorkoutControllerError');
  _handleError('建立訓練模板失敗', e);
}
```

### 5. 註解規範 ⭐⭐
- ✅ **必須**：關鍵業務邏輯加**繁體中文註解**
- ✅ **必須**：公共方法使用 Dart Doc 註解（`///`）
- ✅ **必須**：所有程式碼註解、變數命名、UI 文字都使用**繁體中文**

### 6. 文檔管理規範 ⭐⭐
- ❌ **禁止**：非必要情況下產生新的 Markdown 文檔
- ✅ **必須**：新增文檔前先確認是否可以更新現有文檔
- ✅ **必須**：臨時性、實驗性文檔在任務完成後應清理

### 7. UI/UX 設計規範 ⭐⭐
- ✅ **必須**：遵循 `docs/UI_UX_GUIDELINES.md` 中的設計系統
- ✅ **必須**：所有間距使用 8 點網格系統（8, 16, 24, 32...）
- ✅ **必須**：觸控目標最小高度 48dp
- ✅ **必須**：支援深色/淺色模式切換
- ✅ **必須**：使用語意化色彩（Primary, Surface, OnSurface 等）
- ✅ **建議**：關鍵操作加入觸覺回饋（HapticFeedback）

---

## 🗄️ 資料庫重要約定

### ⚠️ 已完成 Supabase 遷移（2024-12-25）

**重要**：專案已從 Firestore 完全遷移至 Supabase PostgreSQL

**完整資料庫文檔**：請參考 **[docs/DATABASE_SUPABASE.md](docs/DATABASE_SUPABASE.md)**

### 1. workout_plans 表格（統一）

**架構**：
```
workout_plans（PostgreSQL 表格）
├── completed: false  → 未完成的訓練計劃
└── completed: true   → 已完成的訓練記錄
```

**必須包含的欄位**：
```dart
{
  'id': TEXT,              // Firestore 相容 ID（20 字符）
  'user_id': UUID,         // 向後相容
  'trainee_id': UUID,      // 受訓者 ID
  'creator_id': UUID,      // 創建者 ID
  'completed': bool,       // 完成狀態
  'scheduled_date': TIMESTAMPTZ,  // 預定日期
  'exercises': JSONB,      // 訓練動作（JSON）
  ...
}
```

### 2. 查詢訓練計劃時

**使用 Supabase Client**：
```dart
// 查詢作為受訓者的計劃（注意：Supabase 使用 snake_case）
await Supabase.instance.client
  .from('workout_plans')
  .select()
  .eq('trainee_id', userId);

// 如果是教練，也查詢作為創建者的計劃
if (isCoach) {
  .eq('creator_id', userId)
  .eq('plan_type', 'trainer');
}
```

### 3. 使用 WorkoutService 介面（✅ 已完成架構優化）

**重要**：所有 View 層和 Controller 層都必須透過 Interface 使用服務

```dart
// ✅ 正確：透過服務層和 Interface
final workoutService = serviceLocator<IWorkoutService>();
await workoutService.createRecord(record);

// ✅ 正確：查詢訓練計劃（使用新增的方法）
final plans = await workoutService.getUserPlans(
  completed: false,
  startDate: today,
  endDate: tomorrow,
);

// ❌ 禁止：View 層直接操作 Supabase（違反架構原則）
await Supabase.instance.client.from('workout_plans').insert(...);
```

**架構驗證**（2024-12-26）：
- ✅ Controller 層使用 Interface：100%
- ✅ View 層使用 Interface：100%
- ✅ 直接 Supabase 調用：0 處
- ✅ 直接 Service 實作調用：0 處

### 4. Snake_case 轉換

Supabase 使用 `snake_case`，Dart 使用 `camelCase`：

```dart
factory UserModel.fromSupabase(Map<String, dynamic> json) {
  return UserModel(
    uid: json['id'] as String,  // id → uid
    displayName: json['display_name'] as String?,  // snake_case → camelCase
    isCoach: json['is_coach'] as bool? ?? false,
  );
}
```

---

## 🚀 開發流程

### 新增功能的標準流程

```
1. 設計 Model (lib/models/)
   ├── 實作 fromSupabase() 方法
   └── 實作 toMap() 方法
   ↓
2. 創建 Service 介面 (lib/services/interfaces/)
   └── 定義 CRUD 方法
   ↓
3. 實作 Service (lib/services/)
   └── 實作 Supabase 操作
   ↓
4. 註冊到 Service Locator (service_locator.dart)
   └── 註冊為 LazySingleton
   ↓
5. 創建 Controller (lib/controllers/)
   ├── 繼承 ChangeNotifier
   └── 透過 Interface 注入依賴
   ↓
6. 建立 UI (lib/views/pages/)
   └── 透過 Interface 使用服務
   ↓
7. 測試並驗證
```

### To-Do List 管理

**必須**使用 `todo_write` 工具管理任務：

```
開始任務 → 創建 TODO List
  ↓
完成步驟 → 更新狀態為 completed
  ↓
開始新步驟 → 更新狀態為 in_progress
  ↓
任務完成 → 所有項目標記為 completed
```

---

## 🔍 常見問題排查

### 服務未初始化
```dart
// 檢查是否在 main() 呼叫
await setupServiceLocator();

// 檢查服務是否註冊
print(serviceLocator.isRegistered<IWorkoutService>());
```

### 型別轉換錯誤
```dart
// ✅ 使用 Model
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

### TextField 內容消失
```dart
// ❌ 每次 build 都創建新的 Controller
TextField(
  controller: TextEditingController(text: value),
  ...
)

// ✅ 使用持久的 Controller
final _controller = TextEditingController();
...
TextField(
  controller: _controller,
  ...
)
```

---

## 🎯 當前開發重點

**目標**：✅ 個人資料頁面完善已完成（2024-12-26）

**當前階段**：🎉 **Phase 1-3 全部完成！**

### 📋 已完成任務

| 任務 | 狀態 | 完成日期 | 說明 |
|------|------|----------|------|
| 移除 Firebase 依賴 | ✅ 已完成 | 2024-12-25 | 移除 Firebase Auth、Firestore 舊代碼 |
| UI/UX 優化 | ✅ 已完成 | 2024-12-26 | 統一通知系統、修復卡片樣式 |
| 檢查 View 層架構 | ✅ 已完成 | 2024-12-26 | 所有 View 都使用 Interface |
| 身體數據功能 | ✅ 已完成 | 2024-12-26 | 完整 CRUD、圖表、趨勢分析 |
| 文檔整理 | ✅ 已完成 | 2024-12-26 | 歸檔階段性文檔，保留核心文檔 |
| 執行資料庫遷移 | ✅ 已完成 | 2024-12-26 | 執行 `004_create_body_data_table.sql` |
| 個人資料頁面整合統計 | ✅ 已完成 | 2024-12-26 | 新增「我的統計」按鈕 |
| 統計頁面新增身體數據 | ✅ 已完成 | 2024-12-26 | 新增「身體數據」Tab |
| **資料庫完整匯出** | ✅ **已完成** | **2024-12-26** | **匯出所有數據並生成分析文檔** |

### 🎉 重大里程碑

**個人資料頁面完善（Phase 1-3）全部完成！**（2024-12-26）

**資料庫效能優化準備完成！**
- ✅ 完整資料庫數據匯出（8 個表格）
- ✅ 健身動作完整資訊文檔（794 個動作）
- ✅ 查詢完整列表與優化建議（~120 個查詢）
- ✅ 索引優化 SQL（預期提升 50-90%）

詳見：[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)

---

**下一步方向**：
- 🔧 資料庫效能優化（執行索引 SQL）
- 🎨 UI/UX 持續優化
- 📱 新功能開發

---

**最近完成**（2024-12-26）：
- ✅ **身體數據功能完整實作**（2024-12-26 下午）⭐⭐⭐
  - Model → Service → Controller → UI 完整架構
  - 體重/體脂/BMI/肌肉量記錄
  - 趨勢圖表（使用 fl_chart）
  - CRUD 功能完整
  - 資料庫遷移腳本（`migrations/004_create_body_data_table.sql`）
  - 新增 1,235 行代碼，0 個 linter 錯誤
- ✅ **個人資料頁面單位系統轉換**（2024-12-26 下午）⭐
  - 公制/英制單位轉換（身高、體重、BMI）
  - 動態顯示切換
- ✅ **文檔整理完成**（2024-12-26 下午）⭐
  - 整合 `CHANGELOG.md` 到 `DEVELOPMENT_STATUS.md`
  - 統一變更記錄管理
  - 更新所有文檔參考連結
- ✅ **文檔整理完成**（2024-12-26 上午）⭐
  - 歸檔 11 個已完成/過時文檔
  - 保留 9 個核心文檔
  - 創建 `docs/README.md` 導航指南
  - 創建 `docs/archived/` 目錄
- ✅ **架構優化 100% 完成**（2024-12-26）⭐⭐⭐
  - 所有 View 層使用 Interface（依賴反轉原則）
  - 移除所有直接 Supabase 調用（2 處）
  - 添加 `IWorkoutService.getUserPlans()` 方法
  - 修復 5 個文件，0 個 analyze 錯誤
  - 完全符合 Clean Architecture 規範
- ✅ **UI/UX 優化完成**（2024-12-26）⭐⭐
  - 統一通知系統（NotificationUtils）
  - 修復訓練計劃標題顯示
  - 修復統計頁面動作顯示（5 層導航）
  - 修復卡片 UI/UX 規範
  - 修復服務初始化警告
- ✅ **Supabase 遷移 100% 完成**（2024-12-25）⭐⭐⭐
  - 完成資料庫遷移：Firestore → Supabase PostgreSQL
  - 成功遷移：exercises (794)、equipments (21)、jointTypes (12)
  - 新用戶認證：Firebase Auth → Supabase Auth
  - 重構 8 個核心頁面：home、training、booking、plan_editor 等
  - 實現「今日訓練」功能
  - 實現時間權限編輯（過去/現在/未來）
  - 成本優勢：$25/月固定（vs Firestore $11-50/月增長）
- ✅ **UI/UX 重設計完成**（Week 1-4 完成）
  - Kinetic 設計系統建立
  - Material 3 完整實作
  - Titanium Blue 配色方案
  - 深色/淺色/系統模式切換
- ✅ **文檔整理完成**（2024-12-25）
  - 創建統一的 `DATABASE_SUPABASE.md`
  - 整合 `PROJECT_SUMMARY.md` 到 `PROJECT_OVERVIEW.md`
  - 歸檔舊的 Firestore 相關文檔

**基礎功能 v1.0**：✅ 已完成
- ✅ 訓練模板系統
- ✅ 時間權限控制
- ✅ Google 登入（Supabase Auth）
- ✅ 統計分析系統（~5,180 行）
- ✅ 794 個專業動作資料庫

**參考文檔**：
- `docs/README.md` - 📚 文檔導航（必讀）
- `docs/DATABASE_SUPABASE.md` - 查看 Supabase 資料庫結構
- `docs/DEVELOPMENT_STATUS.md` - 了解整體進度和下一步任務（包含最新變更記錄）
- `docs/UI_UX_GUIDELINES.md` - UI/UX 設計規範
- `docs/BUILD_RELEASE.md` - 構建和發布指南

---

## 📚 相關文檔

### 核心文檔（⭐ 必讀）
- **`docs/README.md`** - 📚 文檔導航（必讀）
- **`docs/PROJECT_OVERVIEW.md`** - 專案架構總覽
- **`docs/DATABASE_SUPABASE.md`** - Supabase PostgreSQL 資料庫設計
- **`docs/DEVELOPMENT_STATUS.md`** - 開發狀態和下一步任務
- **`docs/UI_UX_GUIDELINES.md`** - UI/UX 設計規範

### 功能實作文檔
- `docs/STATISTICS_IMPLEMENTATION.md` - 統計功能實作細節

### 操作指南
- `docs/BUILD_RELEASE.md` - Release APK 構建指南
- `docs/GOOGLE_SIGNIN_COMPLETE_SETUP.md` - Google Sign-In 配置

### 腳本文檔
- `scripts/README.md` - 所有腳本的使用說明

### 已歸檔文檔
- `docs/archived/` - 已完成階段性任務或已過時的文檔（供參考）

**💡 提示**：查看最近完成的工作，請參考 `docs/DEVELOPMENT_STATUS.md` 中的「變更記錄」章節

---

## ⚙️ 開發最佳實踐

### 修復 Bug 的流程
1. 理解問題的根源
2. 查看相關代碼
3. 設計解決方案
4. 小步驟修改代碼
5. 測試驗證
6. 更新 `DEVELOPMENT_STATUS.md`

### 實作新功能的流程
1. 閱讀 `PROJECT_OVERVIEW.md` 了解架構
2. 閱讀 `DATABASE_SUPABASE.md` 設計數據結構
3. 創建 TODO List
4. 按照標準流程開發（Model → Service → Controller → UI）
5. 測試並優化
6. 更新 `DEVELOPMENT_STATUS.md`

### 常見錯誤預防
- ✅ 使用持久的 `TextEditingController`
- ✅ 異步操作完成後再關閉 Dialog
- ✅ 保存數據時包含所有必要欄位
- ✅ 查詢時同時查 `trainee_id` 和 `creator_id`（Supabase 用 snake_case）
- ✅ 使用 `WorkoutService.updateRecord()` 更新記錄
- ✅ 動態計算完成狀態
- ✅ 所有 Model 都有 `.fromSupabase()` 方法處理 snake_case 轉換
- ✅ View 層必須透過 Interface 使用服務，不直接操作 Supabase

---

**開始開發前，務必先閱讀 `docs/README.md` 了解文檔結構！**
