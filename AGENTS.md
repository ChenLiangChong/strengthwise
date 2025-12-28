# StrengthWise - AI Agent 開發指南

> AI 程式碼助手開發規範與最佳實踐

**最後更新**：2024年12月28日 - v2.0 Phase 2 完成（100%）✅

---

## 📖 文檔導航

**核心文檔**（⭐ 必讀）：
1. **[docs/README.md](docs/README.md)** - 📚 文檔導航（入口）
2. **[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)** - 當前開發狀態
   - v1.0 單機版完成 ✅
   - v2.0 Phase 1 完成 ✅（教練學員系統）
   - v2.0 Phase 2 完成 ✅（預約系統 - 100%）⭐
   - Phase 3 計劃（時間管理與筆記）
3. **[docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md)** - 專案架構和技術棧
4. **[docs/DATABASE_SUPABASE.md](docs/DATABASE_SUPABASE.md)** - Supabase PostgreSQL 資料庫設計
5. **[docs/SAAS_PLATFORM_ROADMAP.md](docs/SAAS_PLATFORM_ROADMAP.md)** - 完整 SaaS 計劃（Phase 1-5）

**UI/UX 與部署**：
- **[docs/UI_UX_GUIDELINES.md](docs/UI_UX_GUIDELINES.md)** - UI/UX 設計規範
- **[docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)** - 部署指南

**工具腳本**：
- **[scripts/README.md](scripts/README.md)** - Python 工具腳本（含測試帳號）

**已歸檔文檔**：
- **[docs/archived/](docs/archived/)** - 已完成的重構報告、優化報告、任務文檔
- **[docs/archived/phase1/](docs/archived/phase1/)** - Phase 1 實作指南（已完成）

---

## 🚨 核心開發規則

### 1. 不破壞現有功能 ⭐⭐⭐
- ✅ 修改代碼前先測試
- ✅ 小步提交，確保可編譯
- ❌ 不刪除或破壞現有功能

### 2. 型別安全 ⭐⭐⭐
- ✅ **必須**：透過 Model 的 `.fromSupabase()` 和 `.toMap()` 操作資料庫
- ❌ **禁止**：直接操作 `Map<String, dynamic>`

```dart
// ✅ 正確
final record = WorkoutRecord.fromSupabase(data);
await workoutService.createRecord(record);

// ❌ 錯誤
await supabase.from('workout_plans').insert({'title': 'Test'});
```

### 3. 依賴注入 ⭐⭐⭐
- ✅ **必須**：透過 `serviceLocator` + Interface 使用服務
- ❌ **禁止**：直接實例化服務類別

```dart
// ✅ 正確
final workoutService = serviceLocator<IWorkoutService>();

// ❌ 錯誤
final service = WorkoutServiceSupabase();
```

### 4. 錯誤處理 ⭐⭐
- ✅ 使用 `ErrorHandlingService` 記錄錯誤
- ✅ 控制器層轉換為友善訊息

### 5. 註解規範 ⭐⭐
- ✅ **必須**：關鍵邏輯加**繁體中文註解**
- ✅ **必須**：公共方法使用 `///` Dart Doc 註解
- ✅ **必須**：UI 文字使用繁體中文

### 6. 查詢效能規範 ⭐⭐⭐

**禁止事項**：
- ❌ 使用 `SELECT *`（必須明確指定欄位）
- ❌ 使用 Offset 分頁（深層分頁效能差）
- ❌ N+1 查詢問題（循環中查詢）
- ❌ `COUNT(*)` exact（全表掃描）

**必須遵守**：
- ✅ 使用 Cursor-based 分頁（時間複雜度 O(1)）
- ✅ 為 RLS 欄位建立索引
- ✅ 使用覆蓋索引（Index-Only Scan）
- ✅ JSONB 使用 GIN 索引
- ✅ TSTZRANGE 使用 GiST 索引 + 範圍重疊運算子（`ov`）⭐

```dart
// ❌ 錯誤：SELECT * + Offset 分頁
final data = await supabase
  .from('workout_plans')
  .select()
  .range(100, 119);

// ✅ 正確：明確欄位 + Cursor 分頁
final data = await supabase
  .from('workout_plans')
  .select('id, title, scheduled_date, completed')
  .lt('scheduled_date', lastCursor)
  .order('scheduled_date', ascending: false)
  .limit(20);

// ✅ 正確：TSTZRANGE 範圍查詢（使用 PostgreSQL 範圍重疊運算子）
final data = await supabase
  .from('availability_slots')
  .select('id, coach_id, time_range, is_available')
  .filter('time_range', 'ov', '[${startDate.toIso8601String()},${endDate.toIso8601String()})')
  .order('time_range', ascending: true);
```

