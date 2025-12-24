# 任務指令：教學筆記與課表整合

> **前置任務**：必須先完成 `03_TASK_BOOKING.md`（預約系統）

---

## 目標

將現有的 `notes`（繪圖）與 `workoutPlans`（課表）整合進 `appointments`（預約課程）中，讓教練可以在上課時記錄筆記和課表。

---

## 1. 資料庫調整

### 更新 Note Model

**不需要刪除舊資料**，但新產生的 `notes` 必須包含 `appointmentId`。

更新 `lib/models/note_model.dart`：

```dart
class Note {
  final String id;
  final String userId;  // 建立者（教練）
  final String? appointmentId;  // 新增：關聯到哪一堂課
  final String? studentId;      // 新增：針對哪位學生
  final String title;
  final String? textContent;   // 新增：純文字筆記（已存在）
  final List<DrawingPoint>? drawingPoints;  // 繪圖軌跡（原有）
  final DateTime createdAt;
  final DateTime updatedAt;

  // fromMap, toMap, copyWith 方法
  // 注意：fromMap 需要向後兼容，appointmentId 和 studentId 可為 null
}
```

**欄位說明**：
- `appointmentId`：關聯到 `appointments` 集合的 ID（可選，用於課程筆記）
- `studentId`：針對的學員 ID（可選，用於學員特定筆記）
- `textContent`：純文字筆記（已存在，確認支援）
- `drawingPoints`：繪圖軌跡（原有功能，保留）

---

## 2. 更新 Note Service

更新 `lib/services/note_service.dart`：

```dart
/// 取得特定課程的所有筆記
Future<List<Note>> getNotesByAppointment(String appointmentId) async {
  // 查詢 notes 集合，appointmentId = appointmentId
}

/// 取得針對特定學員的所有筆記
Future<List<Note>> getNotesByStudent(String studentId) async {
  // 查詢 notes 集合，studentId = studentId
}

/// 建立課程筆記
Future<Note> createSessionNote({
  required String userId,
  required String appointmentId,
  required String studentId,
  String? title,
  String? textContent,
  List<DrawingPoint>? drawingPoints,
}) async {
  // 建立 Note，包含 appointmentId 和 studentId
}
```

---

## 3. UI 流程優化

### 教練上課模式 (Coach Session View)

**頁面**：`lib/views/pages/session_detail_page.dart`（新建）

**功能**：

1. **頁面參數**
   ```dart
   class SessionDetailPage extends StatelessWidget {
     final String appointmentId;
     final String studentId;
     // ...
   }
   ```

2. **學員資訊卡**
   - 顯示學員名字、頭像
   - 顯示上次訓練重點（從 notes 中取得）
   - 顯示學員基本資訊（身高、體重等）

3. **今日課表區**
   - 顯示該預約課程的課表（從 `workoutPlans` 匯入）
   - 允許教練現場新增動作
   - 可以編輯動作的組數、重量等

4. **筆記區**
   - **繪圖功能**：使用現有的 Canvas 繪圖功能
   - **文字輸入**：`TextField` 或 `TextFormField` 輸入文字筆記
   - **儲存按鈕**：將筆記儲存，標記 `appointmentId` 和 `studentId`

5. **課表匯入**
   - 可以從 `workoutPlans` 選擇一個計劃匯入
   - 或建立新的課表

**UI 結構**：

```dart
Scaffold(
  appBar: AppBar(title: Text('上課記錄')),
  body: Column(
    children: [
      // 學員資訊卡
      StudentInfoCard(studentId: studentId),
      
      // 今日課表
      Expanded(
        child: WorkoutPlanSection(
          appointmentId: appointmentId,
          studentId: studentId,
        ),
      ),
      
      // 筆記區（TabView）
      Expanded(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: '文字筆記'),
                  Tab(text: '繪圖筆記'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    TextNoteEditor(
                      appointmentId: appointmentId,
                      studentId: studentId,
                    ),
                    DrawingBoard(
                      appointmentId: appointmentId,
                      studentId: studentId,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
)
```

---

## 4. 重構繪圖功能

### 建立可複用的 DrawingBoard Widget

**檔案**：`lib/views/widgets/drawing_board.dart`

**功能**：
- 將現有的 Canvas 繪圖功能重構為獨立 Widget
- 支援傳入 `appointmentId` 和 `studentId`
- 可以載入現有筆記的 `drawingPoints`
- 儲存時自動關聯到課程

**範例**：

