# StrengthWise - 資料庫完整匯出報告

**匯出時間**: 2024-12-26 04:06:46  
**目的**: 資料庫效能優化 - 提供給資料庫設計專家分析

---

## 📦 匯出內容清單

### 1. 原始數據檔案（JSON 格式）

| 檔案名稱 | 記錄數 | 大小 | 說明 |
|---------|--------|------|------|
| `users.json` | 1 | ~1 KB | 用戶基本資料 |
| `exercises.json` | 794 | ~400 KB | 健身動作完整資料（⭐核心數據） |
| `equipments.json` | 21 | ~2 KB | 器材列表 |
| `joint_types.json` | 2 | ~0.5 KB | 關節類型 |
| `workout_plans.json` | 24 | ~20 KB | 訓練計劃記錄 |
| `body_data.json` | 4 | ~1 KB | 身體數據記錄 |
| `notes.json` | 0 | ~0.1 KB | 訓練筆記 |
| `favorite_exercises.json` | 0 | ~0.1 KB | 收藏動作（表格不存在）|

**總計**: ~425 KB 原始數據

---

### 2. 專門分析文檔

#### 📄 01_EXERCISES_COMPLETE.md
**健身動作完整資訊**

包含內容：
- ✅ 794 個健身動作完整資料
- ✅ 訓練類型分布統計
- ✅ 身體部位分布統計
- ✅ 器材分布統計
- ✅ 資料表結構完整說明
- ✅ 關聯集合說明（equipments, joint_types, favorite_exercises, workout_plans）
- ✅ 欄位定義（26 個欄位）
- ✅ 命名規則說明
- ✅ 常見查詢模式範例
- ✅ 動作分類階層（Level 1-5）
- ✅ 資料品質評估
- ✅ 資料維護說明

**適合對象**: 資料庫設計師、後端工程師、產品經理

---

#### 📄 02_DATABASE_QUERIES.md
**資料庫查詢完整列表**

包含內容：
- ✅ 所有表格查詢完整列表（~120 個查詢）
- ✅ 按表格分類（8 個主要表格）
- ✅ 按操作類型分類（SELECT, INSERT, UPDATE, DELETE）
- ✅ 每個查詢的：
  - 使用頻率（極高/高/中/低）
  - 預估執行時間
  - 結果大小
  - 完整 SQL 代碼
  - 優化建議（⭐優先級標示）
- ✅ 效能瓶頸識別
- ✅ 索引優化建議（具體 SQL）
- ✅ 預期效能提升（50-90%）

**適合對象**: 資料庫優化專家、DBA、效能工程師

---

#### 📄 database_structure.md
**資料庫結構自動生成文檔**

包含內容：
- ✅ 所有表格的完整結構
- ✅ 欄位類型和範例值
- ✅ 統計資訊
- ✅ 自動化分析結果

---

## 🎯 給資料庫設計專家的重點摘要

### 1. 核心數據表

#### 📊 exercises（健身動作）- ⭐⭐⭐ 最重要
- **記錄數**: 794
- **查詢頻率**: 極高（每次動作選擇都查詢）
- **效能瓶頸**: ⚠️ 全表查詢、模糊搜尋
- **優化優先級**: ⭐⭐⭐ 最高

**關鍵索引需求**:
```sql
-- 1. 系統預設動作索引（user_id IS NULL）
CREATE INDEX idx_exercises_user_id_null 
ON exercises (user_id) WHERE user_id IS NULL;

-- 2. 身體部位篩選索引
CREATE INDEX idx_exercises_body_part 
ON exercises (body_part) WHERE user_id IS NULL;

-- 3. 器材篩選索引
CREATE INDEX idx_exercises_equipment 
ON exercises (equipment) WHERE user_id IS NULL;

-- 4. 複合篩選索引
CREATE INDEX idx_exercises_filters 
ON exercises (body_part, equipment, training_type) WHERE user_id IS NULL;

-- 5. 全文搜尋索引（中文）
CREATE INDEX idx_exercises_name_gin 
ON exercises USING gin(to_tsvector('chinese', name));
```

#### 🏋️ workout_plans（訓練計劃）- ⭐⭐⭐ 核心業務
- **記錄數**: 24（測試數據，實際會有數千筆）
- **查詢頻率**: 極高（首頁、統計、預約）
- **效能瓶頸**: ⚠️ JSONB 欄位查詢（exercises）
- **優化優先級**: ⭐⭐⭐ 最高

**關鍵索引需求**:
```sql
-- 1. 用戶未完成計劃
CREATE INDEX idx_workout_plans_user_pending 
ON workout_plans (trainee_id, completed, scheduled_date);

-- 2. 今日訓練（最常查）
CREATE INDEX idx_workout_plans_today 
ON workout_plans (trainee_id, completed, scheduled_date) 
WHERE completed = false;

-- 3. 已完成訓練（統計用）
CREATE INDEX idx_workout_plans_completed 
ON workout_plans (trainee_id, completed, completed_date) 
WHERE completed = true;

-- 4. JSONB 欄位索引（動作記錄）
CREATE INDEX idx_workout_plans_exercises 
ON workout_plans USING gin(exercises);
```

**JSONB 結構說明**:
```json
{
  "exercises": [
    {
      "exercise_id": "...",
      "exercise_name": "...",
      "sets": 4,
      "reps": 10,
      "weight": 60,
      "completed_sets": [...]
    }
  ]
}
```

---

### 2. 支援數據表

#### 👤 users（用戶）- ⭐⭐ 重要
- **記錄數**: 1（測試，實際會有數千）
- **查詢頻率**: 高（每頁都查）
- **優化需求**: 客戶端快取
- **已有索引**: 主鍵（id）