### 7. 日期時間處理規範 ⭐⭐⭐

**PostgreSQL 時間戳格式轉換**：

PostgreSQL 返回的時間戳格式與 Dart 的 ISO 8601 格式不同，必須進行轉換：

```dart
/// PostgreSQL 時間戳格式轉換
/// 
/// PostgreSQL 格式：
///   - 無引號：2025-12-15 09:00:00+00
///   - 有引號："2025-12-15 09:00:00+00"
/// 
/// Dart ISO 8601 格式：
///   - 2025-12-15T09:00:00+00:00
/// 
/// 轉換步驟：
///   1. 移除引號（如果有）
///   2. 替換第一個空格為 'T'
///   3. 規範化時區（+00 → +00:00）
static DateTime _parsePostgresTimestamp(String timestamp) {
  // 步驟 1：移除引號並修剪空白
  String cleaned = timestamp.trim();
  if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
    cleaned = cleaned.substring(1, cleaned.length - 1);
  }

  // 步驟 2：替換第一個空格為 'T'
  cleaned = cleaned.replaceFirst(' ', 'T');

  // 步驟 3：規範化時區格式（+00 → +00:00）
  // 使用正則表達式精確匹配時區部分
  final timezoneRegex = RegExp(r'([+-]\d{2})$');
  if (timezoneRegex.hasMatch(cleaned)) {
    cleaned = cleaned.replaceFirstMapped(
      timezoneRegex,
      (match) => '${match.group(1)}:00',
    );
  }

  return DateTime.parse(cleaned);
}
```

**使用場景**：

1. **TSTZRANGE 解析**（`AvailabilitySlotModel`, `AppointmentModel`）：
```dart
factory AvailabilitySlotModel.fromSupabase(Map<String, dynamic> json) {
  final timeRangeStr = json['time_range'] as String;
  final range = _parseTimeRange(timeRangeStr); // 使用 _parsePostgresTimestamp
  
  return AvailabilitySlotModel(
    startTime: range['start']!,
    endTime: range['end']!,
    // ...
  );
}

static Map<String, DateTime> _parseTimeRange(String rangeStr) {
  // 格式："[2025-12-15 09:00:00+00,2025-12-15 10:00:00+00)"
  final cleaned = rangeStr.replaceAll('"', '').trim();
  final inner = cleaned.substring(1, cleaned.length - 1);
  final parts = inner.split(',');
  
  return {
    'start': _parsePostgresTimestamp(parts[0]),
    'end': _parsePostgresTimestamp(parts[1]),
  };
}
```

2. **UTC/本地時間轉換**：
```dart
// ✅ 日曆視圖：比較本地時間
List<AvailabilitySlotModel> _getSlotsForDay(DateTime day) {
  return widget.slots.where((slot) {
    final slotDate = slot.startTime.toLocal(); // 轉換為本地時間
    return slotDate.year == day.year &&
           slotDate.month == day.month &&
           slotDate.day == day.day;
  }).toList();
}

// ✅ 資料庫查詢：使用 UTC 時間
final data = await supabase
  .from('availability_slots')
  .filter('time_range', 'ov', '[${startDate.toUtc().toIso8601String()},${endDate.toUtc().toIso8601String()})');
```

**常見錯誤**：
- ❌ 直接使用 `DateTime.parse()` 解析 PostgreSQL 時間戳
- ❌ 混淆 UTC 和本地時間
- ❌ 忘記規範化時區格式（+00 vs +00:00）

---

## 🗄️ 資料庫重要約定

### 1. workout_plans 表格（統一）

**架構**：
```
workout_plans（PostgreSQL 表格）
├── completed: false  → 未完成的訓練計劃
└── completed: true   → 已完成的訓練記錄
```

**必須包含欄位**：
```dart
{
  'id': TEXT,              // Firestore 相容 ID（20 字符）
  'user_id': UUID,
  'trainee_id': UUID,      // 受訓者 ID
  'creator_id': UUID,      // 創建者 ID
  'completed': bool,
  'scheduled_date': TIMESTAMPTZ,
  'exercises': JSONB,
}
```

### 2. 使用 Service Interface

**重要**：所有 View 層和 Controller 層必須透過 Interface 使用服務

```dart
// ✅ 正確
final workoutService = serviceLocator<IWorkoutService>();
await workoutService.createRecord(record);

// ❌ 禁止
await Supabase.instance.client.from('workout_plans').insert(...);
```

### 3. Snake_case 轉換

Supabase 使用 `snake_case`，Dart 使用 `camelCase`：

```dart
factory UserModel.fromSupabase(Map<String, dynamic> json) {
  return UserModel(
    uid: json['id'] as String,
    displayName: json['display_name'] as String?,
    isCoach: json['is_coach'] as bool? ?? false,
  );
}
```

