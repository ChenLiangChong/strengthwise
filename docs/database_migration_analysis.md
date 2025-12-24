# StrengthWise 資料庫遷移評估報告

**專案**: strengthwise-91f02  
**匯出時間**: 2025-12-25 05:06:28  
**目的**: 評估從 Firebase Firestore 遷移到其他資料庫的可行性

---

## 📊 執行摘要

### 當前資料庫規模

| 指標 | 數值 | 說明 |
|------|------|------|
| **集合數量** | 6 個 | users, workoutPlans, exercise, bodyParts, exerciseTypes, notes |
| **文檔總數** | 868 個 | 主要是 exercise (794 個) |
| **欄位總數** | 96 個 | 含巢狀欄位 |
| **平均欄位數** | ~12-15 個/集合 | 視集合而定 |

### 核心問題

1. **Exercise 集合（794 個動作）** - 靜態資料每次都要從 Firestore 讀取
   - 1000 用戶：每月 $19.2（僅動作資料）
   - 建議：打包進 App / CDN / PostgreSQL + Redis

2. **WorkoutPlans 集合（54 個文檔）** - 歷史記錄累積，成本線性增長
   - 1000 用戶：每月 $7.2（會持續增長到 $15-30）
   - 建議：PostgreSQL + 封存歷史記錄

3. **Firestore 根本限制** - 不支援複雜查詢、成本不可預測
   - 建議：遷移到關聯式資料庫（PostgreSQL）

### 成本對比（1000 活躍用戶）

| 方案 | 月成本 | 適用規模 | 彈性 |
|------|--------|----------|------|
| **Firestore（當前）** | $11-50 | 隨時間增長 | ⚠️ 不可預測 |
| **Supabase Pro** | $25（固定） | < 10K 用戶 | ✅ 完整 SQL |
| **混合架構** | $3-20 | < 5K 用戶 | ⚠️ 維護複雜 |

### 推薦方案

**短期（2-3 天）**：混合架構
- 靜態資料（exercises）打包進 App
- 動態資料保留 Firestore
- 立即降低 60% 成本

**長期（12-18 天）**：完全遷移到 Supabase
- 固定月費 $25
- 完整 SQL 支援
- 可擴展到 10K 用戶

---

## 🎯 詳細遷移建議

### 1. exercise 集合有 794 個動作 `[優先級: 中]`

**影響**: 動作資料幾乎不變，但每次都要從 Firestore 讀取

**建議**: 動作資料可以：1) 打包進 App 內，2) 使用 CDN 快取，3) 遷移到 PostgreSQL 並配合 Redis 快取

### 2. Firestore 不支援複雜查詢 `[優先級: 高]`

**影響**: 需要客戶端排序/過濾，或創建大量複合索引

**建議**: 關聯式資料庫（PostgreSQL）對複雜查詢有原生支援，且成本更可預測

### 3. Firestore 成本隨用戶增長不可預測 `[優先級: 高]`

**影響**: 1000 活躍用戶可能產生每月 $50-200 的讀取成本

**建議**: 關聯式資料庫（如 Supabase PostgreSQL）提供固定月費，更適合規模化

## 💰 查詢成本分析

> 基於 Firestore 定價：讀取 $0.06/100K 次，寫入 $0.18/100K 次

### 常見查詢場景

#### 用戶載入訓練計劃列表

- **說明**: 每次打開 App 查詢 traineeId
- **頻率**: 每用戶每日 5-10 次
- **每次讀取數**: 50
- **每用戶月成本**: $0.0072
- **備註**: 若用戶有大量歷史記錄，成本會線性增加

#### 完成一次訓練

- **說明**: 讀取模板 + 更新記錄
- **頻率**: 每用戶每週 3-5 次
- **讀取次數**: 1
- **寫入次數**: 1
- **每用戶月成本**: $0.0

#### 載入動作資料庫

- **說明**: 用戶選擇動作時查詢所有動作
- **頻率**: 每用戶每週 1-2 次
- **每次讀取數**: 794
- **每用戶月成本**: $0.0038
- **備註**: 共 794 個動作，每次都需要讀取全部

