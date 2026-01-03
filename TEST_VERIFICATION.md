# 教練學員綁定系統測試驗證清單

> 臨時測試文件 - 驗證解除綁定、重新綁定、筆記刪除/隱藏功能
> 
> 創建時間：2026-01-03
> 更新時間：2026-01-03（新增隱藏筆記功能）

---

## ✅ 測試前準備

### 測試帳號
- **教練帳號**：（你的教練帳號）
- **學員帳號**：（你的學員帳號）

### 預期數據庫狀態
- ✅ Migration 017 已執行（重新激活 RLS 政策）
- ✅ Migration 018 已執行（隱藏筆記功能）⭐ 新增
- ✅ `coaching_relationships` 表中有至少一筆 `status = 'active'` 的關係
- ✅ `session_notes` 表中有至少一筆 `visibility = 'shared'` 的共享筆記

---

## 📋 測試流程

### **Phase 1：解除綁定測試**

#### **測試 1-1：教練解除學員綁定**
1. **操作**：
   - 登入教練帳號
   - 進入「教練中心」→「學員管理」
   - 點擊學員卡片進入「學員詳情頁」
   - 滾動到底部「危險區域」
   - 點擊「解除綁定」
   
2. **預期結果**：
   - ✅ 彈出確認 Dialog（Material 3 風格，紅色框，警告圖示）
   - ✅ 顯示解除後果說明（3 項）
   - ✅ 點擊「解除綁定」後顯示成功提示
   - ✅ 返回「學員管理」頁面，該學員**消失**
   
3. **資料庫驗證**：
   ```sql
   SELECT id, coach_id, client_id, status 
   FROM coaching_relationships 
   WHERE status = 'archived'
   ORDER BY updated_at DESC 
   LIMIT 1;
   ```
   - ✅ 應該有一筆 `status = 'archived'` 的記錄
   - ✅ `coach_name` 和 `client_name` 欄位應該有值

---

#### **測試 1-2：學員解除教練綁定**
1. **操作**：
   - 登入學員帳號
   - 進入「學員中心」→「我的教練」
   - 點擊教練卡片進入「教練詳情頁」
   - 滾動到底部「危險區域」
   - 點擊「解除綁定」
   
2. **預期結果**：
   - ✅ 彈出確認 Dialog（與教練端相同風格）
   - ✅ 點擊「解除綁定」後返回到「學員中心」首頁
   - ✅ 「我的教練」列表該教練**消失**
   
3. **資料庫驗證**：
   - ✅ 同測試 1-1，檢查 `status = 'archived'`

---

### **Phase 2：重新綁定測試（QR Code）**

#### **測試 2-1：教練掃描學員 QR Code 重新綁定**
1. **操作前檢查**：
   - 確認 DB 中有一筆 `status = 'archived'` 的關係
   - 記錄該關係的 `id`
   
2. **操作**：
   - 教練端：點擊「綁定」按鈕 → 選擇「QR Code 綁定」
   - 學員端：點擊「綁定」按鈕 → 選擇「QR Code 綁定」→ 切換到「我的 QR Code」Tab
   - 教練端：掃描學員的 QR Code
   
3. **預期結果**：
   - ✅ 顯示「綁定成功」
   - ✅ 教練端：「學員管理」列表**重新顯示**該學員
   - ✅ 學員端：「我的教練」列表**重新顯示**該教練
   
4. **資料庫驗證**：
   ```sql
   SELECT id, coach_id, client_id, status, invited_at, accepted_at
   FROM coaching_relationships 
   WHERE id = '<剛才記錄的 id>'
   ORDER BY updated_at DESC;
   ```
   - ✅ **同一筆關係**（`id` 相同）
   - ✅ `status = 'active'`（已重新激活）
   - ✅ `invited_at` 和 `accepted_at` 已更新為新時間
   - ✅ **沒有創建新記錄**

---

