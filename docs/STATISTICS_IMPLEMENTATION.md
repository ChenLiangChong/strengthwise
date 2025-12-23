# StrengthWise - 統計功能實作指南

> 基於當前單機版的完善，接下來實作統計和分析功能

---

## 🎯 目標：實作統計功能

讓用戶能夠：
- 📊 查看訓練數據分析
- 📈 追蹤進度和趨勢
- 🏆 記錄個人最佳成績
- 💪 了解訓練分布

---

## 📋 需要實作的統計功能

### 1. 訓練頻率統計 ⭐⭐⭐
**優先級：高**

顯示內容：
- 本週訓練次數
- 本月訓練次數
- 平均每週訓練次數
- 連續訓練天數

技術實現：
```dart
// 查詢本週已完成的訓練
.where('completed', isEqualTo: true)
.where('completedDate', isGreaterThanOrEqualTo: weekStart)
.where('completedDate', isLessThanOrEqualTo: weekEnd)
```

UI 設計：
- 卡片式顯示
- 使用圖標和數字
- 趨勢指示（⬆️ 增加 / ⬇️ 減少）

---

### 2. 訓練量趨勢圖表 ⭐⭐⭐
**優先級：高**

顯示內容：
- 每週訓練量（Volume）趨勢線圖
- 每月訓練次數柱狀圖
- 訓練時長趨勢

技術實現：
- 使用 `fl_chart` package
- 計算總訓練量：`Σ(重量 × 次數 × 組數)`
- 按週/月聚合數據

數據結構：
```dart
{
  'date': DateTime,
  'totalVolume': double,
  'totalSets': int,
  'duration': int,
}
```

---

### 3. 各肌群訓練分布 ⭐⭐
**優先級：中**

顯示內容：
- 本週/本月各肌群訓練次數
- 餅狀圖顯示分布
- 建議訓練較少的肌群

技術實現：
```dart
// 統計各肌群
Map<String, int> muscleGroupStats = {};
for (var workout in workouts) {
  for (var exercise in workout.exercises) {
    for (var bodyPart in exercise.bodyParts) {
      muscleGroupStats[bodyPart] = 
          (muscleGroupStats[bodyPart] ?? 0) + 1;
    }
  }
}
```

---

### 4. 個人最佳記錄（PR）⭐⭐⭐
**優先級：高**

顯示內容：
- 每個動作的最大重量記錄
- 達成日期
- 歷史 PR 列表
- PR 進步趨勢

技術實現：
```dart
// 查詢某動作的所有記錄
.where('exercises', arrayContains: {'exerciseId': exerciseId})

// 找出最大重量
var maxWeight = 0.0;
for (var workout in workouts) {
  for (var exercise in workout.exercises) {
    if (exercise.exerciseId == exerciseId) {
      for (var set in exercise.sets) {
        if (set.completed && set.weight > maxWeight) {
          maxWeight = set.weight;
        }
      }
    }
  }
}
```

數據結構：
```dart
{
  'exerciseId': String,
  'exerciseName': String,
  'maxWeight': double,
  'date': DateTime,
  'reps': int,
}
```

---

### 5. 訓練時長統計 ⭐
**優先級：低**

顯示內容：
- 平均訓練時長
- 最長/最短訓練時長
- 本週總訓練時長

---

### 6. 動作頻率統計 ⭐
**優先級：低**

顯示內容：
- 最常訓練的動作 TOP 10
- 每個動作的訓練次數
- 最近一次訓練時間

---

## 🏗️ 實作計劃

### 階段 1：數據收集和計算（第 1 週）✅ 已完成
- [x] 創建 `StatisticsService`
- [x] 實作基本數據查詢方法
- [x] 實作訓練量計算邏輯
- [x] 實作 PR 記錄查詢

### 階段 2：UI 頁面開發（第 2 週）✅ 已完成
- [x] 創建 `StatisticsPage`
- [x] 實作訓練頻率卡片
- [x] 整合圖表庫（`fl_chart`）
- [x] 實作趨勢圖表

### 階段 3：進階統計（第 3 週）⏳ 部分完成
- [x] 實作肌群分布分析
- [ ] 實作 PR 記錄頁面（已有基礎功能，可擴展）
- [ ] 添加數據匯出功能
- [ ] 優化性能和快取

---

## 📦 需要的第三方套件

### 圖表庫
```yaml
dependencies:
  fl_chart: ^0.66.0  # Flutter 圖表庫
```

功能：
- 折線圖（訓練量趨勢）
- 柱狀圖（訓練次數）
- 餅狀圖（肌群分布）

### 其他可能需要的套件
```yaml
dependencies:
  intl: ^0.18.0           # 日期格式化
  collection: ^1.18.0     # 數據處理
  cached_network_image: ^3.3.0  # 圖片快取（如果需要顯示動作圖片）
```

---

## 🎨 UI 設計草圖

### 統計頁面結構
```
統計頁面 (StatisticsPage)
├── 時間選擇器（本週/本月/本年）
├── 訓練概覽卡片
│   ├── 訓練次數
│   ├── 總訓練量
│   ├── 平均時長
│   └── 連續天數
├── 訓練量趨勢圖表
│   └── 折線圖（過去 4 週）
├── 訓練次數圖表
│   └── 柱狀圖（過去 4 週）
├── 肌群分布
│   └── 餅狀圖
└── 個人最佳記錄
    └── 列表（TOP 10）
```

---

## 🗄️ 資料庫查詢策略

### 優化建議
1. **使用快取**：統計數據可以快取 1 小時
2. **分頁載入**：歷史記錄使用分頁
3. **索引優化**：為常用查詢建立索引
4. **客戶端計算**：複雜計算在客戶端進行

### 查詢範例
```dart
// 查詢本週已完成的訓練
final weekStart = DateTime.now().subtract(Duration(days: 7));
final snapshot = await FirebaseFirestore.instance
    .collection('workoutPlans')
    .where('traineeId', isEqualTo: userId)
    .where('completed', isEqualTo: true)
    .where('completedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
    .get();
```

---

## ✅ 驗收標準

統計功能完成的標準：

1. **數據準確性**
   - [ ] 訓練次數統計正確
   - [ ] 訓練量計算正確
   - [ ] PR 記錄正確

2. **性能要求**
   - [ ] 統計頁面載入時間 < 2 秒
   - [ ] 圖表渲染流暢
   - [ ] 使用快取減少查詢

3. **用戶體驗**
   - [ ] UI 美觀易讀
   - [ ] 支援不同時間範圍
   - [ ] 支援數據匯出

4. **錯誤處理**
   - [ ] 無數據時顯示空狀態
   - [ ] 載入失敗顯示錯誤訊息
   - [ ] 支援重新載入

---

## 🚀 開始開發

### 第一步：創建基礎架構
```bash
# 創建新的文件
lib/services/statistics_service.dart
lib/controllers/statistics_controller.dart
lib/views/pages/statistics_page.dart
lib/models/statistics_model.dart
```

### 第二步：安裝依賴
```bash
flutter pub add fl_chart
flutter pub get
```

### 第三步：實作 Service 層
從簡單的統計開始：
1. 訓練次數統計
2. 訓練量計算
3. 逐步添加更複雜的功能

---

**準備好了嗎？開始實作統計功能！** 🚀

