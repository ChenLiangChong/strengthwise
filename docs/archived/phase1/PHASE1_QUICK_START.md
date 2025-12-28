# Phase 1 快速開始指南

> 5 分鐘完成 Migration 並測試教練-學員綁定功能

---

## 🚀 立即執行（3 步驟）

### 步驟 1：執行 Migration（2 分鐘）

1. **開啟 Supabase Dashboard**
   - 前往：https://supabase.com/dashboard
   - 選擇你的專案

2. **執行 SQL**
   - 左側選單：`SQL Editor`
   - 點擊 `+ New query`
   - 複製 `migrations/021_phase1_coaching_relationships.sql` 的全部內容
   - 貼到編輯器，點擊 `Run` ▶️

3. **驗證結果**
   - 應該看到：`Success. No rows returned`
   - 左側選單 `Table Editor` 可看到新表格 `coaching_relationships`

---

### 步驟 2：創建測試數據（1 分鐘）

**在 Supabase SQL Editor 執行**：

```sql
-- 1. 將當前用戶設為教練
UPDATE public.users 
SET is_coach = true 
WHERE id = auth.uid();

-- 2. 創建測試學員（如果還沒有第二個帳號）
-- 先用另一個 Email 在 App 中註冊一個新帳號
-- 然後回來這裡，執行步驟 3

-- 3. 創建綁定關係（替換 UUID）
INSERT INTO public.coaching_relationships (
  coach_id,
  client_id,
  status,
  notes
) VALUES (
  'YOUR_COACH_UUID',    -- 替換為你的教練 UUID
  'YOUR_CLIENT_UUID',   -- 替換為測試學員的 UUID
  'active',
  '測試學員'
);
```

**如何獲取 UUID**：
- `Table Editor` → `users` 表格
- 複製 `id` 欄位的值

---

### 步驟 3：在 App 中測試（2 分鐘）

**方式 1：快速測試（在個人資料頁面添加測試按鈕）**

1. 開啟 `lib/views/pages/profile/profile_page.dart`

2. 在頁面某處添加測試按鈕：

```dart
import '../../services/service_locator.dart';
import '../../controllers/coaching_relationship_controller.dart';

// ... 在 build() 方法中添加：

ElevatedButton(
  onPressed: () async {
    final controller = serviceLocator<CoachingRelationshipController>();
    final currentUser = // 獲取當前用戶
    
    // 載入學員列表
    await controller.loadCoachClients(currentUser.uid);
    
    // 顯示結果
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('學員列表'),
        content: Text('學員數量：${controller.clients.length}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('關閉'),
          ),
        ],
      ),
    );
  },
  child: Text('測試載入學員'),
)
```

3. Hot Reload，點擊按鈕測試

---

## ✅ 驗證成功

如果看到以下結果，表示 Phase 1 基礎架構已完成：

- [ ] Migration 執行成功
- [ ] `coaching_relationships` 表格已建立
- [ ] 測試數據插入成功
- [ ] App 可以載入學員列表（數量 > 0）
- [ ] 沒有 RLS 權限錯誤

---

## 🐛 常見錯誤排查

### 錯誤 1：`relation "coaching_relationships" does not exist`

**原因**：Migration 未執行或執行失敗

**解決**：
1. 檢查 SQL Editor 的執行結果
2. 確認表格已在 `Table Editor` 中顯示

---

### 錯誤 2：`new row violates row-level security policy`

**原因**：RLS 策略阻擋了操作

**解決**：
1. 確認當前用戶的 `is_coach` 為 `true`
2. 使用正確的 `coach_id` 和 `client_id`

---

### 錯誤 3：`serviceLocator is not registered`

**原因**：服務尚未註冊

**解決**：
1. 重啟 App（確保 `setupServiceLocator()` 執行）
2. 檢查 `service_registry.dart` 是否包含註冊代碼

---

## 📋 下一步工作

完成基礎測試後，可以開始：

1. **創建學員管理 UI**
   - 教練端：學員列表頁面
   - 學員端：教練列表頁面

2. **實作邀請流程**
   - 邀請對話框（輸入 Email）
   - 待處理邀請列表
   - 接受/拒絕按鈕

3. **完整測試流程**
   - 教練邀請學員
   - 學員接受邀請
   - 狀態從 pending → active

---

## 🎯 關鍵提醒

**❌ 不需要**：
- ❌ 建立生產環境（Phase 5 才需要）
- ❌ 配置郵件服務（Phase 1 結束後）
- ❌ Edge Function 開發（Phase 1 結束後）

**✅ 現在要做**：
- ✅ 執行 Migration（在當前 Supabase 專案）
- ✅ 創建測試數據
- ✅ 測試基礎功能
- ✅ 開始開發 UI

---

**有問題？** 查看完整文檔：`docs/PHASE1_IMPLEMENTATION_GUIDE.md`

