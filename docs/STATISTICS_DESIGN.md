# StrengthWise - 統計功能設計文檔

> 基於專業 5 層動作分類系統的統計功能設計

**最後更新**：2024年12月23日

---

## 🚨 核心問題

### 現況分析

**動作分類結構**（`exercise` 集合）：
```javascript
{
  id: "ex001",
  name: "上斜啞鈴臥推",
  
  // 新的專業 5 層分類
  trainingType: "重訓",              // 訓練類型
  bodyPart: "胸",                    // 身體部位
  specificMuscle: "上胸",            // 特定肌群
  equipmentCategory: "自由重量",      // 器材類別
  equipmentSubcategory: "啞鈴",      // 器材子類別
}
```

**訓練記錄結構**（`workoutPlans` 集合中的 `exercises`）：
```javascript
{
  exerciseId: "ex001",
  name: "上斜啞鈴臥推",
  
  // ⚠️ 問題：只有舊欄位，沒有新的 5 層分類！
  bodyParts: ["胸"],                 // 舊欄位
  equipment: "啞鈴",                 // 舊欄位
  
  sets: 3,
  reps: 10,
  weight: 20,
}
```

### 問題所在

**訓練記錄中缺少新的分類信息**，導致無法進行精細統計！

例如：
- ❌ 無法統計「上胸 vs 中胸 vs 下胸」的訓練量
- ❌ 無法統計「自由重量 vs 機械式 vs 徒手」的訓練佔比
- ❌ 無法統計「啞鈴 vs 槓鈴」的使用頻率

---

## 💡 解決方案

### 方案 A：統計時動態查詢（推薦）⭐

**優點**：
- ✅ 不需要修改現有數據結構
- ✅ 始終使用最新的動作分類
- ✅ 如果動作分類更新，統計會自動反映

**缺點**：
- ⚠️ 需要額外的 Firestore 查詢
- ⚠️ 性能稍差（可用快取優化）

**實作方式**：
```dart
// 統計時，先批量載入所有動作的分類信息
Map<String, Exercise> exerciseMap = {};

Future<void> loadExerciseClassifications(List<String> exerciseIds) async {
  // 批量查詢動作信息（使用快取）
  for (var id in exerciseIds) {
    if (!exerciseMap.containsKey(id)) {
      final exercise = await exerciseService.getExerciseById(id);
      exerciseMap[id] = exercise;
    }
  }
}

// 統計時使用動作分類
Map<String, double> calculateVolumeBySpecificMuscle(List<WorkoutPlan> plans) {
  Map<String, double> stats = {};
  
  for (var plan in plans) {
    for (var workoutEx in plan.exercises) {
      // 從 exerciseMap 獲取完整分類
      final exercise = exerciseMap[workoutEx.exerciseId];
      if (exercise != null) {
        final muscle = exercise.specificMuscle;
        final volume = workoutEx.weight * workoutEx.reps * workoutEx.sets;
        stats[muscle] = (stats[muscle] ?? 0) + volume;
      }
    }
  }
  
  return stats;
}
```

### 方案 B：在訓練記錄中保存完整分類

**優點**：
- ✅ 查詢快速，不需要額外查詢
- ✅ 保留歷史分類（即使動作分類後來改變）

**缺點**：
- ❌ 需要修改 `WorkoutExercise` Model
- ❌ 需要更新所有創建訓練計劃的代碼
- ❌ 資料冗餘

---

## 🎯 統計功能設計

### 統計維度設計

基於我們的 5 層分類，以下是有價值的統計維度：

#### 第 1 層：訓練類型統計 ⭐⭐
**問題**：我的訓練是否平衡？重訓、有氧、伸展的比例如何？

**統計內容**：
- 重訓 vs 有氧 vs 伸展的訓練次數
- 各類型的訓練量（Volume）
- 各類型的訓練時長

**呈現方式**：
```
本月訓練類型分布
┌─────────────────┐
│ 重訓    85%  ██████████████████  │
│ 有氧    10%  ████                │
│ 伸展     5%  ██                  │
└─────────────────┘
```

#### 第 2 層：身體部位統計 ⭐⭐⭐（最重要）
**問題**：我的訓練是否全面？有沒有忽略某些肌群？

