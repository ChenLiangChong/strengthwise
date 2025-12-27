# Scripts - 工具腳本（Supabase 版本）

> StrengthWise 專案的 Python 工具腳本

**最後更新**：2024年12月26日

---

## 📁 可用腳本

### 1. `export_exercises_supabase.py` - 動作資料導出 ⭐

**功能**：從 Supabase 下載所有動作資料

**使用方式**：
```bash
python scripts/export_exercises_supabase.py
```

**輸出**：
- `data/exports/exercises_export.json` - 完整 JSON 格式
- `data/exports/exercises_export.csv` - CSV 格式（適合 Excel）
- `data/exports/metadata_export.json` - 元數據

**功能特色**：
- ✅ 下載所有系統動作（794 個）
- ✅ 下載元數據（body_parts, exercise_types, equipments, joint_types）
- ✅ 統計分析（訓練類型、身體部位、器材分布）
- ✅ 多格式導出（JSON + CSV）

**需求**：
- Python 3.x
- supabase-py
- pandas
- python-dotenv
- 需要配置 `.env` 文件（SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY）

---

### 2. `generate_training_data_supabase.py` - 假訓練資料生成 ⭐

**功能**：生成專業的一個月訓練假資料

**使用方式**：
```bash
# 方式 1：命令列指定用戶 ID
python scripts/generate_training_data_supabase.py <user_uuid>

# 方式 2：互動式輸入
python scripts/generate_training_data_supabase.py
```

**範例**：
```bash
python scripts/generate_training_data_supabase.py 550e8400-e29b-41d4-a716-446655440000
```

**功能特色**：
- ✅ 推拉腿分化（Push-Pull-Legs Split）
- ✅ 漸進式超負荷原則（每週增加 5% 重量）
- ✅ 使用真實動作 ID（從 Supabase 查詢）
- ✅ 符合 WorkoutRecord 模型結構
- ✅ 智能休息日安排（週日休息 + 隨機休息）
- ✅ 自動計算統計數據（總量、總組數、訓練時長）

**訓練類型**：
- **Push Day（推日）**：胸、肩、三頭肌
- **Pull Day（拉日）**：背、二頭肌
- **Leg Day（腿日）**：股四頭肌、臀部

**需求**：
- Python 3.x
- supabase-py
- python-dotenv
- 需要配置 `.env` 文件
- 需要有效的用戶 UUID

---

### 3. `read_exercises_csv.py` - CSV 動作資料讀取

**功能**：從 CSV 讀取動作數據並查找常見動作

**使用方式**：
```bash
python scripts/read_exercises_csv.py
```

**需求**：
- Python 3.x
- pandas
- 需要 `exercises_reclassified.csv` 文件

**用途**：
- 快速查找特定動作
- 分析動作分類
- 測試和驗證

---

### 4. `reset_workouts_and_templates.py` - 用戶數據重置與假資料生成 ⭐⭐

**功能**：刪除用戶所有訓練資料並生成專業的假訓練資料（推拉腿分化）

**使用方式**：
```bash
# 互動式執行（推薦）
python scripts/reset_workouts_and_templates.py <user_uuid>

# 自動確認模式
python scripts/reset_workouts_and_templates.py <user_uuid> --yes
```

**範例**：
```bash
python scripts/reset_workouts_and_templates.py d1798674-0b96-4c47-a7c7-ee20a5372a03
```

**功能特色**：
- ✅ 清除用戶的 `workout_plans` 和 `workout_templates` 資料
- ✅ 生成專業的推拉腿分化訓練（Push-Pull-Legs Split）
- ✅ 漸進式超負荷原則（每週增加重量）
- ✅ 支援 Phase 3 觸發器（包含 `trainingType`）
- ✅ 使用真實動作 ID（從 Supabase 查詢）
- ✅ 符合 WorkoutRecord 模型結構

**訓練類型**：
- **Push Day（推日）**：胸、肩、三頭肌
- **Pull Day（拉日）**：背、二頭肌
- **Leg Day（腿日）**：股四頭肌、臀部

**需求**：
- Python 3.x
- supabase-py
- python-dotenv
- 需要配置 `.env` 文件
- 需要有效的用戶 UUID

---

## 🔧 環境設置

### 1. 安裝 Python 依賴

創建虛擬環境（可選）：
```bash
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
```

安裝套件：
```bash
pip install supabase-py pandas python-dotenv
```

### 2. 配置 Supabase 環境變數

創建 `.env` 文件（專案根目錄）：
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

**取得 Supabase Keys**：
1. 登入 [Supabase Dashboard](https://app.supabase.com/)
2. 選擇專案
3. Settings → API
4. 複製 `URL` 和 `service_role key`

**⚠️ 注意**：
- `service_role key` 擁有完整權限，**不要提交到 Git**
- `.env` 文件已加入 `.gitignore`

---

## 📊 使用流程

### 導出動作資料
```bash
# 1. 下載所有動作
python scripts/export_exercises_supabase.py

# 2. 查看輸出
cat data/exports/exercises_export.json
```

### 生成假訓練資料
```bash
# 1. 先取得用戶 UUID（從 Supabase Dashboard 或應用）
# 2. 執行生成腳本
python scripts/generate_training_data_supabase.py <user_uuid>

# 3. 在應用中查看訓練記錄
```

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

## 🔄 與舊版 Firestore 腳本的差異

### 已移除的 Firestore 腳本

以下 Firestore 專用腳本已刪除（專案已完全遷移到 Supabase）：

**分析類（19 個）**：
- `analyze_firestore.py`
- `analyze_firestore_from_code.py`
- `analyze_body_parts.py`
- `analyze_exercises.py`
- `count_all_collections.py`
- `export_database_structure.py`
- 等...

**操作類**：
- `import_exercises.py`
- `merge_body_parts.py`
- `delete_user_templates.py`
- `generate_professional_training_data.py` ❌ → `generate_training_data_supabase.py` ✅

**遷移類**：
- `migrate_to_supabase.py` - 遷移已完成
- `migrate_to_supabase_direct.py` - 遷移已完成

### 新增的 Supabase 腳本

1. ✅ `export_exercises_supabase.py` - 全新動作導出工具
2. ✅ `generate_training_data_supabase.py` - 改寫的假資料生成器
3. ✅ `read_exercises_csv.py` - 保留（通用工具）

---

## 📚 相關文檔

- [Supabase 文檔](https://supabase.com/docs)
- [Supabase Python Client](https://supabase.com/docs/reference/python/introduction)
- 專案資料庫設計：`docs/DATABASE_SUPABASE.md`
- 開發指南：`AGENTS.md`

---

## 💡 常見問題

### Q: 找不到 `.env` 文件
**A**: 請複製 `.env.example` 為 `.env` 並填入正確的 Supabase Keys

### Q: 權限錯誤（403 Forbidden）
**A**: 確認使用 `SUPABASE_SERVICE_ROLE_KEY` 而非 `SUPABASE_KEY`

### Q: 找不到動作資料
**A**: 確認 Supabase 中已有動作資料（794 個系統動作）

### Q: 生成假資料後看不到記錄
**A**: 檢查用戶 UUID 是否正確，確認 RLS 策略已正確配置

---

**維護者**：StrengthWise 開發團隊  
**最後更新**：2024年12月26日 - Supabase 遷移完成
