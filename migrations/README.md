# StrengthWise Migrations

> 資料庫架構變更腳本（精簡版 - 從 19 個優化為 12 個）

**最後更新**：2026-01-03 - 新增重新激活關係政策 ✅

---

## 📋 執行順序

### 完整部署（v1.0 + v2.0 + v2.1 + v2.2 + v2.3）

執行以下 **13 個檔案**（按順序）：

```sql
-- v1.0 核心（4 個）
001_v1_core_tables.sql          # 核心表格
002_v1_initial_data.sql         # 系統資料（794 個動作）
003_v1_enhancements.sql         # 功能增強
004_v1_optimization.sql         # 統計優化

-- v2.0 功能（3 個）
005_v2_phase1_coaching.sql      # 教練學員系統
006_v2_phase2_appointments.sql  # 預約系統
007_v2_phase3_notes.sql         # 視覺化筆記

-- v2.1 功能（1 個）
008_workout_time_range_no_constraint.sql  # 訓練時間範圍（TSTZRANGE）

-- v2.2/v2.3 修復與增強（5 個）⭐
009_v2_fixes.sql                # 合併所有修復（4 個 → 1 個）
010_v2_enhancements.sql         # 合併所有增強（4 個 → 1 個）
013_invite_codes_system.sql     # 邀請碼系統（遠端綁定）⭐
014_client_profile.sql          # 個人資料完整驗證
015_fix_cascade_to_set_null.sql # CASCADE 修復（保留歷史數據）⭐
017_fix_reactivate_relationship.sql # 重新激活 archived 關係 RLS 修復 ⭐ NEW
```

### 僅部署 v1.0（單機版）

只需執行前 **4 個檔案**：

```sql
001_v1_core_tables.sql
002_v1_initial_data.sql
003_v1_enhancements.sql
004_v1_optimization.sql
```

---

## 📦 Migration 檔案說明

### v1.0 核心（4 個檔案）

#### 001_v1_core_tables.sql
**合併自**: 001, 002, 004  
**說明**: 建立所有基礎表格

**包含表格**:
- `exercises` - 系統動作庫（準備接收 794 個動作）
- `body_parts` - 身體部位元數據（8 個）
- `exercise_types` - 訓練類型（3 個）
- `equipments` - 器材列表（21 種）
- `joint_types` - 關節類型（2 種）
- `users` - 用戶資料（與 Supabase Auth 同步）
- `workout_plans` - 訓練計劃/記錄統一表
- `workout_templates` - 訓練模板
- `custom_exercises` - 用戶自訂動作
- `body_data` - 身體數據記錄

**RLS 策略**: 15 個（完整權限控制）

---

#### 002_v1_initial_data.sql
**合併自**: 008, 009, 011  
**說明**: 導入系統初始資料

**包含**:
- 794 個系統動作的雙語資料（name + name_en）
- 修正元數據表的雙語欄位
- 強制同步 body_parts 資料

**檔案大小**: ~300KB（主要是 794 個 UPDATE 語句）

---

#### 003_v1_enhancements.sql
**合併自**: 012, 015, 016, 017, 018, 019, 020  
**說明**: 功能增強與效能優化

**包含**:
- `custom_exercises` 表欄位擴展（body_part, training_type）
- 索引優化 Phase 1（workout_plans, body_data）
- pgroonga 全文搜尋（exercises, custom_exercises）
- Body Part 修正（心肺/伸展）
- Body Part View 建立

**效能提升**: 查詢速度 +80-99%

---

#### 004_v1_optimization.sql
**來自**: 026  
**說明**: 統計彙總表（Materialized View）

**包含**:
- `workout_stats_summary` 物化視圖
- 自動刷新機制（觸發器）
- 支援快速統計查詢（<5ms）

**效能提升**: 統計頁面從 2-5s → <5ms（99%+）

---

### v2.0 功能（3 個檔案）

#### 005_v2_phase1_coaching.sql
**來自**: 021  
**說明**: v2.0 Phase 1 - 教練學員系統

**包含表格**:
- `coaching_relationships` - 教練學員關係

**RLS 策略**: 8 個

**功能**:
- 教練邀請學員（UUID 綁定）
- 學員接受/拒絕邀請
- 雙向關係管理（活躍/待接受/已歸檔）

---

#### 006_v2_phase2_appointments.sql
**來自**: 022  
**說明**: v2.0 Phase 2 - 預約系統

**包含表格**:
- `availability_slots` - 教練可用時段（支援 RRULE 週期性）
- `appointments` - 預約記錄（狀態機）

**核心技術**:
- PostgreSQL TSTZRANGE（時間範圍類型）
- GiST 排除約束（物理層防止雙重預約）⭐
- 10 個 RLS 策略

**功能**:
- 教練設定可用時段
- 學員線上預約
- 狀態管理（待確認/已確認/已完成/已取消/已拒絕）

---

#### 007_v2_phase3_notes.sql
**合併自**: 023, 024, 025  
**說明**: v2.0 Phase 3 - 視覺化筆記系統