#### **測試 2-2：學員使用邀請碼重新綁定**
1. **操作前準備**：
   - 先執行測試 1-1 或 1-2（確保關係為 archived）
   
2. **操作**：
   - 教練端：點擊「綁定」→「生成邀請碼」
   - 複製顯示的 6 位邀請碼（如：A1B2C3）
   - 學員端：點擊「綁定」→「輸入邀請碼」
   - 輸入邀請碼並確認
   
3. **預期結果**：
   - ✅ 顯示「綁定成功」
   - ✅ 雙方列表重新顯示對方
   
4. **資料庫驗證**：
   - ✅ 同測試 2-1（檢查是更新而非新增）

---

### **Phase 3：筆記刪除測試（學員端）**

#### **測試 3-1：學員無法刪除 active 關係的共享筆記**
1. **操作前準備**：
   - 確保有一筆 `status = 'active'` 的綁定關係
   - 教練創建一筆共享筆記給學員
   
2. **操作**：
   - 學員端：進入「學員中心」→「課程筆記」
   - 找到共享筆記，點擊刪除按鈕
   
3. **預期結果**：
   - ✅ 彈出 Dialog：「無法移除筆記」
   - ✅ 內容：「此筆記由教練分享給您，在教練關係有效期間無法移除。」
   - ✅ 點擊「知道了」後關閉 Dialog
   - ✅ 筆記**仍然存在**

---

#### **測試 3-2：學員可以刪除 archived 關係的共享筆記**
1. **操作前準備**：
   - 先執行測試 1-2（學員解除教練綁定）
   - 確認 `status = 'archived'`
   
2. **操作**：
   - 學員端：進入「學員中心」→「課程筆記」
   - 使用教練篩選器，選擇該教練
   - 找到共享筆記，點擊刪除按鈕
   
3. **預期結果**：
   - ✅ 彈出確認 Dialog：「移除筆記」
   - ✅ 內容：「此筆記將從您的檢視中移除，但教練仍可查看。」
   - ✅ 點擊「移除」後顯示「筆記已從您的檢視中移除」
   - ✅ 筆記從學員端**消失**
   
4. **資料庫驗證**：
   ```sql
   -- 學員端查詢（應該查不到）
   SELECT id, title, visibility, coach_id, client_id
   FROM session_notes
   WHERE client_id = '<學員 id>'
     AND visibility = 'shared';
   
   -- 教練端查詢（應該仍然存在）
   SELECT id, title, visibility, coach_id, client_id
   FROM session_notes
   WHERE coach_id = '<教練 id>';
   ```
   - ✅ 學員端：該筆記已被刪除（查詢結果為空）
   - ✅ 教練端：該筆記仍然存在

---

### **Phase 4：歷史數據查看測試**

#### **測試 4-1：筆記列表顯示已解除關係的教練**
1. **操作前準備**：
   - 確保有一筆 `status = 'archived'` 的關係
   - 該關係有歷史共享筆記
   
2. **操作**：
   - 學員端：進入「學員中心」→「課程筆記」
   - 查看教練篩選下拉選單
   
3. **預期結果**：
   - ✅ 下拉選單包含**所有教練**（active + archived）
   - ✅ 選擇已解除的教練後，可以看到歷史共享筆記
   - ✅ 教練名稱正確顯示（使用 `coach_name` 快照）

---

#### **測試 4-2：名稱快照正確保存**
1. **資料庫驗證**：
   ```sql
   SELECT 
     cr.id,
     cr.coach_id,
     cr.client_id,
     cr.coach_name,
     cr.client_name,
     u1.display_name AS current_coach_name,
     u2.display_name AS current_client_name
   FROM coaching_relationships cr
   LEFT JOIN users u1 ON cr.coach_id = u1.id
   LEFT JOIN users u2 ON cr.client_id = u2.id
   WHERE cr.status = 'archived'
   ORDER BY cr.updated_at DESC
   LIMIT 5;
   ```
   