#### 用戶登入

- **說明**: 查詢用戶資料
- **頻率**: 每用戶每日 1-3 次
- **讀取次數**: 1
- **每用戶月成本**: $0.0

## 📁 集合詳細結構

### bodyParts

- **文檔數量**: 8
- **欄位數量**: 3（含巢狀）
- **平均欄位數/文檔**: 0.38

#### 欄位清單

| 欄位路徑 | 類型 | 出現率 | 空值率 | 範例值 |
|---------|------|--------|--------|--------|
| `count` | 整數 (integer) | 100.0% | 0.0% | 53 |
| `description` | 字串 (string) | 100.0% | 0.0% |  |
| `name` | 字串 (string) | 100.0% | 0.0% | 手 |

#### 範例文檔

```json
{
  "id": "1m6ZvsyrF4yJGeWwcID1",
  "data": {
    "description": "",
    "count": 53,
    "name": "手"
  }
}
```

### exercise

- **文檔數量**: 794
- **欄位數量**: 22（含巢狀）
- **平均欄位數/文檔**: 0.03

#### 欄位清單

| 欄位路徑 | 類型 | 出現率 | 空值率 | 範例值 |
|---------|------|--------|--------|--------|
| `actionName` | 字串 (string) | 100.0% | 0.0% | 內外波浪 |
| `apps` | 陣列 (array) | 100.0% | 0.0% | [陣列, 0 項] |
| `bodyPart` | 字串 (string) | 100.0% | 0.0% | 全身 |
| `bodyParts` | 陣列 (array), 陣列 (array<字串 (string)>) | 100.0% | 0.0% | [陣列, 1 項] |
| `createdAt` | 其他類型 (DatetimeWithNanoseconds) | 100.0% | 0.0% | - |
| `description` | 字串 (string) | 100.0% | 0.0% |  |
| `equipment` | 字串 (string) | 100.0% | 0.0% | 徒手 |
| `equipmentCategory` | 字串 (string) | 100.0% | 0.0% | 徒手 |
| `equipmentSubcategory` | 字串 (string) | 100.0% | 0.0% | 自身體重 |
| `imageUrl` | 字串 (string) | 100.0% | 0.0% |  |
| `jointType` | 字串 (string) | 100.0% | 0.0% | 多關節 |
| `level1` | 字串 (string) | 100.0% | 0.0% | 戰繩 |
| `level2` | 字串 (string) | 100.0% | 0.0% |  |
| `level3` | 字串 (string) | 100.0% | 0.0% |  |
| `level4` | 字串 (string) | 100.0% | 0.0% |  |
| `level5` | 字串 (string) | 100.0% | 0.0% |  |
| `name` | 字串 (string) | 100.0% | 0.0% | 戰繩/內外波浪 |
| `nameEn` | 字串 (string) | 100.0% | 0.0% | Battle ropes/In and out waves |
| `specificMuscle` | 字串 (string), 空值 (null) | 100.0% | 0.88% | 綜合訓練 |
| `trainingType` | 字串 (string) | 100.0% | 0.0% | 重訓 |
| `type` | 字串 (string) | 100.0% | 0.0% | 重訓 |
| `videoUrl` | 字串 (string) | 100.0% | 0.0% |  |

#### 範例文檔

```json
{
  "id": "03g9loX3XxvLPMsI0Qax",
  "data": {
    "imageUrl": "",
    "type": "重訓",
    "description": "",
    "videoUrl": "",
    "level3": "",
    "equipment": "徒手",
    "apps": [],
    "level4": "",
    "nameEn": "Battle ropes/In and out waves",
    "level5": "",
    "bodyParts": [
      "全身"
    ],
    "name": "戰繩/內外波浪",
    "equipmentSubcategory": "自身體重",
    "level1": "戰繩",
    "equipmentCategory": "徒手",
    "specificMuscle": "綜合訓練",
    "actionName": "內外波浪",
    "jointType": "多關節",
    "createdAt": "2025-03-01 18:51:49.265000+00:00",
    "trainingType": "重訓",
    "level2": "",
    "bodyPart": "全身"
  }
}
```