**統計內容**：
- 各身體部位的訓練次數
- 各身體部位的訓練量（重量 × 次數 × 組數）
- 訓練頻率（每週訓練幾次）

**呈現方式**：餅狀圖 + 建議
```
本月肌群訓練分布
  
  胸  20%    背  25%
  肩  15%    腿  30%
  手  10%
  
💡 建議：核心訓練較少，建議增加訓練頻率
```

#### 第 3 層：特定肌群統計 ⭐⭐（進階）
**問題**：胸部訓練中，上胸、中胸、下胸是否均衡？

**統計內容**：
- 同一身體部位下的特定肌群分布
- 例如：胸部 → 上胸/中胸/下胸/整體

**呈現方式**：
```
胸部訓練細分（本月）
┌─────────────────────┐
│ 上胸  40%    12 次   │
│ 中胸  35%    10 次   │
│ 下胸  25%     8 次   │
└─────────────────────┘
```

#### 第 4 層：器材類別統計 ⭐⭐
**問題**：我的訓練方式是否多樣化？

**統計內容**：
- 自由重量 vs 機械式 vs 徒手的訓練佔比
- 各器材類別的訓練量

**呈現方式**：
```
訓練方式分布（本月）
┌──────────────────────┐
│ 自由重量  45%  📦      │
│ 機械式    35%  🏋️      │
│ 徒手      20%  💪      │
└──────────────────────┘

💡 建議：加入更多徒手訓練增加功能性
```

#### 第 5 層：器材子類別統計 ⭐（細節）
**問題**：我偏好哪種器材？

**統計內容**：
- 啞鈴 vs 槓鈴 vs Cable 的使用頻率
- 幫助用戶了解訓練偏好

**呈現方式**：
```
器材使用統計（本月）
┌──────────────────┐
│ 啞鈴    25 次    │
│ 槓鈴    15 次    │
│ Cable   10 次    │
└──────────────────┘
```

---

## 📊 完整統計頁面架構

### 頁面結構（Tab 切換）

```
統計頁面
├── Tab 1: 概覽 ⭐⭐⭐
│   ├── 訓練頻率卡片（本週/本月次數）
│   ├── 訓練量趨勢圖（折線圖）
│   ├── 身體部位分布（餅狀圖）★ 最重要
│   └── 連續訓練天數
│
├── Tab 2: 肌群分析 ⭐⭐⭐
│   ├── 身體部位訓練量統計
│   ├── 特定肌群細分（可展開）
│   ├── 訓練建議（AI 分析）
│   └── 歷史趨勢圖
│
├── Tab 3: 訓練方式 ⭐⭐
│   ├── 訓練類型分布（重訓/有氧/伸展）
│   ├── 器材類別分布
│   ├── 器材子類別統計
│   └── 多樣性評分
│
└── Tab 4: 個人記錄 ⭐⭐⭐
    ├── PR 列表（最大重量）
    ├── PR 進步趨勢
    ├── 按肌群查看 PR
    └── 歷史對比
```

---

## 🔧 技術實作細節

### 1. 數據載入策略

#### A. 批量載入動作分類（使用快取）
```dart
class StatisticsService {
  final ExerciseCacheService _cacheService;
  Map<String, Exercise> _exerciseCache = {};
  
  /// 批量載入動作分類信息
  Future<void> _loadExerciseClassifications(
    List<String> exerciseIds
  ) async {
    // 先嘗試從快取取得
    for (var id in exerciseIds) {
      if (_exerciseCache.containsKey(id)) continue;
      
      final exercise = await _cacheService.getExerciseById(id);
      if (exercise != null) {
        _exerciseCache[id] = exercise;
      }
    }
  }
}
```

