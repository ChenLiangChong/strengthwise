# 教練評估備註系統實作總結

> 完成日期：2026-01-04  
> 狀態：資料層與服務層完成 ✅ | UI 層待續 🔄

---

## ✅ 已完成 (1-5)

### 1. **資料庫層** - Migration 021

檔案：`migrations/021_coach_assessment_notes.sql`

**創建了**：
- 新表 `coach_assessment_notes`（教練私有備註）
- 每個教練對每個評估只能有一條備註（UNIQUE 約束）
- 完整的 RLS 策略（教練只能看/改自己的）
- 索引優化

**移除了**：
- `health_assessments.coach_notes` 欄位（舊的共用欄位）

**表結構**：
```sql
CREATE TABLE public.coach_assessment_notes (
    id UUID PRIMARY KEY,
    coach_id UUID NOT NULL,          -- 教練 ID
    assessment_id UUID NOT NULL,     -- 評估 ID
    notes TEXT NOT NULL,             -- 備註內容
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    UNIQUE(coach_id, assessment_id)  -- 確保唯一性
);
```

---

### 2. **Model 層**

檔案：`lib/models/coach_assessment_note_model.dart`

```dart
class CoachAssessmentNoteModel {
  final String id;
  final String coachId;
  final String assessmentId;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // fromSupabase(), toSupabase(), copyWith()
}
```

---

### 3. **Service Interface**

檔案：`lib/services/interfaces/i_coach_assessment_note_service.dart`

**提供方法**：
- `getNote()` - 取得教練對某評估的備註
- `upsertNote()` - 建立或更新備註
- `deleteNote()` - 刪除備註
- `getCoachNotes()` - 取得教練的所有備註

---

### 4. **Service 實作**

檔案：`lib/services/supabase/coach_assessment_note_service_supabase.dart`

- 完整實作所有 CRUD 操作
- 錯誤處理與 logging
- Upsert 邏輯（檢查是否存在 → 更新或新增）

---

### 5. **Service 註冊**

檔案：`lib/services/locator/service_registry.dart`

```dart
// 已註冊為 LazySingleton
serviceLocator.registerLazySingleton<ICoachAssessmentNoteService>(
  () => CoachAssessmentNoteServiceSupabase(...)
);
```

---

## 🔄 待完成 (6-7)

### 6. **健康評估表單加入教練備註欄位** (進行中)

檔案：`lib/views/pages/relationships/role_coach/health_assessment_page.dart`

**需要**：
1. 新增 `_coachNotesController` (TextEditingController)
2. 在步驟 5 (緊急聯絡人) 之後新增「教練備註」區塊
   - 僅在**非學員自填模式**時顯示（`!widget.isClientSelfFilling`）
   - MultiLine TextField，至少 4 行
3. 在 `_saveAssessment()` 中：
   - 呼叫 `ICoachAssessmentNoteService.upsertNote()` 儲存備註
   - 注意：備註與評估分開儲存（兩個獨立操作）

**範例程式碼**：

```dart
// 1. 新增 Controller
final _coachNotesController = TextEditingController();

// 2. 在 initState 中初始化（如果是編輯模式且有備註）
// (需要先載入備註...)

// 3. 在步驟 5 之後新增 UI
if (!widget.isClientSelfFilling) {
  const SizedBox(height: 24),
  Text(
    '教練備註（學員不可見）',
    style: theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    ),
  ),
  const SizedBox(height: 8),
  TextFormField(
    controller: _coachNotesController,
    decoration: const InputDecoration(
      labelText: '您的私人備註',
      hintText: '記錄您對此學員健康評估的觀察與建議...',
      border: OutlineInputBorder(),
      alignedLabelStyle: TextAlignVertical.top,
    ),
    maxLines: 4,
    textInputAction: TextInputAction.newline,
  ),
}

// 4. 在 _saveAssessment() 中儲存備註
// 儲存評估後...
if (!widget.isClientSelfFilling && _coachNotesController.text.trim().isNotEmpty) {
  final noteService = serviceLocator<ICoachAssessmentNoteService>();
  final coachId = supabase.auth.currentUser?.id;
  if (coachId != null) {
    await noteService.upsertNote(
      coachId: coachId,
      assessmentId: assessment.id,
      notes: _coachNotesController.text.trim(),
    );
  }
}
```

---

### 7. **健康評估摘要卡片顯示教練備註**

檔案：`lib/views/pages/relationships/role_coach/tabs/client_info_tab.dart`

**已完成**：
- ✅ 新增 `_coachNote` 欄位
- ✅ 註冊 `_assessmentNoteService`
- ✅ Import 相關檔案

**待完成**：
1. 在 `_loadHealthAssessment()` 中載入備註：
   ```dart
   CoachAssessmentNoteModel? note;
   if (assessment != null) {
     final coachId = _authController.user?.uid;
     if (coachId != null) {
       note = await _assessmentNoteService.getNote(
         coachId: coachId,
         assessmentId: assessment.id,
       );
     }
   }
   
   setState(() {
     _coachNote = note;
   });
   ```

2. 傳遞 `coachNote` 給 `HealthAssessmentSummaryCard`：
   ```dart
   HealthAssessmentSummaryCard(
     assessment: _healthAssessment!,
     preferences: _displayPreferences,
     coachNote: _coachNote, // ⭐ 新增
     onViewFull: ...,
     onEdit: ...,
     onConfigurePreferences: ...,
   )
   ```

3. 修改 `HealthAssessmentSummaryCard` widget：
   ```dart
   // 新增參數
   final CoachAssessmentNoteModel? coachNote;
   
   // 在 _buildDynamicFields() 最後加入
   if (coachNote != null && coachNote.notes.isNotEmpty) {
     widgets.add(_buildFieldContainer(
       context,
       icon: Icons.note_outlined,
       title: '我的備註',
       content: coachNote.notes,
     ));
   }
   ```

---

## 📊 架構總覽

```
健康評估系統
├── health_assessments (表)
│   ├── user_id (學員 ID)
│   ├── 問卷內容（PAR-Q+、傷病史、訓練目標...）
│   └── RLS: 學員本人 + 所有教練都能看/改
│
└── coach_assessment_notes (表) ⭐ 新增
    ├── coach_id (教練 ID)
    ├── assessment_id (評估 ID)
    ├── notes (備註內容)
    └── RLS: 僅該教練能看/改（學員完全看不到）
```

**關鍵特性**：
- ✅ 一份評估可以有多個教練備註（教練 A、B、C 各自獨立）
- ✅ 教練之間互不干擾
- ✅ 學員完全看不到任何教練備註（RLS 保證）

---

## 🧪 測試建議

1. **權限測試**：
   - 教練 A 能看到自己的備註
   - 教練 A 看不到教練 B 的備註
   - 學員看不到任何教練備註

2. **CRUD 測試**：
   - 建立備註
   - 更新備註（Upsert）
   - 刪除備註

3. **UI 測試**：
   - 學員自填模式不顯示備註欄位
   - 教練填寫模式顯示備註欄位
   - 摘要卡片正確顯示當前教練的備註

---

## 📝 下一步

1. 完成待辦事項 6 和 7
2. 執行 `flutter analyze` 檢查錯誤
3. 測試權限和功能
4. 更新 `docs/DEVELOPMENT_STATUS.md` 和 `docs/HEALTH_ASSESSMENT_SYSTEM.md`

---

**完成度**：70% ✅  
**剩餘工作量**：約 30 分鐘（UI 整合）