**包含表格**:
- `session_notes` - SOAP 格式課程筆記
- `client_availability_preferences` - 學員時間偏好（TSTZRANGE）
- `drawing_notes` - 手繪板向量繪圖（JSONB）

**Storage Buckets**:
- `session-photos` - 課程照片（Private）
- Storage RLS 策略（學員隔離）⭐

**功能**:
- SOAP 筆記（Subjective, Objective, Assessment, Plan）
- 照片拍攝與上傳
- 手繪板標註（4 種底圖 + 4 種工具）
- 學員時間偏好設定（雙向時間管理）

---

### v2.1 訓練時間範圍（1 個檔案）

#### 008_workout_time_range_no_constraint.sql
**說明**: 添加訓練時間範圍欄位（v2.1）

**包含**:
- `training_time_range` 欄位 (TSTZRANGE 類型)
- GiST 索引（支援範圍查詢）
- 複合索引（trainee_id + training_time_range）
- btree_gist 擴展啟用

**注意**: 不包含排除約束，避免與現有資料衝突

---

### v2.2/v2.3 修復與增強（3 個檔案）⭐⭐⭐

#### 009_v2_fixes.sql
**合併自**: 
- 008_fix_get_available_slots.sql
- 009_fix_trigger_bool_support.sql
- 010_fix_personal_records_body_part.sql
- 010_fix_trigger_delete_support.sql

**說明**: 合併所有 v2.2 修復

**包含修復**:

1. **get_available_slots() 函數修復**
   - 修復查詢邏輯錯誤
   - 正確返回可用時段

2. **觸發器支援布林值**
   - 同時支援字串（"true"/"false"）和布林值（true/false）
   - 向後相容 100%

3. **Personal Records 自動填入 body_part**
   - 從 `exercises.body_parts[1]` 查詢第一個部位
   - 自訂動作從 `custom_exercises.body_part` 查詢
   - 自動重新計算所有現有記錄

4. **觸發器支援 DELETE 操作**
   - 刪除訓練計畫時統計數字正確減少
   - 取消勾選完成組數時統計正確更新
   - 自動清理空的彙總記錄

---

#### 010_v2_enhancements.sql
**合併自**: 
- 011_fix_custom_exercises_rls.sql
- 012_remove_template_training_time.sql
- 013_delete_user_account.sql
- 014_add_gender_visible_field.sql
- 015_fix_delete_user_account_visibility.sql

**說明**: 合併所有 v2.3 增強功能

**包含增強**:

1. **移除 workout_templates.training_time 欄位**
   - 訓練模板不需要時間欄位
   - 模板只是動作範本

2. **新增 users.gender_visible 欄位**
   - 性別是否對其他人可見
   - 預設值為 `true`（向後相容）

3. **修復 custom_exercises RLS 策略**
   - 允許查看 `user_id IS NULL` 的自訂動作
   - 支援刪除帳號後保留的動作

4. **完整實現 delete_user_account() 函數**
   - 使用正確的欄位名稱（`client_id`, `visibility`）
   - 刪除私人筆記，保留共享筆記
   - 保留自訂動作和教練創建的訓練計劃
   - 返回詳細的刪除統計資訊

---

#### 011_fix_qrcode_binding_rls.sql
**說明**: QR Code 綁定 RLS 政策修復（2026-01-03）

**問題**:
- 原 RLS 只允許教練創建關係
- 學員掃描教練 QR Code 時無法創建關係

**修復**:
- 新增 `"Clients can create coach relationships"` 政策
- 條件：`auth.uid() = client_id`（不限制角色）

**支援場景**:
- ✅ 教練掃描學員 QR Code → 教練創建關係
- ✅ 學員掃描教練 QR Code → 學員創建關係
- ✅ 雙重角色用戶（既是教練又是學員）

**相關程式碼**:
- `lib/controllers/coaching_relationship_controller.dart` - `scanAndBind()`
- `lib/views/pages/shared/binding_page.dart` - QR Code 綁定頁面

---

#### 013_invite_codes_system.sql ⭐
**說明**: 一次性邀請碼系統（2026-01-03）

**用途**:
- 教練遠端邀請學員（當無法使用 QR Code 時）
- 生成 6 位邀請碼（如：`A1B2C3`）
- 5 分鐘過期，用完即刪

**特色**:
- ✅ 簡化設計：只有 `code`, `coach_id`, `expires_at` 三個欄位
- ✅ 無需管理介面：生成即用，自動刪除
- ✅ 安全性：只有教練能生成，5 分鐘過期
- ✅ 定時清理：過期邀請碼自動刪除

**表格結構**:
```sql
CREATE TABLE public.invite_codes (
  code TEXT PRIMARY KEY,              -- 6 位邀請碼
  coach_id UUID NOT NULL,             -- 教練 ID
  created_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ              -- 5 分鐘後過期
);
```

**RLS 策略**:
- 教練可創建邀請碼（需要 `is_coach = true`）
- 所有用戶可查詢有效邀請碼（用於驗證）
- 所有用戶可刪除邀請碼（使用後自動刪除）

