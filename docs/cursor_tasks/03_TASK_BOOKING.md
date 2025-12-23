# 任務指令：類似 Booking.com 的預約系統

> **前置任務**：必須先完成 `02_TASK_RELATIONSHIPS.md`（教練學員綁定）

---

## 目標

實作核心預約功能：教練設定可預約時段，學員查看並預約課程。

---

## 1. 資料庫設計

### `availabilities` 集合

教練的可預約時段（重複性設定）：

```json
{
  "id": "auto-generated",
  "coachId": "String (uid)",
  "dayOfWeek": 1,  // 1=Monday, 2=Tuesday, ..., 7=Sunday
  "startTime": "09:00",  // HH:mm 格式
  "endTime": "12:00",    // HH:mm 格式
  "isRecurring": true,   // 是否為重複時段
  "isActive": true,      // 是否啟用
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### `appointments` 集合

實際預約單：

```json
{
  "id": "auto-generated",
  "coachId": "String (uid)",
  "studentId": "String (uid)",
  "startTime": "Timestamp",  // 具體日期時間
  "endTime": "Timestamp",    // 具體日期時間
  "status": "confirmed",     // pending, confirmed, cancelled, completed
  "notes": "String (可選)",  // 預約備註
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp",
  "cancelledAt": "Timestamp (可選)",
  "cancelledBy": "String (uid, 可選)"
}
```

**狀態說明**：
- `pending`：待確認（教練需要確認）
- `confirmed`：已確認
- `cancelled`：已取消
- `completed`：已完成

---

## 2. Model 實作

### Availability Model

建立 `lib/models/availability_model.dart`：

```dart
class Availability {
  final String id;
  final String coachId;
  final int dayOfWeek;  // 1-7 (Monday-Sunday)
  final String startTime;  // "HH:mm"
  final String endTime;    // "HH:mm"
  final bool isRecurring;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // fromMap, toMap, copyWith 方法
}
```

### Appointment Model

建立 `lib/models/appointment_model.dart`：

```dart
class Appointment {
  final String id;
  final String coachId;
  final String studentId;
  final DateTime startTime;
  final DateTime endTime;
  final AppointmentStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;

  // fromMap, toMap, copyWith 方法
}

enum AppointmentStatus {
  pending,
  confirmed,
  cancelled,
  completed
}
```

---

## 3. Service 實作

### Availability Service

建立 `lib/services/availability_service.dart`：

```dart
/// 取得教練的所有可預約時段
Future<List<Availability>> getCoachAvailabilities(String coachId) async {}

/// 新增可預約時段
Future<Availability> createAvailability(Availability availability) async {}

/// 更新可預約時段
Future<bool> updateAvailability(Availability availability) async {}

/// 刪除可預約時段
Future<bool> deleteAvailability(String availabilityId) async {}

/// 檢查時段是否可用（考慮已有預約）
Future<bool> isTimeSlotAvailable(
  String coachId,
  DateTime startTime,
  DateTime endTime,
) async {
  // 1. 檢查是否符合 availabilities 設定
  // 2. 檢查該時段是否已有 confirmed 或 pending 的預約
  // 3. 返回是否可用
}
```

### Appointment Service

建立 `lib/services/appointment_service.dart`：

```dart
/// 建立預約
Future<Appointment> createAppointment(Appointment appointment) async {
  // 1. 檢查時段是否可用
  // 2. 檢查教練與學員是否有綁定關係
  // 3. 寫入 appointments 集合
  // 4. 返回 Appointment 物件
}

/// 取得教練的所有預約
Future<List<Appointment>> getCoachAppointments(
  String coachId,
  DateTime? startDate,
  DateTime? endDate,
) async {}

/// 取得學員的所有預約
Future<List<Appointment>> getStudentAppointments(
  String studentId,
  DateTime? startDate,
  DateTime? endDate,
) async {}

/// 取消預約
Future<bool> cancelAppointment(
  String appointmentId,
  String cancelledBy,
) async {
  // 更新 status 為 cancelled
  // 記錄 cancelledAt 和 cancelledBy
}

