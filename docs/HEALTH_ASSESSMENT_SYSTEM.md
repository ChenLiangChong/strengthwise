# StrengthWise - 健康評估系統

> 基於國際 PAR-Q+ 標準的健康篩檢與評估系統

**最後更新**：2026-01-05

---

## 📋 目錄

1. [系統概述](#系統概述)
2. [資料庫設計](#資料庫設計)
3. [PAR-Q+ 問卷](#parq-問卷)
4. [資料模型](#資料模型)
5. [Service 層](#service-層)
6. [權限控制 (RLS)](#權限控制-rls)
7. [使用流程](#使用流程)

---

## 系統概述

### 目的

為教練提供結構化的學員健康評估工具，基於國際標準 **PAR-Q+** 框架，確保訓練安全。

### 核心功能

| 功能 | 說明 |
|------|------|
| 安全篩檢 | 7 題 PAR-Q+ 問卷，自動判定風險等級 |
| 傷病記錄 | 結構化記錄（部位、狀態、限制）|
| 生活型態 | 訓練經驗、職業活動度、器材 |
| 訓練目標 | 主要目標、數值、期望時程 |
| 緊急聯絡人 | 安全保障資訊 |
| 教練偏好 | 自訂顯示欄位（11 個可配置）|
| 教練備註 | 私有備註，教練間互不干擾 |

### 技術特點

- **自動風險評估**：低/中/高三級制
- **版本控制**：`is_current` 標記
- **JSONB 彈性**：進階評估使用 JSONB
- **GIN 索引**：快速查詢傷病或風險因子
- **RLS 安全**：教練僅存取 `active` 學員

---

## 資料庫設計

### 主要資料表

#### `health_assessments`

```sql
CREATE TABLE health_assessments (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    assessed_by UUID,
    assessment_date TIMESTAMPTZ DEFAULT NOW(),
    
    -- PAR-Q+ 7 題
    heart_disease BOOLEAN DEFAULT FALSE,
    chest_pain_exercise BOOLEAN DEFAULT FALSE,
    chest_pain_rest BOOLEAN DEFAULT FALSE,
    dizziness BOOLEAN DEFAULT FALSE,
    bone_joint_problem BOOLEAN DEFAULT FALSE,
    medication BOOLEAN DEFAULT FALSE,
    other_reason BOOLEAN DEFAULT FALSE,
    
    -- 自動計算
    is_cleared BOOLEAN GENERATED ALWAYS AS (
        NOT (heart_disease OR chest_pain_exercise OR ...)
    ) STORED,
    
    -- 進階評估（JSONB）
    cardiovascular_details JSONB DEFAULT '{}'::jsonb,
    musculoskeletal_details JSONB DEFAULT '[]'::jsonb,
    
    -- 生活型態
    training_experience training_level,
    training_years NUMERIC(3,1),
    occupation_activity activity_level,
    equipment_access TEXT[],
    
    -- 訓練目標
    training_goals JSONB DEFAULT '{}'::jsonb,
    
    -- 版本控制
    version INT DEFAULT 1,
    is_current BOOLEAN DEFAULT TRUE,
    emergency_contact JSONB
);
```

#### `coach_assessment_notes`（教練私有備註）

```sql
CREATE TABLE coach_assessment_notes (
    id UUID PRIMARY KEY,
    coach_id UUID NOT NULL,
    client_id UUID NOT NULL,
    note TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(coach_id, client_id)
);
```

#### `coach_display_preferences`

```sql
CREATE TABLE coach_display_preferences (
    coach_id UUID PRIMARY KEY,
    health_assessment_fields TEXT[] DEFAULT ARRAY[
        'safety_screening', 'injuries', 'medications',
        'training_experience', 'training_goals'
    ]
);
```

### 列舉類型

```sql
CREATE TYPE training_level AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE activity_level AS ENUM ('sedentary', 'light', 'moderate', 'vigorous');
CREATE TYPE injury_status AS ENUM ('acute', 'subacute', 'chronic', 'post_surgery');
```

---

## PAR-Q+ 問卷

### 基礎 7 題

| # | 問題 | 欄位 |
|---|------|------|
| 1 | 醫生是否曾診斷您患有心臟疾病？ | `heart_disease` |
| 2 | 您在運動時是否感到胸痛？ | `chest_pain_exercise` |
| 3 | 您在未運動時是否感到胸痛？ | `chest_pain_rest` |
| 4 | 您是否因頭暈而失去平衡？ | `dizziness` |
| 5 | 您是否有骨骼或關節問題？ | `bone_joint_problem` |
| 6 | 您目前是否正在服用處方藥物？ | `medication` |
| 7 | 您是否知道任何其他不宜運動的原因？ | `other_reason` |

### 判定邏輯

- ✅ **通過**：所有題目回答「否」
- ⚠️ **未通過**：任一題回答「是」→ 建議諮詢醫生

---

## 資料模型

### 檔案結構

```
lib/models/health_assessment/
├── enums.dart                    # 列舉類型
├── injury_record.dart            # 傷病記錄
├── training_goals.dart           # 訓練目標
└── health_assessment_model.dart  # 主要模型
```

### 核心模型欄位

| Model | 主要欄位 |
|-------|---------|
| `HealthAssessmentModel` | PAR-Q+ 7 題、injuries、trainingGoals、emergencyContact |
| `InjuryRecord` | site、status、diagnosis、limitations、occurredDate |
| `TrainingGoals` | primary、targetKg、timeframeMonths、notes |
| `CoachAssessmentNoteModel` | coachId、clientId、note |

---

## Service 層

### Interface

```dart
abstract class IHealthAssessmentService {
  Future<HealthAssessmentModel?> getCurrentAssessment(String userId);
  Future<HealthAssessmentModel> createAssessment(HealthAssessmentModel assessment);
  Future<void> updateAssessment(HealthAssessmentModel assessment);
  Future<void> deleteAssessment(String assessmentId);
  Future<Map<String, HealthAssessmentModel?>> batchGetCurrentAssessments(List<String> userIds);
}

abstract class ICoachAssessmentNoteService {
  Future<CoachAssessmentNoteModel?> getNoteForClient(String coachId, String clientId);
  Future<void> upsertNote(CoachAssessmentNoteModel note);
}
```

### 檔案結構

```
lib/services/
├── interfaces/
│   ├── i_health_assessment_service.dart
│   └── i_coach_assessment_note_service.dart
└── supabase/
    ├── health_assessment_service_supabase.dart
    └── coach_assessment_note_service_supabase.dart
```

---

## 權限控制 (RLS)

### 學員權限

```sql
-- 學員可以查看/編輯自己的評估
CREATE POLICY "Users can manage their own assessments"
ON health_assessments FOR ALL
USING (auth.uid() = user_id);
```

### 教練權限

```sql
-- 教練可以存取 active 學員的評估
CREATE POLICY "Coaches can access their clients' assessments"
ON health_assessments FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM coaching_relationships cr
        WHERE cr.client_id = health_assessments.user_id
        AND cr.coach_id = auth.uid()
        AND cr.status = 'active'
    )
);
```

### 教練備註隔離

```sql
-- 教練僅能存取自己的備註
CREATE POLICY "Coaches can only access own notes"
ON coach_assessment_notes FOR ALL
USING (auth.uid() = coach_id);
```

---

## 使用流程

### 教練建立評估

```
教練 → 學員詳情 → 基本資訊 Tab
  ↓
空健康評估卡片 → 立即建立評估
  ↓
5 步驟問卷：
├── 步驟 1：PAR-Q+ 篩檢（7 題）
├── 步驟 2：傷病史
├── 步驟 3：生活型態
├── 步驟 4：訓練目標
└── 步驟 5：緊急聯絡人
  ↓
完成 → 顯示摘要卡片
```

### 學員自填評估

```
學員 → 學員中心 → 健康評估 Tab
  ↓
填寫/編輯評估資料
  ↓
教練可在學員詳情頁查看
```

---

## 📎 相關文檔

- [DATABASE_SUPABASE.md](DATABASE_SUPABASE.md) - 完整資料庫設計
- [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) - 開發進度
- [migrations/016_health_assessments.sql](../migrations/016_health_assessments.sql) - 資料庫 Migration
