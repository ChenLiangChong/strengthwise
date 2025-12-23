# 任務指令：使用者資料庫重構 (Refactoring User Collection)

> **優先級**：最高（必須先完成此任務）  
> **參考文檔**：`docs/02_FIRESTORE_ANALYSIS.md`（實際資料庫分析）

---

## 目標

目前使用者的資料分散在 `user` 與 `users` 兩個集合，這導致邏輯混亂。我們需要將其合併為單一的 `users` 集合。

**現況**：
- `user` 集合：1 個文檔，使用舊欄位命名（`isTrainer`, `isTrainee`）
- `users` 集合：1 個文檔，使用新欄位命名（`isCoach`, `isStudent`）

---

## 需求細節

### 1. 建立統一的 User Model

請在 `lib/models/user_model.dart` 更新或確認 `UserModel` 類別。

**新結構應包含**：

```dart
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? nickname;
  final String? gender;
  final double? height;
  final double? weight;
  final int? age;
  final DateTime? birthDate;  // 新增：從 user 集合遷移
  final bool isCoach;         // 統一欄位，替代 isTrainer
  final bool isStudent;       // 統一欄位，替代 isTrainee
  final String? bio;          // 新增：從 user 集合遷移
  final String? unitSystem;   // 新增：從 user 集合遷移
  final DateTime? profileCreatedAt;
  final DateTime? profileUpdatedAt;
  final DateTime? lastLogin; // 新增：從 user 集合遷移

  // 必須包含的方法：
  // - factory UserModel.fromMap(Map<String, dynamic> map)
  // - Map<String, dynamic> toMap()
  // - UserModel copyWith({...})
  
  // 向後兼容：fromMap 方法需要同時支援舊欄位
  // - isTrainer -> isCoach
  // - isTrainee -> isStudent
  // - createdAt -> profileCreatedAt
}
```

**欄位映射表**：

| 舊欄位 (`user`) | 新欄位 (`users`) | 說明 |
|---------------|----------------|------|
| `isTrainer` | `isCoach` | 布林值，是否為教練 |
| `isTrainee` | `isStudent` | 布林值，是否為學員 |
| `createdAt` | `profileCreatedAt` | 建立時間 |
| `lastLogin` | `lastLogin` | 最後登入時間（保留） |
| `bio` | `bio` | 個人簡介（新增到 users） |
| `unitSystem` | `unitSystem` | 單位系統（新增到 users） |
| `birthDate` | `birthDate` | 生日（新增到 users，或計算 age） |

---

### 2. 資料遷移邏輯 (Migration Strategy)

請在 `lib/services/user_service.dart` 或建立新的 `lib/services/user_migration_service.dart` 實作遷移邏輯。

**遷移步驟**：

1. **檢查並遷移資料**：
   ```dart
   /// 遷移用戶資料從 user 集合到 users 集合
   /// 此方法應在應用啟動時或用戶登入時執行一次
   Future<void> migrateUserData(String uid) async {
     // 1. 檢查 users/{uid} 是否存在
     // 2. 檢查 user/{uid} 是否存在
     // 3. 如果舊資料存在且新資料缺少欄位，合併資料
     // 4. 將合併後的資料寫入 users/{uid}
     // 5. 標記 user/{uid} 為已遷移（或刪除，建議先標記）
   }
   ```

2. **合併邏輯**：
   - 優先使用 `users` 集合的資料
   - 從 `user` 集合補充缺少的欄位（`bio`, `unitSystem`, `birthDate`, `lastLogin`）
   - 轉換欄位名稱（`isTrainer` → `isCoach`, `isTrainee` → `isStudent`）

3. **遷移標記**：
   - 在 `user/{uid}` 文檔中添加 `migrated: true` 欄位
   - 或建立遷移記錄集合 `userMigrations`

---

### 3. 更新 Auth Service

修改 `lib/services/auth_wrapper.dart` 或相關的認證服務：

**變更**：
- ✅ 註冊新用戶時，只寫入 `users` 集合
- ✅ 讀取用戶資料時，只讀取 `users` 集合
- ✅ 更新用戶資料時，只更新 `users` 集合

**範例**：

```dart
// ✅ 正確：使用 users 集合
await firestore.collection('users').doc(uid).set(userModel.toMap());

// ❌ 錯誤：使用 user 集合
await firestore.collection('user').doc(uid).set(userModel.toMap());
```

---

### 4. 更新所有引用

**搜尋並替換**：
- 搜尋專案中所有 `Firestore.instance.collection('user')` 的地方
- 全部改為 `Firestore.instance.collection('users')`
- 檢查所有 Model 的 `fromMap` 方法是否支援舊欄位名稱

**檢查清單**：
- [ ] `lib/services/user_service.dart`
- [ ] `lib/services/auth_wrapper.dart`
- [ ] `lib/controllers/auth_controller.dart`
- [ ] `lib/views/pages/profile_page.dart`
- [ ] 其他引用 `user` 集合的檔案

---

## 執行步驟

1. ✅ **更新 UserModel**：確認 `lib/models/user_model.dart` 包含所有必要欄位，並支援向後兼容
2. ✅ **實作遷移邏輯**：建立遷移服務或方法
3. ✅ **更新 Auth Service**：確保只使用 `users` 集合
4. ✅ **搜尋並替換**：將所有 `collection('user')` 改為 `collection('users')`
5. ✅ **測試**：確保應用可以正常編譯和運行
6. ✅ **驗證**：檢查資料是否正確遷移

---

## 注意事項

⚠️ **不要刪除舊資料**：先標記為已遷移，保留 `user` 集合作為備份

⚠️ **向後兼容**：`fromMap` 方法必須同時支援新舊欄位名稱

⚠️ **小步提交**：每個步驟完成後確保應用可以編譯通過

---

## 驗證標準

- [ ] `UserModel` 包含所有必要欄位
- [ ] `fromMap` 方法支援舊欄位名稱
- [ ] 遷移邏輯正確執行
- [ ] 所有代碼只使用 `users` 集合
- [ ] 應用可以正常編譯和運行
- [ ] 用戶資料正確顯示

---

**完成後**：請更新 `docs/02_FIRESTORE_ANALYSIS.md` 標記遷移狀態。