### exerciseTypes

- **文檔數量**: 3
- **欄位數量**: 3（含巢狀）
- **平均欄位數/文檔**: 1.0

#### 欄位清單

| 欄位路徑 | 類型 | 出現率 | 空值率 | 範例值 |
|---------|------|--------|--------|--------|
| `count` | 整數 (integer) | 100.0% | 0.0% | 20 |
| `description` | 字串 (string) | 100.0% | 0.0% |  |
| `name` | 字串 (string) | 100.0% | 0.0% | 有氧 |

#### 範例文檔

```json
{
  "id": "IjWIqCVVXekx3sqUIDyR",
  "data": {
    "description": "",
    "count": 20,
    "name": "有氧"
  }
}
```

### notes

- **文檔數量**: 5
- **欄位數量**: 10（含巢狀）
- **平均欄位數/文檔**: 2.0

#### 欄位清單

| 欄位路徑 | 類型 | 出現率 | 空值率 | 範例值 |
|---------|------|--------|--------|--------|
| `createdAt` | 整數 (integer) | 100.0% | 0.0% | 1765201027832 |
| `drawingPoints` | 空值 (null), 陣列 (array<物件 (map/object)>) | 100.0% | 20.0% | [陣列, 67 項] |
| `drawingPoints[0].color` | 整數 (integer) | 80.0% | 0.0% | 4278190080 |
| `drawingPoints[0].offsetX` | 浮點數 (float) | 80.0% | 0.0% | 83.42075892857143 |
| `drawingPoints[0].offsetY` | 浮點數 (float) | 80.0% | 0.0% | 122.26227678571428 |
| `drawingPoints[0].strokeWidth` | 浮點數 (float) | 80.0% | 0.0% | 3.0 |
| `textContent` | 字串 (string) | 100.0% | 0.0% | 123546 |
| `title` | 字串 (string) | 100.0% | 0.0% | 888 |
| `updatedAt` | 整數 (integer) | 100.0% | 0.0% | 1765201027832 |
| `userId` | 字串 (string) | 100.0% | 0.0% | UmtFu02WQ4QUoTV3x6AFRbd1ov52 |

#### 範例文檔

