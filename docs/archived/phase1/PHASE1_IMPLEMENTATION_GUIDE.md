# v2.0 Phase 1 實施指南

> 教練-學員綁定機制完整實施流程

**創建時間**：2024-12-28  
**當前進度**：✅ 代碼完成，⏳ 待執行 Migration

---

## 📋 完成進度總覽

| 階段 | 任務 | 狀態 |
|------|------|------|
| 1.1 | 資料庫架構設計 | ✅ 完成 |
| 1.2 | Migration SQL 腳本 | ✅ 完成 |
| 1.3 | 執行 Migration 到 Supabase | ⏳ 待執行 |
| 1.4 | 創建 Model 和 Service Interface | ✅ 完成 |
| 1.5 | 實作 CoachingRelationshipService | ✅ 完成 |
| 1.6 | 實作 Controller 層 | ✅ 完成 |
| 1.7 | Flutter UI - 教練邀請學員介面 | ⏳ 待開發 |
| 1.8 | Flutter UI - 學員列表顯示 | ⏳ 待開發 |
| 1.9 | 測試邀請流程（手動綁定） | ⏳ 待測試 |
| 1.10 | Edge Function 開發（郵件邀請） | 📋 Phase 1 結束後 |

---

## 🎯 階段 1.3：執行 Migration 到 Supabase

### 方法 1：Supabase Dashboard（推薦）✅

**步驟**：

1. **開啟 Supabase Dashboard**
   - 前往：https://supabase.com/dashboard
   - 登入你的帳號
   - 選擇你的專案（當前開發專案）

2. **進入 SQL Editor**
   - 左側選單：`SQL Editor`
   - 點擊 `+ New query`

3. **複製並執行 Migration**
   - 開啟檔案：`migrations/021_phase1_coaching_relationships.sql`
   - 全選複製（Ctrl+A, Ctrl+C）
   - 貼到 SQL Editor
   - 點擊右下角 `Run` 按鈕 ▶️

4. **驗證執行結果**
   - 如果成功，會顯示：`Success. No rows returned`
   - 檢查最後的查詢結果：應該顯示「coaching_relationships 表格已建立」

5. **檢查表格**
   - 左側選單：`Table Editor`
   - 應該看到新表格：`coaching_relationships`
   - 點擊查看欄位結構

---

### 方法 2：使用 Supabase CLI（進階）

```bash
# 1. 安裝 Supabase CLI（如果還沒安裝）
npm install -g supabase

# 2. 登入 Supabase
supabase login

# 3. 連結到你的專案
supabase link --project-ref YOUR_PROJECT_REF

# 4. 執行 Migration
supabase db push --file migrations/021_phase1_coaching_relationships.sql
```

---

## 🖥️ 階段 1.7-1.8：建立 Flutter UI

### 需要創建的頁面

#### 1. **教練端：學員管理頁面** 📋

**路徑**：`lib/views/pages/coach/clients_management_page.dart`

**功能**：
- 顯示學員列表（含頭像、姓名、Email）
- 顯示活躍學員數量
- 「邀請學員」按鈕
- 每個學員有「歸檔」、「備註」選項

**UI 草圖**：
```
┌──────────────────────────────────────┐
│  學員管理                             │
│  ────────────────────────────────────│
│  活躍學員：5 人                        │
│                                       │
│  [+ 邀請學員]                         │
│                                       │
│  ┌────────────────────────────────┐  │
│  │ 👤 張三                         │  │
│  │    zhangsan@example.com        │  │
│  │    [歸檔] [備註]               │  │
│  └────────────────────────────────┘  │
│                                       │
│  ┌────────────────────────────────┐  │
│  │ 👤 李四                         │  │
│  │    lisi@example.com            │  │
│  │    [歸檔] [備註]               │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

#### 2. **邀請學員對話框**

**路徑**：`lib/views/pages/coach/widgets/invite_client_dialog.dart`

**功能**：
- Email 輸入框
- 備註輸入框（可選）
- 確認/取消按鈕

#### 3. **學員端：教練列表頁面**

**路徑**：`lib/views/pages/client/my_coaches_page.dart`

**功能**：
- 顯示已綁定的教練列表
- 顯示待處理的邀請（pending）
- 接受/拒絕邀請按鈕

---

## 🧪 階段 1.9：測試邀請流程

### 測試步驟（手動綁定）

#### 測試環境準備

1. **創建測試用戶**（如果還沒有）
   - 註冊教練帳號（設置 `is_coach = true`）
   - 註冊學員帳號（`is_student = true`）

2. **獲取用戶 ID**
   - Supabase Dashboard → `Table Editor` → `users`
   - 複製兩個用戶的 `id`（UUID）

#### 測試場景 1：手動建立綁定關係

**方式 1：透過 SQL Editor**

```sql
-- 創建活躍綁定關係
INSERT INTO public.coaching_relationships (
  coach_id,
  client_id,
  status,
  notes
) VALUES (
  'COACH_UUID',      -- 替換為教練的 UUID
  'CLIENT_UUID',     -- 替換為學員的 UUID
  'active',
  '測試學員'
);
```

**方式 2：透過 Flutter App**（需要先實作 UI）

```dart
// 在個人資料頁面添加測試按鈕
final controller = serviceLocator<CoachingRelationshipController>();