---

## 🚀 開發流程

### 新增功能標準流程

```
1. 設計 Model (lib/models/)
   ├── 實作 fromSupabase()
   └── 實作 toMap()
   ↓
2. 創建 Service Interface (lib/services/interfaces/)
   ↓
3. 實作 Service (lib/services/)
   ↓
4. 註冊到 Service Locator
   ↓
5. 創建 Controller (lib/controllers/)
   ├── 繼承 ChangeNotifier
   └── 透過 Interface 注入依賴
   ↓
6. 建立 UI (lib/views/pages/)
   ↓
7. 測試並驗證
```

---

## 🎯 當前開發狀態

**🎉 StrengthWise 單機版正式完成**（2024-12-28）⭐⭐⭐

**v1.0 單機版**（2024-12-24 完成）：
- ✅ 訓練計劃管理（創建、編輯、模板、執行）
- ✅ 專業統計系統（力量進步、趨勢分析、熱力圖）
- ✅ 身體數據追蹤（體重、體脂、BMI、每日一筆）
- ✅ 自訂動作功能（CRUD + 統計整合）
- ✅ Google Sign-In 登入（Android APK 可用）
- ✅ 資料庫效能優化（查詢提升 80-99%）
- ✅ 全代碼解耦合（Clean Architecture 100%）
- ✅ 主線程優化（卡頓 -96%）

**v2.0 Phase 1：教練學員系統**（2024-12-28 完成）：
1. **資料庫層** ✅
   - `coaching_relationships` 表 + RLS 策略
   - Migration SQL 腳本（235 行）

2. **後端層（完全解耦）** ✅
   - Model: `CoachingRelationshipModel`
   - Service Interface + 實現（3 子模組）
   - Controller: `CoachingRelationshipController`

3. **UI 層（6 個組件）** ✅
   - 學員管理主頁面
   - 邀請學員 Dialog（雙測試帳號按鈕）
   - 學員列表卡片
   - 狀態標籤、空狀態等

4. **功能特色** ✅
   - 邀請學員（UUID 直接綁定）
   - 學員列表（統計 + 篩選）
   - 狀態管理（活躍/待接受/已歸檔）
   - 歸檔與刪除
   - 重複綁定檢查
   - 開發測試輔助

5. **測試結果** ✅
   - 雙設備（VM + 手機）測試通過
   - 雙向綁定成功
   - 所有功能正常運作

**新增檔案**：17 個（Model 1 + Service 5 + Controller 1 + UI 7 + Migration 1 + Doc 2）

**v2.0 Phase 2：預約系統**（2024-12-28 完成）✅：

**✅ 已完成**（100%）：
1. **資料庫層** ✅
   - `availability_slots` 表（教練可用時段）
   - `appointments` 表（預約記錄）
   - TSTZRANGE 時間範圍類型
   - GiST 排除約束（物理層防止雙重預約）
   - 10 個 RLS 策略

2. **Model 層** ✅
   - `AppointmentModel`（含狀態機）
   - `AvailabilitySlotModel`（含 RRULE）
   - `TstzRange` 輔助類別
   - PostgreSQL 時間戳解析 ⭐

3. **Service 層** ✅
   - Interface: `IAppointmentService` + `IAvailabilitySlotService`
   - 實現: `AppointmentServiceSupabase` + `AvailabilitySlotServiceSupabase`
   - Service Locator 註冊

4. **後端測試** ✅（8/8 通過）
   - 創建時段 ✅
   - 創建預約 ✅
   - 雙重預約防護 ✅ ⭐ 核心功能驗證成功
   - 確認預約 ✅
   - RLS 策略 ✅
   - 可用時段查詢 ✅
   - 取消預約 ✅
   - 清理數據 ✅

5. **Controller 層** ✅（完全解耦 + 子模組化）
   - `AppointmentController`（308 行）+ 4 個子模組
   - `AvailabilitySlotController`（324 行）+ 4 個子模組
   - 註冊到 Service Locator

6. **UI 層** ✅（8 個頁面 + 20+ 組件）
   - 教練管理中心（`CoachHubPage`）- 3 個 Tab
   - 學員預約中心（`ClientHubPage`）- 2 個 Tab
   - 教練時段管理頁面（343 行 + 8 個組件）
   - 學員預約頁面
   - 預約列表頁面
   - 預約詳情頁面

7. **功能測試** ✅（12/12 通過）
   - 教練創建時段 ✅
   - 學員查看時段 ✅
   - 學員預約 ✅
   - 教練確認/拒絕 ✅
   - 學員取消 ✅
   - 教練取消 ✅
   - 預約列表 ✅
   - 預約詳情 ✅
   - 下拉刷新 ✅
   - 狀態篩選 ✅
   - 雙角色支援 ✅