/// 確認預約（教練端）
Future<bool> confirmAppointment(String appointmentId) async {
  // 更新 status 為 confirmed
}
```

---

## 4. UI 實作需求

### 教練端 - 時段設定

**頁面**：`lib/views/pages/coach_availability_page.dart`

**功能**：
1. **顯示一週七天的列表**
   - 使用 `ListView` 或 `ExpansionTile` 顯示每天
   - 顯示該天的所有可預約時段

2. **新增時段**
   - 選擇星期幾（1-7）
   - 輸入開始時間和結束時間（使用 `TimePicker`）
   - 選擇是否為重複時段
   - 儲存到 `availabilities` 集合

3. **編輯/刪除時段**
   - 可以編輯現有時段
   - 可以刪除時段（軟刪除：設 `isActive = false`）

**UI 範例**：

```dart
ListView.builder(
  itemCount: 7,
  itemBuilder: (context, dayIndex) {
    final dayName = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'][dayIndex];
    return ExpansionTile(
      title: Text(dayName),
      children: [
        // 顯示該天的所有時段
        // 新增時段按鈕
      ],
    );
  },
)
```

### 學員端 - 預約介面

**頁面**：`lib/views/pages/booking_page.dart`（可能已存在，需要擴充）

**功能**：
1. **日曆視圖**
   - 使用 `table_calendar` 套件顯示日曆
   - 標記可預約的日期

2. **選擇日期後顯示時段**
   - 點選日期 → 查詢該教練當天的 `availabilities`
   - 同時查詢該教練當天已有的 `appointments`（避免衝突）
   - 顯示可預約的「空檔時段 (Slots)」

3. **預約流程**
   - 點擊時段 → 彈出確認對話框
   - 顯示日期、時間、教練資訊
   - 可輸入備註（可選）
   - 確認後寫入 `appointments` 集合

**UI 範例**：

```dart
TableCalendar(
  firstDay: DateTime.now(),
  lastDay: DateTime.now().add(Duration(days: 90)),
  focusedDay: _selectedDay,
  onDaySelected: (selectedDay, focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _loadAvailableSlots(selectedDay);
    });
  },
)

// 顯示可用時段
ListView.builder(
  itemCount: availableSlots.length,
  itemBuilder: (context, index) {
    final slot = availableSlots[index];
    return ListTile(
      title: Text('${slot.startTime} - ${slot.endTime}'),
      trailing: ElevatedButton(
        onPressed: () => _bookAppointment(slot),
        child: Text('預約'),
      ),
    );
  },
)
```

---

## 5. 時區處理 ⚠️

**重要**：必須正確處理時區問題！

```dart
// ✅ 正確：使用 UTC 儲存，顯示時轉換為本地時區
final startTime = DateTime.now().toUtc();
await firestore.collection('appointments').add({
  'startTime': Timestamp.fromDate(startTime),
});

// 顯示時轉換為本地時區
final localTime = startTime.toLocal();
```

**建議**：
- Firestore 中儲存 UTC 時間
- UI 顯示時轉換為用戶本地時區
- 使用 `intl` 套件格式化時間

---

## 6. 套件安裝

確認 `pubspec.yaml` 中包含：

```yaml
dependencies:
  table_calendar: ^3.0.9  # 日曆視圖
  intl: ^0.20.2            # 時間格式化
```

如果沒有，請執行：

```bash
flutter pub add table_calendar
flutter pub add intl
```

---

## 7. Firestore 規則更新

更新 `firestore.rules`：

```javascript
// availabilities 集合
match /availabilities/{availabilityId} {
  allow read: if request.auth != null;
  allow create, update, delete: if request.auth != null && 
    resource.data.coachId == request.auth.uid;
}

// appointments 集合
match /appointments/{appointmentId} {
  allow read: if request.auth != null && 
    (resource.data.coachId == request.auth.uid || 
     resource.data.studentId == request.auth.uid);
  allow create: if request.auth != null && 
    request.resource.data.studentId == request.auth.uid;
  allow update: if request.auth != null && 
    (resource.data.coachId == request.auth.uid || 
     resource.data.studentId == request.auth.uid);
}
```

---

## 執行步驟

1. ✅ **安裝套件**：確認 `table_calendar` 和 `intl` 已安裝
2. ✅ **建立 Model**：`AvailabilityModel`, `AppointmentModel`
3. ✅ **建立 Service 介面**：`IAvailabilityService`, `IAppointmentService`
4. ✅ **實作 Service**：`AvailabilityService`, `AppointmentService`
5. ✅ **註冊到 Service Locator**：在 `service_locator.dart` 中註冊
6. ✅ **建立 Controller**：`AvailabilityController`, `AppointmentController`
7. ✅ **實作 UI**：教練端時段設定頁面、學員端預約頁面
8. ✅ **更新 Firestore 規則**：添加訪問權限
9. ✅ **測試時區處理**：確保時間正確顯示
10. ✅ **測試**：確保功能正常運作

---

## 注意事項

⚠️ **時區處理**：必須正確處理 UTC 和本地時區的轉換

⚠️ **衝突檢查**：預約前必須檢查時段是否已被預約

⚠️ **權限檢查**：確保只有綁定的教練和學員可以預約

⚠️ **用戶體驗**：提供清晰的時段顯示和預約確認流程

---

## 驗證標準

- [ ] 教練可以設定可預約時段
- [ ] 時段正確儲存到資料庫
- [ ] 學員可以看到日曆視圖
- [ ] 選擇日期後顯示可用時段
- [ ] 時段正確排除已有預約
- [ ] 學員可以成功預約
- [ ] 預約正確寫入資料庫
- [ ] 時區正確處理
- [ ] Firestore 規則正確設定


