# StrengthWise - AI Agent 開發指南

> AI 程式碼助手的完整開發指南

**最後更新**：2024年12月25日

---

## 📖 文檔導航

開始開發前，請先閱讀以下文檔：

1. **[docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md)** - 專案架構和技術棧
2. **[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)** - 當前開發進度
3. **[docs/DATABASE_DESIGN.md](docs/DATABASE_DESIGN.md)** - Firestore 資料庫設計
4. **[docs/UI_UX_GUIDELINES.md](docs/UI_UX_GUIDELINES.md)** - UI/UX 設計規範（⭐ 新增）

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

### 6. 文檔管理規範 ⭐⭐
- ❌ **禁止**：非必要情況下產生新的 Markdown 文檔
- ✅ **必須**：新增文檔前先確認是否可以更新現有文檔
- ✅ **必須**：臨時性、實驗性文檔在任務完成後應清理

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

**目標**：🎨 UI/UX 全面重設計（2024-12-25 開始）

**當前階段**：✅ **配色系統最終定案**（準備進入 Week 3）

### 📋 4 週執行計劃

| 週次 | 階段 | 狀態 | 交付物 |
|------|------|------|--------|
| ~~Week 1~~ | ⚙️ 基礎建設 | ✅ **已完成** | 可切換深淺模式的主題系統 |
| ~~Week 2~~ | 🎯 核心重構 | ✅ **已完成** | 全新的訓練記錄體驗 + 配色標準化 |
| **Week 3** | 🗺️ 導航與框架 | ⏳ **準備開始** | 完整的 App 框架 |
| Week 4 | ✨ 細節打磨 | ⏳ 待開始 | 市場級品質 UI/UX |

**✅ Week 2 已完成**：
- ✅ 卡片式訓練記錄 UI（ExerciseCard + SetInputRow）
- ✅ JetBrains Mono 等寬字體整合
- ✅ 配色系統最終定案（設計團隊簽署）
- ✅ 全 App 配色標準化（8 個核心頁面）
- ✅ 移除所有硬編碼顏色（~70 處修正）

**🎉 重大里程碑**：
從「通用 App」成功轉型為「品牌 App」，完成「打熬」專屬配色系統建立。

**設計文檔**：
- `docs/UI_UX_GUIDELINES.md` - 完整 UI/UX 規範
- `docs/ui_prototype.html` - 互動原型

---

**最近完成**（2024-12-25）：
- ✅ **配色系統最終定案**（2024-12-25 晚上）⭐⭐⭐
  - 設計團隊正式簽署配色決策
  - 實施 Sky-400 電光藍（深色主色）
  - 實施 Slate-50 極致乾淨背景（淺色）
  - 全 App 配色標準化（8 個核心頁面，~70 處修正）
  - 從「通用 App」到「品牌 App」的轉型完成
- ✅ **Week 2 核心組件**（2024-12-25）
  - ExerciseCard + SetInputRow 卡片式 UI
  - JetBrains Mono 等寬字體整合
  - 智能數字格式化（20 而不是 20.000）
  - WorkoutExecutionPage 完整重構
- ✅ **Week 1 主題系統**（2024-12-25）
  - Titanium Blue 配色方案
  - Light/Dark/System 三種模式
  - 完整的 Material 3 實作
- ✅ **UI/UX 設計系統建立**（2024-12-25）
  - 創建完整設計規範文檔（20,000+ 字）
  - 定義 Kinetic 設計系統
  - HTML 互動原型與 Flutter 實作指南
  - 4 週執行路徑圖
- ✅ **Google 登入 & 新用戶默認模板**（2024-12-24 深夜）
  - Google 登入修復（真實設備測試成功）
  - 新用戶自動獲得 5 天專業訓練模板
  - Release APK 構建與安裝（55.8 MB）
- ✅ **訓練模板系統完善**（2024-12-24 晚上）
  - 簡化模板編輯器、解決緩存刷新問題
- ✅ **時間權限控制**（2024-12-24 晚上）
  - 過去/現在/未來訓練的權限控制

**基礎功能 v1.0**：✅ 已完成
- ✅ 訓練模板系統（階段 8）
- ✅ 時間權限控制（階段 9）
- ✅ Google 登入（階段 10）

**已順延的任務**：
以下任務待 UI/UX 重設計完成後處理（詳見 `docs/DEVELOPMENT_STATUS.md`）
- FloatingActionButton 擋住內容 → Week 3 解決
- 手機返回鍵導航問題 → Week 3 解決
- 通知欄位置問題 → Week 4 解決
- 力量進步頁面優化 → UI 重構後評估
- 自訂動作錯誤處理 → UI 重構後優化

**參考文檔**：
- `docs/DEVELOPMENT_STATUS.md` - 了解整體進度和已知問題
- `docs/DATABASE_DESIGN.md` - 查看資料庫結構
- `docs/UI_UX_GUIDELINES.md` - UI/UX 設計規範（⭐ 新增）
- `docs/BUILD_RELEASE.md` - 構建和發布指南
- `docs/GOOGLE_SIGNIN_COMPLETE_SETUP.md` - Google 登入配置

---

## 📚 相關文檔

### 核心文檔
- `docs/README.md` - 文檔導航（必讀）
- `docs/PROJECT_OVERVIEW.md` - 專案架構總覽
- `docs/DEVELOPMENT_STATUS.md` - 開發狀態和已知問題
- `docs/DATABASE_DESIGN.md` - 資料庫設計（794 個動作）
- `docs/UI_UX_GUIDELINES.md` - UI/UX 設計規範（⭐ 新增）
- `docs/STATISTICS_IMPLEMENTATION.md` - 統計功能實作

### 操作指南
- `docs/BUILD_RELEASE.md` - Release APK 構建指南
- `docs/GOOGLE_SIGNIN_COMPLETE_SETUP.md` - Google Sign-In 配置

### 任務文檔
- `docs/cursor_tasks/` - 雙邊平台任務（暫停）

### 腳本文檔
- `scripts/README.md` - 所有腳本的使用說明
- `scripts/generate_professional_training_data.py` - 生成訓練數據

### 分析文檔
- `analysis/README.md` - 專案分析文檔
- `analysis/firestore_analysis.md` - Firestore 資料庫分析

### 其他重要文檔
- `PROJECT_SUMMARY.md` - 專案總結
- `README.md` - 專案首頁

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