**技術亮點**：
- ✅ PostgreSQL TSTZRANGE 正常運作
- ✅ GiST 排除約束物理層防止雙重預約 ⭐
- ✅ 10 個 RLS 策略保護資料安全
- ✅ 狀態機完整運作
- ✅ iCal RRULE 支援週期性時段
- ✅ Controller 子模組化設計（8 個子模組）
- ✅ UI 組件化設計（平均 ~60 行/組件）
- ✅ 雙角色支援（教練/學員同時可見）
- ✅ PostgreSQL 時間戳正確解析 ⭐

**新增檔案**：35 個（Model 2 + Service 4 + Controller 10 + UI 28 + Migration 1）

**今天修復的問題**（12 個）：
1. ✅ UI 渲染錯誤（`BoxConstraints` infinite width）
2. ✅ 依賴注入錯誤（`IAuthController` 統一使用）
3. ✅ 教練名稱顯示（`getUserProfile` 查詢）
4. ✅ 時間格式解析（PostgreSQL → ISO 8601）⭐ 核心修復
5. ✅ 查詢邏輯（使用 PostgreSQL 範圍重疊運算子 `ov`）
6. ✅ 空 UUID 問題（`toMap(includeId: false)`）
7. ✅ null 轉換錯誤（明確型別轉換）
8. ✅ 日曆時段顯示（UTC/本地時間轉換）
9. ✅ 教練取消預約功能
10. ✅ 取消原因動態設置
11. ✅ 預約詳情頁面路由
12. ✅ TabController 狀態重置

**Phase 2 完成時間**：1 天（2024-12-28）✅

**效能提升總覽**：
- **應用啟動**：2.5s+ → **200ms** ⚡ 92%+
- **主線程卡頓**：721 frames → **<30 frames** ⚡ 96%+
- 統計頁面：2-5s → **秒開（<5ms）** ⚡ 99%+
- 頁面切換（快取）：200-500ms → **<5ms** ⚡ 99%+

**架構驗證**（完美的 Clean Architecture）：
- ✅ Controller 層使用 Interface：100%
- ✅ View 層使用 Interface：100%
- ✅ 直接 Supabase 調用：0 處
- ✅ 主線程優化：<30 frames skip
- ✅ 全代碼解耦合完成

詳見：[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)

---

## 🔍 常見問題排查

### 服務未初始化
```dart
await setupServiceLocator();
print(serviceLocator.isRegistered<IWorkoutService>());
```

### 型別轉換錯誤
```dart
// ✅ 使用 Model
final user = UserModel.fromSupabase(data);

// ❌ 直接轉換
final user = data as UserModel;  // 會出錯
```

### 狀態不更新
```dart
// 確保呼叫 notifyListeners()
setState(() {
  _data = newData;
});
notifyListeners();  // ← 必須
```

---

## ⚙️ 開發最佳實踐

### 修復 Bug 流程
1. 理解問題根源
2. 查看相關代碼
3. 設計解決方案
4. 小步驟修改
5. 測試驗證
6. 更新文檔

### 常見錯誤預防
- ✅ 使用持久的 `TextEditingController`
- ✅ 異步操作完成後再關閉 Dialog
- ✅ 查詢時同時查 `trainee_id` 和 `creator_id`
- ✅ 使用 `WorkoutService.updateRecord()` 更新記錄
- ✅ View 層必須透過 Interface 使用服務

---

## 📚 相關文檔

### 核心文檔
- **[docs/README.md](docs/README.md)** - 📚 文檔導航（入口）
- **[docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md)** - 專案架構總覽
- **[docs/DATABASE_SUPABASE.md](docs/DATABASE_SUPABASE.md)** - Supabase PostgreSQL 資料庫設計（完整）
- **[docs/DATABASE_OPTIMIZATION_GUIDE.md](docs/DATABASE_OPTIMIZATION_GUIDE.md)** - 資料庫優化指南
- **[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)** - 開發狀態和下一步任務（含性能優化總覽）
- **[docs/UI_UX_GUIDELINES.md](docs/UI_UX_GUIDELINES.md)** - UI/UX 設計規範
- **[docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)** - 部署指南

### 已歸檔文檔（供參考）
- **[docs/archived/README.md](docs/archived/README.md)** - 歸檔文檔導航
- **重構與優化報告**：主線程優化、性能瓶頸分析、架構重構指南
- **階段性任務文檔**：個人資料優化、通知系統、模板除錯

### 工具腳本
- **[scripts/README.md](scripts/README.md)** - Python 工具腳本使用指南

---

**開始開發前，務必先閱讀 [docs/README.md](docs/README.md) 了解文檔結構！**
