# StrengthWise - 資料庫設計

> Firestore 資料庫結構設計和查詢策略

**最後更新**：2024年12月22日

---

## 📊 集合總覽

```
Firestore
├── users                    # 用戶資料
├── workoutPlans            # 訓練計劃/記錄（統一）
├── workoutTemplates        # 訓練模板
├── customExercises         # 自訂動作
├── exercises               # 公共運動庫（靜態）
├── bodyParts               # 身體部位（靜態）
├── exerciseTypes           # 運動類型（靜態）
├── notes                   # 筆記（預留）
└── bookings               # 預約記錄（預留）
```

---

## 🗂️ 集合詳細說明

### 1. users（用戶資料）

**用途**：存儲所有用戶的個人資料

**結構**：
```javascript
{
  uid: "UmtFu02WQ4QUoTV3x6AFRbd1ov52",       // 用戶 ID（與 Auth UID 一致）
  email: "user@example.com",                  // 電子郵件
  displayName: "Charlie",                     // 顯示名稱
  nickname: "Charlie",                        // 暱稱
  photoURL: "https://...",                    // 頭像 URL
  
  // 角色（統一欄位）
  isCoach: true,                              // 是否為教練
  isStudent: true,                            // 是否為學員
  
  // 身體資料
  height: 179,                                // 身高（cm）
  weight: 85,                                 // 體重（kg）
  age: 28,                                    // 年齡
  gender: "male",                             // 性別
  birthDate: Timestamp,                       // 生日
  
  // 系統設定
  unitSystem: "metric",                       // 單位系統（metric/imperial）
  bio: "熱愛健身的軟體工程師",                  // 個人簡介
  
  // 時間戳記
  profileCreatedAt: Timestamp,
  profileUpdatedAt: Timestamp,
  lastLogin: Timestamp
}
```

**索引**：
- `uid` (主鍵)
- `email`

**查詢範例**：
```dart
// 獲取當前用戶資料
final doc = await firestore
    .collection('users')
    .doc(currentUserId)
    .get();
final user = UserModel.fromMap(doc.data()!);
```

---

### 2. workoutPlans（訓練計劃/記錄）⭐

**用途**：統一存儲訓練計劃和訓練記錄

**結構**：
```javascript
{
  // 基本資訊
  userId: "user123",                          // 用戶 ID（向後相容）
  creatorId: "user123",                       // 創建者 ID
  traineeId: "user123",                       // 受訓者 ID
  title: "力量訓練 A",                        // 計劃名稱
  description: "胸+三頭",                     // 描述
  
  // 訓練類型
  planType: "self",                           // 計劃類型（self/trainer）
  uiPlanType: "力量訓練",                     // UI 顯示的類型
  
  // 日期
  scheduledDate: Timestamp,                   // 安排日期
  completedDate: Timestamp | null,            // 完成日期
  trainingTime: Timestamp,                    // 訓練時間
  
  // 訓練內容
  exercises: [                                // 運動列表
    {
      exerciseId: "ex001",
      exerciseName: "臥推",
      completed: true,                        // 運動完成狀態
      sets: [                                 // 組數記錄
        {
          setNumber: 1,
          reps: 10,
          weight: 60.0,
          restTime: 90,
          completed: true,                    // 組數完成狀態
          note: "感覺良好"
        }
      ]
    }
  ],
  
  // 狀態
  completed: false,                           // 整體完成狀態
  
  // 統計
  totalExercises: 5,                          // 總運動數
  totalSets: 15,                              // 總組數
  totalVolume: 4500.0,                        // 總訓練量（kg）
  
  // 備註
  note: "今天狀態不錯",                       // 訓練備註
  
  // 時間戳記
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**重要欄位說明**：

| 欄位 | 用途 | 注意事項 |
|------|------|----------|
| `userId` | 向後相容 | 必須包含，與 creatorId 相同 |
| `creatorId` | 創建者 | 用於查詢教練創建的計劃 |
| `traineeId` | 受訓者 | 用於查詢學員的計劃 |
| `completed` | 完成狀態 | false=計劃，true=記錄 |
| `completedDate` | 完成日期 | 只有 completed=true 時才有值 |

**索引**：
- `traineeId` + `completed`
- `creatorId` + `completed`
- `traineeId` + `scheduledDate`

**查詢範例**：
```dart
// 查詢今日訓練計劃（未完成+已完成）
final snapshot = await firestore
    .collection('workoutPlans')
    .where('traineeId', isEqualTo: userId)
    .get();

