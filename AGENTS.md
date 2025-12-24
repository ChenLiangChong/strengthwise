# StrengthWise - AI Agent 開發指南

> AI 程式碼助手的完整開發指南

**最後更新**：2024年12月25日

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

**最近完成**（2024-12-25）：
- ✅ **Google 登入 & 新用戶默認模板**（2024-12-24 深夜）
  - Google 登入修復（真實設備測試成功）
  - 新用戶自動獲得 5 天專業訓練模板
  - Release APK 構建與安裝（55.8 MB）
  - 文檔整理和清理
- ✅ **訓練模板系統完善**（2024-12-24 晚上）
  - 簡化模板編輯器（移除複雜功能）
  - 解決緩存刷新問題（編輯後立即更新）
  - 完善訓練頁面功能（添加編輯選項、修正導航）
- ✅ **時間權限控制**（2024-12-24 晚上）
  - 過去的訓練：只能查看，不能編輯/刪除
  - 未來的訓練：可以編輯，不能勾選完成
  - 今天的訓練：完整權限
- ✅ **計劃編輯器每組單獨編輯功能**（2024-12-24）
  - 支持 setTargets 欄位
  - 內嵌式編輯 UI
  - 與訓練執行頁面同步
- ✅ **隱藏記錄頁面**（教練-學員版本功能）
- ✅ **簡化首頁**（移除未完成的功能）

**基礎功能 v1.0**：✅ 已完成
- ✅ 訓練模板系統（階段 8）
- ✅ 時間權限控制（階段 9）
- ✅ Google 登入（階段 10）

**已知問題**（需優化）：
詳見 `docs/DEVELOPMENT_STATUS.md`
- 🔴 P0：FloatingActionButton 擋住內容
- 🟡 P0：手機返回鍵導航問題
- 🟡 P0：通知欄位置問題
- 🔵 P1：力量進步頁面顯示小曲線
- 🟡 P1：自訂動作錯誤處理

**下一步**：
1. **P0**：修復已知的 UI/UX 問題（FAB、返回鍵、通知欄）
2. **P1**：力量進步頁面優化（卡片曲線預覽）
3. **P2**：性能優化、錯誤處理完善

**參考文檔**：
- `docs/DEVELOPMENT_STATUS.md` - 了解整體進度和已知問題
- `docs/DATABASE_DESIGN.md` - 查看資料庫結構
- `docs/BUILD_RELEASE.md` - 構建和發布指南
- `docs/GOOGLE_SIGNIN_COMPLETE_SETUP.md` - Google 登入配置

---

## 📚 相關文檔

### 核心文檔
- `docs/README.md` - 文檔導航（必讀）
- `docs/PROJECT_OVERVIEW.md` - 專案架構總覽
- `docs/DEVELOPMENT_STATUS.md` - 開發狀態和已知問題
- `docs/DATABASE_DESIGN.md` - 資料庫設計（794 個動作）
- `docs/STATISTICS_IMPLEMENTATION.md` - 統計功能實作

### 操作指南
- `docs/BUILD_RELEASE.md` - Release APK 構建指南
- `docs/GOOGLE_SIGNIN_COMPLETE_SETUP.md` - Google Sign-In 配置

### 任務文檔
- `docs/cursor_tasks/` - 雙邊平台任務（暫停）

### 腳本文檔
- `scripts/README.md` - 所有腳本的使用說明
- `scripts/generate_professional_training_data.py` - 生成訓練數據

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