await controller.createRelationship(
  coachId: currentUser.uid,
  clientId: 'TARGET_CLIENT_ID',
  status: 'active',
  notes: '測試學員',
);
```

#### 測試場景 2：邀請流程（pending → active）

**步驟**：

1. **教練邀請學員**（創建 pending 關係）
```dart
await controller.inviteClient(
  coachId: currentUser.uid,
  clientEmail: 'client@example.com',
);
```

2. **學員查看待處理邀請**
```dart
await controller.loadPendingInvitations(currentUser.uid);
```

3. **學員接受邀請**
```dart
await controller.acceptInvitation(
  relationshipId: invitation.id,
  clientId: currentUser.uid,
);
```

4. **驗證狀態變更**
   - Supabase Dashboard → `Table Editor` → `coaching_relationships`
   - 確認 `status` 已變更為 `active`
   - 確認 `accepted_at` 有時間戳記

---

## 🔍 測試檢查清單

### 資料庫層測試

- [ ] `coaching_relationships` 表格已建立
- [ ] 17 個欄位全部存在
- [ ] RLS 策略已啟用
- [ ] 索引已建立（4 個）
- [ ] 觸發器運作正常（`updated_at` 自動更新）
- [ ] 唯一約束生效（同一教練-學員不可重複綁定）

### Service 層測試

- [ ] `getCoachClients()` 返回正確的學員列表
- [ ] `inviteClient()` 可成功創建 pending 關係
- [ ] `acceptInvitation()` 可將狀態改為 active
- [ ] `isActiveRelationship()` 正確檢查關係狀態
- [ ] 快取機制運作正常（5 分鐘有效期）

### Controller 層測試

- [ ] `loadCoachClients()` 正確載入並更新 UI
- [ ] `inviteClient()` 成功後重新載入列表
- [ ] `acceptInvitation()` 成功後清除 pending 列表
- [ ] 錯誤訊息正確顯示（`_errorMessage`）
- [ ] Loading 狀態正確切換（`_isLoading`）

### UI 層測試（待實作）

- [ ] 教練可看到學員列表
- [ ] 教練可邀請學員（輸入 Email）
- [ ] 學員可看到待處理邀請
- [ ] 學員可接受/拒絕邀請
- [ ] 數據隔離：教練 A 看不到教練 B 的學員

---

## 🚀 下一步行動

### 立即可做

1. **執行 Migration** ⭐⭐⭐
   - 開啟 Supabase Dashboard
   - 執行 `021_phase1_coaching_relationships.sql`
   - 驗證表格建立成功

2. **測試 Service 層**
   - 使用 SQL Editor 手動插入測試數據
   - 開啟 App，確認快取和查詢運作正常

3. **創建基礎 UI**（簡化版測試）
   - 在個人資料頁面添加「學員管理」按鈕
   - 創建簡單的學員列表頁面

### 後續開發（Phase 1 完成後）

4. **完整 UI 開發**
   - 教練端：學員管理頁面（完整功能）
   - 學員端：教練列表頁面
   - 邀請對話框、備註編輯器

5. **Edge Function 開發**（Phase 1 結束）
   - 實作郵件邀請系統
   - 整合 Resend 服務
   - 自動綁定流程

---

## 📊 關於「生產環境」的說明

### 什麼時候建立生產環境？

**答案**：**Phase 5（精細化與上線準備）** 才建立！

```
當前開發流程：
┌─────────────────────────────────────┐
│  Phase 1-4：開發與測試               │
│  ├── 使用當前 Supabase 專案         │
│  ├── 隨意測試、刪除資料             │
│  └── 完成所有功能開發               │
└─────────────────────────────────────┘
            ↓