// 查詢已完成的訓練記錄
final snapshot = await firestore
    .collection('workoutPlans')
    .where('traineeId', isEqualTo: userId)
    .where('completed', isEqualTo: true)
    .get();
```

---

### 3. workoutTemplates（訓練模板）

**用途**：存儲可重複使用的訓練模板

**結構**：
```javascript
{
  userId: "user123",                          // 用戶 ID
  title: "增肌計劃 A",                        // 模板名稱
  description: "週一、三、五",                // 描述
  planType: "力量訓練",                       // 訓練類型
  
  exercises: [                                // 運動列表（同 workoutPlans）
    {
      exerciseId: "ex001",
      exerciseName: "深蹲",
      sets: [...]
    }
  ],
  
  trainingTime: Timestamp,                    // 預設訓練時間
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**索引**：
- `userId`

**查詢範例**：
```dart
// 獲取用戶的所有模板
final snapshot = await firestore
    .collection('workoutTemplates')
    .where('userId', isEqualTo: userId)
    .get();

// 客戶端排序（避免建立 Firestore 索引）
templates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
```

---

### 4. customExercises（自訂動作）

**用途**：存儲用戶自訂的運動動作

**結構**：
```javascript
{
  id: "custom001",                            // 文檔 ID
  userId: "user123",                          // 用戶 ID
  name: "單腿羅馬尼亞硬舉",                    // 動作名稱
  createdAt: Timestamp
}
```

**索引**：
- `userId`

**查詢範例**：
```dart
// 獲取用戶的自訂動作
final snapshot = await firestore
    .collection('customExercises')
    .where('userId', isEqualTo: userId)
    .orderBy('createdAt', descending: true)
    .get();
```

---

### 5. exercises（公共運動庫）

**用途**：存儲系統預設的運動動作（靜態數據）

**結構**：
```javascript
{
  id: "ex001",
  name: "臥推",
  nameEn: "Bench Press",
  bodyParts: ["胸", "三頭肌"],                // 訓練部位
  type: "自由重量",                           // 運動類型
  equipment: "槓鈴",                          // 器材
  level1: "上肢",                             // 階層分類
  level2: "推",
  level3: "水平推",
  videoUrl: "https://...",                   // 教學影片
  imageUrl: "https://..."                    // 示意圖
}
```

**特性**：
- 只讀數據
- 所有用戶共享
- 由管理員維護

---

### 6. bodyParts（身體部位）

**用途**：存儲身體部位分類（靜態數據）

**結構**：
```javascript
{
  id: "chest",
  name: "胸",
  nameEn: "Chest",
  order: 1                                    // 顯示順序
}
```

---

### 7. exerciseTypes（運動類型）

**用途**：存儲運動類型分類（靜態數據）

**結構**：
```javascript
{
  id: "strength",
  name: "力量訓練",
  nameEn: "Strength Training",
  order: 1
}
```

---

## 🔍 常用查詢模式

### 查詢今日訓練
```dart
final today = DateTime.now();
final todayStart = DateTime(today.year, today.month, today.day);
final todayEnd = todayStart.add(Duration(days: 1));

// 查詢方案 1：查詢後在客戶端過濾
final snapshot = await firestore
    .collection('workoutPlans')
    .where('traineeId', isEqualTo: userId)
    .get();

final todayPlans = snapshot.docs.where((doc) {
  final scheduledDate = (doc.data()['scheduledDate'] as Timestamp).toDate();
  final planDay = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
  return planDay == todayStart;
}).toList();
```

### 查詢最近訓練（已完成）
```dart
final snapshot = await firestore
    .collection('workoutPlans')
    .where('traineeId', isEqualTo: userId)
    .where('completed', isEqualTo: true)
    .get();

// 客戶端排序
final records = snapshot.docs
    .map((doc) => doc.data())
    .toList()
  ..sort((a, b) {
    final dateA = (a['completedDate'] ?? a['scheduledDate']) as Timestamp;
    final dateB = (b['completedDate'] ?? b['scheduledDate']) as Timestamp;
    return dateB.compareTo(dateA);
  });

final recentRecords = records.take(5).toList();
```

### 查詢本週訓練頻率
```dart
final weekStart = DateTime.now().subtract(Duration(days: 7));

final snapshot = await firestore
    .collection('workoutPlans')
    .where('traineeId', isEqualTo: userId)
    .where('completed', isEqualTo: true)
    .where('completedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
    .get();

final count = snapshot.docs.length;
```

---

## ⚡ 性能優化策略

### 1. 使用快取
```dart
// Service 層快取
Map<String, dynamic> _cache = {};
DateTime? _cacheTime;

Future<List<WorkoutPlan>> getPlans() async {
  // 檢查快取（5 分鐘有效）
  if (_cache.isNotEmpty && _cacheTime != null) {
    final age = DateTime.now().difference(_cacheTime!);
    if (age.inMinutes < 5) {
      return _cache;
    }
  }
  
  // 查詢資料庫
  final snapshot = await firestore.collection('workoutPlans').get();
  _cache = snapshot.docs;
  _cacheTime = DateTime.now();
  return _cache;
}
```

### 2. 客戶端排序
```dart
// ✅ 避免建立 Firestore 索引
final snapshot = await firestore
    .collection('workoutTemplates')
    .where('userId', isEqualTo: userId)
    .get();  // 不使用 .orderBy()

// 在客戶端排序
templates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
```

### 3. 分頁載入
```dart
// 首次載入
var query = firestore
    .collection('workoutPlans')
    .where('traineeId', isEqualTo: userId)
    .limit(20);

// 下一頁
query = query.startAfterDocument(lastDocument);
```

---

## 🚨 注意事項

### 1. 必須同時查詢多個 ID 欄位
```dart
// ✅ 正確：同時查詢 traineeId 和 creatorId
final traineeSnapshot = await firestore
    .where('traineeId', isEqualTo: userId)
    .get();

if (isCoach) {
  final creatorSnapshot = await firestore
      .where('creatorId', isEqualTo: userId)
      .get();
}
```

### 2. 避免複雜查詢
```dart
// ❌ 需要複合索引
.where('traineeId', isEqualTo: userId)
.where('completed', isEqualTo: true)
.orderBy('completedDate', descending: true)  // ← 需要索引

// ✅ 改用客戶端排序
.where('traineeId', isEqualTo: userId)
.where('completed', isEqualTo: true)
.get()
// 然後在客戶端排序
```

### 3. 使用 Model 類別
```dart
// ✅ 必須使用 Model
final plan = WorkoutPlan.fromMap(doc.data()!);
await firestore.collection('workoutPlans').add(plan.toMap());

// ❌ 禁止直接操作 Map
await firestore.collection('workoutPlans').add({...});
```

---

## 📈 未來擴展

### 預留的集合（暫未使用）

#### notes（筆記）
- 用於教練記錄學員的訓練筆記
- 包含繪圖軌跡和文字

#### bookings（預約）
- 用於預約系統
- 教練-學員課程預約

#### relationships（關係）
- 用於教練-學員綁定關係
- 邀請碼機制

---

## 🔗 相關文檔

- `PROJECT_OVERVIEW.md` - 專案技術架構
- `DEVELOPMENT_STATUS.md` - 當前開發進度
- `STATISTICS_IMPLEMENTATION.md` - 統計功能實作

---

**這份文檔是資料庫操作的權威指南，所有查詢邏輯都應該參考這裡！**

