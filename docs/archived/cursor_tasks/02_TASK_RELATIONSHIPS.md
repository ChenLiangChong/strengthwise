# 任務指令：教練與學員綁定功能 (Relationships)

> **前置任務**：必須先完成 `01_TASK_DB_REFACTOR.md`（用戶資料庫重構）

---

## 目標

實作「綁定機制」，讓學員輸入教練的邀請碼後，建立資料庫關聯。

---

## 1. 資料庫設計

### 新增集合 `relationships`

用於儲存教練與學員的綁定關係：

```json
{
  "id": "auto-generated",
  "coachId": "String (uid)",
  "studentId": "String (uid)",
  "status": "active",  // active, pending, inactive
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### 新增集合 `invitations`

用於儲存教練產生的邀請碼：

```json
{
  "id": "invite-code (6碼字串)",
  "coachId": "String (uid)",
  "createdAt": "Timestamp",
  "expiresAt": "Timestamp (可選)",
  "isUsed": false,
  "usedAt": "Timestamp (可選)",
  "usedBy": "String (studentId, 可選)"
}
```

**設計決策**：
- 邀請碼為 6 碼隨機字串（大寫字母 + 數字）
- 預設為永久有效（`expiresAt` 可選）
- 可設定為一次性使用（`isUsed` 標記）或永久性（預設）

---

## 2. Model 實作

### Relationship Model

建立 `lib/models/relationship_model.dart`：

```dart
class Relationship {
  final String id;
  final String coachId;
  final String studentId;
  final RelationshipStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // fromMap, toMap, copyWith 方法
}

enum RelationshipStatus {
  active,
  pending,
  inactive
}
```

### Invitation Model

建立 `lib/models/invitation_model.dart`：

```dart
class Invitation {
  final String id;  // 邀請碼（6碼）
  final String coachId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isUsed;
  final DateTime? usedAt;
  final String? usedBy;

  // fromMap, toMap, copyWith 方法
}
```

---

## 3. Service 實作

### Relationship Service

建立 `lib/services/relationship_service.dart` 實作 `IRelationshipService`：

**核心方法**：

```dart
/// 產生邀請碼
/// 返回 6 碼字串
Future<String> generateInviteCode(String coachId) async {
  // 1. 產生 6 碼隨機字串
  // 2. 檢查是否已存在（避免重複）
  // 3. 存入 invitations 集合
  // 4. 返回邀請碼
}

/// 綁定教練（學員使用）
/// 輸入邀請碼，建立綁定關係
Future<Relationship> bindCoach(String inviteCode, String studentId) async {
  // 1. 查詢邀請碼是否有效
  // 2. 檢查是否已使用（如果是一次性）
  // 3. 檢查是否過期
  // 4. 取得 coachId
  // 5. 檢查是否已存在綁定關係
  // 6. 在 relationships 寫入文件
  // 7. 更新 invitation 的 isUsed 狀態（如果是一次性）
  // 8. 返回 Relationship 物件
}

/// 取得教練的所有學員
Future<List<Relationship>> getCoachStudents(String coachId) async {
  // 查詢 relationships 集合，status = active
}

/// 取得學員的教練
Future<Relationship?> getStudentCoach(String studentId) async {
  // 查詢 relationships 集合，status = active
}
```

---

## 4. UI 實作需求

### 教練端 (Coach View)

**位置**：`lib/views/pages/profile_page.dart` 或新增 `lib/views/pages/coach_management_page.dart`

**功能**：
1. **產生邀請碼按鈕**
   - 在「個人頁面」或「學員管理頁」新增按鈕「產生邀請碼」
   - 點擊後顯示 6 碼代碼
   - 提供「複製」功能（使用 `Clipboard.setData`）

2. **學員列表**
   - 顯示所有已綁定的學員
   - 顯示學員名稱、綁定時間
   - 可取消綁定（將 status 設為 `inactive`）

**UI 範例**：

```dart
// 產生邀請碼卡片
Card(
  child: Column(
    children: [
      ElevatedButton(
        onPressed: () async {
          final code = await relationshipService.generateInviteCode(currentUserId);
          // 顯示邀請碼對話框
        },
        child: Text('產生邀請碼'),
      ),
      if (inviteCode != null)
        Text('邀請碼：$inviteCode'),
    ],
  ),
)
```

### 學員端 (Student View)

**位置**：`lib/views/pages/profile_page.dart` 或新增 `lib/views/pages/my_coach_page.dart`

**功能**：
1. **輸入邀請碼**
   - 在「設定」或「我的教練」頁面，新增「輸入邀請碼」的輸入框
   - 輸入後點擊確認按鈕
   - 顯示載入狀態和結果訊息

2. **顯示教練資訊**
   - 如果已綁定，顯示教練名稱、頭像
   - 可取消綁定

**UI 範例**：

```dart
// 輸入邀請碼卡片
Card(
  child: Column(
    children: [
      TextField(
        controller: inviteCodeController,
        decoration: InputDecoration(
          labelText: '輸入邀請碼',
          hintText: '請輸入 6 碼邀請碼',
        ),
      ),
      ElevatedButton(
        onPressed: () async {
          final result = await relationshipService.bindCoach(
            inviteCodeController.text,
            currentUserId,
          );
          // 顯示成功或錯誤訊息
        },
        child: Text('確認綁定'),
      ),
    ],
  ),
)
```

---

## 5. Firestore 規則更新

更新 `firestore.rules`：

```javascript
// relationships 集合
match /relationships/{relationshipId} {
  allow read: if request.auth != null && 
    (resource.data.coachId == request.auth.uid || 
     resource.data.studentId == request.auth.uid);
  allow create: if request.auth != null && 
    request.resource.data.studentId == request.auth.uid;
  allow update, delete: if request.auth != null && 
    (resource.data.coachId == request.auth.uid || 
     resource.data.studentId == request.auth.uid);
}

// invitations 集合
match /invitations/{inviteCode} {
  allow read: if request.auth != null;
  allow create: if request.auth != null;
  allow update: if request.auth != null;
}
```

---

## 執行步驟

1. ✅ **建立 Model**：`RelationshipModel`, `InvitationModel`
2. ✅ **建立 Service 介面**：`IRelationshipService`
3. ✅ **實作 Service**：`RelationshipService`
4. ✅ **註冊到 Service Locator**：在 `service_locator.dart` 中註冊
5. ✅ **建立 Controller**：`RelationshipController`（如果需要）
6. ✅ **實作 UI**：教練端和學員端介面
7. ✅ **更新 Firestore 規則**：添加訪問權限
8. ✅ **測試**：確保功能正常運作

---

## 注意事項

⚠️ **邀請碼唯一性**：確保產生的邀請碼不會重複

⚠️ **權限檢查**：確保只有教練可以產生邀請碼，只有學員可以綁定

⚠️ **錯誤處理**：處理邀請碼無效、已使用、過期等情況

⚠️ **用戶體驗**：提供清晰的錯誤訊息和成功提示

---

## 驗證標準

- [ ] 教練可以產生邀請碼
- [ ] 邀請碼顯示正確且可複製
- [ ] 學員可以輸入邀請碼綁定
- [ ] 綁定關係正確寫入資料庫
- [ ] 教練可以看到學員列表
- [ ] 學員可以看到教練資訊
- [ ] Firestore 規則正確設定
- [ ] 錯誤情況正確處理





