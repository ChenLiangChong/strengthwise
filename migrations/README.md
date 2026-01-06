# StrengthWise Migrations

> 資料庫架構變更腳本

**最後更新**：2026-01-07

---

## 📋 執行順序

### 完整部署（v1.0 - v2.8.1）

執行以下檔案（按順序）：

```sql
-- v1.0 核心（4 個）
001_v1_core_tables.sql          # 核心表格 + RLS
002_v1_initial_data.sql         # 系統資料（794 個動作）
003_v1_enhancements.sql         # 功能增強 + pgroonga
004_v1_optimization.sql         # 統計物化視圖

-- v2.0 功能（3 個）
005_v2_phase1_coaching.sql      # 教練學員系統
006_v2_phase2_appointments.sql  # 預約系統（TSTZRANGE + GiST）
007_v2_phase3_notes.sql         # 視覺化筆記 + Storage

-- v2.1+ 功能
008_workout_time_range_no_constraint.sql  # 訓練時間範圍
009_v2_fixes.sql                # v2.2 修復合併
010_v2_enhancements.sql         # v2.3 增強合併
011_fix_qrcode_binding_rls.sql  # QR Code RLS 修復
013_invite_codes_system.sql     # 邀請碼系統

-- v2.8 健康評估
016_health_assessments.sql      # 健康評估表 + PAR-Q+
017_fix_reactivate_relationship.sql  # 重新激活 RLS
018_add_hidden_by_client.sql    # 學員隱藏筆記
019_fix_client_archive_relationship.sql  # 學員歸檔 RLS
020_remove_client_profile.sql   # 移除舊表
021_coach_assessment_notes.sql  # 教練評估備註
022_fix_pr_trigger_body_part.sql  # PR 觸發器修復（body_part + 取消回滾）
023_fix_updated_at.sql          # 修復 022 造成的 updated_at 問題
024_binding_rpc_functions.sql   # 綁定 RPC 函數（SECURITY DEFINER）

-- v2.9 教練公開檔案
025_coaches_table.sql           # 教練公開檔案表（與 users 1:1 關聯）
026_fix_workout_delete_rls.sql  # 修正訓練計畫刪除 RLS（只有創建者可刪除）

-- v2.9.1 訓練 UX 優化
027_add_training_status_fields.sql  # 訓練狀態追蹤欄位（暫停/繼續功能）

-- v3.0 預約系統優化 + Session Mode
028_coach_booking_settings.sql      # 教練預約設定表
029_add_rejected_status.sql         # 新增預約 rejected 狀態
030_daily_readiness.sql             # 每日準備度問卷表
031_session_auto_create.sql         # 預約確認自動創建資料
033_user_devices.sql                # 用戶設備表（FCM Token 管理）

-- v3.1 修復
034_fix_session_auto_create.sql     # 修復 session_notes 觸發器欄位
035_fix_session_note_visibility.sql # 修正 session_notes 預設 visibility 為 'shared'
036_fix_missing_rls.sql             # 啟用 daily_workout_summary, personal_records RLS
037_fix_daily_summary_rls.sql       # 修復 RLS（允許教練操作學員資料）
```

### 僅部署 v1.0（單機版）

```sql
001_v1_core_tables.sql
002_v1_initial_data.sql
003_v1_enhancements.sql
004_v1_optimization.sql
```

---

## 📦 版本對應

| Migration | 版本 | 說明 |
|-----------|------|------|
| 001-004 | v1.0 | 單機版核心 |
| 005-007 | v2.0 | 教練學員、預約、筆記 |
| 008 | v2.1 | 訓練時間範圍 |
| 009-013 | v2.2-v2.4 | 修復與增強 |
| 016-021 | v2.8 | 健康評估系統 |
| 022-024 | v2.8.3-v2.8.4 | PR 觸發器修復、用戶角色修復、綁定 RPC |
| 025-026 | v2.9 | 教練公開檔案、訓練刪除 RLS |
| 027 | v2.9.1 | 訓練狀態追蹤（暫停/繼續）|
| 028-031, 033 | v3.0 | 預約優化 + Session Mode + FCM |
| 034 | v3.1 | 修復 session_notes 觸發器 |
| 035 | v3.1 | 修正 session_notes 預設 visibility |
| 036-037 | v3.1 | RLS 修復（daily_workout_summary, personal_records）|

---

## 🚀 執行方式

### Supabase Dashboard

1. 登入 Dashboard → SQL Editor
2. 依序貼上每個檔案並執行

### psql 命令列

```bash
cd migrations
psql -U postgres -d strengthwise -f 001_v1_core_tables.sql
# ...依序執行所有檔案
```

---

## ⚠️ 注意事項

| 規則 | 說明 |
|------|------|
| 順序執行 | 必須按編號順序（001 → 033）|
| 不可跳過 | v2.0 依賴 v1.0 的 `users` 表 |
| 冪等性 | 所有 SQL 使用 `IF NOT EXISTS` |
| Auth | 需先啟用 Supabase Auth |
| pgroonga | 需安裝 pgroonga 擴展 |

---

## 📎 相關文檔

- [DATABASE_SUPABASE.md](../docs/DATABASE_SUPABASE.md) - 資料庫設計
- [DATABASE_HISTORY.md](../docs/archived/DATABASE_HISTORY.md) - 資料庫變更歷史
