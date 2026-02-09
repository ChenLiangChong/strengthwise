# StrengthWise Migrations

> 資料庫 Migration 文件索引

**最後更新**：2026-02-10（v5.2 安全性修復）

---

## 📁 文件結構

```
migrations/
├── consolidated/           # 精簡版（新部署推薦）- 10 個文件
│   ├── 01_extensions.sql
│   ├── 02_types.sql
│   ├── 03_tables.sql
│   ├── 04_foreign_keys.sql
│   ├── 05_indexes.sql
│   ├── 06_functions.sql
│   ├── 07_triggers.sql
│   ├── 08_rls_policies.sql
│   ├── 09_views.sql
│   └── 10_initial_data.sql
│
├── 001_v1_core_tables.sql  # 演進版 - 28 個文件
├── 002_v1_initial_data.sql
├── ... (按版本演進)
└── README.md
```

---

## 🚀 使用方式

### 方式一：新部署（使用 consolidated）

適合全新環境，一次性建立完整 Schema：

```bash
cd migrations/consolidated
psql -U postgres -d strengthwise -f 01_extensions.sql
psql -U postgres -d strengthwise -f 02_types.sql
# ... 按順序執行 01-10
```

### 方式二：演進部署（使用主目錄）

適合了解資料庫演進歷史，或需要追蹤變更：

```bash
cd migrations
psql -U postgres -d strengthwise -f 001_v1_core_tables.sql
psql -U postgres -d strengthwise -f 002_v1_initial_data.sql
# ... 按順序執行 001-26, 32-33
```

---

## 📋 演進版文件說明

### 核心基礎（v1.0）

| 文件 | 版本 | 描述 |
|------|------|------|
| `001_v1_core_tables.sql` | v1.0 | 核心表格（users, exercises, workout_plans, templates）|
| `002_v1_initial_data.sql` | v1.0 | 794 個動作初始資料 |
| `003_v1_enhancements.sql` | v1.0 | 自訂動作、pgroonga 搜尋 |
| `004_v1_optimization.sql` | v1.0 | 統計系統（daily_summary, personal_records）|

### 教練學員系統（v2.0）

| 文件 | 版本 | 描述 |
|------|------|------|
| `005_v2_phase1_coaching.sql` | v2.0 | 教練學員關係系統 |
| `006_v2_phase2_appointments.sql` | v2.0 | 預約系統（availability_slots, appointments）|
| `007_v2_phase3_notes.sql` | v2.0 | Session Notes（視覺化筆記）|
| `008_workout_time_range_no_constraint.sql` | v2.0 | 訓練時間範圍欄位 |

### 合併後的 Migration（v2.2+）

