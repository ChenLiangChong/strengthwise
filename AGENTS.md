# StrengthWise - AI Agent 開發指南

> AI 程式碼助手的完整開發指南

**最後更新**：2024年12月23日

---

## 📖 文檔導航

開始開發前，請先閱讀以下文檔：

1. **[docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md)** - 專案架構和技術棧
2. **[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)** - 當前開發進度
3. **[docs/DATABASE_DESIGN.md](docs/DATABASE_DESIGN.md)** - Firestore 資料庫設計

---

## 🚨 核心開發規則（必須遵守）

### 1. 不破壞現有功能 ⭐⭐⭐
- ✅ 修改代碼前先測試現有功能
- ✅ 小步提交，確保每次修改後應用可編譯
- ❌ 不要刪除或破壞現有功能

### 2. 型別安全 ⭐⭐⭐
- ✅ **必須**：所有 Firestore 操作透過 Model 類別的 `.fromMap()` 和 `.toMap()` 方法
- ❌ **禁止**：直接操作 `Map<String, dynamic>`

```dart
// ✅ 正確
final user = UserModel.fromMap(doc.data()!);
await firestore.collection('users').doc(uid).set(user.toMap());

// ❌ 錯誤
await firestore.collection('users').doc(uid).set({'name': 'John'});
```

### 3. 依賴注入 ⭐⭐
- ✅ 所有服務透過 `serviceLocator` 獲取
- ✅ 控制器透過建構函式注入依賴

```dart
// ✅ 正確
final workoutController = serviceLocator<IWorkoutController>();
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

---

## 🗄️ 資料庫重要約定

### 1. workoutPlans 集合（統一）

**架構**：
```
workoutPlans（統一集合）
├── completed: false  → 未完成的訓練計劃
└── completed: true   → 已完成的訓練記錄
```

**必須包含的欄位**：
```dart
{
  'userId': userId,      // 向後相容
  'traineeId': userId,   // 受訓者 ID
  'creatorId': userId,   // 創建者 ID
  'completed': bool,     // 完成狀態
  ...
}
```

### 2. 查詢訓練計劃時

**必須同時查詢兩個欄位**：
```dart
// 查詢作為受訓者的計劃
.where('traineeId', isEqualTo: userId)

// 如果是教練，也查詢作為創建者的計劃
if (isCoach) {
  .where('creatorId', isEqualTo: userId)
}
```

### 3. 避免複雜查詢

```dart
// ❌ 需要 Firestore 複合索引
.where('traineeId', isEqualTo: userId)
.orderBy('updatedAt', descending: true)

// ✅ 改用客戶端排序
.where('traineeId', isEqualTo: userId)
.get()
// 然後在客戶端排序
templates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
```

---

## 🚀 開發流程

### 新增功能的標準流程

```
1. 設計 Model (lib/models/)
   ↓
2. 創建 Service 介面 (lib/services/interfaces/)
   ↓
3. 實作 Service (lib/services/)
   ↓
4. 註冊到 Service Locator (service_locator.dart)
   ↓
5. 創建 Controller (lib/controllers/)
   ↓
6. 建立 UI (lib/views/pages/)
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

**目標**：完善單機版功能

**最近完成**（2024-12-23）：
- ✅ 動作分類系統升級（794 個動作重新分類）
- ✅ 新動作瀏覽 UI（5 層專業分類導航）
- ✅ 身體部位數據清理（合併重複項）

**當前任務**：實作統計功能
- 訓練頻率統計
- 訓練量趨勢圖表
- 個人最佳記錄（PR）

**參考文檔**：
- `docs/DEVELOPMENT_STATUS.md` - 了解整體進度
- `docs/DATABASE_DESIGN.md` - 查看新的動作分類結構
- `docs/STATISTICS_IMPLEMENTATION.md` - 實作細節

---

## 📚 相關文檔

### 核心文檔
- `docs/README.md` - 文檔導航
- `docs/PROJECT_OVERVIEW.md` - 專案總覽
- `docs/DEVELOPMENT_STATUS.md` - 開發狀態（包含最新的資料庫升級記錄）
- `docs/DATABASE_DESIGN.md` - 資料庫設計（包含新的動作分類結構）

### 任務文檔
- `docs/STATISTICS_IMPLEMENTATION.md` - 統計功能實作
- `docs/cursor_tasks/` - 雙邊平台任務（暫停）

### 腳本文檔
- `scripts/README.md` - 所有腳本的使用說明
- `scripts/analyze_body_parts.py` - 身體部位分析
- `scripts/merge_body_parts.py` - 身體部位合併
- `scripts/reclassify_exercises.py` - 動作重新分類
- `scripts/update_exercise_classification.py` - 更新分類到 Firestore

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
2. 閱讀 `DATABASE_DESIGN.md` 設計數據結構
3. 創建 TODO List
4. 按照標準流程開發（Model → Service → Controller → UI）
5. 測試並優化
6. 更新 `DEVELOPMENT_STATUS.md`

### 常見錯誤預防
- ✅ 使用持久的 `TextEditingController`
- ✅ 異步操作完成後再關閉 Dialog
- ✅ 保存數據時包含所有必要欄位
- ✅ 查詢時同時查 `traineeId` 和 `creatorId`
- ✅ 使用 `update()` 而不是 `add()` 更新文檔
- ✅ 動態計算完成狀態

---

**開始開發前，務必先閱讀 `docs/README.md` 了解文檔結構！**