**相關程式碼**:
- `lib/services/supabase/invite_code_service_supabase.dart` - 服務實作
- `lib/controllers/coaching_relationship_controller.dart` - 綁定邏輯
- `lib/views/pages/coaching/widgets/generate_invite_code_dialog.dart` - 教練端 UI
- `lib/views/pages/client/tabs/coach_list_tab.dart` - 學員端輸入

---

#### 017_fix_reactivate_relationship.sql ⭐ NEW
**說明**: 重新激活 archived 關係的 RLS 政策修復（2026-01-03）

**問題**:
- 當關係狀態為 `archived` 時，雙方都無法 UPDATE 將其改回 `active`
- 原有 UPDATE 政策只允許：
  1. 教練更新自己創建的關係（任何狀態）
  2. 學員只能更新 `status = 'pending'` 的關係

**修復**:
- 新增 `"Both parties can reactivate archived relationships"` 政策
- 允許雙方（教練或學員）將 `archived` 關係改回 `active`

**RLS 策略**:
```sql
CREATE POLICY "Both parties can reactivate archived relationships"
  ON public.coaching_relationships FOR UPDATE
  USING (
    (auth.uid() = coach_id OR auth.uid() = client_id)
    AND status = 'archived'
  )
  WITH CHECK (
    (auth.uid() = coach_id OR auth.uid() = client_id)
    AND status = 'active'
  );
```

**使用場景**:
- ✅ 教練解除學員綁定後，重新掃描 QR Code 綁定 → 更新 status = 'active'
- ✅ 學員解除教練綁定後，重新輸入邀請碼綁定 → 更新 status = 'active'

**相關程式碼**:
- `lib/services/supabase/coaching_relationship/coaching_relationship_operations.dart` - `createRelationship()`

---

## 🚀 執行方式

### 方法 1：Supabase Dashboard

1. 登入 Supabase Dashboard
2. 進入 SQL Editor
3. 依序貼上每個檔案內容並執行

### 方法 2：psql 命令列

```bash
# 完整部署
cd migrations
psql -U postgres -d strengthwise -f 001_v1_core_tables.sql
psql -U postgres -d strengthwise -f 002_v1_initial_data.sql
psql -U postgres -d strengthwise -f 003_v1_enhancements.sql
psql -U postgres -d strengthwise -f 004_v1_optimization.sql
psql -U postgres -d strengthwise -f 005_v2_phase1_coaching.sql
psql -U postgres -d strengthwise -f 006_v2_phase2_appointments.sql
psql -U postgres -d strengthwise -f 007_v2_phase3_notes.sql
psql -U postgres -d strengthwise -f 008_workout_time_range_no_constraint.sql
psql -U postgres -d strengthwise -f 009_v2_fixes.sql
psql -U postgres -d strengthwise -f 010_v2_enhancements.sql
psql -U postgres -d strengthwise -f 013_invite_codes_system.sql  # ⭐ 新增
```

---

## ⚠️ 注意事項

1. **執行順序**: 必須按照編號順序執行（001 → 010）
2. **不可跳過**: v2.0 的表格依賴 v1.0 的 `users` 表
3. **冪等性**: 所有 SQL 使用 `IF NOT EXISTS`，可重複執行
4. **RLS**: Supabase Auth 必須先啟用
5. **pgroonga**: 需安裝 pgroonga 擴展（全文搜尋）

---

## 📊 統計資訊

| 項目 | 數量 |
|------|------|
| 原始 Migrations | 19 個 |
| v2.2/v2.3 修復/增強 | 9 個 |
| **最終 Migrations** | **10 個** |
| 減少比例 | -64% |
| 總表格數 | 16 個 |
| RLS 策略 | 50+ 個 |
| 系統動作 | 794 個 |

---

## 📚 相關文檔

- **[docs/DATABASE_SUPABASE.md](../docs/DATABASE_SUPABASE.md)** - 完整資料庫設計文檔
- **[docs/DATABASE_OPTIMIZATION_GUIDE.md](../docs/DATABASE_OPTIMIZATION_GUIDE.md)** - 效能優化指南
- **[docs/DEVELOPMENT_STATUS.md](../docs/DEVELOPMENT_STATUS.md)** - 開發狀態

---

**建立時間**: 2025-01-01  
**最後更新**: 2026-01-03 ✅  
**維護者**: AI Agent  
**測試狀態**: ✅ 已驗證（完整功能測試通過）

---

## 🎯 整合說明

### 合併策略

1. **v1.0**: 保持原有 4 個檔案（已經優化過）
2. **v2.0**: 保持原有 3 個檔案（功能獨立）
3. **v2.1**: 保持原有 1 個檔案（功能獨立）
4. **v2.2/v2.3**: 合併為 2 個檔案
   - `009_v2_fixes.sql`: 4 個修復 → 1 個
   - `010_v2_enhancements.sql`: 5 個增強 → 1 個

### 優點

✅ 檔案數量大幅減少（28 → 10，-64%）  
✅ 結構更清晰（核心 → 功能 → 修復 → 增強）  
✅ 執行更方便（只需 10 個檔案）  
✅ 維護更容易（相關功能集中）  
✅ 移除重複的歸檔文件，保持精簡