| 文件 | 來源 | 版本 | 描述 |
|------|------|------|------|
| `09_v2_fixes_and_enhancements.sql` | 009, 010 | v2.2-v2.3 | 函數修復、布林值處理、PR body_part |
| `10_v2_binding_system.sql` | 011, 013, 024 | v2.2+ | QR 碼綁定、邀請碼、RPC 函數 |
| `11_v2_data_preservation.sql` | 014, 015 | v2.3+ | SET NULL 策略、姓名快照 |
| `12_v2_health_assessment.sql` | 016, 016_verify, 021 | v2.8 | PAR-Q+ 健康評估系統 |
| `13_v2_relationship_rls.sql` | 017-020 | v2.8 | 關係 RLS、session_notes 隱藏 |
| `14_v2_pr_fixes.sql` | 022, 023 | v2.8 | PR 觸發器修復、回滾邏輯 |
| `15_v2_coach_system.sql` | 025, 026, 027 | v2.9-v2.9.1 | 教練表、DELETE RLS、訓練狀態 |
| `16_v3_appointment_booking.sql` | 028-031 | v3.0 | 預約設定、readiness、Session Mode |
| `17_v3_fcm_devices.sql` | 033 | v3.0-C | FCM Token 多設備管理 |
| `18_v3_session_mode_fixes.sql` | 034, 035 | v3.1 | Session Mode 觸發器修復 |
| `19_v3_rls_and_summary.sql` | 036-041 | v3.1.1 | RLS 完善、統計觸發器、清理 |
| `20_v3_injury_tracking.sql` | 042, 043, 044_injury | v3.3 | 傷病備註、睡眠範圍 |
| `21_v3_tracking_mode.sql` | 044, 044b, 045 | v3.2+ | TrackingMode 欄位與搜尋 |
| `22_v3_pr_final_fixes.sql` | 046, 047 | v3.3 | PR DELETE 觸發器、ID 格式修復 |
| `23_fix_pr_weight_time.sql` | - | v3.3.1 | 修復 weight_time 模式被錯誤納入 PR |
| `24_v5_exercise_classification_v2.sql` | - | v5.0 | 動作分類系統 v2 Schema（新欄位、別名表、參照表）|
| `25_v5_exercise_data_import.sql` | - | v5.0 | 動作分類 v2 資料匯入（775 筆 + 2344 別名）|
| `26_v5_update_exercise_names_to_see.sql` | - | v5.0 | 歷史資料動作名稱更新為 SEE 標準名稱 + trigger 修改 |
| `27_v5_fix_equipment_column.sql` | - | v5.0 | 修復 exercises.equipment 欄位為 ref_equipment.id 標準值 |
| `28_v5_drop_search_rpc.sql` | - | v5.0 | 移除 search_exercises_v2 RPC（改用客戶端快取篩選） |
| `32_add_webhooks_availability.sql` | - | v3.9 | FCM Webhook 配置說明（手動在 Dashboard） |
| `33_enable_realtime_availability.sql` | - | v3.9 | 開啟 Realtime + REPLICA IDENTITY FULL |
| `34_app_config.sql` | - | v5.1 | App 全局配置表（版本檢查）|
| `35_security_fixes.sql` | - | v5.2 | 安全性修復（invite_codes DELETE RLS）|

---

## 🔄 執行順序

```
演進版：001 → 002 → ... → 008 → 09 → 10 → ... → 23 → 24 → 25 → 26 → 27 → 28 → 32 → 33 → 34 → 35

精簡版：01 → 02 → ... → 10
```

---

## 📦 原始文件對照表

| 合併後 | 原始文件 |
|--------|----------|
| 09 | 009_v2_fixes.sql, 010_v2_enhancements.sql |
| 10 | 011_fix_qrcode_binding_rls.sql, 013_invite_codes_system.sql, 024_binding_rpc_functions.sql |
| 11 | 014_client_profile.sql, 015_fix_cascade_to_set_null.sql |
| 12 | 016_health_assessments.sql, 016_health_assessments_verify.sql, 021_coach_assessment_notes.sql |
| 13 | 017_fix_reactivate_relationship.sql, 018_add_hidden_by_client.sql, 019_fix_client_archive_relationship.sql, 020_remove_client_profile.sql |
| 14 | 022_fix_pr_trigger_body_part.sql, 023_fix_updated_at.sql |
| 15 | 025_coaches_table.sql, 026_fix_workout_delete_rls.sql, 027_add_training_status_fields.sql |
| 16 | 028_coach_booking_settings.sql, 029_add_rejected_status.sql, 030_daily_readiness.sql, 031_session_auto_create.sql |
| 17 | 033_user_devices.sql |
| 18 | 034_fix_session_auto_create.sql, 035_fix_session_note_visibility.sql |
| 19 | 036_fix_missing_rls.sql, 037_fix_daily_summary_rls.sql, 038_fix_daily_summary_trigger.sql, 039_add_scheduled_workout_count.sql, 040_coach_create_appointment_rls.sql, 041_cancel_appointment_cleanup.sql |
| 20 | 042_injury_coach_notes.sql, 043_sleep_hours_range.sql, 044_injury_notes_client_access.sql |
| 21 | 044_tracking_mode.sql, 044b_tracking_mode_manual.sql, 045_search_tracking_mode.sql |
| 22 | 046_fix_pr_delete_trigger.sql, 047_fix_exercise_id_format.sql |

---

## ⚠️ 注意事項

1. **Extensions**：需先安裝 pgroonga 擴展
2. **順序**：必須按編號順序執行
3. **冪等性**：使用 `IF NOT EXISTS` 和 `CREATE OR REPLACE`
4. **生產環境**：如已部署原始 48 個文件，無需重新執行合併版

---

**維護者**：StrengthWise 開發團隊
