# Scripts - Python 工具腳本

> 資料庫管理、測試資料生成、圖片處理工具

**最後更新**：2026-01-12（v3.3 整理完成）

---

## 📁 檔案結構

```
scripts/
├── crop_status_bar.py                    # 裁剪截圖狀態欄
├── crop_white_border.py                  # 填充圖片白邊
├── resize_store_images.py                # 調整商店圖片尺寸
├── README.md
└── tools/
    ├── download_complete_database.py     # 下載完整資料庫（24 表格）
    ├── delete_all_workouts.py            # 刪除訓練記錄
    ├── clear_summary_tables.py           # 清空統計表
    ├── reset_statistics.py               # 重置統計（清空+重算）
    ├── generate_training_data_with_timezone.py  # 生成假資料
    ├── export_db_schema.py               # 導出資料庫 Schema
    └── verify_daily_summary.py           # 驗證統計正確性
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

**維護者**：StrengthWise 開發團隊