┌─────────────────────────────────────┐
│  Phase 5：上線準備                  │
│  ├── 建立新的 Supabase 專案         │
│  ├── 執行所有 Migration             │
│  ├── 數據遷移（如果需要）           │
│  └── 配置生產環境設定               │
└─────────────────────────────────────┘
            ↓
┌─────────────────────────────────────┐
│  正式上線                            │
│  └── 開放給真實用戶使用             │
└─────────────────────────────────────┘
```

### 為什麼不現在建立？

1. **避免重複付費**：Supabase 按專案數收費
2. **開發彈性**：開發環境可以隨意測試、刪除資料
3. **節省時間**：避免在兩個專案間同步 Migration
4. **風險降低**：確保所有功能完整測試後再上線

### 生產環境 vs 開發環境

| 項目 | 開發環境（當前） | 生產環境（未來） |
|------|-----------------|-----------------|
| **用途** | 開發測試 | 真實用戶使用 |
| **資料** | 測試資料（可刪除） | 真實資料（不可丟失） |
| **錯誤** | 可以有 Bug | 必須穩定運行 |
| **費用** | 已在使用中 | Phase 5 再建立 |
| **Supabase 專案** | 當前專案 | 新專案 |

---

## 📁 已創建的檔案

### Migration
- ✅ `migrations/021_phase1_coaching_relationships.sql`（270 行）

### Model
- ✅ `lib/models/coaching_relationship_model.dart`（93 行）

### Service Layer
- ✅ `lib/services/interfaces/i_coaching_relationship_service.dart`（129 行）
- ✅ `lib/services/supabase/coaching_relationship_service_supabase.dart`（338 行）
- ✅ `lib/services/supabase/coaching_relationship/` 子模組：
  - `coaching_relationship_query.dart`（140 行）
  - `coaching_relationship_operations.dart`（138 行）
  - `coaching_relationship_cache_manager.dart`（135 行）

### Controller Layer
- ✅ `lib/controllers/coaching_relationship_controller.dart`（339 行）

### Service Locator
- ✅ 已註冊到 `service_registry.dart`
- ✅ 已註冊到 `controller_registry.dart`

---

## 🎓 學習資源

### Supabase 相關
- [Supabase RLS 文檔](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL 觸發器](https://www.postgresql.org/docs/current/trigger-definition.html)

### Flutter 相關
- [Provider 狀態管理](https://pub.dev/packages/provider)
- [GetIt 依賴注入](https://pub.dev/packages/get_it)

---

## ❓ 常見問題

### Q1：執行 Migration 後可以回滾嗎？

**A**：可以，但需要手動撰寫 DROP 語句：

```sql
-- 回滾腳本（謹慎使用！）
DROP TABLE IF EXISTS public.coaching_relationships CASCADE;
DROP FUNCTION IF EXISTS public.is_active_coaching_relationship CASCADE;
DROP FUNCTION IF EXISTS public.get_coach_client_count CASCADE;
```

### Q2：如何測試 RLS 策略是否生效？

**A**：使用 Supabase Dashboard 的 RLS Debugger：

1. `Table Editor` → `coaching_relationships`
2. 點擊右上角 `RLS` 按鈕
3. 測試不同角色的查詢權限

### Q3：如何在 Flutter 中快速測試？

**A**：在個人資料頁面添加測試按鈕：

```dart
ElevatedButton(
  onPressed: () async {
    final controller = serviceLocator<CoachingRelationshipController>();
    await controller.loadCoachClients(currentUser.uid);
    print('學員數量：${controller.clients.length}');
  },
  child: Text('測試載入學員'),
)
```

---

**下一步**：執行 Migration 到 Supabase！ 🚀

**完成後回報**：Migration 執行結果（成功或錯誤訊息）