2. **預期結果**：
   - ✅ `coach_name` 和 `client_name` 欄位有值
   - ✅ 如果用戶還未刪除，快照應該與當前 `display_name` 相同
   - ✅ 如果用戶已刪除，`current_coach_name` 為 NULL，但快照仍有值

---

## 🐛 已知問題排查

### 如果綁定失敗
1. 檢查 Migration 017 是否成功執行：
   ```sql
   SELECT policyname, cmd 
   FROM pg_policies
   WHERE tablename = 'coaching_relationships'
     AND policyname = 'Both parties can reactivate archived relationships';
   ```
   - 應該返回 1 筆記錄

2. 檢查終端錯誤訊息：
   - 如果顯示 `PGRST116`：RLS 政策問題
   - 如果顯示 `該學員已存在有效的綁定關係`：檢查 DB 中是否有 `status = 'active'` 的重複記錄

### 如果學員無法刪除 archived 筆記
1. 檢查關係狀態：
   ```sql
   SELECT status FROM coaching_relationships
   WHERE coach_id = '<教練 id>' AND client_id = '<學員 id>';
   ```
   - 應該是 `'archived'`，不是 `'active'`

2. 檢查 RLS 政策：
   ```sql
   SELECT policyname 
   FROM pg_policies
   WHERE tablename = 'session_notes'
     AND policyname IN (
       'Clients delete shared notes after relationship ends',  -- 舊政策
       'Clients can hide shared notes after relationship ends'  -- 新政策（Migration 018）
     );
   ```
   - 應該存在 `Clients can hide shared notes after relationship ends` 政策
   - 舊的 DELETE 政策應該已被移除

---

## 📝 Phase 5：隱藏筆記功能測試（⭐ 新增）

### **測試 5-1：學員隱藏 archived 關係的共享筆記**

1. **前置條件**：
   - 關係已 archived（執行 Phase 1 測試）
   - 有至少一筆共享筆記（`visibility = 'shared'`）

2. **操作**：
   - 登入學員帳號
   - 進入「個人中心」→「我的筆記」
   - 找到共享筆記，點擊「刪除」按鈕

3. **預期結果**：
   - ✅ 彈出「移除筆記」Dialog（不是「刪除筆記」）
   - ✅ 提示：「此筆記將從您的檢視中移除，但教練仍可查看」
   - ✅ 確認後，筆記從學員視圖消失
   - ✅ 顯示成功提示：「筆記已從您的檢視中移除」

4. **資料庫驗證**：
   ```sql
   SELECT id, title, visibility, hidden_by_client, hidden_by_coach
   FROM session_notes
   WHERE client_id = '<學員 id>'
   ORDER BY updated_at DESC
   LIMIT 5;
   ```
   - ✅ `hidden_by_client = true`
   - ✅ `hidden_by_coach = false`
   - ✅ 記錄仍存在（沒有被真正刪除）

---

### **測試 5-2：教練隱藏共享筆記**

1. **前置條件**：
   - 有至少一筆共享筆記（可以是 active 或 archived 關係）

2. **操作**：
   - 登入教練帳號
   - 進入「教練中心」→「課程筆記」
   - 找到共享筆記，點擊「刪除」按鈕

3. **預期結果**：
   - ✅ 彈出「移除筆記」Dialog
   - ✅ 提示：「此筆記將從您的檢視中移除，但學員仍可查看」
   - ✅ 確認後，筆記從教練視圖消失
   - ✅ 顯示成功提示：「筆記已從您的檢視中移除」

4. **資料庫驗證**：
   ```sql
   SELECT id, title, visibility, hidden_by_client, hidden_by_coach
   FROM session_notes
   WHERE coach_id = '<教練 id>'
   ORDER BY updated_at DESC
   LIMIT 5;
   ```
   - ✅ `hidden_by_coach = true`
   - ✅ `hidden_by_client = false`（學員尚未隱藏）
   - ✅ 記錄仍存在

---