```dart
class DrawingBoard extends StatefulWidget {
  final String? appointmentId;
  final String? studentId;
  final List<DrawingPoint>? initialPoints;  // 載入現有筆記
  
  const DrawingBoard({
    Key? key,
    this.appointmentId,
    this.studentId,
    this.initialPoints,
  }) : super(key: key);

  @override
  State<DrawingBoard> createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  List<DrawingPoint> _points = [];
  
  @override
  void initState() {
    super.initState();
    if (widget.initialPoints != null) {
      _points = widget.initialPoints!;
    }
  }
  
  Future<void> _saveDrawing() async {
    final noteService = serviceLocator<INoteService>();
    await noteService.createSessionNote(
      userId: currentUserId,
      appointmentId: widget.appointmentId!,
      studentId: widget.studentId!,
      drawingPoints: _points,
    );
  }
  
  // ... 繪圖邏輯
}
```

---

## 5. 課表整合

### 從 WorkoutPlans 匯入課表

在 `SessionDetailPage` 中添加功能：

```dart
/// 匯入課表到課程
Future<void> importWorkoutPlan(String planId) async {
  // 1. 取得 workoutPlan
  // 2. 將 exercises 複製到 appointment 的課表欄位
  // 3. 或建立新的 workoutRecord 關聯到 appointment
}
```

**設計決策**：
- 可以在 `appointments` 集合中添加 `workoutPlanId` 欄位
- 或建立 `appointmentWorkouts` 子集合
- 或使用現有的 `workoutPlans` 集合，添加 `appointmentId` 欄位

---

## 6. 導航流程

### 從預約列表進入上課頁面

**更新**：`lib/views/pages/booking_page.dart` 或 `lib/views/pages/appointments_page.dart`

```dart
// 在預約列表中，點擊已確認的預約
ListTile(
  title: Text('${appointment.startTime} - ${appointment.endTime}'),
  subtitle: Text('學員：${studentName}'),
  trailing: appointment.status == AppointmentStatus.confirmed
    ? ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionDetailPage(
                appointmentId: appointment.id,
                studentId: appointment.studentId,
              ),
            ),
          );
        },
        child: Text('開始上課'),
      )
    : null,
)
```

---

## 7. Firestore 規則更新

更新 `firestore.rules`：

```javascript
// notes 集合（更新規則）
match /notes/{noteId} {
  allow read: if request.auth != null && 
    (resource.data.userId == request.auth.uid || 
     resource.data.studentId == request.auth.uid);
  allow create: if request.auth != null && 
    request.resource.data.userId == request.auth.uid;
  allow update, delete: if request.auth != null && 
    resource.data.userId == request.auth.uid;
}
```

---

## 執行步驟

1. ✅ **更新 NoteModel**：添加 `appointmentId` 和 `studentId` 欄位
2. ✅ **更新 NoteService**：添加課程筆記相關方法
3. ✅ **重構繪圖功能**：建立 `DrawingBoard` Widget
4. ✅ **建立 SessionDetailPage**：教練上課頁面
5. ✅ **實作學員資訊卡**：顯示學員資訊
6. ✅ **實作課表區**：顯示和編輯課表
7. ✅ **實作筆記區**：文字和繪圖筆記
8. ✅ **更新導航**：從預約列表進入上課頁面
9. ✅ **更新 Firestore 規則**：添加訪問權限
10. ✅ **測試**：確保功能正常運作

---

## 注意事項

⚠️ **向後兼容**：`NoteModel.fromMap` 必須支援沒有 `appointmentId` 和 `studentId` 的舊資料

⚠️ **權限檢查**：確保只有教練可以建立課程筆記

⚠️ **資料關聯**：確保 `appointmentId` 正確關聯到 `appointments` 集合

⚠️ **用戶體驗**：提供清晰的筆記儲存和載入流程

---

## 驗證標準

- [ ] `NoteModel` 包含 `appointmentId` 和 `studentId` 欄位
- [ ] `fromMap` 方法支援向後兼容
- [ ] `DrawingBoard` Widget 可以獨立使用
- [ ] `SessionDetailPage` 正確顯示學員資訊
- [ ] 可以匯入和編輯課表
- [ ] 可以建立文字和繪圖筆記
- [ ] 筆記正確關聯到課程
- [ ] 可以從預約列表進入上課頁面
- [ ] Firestore 規則正確設定

---

**完成後**：教練可以在上課時記錄筆記和課表，所有資料都關聯到具體的預約課程。





