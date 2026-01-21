# StrengthWise v4.0 架構嚴格審查報告

> 版本：v1.1
> 審查日期：2026-01-17
> 更新日期：2026-01-19
> 狀態：✅ 已歸檔

---

## 📋 目錄

- [整體架構評價](#整體架構評價)
- [問題分析](#問題分析)
- [已完成修復](#已完成修復)
- [優先級建議](#優先級建議)
- [結論](#結論)

---

## 整體架構評價

### 優點

| 項目 | 說明 |
|------|------|
| 分層架構 | MVVM + Clean Architecture 4 層分離清晰 |
| 依賴注入 | GetIt Service Locator + Interface 分離良好 |
| 同步機制 | EventBus + Realtime + FCM 三層架構設計合理 |
| 快取策略 | Hive（持久化）+ 記憶體（臨時）雙層快取 |
| 代碼規模 | ~68,000 行，組織結構良好 |

### 專案規模統計

```
核心組件：
├── Pages：65+
├── Controllers：29（含子模組 70+）
├── Services：56+（含 Realtime、Onboarding）
├── Models：67+
├── Widgets：202+
├── Migrations：33 個 SQL 檔案
└── 測試檔案：59 個
```

---

## 已完成修復

### 2026-01-19 修復項目

#### 1. Controller 接口覆蓋 ✅ 已完成

**修復前：** 29 個 Controller，僅 8 個有對應 Interface
**修復後：** 25/29 個 Controller 有對應 Interface

新增接口：
- `IAppointmentController`
- `IProfileController`
- `ISessionModeController`
- `IAvailabilitySlotController`
- `IClientAvailabilityController`
- `ISessionNoteController`
- `IDrawingController`
- `IBodyDataController`
- `ICoachProfileController`
- `IDeleteAccountController`
- `ICoachingRelationshipController`
- `IClientManagementController`
- `ICoachManagementController`
- `IEventBusController`
- `IRealtimeController`
- `IThemeController`
- `IReadinessController`

---

#### 2. 強制解包（!）修復 ✅ 大幅改善

**修復前：** 42 處 `!.uid` 或 `!.id` 強制解包
**修復後：** 8 處（減少 81%）

**修復模式：**
```dart
// ❌ 修復前
final userId = _authController.user!.uid;

// ✅ 修復後（Local Variable Pattern）
final user = _authController.user;
if (user == null) return;
final userId = user.uid;
```

**已修復檔案：**
- Controllers：`profile_controller.dart`、`drawing_controller.dart`、`session_mode_controller.dart`、`client_availability_controller.dart`、`session_note_controller.dart`
- Views：`booking_page.dart`、`session_record_page.dart`、`session_note_card.dart`、`session_note_detail_page.dart`、`session_statistics_tab.dart`、`availability_slot_editor_dialog.dart`、`health_assessment_page.dart`、`health_assessment_summary_card.dart`、`drawing_canvas_painter.dart`、`plan_editor_page.dart`、`client_workout_calendar_tab.dart`、`quick_add_slot_dialog.dart`、`profile_header_card.dart`、`booking_calendar_view.dart`

---

#### 3. BodyDataController 生命週期問題 ✅ 已修復

**問題：** `BodyDataController` 註冊為 `LazySingleton`，但 View 層使用 `ChangeNotifierProvider` 包裝，導致 Tab 銷毀時 singleton 被 dispose

**錯誤訊息：**
```
A BodyDataController was used after being disposed.
```

**修復：**
```dart
// ❌ 修復前：會 dispose singleton
ChangeNotifierProvider(
  create: (_) => serviceLocator<IBodyDataController>()..loadRecords(userId),
  child: ...
)

// ✅ 修復後：不會 dispose singleton
ChangeNotifierProvider.value(
  value: serviceLocator<IBodyDataController>(),
  child: ...
)
```

**修復檔案：** `lib/views/pages/statistics/tabs/body_data_tab.dart`

---

#### 4. connectivity_plus Windows Bug ✅ 已修復

**問題：** Windows 平台的 `connectivity_plus` 有已知 bug，會拋出 `PlatformException(0, NetworkManager::StartListen, null, null)`

**修復：** 在 `NetworkStatusService` 中加入平台檢查，Windows 跳過網路監聽

```dart
if (Platform.isWindows) {
  _isOnline = true;
  _isInitialized = true;
  return; // 跳過網路監聽
}
```

**修復檔案：** `lib/services/core/network_status_service.dart`

---

#### 5. Service ErrorService 統一注入 ✅ 已完成

**修復前：** 4 個 Service 缺少 ErrorService 注入
**修復後：** 全部 Service 已統一注入 ErrorService

**修復檔案：**
- `lib/services/supabase/session_note_service_supabase.dart`
- `lib/services/supabase/client_availability_service_supabase.dart`
- `lib/services/supabase/drawing_service_supabase.dart`
- `lib/services/supabase/invite_code_service_supabase.dart`
- `lib/services/locator/service_registry.dart`（更新註冊）

---

## 問題分析

### 1. Controller 接口覆蓋 ✅ 已解決

> 詳見「已完成修復」章節

---

### 2. dynamic 和 Map<String, dynamic> 使用較多 ⚠️ 中等風險

**現狀：**
- Models 中 `dynamic` 出現 226 次
- `Map<String, dynamic>` 出現 193 次（38 個檔案）

**合理使用場景：**
- `fromSupabase()` / `toMap()` 序列化邊界
- JSONB 欄位解析

**需審查場景：**
- 部分 Model 內部運算使用 dynamic
- 嵌套 JSONB 解析缺少型別斷言

**建議：** 持續優化，逐步替換內部運算的 dynamic

---

### 3. 強制解包（!）使用 ✅ 大幅改善

**修復前：** 42 處
**修復後：** 8 處（減少 81%）

**剩餘位置（已有 null 檢查保護）：**

| 檔案 | 數量 | 說明 |
|------|------|------|
| `booking_page.dart` | 4 處 | Builder 內部，已有前置檢查 |
| `template_editor_page.dart` | 1 處 | 已有前置檢查 |
| `health_assessment_tab.dart` | 1 處 | 已有前置檢查 |
| `client_info_tab.dart` | 1 處 | 已有前置檢查 |
| `slot_editor_dialog.dart` | 1 處 | 已有前置檢查 |

**結論：** ✅ 不需要替換，8 處皆有前置 null 檢查保護，繼續替換屬於過度工程化

---

### 4. 離線/錯誤處理機制不完整 ⚠️ 中等風險

**已實現：**
- `NetworkStatusService`：網路狀態偵測（Windows bug 已修復）
- `OfflineBanner`：離線 UI 提示
- `ErrorHandlingService`：統一錯誤處理

**缺少：**
- 離線時的資料寫入佇列（Write-Through Queue）
- 網路恢復後的自動重試機制

**問題影響：**
- 網路中斷時寫入操作直接失敗
- 無法實現「離線編輯，上線同步」

**建議：** 評估是否需要實現 Offline Queue（視產品需求）

---

### 5. 快取策略不統一 ⚡ 低風險

**現狀：** 5 個獨立的 LocalCacheService

```
lib/services/cache/
├── StatisticsLocalCacheService
├── WorkoutPlanLocalCacheService
├── UserLocalCacheService
├── RelationshipLocalCacheService
└── ExerciseLocalCacheService
```

**問題：**
- 初始化邏輯重複（retry 機制 copy-paste）
- 缺少統一的 LocalCacheManager 入口

**建議：** 已列入未來計劃（低優先級），可後續重構

---

### 6. RLS 策略完整性需驗證 ⚠️ 中等風險

**現狀：**
- 50+ RLS 策略
- 覆蓋 24 個表格

**需關注：**
- 虛擬學員功能需新增 RLS（已在規格書規劃）
- `is_virtual_client_owner()` 輔助函數需建立索引

**建議：** 新功能開發前先審查 RLS 完整性

---

### 7. Realtime 訂閱清理 ✅ 良好

**現狀：** 大部分頁面已正確在 `dispose()` 中清理訂閱

**良好範例：**

```dart
// booking_page.dart
@override
void dispose() {
  _tabController?.dispose();
  _eventSubscription?.cancel();
  _availabilitySubscription?.cancel();
  _unsubscribeFromCoachSlotsRealtime();
  _unsubscribeFromClientAvailabilityRealtime();
  super.dispose();
}
```

**建議：** 維持現有模式，新功能開發時遵循

---

### 8. 測試覆蓋尚需加強 ⚠️ 中等風險

**現狀：** 59 個測試檔案

| 層級 | 測試數 | 組件數 | 覆蓋率 |
|------|--------|--------|--------|
| Models | 14 | 67+ | ~21% |
| Controllers | 15 | 29 | ~52% |
| Services | 7 | 24+ | ~29% |
| Widgets | 4 | 202+ | ~2% |
| Utils | 7 | 20 | ~35% |

**建議：** 優先補充核心 Service 的單元測試
- `WorkoutService`
- `StatisticsService`
- `AppointmentService`

---

### 9. View 層直接使用 serviceLocator ✅ 已審查

**現狀：** View 層調用 `serviceLocator<>` 取得的類型

| 類型 | 數量 | 是否合理 |
|------|------|----------|
| Controller | ~150 處 | ✅ 合理（MVVM 標準做法）|
| ErrorHandlingService | 14 處 | ✅ 基礎設施（錯誤記錄）|
| OnboardingService | 11 處 | ✅ UI 層服務（Coach Mark）|
| SessionRealtimeService | 1 處 | ✅ 即時同步訂閱 |
| **業務 Service** | **0 處** | ✅ 全部透過 Controller |

**結論：** MVVM 架構合規，無需修改

---

### 10. JSONB 欄位缺少 Schema 驗證 ⚡ 低風險

**JSONB 欄位清單：**

| 表格 | 欄位 | 用途 |
|------|------|------|
| `workout_plans` | `exercises` | 動作列表 |
| `session_notes` | `content` | SOAP 內容 |
| `health_assessments` | `injury_history` | 傷病記錄 |
| `coaches` | `specialties`, `certifications` | 專長與證照 |
| `daily_readiness` | `metrics` | 5 項指標 |

**問題：** 資料庫端無 CHECK CONSTRAINT 驗證 JSONB 結構

**建議：** 評估是否需要 JSON Schema 驗證（PostgreSQL 15+）

---

### 11. Migration 命名跳號 ⚡ 低風險

**現狀：** `23 → 32 → 33`（跳過 24-31）

**原因：** 原始 48 個 migration 合併後編號不連續

**建議：** 下次 migration 從 34 開始，保持連續

---

### 12. 部分 Service 缺少 ErrorService 注入 ✅ 已修復

**已完成注入：**

| Service | 狀態 |
|---------|------|
| `SessionNoteServiceSupabase` | ✅ 已注入 ErrorService |
| `ClientAvailabilityServiceSupabase` | ✅ 已注入 ErrorService |
| `DrawingServiceSupabase` | ✅ 已注入 ErrorService |
| `InviteCodeServiceSupabase` | ✅ 已注入 ErrorService |

**修復日期：** 2026-01-19

---

### 13. ChangeNotifierProvider 與 Singleton Controller ✅ 已修復

**問題：** 使用 `ChangeNotifierProvider` 包裝 Singleton Controller 會在 Widget 銷毀時 dispose singleton

**已修復檔案：**
- `body_data_tab.dart`

**正確用法：**
```dart
// Singleton Controller 必須用 .value
ChangeNotifierProvider.value(
  value: serviceLocator<ISingletonController>(),
  child: ...
)

// Factory Controller 可以用 create
ChangeNotifierProvider(
  create: (_) => serviceLocator<IFactoryController>(),
  child: ...
)
```

---

### 14. 未來擴展性考量

#### 14.1 虛擬學員功能整合

根據 `VIRTUAL_CLIENT_SPEC.md`：
- 需修改 `users` 表結構（新增 `is_virtual`、`owner_id`）
- 需新增 RLS 策略（`is_virtual_client_owner()` 函數）
- 需評估對現有 Service/Controller 的影響

#### 14.2 多租戶架構（SaaS）

若未來實現多租戶：
- 現有 RLS 基於 `auth.uid()`
- 可能需要 `tenant_id` 欄位實現租戶隔離
- 需評估 RLS 策略改造成本

#### 14.3 效能擴展

**現有瓶頸：**
- 統計計算在 Client 端進行
- 大量學員時可能需要後端計算

**建議方案：**
- 複雜統計遷移至 PostgreSQL Functions
- 或使用 Supabase Edge Functions

---

## 優先級建議

### 高優先級（Beta 測試前完成）

| 項目 | 工作量 | 狀態 |
|------|--------|------|
| Controller Interface 補充 | 2-3 天 | ✅ 已完成（25/29） |
| 強制解包修復 | 1-2 天 | ✅ 已完成（減少 81%） |
| Service ErrorService 統一注入 | 0.5 天 | ✅ 已完成（4 個 Service） |
| 核心 Service 單元測試補充 | 3-5 天 | 待處理 |

### 中優先級（Beta 測試後優化）

| 項目 | 工作量 | 狀態 |
|------|--------|------|
| View 層 Service 調用審查 | - | ✅ 已審查（合規）|
| 剩餘強制解包替換 | - | ✅ 不需要（8 處皆有前置檢查，非過度工程化）|

### 低優先級（持續優化）

| 項目 | 工作量 | 狀態 |
|------|--------|------|
| LocalCacheManager 統一 | 2-3 天 | 待處理 |
| dynamic 使用審查與替換 | 持續 | 待處理 |

---

## 結論

StrengthWise v4.0 整體架構設計良好，MVVM + Clean Architecture 實施到位。

### v1.1 更新摘要（2026-01-19）

| 項目 | 修復前 | 修復後 |
|------|--------|--------|
| Controller Interface | 8/29 (28%) | 25/29 (86%) |
| 強制解包 `!.uid`/`!.id` | 42 處 | 8 處 (↓81%) |
| BodyDataController 生命週期 | Bug | ✅ 已修復 |
| connectivity_plus Windows | Bug | ✅ 已修復 |
| Service ErrorService 注入 | 4 個缺少 | ✅ 全部完成 |

### Beta 測試前剩餘工作

1. 核心 Service 單元測試補充（3-5 天）

### Beta 後可延後優化

1. 快取架構統一
2. dynamic 使用優化
3. View 層 Service 調用重構

---

## 相關文檔

- [DEVELOPMENT_STATUS.md](../../DEVELOPMENT_STATUS.md) - 開發狀態
- [PROJECT_OVERVIEW.md](../../PROJECT_OVERVIEW.md) - 專案架構
- [SYNC_ARCHITECTURE_SPEC.md](../SYNC_ARCHITECTURE_SPEC.md) - 同步機制
- [VIRTUAL_CLIENT_SPEC.md](../VIRTUAL_CLIENT_SPEC.md) - 虛擬學員規格

---

**審查者**：StrengthWise AI 架構師
**審查標準**：嚴格（生產級品質）
