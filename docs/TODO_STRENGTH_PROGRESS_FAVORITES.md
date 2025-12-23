# 力量進步收藏功能設計

> 讓使用者可以標記喜愛的運動，快速查看力量進步

**狀態**：⏳ 待實作  
**優先級**：高  
**預估工作量**：~300-400 行代碼

---

## 📋 需求描述

### 使用者故事
> 作為健身使用者，我想要標記我常做的運動為「收藏」，這樣我就可以快速查看這些運動的力量進步，而不用在一長串動作列表中尋找。

### 核心功能
1. **收藏管理**
   - 使用者可以標記/取消標記喜愛的運動
   - 收藏列表持久化儲存（SharedPreferences 或 Firestore）
   - 提供「管理收藏」功能（編輯/刪除）

2. **顯示邏輯**
   - **有收藏**：在力量進步頁面頂部顯示收藏的運動
   - **無收藏**：顯示 5 層分類選擇頁面

3. **數據過濾**
   - **只顯示有訓練記錄的動作**（至少完成過一次）
   - 按最後訓練日期排序

---

## 🎨 UI 設計

### 情境 A：已有收藏

```
┌─────────────────────────────────────┐
│ 💪 力量進步追蹤                      │
├─────────────────────────────────────┤
│ ⭐ 我的收藏動作        [管理]        │
│                                     │
│ ┌─────────────────────────────┐   │
│ │ 🔴 槓鈴臥推              +16% │   │
│ │ 胸 | 最後訓練: 今天            │   │
│ │ [📈 查看曲線]  [❌ 取消收藏]   │   │
│ └─────────────────────────────┘   │
│                                     │
│ ┌─────────────────────────────┐   │
│ │ 🟢 槓鈴深蹲              +12% │   │
│ │ 腿 | 最後訓練: 2天前           │   │
│ │ [📈 查看曲線]  [❌ 取消收藏]   │   │
│ └─────────────────────────────┘   │
│                                     │
│ [+ 添加更多收藏動作]                │
│                                     │
│ ▼ 所有動作（按部位分類）             │
│ ...                                 │
└─────────────────────────────────────┘
```

### 情境 B：無收藏（首次使用）

```
┌─────────────────────────────────────┐
│ 💪 力量進步追蹤                      │
├─────────────────────────────────────┤
│ 💡 提示                              │
│ 選擇你想追蹤的動作，查看力量進步！   │
│ 你可以標記常用動作為「收藏」快速查看 │
│                                     │
│ 📊 選擇動作                          │
│                                     │
│ ┌─────────────────────┐            │
│ │ 🏋️ 力量訓練    (12)  │ →         │
│ └─────────────────────┘            │
│ ┌─────────────────────┐            │
│ │ 🤸 肌肥大訓練  (8)   │ →         │
│ └─────────────────────┘            │
│ ┌─────────────────────┐            │
│ │ 🏃 肌耐力訓練  (5)   │ →         │
│ └─────────────────────┘            │
│                                     │
│ 💡 數字表示你有訓練記錄的動作數量    │
└─────────────────────────────────────┘
```

### 情境 C：5 層分類導航

```
層級 1: 訓練類型
┌────────────────────┐
│ 🏋️ 力量訓練 (12)   │ → 選擇
└────────────────────┘

層級 2: 身體部位
┌────────────────────┐
│ 🔴 胸部 (3)         │ → 選擇
│ 🟢 腿部 (5)         │
│ 🔵 背部 (4)         │
└────────────────────┘

層級 3: 特定肌群
┌────────────────────┐
│ 整體胸肌 (2)        │ → 選擇
│ 上胸 (1)            │
└────────────────────┘

層級 4: 器材類別
┌────────────────────┐
│ 自由重量 (2)        │ → 選擇
│ 機械式 (1)          │
└────────────────────┘

層級 5: 動作列表
┌────────────────────────────────┐
│ ✅ 槓鈴臥推                [⭐]│
│    最後訓練: 今天                │
│    最大重量: 70kg               │
│    [查看曲線]                    │
├────────────────────────────────┤
│ ✅ 啞鈴臥推                [☆]│
│    最後訓練: 3天前              │
│    最大重量: 24kg               │
│    [查看曲線]                    │
└────────────────────────────────┘

⭐ = 已收藏
☆ = 未收藏（點擊可收藏）
```

---

## 🏗️ 技術實作

### 1. 數據模型

#### FavoriteExercise（收藏動作）
```dart
class FavoriteExercise {
  final String exerciseId;
  final String exerciseName;
  final String bodyPart;
  final DateTime lastTrainingDate;
  final double maxWeight;
  
  FavoriteExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.bodyPart,
    required this.lastTrainingDate,
    required this.maxWeight,
  });
  
  Map<String, dynamic> toMap();
  factory FavoriteExercise.fromMap(Map<String, dynamic> map);
}
```

