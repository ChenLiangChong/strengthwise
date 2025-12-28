# StrengthWise 雙端 SaaS 平台開發路線圖

> 從單機應用至教練-學員雙端 SaaS 平台的完整轉型計劃

**最後更新**：2024年12月28日  
**當前狀態**：✅ Phase 2 完成（100%）  
**v2.0 版本**：Phase 1 完成 ✅ | Phase 2 完成 ✅

---

## 📑 快速導航

- [1. 轉型概述](#1-轉型概述)
- [2. 核心架構設計](#2-核心架構設計)
- [3. 實施路線圖](#3-實施路線圖)
- [4. 技術規範](#4-技術規範)
- [5. 數據遷移計劃](#5-數據遷移計劃)

---

## 1. 轉型概述

### 1.1 專案背景與目標

**當前狀態**（v1.0 單機版）：
- ✅ 個人健身記錄應用
- ✅ 本地數據存儲
- ✅ 單用戶模式
- ✅ 完整的訓練管理功能

**轉型目標**（v2.0 雙端 SaaS）：
- 🎯 連接教練與學員的雲端平台
- 🎯 實時數據同步
- 🎯 嚴格權限控制（RLS）
- 🎯 高並發數據分析
- 🎯 多對多關係管理

### 1.2 設計哲學

**資料庫優先（Database-First）**：
1. **安全性內建於數據層**
   - Row Level Security (RLS) 確保數據隔離
   - 即使繞過前端，也無法存取未授權數據

2. **數據一致性的硬性保障**
   - PostgreSQL Exclusion Constraints 防止重疊預約
   - 物理層面杜絕並發衝突

3. **分析性能優化**
   - Materialized Views 預先計算統計指標
   - 儀表板毫秒級加載

---

## 2. 核心架構設計

### 2.1 身份認證與角色權限 (RBAC)

#### 角色定義

```sql
CREATE TYPE public.app_role AS ENUM ('admin', 'coach', 'client');
```

#### Profiles 表結構

| 欄位名稱 | 資料類型 | 約束條件 | 用途 |
|---------|---------|---------|------|
| `id` | uuid | PRIMARY KEY, REFERENCES auth.users(id) | 與 Supabase Auth 綁定 |
| `role` | app_role | NOT NULL, DEFAULT 'client' | 角色控制 |
| `email` | text | UNIQUE, NOT NULL | 邀請系統查詢 |
| `full_name` | text | | UI 顯示 |
| `avatar_url` | text | | Supabase Storage 路徑 |
| `onboarding_status` | text | DEFAULT 'pending' | 初始設定狀態 |
| `preferences` | jsonb | DEFAULT '{}' | 用戶偏好設定 |

#### 自動化同步機制

**Trigger 函式**：當用戶通過 Supabase Auth 註冊時，自動創建 profile 記錄

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role, avatar_url)
  VALUES (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    COALESCE((new.raw_user_meta_data->>'role')::public.app_role, 'client'),
    new.raw_user_meta_data->>'avatar_url'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### RLS 策略範例

```sql
-- 用戶可查看自己的資料
CREATE POLICY "Users can view own profile"
ON public.profiles FOR SELECT
USING (auth.uid() = id);

-- 教練查看活躍學員的資料
CREATE POLICY "Coaches view active clients profiles"
ON public.profiles FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.coaching_relationships cr
    WHERE cr.coach_id = auth.uid()
    AND cr.client_id = public.profiles.id
    AND cr.status = 'active'
  )
);
```

---

### 2.2 教練-學員綁定機制

#### coaching_relationships 表結構

| 欄位名稱 | 資料類型 | 約束條件 | 用途 |
|---------|---------|---------|------|
| `id` | uuid | PRIMARY KEY | 關係唯一標識符 |
| `coach_id` | uuid | REFERENCES profiles(id) | 教練 ID |
| `client_id` | uuid | REFERENCES profiles(id) | 學員 ID |
| `status` | text | CHECK IN ('pending', 'active', 'archived', 'rejected') | 狀態機控制 |
| `notes` | text | | 教練內部備註 |
| `created_at` | timestamptz | DEFAULT now() | 建立時間 |
| `updated_at` | timestamptz | DEFAULT now() | 更新時間 |

**複合唯一約束**：`UNIQUE(coach_id, client_id)` 防止重複綁定

#### 安全邀請流程（Edge Functions）

**流程設計**：
1. 教練在 App 輸入學員 Email
2. App 調用 Edge Function `invite-client`
3. Edge Function 驗證教練角色
4. 使用 `supabaseAdmin.auth.inviteUserByEmail` 發送邀請
5. 在 metadata 中寫入 `{ "invited_by": "coach_uuid" }`
6. 學員註冊時，Trigger 自動建立 `coaching_relationships` 記錄

**特點**：無縫綁定，學員登入即刻看到教練

---

### 2.3 雙向時間預約系統

#### 核心技術：tstzrange + GiST 索引

**挑戰**：防止同一教練同一時段被重複預約（Race Conditions）

**解決方案**：PostgreSQL 原生 Range Types + Exclusion Constraints

#### availability_slots 表（教練可用時段）

| 欄位名稱 | 資料類型 | 描述 |
|---------|---------|------|
| `id` | uuid | Primary Key |
| `coach_id` | uuid | 關聯教練 |
| `time_range` | tstzrange | 時間範圍（原生類型） |
| `recurrence_rule` | text | iCal RRULE（週期性設定） |
| `is_override` | boolean | 是否為特殊覆蓋（休假） |

#### appointments 表（預約記錄）

| 欄位名稱 | 資料類型 | 約束條件 | 描述 |
|---------|---------|---------|------|
| `id` | uuid | PRIMARY KEY | |
| `coach_id` | uuid | REFERENCES profiles | |
| `client_id` | uuid | REFERENCES profiles | |
| `time_range` | tstzrange | NOT NULL | 預約時段 |
| `status` | text | CHECK IN (...) | 'requested', 'confirmed', 'completed', 'cancelled' |
| `notes` | text | | 備註 |

#### 排除約束（防止雙重預約）

```sql
-- 安裝擴展
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- 添加排除約束
ALTER TABLE public.appointments
ADD CONSTRAINT no_coach_overlap
EXCLUDE USING GIST (
  coach_id WITH =,              -- 同一教練
  time_range WITH &&            -- 時間範圍不可重疊
) WHERE (status != 'cancelled');
```

**技術洞察**：
- 物理層面禁止重疊預約
- 高並發下第一個事務成功，第二個拋出 SQL 錯誤
- Flutter 捕獲錯誤並提示「該時段已被預約」
- 無需複雜的後端鎖定機制

---

### 2.4 課表安排與訓練編排

#### 基於屬性的動態動作庫架構 ⭐⭐⭐

**設計哲學**：從靜態實體到動態屬性的典範轉移

傳統的預設動作庫（794 個系統動作）在實際使用中極少被使用，因為：
- ❌ 教練訓練哲學各異，對動作命名有細微差別
- ❌ 靜態欄位無法描述複合動作的多重屬性
- ❌ 無法滿足「身體部位 PR」的統計需求

**新架構**：屬性驅動的動作系統
- ✅ 動作不再是嚴格定義的實體，而是由多個屬性標籤組成的容器
- ✅ 支援「身體部位 PR」統計（跨動作聚合）
- ✅ 支援「單一動作進步」追蹤
- ✅ 教練可通過屬性組合快速篩選動作

#### 核心表結構設計

**1. attribute_categories（屬性分類）**

| 欄位名稱 | 資料類型 | 約束條件 | 用途 |
|---------|---------|---------|------|
| `id` | uuid | PRIMARY KEY | 唯一標識符 |
| `slug` | text | UNIQUE, NOT NULL | 系統識別字串（muscle_group, equipment, movement_pattern） |
| `display_name` | text | NOT NULL | 顯示名稱（「目標肌群」、「器材類型」） |
| `is_system` | boolean | DEFAULT TRUE | 系統核心類別不可刪除 |
| `cardinality` | enum | single_select / multi_select | 該類別下標籤是否互斥 |
| `sort_order` | int | DEFAULT 0 | UI 顯示順序 |

**2. attributes（屬性標籤）**

| 欄位名稱 | 資料類型 | 約束條件 | 用途 |
|---------|---------|---------|------|
| `id` | uuid | PRIMARY KEY | 唯一標識符 |
| `category_id` | uuid | FK (attribute_categories) | 所屬類別 |
| `name` | text | NOT NULL | 標籤名稱（胸部、槓鈴、推） |
| `created_by` | uuid | NULLABLE FK (users) | **關鍵**：NULL = 系統標籤，有值 = 教練私有標籤 |
| `is_archived` | boolean | DEFAULT FALSE | 軟刪除機制 |

**3. exercises（動作主表）**

| 欄位名稱 | 資料類型 | 約束條件 | 用途 |
|---------|---------|---------|------|
| `id` | uuid | PRIMARY KEY | 唯一標識符 |
| `user_id` | uuid | NULLABLE FK (users) | NULL = 系統動作，有值 = 教練自定義 |
| `name` | text | NOT NULL | 動作名稱 |
| `description` | text | | 動作說明 |
| `video_url` | text | | 示範影片 |
| `default_metric` | enum | weight_reps / time / distance | 預設記錄方式 |
| `is_placeholder` | boolean | DEFAULT FALSE | 是否為佔位符動作 |

**4. exercise_attributes（動作-屬性關聯）**

```sql
CREATE TABLE exercise_attributes (
  exercise_id UUID REFERENCES exercises(id) ON DELETE CASCADE,
  attribute_id UUID REFERENCES attributes(id) ON DELETE CASCADE,
  PRIMARY KEY (exercise_id, attribute_id)
);

-- 正向查詢索引（查詢動作的所有標籤）
CREATE INDEX idx_ea_exercise ON exercise_attributes(exercise_id);

-- 反向查詢索引（查詢所有「胸部」動作）⭐ 核心優化
CREATE INDEX idx_ea_attribute ON exercise_attributes(attribute_id, exercise_id);
```

**為何不使用 JSONB？**
- ✅ 關聯表在 JOIN 和 GROUP BY 操作時效能更佳（百萬級數據）
- ✅ 外鍵約束確保數據完整性
- ✅ 針對統計查詢可建立覆蓋索引

#### 教練排課工作流優化

**屬性交集篩選**：教練選擇「背部 + 機械 + 單邊」→ 秒速篩選動作

```sql
-- 優化的交集查詢
SELECT e.id, e.name
FROM exercises e
WHERE EXISTS (
  SELECT 1 FROM exercise_attributes ea
  WHERE ea.exercise_id = e.id AND ea.attribute_id = 'UUID-BACK'
)
AND EXISTS (
  SELECT 1 FROM exercise_attributes ea
  WHERE ea.exercise_id = e.id AND ea.attribute_id = 'UUID-MACHINE'
);
```

**佔位符動作（Placeholder Exercises）**：
- 教練可安排抽象動作（如「水平推」）
- 學員執行時根據健身房設備自行替換（啞鈴臥推 / 器械推胸）
- 系統記錄實際執行動作，但保留原始模板意圖

**課表結構**：JSONB + 正規化混合

1. **訓練模板（Templates）**：使用 JSONB 存儲結構
   - 獲得最大靈活性
   - 支援複雜訓練邏輯（超級組、Tempo、RPE）

2. **執行記錄（Logs）**：使用正規化表格存儲
   - 便於 SQL 聚合運算（SUM, AVG）
   - 支援高效數據分析

#### workout_templates 表

| 欄位名稱 | 資料類型 | 描述 |
|---------|---------|------|
| `id` | uuid | Primary Key |
| `coach_id` | uuid | 創建者 |
| `name` | text | 模板名稱 |
| `structure` | jsonb | 詳細訓練結構（動作、組數、強度） |
| `tags` | text[] | 標籤（如：力量、增肌） |

#### assigned_workouts 表（已指派課表）

| 欄位名稱 | 資料類型 | 描述 |
|---------|---------|------|
| `id` | uuid | Primary Key |
| `client_id` | uuid | 接收學員 |
| `coach_id` | uuid | 開立教練 |
| `scheduled_date` | date | 預計執行日期 |
| `template_snapshot` | jsonb | **關鍵**：指派時的模板快照 |
| `status` | text | 'assigned', 'in_progress', 'completed', 'missed' |
| `feedback` | text | 學員反饋 |

**設計重點**：`template_snapshot` 保存指派時的完整結構，避免原模板修改影響歷史記錄

#### workout_sets 表（數據分析核心）⚡⚡⚡

| 欄位名稱 | 資料類型 | 描述 |
|---------|---------|------|
| `id` | uuid | Primary Key |
| `workout_log_id` | uuid | 關聯日誌 |
| `exercise_id` | uuid | 關聯動作 |
| `set_number` | int | 第幾組 |
| `weight_kg` | numeric | **關鍵分析指標** |
| `reps` | int | **關鍵分析指標** |
| `rpe` | numeric | 自覺受力係數 |
| `is_warmup` | boolean | **關鍵**：熱身組需從 PR 統計中排除 |
| `is_pr` | boolean | 是否破紀錄 |
| `estimated_1rm` | numeric | **生成欄位**：自動計算 Epley 公式 |

**estimated_1rm 生成欄位**（關鍵創新）⭐

```sql
ALTER TABLE workout_sets
ADD COLUMN estimated_1rm NUMERIC
GENERATED ALWAYS AS (
  CASE WHEN reps > 0 THEN weight_kg * (1 + reps::numeric / 30.0) ELSE 0 END
) STORED;
```

**技術優勢**：
- ✅ 寫入時自動計算，讀取時零成本
- ✅ 標準化強度指標（100kg x 5 vs 110kg x 3 可直接對比）
- ✅ 支援「單一動作進步」追蹤
- ✅ 獨立建表支援高效 SQL 聚合
- ✅ 計算訓練量：`SUM(weight_kg * reps)`

---

### 2.5 數據儀表板與高效能分析

#### 關鍵指標定義

1. **合規率（Compliance Rate）**
   - 公式：`(已完成課表數 / 總指派課表數) * 100`
   - 用途：監控學員訓練紀律

2. **訓練總量（Volume Load）**
   - 公式：`SUM(weight * reps)`
   - 用途：肌群訓練量追蹤

3. **最大肌力估算（e1RM）**
   - 公式：`weight * (1 + reps / 30)`（Epley 公式）
   - 用途：力量進步追蹤

4. **身體部位 PR（Body Part PR）**⭐ 新增
   - 定義：特定身體部位在單次訓練的最大訓練總量
   - 公式：`MAX(SUM(weight * reps) GROUP BY session, attribute)`
   - 用途：跨動作的肌群進步追蹤

5. **單一動作進步（Single Exercise Progress）**⭐ 新增
   - 指標：最大重量、最佳 e1RM、最大單次訓練量
   - 用途：特定動作（如深蹲）的進步追蹤

#### 高效能統計引擎設計 ⚡⚡⚡

**挑戰**：「身體部位 PR」需跨多個動作、多個訓練課表進行聚合，即時查詢會嚴重卡頓

**解決方案**：寫入時聚合（Write-Time Aggregation）+ 物化統計表

**1. user_attribute_stats（身體部位統計）**

```sql
CREATE TABLE user_attribute_stats (
  user_id UUID NOT NULL REFERENCES users(id),
  attribute_id UUID NOT NULL REFERENCES attributes(id), -- 對應「胸部」、「腿部」等標籤
  total_lifetime_volume BIGINT DEFAULT 0, -- 生涯累積訓練量
  max_session_volume BIGINT DEFAULT 0, -- 身體部位 PR（單次訓練最大量）
  max_session_date TIMESTAMPTZ, -- PR 創建日期
  last_updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, attribute_id)
);

-- 索引優化
CREATE INDEX idx_user_attr_stats_user ON user_attribute_stats(user_id);
CREATE INDEX idx_user_attr_stats_attr ON user_attribute_stats(attribute_id);
```

**觸發器邏輯**（事件驅動）：
1. 當訓練記錄狀態變更為 `completed` 時觸發
2. 選取該次訓練所有非熱身組（`is_warmup = FALSE`）
3. 透過 `exercise_attributes` 展開所有涉及的身體部位標籤
4. 針對每個標籤計算本次訓練總量（`SUM(weight * reps)`）
5. 更新 `total_lifetime_volume`
6. 若本次總量 > `max_session_volume`，則更新 PR 值與日期

**效能優勢**：
- ✅ 讀取時 O(1) 查詢（直接讀取統計表）
- ✅ 儀表板秒開（<5ms）
- ✅ 複雜聚合操作在「寫入」階段完成（用戶可接受）

**2. user_exercise_stats（單一動作統計）**

```sql
CREATE TABLE user_exercise_stats (
  user_id UUID NOT NULL REFERENCES users(id),
  exercise_id UUID NOT NULL REFERENCES exercises(id),
  personal_record_weight NUMERIC, -- 最大實際舉起重量
  personal_record_e1rm NUMERIC, -- 最佳估算 1RM（理論極限）
  max_volume_single_session NUMERIC, -- 該動作的單次最大訓練量
  last_performed_at TIMESTAMPTZ, -- 上次訓練時間
  PRIMARY KEY (user_id, exercise_id)
);

-- 索引優化
CREATE INDEX idx_user_ex_stats_user ON user_exercise_stats(user_id);
CREATE INDEX idx_user_ex_stats_recent ON user_exercise_stats(last_performed_at DESC);
```

**用途**：
- 教練查看學員列表時直接顯示「深蹲 1RM: 150kg」
- 學員查看自訂動作統計卡片（如您當前實作）
- 無需遍歷歷史日誌

#### Materialized Views（物化視圖）

**問題**：教練打開儀表板，查詢 50 位學員過去 30 天數據 → 數萬行掃描 → App 卡頓

**解決方案**：物化視圖將查詢結果「快取」為實體表

```sql
CREATE MATERIALIZED VIEW public.mv_client_compliance AS
SELECT
  client_id,
  coach_id,
  COUNT(*) FILTER (WHERE status = 'completed') AS completed_count,
  COUNT(*) AS total_assigned,
  CASE
    WHEN COUNT(*) = 0 THEN 0
    ELSE ROUND((COUNT(*) FILTER (WHERE status = 'completed')::numeric / COUNT(*)) * 100, 2)
  END AS compliance_rate_30d,
  MAX(scheduled_date) FILTER (WHERE status = 'completed') AS last_workout_date
FROM public.assigned_workouts
WHERE scheduled_date > (now() - interval '30 days')
GROUP BY client_id, coach_id;

-- 建立索引加速查詢
CREATE INDEX idx_mv_compliance_coach ON public.mv_client_compliance(coach_id);
```

#### 數據更新策略

**方案 1：定時更新**（推薦）
- 使用 `pg_cron` 擴展
- 每小時執行：`REFRESH MATERIALIZED VIEW CONCURRENTLY`
- 數據延遲 5-10 分鐘可接受

**方案 2：觸發更新**
- 數據變更時觸發 Edge Function
- 適合高實時性需求
- 需注意並發性能

#### 風險預警系統

**風險學員識別**：
- 條件：`compliance_rate_30d < 50 OR last_workout_date < (now() - interval '7 days')`
- UI：教練列表標紅置頂
- 用途：主動關懷，提升留存率

---

### 2.6 筆記功能：SOAP 架構與隱私控制

#### SOAP 格式（醫療與教練領域標準）

- **S (Subjective)**：主觀描述（學員說很累）
- **O (Objective)**：客觀數據（深蹲時膝蓋內夾）
- **A (Assessment)**：評估（可能臀中肌無力）
- **P (Plan)**：計畫（增加彈力帶訓練）

#### session_notes 表結構

| 欄位名稱 | 資料類型 | 描述 |
|---------|---------|------|
| `id` | uuid | Primary Key |
| `client_id` | uuid | 筆記對象 |
| `author_id` | uuid | 撰寫者（教練） |
| `content` | jsonb | 存儲 SOAP 結構 |
| `visibility` | text | **關鍵**：'private' / 'shared' |
| `created_at` | timestamptz | 建立時間 |

#### 隱私控制 RLS

```sql
-- 學員只能看被分享的筆記
CREATE POLICY "Clients view shared notes"
ON public.session_notes FOR SELECT
USING (
  client_id = auth.uid() AND visibility = 'shared'
);

-- 教練看自己撰寫的所有筆記
CREATE POLICY "Coaches view all authored notes"
ON public.session_notes FOR SELECT
USING (
  author_id = auth.uid()
);
```

**安全保障**：學員永遠無法看到 `visibility = 'private'` 的內部評估

---

## 3. 實施路線圖

### Phase 1：基礎設施與身份認證（2-3 週）

**目標**：教練可登入、邀請學員，學員自動綁定

**狀態**：✅ 已完成（2024-12-28）

**任務清單**：
- [x] 建立 Supabase 專案（生產環境）
- [x] 實作 `profiles` 表與角色枚舉
- [x] 開發 `handle_new_user` Trigger
- [x] 實作 `coaching_relationships` 表
- [x] RLS 策略：profiles 跨角色查詢
- [x] Flutter UI：邀請介面 + 學員列表（6 個組件）
- [x] Model: CoachingRelationshipModel
- [x] Service: CoachingRelationshipService（3 子模組）
- [x] Controller: CoachingRelationshipController

**驗收標準**：
- ✅ 教練輸入 UUID → 學員自動出現在教練的學員列表
- ✅ 測試數據隔離：教練 A 無法看到教練 B 的學員
- ✅ 雙設備測試通過（VM + 手機）

---

### Phase 2：核心訓練業務（3-4 週）

**目標**：完成預約系統（教練設定時段 + 學員預約）

**當前狀態**：✅ 已完成（100%）

**任務清單**：

**A. 預約系統（教練設定時段 + 學員預約）** ⭐⭐⭐
- [x] 創建 `availability_slots` 表（教練可用時段）
- [x] 創建 `appointments` 表（預約記錄）
- [x] 實作 TSTZRANGE 時間範圍類型
- [x] 實作 GiST 排除約束（物理層防止雙重預約）
- [x] RLS 策略（10 個）：預約可見性與操作權限
- [x] Model 層：AppointmentModel + AvailabilitySlotModel
- [x] Service Interface：IAppointmentService + IAvailabilitySlotService
- [x] Service 實現：AppointmentServiceSupabase + AvailabilitySlotServiceSupabase
- [x] Service Locator 註冊
- [x] 後端功能測試（8/8 通過）⭐
  - 創建時段 ✅
  - 創建預約 ✅
  - 雙重預約防護 ✅（核心功能驗證）
  - 確認預約 ✅
  - RLS 策略 ✅
  - 可用時段查詢 ✅
  - 取消預約 ✅
  - 清理數據 ✅
- [x] Controller 層（完全解耦 + 子模組化）
  - AppointmentController（308 行）+ 4 個子模組
  - AvailabilitySlotController（324 行）+ 4 個子模組
- [x] UI 層 - 教練時段管理頁面（343 行 + 8 組件）✅
- [x] UI 層 - 學員預約頁面（完成）✅
- [x] UI 層 - 預約列表頁面（完成）✅
- [x] UI 層 - 預約詳情頁面（完成）✅
- [x] UI 層 - 教練管理中心（3 個 Tab）✅
- [x] UI 層 - 學員預約中心（2 個 Tab）✅
- [x] 功能測試（12/12 通過）⭐
  - 教練創建時段 ✅
  - 學員查看時段 ✅
  - 學員預約 ✅
  - 教練確認/拒絕 ✅
  - 學員取消 ✅
  - 教練取消 ✅
  - 預約列表 ✅
  - 預約詳情 ✅
  - 下拉刷新 ✅
  - 狀態篩選 ✅
  - 雙角色支援 ✅

**技術特色**：
- ✅ PostgreSQL TSTZRANGE（時間範圍類型）
- ✅ GiST 排除約束（物理層防止雙重預約）⭐ 驗證通過
- ✅ Row Level Security（10 個策略運作正常）
- ✅ iCal RRULE（週期性規則支援）
- ✅ PostgreSQL 時間戳正確解析 ⭐
- ✅ 雙角色支援（教練/學員同時可見）
- ✅ UI 組件化設計（平均 ~60 行/組件）

**驗收標準**：
- ✅ 後端測試：雙重預約物理層阻擋成功
- ✅ 後端測試：RLS 策略保護資料安全
- ✅ 後端測試：狀態機完整運作
- ✅ 教練可設定可用時段（單次/週期性）
- ✅ 學員可查看教練可用時段並預約
- ✅ 預約狀態流轉（requested → confirmed → completed）
- ✅ 並發預約測試（GiST 排除約束驗證）

**新增檔案**：35 個（完全解耦合設計）
- Model: 2
- Service: 4
- Controller: 10（2 主 + 8 子模組）
- UI: 28（8 頁面 + 20 組件）
- Migration: 1

**今天修復的問題**（12 個）：
1. ✅ UI 渲染錯誤（BoxConstraints）
2. ✅ 依賴注入錯誤（IAuthController）
3. ✅ 教練名稱顯示
4. ✅ 時間格式解析 ⭐
5. ✅ 查詢邏輯（範圍重疊運算子）
6. ✅ 空 UUID 問題
7. ✅ null 轉換錯誤
8. ✅ 日曆時段顯示
9. ✅ 教練取消預約功能
10. ✅ 取消原因顯示
11. ✅ 預約詳情頁面路由
12. ✅ TabController 狀態重置

**Phase 2 完成時間**：1 天（2024-12-28）✅

---

### Phase 3：雙向時間管理與筆記（3-4 週）

**目標**：完成雙向時間管理與教練記錄功能

#### A. 學員時間偏好系統（新增功能）⭐

**需求**：學員設定可運動時間 → 教練主動安排訓練

**任務清單**：
- [ ] 設計 `client_availability` 表（學員可用時間）
  - 時間範圍（TSTZRANGE）
  - 週期性規則（iCal RRULE）
  - 優先級標記（preferred / available）
- [ ] RLS 策略：教練可查看活躍學員的時間偏好
- [ ] 實作 Service Interface + 實現
- [ ] 實作 Controller 層
- [ ] Flutter UI：學員設定可用時間
- [ ] Flutter UI：教練查看學員時間（日曆視圖）
- [ ] Flutter UI：教練拖拽創建訓練計劃到學員時間

**流程設計**：
1. 學員在 App 設定：「週一三五 18:00-20:00 可運動」
2. 教練打開學員詳情頁 → 看到學員的時間偏好日曆
3. 教練點擊學員可用時間 → 直接創建訓練計劃並指派
4. 學員收到通知：「教練已安排週一 18:00 訓練」

**驗收標準**：
- ✅ 學員可設定週期性可用時間
- ✅ 教練可查看學員的時間偏好
- ✅ 教練可在學員時間內創建訓練計劃
- ✅ 學員收到訓練計劃通知

#### B. 課程筆記系統（SOAP 格式）

**任務清單**：
- [ ] 實作 `session_notes` 表（SOAP + 隱私控制）
- [ ] RLS 策略：筆記可見性控制
- [ ] 實作 Service Interface + 實現
- [ ] 實作 Controller 層
- [ ] Flutter UI：SOAP 筆記編輯器（可切換分享狀態）
- [ ] Flutter UI：學員查看共享筆記

**驗收標準**：
- ✅ 教練撰寫 private 筆記 → 學員無法看到
- ✅ 教練切換為 shared → 學員立即看到
- ✅ 支援 SOAP 格式（Subjective, Objective, Assessment, Plan）

---

### Phase 4：數據洞察與儀表板（3-4 週）

**目標**：教練擁有完整的學員監控儀表板

**任務清單**：
- [ ] 創建 `mv_client_compliance` 物化視圖
- [ ] 創建 `mv_volume_by_muscle` 物化視圖
- [ ] 創建 `mv_strength_progress` 物化視圖
- [ ] 配置 `pg_cron` 定時刷新（每小時）
- [ ] 實作風險學員識別查詢
- [ ] Flutter UI：教練儀表板（合規率、訓練量）
- [ ] Flutter UI：學員個人進步曲線
- [ ] Flutter 圖表庫整合（fl_chart）
- [ ] 性能優化：視圖索引、查詢緩存

**驗收標準**：
- ✅ 教練打開儀表板 → 50 位學員數據秒開（<500ms）
- ✅ 風險學員自動標紅
- ✅ 點擊學員 → 顯示詳細訓練量、e1RM 曲線

---

### Phase 5：精細化與上線準備（2-3 週）

**目標**：生產環境部署與性能優化

**任務清單**：
- [ ] 生產環境 Supabase 配置（RLS 審查）
- [ ] Edge Functions 部署與監控
- [ ] 數據備份策略（pg_dump + Supabase Backup）
- [ ] 錯誤追蹤（Sentry）
- [ ] 性能監控（Supabase Metrics + pg_stat_statements）
- [ ] 用戶引導流程（Onboarding）
- [ ] 教練培訓文檔
- [ ] Beta 測試（5-10 組教練-學員）
- [ ] 隱私政策更新（雙端數據條款）

**驗收標準**：
- ✅ 生產環境 RLS 審查通過（無數據洩露）
- ✅ 並發壓力測試（100 學員同時記錄訓練）
- ✅ Beta 用戶反饋收集與迭代

---

## 4. 技術規範

### 4.1 命名規範

**資料庫層**：
- 表名：`snake_case`（如：`coaching_relationships`）
- 欄位名：`snake_case`（如：`scheduled_date`）
- 函式名：`snake_case`（如：`handle_new_user`）

**Flutter 層**：
- Model 類別：`PascalCase`（如：`CoachingRelationship`）
- 屬性：`camelCase`（如：`scheduledDate`）
- Service：`PascalCase` + `Supabase` 後綴（如：`AppointmentServiceSupabase`）

### 4.2 RLS 策略原則

1. **預設拒絕**：所有表啟用 RLS 後，預設無權限
2. **最小權限**：僅授予必要的操作權限
3. **明確關聯**：跨表查詢必須明確關聯條件（如：`coaching_relationships.status = 'active'`）
4. **性能考量**：RLS 子查詢必須有索引支撐

### 4.3 JSONB 使用規範

**適用場景**：
- ✅ 結構可變的數據（訓練模板、用戶偏好）
- ✅ 不需聚合查詢的嵌套數據

**不適用場景**：
- ❌ 需要 SUM/AVG 的數據（訓練組數、重量）
- ❌ 需要索引的查詢欄位（使用關聯表）

### 4.4 查詢效能規範

**必須遵守**：
- ✅ 明確欄位選擇（禁止 `SELECT *`）
- ✅ 為 RLS 關聯欄位建立索引
- ✅ 使用 Materialized Views 預計算統計數據
- ✅ 複雜查詢使用 EXPLAIN ANALYZE 驗證

**禁止事項**：
- ❌ 循環中查詢（N+1 問題）
- ❌ 深層 Offset 分頁（使用 Cursor-based）
- ❌ 未索引的全文搜尋（使用 pgroonga）

---

## 5. 數據遷移計劃

### 5.1 單機版數據評估

**可保留數據**：
- ✅ 用戶個人訓練記錄（遷移為 `workout_logs`）
- ✅ 自訂動作（遷移為 `exercise_library` is_custom = true）
- ✅ 身體數據（遷移為 `body_data`）
- ✅ 訓練模板（遷移為 `workout_templates`）

**需重新設計數據**：
- ⚠️ 單機版 `workout_plans` → 雙端版 `assigned_workouts`（需分離教練/學員關係）
- ⚠️ 統計數據 → 需重新計算（基於新的 `workout_sets` 表）

### 5.2 遷移腳本設計

**階段 1：結構遷移**
```python
# scripts/migrate_to_saas_structure.py
# 1. 讀取單機版 SQLite 數據
# 2. 轉換為 Supabase PostgreSQL 結構
# 3. 批量插入（使用事務）
```

**階段 2：關聯建立**
- 現有用戶自動設為 `role = 'client'`
- 如需升級為教練，需管理員手動調整

**階段 3：數據驗證**
- 對比遷移前後訓練記錄總數
- 驗證統計數據一致性

---

## 6. 風險評估與緩解

### 6.1 技術風險

| 風險項目 | 影響 | 可能性 | 緩解措施 |
|---------|------|--------|---------|
| RLS 策略配置錯誤導致數據洩露 | 高 | 中 | 1. 嚴格 Code Review<br>2. 自動化測試<br>3. 生產前安全審查 |
| 並發預約衝突處理失敗 | 中 | 低 | 1. GiST 排除約束<br>2. 壓力測試<br>3. 錯誤監控 |
| 物化視圖更新延遲過高 | 低 | 中 | 1. 優化更新頻率<br>2. 顯示「更新時間」標籤 |
| Edge Functions 冷啟動延遲 | 低 | 高 | 1. 保持函式溫暖（定時 ping）<br>2. 關鍵流程使用 Database Functions |

### 6.2 業務風險

| 風險項目 | 影響 | 可能性 | 緩解措施 |
|---------|------|--------|---------|
| 現有單機用戶抗拒雲端化 | 中 | 中 | 1. 提供本地匯出功能<br>2. 強調雲端備份優勢<br>3. 逐步引導遷移 |
| 教練學習成本過高 | 中 | 高 | 1. 詳細培訓文檔<br>2. 視頻教學<br>3. Beta 測試收集反饋 |
| 定價策略不清晰 | 高 | 中 | 1. 明確免費/付費功能<br>2. 學員數量分級定價<br>3. 透明費用說明 |

---

## 7. 成功指標 (KPIs)

### 7.1 技術指標

- **數據安全**：0 起數據洩露事件
- **查詢性能**：儀表板載入 < 500ms（50 學員）
- **預約成功率**：> 99.9%（排除約束生效）
- **RLS 覆蓋率**：100%（所有敏感表啟用）

### 7.2 業務指標

- **教練註冊數**：Phase 5 結束前達到 20 位
- **學員活躍度**：每週至少 3 次訓練記錄（合規率 > 70%）
- **功能採用率**：
  - 預約功能使用率 > 60%
  - 筆記功能使用率 > 40%
  - 儀表板查看率 > 80%（教練端）

---

## 8. 相關文檔

**核心文檔**：
- [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) - 當前開發狀態
- [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) - 專案架構總覽
- [DATABASE_SUPABASE.md](DATABASE_SUPABASE.md) - 單機版資料庫設計
- [DATABASE_OPTIMIZATION_GUIDE.md](DATABASE_OPTIMIZATION_GUIDE.md) - 資料庫優化指南

**技術參考**：
- [Supabase RLS 文檔](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Range Types](https://www.postgresql.org/docs/current/rangetypes.html)
- [PostgreSQL Exclusion Constraints](https://www.postgresql.org/docs/current/ddl-constraints.html#DDL-CONSTRAINTS-EXCLUSION)
- [Materialized Views](https://www.postgresql.org/docs/current/rules-materializedviews.html)

---

## 9. 附錄：關鍵 SQL 範例

### A. 基於屬性的動作庫完整 Schema

```sql
-- 1. 屬性分類表
CREATE TABLE public.attribute_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL, -- 'muscle_group', 'equipment', 'movement_pattern'
  display_name TEXT NOT NULL, -- '目標肌群', '器材類型', '運動模式'
  is_system BOOLEAN DEFAULT TRUE,
  cardinality TEXT CHECK (cardinality IN ('single_select', 'multi_select')) DEFAULT 'multi_select',
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 屬性標籤表
CREATE TABLE public.attributes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES public.attribute_categories(id),
  name TEXT NOT NULL, -- 'Chest', 'Barbell', 'Push'
  created_by UUID REFERENCES public.profiles(id), -- NULL = 系統標籤
  is_archived BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (name, category_id, created_by) -- 防止重複標籤
);

-- 索引優化
CREATE INDEX idx_attributes_name ON public.attributes(name text_pattern_ops);
CREATE INDEX idx_attributes_category ON public.attributes(category_id);
CREATE INDEX idx_attributes_creator ON public.attributes(created_by) WHERE created_by IS NOT NULL;

-- 3. 動作主表（輕量化）
CREATE TABLE public.exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id), -- NULL = 系統動作
  name TEXT NOT NULL,
  description TEXT,
  video_url TEXT,
  default_metric TEXT CHECK (default_metric IN ('weight_reps', 'time', 'distance')) DEFAULT 'weight_reps',
  is_placeholder BOOLEAN DEFAULT FALSE, -- 佔位符動作
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. 動作-屬性關聯表（核心）
CREATE TABLE public.exercise_attributes (
  exercise_id UUID REFERENCES public.exercises(id) ON DELETE CASCADE,
  attribute_id UUID REFERENCES public.attributes(id) ON DELETE CASCADE,
  PRIMARY KEY (exercise_id, attribute_id)
);

-- 正向查詢索引（查詢動作的所有標籤）
CREATE INDEX idx_ea_exercise ON public.exercise_attributes(exercise_id);

-- 反向查詢索引（查詢所有「胸部」動作）⭐ 核心統計優化
CREATE INDEX idx_ea_attribute ON public.exercise_attributes(attribute_id, exercise_id);

-- 5. 訓練組數據表（添加關鍵欄位）
ALTER TABLE public.workout_sets
ADD COLUMN is_warmup BOOLEAN DEFAULT FALSE,
ADD COLUMN estimated_1rm NUMERIC GENERATED ALWAYS AS (
  CASE WHEN reps > 0 THEN weight_kg * (1 + reps::numeric / 30.0) ELSE 0 END
) STORED;

-- 6. 身體部位統計表
CREATE TABLE public.user_attribute_stats (
  user_id UUID NOT NULL REFERENCES public.profiles(id),
  attribute_id UUID NOT NULL REFERENCES public.attributes(id),
  total_lifetime_volume BIGINT DEFAULT 0,
  max_session_volume BIGINT DEFAULT 0,
  max_session_date TIMESTAMPTZ,
  last_updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, attribute_id)
);

CREATE INDEX idx_user_attr_stats_user ON public.user_attribute_stats(user_id);
CREATE INDEX idx_user_attr_stats_attr ON public.user_attribute_stats(attribute_id);

-- 7. 單一動作統計表
CREATE TABLE public.user_exercise_stats (
  user_id UUID NOT NULL REFERENCES public.profiles(id),
  exercise_id UUID NOT NULL REFERENCES public.exercises(id),
  personal_record_weight NUMERIC,
  personal_record_e1rm NUMERIC,
  max_volume_single_session NUMERIC,
  last_performed_at TIMESTAMPTZ,
  PRIMARY KEY (user_id, exercise_id)
);

CREATE INDEX idx_user_ex_stats_user ON public.user_exercise_stats(user_id);
CREATE INDEX idx_user_ex_stats_recent ON public.user_exercise_stats(last_performed_at DESC);

-- 8. RLS 策略：動作庫可見性
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "exercise_access_policy" ON public.exercises
FOR SELECT
USING (
  user_id IS NULL -- 1. 系統動作（公開）
  OR user_id = auth.uid() -- 2. 用戶自己的動作
  OR user_id IN ( -- 3. 我的教練創建的動作
    SELECT coach_id 
    FROM public.coaching_relationships 
    WHERE client_id = auth.uid() AND status = 'active'
  )
);

-- 9. RLS 策略：屬性標籤可見性
ALTER TABLE public.attributes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "attributes_access_policy" ON public.attributes
FOR SELECT
USING (
  created_by IS NULL -- 系統標籤（公開）
  OR created_by = auth.uid() -- 自己創建的標籤
);
```

### B. 自動化統計觸發器

#### 身體部位 PR 自動更新

```sql
-- 觸發器函式
CREATE OR REPLACE FUNCTION public.update_attribute_stats()
RETURNS TRIGGER AS $$
DECLARE
  workout_attributes RECORD;
  session_volume BIGINT;
BEGIN
  -- 只在訓練完成時執行
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    
    -- 遍歷此次訓練涉及的所有身體部位標籤
    FOR workout_attributes IN
      SELECT DISTINCT ea.attribute_id
      FROM public.workout_exercises we
      JOIN public.exercise_attributes ea ON ea.exercise_id = we.exercise_id
      WHERE we.workout_id = NEW.id
    LOOP
      
      -- 計算該身體部位在本次訓練的總量（排除熱身組）
      SELECT COALESCE(SUM(ws.weight_kg * ws.reps), 0) INTO session_volume
      FROM public.workout_sets ws
      JOIN public.workout_exercises we ON we.id = ws.workout_exercise_id
      JOIN public.exercise_attributes ea ON ea.exercise_id = we.exercise_id
      WHERE we.workout_id = NEW.id
        AND ea.attribute_id = workout_attributes.attribute_id
        AND ws.is_warmup = FALSE;
      
      -- 插入或更新統計表
      INSERT INTO public.user_attribute_stats (
        user_id, attribute_id, total_lifetime_volume, max_session_volume, max_session_date
      )
      VALUES (
        NEW.user_id, 
        workout_attributes.attribute_id, 
        session_volume,
        session_volume,
        NEW.completed_date
      )
      ON CONFLICT (user_id, attribute_id) DO UPDATE SET
        total_lifetime_volume = user_attribute_stats.total_lifetime_volume + EXCLUDED.total_lifetime_volume,
        max_session_volume = CASE 
          WHEN EXCLUDED.max_session_volume > user_attribute_stats.max_session_volume 
          THEN EXCLUDED.max_session_volume 
          ELSE user_attribute_stats.max_session_volume 
        END,
        max_session_date = CASE 
          WHEN EXCLUDED.max_session_volume > user_attribute_stats.max_session_volume 
          THEN EXCLUDED.max_session_date 
          ELSE user_attribute_stats.max_session_date 
        END,
        last_updated_at = NOW();
        
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 綁定觸發器
CREATE TRIGGER workout_completion_stats_trigger
AFTER INSERT OR UPDATE OF status ON public.workouts
FOR EACH ROW EXECUTE FUNCTION public.update_attribute_stats();
```

#### 單一動作 PR 自動更新

```sql
-- 觸發器函式
CREATE OR REPLACE FUNCTION public.update_exercise_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- 只處理非熱身組
  IF NEW.is_warmup = FALSE THEN
    INSERT INTO public.user_exercise_stats (
      user_id, 
      exercise_id, 
      personal_record_weight, 
      personal_record_e1rm,
      last_performed_at
    )
    SELECT 
      w.user_id,
      we.exercise_id,
      NEW.weight_kg,
      NEW.estimated_1rm,
      NOW()
    FROM public.workout_exercises we
    JOIN public.workouts w ON w.id = we.workout_id
    WHERE we.id = NEW.workout_exercise_id
    ON CONFLICT (user_id, exercise_id) DO UPDATE SET
      personal_record_weight = GREATEST(user_exercise_stats.personal_record_weight, EXCLUDED.personal_record_weight),
      personal_record_e1rm = GREATEST(user_exercise_stats.personal_record_e1rm, EXCLUDED.personal_record_e1rm),
      last_performed_at = EXCLUDED.last_performed_at;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 綁定觸發器
CREATE TRIGGER workout_set_stats_trigger
AFTER INSERT ON public.workout_sets
FOR EACH ROW EXECUTE FUNCTION public.update_exercise_stats();
```

### C. 屬性交集查詢優化

```sql
-- 查詢「背部 + 機械 + 單邊」動作（高效版本）
SELECT e.id, e.name, e.description
FROM public.exercises e
WHERE EXISTS (
  SELECT 1 FROM public.exercise_attributes ea
  WHERE ea.exercise_id = e.id AND ea.attribute_id = 'UUID-BACK'
)
AND EXISTS (
  SELECT 1 FROM public.exercise_attributes ea
  WHERE ea.exercise_id = e.id AND ea.attribute_id = 'UUID-MACHINE'
)
AND EXISTS (
  SELECT 1 FROM public.exercise_attributes ea
  WHERE ea.exercise_id = e.id AND ea.attribute_id = 'UUID-UNILATERAL'
)
AND (e.user_id IS NULL OR e.user_id = auth.uid()) -- RLS 補充過濾
ORDER BY e.name;
```

### D. 查詢身體部位 PR（極速查詢）

```sql
-- 查詢用戶所有身體部位的 PR
SELECT 
  a.name AS body_part,
  uas.max_session_volume AS pr_volume,
  uas.max_session_date AS pr_date,
  uas.total_lifetime_volume AS lifetime_volume
FROM public.user_attribute_stats uas
JOIN public.attributes a ON a.id = uas.attribute_id
WHERE uas.user_id = auth.uid()
  AND a.category_id = (SELECT id FROM public.attribute_categories WHERE slug = 'muscle_group')
ORDER BY uas.max_session_volume DESC;

-- 效能：O(1) 查詢，< 5ms
```

### E. 查詢單一動作進步曲線

```sql
-- 查詢深蹲的歷史 e1RM 趨勢（用於繪製進步曲線）
SELECT 
  w.completed_date::DATE AS workout_date,
  MAX(ws.estimated_1rm) AS best_e1rm
FROM public.workout_sets ws
JOIN public.workout_exercises we ON we.id = ws.workout_exercise_id
JOIN public.workouts w ON w.id = we.workout_id
WHERE we.exercise_id = 'UUID-SQUAT'
  AND w.user_id = auth.uid()
  AND w.status = 'completed'
  AND ws.is_warmup = FALSE
GROUP BY w.completed_date::DATE
ORDER BY workout_date DESC
LIMIT 30;
```

### F. 自動綁定邀請用戶

```sql
-- 擴展 handle_new_user Trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  invited_by_coach uuid;
BEGIN
  -- 插入 profile
  INSERT INTO public.profiles (id, email, full_name, role, avatar_url)
  VALUES (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    COALESCE((new.raw_user_meta_data->>'role')::public.app_role, 'client'),
    new.raw_user_meta_data->>'avatar_url'
  );
  
  -- 檢查是否由教練邀請
  invited_by_coach := (new.raw_user_meta_data->>'invited_by')::uuid;
  
  IF invited_by_coach IS NOT NULL THEN
    -- 自動建立綁定關係
    INSERT INTO public.coaching_relationships (coach_id, client_id, status)
    VALUES (invited_by_coach, new.id, 'active');
  END IF;
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### B. 計算學員合規率的函式

```sql
CREATE OR REPLACE FUNCTION public.get_client_compliance(
  p_client_id uuid,
  p_days int DEFAULT 30
)
RETURNS TABLE (
  completed_count int,
  total_assigned int,
  compliance_rate numeric,
  last_workout_date date
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*) FILTER (WHERE status = 'completed')::int AS completed_count,
    COUNT(*)::int AS total_assigned,
    CASE
      WHEN COUNT(*) = 0 THEN 0
      ELSE ROUND((COUNT(*) FILTER (WHERE status = 'completed')::numeric / COUNT(*)) * 100, 2)
    END AS compliance_rate,
    MAX(scheduled_date) FILTER (WHERE status = 'completed') AS last_workout_date
  FROM public.assigned_workouts
  WHERE client_id = p_client_id
    AND scheduled_date > (CURRENT_DATE - p_days);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### C. 查詢教練的所有風險學員

```sql
-- 使用物化視圖查詢
SELECT
  p.full_name,
  p.email,
  mvc.compliance_rate_30d,
  mvc.last_workout_date,
  CASE
    WHEN mvc.last_workout_date < (CURRENT_DATE - 7) THEN '超過 7 天未訓練'
    WHEN mvc.compliance_rate_30d < 50 THEN '合規率低於 50%'
    ELSE '需關注'
  END AS risk_reason
FROM public.mv_client_compliance mvc
JOIN public.profiles p ON p.id = mvc.client_id
WHERE mvc.coach_id = auth.uid()
  AND (
    mvc.compliance_rate_30d < 50
    OR mvc.last_workout_date < (CURRENT_DATE - 7)
  )
ORDER BY mvc.last_workout_date ASC;
```

---

**下一步行動**：完成 Phase 1 基礎設施搭建（預計 2-3 週），並行進行 UI/UX 原型設計（Figma）。

