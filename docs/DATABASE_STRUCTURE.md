# StrengthWise - 資料庫結構文檔

> **最後更新**: 2025年12月31日 08:35:46
> **資料庫**: Supabase PostgreSQL
> **表格數量**: 16 個

---

## 📋 目錄

### v1.0 核心表格
- [users](#users) (4 筆)
- [exercises](#exercises) (794 筆)
- [custom_exercises](#custom_exercises) (6 筆)
- [workout_plans](#workout_plans) (28 筆)
- [workout_templates](#workout_templates) (8 筆)
- [body_data](#body_data) (14 筆)
- [notes](#notes) (0 筆)

### v1.0 元數據表格
- [body_parts](#body_parts) (8 筆)
- [exercise_types](#exercise_types) (3 筆)

### v2.0 Phase 1: 教練學員系統
- [coaching_relationships](#coaching_relationships) (4 筆) ✅

### v2.0 Phase 2: 預約系統
- [availability_slots](#availability_slots) (2 筆) ✅
- [appointments](#appointments) (6 筆) ✅

### v2.0 Phase 3: 視覺化筆記與時間管理 ⭐
- [session_notes](#session_notes) (2 筆) ✅
- [client_availability](#client_availability) (2 筆) ✅

### 統計彙總表格（效能優化）
- [daily_workout_summary](#daily_workout_summary) (26 筆)
- [personal_records](#personal_records) (15 筆)

---

## 📊 表格詳細資訊

### users

**記錄數**: 4 筆
**欄位數**: 17 個

#### 欄位結構

| 欄位名稱 | 資料型別 | 範例值 |
|---------|---------|--------|
| `id` | str | 674b2d21-eaf3-4ab9-8751-d90126d3c75e |
| `email` | str | mark61102005@gmail.com |
| `display_name` | NULL | NULL |
| `photo_url` | NULL | NULL |
| `nickname` | NULL | NULL |
| `gender` | NULL | NULL |
| `height` | NULL | NULL |
| `weight` | float | 150.0 |
| `age` | NULL | NULL |
| `birth_date` | NULL | NULL |
| `is_coach` | bool | NULL |
| `is_student` | bool | True |
| `bio` | NULL | NULL |
| `unit_system` | str | metric |
| `profile_created_at` | str | 2025-12-27T07:18:36.627305+00:00 |
| `profile_updated_at` | str | 2025-12-27T07:26:36.656152+00:00 |
| `last_login` | str | 2025-12-27T07:18:36.627305+00:00 |

**說明**: 用戶資料表
- 包含 Google Sign-In 認證資訊
- 支援 `is_coach` 欄位（教練模式）

---

### exercises

**記錄數**: 794 筆
**欄位數**: 28 個

#### 欄位結構

| 欄位名稱 | 資料型別 | 範例值 |
|---------|---------|--------|
| `id` | str | 84i8R6FXn88ABbEDv9cf |
| `name` | str | TRX/衝刺 |
| `name_en` | str | Suspension trainer/Sprint |
| `action_name` | str | 衝刺 |
| `training_type` | str | 阻力訓練 |
| `body_part` | str | 全身 |
| `body_parts` | list | ['全身'] |
| `specific_muscle` | str | 全身綜合 |
| `equipment` | str | 徒手訓練 |
| `equipment_category` | str | 徒手訓練 |
| `equipment_subcategory` | str | 自身體重 |
| `joint_type` | str | 多關節 |
| `level1` | str | TRX |
| `level2` | str | NULL |
| `level3` | str | NULL |
| `level4` | str | NULL |
| `level5` | str | NULL |
| `description` | str | NULL |
| `image_url` | str | NULL |
| `video_url` | str | NULL |
| `user_id` | NULL | NULL |
| `created_at` | NULL | NULL |
| `updated_at` | str | 2025-12-25T22:32:53.718418+00:00 |
| `training_type_en` | str | Resistance Training |
| `body_part_en` | str | Full Body |
| `specific_muscle_en` | str | Total Body |
| `equipment_category_en` | str | Bodyweight Training |
| `equipment_subcategory_en` | str | Bodyweight |

**說明**: 系統內建動作庫（794 個專業動作）
- 五階層分類：訓練類型 → 身體部位 → 動作分類 → 具體動作
- 支援中英雙語（繁體中文 + English）
- pgroonga 全文搜尋索引

---

### custom_exercises

**記錄數**: 6 筆
**欄位數**: 13 個

#### 欄位結構

| 欄位名稱 | 資料型別 | 範例值 |
|---------|---------|--------|
| `id` | str | AdQUEfIYoyC4aXoWXt7W |
| `user_id` | str | 674b2d21-eaf3-4ab9-8751-d90126d3c75e |
| `name` | str | 哈克深蹲 |
| `body_part` | str | 腿部 |
| `equipment` | str | 固定式機械 |
| `description` | str | NULL |
| `notes` | str | NULL |
| `created_at` | str | 2025-12-27T07:50:09.865525+00:00 |
| `updated_at` | str | 2025-12-27T07:50:09.865525+00:00 |
| `training_type` | str | 阻力訓練 |
| `training_type_en` | str | Resistance Training |
| `body_part_en` | str | Legs |
| `equipment_en` | str | Machine |

**說明**: 用戶自訂動作
- 用戶可創建個人化動作
- 與系統動作統一整合（統計、訓練計劃）

---

### workout_plans

**記錄數**: 28 筆
**欄位數**: 19 個

#### 欄位結構

| 欄位名稱 | 資料型別 | 範例值 |
|---------|---------|--------|
| `id` | str | 4Yh4W8brlEjBVJl4bQ2f |
| `user_id` | str | d1798674-0b96-4c47-a7c7-ee20a5372a03 |
| `creator_id` | str | d1798674-0b96-4c47-a7c7-ee20a5372a03 |
| `trainee_id` | str | d1798674-0b96-4c47-a7c7-ee20a5372a03 |
| `title` | str | 全身功能性訓練2 |
| `description` | NULL | NULL |
| `plan_type` | str | self |
| `ui_plan_type` | NULL | NULL |
| `scheduled_date` | str | 2025-12-28T15:34:07.182624+00:00 |
| `completed_date` | str | 2025-12-28T15:34:08.057207+00:00 |
| `training_time` | str | 2025-12-27T17:00:25.914536+00:00 |
| `exercises` | list | [{'sets': [{'note': '', 'reps': 10, 'weight': 50.0 |
| `completed` | bool | True |
| `total_exercises` | int | NULL |
| `total_sets` | int | NULL |
| `total_volume` | float | NULL |
| `note` | str | 全身複合動作的功能性訓練 |
| `created_at` | str | 2025-12-28T15:34:03.395977+00:00 |
| `updated_at` | str | 2025-12-28T15:34:03.395977+00:00 |

**說明**: 訓練計劃與記錄（統一表格）
- `completed = false`: 未完成的訓練計劃
- `completed = true`: 已完成的訓練記錄
- 包含 JSONB exercises 欄位（完整訓練數據）

---

### workout_templates

**記錄數**: 8 筆
**欄位數**: 9 個

#### 欄位結構

| 欄位名稱 | 資料型別 | 範例值 |
|---------|---------|--------|
| `id` | str | 7pIo0ydHGN7c92dilavp |
| `user_id` | str | d1798674-0b96-4c47-a7c7-ee20a5372a03 |
| `title` | str | 下肢訓練 |
| `description` | str | 腿部和核心的全面訓練 |
| `plan_type` | str | 力量訓練 |
| `exercises` | list | [{'id': '2ff3605c-7021-4cee-8129-f292572b8f82', 'n |
| `training_time` | NULL | NULL |
| `created_at` | str | 2025-12-26T10:13:06.705166+00:00 |
| `updated_at` | str | 2025-12-26T10:13:06.705166+00:00 |

**說明**: 訓練模板
- 用戶可保存常用訓練計劃為模板
- 快速創建新訓練計劃

---

### body_data

**記錄數**: 14 筆
**欄位數**: 10 個

#### 欄位結構

| 欄位名稱 | 資料型別 | 範例值 |
|---------|---------|--------|
| `id` | str | vyhaMCqNdkzWfjiUU2Up |
| `user_id` | str | d1798674-0b96-4c47-a7c7-ee20a5372a03 |
| `record_date` | str | 2025-12-25T19:48:58.726153+00:00 |
| `weight` | int | 80 |
| `body_fat` | NULL | NULL |
| `muscle_mass` | NULL | NULL |
| `bmi` | NULL | NULL |
| `notes` | NULL | NULL |
| `created_at` | str | 2025-12-25T19:49:04.393438+00:00 |
| `updated_at` | NULL | NULL |

**說明**: 身體數據追蹤
- 體重、體脂、BMI、肌肉量
- 每日一筆邏輯（同天更新而非新增）

---

### notes

**記錄數**: 0 筆
**欄位數**: 0 個

---

### body_parts

**記錄數**: 8 筆
**欄位數**: 8 個

#### 欄位結構

| 欄位名稱 | 資料型別 | 範例值 |
|---------|---------|--------|
| `id` | str | epHlrDTlBP4cARI4Q3cE |
| `name` | str | 全身 |
| `description` | str | NULL |
| `count` | int | 145 |
| `created_at` | str | 2025-12-24T22:28:45.222638+00:00 |
| `updated_at` | str | 2025-12-25T21:59:21.475545+00:00 |
| `name_en` | str | Full Body |
| `description_en` | str | Full body compound movements |

---

### exercise_types

**記錄數**: 3 筆
**欄位數**: 8 個

#### 欄位結構

| 欄位名稱 | 資料型別 | 範例值 |
|---------|---------|--------|
| `id` | str | uWL6kZ3GwSJ3DYZUMRh8 |
| `name` | str | 阻力訓練 |
| `description` | str | NULL |
| `count` | int | 744 |
| `created_at` | str | 2025-12-24T22:28:45.561825+00:00 |
| `updated_at` | str | 2025-12-25T21:59:21.475545+00:00 |
| `name_en` | str | Resistance Training |
| `description_en` | str | Training using resistance to build muscle strength |

---

### coaching_relationships

**記錄數**: 4 筆
**欄位數**: 9 個

#### 欄位結構

| 欄位名稱 | 資料型別 | 範例值 |
|---------|---------|--------|
| `id` | str | 57c96398-dc9f-4143-ae3d-130fac047039 |
| `coach_id` | str | 1d7f5ed6-7759-4abc-9832-9db791e75e4f |
| `client_id` | str | d1798674-0b96-4c47-a7c7-ee20a5372a03 |
| `status` | str | active |
| `notes` | str | 測試學員 1 - 良朱 (charlie19960414) |
| `invited_at` | str | 2025-12-28T08:02:14.025818+00:00 |
| `accepted_at` | NULL | NULL |
| `created_at` | str | 2025-12-28T08:02:14.025818+00:00 |
| `updated_at` | str | 2025-12-28T08:02:14.025818+00:00 |

**說明**: 教練與學員關係表（v2.0 Phase 1）
- 教練可邀請學員建立綁定關係
- 支援狀態管理：pending, active, archived
- RLS 策略保護資料安全

---

### availability_slots

**記錄數**: 2 筆
**欄位數**: 8 個

#### 欄位結構

| 欄位名稱 | 資料型別 | 範例值 |
|---------|---------|--------|
| `id` | str | 20f8a03d-b22f-4af8-b5a6-50672dfe6c8f |
| `coach_id` | str | d1798674-0b96-4c47-a7c7-ee20a5372a03 |
| `time_range` | str | ["2025-12-29 09:00:00+00","2025-12-29 10:00:00+00" |
| `recurrence_rule` | NULL | NULL |
| `is_override` | bool | NULL |
| `notes` | NULL | NULL |
| `created_at` | str | 2025-12-28T03:35:42.157741+00:00 |
| `updated_at` | str | 2025-12-28T03:35:42.157752+00:00 |

**說明**: 教練可用時段表（v2.0 Phase 2）
- 使用 PostgreSQL TSTZRANGE 時間範圍類型
- 支援 iCal RRULE 週期性規則
- GiST 索引優化範圍查詢

---

### appointments

**記錄數**: 6 筆
**欄位數**: 14 個

#### 欄位結構

| 欄位名稱 | 資料型別 | 範例值 |
|---------|---------|--------|
| `id` | str | b317dee5-4b95-41e4-af46-bffb510bdb31 |
| `coach_id` | str | 1d7f5ed6-7759-4abc-9832-9db791e75e4f |
| `client_id` | str | d1798674-0b96-4c47-a7c7-ee20a5372a03 |
| `time_range` | str | ["2025-12-29 10:00:00+00","2025-12-29 11:00:00+00" |
| `status` | str | cancelled |
| `workout_plan_id` | NULL | NULL |
| `notes` | NULL | NULL |
| `client_notes` | NULL | NULL |
| `coach_notes` | NULL | NULL |
| `cancellation_reason` | str | 教練拒絕 |
| `cancelled_by` | str | 1d7f5ed6-7759-4abc-9832-9db791e75e4f |
| `cancelled_at` | str | 2025-12-28T12:28:09.346409+00:00 |
| `created_at` | str | 2025-12-28T04:04:08.725304+00:00 |
| `updated_at` | str | 2025-12-28T04:28:10.496836+00:00 |

**說明**: 預約記錄表（v2.0 Phase 2）
- 學員預約教練可用時段
- 狀態機：pending → confirmed → completed / cancelled
- GiST 排除約束防止雙重預約

---

### session_notes

**記錄數**: 2 筆
**欄位數**: 9 個

#### 欄位結構

| 欄位名稱 | 資料型別 | 範例值 |
|---------|---------|--------|
| `id` | str | ea482a44-603b-4f8c-8bda-d9099b55328e |
| `client_id` | str | 1d7f5ed6-7759-4abc-9832-9db791e75e4f |
| `coach_id` | str | d1798674-0b96-4c47-a7c7-ee20a5372a03 |
| `appointment_id` | NULL | NULL |
| `workout_log_id` | NULL | NULL |
| `content` | dict | {'soap': {'plan': '增加彈力帶訓練', 'objective': '深蹲時膝蓋內夾 |
| `visibility` | str | shared |
| `created_at` | str | 2025-12-29T15:59:34.225735+00:00 |
| `updated_at` | str | 2025-12-29T15:59:34.225735+00:00 |

**說明**: 視覺化筆記表（v2.0 Phase 3）⭐
- SOAP 格式專業筆記（Subjective, Objective, Assessment, Plan）
- JSONB 混合內容：文字 + 手繪圖 + 照片 + 語音
- Private/Shared 隱私控制
- Storage Buckets: coach_drawings, session_photos, voice_notes

---

### client_availability

**記錄數**: 2 筆
**欄位數**: 8 個

#### 欄位結構

| 欄位名稱 | 資料型別 | 範例值 |
|---------|---------|--------|
| `id` | str | 7d93a410-4b0a-42c5-946f-070b92cf5af8 |
| `client_id` | str | 1d7f5ed6-7759-4abc-9832-9db791e75e4f |
| `time_range` | str | ["2025-01-06 10:00:00+00","2025-01-06 12:00:00+00" |
| `recurrence_rule` | str | FREQ=WEEKLY;BYDAY=MO,WE,FR |
| `priority` | str | preferred |
| `notes` | str | 這是我最常去健身房的時段 |
| `created_at` | str | 2025-12-29T15:59:34.225735+00:00 |
| `updated_at` | str | 2025-12-29T15:59:34.225735+00:00 |

**說明**: 學員時間偏好表（v2.0 Phase 3）⭐
- 學員設定可運動時間（雙向時間管理）
- 使用 TSTZRANGE + RRULE 支援週期性時段
- 優先級：preferred, available, avoid
- 教練可查看學員時間偏好

---

### daily_workout_summary

**記錄數**: 26 筆
**欄位數**: 15 個

#### 欄位結構

| 欄位名稱 | 資料型別 | 範例值 |
|---------|---------|--------|
| `id` | str | 80a1b620-78dc-4ea8-810d-34e5157b18c8 |
| `user_id` | str | d1798674-0b96-4c47-a7c7-ee20a5372a03 |
| `date` | str | 2025-12-15 |
| `workout_count` | int | 1 |
| `total_exercises` | int | 4 |
| `total_sets` | int | 17 |
| `total_volume` | float | 7497.8 |
| `resistance_training_count` | int | NULL |
| `cardio_count` | int | NULL |
| `mobility_count` | int | NULL |
| `total_training_time` | int | NULL |
| `created_at` | str | 2025-12-28T15:33:12.773534+00:00 |
| `updated_at` | str | 2025-12-28T15:33:12.773534+00:00 |
| `completed_workout_count` | int | 1 |
| `partial_workout_count` | int | NULL |

**說明**: 每日訓練統計彙總（效能優化 Phase 3）
- 自動計算每日訓練統計（觸發器）
- 包含訓練量、訓練組數、訓練動作數等
- 查詢效能提升 80-95%

---

### personal_records

**記錄數**: 15 筆
**欄位數**: 12 個

#### 欄位結構

| 欄位名稱 | 資料型別 | 範例值 |
|---------|---------|--------|
| `id` | str | 4c7ef9d9-021b-4559-ba5e-45e96385449d |
| `user_id` | str | 674b2d21-eaf3-4ab9-8751-d90126d3c75e |
| `exercise_id` | str | a213b93e-b688-43a9-9e1d-3c58a5070358 |
| `exercise_name` | str | 哈克深蹲 |
| `max_weight` | float | 200.0 |
| `max_reps` | int | 10 |
| `max_volume` | float | 2000.0 |
| `achieved_date` | str | 2025-12-27 |
| `workout_plan_id` | str | TOzc66BjaFqo34gN2foe |
| `created_at` | str | 2025-12-28T15:06:50.026102+00:00 |
| `updated_at` | str | 2025-12-28T15:06:50.026102+00:00 |
| `body_part` | NULL | NULL |

**說明**: 個人記錄彙總（效能優化 Phase 3）
- 自動計算每個動作的最大重量（觸發器）
- 追蹤個人最佳記錄（PR）
- 查詢效能提升 90-98%

---

## 📈 資料庫統計

- **總表格數**: 16 個
- **總記錄數**: 922 筆

### 各表格記錄數

| 表格名稱 | 記錄數 |
|---------|--------|
| exercises | 794 |
| workout_plans | 28 |
| daily_workout_summary | 26 |
| personal_records | 15 |
| body_data | 14 |
| workout_templates | 8 |
| body_parts | 8 |
| custom_exercises | 6 |
| appointments | 6 |
| users | 4 |
| coaching_relationships | 4 |
| exercise_types | 3 |
| availability_slots | 2 |
| session_notes | 2 |
| client_availability | 2 |
| notes | 0 |

---

## 🔗 相關文檔

- [DATABASE_SUPABASE.md](DATABASE_SUPABASE.md) - 詳細資料庫設計
- [DATABASE_OPTIMIZATION_GUIDE.md](DATABASE_OPTIMIZATION_GUIDE.md) - 效能優化指南
- [migrations/](../migrations/) - SQL 遷移腳本

---

**生成時間**: 2025-12-31 08:35:46