```json
{
  "id": "2A741SzVK4AQzEu7LTwE",
  "data": {
    "drawingPoints": [
      {
        "offsetY": 122.26227678571428,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 83.42075892857143
      },
      {
        "offsetY": 117.68638392857144,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 83.42075892857143
      },
      {
        "offsetY": 116.54241071428572,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 84.56324404761905
      },
      {
        "offsetY": 113.50111607142856,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 84.56324404761905
      },
      {
        "offsetY": 107.78125,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 87.99107142857143
      },
      {
        "offsetY": 95.22544642857144,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 99.04017857142857
      },
      {
        "offsetY": 94.44419642857144,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 104.75297619047619
      },
      {
        "offsetY": 89.89620535714283,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 114.65959821428571
      },
      {
        "offsetY": 86.46428571428572,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 128.37053571428572
      },
      {
        "offsetY": 86.46428571428572,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 138.27715773809524
      },
      {
        "offsetY": 94.44419642857144,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 179.79910714285714
      },
      {
        "offsetY": 100.91741071428572,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 193.13355654761904
      },
      {
        "offsetY": 107.78125,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 206.46763392857142
      },
      {
        "offsetY": 147.01116071428572,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 231.22767857142858
      },
      {
        "offsetY": 156.91629464285717,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 231.22767857142858
      },
      {
        "offsetY": 174.82924107142856,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 231.22767857142858
      },
      {
        "offsetY": 188.55691964285717,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 225.51488095238096
      },
      {
        "offsetY": 201.86607142857144,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 212.18043154761904
      },
      {
        "offsetY": 214.05915178571428,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 189.70572916666666
      },
      {
        "offsetY": 223.2109375,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 167.23065476190476
      },
      {
        "offsetY": 224.35491071428572,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 155.0390625
      },
      {
        "offsetY": 227.39620535714283,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 145.13244047619048
      },
      {
        "offsetY": 227.39620535714283,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 123.80022321428571
      },
      {
        "offsetY": 224.35491071428572,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 119.22991071428571
      },
      {
        "offsetY": 220.92299107142856,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 118.0874255952381
      },
      {
        "offsetY": 207.5859375,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 113.5171130952381
      },
      {
        "offsetY": 197.31808035714283,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 113.5171130952381
      },
      {
        "offsetY": 186.26897321428572,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 113.5171130952381
      },
      {
        "offsetY": 149.29910714285717,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 116.94494047619048
      },
      {
        "offsetY": 139.03125,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 120.37239583333333
      },
      {
        "offsetY": 112.35714285714283,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 150.46875
      },
      {
        "offsetY": 107.78125,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 160.75186011904762
      },
      {
        "offsetY": 103.20535714285717,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 180.56510416666666
      },
      {
        "offsetY": 103.20535714285717,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 190.84821428571428
      },
      {
        "offsetY": 103.20535714285717,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 203.03980654761904
      },
      {
        "offsetY": 111.21316964285717,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 212.18043154761904
      },
      {
        "offsetY": 130.27008928571428,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 225.51488095238096
      },
      {
        "offsetY": 139.03125,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 231.22767857142858
      },
      {
        "offsetY": 152.36830357142856,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 235.42150297619048
      },
      {
        "offsetY": 174.82924107142856,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 241.1343005952381
      },
      {
        "offsetY": 186.26897321428572,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 241.1343005952381
      },
      {
        "offsetY": 201.86607142857144,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 237.70647321428572
      },
      {
        "offsetY": 214.05915178571428,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 225.51488095238096
      },
      {
        "offsetY": 214.05915178571428,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 219.80208333333334
      },
      {
        "offsetY": 211.77120535714283,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 215.21912202380952
      },
      {
        "offsetY": 207.5859375,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 212.18043154761904
      },
      {
        "offsetY": 199.60602678571428,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 211.03794642857142
      },
      {
        "offsetY": 180.54910714285717,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 208.7529761904762
      },
      {
        "offsetY": 166.06808035714283,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 208.7529761904762
      },
      {
        "offsetY": 161.4921875,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 211.03794642857142
      },
      {
        "offsetY": 156.91629464285717,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 217.51674107142858
      },
      {
        "offsetY": 161.4921875,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 228.94270833333334
      },
      {
        "offsetY": 168.35602678571428,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 231.98102678571428
      },
      {
        "offsetY": 188.55691964285717,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 238.84895833333334
      },
      {
        "offsetY": 201.86607142857144,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 239.99181547619048
      },
      {
        "offsetY": 214.05915178571428,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 241.1343005952381
      },
      {
        "offsetY": 241.12388392857144,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 242.27678571428572
      },
      {
        "offsetY": 254.4609375,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 239.99181547619048
      },
      {
        "offsetY": 266.62611607142856,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 237.70647321428572
      },
      {
        "offsetY": 295.97879464285717,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 216.37425595238096
      },
      {
        "offsetY": 298.26674107142856,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 208.7529761904762
      },
      {
        "offsetY": 299.4107142857143,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 198.46949404761904
      },
      {
        "offsetY": 298.26674107142856,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 194.27604166666666
      },
      {
        "offsetY": 295.97879464285717,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 190.84821428571428
      },
      {
        "offsetY": 287.97098214285717,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 186.27790178571428
      },
      {
        "offsetY": 286.82700892857144,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 185.13541666666666
      },
      {
        "offsetY": 283.7857142857143,
        "strokeWidth": 3.0,
        "color": 4278190080,
        "offsetX": 185.13541666666666
      }
    ],
    "createdAt": 1765201027832,
    "title": "888",
    "userId": "UmtFu02WQ4QUoTV3x6AFRbd1ov52",
    "updatedAt": 1765201027832,
    "textContent": "123546"
  }
}
```

### users

- **文檔數量**: 4
- **欄位數量**: 16（含巢狀）
- **平均欄位數/文檔**: 4.0

#### 欄位清單

