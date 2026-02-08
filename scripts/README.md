# Scripts - Python 工具腳本

> 資料庫管理、測試資料生成、圖片處理工具

**最後更新**：2026-02-09（v5.0 動作分類系統 v2）

---

## 📁 檔案結構

```
scripts/
├── crop_status_bar.py                    # 裁剪截圖狀態欄
├── crop_white_border.py                  # 填充圖片白邊
├── resize_store_images.py                # 調整商店圖片尺寸
├── README.md
├── reference_data/                       # 參照資料（動作分類）
│   ├── ref_movement_patterns.json        # 動作模式定義
│   ├── ref_muscle_groups.json            # 肌群定義
│   └── ref_equipment.json                # 器材定義
├── review_data/                          # 動作分類審核資料
│   ├── exercises_review.csv              # 原始審核檔
│   ├── exercises_review_audited.csv      # ✅ 審核完成（779 筆）
│   └── by_muscle_grouped/*.csv           # 按肌群分割（20 檔案）
└── tools/
    ├── download_complete_database.py     # 下載完整資料庫（24 表格）
    ├── delete_all_workouts.py            # 刪除訓練記錄
    ├── clear_summary_tables.py           # 清空統計表
    ├── reset_statistics.py               # 重置統計（清空+重算）
    ├── generate_training_data_with_timezone.py  # 生成假資料
    ├── export_db_schema.py               # 導出資料庫 Schema
    ├── verify_daily_summary.py           # 驗證統計正確性
    ├── exercise_auditor.py               # 動作分類審核（多 Agent 版）
    ├── exercise_auditor_simple.py        # 動作分類審核（簡化版）
    ├── check_v4_fields.py               # v4/v5 欄位完整性檢查 ⭐ v5.0
    ├── check_see_names.py               # SEE 標準名稱檢查 ⭐ v5.0
    ├── generate_equipment_migration.py   # 器材欄位遷移 SQL 生成 ⭐ v5.0
    ├── verify_migration_25.py           # Migration 25 資料驗證 ⭐ v5.0
    └── cleanup_orphan_exercises.py      # 孤立動作清理 ⭐ v5.0
```

---

## 🚀 快速開始

### 環境設置

```bash
pip install supabase python-dotenv pytz psycopg2-binary
```

`.env` 配置：
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

---

## 🛠️ 工具說明

### 圖片處理工具（scripts/ 根目錄）

| 腳本 | 用途 |
|------|------|
| `crop_status_bar.py` | 裁剪截圖頂部狀態欄（53px）|
| `crop_white_border.py` | 從邊緣填充淺色區域（flood fill）|
| `resize_store_images.py` | 調整應用商店截圖尺寸 |

### 資料庫工具（scripts/tools/）

#### 1. 下載完整資料庫

```bash
python scripts/tools/download_complete_database.py
```

輸出：`database_export/YYYYMMDD_HHMMSS/`（24 個表格 JSON）

#### 2. 刪除訓練記錄

```bash
python scripts/tools/delete_all_workouts.py <user_uuid> -y
```

#### 3. 清空統計表

```bash
python scripts/tools/clear_summary_tables.py <user_uuid>
```

清空 `daily_workout_summary` 和 `personal_records`

#### 4. 重置統計資料

```bash
python scripts/tools/reset_statistics.py <user_uuid>
```

完整流程：清空統計表 → 觸發重新計算 → 驗證結果

#### 5. 生成假訓練資料

```bash
python scripts/tools/generate_training_data_with_timezone.py <user_uuid>
```

生成過去一個月 PPL 訓練記錄（時區正確處理）

#### 6. 導出資料庫 Schema

```bash
python scripts/tools/export_db_schema.py
```

導出完整 Schema（Tables、Triggers、Functions、RLS、Views、Indexes）

#### 7. 驗證統計正確性

```bash
python scripts/tools/verify_daily_summary.py <user_uuid>
```

檢查 daily_workout_summary 與實際資料是否一致

#### 8. v4/v5 欄位完整性檢查 ⭐ v5.0

