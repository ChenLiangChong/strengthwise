# Scripts - Python 工具腳本

> 資料庫管理與測試資料生成工具

**最後更新**：2026-01-05（v3.0）

---

## 📁 檔案結構

```
scripts/
├── tools/
│   ├── download_complete_database.py   # 下載完整資料庫（23 表格）
│   ├── delete_all_workouts.py          # 刪除訓練記錄
│   ├── clear_summary_tables.py         # 清空統計表
│   ├── reset_statistics.py             # 重置統計（清空+重算）
│   └── generate_training_data_with_timezone.py  # 生成假資料
└── README.md
```

---

## 🚀 快速開始

### 環境設置

```bash
pip install supabase-py python-dotenv pytz
```

`.env` 配置：
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

---

## 🛠️ 工具說明

### 1. 下載完整資料庫

```bash
python scripts/tools/download_complete_database.py
```

輸出：`database_export/YYYYMMDD_HHMMSS/`（23 個表格 JSON）

**表格分類**：
- v1.0 Core: 7 表格（users, exercises, workout_plans 等）
- v2.0 Phase 1-3: 5 表格（coaching, appointments, session_notes 等）
- v2.8 Health Assessment: 3 表格
- v2.9 Coach Profile: 1 表格（coaches）
- v3.0 Booking Optimization: 2 表格（coach_booking_settings, daily_readiness）

---

### 2. 刪除訓練記錄

```bash
python scripts/tools/delete_all_workouts.py <user_uuid> -y
```

---

### 3. 清空統計表

```bash
python scripts/tools/clear_summary_tables.py <user_uuid>
```

清空 `daily_workout_summary` 和 `personal_records`

---

### 4. 重置統計資料

```bash
python scripts/tools/reset_statistics.py <user_uuid>
```

完整流程：清空統計表 → 觸發重新計算 → 驗證結果

---

### 5. 生成假訓練資料

```bash
python scripts/tools/generate_training_data_with_timezone.py <user_uuid>
```

生成過去一個月 PPL 訓練記錄（時區正確處理）

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