#### B. 統計時的數據處理
```dart
/// 統計各身體部位的訓練量
Future<Map<String, double>> calculateVolumeByBodyPart(
  String userId,
  DateTime startDate,
  DateTime endDate,
) async {
  // 1. 查詢已完成的訓練
  final plans = await _getCompletedWorkouts(userId, startDate, endDate);
  
  // 2. 提取所有 exerciseId
  final exerciseIds = plans
      .expand((p) => p.exercises)
      .map((e) => e.exerciseId)
      .toSet()
      .toList();
  
  // 3. 批量載入動作分類
  await _loadExerciseClassifications(exerciseIds);
  
  // 4. 計算訓練量
  Map<String, double> stats = {};
  
  for (var plan in plans) {
    for (var workoutEx in plan.exercises) {
      if (!workoutEx.isCompleted) continue;
      
      // 獲取動作分類
      final exercise = _exerciseCache[workoutEx.exerciseId];
      if (exercise == null) continue;
      
      final bodyPart = exercise.bodyPart;
      final volume = workoutEx.weight * workoutEx.reps * workoutEx.sets;
      
      stats[bodyPart] = (stats[bodyPart] ?? 0) + volume;
    }
  }
  
  return stats;
}
```

### 2. 性能優化

#### A. 快取策略
```dart
// Service 層
class StatisticsService {
  // 統計數據快取（1 小時）
  Map<String, dynamic>? _statisticsCache;
  DateTime? _cacheTime;
  
  Future<StatisticsData> getStatistics(String userId) async {
    // 檢查快取
    if (_statisticsCache != null && _cacheTime != null) {
      final age = DateTime.now().difference(_cacheTime!);
      if (age.inHours < 1) {
        return StatisticsData.fromCache(_statisticsCache!);
      }
    }
    
    // 重新計算
    final stats = await _calculateStatistics(userId);
    _statisticsCache = stats.toCache();
    _cacheTime = DateTime.now();
    
    return stats;
  }
}
```

#### B. 分時間範圍查詢
```dart
// 避免一次載入太多數據
enum TimeRange {
  week,      // 本週
  month,     // 本月
  threeMonth, // 三個月
  year,      // 本年
}

Future<List<WorkoutPlan>> _getCompletedWorkouts(
  String userId,
  TimeRange range,
) async {
  final now = DateTime.now();
  DateTime startDate;
  
  switch (range) {
    case TimeRange.week:
      startDate = now.subtract(Duration(days: 7));
      break;
    case TimeRange.month:
      startDate = DateTime(now.year, now.month, 1);
      break;
    // ...
  }
  
  return await _workoutService.getCompletedWorkouts(
    userId,
    startDate: startDate,
    endDate: now,
  );
}
```

---

## 🎨 UI 設計建議

### 1. 概覽頁（首頁）

```
┌─────────────────────────────────────┐
│  📊 訓練統計                         │
│  ┌───────┬───────┬───────┬────────┐ │
│  │ 本週  │ 本月  │ 三個月 │ 本年   │ ← 時間選擇
│  └───────┴───────┴───────┴────────┘ │
│                                     │
│  🏋️ 本週訓練                         │
│  ┌─────────────────────────────┐   │
│  │  5 次   📈 +1                │   │
│  │  3.2小時  💪 連續7天          │   │
│  └─────────────────────────────┘   │
│                                     │
│  📈 訓練量趨勢                       │
│  ┌─────────────────────────────┐   │
│  │   ╱╲                         │   │
│  │  ╱  ╲    ╱                   │   │
│  │ ╱    ╲  ╱                    │   │
│  │───────────────────────────   │   │
│  │ W1  W2  W3  W4               │   │
│  └─────────────────────────────┘   │
│                                     │
│  💪 肌群訓練分布                     │
│  ┌─────────────────────────────┐   │
│  │      胸                       │   │
│  │   腿    背   ← 餅狀圖         │   │
│  │      肩                       │   │
│  │                               │   │
│  │  💡 核心訓練較少              │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### 2. 肌群分析頁

```
┌─────────────────────────────────────┐
│  💪 肌群分析                         │
│                                     │
│  各肌群訓練量（本月）                │
│  ┌─────────────────────────────┐   │
│  │ 腿   5,200 kg   ████████    │   │
│  │ 背   4,800 kg   ███████     │ ← 點擊展開
│  │ 胸   3,500 kg   █████       │   │
│  │ 肩   2,100 kg   ███         │   │
│  └─────────────────────────────┘   │
│                                     │
│  ➕ 胸部訓練細分                     │
│  ┌─────────────────────────────┐   │
│  │ 上胸  1,400 kg   40%         │   │
│  │ 中胸  1,225 kg   35%         │   │
│  │ 下胸    875 kg   25%         │   │
│  └─────────────────────────────┘   │
│                                     │
│  💡 建議                             │
│  ┌─────────────────────────────┐   │
│  │ • 核心訓練頻率偏低             │   │
│  │ • 建議每週至少 2 次核心訓練    │   │
│  │ • 腿部訓練量充足，保持！       │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### 3. 訓練方式頁

