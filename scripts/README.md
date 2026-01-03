# Scripts - Python 工具腳本

> StrengthWise 專案的資料庫管理與測試工具

**最後更新**：2026年1月1日 - v2.2 時區統一化完成 ✅

---

## 📁 檔案結構

```
scripts/
├── tools/                     # 核心工具（6 個）⭐
│   ├── generate_training_data_with_timezone.py  # 生成假訓練資料（v2.2）⭐⭐⭐
│   ├── delete_all_workouts.py                   # 刪除訓練記錄
│   ├── clear_summary_tables.py                  # 清空統計表
│   ├── reset_statistics.py                      # 重置統計資料
│   ├── download_complete_database.py            # 完整資料庫下載
│   ├── generate_database_structure_doc.py       # 資料庫文檔生成
│   ├── export_exercises_supabase.py             # 動作資料導出
│   └── setup_coaching_relationship.py           # 教練學員關係設置
│
├── checks/                    # 診斷工具（2 個）
│   ├── check_env.py           # 環境變數檢查
│   └── check_workout_data.py  # 訓練資料檢查
│
└── archived/                  # 已歸檔工具
    └── archived_migrations_tools/  # Migrations 優化工具（已完成）
```

**總計**：8 個活躍腳本（6 核心 + 2 檢查）

---

## 🚀 快速開始

### 環境設置

```bash
# 安裝依賴
pip install supabase-py pandas python-dotenv

# 配置環境變數（專案根目錄 .env）
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### 常用工作流程

#### 📊 生成測試資料（完整流程）

```bash
# 1. 刪除舊資料
python scripts/tools/delete_all_workouts.py <user_uuid> -y

# 2. 清空統計表
python scripts/tools/clear_summary_tables.py <user_uuid>

# 3. 生成一個月假資料（會自動觸發統計更新）
python scripts/tools/generate_training_data_with_timezone.py <user_uuid>
```

#### 🔧 重置統計資料

```bash
# 清空統計表並重新計算
python scripts/tools/reset_statistics.py <user_uuid>
```

---

## 🛠️ 核心工具說明

### 1️⃣ generate_training_data_with_timezone.py ⭐⭐⭐

**生成專業的過去一個月訓練假資料**（v2.2 版本）

```bash
python scripts/tools/generate_training_data_with_timezone.py <user_uuid>
```

**特色**：
- ✅ 正確處理時區（Asia/Taipei UTC+8 → UTC 儲存）
- ✅ 支援 `training_time_range` (TSTZRANGE) 欄位
- ✅ 推拉腿分化（Push-Pull-Legs）訓練計劃
- ✅ 漸進式超負荷（每週 +5% 重量）
- ✅ 智能休息日安排（週日必休 + 30% 隨機休息）
- ✅ 隨機訓練時段（早/午/晚）和時長（60-120 分鐘）
- ✅ 只使用系統動作（不使用自訂動作）
- ✅ 符合 App 的 JSON 格式（`exerciseId`, `exerciseName`, `sets`）
- ✅ 自動觸發統計資料更新

**生成內容**：
- 腿部訓練：深蹲、硬舉、保加利亞分腿蹲、弓步蹲、腿彎舉、臀推（6 個動作）
- 推日訓練：臥推、上斜推舉、肩推、三頭（4 個動作）
- 拉日訓練：硬舉、引體向上、划船、二頭（4 個動作）

---

### 2️⃣ delete_all_workouts.py

**刪除用戶所有訓練記錄**

```bash
# 互動式確認
python scripts/tools/delete_all_workouts.py <user_uuid>

# 自動確認（用於腳本）
python scripts/tools/delete_all_workouts.py <user_uuid> -y
```

**注意**：僅刪除 `workout_plans` 表，不影響統計表

---

### 3️⃣ clear_summary_tables.py

**清空統計彙總表**

```bash
python scripts/tools/clear_summary_tables.py <user_uuid>
```

**清空表格**：
- `daily_workout_summary` - 每日訓練彙總
- `personal_records` - 個人最佳記錄

**注意**：`personal_records_top_by_body_part` 是視圖，不需要清空

---

### 4️⃣ reset_statistics.py

**完整重置統計資料**

```bash
python scripts/tools/reset_statistics.py <user_uuid>
```

**執行步驟**：
1. 清空 `daily_workout_summary`
2. 清空 `personal_records`
3. 觸發所有 `workout_plans` 重新計算
4. 驗證統計資料數量

---

### 5️⃣ download_complete_database.py

**下載完整資料庫數據**（v2 版本）

```bash
python scripts/tools/download_complete_database.py
```

**輸出**：`database_export/YYYYMMDD_HHMMSS/` 資料夾包含：
- 16 個表格的 JSON 檔案
- `database_summary.json` - 統計摘要
- `README.md` - 說明文檔

---

### 6️⃣ generate_database_structure_doc.py

**生成資料庫結構文檔**

```bash
python scripts/tools/generate_database_structure_doc.py
```

**輸出**：
- `docs/DATABASE_STRUCTURE.md` - 完整結構文檔
- `database_export/database_schema_<timestamp>.json` - JSON 格式

---

### 7️⃣ export_exercises_supabase.py

**導出動作資料**

```bash
python scripts/tools/export_exercises_supabase.py
```

**輸出**：JSON 和 CSV 格式的動作資料

---

## 🔍 診斷工具

### check_env.py
驗證 `.env` 檔案配置

```bash
python scripts/checks/check_env.py
```

### check_workout_data.py
檢查用戶訓練資料

```bash
python scripts/checks/check_workout_data.py
```

---

## 📊 測試用戶 UUID

| 角色 | Email | UUID |
|------|-------|------|
| 教練 | charlie19960414@gmail.com | `d1798674-0b96-4c47-a7c7-ee20a5372a03` |
| 學員 | charlie8519960414@gmail.com | `1d7f5ed6-7759-4abc-9832-9db791e75e4f` |

---

## 🚨 重要提醒

### 資料庫觸發器

以下操作會**自動觸發統計更新**：
- ✅ `INSERT workout_plans` → 更新 `daily_workout_summary` 和 `personal_records`
- ✅ `UPDATE workout_plans` → 重新計算統計

以下操作**不會自動清理統計表**：
- ❌ `DELETE workout_plans` → 需要手動執行 `clear_summary_tables.py`

### 視圖說明

`personal_records_top_by_body_part` 是**視圖**（VIEW），不是表格：
- ✅ 自動從 `personal_records` 查詢
- ✅ 按 `body_part` 分組並取最大重量
- ✅ 不需要手動清空或更新

### 時區處理

- **Python 腳本**：使用 `Asia/Taipei` (UTC+8)
- **資料庫儲存**：統一使用 UTC
- **App 顯示**：自動轉為本地時間

---

## 📚 相關文檔

- **資料庫設計**：`docs/DATABASE_SUPABASE.md`
- **時區工具指南**：`docs/DATETIME_UTILS_GUIDE.md`
- **開發指南**：`AGENTS.md`
- **開發狀態**：`docs/DEVELOPMENT_STATUS.md`

---

**維護者**：StrengthWise 開發團隊  
**版本**：v2.2 - 時區統一化完成  
**最後更新**：2026年1月1日
