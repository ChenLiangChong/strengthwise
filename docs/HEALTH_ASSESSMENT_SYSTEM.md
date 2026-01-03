# 健康評估系統 (Health Assessment System)

> **版本**：v1.0  
> **建立日期**：2025-01-03  
> **最後更新**：2025-01-03  
> **狀態**：✅ 架構完成 / ⏳ UI 待完善

---

## 📋 目錄

1. [系統概述](#系統概述)
2. [資料庫設計](#資料庫設計)
3. [PAR-Q+ 問卷](#par-q-問卷)
4. [資料模型](#資料模型)
5. [Service 層](#service-層)
6. [UI 組件](#ui-組件)
7. [權限控制 (RLS)](#權限控制-rls)
8. [使用流程](#使用流程)
9. [待完成項目](#待完成項目)

---

## 系統概述

### 目的

為教練提供結構化的學員健康評估工具，基於國際標準 **PAR-Q+ (Physical Activity Readiness Questionnaire)** 框架，確保訓練安全與效果。

### 核心功能

1. **安全篩檢**：7 題 PAR-Q+ 基礎問卷，自動判定是否適合運動
2. **傷病記錄**：結構化記錄學員傷病史（部位、狀態、限制）
3. **生活型態**：訓練經驗、職業活動度、可用器材
4. **訓練目標**：主要目標、數值、期望時程
5. **緊急聯絡人**：安全保障資訊

### 技術亮點

- ✅ **自動計算**：`is_cleared` 欄位由資料庫自動生成
- ✅ **版本控制**：支援歷史評估記錄（`is_current` 標記）
- ✅ **JSONB 彈性**：進階評估使用 JSONB 儲存，方便擴充
- ✅ **GIN 索引**：支援快速查詢特定傷病或風險因子
- ✅ **RLS 安全**：教練僅能存取 `active` 學員的評估

---

## 資料庫設計

### 主要資料表

#### 1. `health_assessments` 表

```sql
CREATE TABLE public.health_assessments (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    assessed_by UUID,
    assessment_date TIMESTAMPTZ DEFAULT NOW(),
    
    -- 基礎安全篩檢（PAR-Q+ 7 題）
    heart_disease BOOLEAN DEFAULT FALSE,
    chest_pain_exercise BOOLEAN DEFAULT FALSE,
    chest_pain_rest BOOLEAN DEFAULT FALSE,
    dizziness BOOLEAN DEFAULT FALSE,
    bone_joint_problem BOOLEAN DEFAULT FALSE,
    medication BOOLEAN DEFAULT FALSE,
    other_reason BOOLEAN DEFAULT FALSE,
    
    -- 自動計算：是否通過篩檢
    is_cleared BOOLEAN GENERATED ALWAYS AS (
        NOT (heart_disease OR chest_pain_exercise OR chest_pain_rest 
             OR dizziness OR bone_joint_problem OR medication OR other_reason)
    ) STORED,
    
    -- 進階評估（JSONB）
    cardiovascular_details JSONB DEFAULT '{}'::jsonb,
    musculoskeletal_details JSONB DEFAULT '[]'::jsonb,
    metabolic_details JSONB DEFAULT '{}'::jsonb,
    respiratory_details JSONB DEFAULT '{}'::jsonb,
    
    -- 生活型態
    training_experience training_level,
    training_years NUMERIC(3,1),
    occupation_activity activity_level,
    equipment_access TEXT[],
    weekly_sessions INT,
    sleep_hours NUMERIC(3,1),
    
    -- 訓練目標
    training_goals JSONB DEFAULT '{}'::jsonb,
    
    -- 版本控制
    version INT DEFAULT 1,
    is_current BOOLEAN DEFAULT TRUE,
    emergency_contact JSONB,
    coach_notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### 2. `coach_display_preferences` 表

```sql
CREATE TABLE public.coach_display_preferences (
    coach_id UUID PRIMARY KEY,
    health_assessment_fields TEXT[] DEFAULT ARRAY[
        'safety_screening',
        'injuries',
        'medications',
        'training_experience',
        'training_goals'
    ],
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 列舉類型

```sql
CREATE TYPE training_level AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE activity_level AS ENUM ('sedentary', 'light', 'moderate', 'vigorous');
CREATE TYPE injury_status AS ENUM ('acute', 'subacute', 'chronic', 'post_surgery');
```

### 索引策略

```sql
-- 唯一索引：確保每個學員只有一份當前評估
CREATE UNIQUE INDEX unique_current_assessment_per_user
ON health_assessments(user_id) WHERE is_current = TRUE;

-- GIN 索引：快速查詢傷病史
CREATE INDEX idx_health_assessments_injuries 
ON health_assessments USING gin(musculoskeletal_details);

-- GIN 索引：查詢心血管風險
CREATE INDEX idx_health_assessments_cardiovascular 
ON health_assessments USING gin(cardiovascular_details);

-- 條件索引：查詢特定訓練經驗
CREATE INDEX idx_health_assessments_training_level 
ON health_assessments(training_experience) 
WHERE training_experience IS NOT NULL;
```

---

## PAR-Q+ 問卷

### 基礎 7 題（核心篩檢）

| 題號 | 問題 | 欄位名稱 | 備註欄位 |
|------|------|----------|----------|
| 1 | 醫生是否曾診斷您患有心臟疾病？ | `heart_disease` | `heart_disease_note` |
| 2 | 您在運動時是否感到胸痛？ | `chest_pain_exercise` | - |
| 3 | 您在未運動時（過去一個月內）是否感到胸痛？ | `chest_pain_rest` | - |
| 4 | 您是否因頭暈而失去平衡，或曾失去意識？ | `dizziness` | - |
| 5 | 您是否有骨骼或關節問題，可能因運動而惡化？ | `bone_joint_problem` | `bone_joint_note` |
| 6 | 您目前是否正在服用任何處方藥物？ | `medication` | `medication_note` |
| 7 | 您是否知道任何其他不宜運動的原因？ | `other_reason` | `other_reason_note` |

### 判定邏輯

```dart
// 自動計算 is_cleared
is_cleared = !(heart_disease || chest_pain_exercise || chest_pain_rest 
               || dizziness || bone_joint_problem || medication || other_reason)
```

- ✅ **通過**：所有題目回答「否」
- ⚠️ **未通過**：任一題回答「是」→ 建議諮詢醫生

---

## 資料模型

### Dart Model 架構

```
lib/models/
└── health_assessment/
    ├── enums.dart                    # 列舉類型
    ├── injury_record.dart            # 傷病記錄
    ├── training_goals.dart           # 訓練目標
    └── health_assessment_model.dart  # 主要模型
```

### 核心模型

#### `HealthAssessmentModel`

```dart
class HealthAssessmentModel {
  final String id;
  final String userId;
  final String? assessedBy;
  final DateTime assessmentDate;
  
  // PAR-Q+ 篩檢
  final bool heartDisease;
  final bool chestPainExercise;
  final bool chestPainRest;
  final bool dizziness;
  final bool boneJointProblem;
  final bool medication;
  final bool otherReason;
  final bool isCleared; // 自動計算
  
  // 進階評估
  final List<InjuryRecord> injuries;
  final Map<String, dynamic>? cardiovascularDetails;
  final Map<String, dynamic>? metabolicDetails;
  final Map<String, dynamic>? respiratoryDetails;
  
  // 生活型態
  final TrainingLevel? trainingExperience;
  final double? trainingYears;
  final ActivityLevel? occupationActivity;
  final List<String> equipmentAccess;
  final int? weeklySessions;
  final double? sleepHours;
  
  // 訓練目標
  final TrainingGoals? trainingGoals;
  
  // 版本控制
  final int version;
  final bool isCurrent;
  final Map<String, dynamic>? emergencyContact;
  final String? coachNotes;
  
  // 方法
  factory HealthAssessmentModel.fromSupabase(Map<String, dynamic> json);
  Map<String, dynamic> toSupabase();
  bool get hasWarnings;
  List<String> getWarningSummary();
}
```

#### `InjuryRecord`（傷病記錄）

```dart
class InjuryRecord {
  final String site;              // 部位（例：右膝、腰椎）
  final InjuryStatus status;      // 狀態（急性、慢性等）
  final String? diagnosis;        // 診斷
  final String? limitations;      // 功能限制
  final DateTime? occurredDate;   // 發生日期
}
```

#### `TrainingGoals`（訓練目標）

```dart
class TrainingGoals {
  final String primary;           // 主要目標（'weight_loss', 'muscle_gain', 'performance', 'health'）
  final double? targetKg;         // 目標數值（kg）
  final int? timeframeMonths;     // 期望時程（月）
  final String? notes;            // 補充筆記
  
  String get primaryLabel;        // 取得中文標籤
}
```

---

## Service 層

### Interface

```dart
abstract class IHealthAssessmentService {
  // 查詢
  Future<HealthAssessmentModel?> getCurrentAssessment(String userId);
  Future<List<HealthAssessmentModel>> getAssessmentHistory(String userId, {int limit = 10});
  
  // 建立與更新
  Future<HealthAssessmentModel> createAssessment(HealthAssessmentModel assessment, {bool setAsCurrent = true});
  Future<void> updateAssessment(HealthAssessmentModel assessment);
  
  // 管理
  Future<void> deleteAssessment(String assessmentId);
  Future<void> setAsCurrentAssessment(String assessmentId, String userId);
  
  // 批次與警示
  Future<Map<String, HealthAssessmentModel?>> batchGetCurrentAssessments(List<String> userIds);
  Future<List<HealthAssessmentModel>> getWarningAssessments(String coachId);
}
```

### 實作架構

```
lib/services/
├── interfaces/
│   └── i_health_assessment_service.dart
├── health_assessment/
│   ├── health_assessment_query_manager.dart      # 查詢管理
│   └── health_assessment_operations_manager.dart # 寫入管理
└── supabase/
    └── health_assessment_service_supabase.dart   # 服務實作
```

---

## UI 組件

### 已完成組件

#### 1. `EmptyHealthAssessmentCard`（空狀態卡片）

- 顯示位置：學員詳情頁 > 基本資訊 Tab
- 功能：提示教練建立健康評估
- 設計：友善的引導 UI，說明評估的重要性

#### 2. `HealthAssessmentSummaryCard`（摘要卡片）

- 顯示位置：學員詳情頁 > 基本資訊 Tab
- 功能：顯示評估重點（安全篩檢狀態、警示摘要、訓練背景）
- 互動：查看完整 / 編輯按鈕

#### 3. `HealthAssessmentPage`（問卷頁面）

- **5 步驟表單**：
  - **步驟 1**：PAR-Q+ 基礎安全篩檢（✅ 完整實作）
  - **步驟 2**：傷病史記錄（⏸️ 佔位符）
  - **步驟 3**：生活型態與訓練背景（✅ 基礎實作）
  - **步驟 4**：訓練目標（✅ 基礎實作）
  - **步驟 5**：緊急聯絡人（✅ 基礎實作）

- **導航控制**：上一步 / 下一步 / 完成
- **編輯模式**：支援載入現有資料

### 整合位置

```dart
// lib/views/pages/coaching/tabs/client_info_tab.dart

// 教練點擊「學員詳情」→「基本資訊」Tab
// 自動載入並顯示：
// 1. 學員檔案卡片（訓練目標、健康注意事項）
// 2. 健康評估卡片（PAR-Q+ 問卷）← 新增
// 3. 基本資訊（姓名、Email、角色）
```

---

## 權限控制 (RLS)

### RLS 政策

#### 學員權限

```sql
-- 學員可以查看/插入/更新自己的評估
CREATE POLICY "Users can view their own health assessments"
ON health_assessments FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own health assessments"
ON health_assessments FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own health assessments"
ON health_assessments FOR UPDATE
USING (auth.uid() = user_id);
```

#### 教練權限

```sql
-- 教練可以查看/插入/更新所屬學員的評估（僅 active 關係）
CREATE POLICY "Coaches can view their clients' health assessments"
ON health_assessments FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM coaching_relationships cr
        WHERE cr.client_id = health_assessments.user_id
        AND cr.coach_id = auth.uid()
        AND cr.status = 'active'
    )
);

-- INSERT 和 UPDATE 政策同理
```

### 關鍵設計

- ✅ **狀態綁定**：教練僅能存取 `status = 'active'` 的學員評估
- ✅ **自動失效**：當教練與學員解除綁定（`status = 'archived'`），教練立即失去存取權限
- ✅ **資料保留**：學員的評估資料永久保留，不會因解除綁定而被刪除

---

## 使用流程

### 教練建立評估流程

```
1. 教練進入「學員詳情」頁面
   ↓
2. 切換到「基本資訊」Tab
   ↓
3. 看到「空健康評估卡片」
   ↓
4. 點擊「立即建立評估」
   ↓
5. 進入 5 步驟問卷頁面
   ↓
6. 依序填寫：
   - 步驟 1：PAR-Q+ 篩檢（7 題）
   - 步驟 2：傷病史（開發中）
   - 步驟 3：生活型態
   - 步驟 4：訓練目標
   - 步驟 5：緊急聯絡人
   ↓
7. 點擊「完成」儲存
   ↓
8. 返回學員詳情頁，顯示「摘要卡片」
```

### 查看評估流程

```
1. 教練進入「學員詳情」→「基本資訊」
   ↓
2. 看到「健康評估摘要卡片」
   - 安全篩檢狀態（✅ 通過 / ⚠️ 未通過）
   - 警示摘要（傷病、藥物）
   - 訓練背景（經驗、目標）
   ↓
3. 點擊「查看完整評估」
   ↓
4. 進入問卷頁面（唯讀模式）
   ↓
5. 可點擊「編輯」修改資料
```

---

## 待完成項目

### 🚧 高優先級

1. **步驟 2：傷病史記錄表單**
   - 身體圖點選 UI
   - 傷病記錄新增/編輯/刪除
   - 部位、狀態、診斷、限制輸入

2. **`_saveAssessment()` 完整實作**
   - 建立 `HealthAssessmentModel` 實例
   - 呼叫 `createAssessment()` / `updateAssessment()`
   - 返回結果並重新載入

3. **表單驗證與錯誤處理**
   - 必填欄位檢查
   - 數值範圍驗證
   - 友善錯誤訊息

### 🔮 中優先級

4. **步驟 3-5 完善**
   - 器材多選 UI
   - 訓練目標數值輸入
   - 緊急聯絡人電話格式驗證

5. **歷史評估檢視**
   - 顯示所有評估記錄
   - 比較不同版本差異
   - 恢復舊版本功能

6. **教練顯示偏好設定**
   - 自訂學員詳情頁顯示欄位
   - 儲存偏好到 `coach_display_preferences`

### 🌟 低優先級

7. **警示學員列表**
   - 教練中心顯示未通過篩檢的學員
   - 一鍵查看風險因子

8. **匯出 PDF 報告**
   - 完整評估報告生成
   - 包含建議與注意事項

9. **提醒與通知**
   - 定期提醒更新評估（每 6 個月）
   - 新增傷病時自動通知教練

---

## 📊 完成度統計

| 層級 | 完成度 | 說明 |
|------|--------|------|
| **資料庫 (Migration)** | ✅ 100% | 表格、索引、RLS、Trigger 完整 |
| **Model 層** | ✅ 100% | 完整模型、型別安全 |
| **Service 層** | ✅ 100% | Interface + 實作 + 註冊 |
| **UI 層（基礎）** | ✅ 80% | 卡片完成、問卷基礎完成 |
| **UI 層（進階）** | ⏳ 30% | 傷病史表單、歷史記錄待開發 |

---

## 🔗 相關文檔

- **[DATABASE_SUPABASE.md](DATABASE_SUPABASE.md)** - 完整資料庫設計
- **[DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)** - 專案進度追蹤
- **[UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md)** - UI/UX 設計規範
- **[migrations/016_health_assessments.sql](../migrations/016_health_assessments.sql)** - 資料庫 Migration

---

**最後更新**：2025-01-03  
**維護者**：StrengthWise 開發團隊