### **測試 5-3：驗證對方仍可查看已隱藏的筆記**

1. **操作**：
   - 學員隱藏筆記後，登入教練帳號查看
   - 教練隱藏筆記後，登入學員帳號查看

2. **預期結果**：
   - ✅ 教練仍可查看學員已隱藏的筆記（`hidden_by_client = true`）
   - ✅ 學員仍可查看教練已隱藏的筆記（`hidden_by_coach = true`）
   - ✅ 雙方各自隱藏的筆記互不影響

---

### **測試 5-4：重新綁定後，隱藏狀態保持不變（選項 A）**

1. **操作**：
   - 執行測試 5-1（學員隱藏筆記）
   - 重新綁定（QR Code 或邀請碼）
   - 再次解除綁定

2. **預期結果**：
   - ✅ 重新綁定後，筆記**仍然保持隱藏狀態**
   - ✅ 學員端看不到之前隱藏的筆記
   - ✅ 教練端仍可查看

3. **資料庫驗證**：
   ```sql
   SELECT id, title, hidden_by_client, hidden_by_coach
   FROM session_notes
   WHERE client_id = '<學員 id>'
   AND hidden_by_client = true;
   ```
   - ✅ `hidden_by_client` 欄位保持 `true`

---

### **測試 5-5：私人筆記刪除行為驗證**

1. **操作**：
   - 登入教練帳號
   - 進入「課程筆記」→ 找到 `visibility = 'private'` 的筆記
   - 點擊「刪除」

2. **預期結果**：
   - ✅ 彈出「刪除筆記」Dialog（不是「移除」）
   - ✅ 提示：「確定要刪除此筆記嗎？此操作無法復原」
   - ✅ 確認後，筆記**真正被刪除**（不只是隱藏）

3. **資料庫驗證**：
   ```sql
   SELECT COUNT(*) FROM session_notes WHERE id = '<筆記 id>';
   ```
   - ✅ 應該返回 0（記錄已被刪除）

---

### **測試 5-6：雙方都隱藏後自動刪除 ⭐ 新增**

1. **前置條件**：
   - 有一筆共享筆記
   - 關係已 archived

2. **操作**：
   - **步驟 1**：學員先隱藏筆記（執行測試 5-1）
   - **步驟 2**：教練再隱藏同一筆筆記

3. **預期結果**：
   - ✅ 學員隱藏後，筆記仍存在（`hidden_by_client = true`）
   - ✅ 教練隱藏後，筆記**自動被刪除**（雙方都不需要了）
   - ✅ 相關的 Storage 檔案（照片、手繪、語音）也被刪除

4. **資料庫驗證**：
   ```sql
   -- 檢查記錄是否真正刪除
   SELECT COUNT(*) FROM session_notes WHERE id = '<筆記 id>';
   ```
   - ✅ 應該返回 0（記錄已被完全刪除）

5. **Storage 驗證**（如果筆記有照片）：
   - ✅ 到 Supabase Dashboard → Storage → `session_photos`
   - ✅ 確認相關照片已被刪除（沒有孤兒檔案）

---

## ✅ 測試完成檢查清單

- [x] 測試 1-1：教練解除學員綁定 ✅
- [x] 測試 1-2：學員解除教練綁定 ✅
- [x] 測試 2-1：QR Code 重新綁定 ✅
- [x] 測試 2-2：邀請碼重新綁定 ✅
- [x] 測試 3-1：學員無法刪除 active 筆記 ✅
- [x] 測試 3-2：學員可以刪除 archived 筆記 ✅
- [x] 測試 4-1：歷史數據查看 ✅
- [x] 測試 4-2：名稱快照驗證 ✅
- [x] 測試 5-1：學員隱藏 archived 筆記 ✅ ⭐ 新增
- [x] 測試 5-2：教練隱藏共享筆記 ✅ ⭐ 新增
- [x] 測試 5-3：對方仍可查看已隱藏筆記 ✅ ⭐ 新增
- [x] 測試 5-4：重新綁定後隱藏狀態保持 ✅ ⭐ 新增
- [x] 測試 5-5：私人筆記真正刪除 ✅ ⭐ 新增
- [x] 測試 5-6：雙方都隱藏後自動刪除 ✅ ⭐⭐ 重點測試