### 2. 服務層

#### FavoritesService
```dart
class FavoritesService {
  // 儲存方式：SharedPreferences（簡單）或 Firestore（跨設備同步）
  
  /// 獲取收藏列表
  Future<List<String>> getFavoriteExerciseIds(String userId);
  
  /// 添加收藏
  Future<void> addFavorite(String userId, String exerciseId);
  
  /// 移除收藏
  Future<void> removeFavorite(String userId, String exerciseId);
  
  /// 檢查是否已收藏
  Future<bool> isFavorite(String userId, String exerciseId);
}
```

#### StatisticsService 擴展
```dart
// 在 StatisticsService 中添加新方法

/// 獲取有訓練記錄的動作列表（用於分類導航）
Future<List<ExerciseWithStats>> getExercisesWithRecords(
  String userId,
  {
    String? trainingType,
    String? bodyPart,
    String? specificMuscle,
    String? equipmentCategory,
  }
);

/// 獲取收藏動作的力量進步
Future<List<ExerciseStrengthProgress>> getFavoriteExercisesProgress(
  String userId,
  List<String> favoriteExerciseIds,
  TimeRange timeRange,
);
```

### 3. UI 組件

#### StrengthProgressPage（重構）
```dart
class StrengthProgressPage extends StatefulWidget {
  // 分為兩種模式：
  // 1. 收藏模式（顯示收藏動作）
  // 2. 選擇模式（5 層分類導航）
}

// 子組件
- FavoriteExercisesList（收藏列表）
- ExerciseSelectionNavigator（5 層導航）
- ExerciseStrengthChart（力量曲線圖）
```

---

## 📝 實作步驟

### 階段 1：基礎功能（~2-3 小時）
1. ✅ 創建 `FavoriteExercise` 模型
2. ✅ 實作 `FavoritesService`（使用 SharedPreferences）
3. ✅ 註冊到 Service Locator
4. ✅ 創建收藏列表 UI
5. ✅ 實作添加/移除收藏功能

### 階段 2：5 層分類導航（~3-4 小時）
1. ✅ 實作 `getExercisesWithRecords` 方法
2. ✅ 創建 5 層導航 UI 組件
3. ✅ 實作層級之間的導航邏輯
4. ✅ 數據過濾（只顯示有記錄的動作）
5. ✅ 添加動作統計信息（最後訓練、最大重量）

### 階段 3：整合和優化（~1-2 小時）
1. ✅ 整合收藏模式和選擇模式
2. ✅ 添加「管理收藏」功能
3. ✅ 優化 UI 和交互體驗
4. ✅ 測試和 bug 修復

---

## 💾 數據儲存方案

### 方案 A：SharedPreferences（推薦）
**優點**：
- 簡單快速
- 本地儲存，無需網路
- 適合個人使用

**缺點**：
- 不能跨設備同步
- 數據量有限制

**實作**：
```dart
// 儲存格式：JSON 字串數組
{
  "user_123_favorite_exercises": [
    "exercise_id_1",
    "exercise_id_2",
    "exercise_id_3"
  ]
}
```

### 方案 B：Firestore（進階）
**優點**：
- 跨設備同步
- 數據持久化
- 可擴展性強

**缺點**：
- 需要網路連接
- 稍微複雜

**實作**：
```dart
// Firestore 結構
users/{userId}/favorites/{exerciseId}
{
  exerciseId: string,
  exerciseName: string,
  addedAt: timestamp,
  lastViewedAt: timestamp,
}
```

**建議**：先實作方案 A（SharedPreferences），未來可選擇性升級到方案 B。

---

## 🎯 成功指標

### 功能完整性
- [x] 可以添加/移除收藏
- [x] 收藏列表持久化
- [x] 5 層分類導航可用
- [x] 只顯示有記錄的動作
- [x] 可以查看力量進步曲線

### 使用者體驗
- [x] 操作流暢（無卡頓）
- [x] 界面清晰（易於理解）
- [x] 反饋及時（收藏成功提示）
- [x] 導航直觀（麵包屑導航）

### 性能
- [x] 加載速度 < 1 秒
- [x] 分類導航響應時間 < 200ms
- [x] 收藏操作響應時間 < 100ms

---

## 📚 參考文檔

- `docs/DEVELOPMENT_STATUS.md` - 開發進度
- `docs/DATABASE_DESIGN.md` - 數據庫設計
- `docs/STATISTICS_IMPLEMENTATION.md` - 統計功能實作
- `lib/views/pages/statistics_page_v2.dart` - 當前統計頁面

---

## 🚀 開始實作

**準備好開始了嗎？** 

執行以下命令創建分支：
```bash
git checkout -b feature/strength-progress-favorites
```

然後按照上述步驟逐步實作！💪