```
┌─────────────────────────────────────┐
│  🎯 訓練方式分析                     │
│                                     │
│  訓練類型（本月）                    │
│  ┌─────────────────────────────┐   │
│  │ 重訓  85%  ████████████████  │   │
│  │ 有氧  10%  ████              │   │
│  │ 伸展   5%  ██                │   │
│  └─────────────────────────────┘   │
│                                     │
│  器材類別                             │
│  ┌─────────────────────────────┐   │
│  │ 自由重量  45%  📦             │   │
│  │ 機械式    35%  🏋️             │   │
│  │ 徒手      20%  💪             │   │
│  └─────────────────────────────┘   │
│                                     │
│  器材使用頻率                         │
│  ┌─────────────────────────────┐   │
│  │ 啞鈴    ████████  25 次       │   │
│  │ 槓鈴    ██████    15 次       │   │
│  │ Cable   ████      10 次       │   │
│  │ 固定器械 ███       8 次        │   │
│  └─────────────────────────────┘   │
│                                     │
│  💡 訓練多樣性：良好 ⭐⭐⭐⭐         │
└─────────────────────────────────────┘
```

---

## ✅ 實作優先級

### 階段 1：核心統計（第 1 週）⭐⭐⭐
- [ ] 實作 `StatisticsService`（方案 A：動態查詢）
- [ ] 訓練頻率統計
- [ ] 訓練量計算
- [ ] 身體部位分布統計
- [ ] 創建概覽頁 UI

### 階段 2：進階分析（第 2 週）⭐⭐
- [ ] 特定肌群細分統計
- [ ] 訓練類型分布
- [ ] 器材類別統計
- [ ] 創建肌群分析頁 UI

### 階段 3：個人記錄（第 3 週）⭐⭐⭐
- [ ] PR 記錄查詢
- [ ] PR 進步趨勢
- [ ] 按肌群查看 PR
- [ ] 創建個人記錄頁 UI

### 階段 4：優化和完善（第 4 週）⭐
- [ ] 快取優化
- [ ] 圖表美化
- [ ] 添加訓練建議
- [ ] 性能調優

---

## 🎯 統計的價值

### 對用戶的價值
1. **了解訓練全面性**：是否有忽略的肌群？
2. **發現訓練偏好**：更喜歡自由重量還是機械式？
3. **追蹤進步**：訓練量是否在增長？
4. **保持動力**：看到連續訓練天數和 PR 進步

### 對應用的價值
1. **提高黏著度**：用戶會定期查看統計
2. **數據驅動建議**：基於統計提供個性化建議
3. **差異化競爭**：專業的分類系統帶來專業的統計

---

## 📝 總結

### 推薦的統計維度（按重要性排序）

1. **身體部位統計** ⭐⭐⭐
   - 最重要！用戶最關心是否全面訓練
   - 使用餅狀圖 + 建議

2. **訓練頻率** ⭐⭐⭐
   - 簡單但有效
   - 增加使用者成就感

3. **個人最佳記錄（PR）** ⭐⭐⭐
   - 追蹤進步的核心指標
   - 強烈的激勵作用

4. **訓練量趨勢** ⭐⭐
   - 可視化訓練進步
   - 折線圖呈現

5. **訓練方式分布** ⭐⭐
   - 了解訓練多樣性
   - 自由重量 vs 機械式 vs 徒手

6. **特定肌群細分** ⭐
   - 進階用戶喜歡
   - 例如：上胸/中胸/下胸

7. **器材使用頻率** ⭐
   - 了解訓練偏好
   - 啞鈴 vs 槓鈴

---

**結論**：使用方案 A（動態查詢）+ 快取優化，優先實作身體部位統計和訓練頻率！🚀