#### 📊 body_data（身體數據）- ⭐⭐ 重要
- **記錄數**: 4（測試）
- **查詢頻率**: 中（個人資料、統計頁面）
- **優化需求**: 複合索引

**索引需求**:
```sql
CREATE INDEX idx_body_data_user_date 
ON body_data (user_id, record_date DESC);
```

---

### 3. 輔助數據表

#### 🛠️ equipments（器材）- ⭐ 優化度低
- **記錄數**: 21（靜態數據）
- **優化方案**: 客戶端快取

#### 🔗 joint_types（關節類型）- ⭐ 優化度低
- **記錄數**: 2（靜態數據）
- **優化方案**: 客戶端快取或硬編碼

#### 📝 notes（筆記）- ⭐ 優化度低
- **記錄數**: 0（新功能）
- **查詢頻率**: 低

---

## 🚀 效能優化建議（優先級排序）

### Phase 1: 立即執行（⭐⭐⭐ 影響最大）

**預期提升**: 整體查詢效能提升 50-70%

1. **exercises 表索引** ✅ 必須
   - 5 個索引（見上述 SQL）
   - 預計提升: 60-80%
   - 影響: 動作選擇、搜尋、篩選

2. **workout_plans 表索引** ✅ 必須
   - 4 個索引（見上述 SQL）
   - 預計提升: 50-70%
   - 影響: 首頁載入、統計頁面

3. **body_data 表索引** ✅ 必須
   - 1 個索引（見上述 SQL）
   - 預計提升: 40-60%
   - 影響: 身體數據頁面

---

### Phase 2: 進階優化（⭐⭐ 效能提升）

**預期提升**: 特定功能效能提升 60-90%

1. **全文搜尋優化**
   - 使用 PostgreSQL FTS
   - 支援中文分詞
   - 預計提升: 70-90%

2. **統計查詢優化**
   - 建立彙總表（daily_workout_summary）
   - 使用觸發器自動更新
   - 預計提升: 60-80%

3. **JSONB 查詢優化**
   - workout_plans.exercises 欄位索引
   - 使用資料庫函式封裝複雜查詢
   - 預計提升: 50-70%

---

### Phase 3: 長期優化（⭐ 架構改進）

1. **客戶端快取策略**
   - exercises 表（首次載入後快取）
   - equipments、joint_types（靜態數據）
   - users（當前用戶資料）

2. **分頁載入**
   - exercises 表（無限滾動）
   - workout_plans 歷史記錄（分頁）

3. **查詢優化**
   - 減少重複查詢
   - 合併相似查詢
   - 使用 View 封裝

---

## 📊 預期效能提升總表

| 優化階段 | 預期提升 | 實作時間 | 影響範圍 |
|---------|---------|---------|---------|
| Phase 1 索引優化 | 50-70% | 1-2 小時 | 全應用 |
| Phase 2 進階優化 | 60-90% | 3-5 天 | 特定功能 |
| Phase 3 架構改進 | 80-95% | 1-2 週 | 長期維護 |

---

## 🔧 建議的資料庫調校參數

### PostgreSQL 配置優化
```conf
# 增加共享緩衝區（適合小型專案）
shared_buffers = 256MB

# 增加工作記憶體
work_mem = 16MB

# 增加維護工作記憶體
maintenance_work_mem = 64MB

# 有效快取大小
effective_cache_size = 1GB

# 隨機頁面成本
random_page_cost = 1.1  # SSD 適用

# 啟用 JIT 編譯
jit = on
```

---

## 📝 測試數據說明

**⚠️ 注意**: 當前數據為測試環境
- users: 1 筆（實際會有數千筆）
- workout_plans: 24 筆（實際會有數萬筆）
- body_data: 4 筆（實際每用戶 10-100 筆）

**建議**: 在正式環境優化前，先使用生產數據規模進行效能測試

---

## 📂 檔案結構

```
database_export/
├── 01_EXERCISES_COMPLETE.md      # 健身動作完整資訊（⭐核心文檔）
├── 02_DATABASE_QUERIES.md        # 查詢完整列表（⭐優化文檔）
├── database_structure.md         # 自動生成結構文檔
├── users.json                    # 用戶數據
├── exercises.json                # 動作數據（794 筆）
├── equipments.json               # 器材數據（21 筆）
├── joint_types.json              # 關節類型（2 筆）
├── workout_plans.json            # 訓練計劃（24 筆）
├── body_data.json                # 身體數據（4 筆）
├── notes.json                    # 筆記數據（0 筆）
└── favorite_exercises.json       # 收藏動作（0 筆）
```

---

## 🎯 下一步建議

### 給資料庫設計專家：

1. **立即行動** (1-2 小時)
   - [ ] 審閱 `02_DATABASE_QUERIES.md`
   - [ ] 執行 Phase 1 索引 SQL
   - [ ] 驗證索引效果（EXPLAIN ANALYZE）

2. **深入分析** (1-2 天)
   - [ ] 審閱 `01_EXERCISES_COMPLETE.md`
   - [ ] 分析 JSONB 欄位使用模式
   - [ ] 設計統計彙總表結構
   - [ ] 評估分片策略（未來擴展）

3. **長期規劃** (1-2 週)
   - [ ] 建立監控指標（查詢時間、慢查詢日誌）
   - [ ] 設計快取策略（Redis）
   - [ ] 評估讀寫分離需求
   - [ ] 規劃資料歸檔策略

---

## 📞 聯繫資訊

**專案**: StrengthWise  
**資料庫**: Supabase PostgreSQL  
**URL**: https://fihkhoogvkccgpbgjhpw.supabase.co  

**文檔維護**: StrengthWise 開發團隊  
**更新日期**: 2024-12-26

---

**🎉 匯出完成！所有資料和分析文檔已準備就緒！**