---

## 📊 測試結果記錄

| 測試項目 | 狀態 | 備註 |
|---------|------|------|
| 1-1 教練解除綁定 | ✅ 通過 | |
| 1-2 學員解除綁定 | ✅ 通過 | |
| 2-1 QR 重新綁定 | ✅ 通過 | |
| 2-2 邀請碼綁定 | ✅ 通過 | |
| 3-1 無法刪除 active | ✅ 通過 | |
| 3-2 可刪除 archived | ✅ 通過 | |
| 4-1 歷史數據查看 | ✅ 通過 | |
| 4-2 名稱快照 | ✅ 通過 | |
| 5-1 學員隱藏筆記 | ✅ 通過 | ⭐ 新增 |
| 5-2 教練隱藏筆記 | ✅ 通過 | ⭐ 新增 |
| 5-3 對方仍可查看 | ✅ 通過 | ⭐ 新增 |
| 5-4 重新綁定保持隱藏 | ✅ 通過 | ⭐ 新增 |
| 5-5 私人筆記刪除 | ✅ 通過 | ⭐ 新增 |
| 5-6 雙方隱藏自動刪除 | ✅ 通過 | ⭐⭐ 重點 |

---

## 📝 Phase 6：已刪除帳號筆記查詢功能測試（2026-01-03 完成）

### **功能概述**
當教練或學員刪除帳號後，系統保留歷史筆記並支援查詢：
- ✅ 教練端：可查看已刪除學員的筆記（共享 + 私有）
- ✅ 學員端：可查看已刪除教練的筆記（共享）
- ✅ 篩選器顯示已刪除用戶（含圖標和狀態提示）

### **測試 6-1：教練查看已刪除學員的筆記**

1. **前置條件**：
   - 有一筆學員的共享筆記
   - 學員刪除帳號（`client_id` → NULL，`client_name` 保留）

2. **操作**：
   - 登入教練帳號
   - 進入「教練中心」→「課程筆記」
   - 打開學員篩選器

3. **預期結果**：
   - ✅ 下拉選單顯示「👻 [學員名稱] (已刪除)」（灰色文字）
   - ✅ 選擇該學員，可看到歷史筆記
   - ✅ 筆記卡片顯示學員名稱（使用 `client_name` 快照）

4. **資料庫查詢邏輯**：
   ```sql
   SELECT * FROM session_notes
   WHERE coach_id = '<教練 id>'
     AND client_name = '<學員名稱>'
     AND client_id IS NULL;
   ```

---

### **測試 6-2：學員查看已刪除教練的筆記**

1. **前置條件**：
   - 有一筆教練的共享筆記
   - 教練刪除帳號（`coach_id` → NULL，`coach_name` 保留）

2. **操作**：
   - 登入學員帳號
   - 進入「學員中心」→「課程筆記」
   - 打開教練篩選器

3. **預期結果**：
   - ✅ 下拉選單顯示「👻 [教練名稱] (已刪除)」（灰色文字）
   - ✅ 選擇該教練，可看到歷史共享筆記
   - ✅ 筆記卡片顯示教練名稱（使用 `coach_name` 快照）

4. **資料庫查詢邏輯**：
   ```sql
   SELECT * FROM session_notes
   WHERE client_id = '<學員 id>'
     AND coach_name = '<教練名稱>'
     AND coach_id IS NULL
     AND visibility = 'shared';
   ```

---

### **測試 6-3：已刪除用戶的篩選器 UI**

