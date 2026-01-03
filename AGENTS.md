# StrengthWise - AI Agent 開發指南

> AI 程式碼助手開發規範與最佳實踐

**最後更新**：2026年1月2日 - v2.2 完成 ✅

---

## 📌 文檔說明

**本文檔用途**：
- ✅ **開發規範**：程式碼風格、架構規則、最佳實踐
- ✅ **技術指南**：日期時間處理、資料庫查詢、錯誤處理
- ✅ **文檔導航**：指向相關文檔的連結

**本文檔不包含**：
- ❌ **開發進度**：請查看 `docs/DEVELOPMENT_STATUS.md`
- ❌ **功能特色列表**：請查看 `docs/DEVELOPMENT_STATUS.md`
- ❌ **詳細測試結果**：請查看 `docs/DEVELOPMENT_STATUS.md`
- ❌ **待完成任務**：請查看 `docs/DEVELOPMENT_STATUS.md`

**維護原則**：保持本文檔專注於「如何開發」，而非「開發了什麼」

---

## 📖 文檔導航

**核心文檔**（⭐ 必讀）：
1. **[docs/README.md](docs/README.md)** - 📚 文檔導航（入口）
2. **[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)** ⭐⭐⭐ **精簡版**（800+ 行）
   - v1.0 單機版完成 ✅
   - v2.0 Phase 1-4 全部完成 ✅
   - v2.1 訓練時間範圍完成 ✅（2025-01-02）
   - v2.2 時區統一化完成 ✅（2025-01-02）⭐⭐⭐
   - Migrations 優化完成 ✅
   - 預約系統 UI 優化完成 ✅
   - UX 重構完成 ✅
   - **詳細任務清單**（性能監控、UX 優化、Bug 檢查）
   - 清晰結構：已完成摘要 + 下一步計劃 + 未來規劃
3. **[docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md)** - 專案架構和技術棧（精簡版）
4. **[docs/DATABASE_SUPABASE.md](docs/DATABASE_SUPABASE.md)** - Supabase PostgreSQL 資料庫設計（完整技術參考）
5. **[docs/SAAS_PLATFORM_ROADMAP.md](docs/SAAS_PLATFORM_ROADMAP.md)** - 完整 SaaS 計劃（Phase 1-5，精簡版）
6. **[docs/DATETIME_UTILS_GUIDE.md](docs/DATETIME_UTILS_GUIDE.md)** - 時間轉換工具指南（v2.2 完整）⭐

**UI/UX 與部署**：
- **[docs/UI_UX_GUIDELINES.md](docs/UI_UX_GUIDELINES.md)** - UI/UX 設計規範
- **[docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)** - 部署指南

**工具腳本**：
- **[scripts/README.md](scripts/README.md)** - Python 工具腳本（含測試帳號）
  - 資料庫下載工具（v2 全新版本）⭐
  - Migrations 優化工具（已歸檔）

**已歸檔文檔**：
- **[docs/archived/](docs/archived/)** - 已完成的重構報告、優化報告、任務文檔
- **[docs/archived/phase1/](docs/archived/phase1/)** - Phase 1 實作指南（已完成）

---

## 🚨 核心開發規則

### 1. 不破壞現有功能 ⭐⭐⭐
- ✅ 修改代碼前先測試
- ✅ 小步提交，確保可編譯
- ❌ 不刪除或破壞現有功能

### 2. 型別安全 ⭐⭐⭐
- ✅ **必須**：透過 Model 的 `.fromSupabase()` 和 `.toMap()` 操作資料庫
- ❌ **禁止**：直接操作 `Map<String, dynamic>`

```dart
// ✅ 正確
final record = WorkoutRecord.fromSupabase(data);
await workoutService.createRecord(record);

// ❌ 錯誤
await supabase.from('workout_plans').insert({'title': 'Test'});
```

### 3. 依賴注入 ⭐⭐⭐
- ✅ **必須**：透過 `serviceLocator` + Interface 使用服務
- ❌ **禁止**：直接實例化服務類別

```dart
// ✅ 正確
final workoutService = serviceLocator<IWorkoutService>();

// ❌ 錯誤
final service = WorkoutServiceSupabase();
```

### 4. 錯誤處理 ⭐⭐
- ✅ 使用 `ErrorHandlingService` 記錄錯誤
- ✅ 控制器層轉換為友善訊息

### 5. 註解規範 ⭐⭐
- ✅ **必須**：關鍵邏輯加**繁體中文註解**
- ✅ **必須**：公共方法使用 `///` Dart Doc 註解
- ✅ **必須**：UI 文字使用繁體中文

### 6. 查詢效能規範 ⭐⭐⭐

**禁止事項**：
- ❌ 使用 `SELECT *`（必須明確指定欄位）
- ❌ 使用 Offset 分頁（深層分頁效能差）
- ❌ N+1 查詢問題（循環中查詢）
- ❌ `COUNT(*)` exact（全表掃描）