| 欄位路徑 | 類型 | 出現率 | 空值率 | 範例值 |
|---------|------|--------|--------|--------|
| `age` | 整數 (integer) | 50.0% | 0.0% | 28 |
| `bio` | 字串 (string) | 50.0% | 0.0% | 我是個好人 |
| `birthDate` | 其他類型 (DatetimeWithNanoseconds), 空值 (null) | 50.0% | 50.0% | - |
| `displayName` | 字串 (string) | 100.0% | 0.0% | 良允陳 |
| `email` | 字串 (string) | 100.0% | 0.0% | charlie8519960414@gmail.com |
| `gender` | 字串 (string) | 50.0% | 0.0% | 男 |
| `height` | 浮點數 (float) | 50.0% | 0.0% | 178.0 |
| `isCoach` | 布林值 (boolean) | 100.0% | 0.0% | False |
| `isStudent` | 布林值 (boolean) | 100.0% | 0.0% | True |
| `nickname` | 字串 (string) | 50.0% | 0.0% | 夢行 |
| `photoURL` | 字串 (string) | 100.0% | 0.0% | https://lh3.googleusercontent.com/a/A... |
| `profileCreatedAt` | 其他類型 (DatetimeWithNanoseconds) | 100.0% | 0.0% | - |
| `profileUpdatedAt` | 其他類型 (DatetimeWithNanoseconds) | 50.0% | 0.0% | - |
| `uid` | 字串 (string) | 100.0% | 0.0% | MmvGmxq15ZMNzAy67bRPhYVy6pG3 |
| `unitSystem` | 字串 (string) | 50.0% | 0.0% | metric |
| `weight` | 浮點數 (float) | 50.0% | 0.0% | 86.0 |

#### 範例文檔

```json
{
  "id": "MmvGmxq15ZMNzAy67bRPhYVy6pG3",
  "data": {
    "age": 28,
    "uid": "MmvGmxq15ZMNzAy67bRPhYVy6pG3",
    "bio": "我是個好人",
    "displayName": "良允陳",
    "profileUpdatedAt": "2025-12-24 16:17:43.955000+00:00",
    "height": 178.0,
    "photoURL": "https://lh3.googleusercontent.com/a/ACg8ocKH4HT0mLinvbfVzKegc0vyCErRJy1wxb2CfPBQhvwNFO1R4A=s96-c",
    "birthDate": null,
    "isStudent": true,
    "unitSystem": "metric",
    "nickname": "夢行",
    "email": "charlie8519960414@gmail.com",
    "isCoach": false,
    "profileCreatedAt": "2025-12-24 15:56:27.271000+00:00",
    "gender": "男",
    "weight": 86.0
  }
}
```

### workoutPlans

- **文檔數量**: 54
- **欄位數量**: 42（含巢狀）
- **平均欄位數/文檔**: 0.78

#### 欄位清單

