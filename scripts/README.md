# Scripts - 工具腳本（Supabase 版本）

> StrengthWise 專案的 Python 工具腳本

**最後更新**：2024年12月29日 - 清理過時腳本 ✅

---

## 📁 檔案結構

```
scripts/
├── tools/                     # 核心工具（6 個）⭐
│   ├── generate_database_structure_doc.py  資料庫結構文檔生成器
│   ├── download_complete_database.py       完整資料庫下載
│   ├── export_exercises_supabase.py        動作資料導出
│   ├── generate_training_data_supabase.py  假訓練資料生成
│   ├── reset_workouts_and_templates.py     用戶數據重置
│   └── setup_coaching_relationship.py      教練學員關係設置
│
├── checks/                    # 診斷工具（2 個）
│   ├── check_env.py           環境變數檢查
│   └── check_workout_data.py  訓練資料檢查
│
├── archived/                  # 已歸檔腳本（3 個）
│   ├── test_dart_query_logic.py
│   ├── test_query_coverage.py
│   └── reset_and_generate.bat
│
└── README.md                  # 本文檔
```

**總計**：11 個腳本（6 核心工具 + 2 檢查工具 + 3 歸檔）

---

## 🚀 快速開始

### 1. 環境設置

```bash
# 安裝依賴
pip install supabase-py pandas python-dotenv

# 創建 .env 文件（專案根目錄）
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### 2. 常用命令

```bash
# 📊 生成資料庫結構文檔（推薦）
python scripts/tools/generate_database_structure_doc.py

# 🏋️ 生成假訓練資料
python scripts/tools/generate_training_data_supabase.py <user_uuid>

# 🔄 重置用戶數據並生成新資料
python scripts/tools/reset_workouts_and_templates.py <user_uuid>

# ✅ 檢查環境配置
python scripts/checks/check_env.py
```

---

## 🔧 核心工具 (tools/)

### 1️⃣ generate_database_structure_doc.py ⭐⭐⭐
**功能**：從 Supabase 下載完整資料庫結構並生成文檔

```bash
python scripts/tools/generate_database_structure_doc.py
```

**輸出**：
- `docs/DATABASE_STRUCTURE.md` - 完整資料庫結構文檔
- `database_export/database_schema_<timestamp>.json` - JSON 格式

---

### 2️⃣ download_complete_database.py ⭐⭐
**功能**：下載完整的資料庫數據（14 個表格）

```bash
python scripts/tools/download_complete_database.py
```

**輸出**：
- `database_export/*.json` - 各表格的 JSON 檔案
- `database_export/database_structure.md` - 資料庫結構報告

---

### 3️⃣ reset_workouts_and_templates.py ⭐⭐
**功能**：刪除用戶所有訓練資料並生成專業的假訓練資料

```bash
# 互動式執行
python scripts/tools/reset_workouts_and_templates.py <user_uuid>

# 自動確認模式
python scripts/tools/reset_workouts_and_templates.py <user_uuid> --yes
```

**特色**：
- ✅ 推拉腿分化（Push-Pull-Legs Split）
- ✅ 漸進式超負荷原則（每週 +5% 重量）
- ✅ 使用真實動作 ID
- ✅ 智能休息日安排

---

### 4️⃣ generate_training_data_supabase.py ⭐
**功能**：生成專業的一個月訓練假資料

```bash
python scripts/tools/generate_training_data_supabase.py <user_uuid>
```

---

### 5️⃣ export_exercises_supabase.py ⭐
**功能**：從 Supabase 下載所有動作資料

```bash
python scripts/tools/export_exercises_supabase.py
```

**輸出**：
- `data/exports/exercises_export.json` - JSON 格式
- `data/exports/exercises_export.csv` - CSV 格式
- `data/exports/metadata_export.json` - 元數據

---

### 6️⃣ setup_coaching_relationship.py ⭐
**功能**：建立教練與學員的綁定關係（v2.0 Phase 1）

```bash
python scripts/tools/setup_coaching_relationship.py
```

---

## 🔍 診斷工具 (checks/)

### check_env.py
驗證 `.env` 檔案配置是否正確

```bash
python scripts/checks/check_env.py
```

### check_workout_data.py
檢查用戶的訓練計劃資料

```bash
python scripts/checks/check_workout_data.py
```

---

## 📊 測試用戶 UUID

**開發測試帳號**：

| 角色 | Email | UUID |
|------|-------|------|
| 教練 | charlie19960414@gmail.com | `d1798674-0b96-4c47-a7c7-ee20a5372a03` |
| 學員 | charlie8519960414@gmail.com | `1d7f5ed6-7759-4abc-9832-9db791e75e4f` |

**使用範例**：
```bash
# 生成教練的訓練資料
python scripts/tools/generate_training_data_supabase.py d1798674-0b96-4c47-a7c7-ee20a5372a03

# 重置學員資料
python scripts/tools/reset_workouts_and_templates.py 1d7f5ed6-7759-4abc-9832-9db791e75e4f
```

---

## 🗑️ 清理歷史（2024-12-29）

**已刪除的腳本**（11 個）：

1. **功能重複**（2 個）：
   - ❌ `tools/download_database.py` → 被 `download_complete_database.py` 取代
   - ❌ `data-processing/reset_user_data_and_generate.py` → 被 `reset_workouts_and_templates.py` 取代

2. **一次性數據處理**（5 個）：
   - ❌ `data-processing/rename_exercises_professional.py` - 動作重命名已完成
   - ❌ `data-processing/generate_supabase_update.py` - SQL 更新已完成
   - ❌ `data-processing/export_exercises_latest.py` - 臨時導出工具
   - ❌ `data-processing/read_exercises_csv.py` - CSV 讀取（已改用 JSON）
   - ❌ `data-processing/check_and_fix_training_types.py` - 訓練類型已修復

3. **一次性檢查**（4 個）：
   - ❌ `checks/check_cardio_exercises.py` - 心肺訓練檢查已完成
   - ❌ `checks/check_special_chars.py` - 特殊字符檢查已完成
   - ❌ `checks/check_exercise_types_and_custom.py` - 動作類型檢查已完成
   - ❌ `checks/verify_fixes.py` - 修復驗證已完成

**清理結果**：23 個 → 11 個（-52%）✅

---

## 🚨 安全提醒

1. **保護環境變數**
   - 不要分享 `.env` 文件
   - 不要提交 Service Role Key 到 Git
   - 使用 `.gitignore` 保護敏感資訊

2. **使用前測試**
   - 先在測試環境執行
   - 確認用戶 ID 正確
   - 檢查資料庫權限

3. **資料庫安全**
   - Service Role Key 繞過 RLS 策略
   - 謹慎使用寫入操作
   - 定期備份資料

---

## 💡 常見問題

### Q: 找不到 `.env` 文件
**A**: 請複製 `.env.example` 為 `.env` 並填入正確的 Supabase Keys

### Q: 權限錯誤（403 Forbidden）
**A**: 確認使用 `SUPABASE_SERVICE_ROLE_KEY` 而非 `SUPABASE_KEY`

### Q: 找不到動作資料
**A**: 確認 Supabase 中已有動作資料（794 個系統動作）

---

## 📚 相關文檔

- [Supabase 文檔](https://supabase.com/docs)
- [Supabase Python Client](https://supabase.com/docs/reference/python/introduction)
- 專案資料庫設計：`docs/DATABASE_SUPABASE.md`
- 開發指南：`AGENTS.md`

---

**維護者**：StrengthWise 開發團隊  
**最後更新**：2024年12月29日 - 清理過時腳本，保留核心工具