**必須遵守**：
- ✅ 使用 Cursor-based 分頁（時間複雜度 O(1)）
- ✅ 為 RLS 欄位建立索引
- ✅ 使用覆蓋索引（Index-Only Scan）
- ✅ JSONB 使用 GIN 索引
- ✅ TSTZRANGE 使用 GiST 索引 + 範圍重疊運算子（`ov`）⭐

```dart
// ❌ 錯誤：SELECT * + Offset 分頁
final data = await supabase
  .from('workout_plans')
  .select()
  .range(100, 119);

// ✅ 正確：明確欄位 + Cursor 分頁
final data = await supabase
  .from('workout_plans')
  .select('id, title, scheduled_date, completed')
  .lt('scheduled_date', lastCursor)
  .order('scheduled_date', ascending: false)
  .limit(20);

// ✅ 正確：TSTZRANGE 範圍查詢（使用 PostgreSQL 範圍重疊運算子）
final data = await supabase
  .from('availability_slots')
  .select('id, coach_id, time_range, is_available')
  .filter('time_range', 'ov', '[${startDate.toIso8601String()},${endDate.toIso8601String()})')
  .order('time_range', ascending: true);
```

### 7. 日期時間處理規範 ⭐⭐⭐

**統一工具類**：所有時間轉換必須使用 `DateTimeUtils`（`lib/utils/datetime_utils.dart`）

#### 核心規則（v2.2 更新）

1. **所有時間解析使用 `parseIsoTimestamp()`**
   ```dart
   import 'package:strengthwise/utils/datetime_utils.dart';
   
   // ✅ 正確
   final dt = DateTimeUtils.parseIsoTimestamp(json['created_at']);
   
   // ❌ 錯誤：直接使用 DateTime.parse()
   final dt = DateTime.parse(json['created_at']);
   ```

2. **所有時間格式化使用 `formatToUtcIso()`**
   ```dart
   // ✅ 正確
   'created_at': DateTimeUtils.formatToUtcIso(DateTime.now())
   
   // ❌ 錯誤：直接使用 .toUtc().toIso8601String()
   'created_at': DateTime.now().toUtc().toIso8601String()
   ```

3. **TSTZRANGE 處理**（Model 層）
   ```dart
   // 解析
   final range = DateTimeUtils.parseTstzRange(json['time_range']);
   
   // 格式化
   'time_range': DateTimeUtils.formatToTstzRange(startTime, endTime)
   ```

4. **UTC 日期比較**（Service 層統計過濾）
   ```dart
   // ✅ 正確：使用工具類
   if (DateTimeUtils.isWithinUtcDateRange(trainingDate, startDate, endDate)) {
     // 在範圍內
   }
   
   // ❌ 錯誤：手動實作（會導致時區問題）
   final utcDate = DateTime.utc(date.toUtc().year, date.toUtc().month, ...);
   ```

#### 時區處理原則 ⭐

**v2.2 架構**：Model 中所有 `DateTime` 都是本地時間

```dart
// UI 層
Text('${model.createdAt.hour}')  // 直接用！不需要 .toLocal()

// Model 層（fromSupabase）
createdAt: DateTimeUtils.parseIsoTimestamp(json['created_at'])  // 返回本地時間

// Service 層（toSupabase）
'created_at': DateTimeUtils.formatToUtcIso(createdAt)  // 轉為 UTC 儲存
```

訓練記錄按 **UTC 日期** 分組，避免時區轉換導致日期改變：

```dart
// 問題：
// 數據庫：2025-12-27T16:00:45Z (UTC)
// 本地：  2025-12-28 00:00:45 (UTC+8)
// 結果：12/27 的訓練被錯誤地算成 12/28！❌

// 解決：使用 DateTimeUtils.isWithinUtcDateRange()
// 正確：12/27 UTC 不在 12/28-12/29 UTC 範圍內 ✅
```

#### 常見錯誤

- ❌ 直接使用 `DateTime.parse()` 解析時間
- ❌ 直接使用 `.toUtc().toIso8601String()` 格式化
- ❌ 在 Model 中重複實作時間轉換邏輯
- ❌ UI 層使用 `.toLocal()` 轉換（Model 已是本地時間）
- ❌ 使用本地時間比較導致時區偏移

#### 完整文檔

詳見 `docs/DATETIME_UTILS_GUIDE.md`（包含完整 API 列表、使用範例、v2.2 統一化記錄）

---

## 🗄️ 資料庫重要約定

### 0. Migrations 管理（⭐ 2025-01-02 更新）

**新的 Migrations 結構**（從 19 個優化為 8 個）：
- ✅ **migrations/README.md** - 完整說明文檔
- ✅ 清晰的版本劃分（v1.0 vs v2.0 vs v2.1）
- ✅ 舊檔案已歸檔至 `migrations/archived_original/`

**執行順序**：
```
# v1.0 核心（4 個檔案）
001_v1_core_tables.sql          # 基礎表格
002_v1_initial_data.sql         # 794 個動作
003_v1_enhancements.sql         # 功能增強
004_v1_optimization.sql         # 統計優化

# v2.0 功能（3 個檔案）
005_v2_phase1_coaching.sql      # 教練學員系統
006_v2_phase2_appointments.sql  # 預約系統
007_v2_phase3_notes.sql         # 視覺化筆記

# v2.1 功能（1 個檔案）⭐ 新增
008_workout_time_range.sql      # 訓練時間範圍（TSTZRANGE）
```