```bash
python scripts/tools/check_v4_fields.py
```

檢查 exercises 表的 v4 欄位（trigger 向後兼容）和 v5 欄位（客戶端統計）完整性

#### 9. Migration 25 資料驗證 ⭐ v5.0

```bash
python scripts/tools/verify_migration_25.py
```

驗證 migration 25 匯入的動作分類資料是否完整（775 筆 + 2344 別名）

#### 10. 器材欄位遷移 SQL 生成 ⭐ v5.0

```bash
python scripts/tools/generate_equipment_migration.py
```

生成 migration 27 的 SQL（修復 exercises.equipment 欄位為 ref_equipment.id 標準值）

#### 11. 孤立動作清理 ⭐ v5.0

```bash
python scripts/tools/cleanup_orphan_exercises.py
```

清理不在審核 CSV 中的孤立系統動作（18 筆已清除）

---

## 📊 常用流程

```bash
# 完整重置測試資料
python scripts/tools/delete_all_workouts.py <uuid> -y
python scripts/tools/clear_summary_tables.py <uuid>
python scripts/tools/generate_training_data_with_timezone.py <uuid>
```

---

## 🧪 測試帳號

| 角色 | UUID |
|------|------|
| 教練 | `d1798674-0b96-4c47-a7c7-ee20a5372a03` |
| 學員 | `1d7f5ed6-7759-4abc-9832-9db791e75e4f` |
| 測試 | `87e64969-90f6-4c8c-b8bc-8828dfa8429a` |

---

## 🏋️ 動作分類審核工具 ✅ 已完成

> **審核狀態**：775 筆動作已完成 v2 規範審核（2026-02-08）
> **輸出檔案**：`review_data/exercises_review_audited.csv`

### 環境設置

```bash
pip install anthropic
export ANTHROPIC_API_KEY=your_api_key_here
```

### 簡化版（單一 Agent）

```bash
# Dry-run 模式（只顯示資料）
python3 scripts/tools/exercise_auditor_simple.py pecs.csv --limit 3 --dry-run

# 實際審核
python3 scripts/tools/exercise_auditor_simple.py pecs.csv --limit 5

# 指定起始位置
python3 scripts/tools/exercise_auditor_simple.py pecs.csv --start 10 --limit 10
```

### 完整版（多 Agent 並行）

```bash
# 審核 3 筆（預設）
python3 scripts/tools/exercise_auditor.py pecs.csv

# 審核全部
python3 scripts/tools/exercise_auditor.py pecs.csv --all

# 輸出 JSON
python3 scripts/tools/exercise_auditor.py pecs.csv --json --output report.json
```

### 可用的 CSV 檔案

按肌群分割（`review_data/by_muscle_grouped/`）：
- pecs.csv（胸）, delts.csv（肩）, lats.csv（背闘肌）
- quads.csv（股四頭）, hamstrings.csv（腿後）, glutes.csv（臀）
- triceps.csv（三頭）, biceps.csv（二頭）
- core.csv（核心）, calves.csv（小腿）

### 審核欄位（12 項）

| # | 欄位 | 說明 |
|---|------|------|
| 1 | 中文名稱 | SEE 格式 |
| 2 | 英文名稱 | 與中文對應 |
| 3 | 別名 | 俚語/縮寫 |
| 4 | 動作模式 | ref_movement_patterns.json |
| 5 | PPL 標籤 | push/pull/legs（可複選，如 side_delts = "push, pull"）|
| 6 | 主動肌 | 25 個有效值 |
| 7 | 協同肌 | 輔助肌群 |
| 8 | 器材 | 10 種器材 |
| 9 | 複合/孤立 | compound/isolation |
| 10 | 單邊 | TRUE/FALSE |
| 11 | 難度 | beginner/intermediate/advanced |
| 12 | is_explosive | TRUE/FALSE |

詳見：`docs/planning/EXERCISE_CLASSIFICATION_ANALYSIS.md`

---

**維護者**：StrengthWise 開發團隊
