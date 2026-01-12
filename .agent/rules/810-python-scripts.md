---
description: "Python 工具腳本使用指南：資料庫管理、測試資料生成、統計重置、Schema 導出。"
globs: scripts/**/*.py
alwaysApply: false
---

# Python 工具腳本

<critical>
1. DELETE 不會自動清理統計表，需手動執行 `clear_summary_tables.py`
2. 時區：Python 用 `Asia/Taipei`，資料庫存 UTC
</critical>

## 🛠️ 核心工具

| 腳本 | 用途 |
|------|------|
| `generate_training_data_with_timezone.py` | 生成假訓練資料 |
| `delete_all_workouts.py` | 刪除訓練記錄 |
| `clear_summary_tables.py` | 清空統計表 |
| `reset_statistics.py` | 重置統計資料 |
| `download_complete_database.py` | 下載完整資料庫 |
| `export_db_schema.py` | 導出完整 Schema（表、函數、觸發器）|
| `verify_daily_summary.py` | 驗證統計資料一致性 |

## 📊 常用流程

```bash
# 生成測試資料
python scripts/tools/delete_all_workouts.py <uuid> -y
python scripts/tools/clear_summary_tables.py <uuid>
python scripts/tools/generate_training_data_with_timezone.py <uuid>

# 重置統計
python scripts/tools/reset_statistics.py <uuid>
```

## 🧪 測試帳號

| 角色 | UUID |
|------|------|
| 教練 | `d1798674-0b96-4c47-a7c7-ee20a5372a03` |
| 學員 | `1d7f5ed6-7759-4abc-9832-9db791e75e4f` |
| 測試 | `87e64969-90f6-4c8c-b8bc-8828dfa8429a` |

詳見：`@scripts/README.md`