詳見：**[migrations/README.md](migrations/README.md)**

### 1. workout_plans 表格（統一）

**架構**：
```
workout_plans（PostgreSQL 表格）
├── completed: false  → 未完成的訓練計劃
└── completed: true   → 已完成的訓練記錄
```

**必須包含欄位**：
```dart
{
  'id': TEXT,              // Firestore 相容 ID（20 字符）
  'user_id': UUID,
  'trainee_id': UUID,      // 受訓者 ID
  'creator_id': UUID,      // 創建者 ID
  'completed': bool,
  'scheduled_date': TIMESTAMPTZ,
  'exercises': JSONB,
}
```

### 2. 使用 Service Interface

**重要**：所有 View 層和 Controller 層必須透過 Interface 使用服務

```dart
// ✅ 正確
final workoutService = serviceLocator<IWorkoutService>();
await workoutService.createRecord(record);

// ❌ 禁止
await Supabase.instance.client.from('workout_plans').insert(...);
```

### 3. Snake_case 轉換

Supabase 使用 `snake_case`，Dart 使用 `camelCase`：

```dart
factory UserModel.fromSupabase(Map<String, dynamic> json) {
  return UserModel(
    uid: json['id'] as String,
    displayName: json['display_name'] as String?,
    isCoach: json['is_coach'] as bool? ?? false,
  );
}
```

---

## 🚀 開發流程

### 新增功能標準流程

```
1. 設計 Model (lib/models/)
   ├── 實作 fromSupabase()
   └── 實作 toMap()
   ↓
2. 創建 Service Interface (lib/services/interfaces/)
   ↓
3. 實作 Service (lib/services/)
   ↓
4. 註冊到 Service Locator
   ↓
5. 創建 Controller (lib/controllers/)
   ├── 繼承 ChangeNotifier
   └── 透過 Interface 注入依賴
   ↓
6. 建立 UI (lib/views/pages/)
   ↓
7. 測試並驗證
```

---

## 🎯 當前開發狀態

**專案版本**：v2.2（時區統一化完成）

**完成階段**：
- ✅ v1.0 單機版（訓練計劃、統計、身體數據）
- ✅ v2.0 教練學員系統（Phase 1-4 完整）
- ✅ v2.1 訓練時間範圍功能
- ✅ v2.2 時區統一化

**架構狀態**：
- ✅ Clean Architecture 100% 解耦
- ✅ 效能優化完成（啟動 <200ms，卡頓 -96%）
- ✅ 型別安全（所有操作透過 Model）
- ✅ 依賴注入（100% 透過 Interface）

**詳細開發進度與下一步計劃**：請查看 **[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)**

---

## 🔍 常見問題排查

### 服務未初始化
```dart
await setupServiceLocator();
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

---

## ⚙️ 開發最佳實踐

### 修復 Bug 流程
1. 理解問題根源
2. 查看相關代碼
3. 設計解決方案
4. 小步驟修改
5. 測試驗證
6. 更新文檔

### 常見錯誤預防
- ✅ 使用持久的 `TextEditingController`
- ✅ 異步操作完成後再關閉 Dialog
- ✅ 查詢時同時查 `trainee_id` 和 `creator_id`
- ✅ 使用 `WorkoutService.updateRecord()` 更新記錄
- ✅ View 層必須透過 Interface 使用服務

---

## 📚 相關文檔

### 核心文檔
- **[docs/README.md](docs/README.md)** - 📚 文檔導航（入口）
- **[docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md)** - 專案架構總覽
- **[docs/DATABASE_SUPABASE.md](docs/DATABASE_SUPABASE.md)** - Supabase PostgreSQL 資料庫設計（完整）
- **[docs/DATABASE_OPTIMIZATION_GUIDE.md](docs/DATABASE_OPTIMIZATION_GUIDE.md)** - 資料庫優化指南
- **[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)** - 開發狀態和下一步任務（含性能優化總覽）
- **[docs/UI_UX_GUIDELINES.md](docs/UI_UX_GUIDELINES.md)** - UI/UX 設計規範
- **[docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)** - 部署指南

### 已歸檔文檔（供參考）
- **[docs/archived/README.md](docs/archived/README.md)** - 歸檔文檔導航
- **重構與優化報告**：主線程優化、性能瓶頸分析、架構重構指南
- **階段性任務文檔**：個人資料優化、通知系統、模板除錯

### 工具腳本
- **[scripts/README.md](scripts/README.md)** - Python 工具腳本使用指南
  - 資料庫下載工具（v2 全新版本）
  - Migrations 優化工具（已歸檔）

---

## 🎯 下一步工作

**詳細開發規劃與待完成任務**：請查看 **[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)**

---

**開始開發前，務必先閱讀 [docs/README.md](docs/README.md) 了解文檔結構！**