| 欄位路徑 | 類型 | 出現率 | 空值率 | 範例值 |
|---------|------|--------|--------|--------|
| `completed` | 布林值 (boolean) | 100.0% | 0.0% | True |
| `completedDate` | 其他類型 (DatetimeWithNanoseconds) | 92.59% | 0.0% | - |
| `createdAt` | 其他類型 (DatetimeWithNanoseconds) | 100.0% | 0.0% | - |
| `creatorId` | 字串 (string) | 100.0% | 0.0% | zJ8UuJ3LUJSnkyxtf8One4YHRC72 |
| `description` | 字串 (string) | 11.11% | 0.0% |  |
| `exercises` | 陣列 (array<物件 (map/object)>) | 100.0% | 0.0% | [陣列, 4 項] |
| `exercises[0].actionName` | 字串 (string) | 5.56% | 0.0% | 自訂 |
| `exercises[0].bodyParts` | 陣列 (array), 陣列 (array<字串 (string)>) | 5.56% | 0.0% | [陣列, 0 項] |
| `exercises[0].completed` | 布林值 (boolean) | 94.44% | 0.0% | True |
| `exercises[0].equipment` | 字串 (string) | 5.56% | 0.0% | 自訂 |
| `exercises[0].exerciseId` | 字串 (string) | 100.0% | 0.0% | 3zsvNeYy7QC4NNbfB8Cf |
| `exercises[0].exerciseName` | 字串 (string) | 94.44% | 0.0% | 推／胸推／地板臥推／槓鈴，推舉 |
| `exercises[0].id` | 字串 (string) | 5.56% | 0.0% | 1766593889176 |
| `exercises[0].isCompleted` | 布林值 (boolean) | 5.56% | 0.0% | False |
| `exercises[0].name` | 字串 (string) | 5.56% | 0.0% | 自訂 |
| `exercises[0].notes` | 字串 (string) | 5.56% | 0.0% |  |
| `exercises[0].reps` | 整數 (integer) | 5.56% | 0.0% | 10 |
| `exercises[0].restTime` | 整數 (integer) | 5.56% | 0.0% | 90 |
| `exercises[0].setTargets` | 陣列 (array<物件 (map/object)>) | 1.85% | 0.0% | [陣列, 4 項] |
| `exercises[0].setTargets[0].reps` | 整數 (integer) | 1.85% | 0.0% | 10 |
| `exercises[0].setTargets[0].weight` | 浮點數 (float) | 1.85% | 0.0% | 60.0 |
| `exercises[0].sets` | 整數 (integer), 陣列 (array<物件 (map/object)>) | 100.0% | 0.0% | [陣列, 4 項] |
| `exercises[0].sets[0].completed` | 布林值 (boolean) | 94.44% | 0.0% | True |
| `exercises[0].sets[0].note` | 字串 (string) | 5.56% | 0.0% |  |
| `exercises[0].sets[0].reps` | 整數 (integer) | 94.44% | 0.0% | 8 |
| `exercises[0].sets[0].restTime` | 整數 (integer) | 5.56% | 0.0% | 120 |
| `exercises[0].sets[0].setNumber` | 整數 (integer) | 94.44% | 0.0% | 1 |
| `exercises[0].sets[0].timestamp` | 字串 (string) | 88.89% | 0.0% | 2025-12-17T01:49:54.878514 |
| `exercises[0].sets[0].weight` | 整數 (integer), 浮點數 (float) | 94.44% | 0.0% | 65 |
| `exercises[0].weight` | 浮點數 (float) | 5.56% | 0.0% | 0.0 |
| `note` | 字串 (string) | 92.59% | 0.0% | 訓練量: 3,354 kg |
| `planType` | 字串 (string) | 100.0% | 0.0% | self |
| `scheduledDate` | 其他類型 (DatetimeWithNanoseconds) | 100.0% | 0.0% | - |
| `title` | 字串 (string) | 100.0% | 0.0% | 第4週 推日 A - 個人記錄挑戰 |
| `totalExercises` | 整數 (integer) | 92.59% | 0.0% | 4 |
| `totalSets` | 整數 (integer) | 92.59% | 0.0% | 13 |
| `totalVolume` | 整數 (integer), 浮點數 (float) | 92.59% | 0.0% | 3354 |
| `traineeId` | 字串 (string) | 100.0% | 0.0% | zJ8UuJ3LUJSnkyxtf8One4YHRC72 |
| `trainingTime` | 其他類型 (DatetimeWithNanoseconds), 空值 (null) | 100.0% | 5.56% | - |
| `uiPlanType` | 字串 (string) | 100.0% | 0.0% | 力量訓練 |
| `updatedAt` | 其他類型 (DatetimeWithNanoseconds) | 96.3% | 0.0% | - |
| `userId` | 字串 (string) | 100.0% | 0.0% | zJ8UuJ3LUJSnkyxtf8One4YHRC72 |

#### 範例文檔

