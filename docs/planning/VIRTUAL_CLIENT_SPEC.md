# 虛擬學員功能規格書

> 版本：v1.0  
> 建立日期：2026-01-14  
> 狀態：📋 規劃中

---

## 📋 目錄

- [背景與目標](#背景與目標)
- [功能概述](#功能概述)
- [資料庫設計](#資料庫設計)
- [RLS 策略](#rls-策略)
- [服務層設計](#服務層設計)
- [UI 設計](#ui-設計)
- [權限邏輯](#權限邏輯)
- [開發任務清單](#開發任務清單)

---

## 背景與目標

### 痛點

| 問題 | 說明 |
|------|------|
| 教練無法體驗完整流程 | 沒有真實學員時，無法測試安排課表、上課模式、統計等功能 |
| Onboarding 困難 | 新教練註冊後無法馬上了解系統功能 |
| Demo 展示不便 | 需要兩個真實帳號才能展示教練學員互動 |

### 目標

- 讓教練可以創建「虛擬學員」體驗完整功能
- 每位教練最多 2 位虛擬學員
- 虛擬學員資料永久保存，統計數據真實呈現
- 無視「可訓練時間」限制，任意安排課表

---

## 功能概述

### 虛擬學員特性

| 項目 | 說明 |
|------|------|
| 數量限制 | 每位教練最多 2 位 |
| 身份 | 無法登入（沒有 auth 帳號） |
| 操作者 | 教練「代為執行」所有操作 |
| 時間限制 | 無視「可訓練時間」，任意安排 |
| 資料 | 永久保存，支援完整統計 |

### 支援功能

| 功能 | 支援 | 說明 |
|------|:----:|------|
| 安排訓練計畫 | ✅ | 無時間限制 |
| Session Mode 上課 | ✅ | 教練可完全操作（打勾、計時） |
| 課程筆記 | ✅ | SOAP 筆記、照片、手繪 |
| 統計分析 | ✅ | 訓練量、個人記錄等 |
| 健康評估 | ✅ | 教練可代為填寫 |
| 身體數據 | ✅ | 教練可代為記錄 |
| 預約系統 | ⚠️ | 簡化流程（無需確認） |

---

## 資料庫設計

### users 表新增欄位

```sql
-- Migration: 023_virtual_clients.sql

-- 1. 新增虛擬用戶欄位
ALTER TABLE public.users 
ADD COLUMN is_virtual BOOLEAN DEFAULT FALSE,
ADD COLUMN owner_id UUID REFERENCES users(id) ON DELETE CASCADE;

-- 2. 約束：虛擬用戶必須有 owner_id
ALTER TABLE public.users ADD CONSTRAINT chk_virtual_owner
  CHECK (is_virtual = FALSE OR owner_id IS NOT NULL);

-- 3. 索引
CREATE INDEX idx_users_owner ON users(owner_id) WHERE is_virtual = TRUE;

-- 4. 註解
COMMENT ON COLUMN users.is_virtual IS '是否為虛擬學員（教練創建的測試用戶）';
COMMENT ON COLUMN users.owner_id IS '虛擬學員的擁有者（教練 ID）';
```

### coaching_relationships 表新增欄位

```sql
-- 新增虛擬關係標記
ALTER TABLE public.coaching_relationships 
ADD COLUMN is_virtual_client BOOLEAN DEFAULT FALSE;

-- 註解
COMMENT ON COLUMN coaching_relationships.is_virtual_client IS '是否為虛擬學員關係';
```

### 資料模型

```
┌─────────────────────────────────────────────────┐
│                    users                         │
├─────────────────────────────────────────────────┤
│ id (PK)                                          │
│ email                                            │
│ display_name                                     │
│ is_virtual      ← 新增：是否虛擬學員              │
│ owner_id        ← 新增：擁有者（教練 ID）         │
│ ...                                              │
└─────────────────────────────────────────────────┘
           │
           │ owner_id → id (教練)
           ▼
┌─────────────────────────────────────────────────┐
│            coaching_relationships                │
├─────────────────────────────────────────────────┤
│ coach_id        → 教練 ID                        │
│ client_id       → 虛擬學員 ID                    │
│ status          = 'active' (自動)                │
│ is_virtual_client ← 新增：虛擬關係標記           │
└─────────────────────────────────────────────────┘
```

---

## RLS 策略

### 核心原則

教練對虛擬學員的操作需要「代為執行」權限，透過 `owner_id` 判斷：

```sql
-- 輔助函數：檢查是否為虛擬學員的擁有者
CREATE OR REPLACE FUNCTION is_virtual_client_owner(client_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users 
    WHERE id = client_id 
      AND is_virtual = TRUE 
      AND owner_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 需要新增 RLS 的表格

| 表格 | 策略名稱 | 條件 |
|------|----------|------|
| `workout_plans` | `virtual_client_workout_access` | `trainee_id` 是自己的虛擬學員 |
| `body_data` | `virtual_client_body_data` | `user_id` 是自己的虛擬學員 |
| `health_assessments` | `virtual_client_health` | `user_id` 是自己的虛擬學員 |
| `daily_workout_summary` | `virtual_client_summary` | `user_id` 是自己的虛擬學員 |
| `personal_records` | `virtual_client_records` | `user_id` 是自己的虛擬學員 |

### workout_plans RLS 範例

```sql
-- 教練可完全操作虛擬學員的訓練
CREATE POLICY virtual_client_workout_access ON workout_plans
  FOR ALL
  USING (is_virtual_client_owner(trainee_id))
  WITH CHECK (is_virtual_client_owner(trainee_id));
```

---

## 服務層設計

### IVirtualClientService 介面

```dart
// lib/services/interfaces/i_virtual_client_service.dart

abstract class IVirtualClientService {
  /// 創建虛擬學員
  /// 
  /// 自動創建：
  /// 1. users 記錄（is_virtual=true, owner_id=currentUserId）
  /// 2. coaching_relationships 記錄（status='active', is_virtual_client=true）
  Future<UserModel> createVirtualClient({
    required String displayName,
    String? gender,
    double? height,
    double? weight,
    DateTime? birthday,
  });
  
  /// 獲取教練的虛擬學員列表
  Future<List<UserModel>> getVirtualClients();
  
  /// 刪除虛擬學員（級聯刪除所有相關資料）
  Future<void> deleteVirtualClient(String clientId);
  
  /// 更新虛擬學員資料
  Future<void> updateVirtualClient({
    required String clientId,
    String? displayName,
    String? gender,
    double? height,
    double? weight,
  });
  
  /// 檢查是否可以創建更多虛擬學員
  Future<bool> canCreateMore();
  
  /// 獲取虛擬學員數量
  Future<int> getVirtualClientCount();
  
  /// 檢查是否為虛擬學員
  Future<bool> isVirtualClient(String userId);
}
```

### 服務註冊

```dart
// lib/services/locator/service_registry.dart

serviceLocator.registerLazySingleton<IVirtualClientService>(
  () => VirtualClientServiceSupabase(
    supabase: serviceLocator<SupabaseClient>(),
    errorService: serviceLocator<ErrorHandlingService>(),
  ),
);
```

---

## UI 設計

### 入口位置

在「學員管理」頁面新增入口：

```
ClientManagementPage
├── AppBar: 學員管理
├── [學員列表]
│   ├── 真實學員 A
│   ├── 真實學員 B
│   ├── 虛擬學員 1 [虛擬] ← 標籤
│   └── 虛擬學員 2 [虛擬]
└── FloatingActionButton
    ├── 邀請學員（現有）
    └── 新增虛擬學員 ← 新增
```

### 創建虛擬學員 Dialog

```
┌─────────────────────────────────────┐
│      新增虛擬學員 (1/2)              │
├─────────────────────────────────────┤
│                                      │
│  名稱 *                              │
│  ┌─────────────────────────────────┐ │
│  │ 測試學員                         │ │
│  └─────────────────────────────────┘ │
│                                      │
│  性別                                │
│  ○ 男  ○ 女  ○ 其他                 │
│                                      │
│  身高 (cm)         體重 (kg)         │
│  ┌──────────┐     ┌──────────┐      │
│  │ 170      │     │ 65       │      │
│  └──────────┘     └──────────┘      │
│                                      │
│          [取消]    [創建]            │
└─────────────────────────────────────┘
```

### 虛擬學員標籤

```dart
// VirtualClientBadge
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  decoration: BoxDecoration(
    color: Colors.purple.withOpacity(0.1),
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: Colors.purple.withOpacity(0.3)),
  ),
  child: Text(
    '虛擬',
    style: TextStyle(
      color: Colors.purple,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  ),
)
```

### 學員列表整合

修改 `ClientListCard` / `ClientListItem`：

```dart
Row(
  children: [
    Text(client.displayName),
    if (isVirtual) ...[
      SizedBox(width: 8),
      VirtualClientBadge(),
    ],
  ],
)
```

---

## 權限邏輯

### 訓練執行權限

修改 `WorkoutExecutionController.canModify()`：

```dart
bool canModify() {
  // 現有邏輯...
  
  // ⭐ 虛擬學員特殊處理：教練可以直接打勾
  if (_isVirtualClient && isCoachViewingTrainee()) {
    return true;
  }
  
  return _baseCheck();
}
```

### 安排課表

修改 `ClientWorkoutCalendarTab`：

```dart
// 虛擬學員不顯示「可訓練時間」背景
if (!isVirtualClient) {
  _loadClientAvailability();
}

// 虛擬學員跳過時間衝突檢查
if (isVirtualClient) {
  // 直接允許安排
} else {
  // 檢查可訓練時間
}
```

### Session Mode

修改 `SessionModeController`：

```dart
// 虛擬學員：教練可完全操作
bool get canCoachOperate {
  if (isVirtualClient) return true;
  return isCoachMode;
}
```

---

## 開發任務清單

### Phase 1: 資料庫

| 編號 | 任務 | 檔案 |
|------|------|------|
| DB-1 | 創建 Migration | `migrations/023_virtual_clients.sql` |
| DB-2 | 新增 RLS 策略 | 同上 |
| DB-3 | 創建輔助函數 | 同上 |

### Phase 2: 服務層

| 編號 | 任務 | 檔案 |
|------|------|------|
| SVC-1 | 創建服務介面 | `lib/services/interfaces/i_virtual_client_service.dart` |
| SVC-2 | 實作服務 | `lib/services/supabase/virtual_client_service.dart` |
| SVC-3 | 註冊服務 | `lib/services/locator/service_registry.dart` |

### Phase 3: Controller

| 編號 | 任務 | 檔案 |
|------|------|------|
| CTRL-1 | 創建 Controller | `lib/controllers/virtual_client_controller.dart` |
| CTRL-2 | 註冊 Controller | `lib/services/locator/controller_registry.dart` |
| CTRL-3 | 修改權限邏輯 | `lib/controllers/workout_execution_controller.dart` |

### Phase 4: UI

| 編號 | 任務 | 檔案 |
|------|------|------|
| UI-1 | 創建 Dialog | `lib/views/.../create_virtual_client_dialog.dart` |
| UI-2 | 創建 Badge | `lib/views/.../virtual_client_badge.dart` |
| UI-3 | 整合學員列表 | `lib/views/.../client_list_card.dart` |
| UI-4 | 整合 FAB | `lib/views/.../client_management_page.dart` |

### Phase 5: 文檔

| 編號 | 任務 | 檔案 |
|------|------|------|
| DOC-1 | 更新資料庫文檔 | `docs/DATABASE_SUPABASE.md` |
| DOC-2 | 更新開發狀態 | `docs/DEVELOPMENT_STATUS.md` |
| DOC-3 | 更新 Migration README | `migrations/README.md` |

---

## 測試要點

| 測試項目 | 預期結果 |
|----------|----------|
| 創建虛擬學員 | 成功創建，自動建立 active 關係 |
| 達到上限後創建 | 顯示錯誤訊息「已達上限」 |
| 為虛擬學員安排訓練 | 無時間限制，可任意安排 |
| Session Mode 打勾 | 教練可直接操作（無需學員端） |
| 統計資料 | 正確顯示訓練量、個人記錄 |
| 刪除虛擬學員 | 級聯刪除所有相關資料 |

---

## 相關文檔

- [DATABASE_SUPABASE.md](../DATABASE_SUPABASE.md) - 資料庫設計
- [SESSION_MODE_SPEC.md](archived/SESSION_MODE_SPEC.md) - Session Mode 規格
- [TRAINING_PERMISSION_MATRIX.md](archived/TRAINING_PERMISSION_MATRIX.md) - 訓練權限矩陣
