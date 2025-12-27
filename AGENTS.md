# StrengthWise - AI Agent 開發指南

> AI 程式碼助手開發規範與最佳實踐

**最後更新**：2024年12月27日 晚上

---

## 📖 文檔導航

**核心文檔**（⭐ 必讀）：
1. **[docs/README.md](docs/README.md)** - 📚 文檔導航（入口）
2. **[docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md)** - 專案架構和技術棧
3. **[docs/DATABASE_SUPABASE.md](docs/DATABASE_SUPABASE.md)** - Supabase PostgreSQL 資料庫設計
4. **[docs/DATABASE_OPTIMIZATION_GUIDE.md](docs/DATABASE_OPTIMIZATION_GUIDE.md)** - 資料庫優化指南
5. **[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)** - 當前開發進度和下一步任務
6. **[docs/UI_UX_GUIDELINES.md](docs/UI_UX_GUIDELINES.md)** - UI/UX 設計規範
7. **[docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)** - 部署指南

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
```

---

## 🗄️ 資料庫重要約定

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

**✅ Phase 1-4 資料庫優化全部完成**（2024-12-27 晚上）

**最新完成**（2024-12-27 深夜）：
1. **全代碼解耦合完成**（Clean Architecture 100%）⭐⭐⭐
   - 統計頁面解耦重構（1,951 行 → 16 個檔案）
   - Booking 頁面重構報告
   - Supabase Services 解耦報告
2. **主線程優化 v3 完成**（徹底消除卡頓）⚡⚡⚡
   - 應用啟動優化（721 frames → <30 frames）
   - 統計預載入優化（312 frames → <10 frames）
   - 智能延遲載入策略
3. 訓練計劃頁面查詢優化（頁面切換秒開）⭐⭐
4. 統計頁面首頁預載入（秒開優化）⭐
5. 概覽統計使用彙總表（效能提升 80%+）⭐
6. 力量進步頁面快取優化
7. 統計查詢 Bug 修復（時間範圍 + 自訂動作）

**效能提升總覽**：
- **應用啟動**：2.5s+ → **200ms** ⚡ 92%+ 🆕
- **主線程卡頓**：721 frames → **<30 frames** ⚡ 96%+ 🆕
- 統計頁面：2-5s → **秒開（<5ms）** ⚡ 99%+
- 頁面切換（快取）：200-500ms → **<5ms** ⚡ 99%+
- 動作搜尋：500ms-2s → **<50ms** ⚡ 90%+
- 訓練計劃：100-200ms → **<20ms** ⚡ 85%+
- 個人記錄：1-3s → **<10ms** ⚡ 95%+

**架構驗證**（完美的 Clean Architecture）：
- ✅ Controller 層使用 Interface：100%
- ✅ View 層使用 Interface：100%
- ✅ 直接 Supabase 調用：0 處
- ✅ **全 lib 目錄代碼解耦合完成** 🆕
  - 統計頁面：16 個模組（主頁面 166 行）
  - Booking 頁面：7 個模組（主頁面 611 行）
  - 所有 Views 頁面：9 個目錄，每個都有獨立 widgets
  - 服務層：9 個服務 → 33 個子模組（7 個目錄）
- ✅ **主線程優化：<30 frames skip** 🆕
- ✅ **解耦重構報告：3 份完整報告** 🆕

詳見：[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)

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
- **[docs/DATABASE_SUPABASE.md](docs/DATABASE_SUPABASE.md)** - Supabase PostgreSQL 資料庫設計
- **[docs/DATABASE_OPTIMIZATION_GUIDE.md](docs/DATABASE_OPTIMIZATION_GUIDE.md)** - 資料庫優化指南
- **[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)** - 開發狀態和下一步任務
- **[docs/UI_UX_GUIDELINES.md](docs/UI_UX_GUIDELINES.md)** - UI/UX 設計規範
- **[docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)** - 部署指南

### 工具腳本
- **[scripts/README.md](scripts/README.md)** - Python 工具腳本使用指南

---

**開始開發前，務必先閱讀 [docs/README.md](docs/README.md) 了解文檔結構！**