```json
{
  "id": "3bL9FbX02R6QIkLHMVvQ",
  "data": {
    "exercises": [
      {
        "exerciseName": "推／胸推／地板臥推／槓鈴，推舉",
        "sets": [
          {
            "reps": 8,
            "completed": true,
            "timestamp": "2025-12-17T01:49:54.878514",
            "setNumber": 1,
            "weight": 65
          },
          {
            "reps": 6,
            "completed": true,
            "timestamp": "2025-12-17T01:49:54.878514",
            "setNumber": 2,
            "weight": 70
          },
          {
            "reps": 4,
            "completed": true,
            "timestamp": "2025-12-17T01:49:54.878514",
            "setNumber": 3,
            "weight": 75
          },
          {
            "reps": 5,
            "completed": true,
            "timestamp": "2025-12-17T01:49:54.878514",
            "setNumber": 4,
            "weight": 70
          }
        ],
        "completed": true,
        "exerciseId": "3zsvNeYy7QC4NNbfB8Cf"
      },
      {
        "exerciseId": "5yNv0j7fdFEEpuLpA1x5",
        "sets": [
          {
            "reps": 10,
            "completed": true,
            "timestamp": "2025-12-17T01:49:54.878514",
            "setNumber": 1,
            "weight": 26
          },
          {
            "reps": 8,
            "completed": true,
            "timestamp": "2025-12-17T01:49:54.878514",
            "setNumber": 2,
            "weight": 28
          },
          {
            "reps": 8,
            "completed": true,
            "timestamp": "2025-12-17T01:49:54.878514",
            "setNumber": 3,
            "weight": 28
          }
        ],
        "completed": true,
        "exerciseName": "推／胸推／地板臥推／啞鈴，交替推舉"
      },
      {
        "exerciseName": "推／肩推／直立式，彈力繩／單手",
        "sets": [
          {
            "reps": 10,
            "completed": true,
            "timestamp": "2025-12-17T01:49:54.878514",
            "setNumber": 1,
            "weight": 22
          },
          {
            "reps": 8,
            "completed": true,
            "timestamp": "2025-12-17T01:49:54.878514",
            "setNumber": 2,
            "weight": 24
          },
          {
            "reps": 6,
            "completed": true,
            "timestamp": "2025-12-17T01:49:54.878514",
            "setNumber": 3,
            "weight": 26
          }
        ],
        "exerciseId": "6hvpsp4UIyWptRYJYL2l",
        "completed": true
      },
      {
        "exerciseName": "推／肩推／倒立式",
        "sets": [
          {
            "reps": 12,
            "completed": true,
            "timestamp": "2025-12-17T01:49:54.878514",
            "setNumber": 1,
            "weight": 14
          },
          {
            "reps": 10,
            "completed": true,
            "timestamp": "2025-12-17T01:49:54.878514",
            "setNumber": 2,
            "weight": 16
          },
          {
            "reps": 10,
            "completed": true,
            "timestamp": "2025-12-17T01:49:54.878514",
            "setNumber": 3,
            "weight": 16
          }
        ],
        "completed": true,
        "exerciseId": "6mMd1EMonuwNpujwiqlr"
      }
    ],
    "traineeId": "zJ8UuJ3LUJSnkyxtf8One4YHRC72",
    "totalExercises": 4,
    "completedDate": "2025-12-17 01:49:54.878514+00:00",
    "totalVolume": 3354,
    "planType": "self",
    "creatorId": "zJ8UuJ3LUJSnkyxtf8One4YHRC72",
    "updatedAt": "2025-12-17 01:49:54.878514+00:00",
    "trainingTime": "2025-12-17 00:19:54.878514+00:00",
    "completed": true,
    "uiPlanType": "力量訓練",
    "scheduledDate": "2025-12-17 00:19:54.878514+00:00",
    "userId": "zJ8UuJ3LUJSnkyxtf8One4YHRC72",
    "title": "第4週 推日 A - 個人記錄挑戰",
    "createdAt": "2025-12-17 00:19:54.878514+00:00",
    "note": "訓練量: 3,354 kg",
    "totalSets": 13
  }
}
```

---

## 📎 附錄

### 推薦的替代方案

1. **Supabase (PostgreSQL)**
   - 完整的 SQL 功能
   - 固定月費（$25 起）
   - 內建即時訂閱
   - 完整的 Flutter SDK

2. **自架 PostgreSQL + Redis**
   - 完全可控
   - 成本最低（長期）
   - 需要維護

3. **保留 Firestore 但優化**
   - 分離靜態資料（exercises）到 CDN
   - 實作更多客戶端快取
   - 定期封存歷史資料