1. **預期 UI 效果**：
   ```
   【學員：全部學員 ▼】
   ├─ 李學員
   ├─ 王學員  
   ├─ 🔗 張學員 (已解除)  ← 灰色 (Colors.grey.shade600)
   └─ 👻 陳學員 (已刪除)  ← 更灰 (Colors.grey.shade400)
   ```

2. **驗證項目**：
   - ✅ 圖標正確顯示（🔗 已解除 / 👻 已刪除）
   - ✅ 文字顏色漸層（active > archived > deleted）
   - ✅ 狀態文字正確（已解除 / 已刪除）

---

### **測試 6-4：預約系統不顯示已刪除教練**

1. **操作**：
   - 登入學員帳號
   - 進入「學員中心」→「時間偏好」（預約系統）
   - 查看教練選擇器

2. **預期結果**：
   - ✅ 只顯示 `status = 'active'` 且 `coach_id != NULL` 的教練
   - ✅ 已刪除的教練**不顯示**（無法預約）

---

### **技術實作細節**

#### 1. **Model 層變更**
- ✅ `CoachingRelationshipModel`: `coachId` 和 `clientId` 改為 `String?`
- ✅ `ClientWithRelationship`: 組合用戶資料 + 關係狀態
- ✅ `CoachWithRelationship`: 學員端對應模型

#### 2. **Service 層變更**
- ✅ `getCoachNotes(clientId, clientName)`: 支援已刪除學員查詢
- ✅ `getClientNotes(coachId, coachName)`: 支援已刪除教練查詢
- ✅ `getCoachClientsWithRelationship()`: 批量查詢學員+關係
- ✅ `getClientCoachesWithRelationship()`: 批量查詢教練+關係

#### 3. **Migration 019**
- ✅ 新增 RLS 政策：`Both parties can archive relationships`
- ✅ 允許學員和教練都可以將 `active` 改為 `archived`

#### 4. **Bug 修復**
- ✅ 修復 `substring` 對 null `clientId` 的錯誤
- ✅ 修復學員端教練篩選器邏輯（移除前端重複篩選）
- ✅ 修復預約系統的 null-safety 問題

---

## 🚧 待辦事項（Phase 7）

### **任務 7-1：實作已刪除帳號筆記的物理刪除功能** ⭐⭐⭐

**需求**：
當教練或學員刪除帳號後，應提供方式讓用戶刪除相關的歷史筆記。

**設計方案**：

#### 選項 A：在筆記列表中顯示刪除按鈕（推薦）
- 篩選器選擇已刪除用戶時，刪除按鈕變為「永久刪除」
- 判斷邏輯：
  ```dart
  // 教練端
  bool canPermanentlyDelete = note.clientId == null && note.clientName != null;
  
  // 學員端
  bool canPermanentlyDelete = note.coachId == null && note.coachName != null;
  ```

#### 選項 B：在設定頁面提供批量刪除
- 「教練中心」→「設定」→「清理已刪除用戶的筆記」
- 一次性刪除所有 `client_id = NULL` 的筆記

#### 選項 C：自動清理（定時任務）
- 當筆記超過 90 天且 `client_id = NULL` 時自動刪除
- 需要實作 Supabase Edge Function

**實作步驟**：
1. [ ] 決定刪除方案（A/B/C）
2. [ ] 實作 UI 層刪除按鈕邏輯
3. [ ] 實作 Service 層批量刪除方法
4. [ ] 添加確認 Dialog
5. [ ] 測試驗證

**資料庫查詢範例**：
```sql
-- 教練端：查詢所有已刪除學員的筆記
SELECT id, title, client_name, created_at
FROM session_notes
WHERE coach_id = '<教練 id>'
  AND client_id IS NULL
  AND client_name IS NOT NULL;

-- 學員端：查詢所有已刪除教練的筆記
SELECT id, title, coach_name, created_at
FROM session_notes
WHERE client_id = '<學員 id>'
  AND coach_id IS NULL
  AND coach_name IS NOT NULL;
```

---

**測試完成後可刪除此文件** 🗑️

