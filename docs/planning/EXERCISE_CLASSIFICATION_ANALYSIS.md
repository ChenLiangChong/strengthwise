# 動作分類系統與資料庫架構重設計綜合研究報告：邁向多維度分類與直覺化搜尋

## 1. 執行摘要 (Executive Summary)

在當前的健身應用程式市場中，資料結構的僵化是導致使用者體驗（UX）摩擦的主要來源。本報告針對「動作分類系統重新設計」的需求，提出了一套詳盡的架構藍圖。本專案的核心目標是移除自動化處理的模糊性，轉而採用高精度的「人工重命名與標籤化」策略。

我們將解構「動作」這一實體，將其從單一分類中解放，轉而透過**「解剖學目標（Anatomy）」**、**「動作模式（Movement Patterns）」**與**「訓練分裂邏輯（Split Logic）」**三個維度進行動態重組。本報告將詳細論證為何採用多對多（Many-to-Many）的關聯式資料庫設計是實現「多種分類檢視模式」的唯一途徑，並提供具體的命名協定（Naming Convention）與別名系統（Alias System），以徹底解決搜尋不直覺的痛點。

---

## 2. 核心設計原則與理論架構

### 2.1 設計原則轉變

| 原則 | v1 現況 | v2 目標 |
|------|---------|---------|
| **命名規則** | 自由文本 / 不一致 | **SEE 標準**（詳見 Section 4）|
| **分類邏輯** | 單一部位 (Single-Inheritance) | **多標籤 + 功能性模式** (Multi-Dimensional) |
| **ID 類型** | 字串 ID | **UUID** (離線同步友善) |
| **刪除策略** | 直接刪除 | **軟刪除** (保留歷史) |

### 2.2 運動科學理論基礎

#### 2.2.1 動作模式 (Movement Patterns) - 功能性觀點

根據 NSCA 與 FMS 標準，動作應依據生物力學特徵分類。這解決了如「硬舉是練腿還是練背」的分類悖論。

**七大基礎模式（頂層分類）：**

| # | 模式 | 說明 | 子分類 |
|---|------|------|--------|
| 1 | **Push** | 推 | horizontal_push, vertical_push, isolation_push |
| 2 | **Pull** | 拉 | horizontal_pull, vertical_pull, isolation_pull |
| 3 | **Squat** | 蹲（膝主導）| isolation_squat |
| 4 | **Hinge** | 髖鉸鏈（髖主導）| isolation_hinge |
| 5 | **Lunge** | 弓步/單腿 | - |
| 6 | **Core** | 核心 | anti_extension, anti_rotation, anti_lateral, flexion, rotation |
| 7 | **Carry** | 攜帶/移動 | - |

**訓練類型（頂層，非重量訓練）：**
*   **Cardio**: 心肺訓練
*   **Mobility**: 活動度/伸展

**孤立動作歸類規則：**
*   三頭伸展、飛鳥 → `isolation_push`（Push 子類）
*   二頭彎舉、反向飛鳥、側平舉 → `isolation_pull`（Pull 子類）
*   腿伸展 → `isolation_squat`（Squat 子類）
*   腿彎舉、髖外展 → `isolation_hinge`（Hinge 子類）

**爆發力動作標記：**
*   `is_explosive` 欄位（TRUE / FALSE）
*   原 `power` 和 `plyometric` 動作需要：
    1. 改為正確的動作模式（如 Hinge、Squat）
    2. 標記 `is_explosive = TRUE`

##### 動作模式轉換對照表（v1 → v2）

| 舊值 | 新值 | 判斷依據 |
|------|------|---------|
| `isolation_upper` | `isolation_push` | 三頭、胸（飛鳥）|
| `isolation_upper` | `isolation_pull` | 二頭、後三角 |
| `isolation_lower` | `isolation_squat` | 腿伸展（股四頭）|
| `isolation_lower` | `isolation_hinge` | 腿彎舉（腿後肌）|
| `core_anti_extension` | `anti_extension` | - |
| `core_anti_rotation` | `anti_rotation` | - |
| `core_anti_lateral` | `anti_lateral` | - |
| `core_flexion` | `flexion` | - |
| `core_rotation` | `rotation` | - |
| `power` | 對應模式 + `is_explosive=TRUE` | 如 hinge、squat |
| `plyometric` | 對應模式 + `is_explosive=TRUE` | 如 squat、lunge |

#### 2.2.2 訓練分裂邏輯 (PPL) - 使用者習慣視圖

這是一種排程啟發法 (Scheduling Heuristic)，應作為標籤存在。
*   **Push**: 胸、肩前束、三頭。
*   **Pull**: 背、二頭、肩後束。
*   **Push + Pull**（雙標）: 肩中束（side_delts）— 側平舉、直立划船等。
*   **Legs**: 下肢。

*注意：某些動作（如硬舉）可同時標記為 Pull 和 Legs。*

**PPL 標籤邏輯：**

| 動作類型 | PPL 標籤 | 理由 |
|----------|----------|------|
| 後三角肌孤立動作 | **Pull** | 功能上與划船/引體類似 |
| 硬舉 | **Pull + Legs** | 同時涉及拉與下肢 |
| 肩推 | **Push** | 垂直推 |
| 側平舉 | **Push + Pull** | 力學為拉（肩外展），但常排在 Push Day，雙標確保可搜尋性 |
| 直立划船 | **Push + Pull** | 同上，主動肌 side_delts，雙標 |

### 2.3 搜尋架構設計：三層篩選 + 兩種視圖

> **重要設計決策**：系統支援「三層篩選架構」+「兩種核心分類維度」+「一種便利標籤」

#### 三層篩選架構

```
Layer 0: 訓練類型（Training Type）← 使用現有 movement_pattern 欄位
├── 心肺訓練 (Cardio)         → pattern = 'cardio'
├── 活動度訓練 (Mobility)      → pattern = 'mobility'
└── 重量訓練 (Resistance)      → pattern IN ('squat', 'hinge', 'push', 'pull', ...)

Layer 1-2: 兩種視圖（對所有訓練類型都適用）
├── 解剖學視圖 → Region → Muscle → 動作列表
└── 動作模式視圖 → Pattern → 動作列表
```

**設計優勢**：不需要新增欄位，直接複用 `ref_movement_patterns` 的頂層分類作為訓練類型篩選。

#### 訓練類型與動作模式對應

| 訓練類型 | 對應的 Movement Pattern | 說明 |
|---------|------------------------|------|
| **心肺訓練** | `cardio` | 跑步、騎車、划船、跳繩等 |
| **活動度訓練** | `mobility` | 伸展、滾筒放鬆、關節活動度 |
| **重量訓練** | 其他所有模式 | squat, hinge, push, pull, lunge, core_*, isolation_*, power, plyometric, carry |

#### 分類層級定位

| 類型 | 維度 | 核心問題 | 定位 | 資料表類型 |
|------|------|---------|------|-----------|
| **第一層篩選** | 訓練類型 | 「練什麼類型？」| 頂層 Pattern | 複用 Lookup Table |
| **核心分類 1** | 解剖學（Anatomy）| 「練哪裡？」| ✅ 科學分類 | Lookup Table |
| **核心分類 2** | 動作模式（Movement Patterns）| 「怎麼動？」| ✅ 科學分類 | Lookup Table |
| **便利標籤** | PPL（Split Tags）| 「課表怎排？」| ❌ 非分類，是標籤 | Tag Table |

#### 搜尋模式 1：解剖學視圖（Anatomy View）

**思維模式**：「我要練哪個肌肉？」

```
搜尋流程：Region（區域）→ Muscle（肌肉）→ 動作列表

範例：
「上肢」→「三頭肌」→ 三頭下壓、窄握臥推、法式推舉...
「下肢」→「腿後肌」→ 硬舉、腿彎舉、北歐腿彎舉...
```

**適用情境**：
- 健美式訓練（部位分化）
- 「今天練胸」的思維
- 查看某肌群的訓練量統計
- 肌肉熱力圖（Muscle Heatmap）

#### 搜尋模式 2：動作模式視圖（Movement Pattern View）

**思維模式**：「我要做什麼類型的動作？」

```
搜尋流程：Pattern（模式）→ 動作列表

範例：
「Hinge（髖鉸鏈）」→ 硬舉、RDL、早安式、壺鈴擺盪...
「Horizontal Push（水平推）」→ 臥推、伏地挺身、啞鈴臥推...
「Vertical Pull（垂直拉）」→ 引體向上、滑輪下拉...
```

**適用情境**：
- 功能性訓練
- **受傷替代**：「膝蓋痛，避開 Squat 模式，改練 Hinge 模式」
- **訓練平衡**：「這週推拉比例是否均衡？」
- 動作進退階選擇

#### Filters（篩選條件）的設計

Filters 是**可隨時套用的篩選條件**，不受層級限制，可在瀏覽前/中/後任意套用。

| Filter | 用途 | 值 | 可複選 |
|--------|------|-----|--------|
| **Equipment** | 器材篩選 | barbell, dumbbell, bodyweight, cable... | ✅ 是 |
| **PPL** | 訓練日篩選 | push, pull, legs, upper, lower, core | ✅ 是 |
| **Power** | 爆發力篩選 | true / false | ❌ 否 |

**PPL 標籤的定位：**
- **不是第三種搜尋模式**，而是一種「排程便利標籤」
- 用於快速篩選「今天是推日/拉日/腿日」
- 允許複選（硬舉 = Pull + Legs）
- 不涉及科學分類邏輯

**Filter 使用範例：**
```
情境 1：先設 Filter，再瀏覽
[Filter: Push] [Filter: 啞鈴] → 重量訓練 → 解剖學視圖 → 胸肌 → 結果

情境 2：瀏覽後再加 Filter
重量訓練 → 動作模式視圖 → Hinge → [加 Filter: 槓鈴] → 結果縮小

情境 3：只用 Filter
[Filter: 徒手] [Filter: Legs] → 直接顯示所有符合的動作
```

#### 硬舉案例：三維度完整分類

| 維度 | 分類 | 類型 |
|------|------|------|
| **解剖學** | Primary = Hamstrings（腿後肌）| 核心分類 |
| **動作模式** | Hinge（髖鉸鏈）| 核心分類 |
| **PPL 標籤** | Pull + Legs（兩個都選）| 便利標籤 |

> 「將動作歸類為『髖絞鍊』而非單純的『背部訓練』，解決了硬舉分類的歧義性。這允許使用者在**背部受傷需要避免脊椎垂直受力時**，能透過篩選『動作模式』來尋找替代動作，這是**單純解剖學分類無法做到的**。」

### 2.4 肌群階層結構

參考檔案：`scripts/reference_data/ref_muscle_groups.json`

#### 設計原則

- **使用者視角**：搜尋時想的是「練臀」「練小腿」，不會搜「練臀大肌」「練腓腸肌」
- **肌群層級**：主動肌使用肌群層級，不細分到個別肌肉頭
- **三層結構**：Region → Group → Muscle

#### 6 大區域 + 25 個有效肌肉值

```
Region        Group         Muscles (主動肌有效值)
──────────────────────────────────────────────────
upper_body    chest (胸)    pec_major_clavicular, pec_major_sternal,
                            pec_minor, serratus_anterior

              back (背)     lats, traps, rhomboids, erector_spinae,
                            teres_major

              shoulders (肩) front_delts, side_delts, rear_delts,
                            rotator_cuff

              arms (手)     biceps, triceps, brachialis, forearms

lower_body    legs (腿)     quads, hamstrings, glutes, adductors,
                            calves, hip_flexors, tibialis_anterior

core          core (核心)   abs, obliques
```

#### 不需要的細分（統一轉換）

| 過細的值 | 統一為 | 原因 |
|---------|--------|------|
| `glute_max`, `glute_med` | `glutes` | 使用者搜「臀部」不搜「臀大肌」 |
| `gastrocnemius`, `soleus` | `calves` | 使用者搜「小腿」不搜「腓腸肌」 |
| `infraspinatus`, `subscapularis` | `rotator_cuff` | 統一為肩袖肌群 |
| `rectus_femoris`, `vastus_*` | `quads` | 使用者搜「股四頭」 |

#### 主動肌細化對照表（v1 → v2）

| 原值 | 應改為 | 數量 |
|------|--------|------|
| `shoulders` | `front_delts` / `side_delts` / `rear_delts` | 34 |
| `core` | `abs` / `obliques` | 19 |
| `back` | `lats` / `traps` / `rhomboids` / `erector_spinae` | 10 |
| `chest` | `pec_major_sternal` / `pec_major_clavicular` | 10 |
| `glute_max`, `glute_med`, `glute_medius` | `glutes` | 12 |
| `gastrocnemius`, `soleus` | `calves` | 7 |
| `infraspinatus`, `subscapularis`, 等 | `rotator_cuff` | 6 |
| `mid_pecs`, `pec_major` | `pec_major_sternal` | 2 |
| `rectus_abdominis` | `abs` | 3 |
| `upper_back` 系列 | `rhomboids` 或 `traps` | 4 |

#### 背部肌肉說明

| 肌肉 | 位置 | 代表動作 |
|------|------|---------|
| `lats` | 中背 | 引體向上、下拉、划船 |
| `traps` | 上背 | 聳肩、臉拉 |
| `rhomboids` | 上背 | 划船（夾背）|
| `erector_spinae` | 下背 | 硬舉、背伸展 |
| `teres_major` | 中背 | 輔助 lats |

> **備註**：`rear_delts` 雖然常與背部一起訓練，但解剖學上屬於三角肌，放在 shoulders。

#### 主動肌填寫規則

| 規則 | 說明 |
|------|------|
| **只填一個** | 不可多選，協同肌另外填 |
| **不加括號** | ❌ `shoulders (rear_delts)` → ✅ `rear_delts` 或 `shoulders` |
| **使用 Ref ID** | 填寫 `ref_muscle_groups.json` 中的 `id` 值 |

---

## 3. 資料庫架構設計 (Schema Design)

為了支援多維度檢視，我們採用高度正規化的關聯式架構。

### 3.1 核心實體表 (Core Entities)

#### `exercises` (動作主表)
動作的唯一真理來源。
```sql
CREATE TABLE exercises (
    id UUID PRIMARY KEY,
    canonical_name VARCHAR NOT NULL,      -- 標準中文名 (SEE 格式)
    canonical_name_en VARCHAR,            -- 標準英文名 (SEE 格式)
    equipment_id UUID,                    -- 主要器材FK
    mechanics_type VARCHAR,               -- compound / isolation
    is_unilateral BOOLEAN,
    difficulty_level VARCHAR,             -- beginner / intermediate / advanced
    is_deleted BOOLEAN DEFAULT FALSE,     -- 軟刪除
    merged_to_id UUID NULL                -- 合併重定向
);
```

#### `search_aliases` (搜尋別名表)
解決「搜尋不直覺」的關鍵。將俚語、縮寫映射到標準動作。
```sql
CREATE TABLE search_aliases (
    id UUID PRIMARY KEY,
    exercise_id UUID FK,
    term VARCHAR,          -- 關鍵字 (如 "Skullcrushers", "BSS")
    locale VARCHAR,        -- zh-TW, en-US
    category VARCHAR       -- Slang, Abbreviation
);
```

### 3.2 關聯表 (Junction Tables)

#### `rel_exercise_muscles` (動作↔肌肉)
區分主動肌與協同肌。
*   `exercise_id` (FK)
*   `muscle_id` (FK)
*   `role`: 'Primary' (主要), 'Secondary' (協同), 'Stabilizer' (穩定)

#### `rel_exercise_patterns` (動作↔模式)
解決複合動作跨模式問題（如 Thruster = Squat + Vertical Push）。
*   `exercise_id` (FK)
*   `pattern_id` (FK)

#### `rel_exercise_split_tags` (動作↔PPL)
*   `exercise_id` (FK)
*   `split_tag`: Push, Pull, Legs, Upper, Lower, Core, Cardio

---

## 4. 人工重命名協定：SEE 法則

為了確保資料一致性，所有動作名稱必須遵循 **SEE (Specification - Equipment - Exercise)** 結構。

### 4.1 結構定義

```
[規格] + [器材] + [動作]
[Specification] + [Equipment] + [Exercise]
```

#### 4.1.1 規格（Specification）的類型與順序

當有多個規格時，依照以下順序排列：

```
[單雙側] → [姿勢] → [握法] → [角度] → [器材] → [動作]
```

| 順序 | 類型 | 中文 | 英文 |
|------|------|------|------|
| 1 | **單雙側** | 單手、單腳、交替 | Single Arm, Single Leg, Alternating |
| 2 | **姿勢** | 站姿、坐姿、仰臥、俯臥、俯身、跪姿、懸垂 | Standing, Seated, Lying/Supine, Prone, Bent Over, Kneeling, Hanging |
| 3 | **握法** | 寬握、窄握、反握、正握、中立握 | Wide Grip, Close/Narrow Grip, Reverse/Underhand, Overhand, Neutral Grip |
| 4 | **角度** | 上斜、下斜、平板 | Incline, Decline, Flat |

**省略規則**：
- 雙手/雙腳（預設）→ 省略
- 站姿（部分動作預設）→ 可省略
- 正握（部分動作預設）→ 可省略
- 平板（臥推預設）→ 可省略

**範例**：
| 完整規格 | 標準名稱 |
|---------|---------|
| 單手 + 俯身 + 寬握 | 單手俯身寬握啞鈴划船 |
| 交替 + 上斜 | 交替上斜啞鈴臥推 |
| 坐姿 + 窄握 | 坐姿窄握纜繩划船 |

#### 4.1.2 器材（Equipment）

使用的**主要負重工具**。

| 器材 | 中文 | 英文 |
|------|------|------|
| barbell | 槓鈴 | Barbell |
| dumbbell | 啞鈴 | Dumbbell |
| kettlebell | 壺鈴 | Kettlebell |
| cable | 纜繩 | Cable |
| machine | 固定式機械 | Machine |
| bodyweight | 徒手 | Bodyweight |
| smith_machine | 史密斯機 | Smith Machine |
| suspension | 懸吊 | Suspension |
| resistance_band | 彈力帶 | Resistance Band |
| landmine | 地雷管 | Landmine |

#### 4.1.3 輔助器材與場地需求

**輔助器材不放在名稱中**，改放在「說明欄位」描述：

| 動作 | 器材欄位 | 說明欄位 |
|------|---------|---------|
| 槓鈴臥推 | barbell | 需要臥推架、平板凳 |
| 雙槓撐體 | bodyweight | 需要雙槓或撐體架 |
| 引體向上 | bodyweight | 需要單槓 |
| 啞鈴飛鳥 | dumbbell | 需要平板凳或上斜凳 |
| 箱跳 | bodyweight | 需要跳箱 |

#### 4.1.4 動作（Exercise）

核心動作名。
*   *詞彙*: Bench Press（臥推）, Squat（深蹲）, Row（划船）, Curl（彎舉）, Press（推舉）, Deadlift（硬舉）, Fly（飛鳥）, Extension（伸展）。

### 4.2 實例對照

| 原名稱 (Bad) | 標準化名稱 (Canonical Name) | 命名邏輯 | 別名 (Aliases) |
|--------------|-----------------------------|----------|----------------|
| DB Bench | **Flat Dumbbell Bench Press** | 補全角度(Flat)與全名。 | DB Bench, 胸推 |
| Skullcrushers | **Lying EZ-Bar Triceps Extension** | 移除俚語，描述本質。 | Skullcrushers, French Press |
| Lat Pulldowns | **Wide Grip Cable Lat Pulldown** | 指定器材與握距。 | 滑輪下拉, 背部下拉 |
| TRX Row | **Suspension Row** | 移除品牌名，使用通用器材。 | TRX Row, Ring Row |
| RDL | **Barbell Romanian Deadlift** | 展開縮寫，明確器材。 | RDL, 羅馬尼亞硬舉 |

### 4.3 命名 Edge Cases

以下是在人工分類過程中確立的特殊規則：

#### 4.3.1 單邊動作與握距

| 情境 | 規則 | 理由 |
|------|------|------|
| **Single Arm 動作省略「Narrow Grip」** | ✅ 省略 | 單手操作沒有「雙手間距」概念，預設就是自然握法 |
| **Wide Grip 需明確標示** | ✅ 保留 | 寬握（手肘外展）改變了力學，需區分 |

#### 4.3.2 肩胛 vs 肩關節

| 原始輸入 | 修正後 | 理由 |
|----------|--------|------|
| 「胛內旋 / 胛外旋」 | **肩內旋 / 肩外旋** | 實際旋轉的是肱骨（肩關節），不是肩胛骨 |
| 「Scapular Rotation」 | **Shoulder Rotation** | 肩胛骨旋轉是翼狀肩胛，這不是訓練目標 |

#### 4.3.3 姿勢命名標準化

| 中文 | 英文 | 定義 |
|------|------|------|
| 半跪姿 | Half Kneeling | 單膝跪地，另一腳踩地 |
| 高跪姿 | Tall Kneeling | 雙膝跪地 |
| 俯身 | Bent Over | 髖關節屈曲，軀幹前傾 |
| 弓箭步 | Lunge Stance | 前後腳分開站立 (靜態) |

#### 4.3.4 預設省略規則

| 情境 | 是否省略 | 範例 |
|------|----------|------|
| Bent Over + Parallel Stance | ✅ 省略 Stance | 「俯身啞鈴划船」而非「平行步俯身划船」 |
| Standing + Two Arm | ❌ 保留 | 「站姿槓鈴彎舉」 (Explicit Preferred) |
| Seated（坐姿）| ❌ 保留 | 「坐姿啞鈴肩推」 (Always Explicit) |

#### 4.3.5 器材關鍵字對照

| 關鍵字 | 對應 Equipment ID |
|--------|-------------------|
| `band`, `彈力帶` | `resistance_band` |
| `cable`, `纜繩` | `cable` |
| `TRX`, `懸吊` | `suspension` |
| `pulley`, `半固定器材` | `cable` |
| `landmine`, `地雷管` | `landmine` |

---

## 5. 審核作業

### 5.1 審核目標與檢查清單

審核檔案：`scripts/review_data/by_muscle_grouped/*.csv`（781 筆，20 個檔案）

#### 單一動作審核檢查清單

每個動作需確認以下 12 項：

| # | 項目 | 檢查內容 |
|---|------|---------|
| 1 | **中文名稱** | 符合 SEE 格式：[單雙側]-[姿勢]-[握法]-[角度]-[器材]-[動作] |
| 2 | **英文名稱** | 符合 SEE 格式，與中文對應 |
| 3 | **別名** | 只包含「角度 + 器材 + 動作」，省略單雙側/交替/握距 |
| 4 | **動作模式** | 是否正確涵蓋所有適用的模式 |
| 5 | **PPL 標籤** | Push/Pull/Legs 是否都考慮到 |
| 6 | **主動肌** | 符合 `ref_muscle_groups.json` 的 25 個有效值 |
| 7 | **協同肌** | 是否正確包含輔助肌群（需附中文說明）|
| 8 | **器材** | 是否符合動作使用的器材類型 |
| 9 | **複合/孤立** | compound（多關節）或 isolation（單關節）|
| 10 | **單邊** | 單側動作標記 TRUE，雙側標記 FALSE |
| 11 | **難度** | beginner / intermediate / advanced |
| 12 | **is_explosive** | 爆發力動作是否標記為 TRUE |

#### 審核流程

```
1. 按肌群分割檔案審核（by_muscle_grouped/）
2. 每個檔案逐筆檢查上述 12 項
3. 修改原始 exercises_review.csv
4. 重新執行分割腳本驗證
5. 完成後標記該肌群 ✅
```

### 5.2 審核進度

| 肌群 | 筆數 | 狀態 | 說明 |
|------|------|------|------|
| pecs (胸) | 105 | ✅ 已完成 | SEE 命名、組合補齊（+4 筆）、器材修正、全面自動化驗證 0 錯誤 |
| delts (肩) | 129 | ✅ 已完成 | 見下方 delts 審核摘要 |
| lats (背闘肌) | 116 | ✅ 已完成 | 見下方 lats 審核摘要 |
| quads (股四頭) | 127 | ✅ 已完成 | 見下方 quads 審核摘要 |
| core (核心) | 71 | ✅ 已完成 | 見下方 core 審核摘要 |
| hamstrings (腿後) | 60 | ✅ 已完成 | 見下方 hamstrings 審核摘要 |
| triceps (三頭) | 47 | ✅ 已完成 | isolation_upper→isolation_push、synergist細化、別名規範化 |
| glutes (臀) | 38 | ✅ 已完成 | power/plyometric→hinge/lunge/vertical_pull、synergist規範化、別名"/"移除、刪除重複機械髖外展 |
| biceps (二頭) | 20 | ✅ 已完成 | isolation_upper→isolation_pull、synergist規範化、別名規範化、傳教士→牧師統一 |
| traps (斜方) | 17 | ✅ 已完成 | power/olympic→hinge、PPL移除upper、synergist規範化、別名路徑移除 |
| back_general | 10 | ✅ 已完成 | back→lats/traps細化、mobility補PPL、TRX品牌名移除、別名規範化 |
| calves (小腿) | 9 | ✅ 已完成 | isolation_lower→isolation_hinge、gastrocnemius/soleus→calves、PPL補mobility |
| rotator_cuff | 8 | ✅ 已完成 | rotation括號子類移除、infraspinatus/subscapularis→rotator_cuff、單臂規格補充 |
| adductors (內收肌) | 5 | ✅ 已完成 | isolation_lower→isolation_hinge、core→abs、PPL補mobility |
| erector_spinae (豎脊肌) | 5 | ✅ 已完成 | glute_max→glutes、anti_flexion→anti_extension、PPL補mobility |
| upper_back (上背) | 4 | ✅ 已完成 | upper_back→rhomboids、isolation_upper→isolation_pull、lower_back→erector_spinae |
| forearms (前臂) | 3 | ✅ 已完成 | isolation_upper→isolation_pull、grip→forearms(主動肌)、core→abs |
| hip_flexors (髖屈肌) | 3 | ✅ 已完成 | 高跪姿→半跪姿、PPL補mobility、別名中英文補充 |
| serratus_anterior (前鋸肌) | 1 | ✅ 已完成 | isolation_upper→isolation_push、core→abs |
| tibialis_anterior (脛前肌) | 1 | ✅ 已完成 | Shins→Tibialis Anterior、PPL補mobility、別名補充 |

**總筆數**：779 筆（20 個檔案）｜**已完成**：779 筆（20/20 檔案）✅

#### 最終審核結果摘要

| 項目 | 結果 |
|------|------|
| 動作模式 | ✅ 全部符合 v2 規範 |
| PPL 標籤 | ✅ 全部有效（無 upper/lower）|
| 主動肌 | ✅ 全部符合 25 個有效值 |
| 協同肌 | ✅ 全部規範化 |
| 別名 | ✅ 全部有中英文、無斜線 |
| is_explosive | ✅ 88 筆爆發力動作已標記 |
| 重複資料 | ✅ 已移除 1 筆重複（機械髖外展）|

**輸出檔案**：`scripts/review_data/exercises_review_audited.csv`

#### lats (背闊肌) 審核摘要

| 類別 | 修正內容 |
|------|----------|
| PPL 標籤 | 全面移除 `upper`（116 筆）；弓箭步划船保留 `pull, legs`；anti_rotation 動作加 `core` |
| SEE 命名順序 | 單雙側(1)→姿勢(2) 修正約 30+ 筆（如 俯身單臂→單臂俯身）|
| 別名規範化 | 省略單雙側/交替/握距/姿勢、移除括號條件、補充中英文別名（全面修正）|
| Narrow Grip 移除 | 交替/單臂動作省略窄握（~8 筆，如 ROW 73, 81, 97）|
| 高跪姿翻譯修正 | Half Kneeling → Tall Kneeling（ROW 110, 113, 115 原名高跪式=雙膝跪地）|
| 坐姿補充 | 坐姿下拉補加 Seated（ROW 75, 78，SEE 規則 Seated 永遠保留）|
| 動作模式 | 弓箭步划船移除 hinge/lunge（ROW 68-73，弓箭步為姿勢非動作模式）|
| Pullover 系列 | vertical_pull → isolation_pull（ROW 106）；Straight Arm Pulldown 統一 isolation_pull |
| 協同肌 | 下拉動作補 biceps；Pullover 動作 rhomboids → serratus_anterior；Pull-Up 補 teres_major |
| Chin Up 中文 | 加「反手」對應英文 Chin Up（ROW 98, 101, 103）|
| Side Plank Row | 補 單臂/Single Arm（ROW 31-35）|

#### quads (股四頭) 審核摘要

| 類別 | 修正內容 |
|------|----------|
| 動作模式 v2 轉換 | `isolation_lower` → `isolation_squat`（ROW 107-109）；`plyometric` → `squat`（ROW 117-124）；`power` → `hinge/squat`（ROW 102-103, 125-127）|
| Split Squat/Bulgarian | `squat` → `lunge`（~25 筆分腿蹲/保加利亞分腿蹲皆歸為 lunge 模式）|
| PPL 移除 push | Overhead 動作移除 push（等距持 holding 非主動推，~12 筆）|
| 協同肌修正 | `core` → `abs`（全面修正 ~50 筆）；`shoulders` → `front_delts/side_delts`（~15 筆）；`grip` → `forearms`；`upper_back` → `traps/rhomboids/erector_spinae`；`lower_back` → `erector_spinae` |
| 史密斯→史密斯機 | 器材全名修正（ROW 20, 25, 36, 48, 51, 60）|
| SEE 順序修正 | 交替(單雙側)應在前架式(握法)/過頂(角度)之前（~10 筆，如 ROW 18, 23, 58, 63, 65, 67, 68）|
| 別名規範化 | 移除斜線"/"格式（ROW 101-105, 117-122）；移除括號條件"(Assisted)"等（ROW 37, 39, 43, 59）；省略交替/單雙側；補充英文別名（全面修正）|
| 中文用字修正 | 深蹲上博→深蹲上搏（ROW 125-126）|
| is_explosive 標記 | plyometric/power 動作皆改為 TRUE（ROW 102-103, 117-127）|

#### core (核心) 審核摘要

| 類別 | 修正內容 |
|------|----------|
| 動作模式 v2 轉換 | `core_anti_lateral` → `anti_lateral`；`core_anti_rotation` → `anti_rotation`；`core_flexion` → `flexion`；`core_rotation` → `rotation`；`anti_flexion` → `anti_extension`；`lateral_flexion` → `anti_lateral/flexion`；`isolation_upper` → `isolation_push`（ROW 51）|
| 主動肌修正 | `core` → `abs/obliques`（全面修正 ~40 筆）；`rectus_abdominis` → `abs`（ROW 62-63）|
| 協同肌修正 | `core` → `abs`；`shoulders` → `front_delts`；`spine` → `erector_spinae`；`arms` → `triceps/forearms`；`back` → `lats/erector_spinae`；`quadratus_lumborum` → `obliques/erector_spinae`；`transverse_abdominis` → `abs`；`glute_medius` → `glutes` |
| PPL 修正 | 空白補 `core/mobility`；移除 `push/upper/pull`（ROW 20）；`cardio` 補加 `core`（ROW 69）|
| 別名規範化 | 移除斜線"/"格式（~15 筆）；移除括號"()"格式（ROW 41, 52, 54）；補充中英文別名（全面修正）|
| SEE 命名修正 | 高跪姿→半跪姿（Half Kneeling 修正 ROW 22）；移除 TRX 品牌名（ROW 21, 32）|
| 拼寫修正 | 帕洛夫→帕羅夫（Pallof 統一 ROW 14, 22）|
| is_explosive 欄位 | 新增欄位；power 動作標記 TRUE（ROW 62-63, 71-72）|
| 重複資料 | ROW 46/50、ROW 68/69 重複（已修正欄位但保留 ID）|

#### hamstrings (腿後肌) 審核摘要

| 類別 | 修正內容 |
|------|----------|
| 動作模式 v2 轉換 | `isolation_lower` → `isolation_hinge`（ROW 44-55 腿彎舉系列）；`core_rotation` → `rotation`（ROW 42）；`power` / `power, pull` / `power, vertical_push` → `hinge` / `hinge, vertical_push`（ROW 58-60）|
| 協同肌修正 | `grip` → `forearms`（ROW 41）；`glute_max` → `glutes`（ROW 43-49）；`core` → `abs`（ROW 44-49, 58-60）；`shoulders` → `front_delts`（ROW 59-60）；`back` → `lats`（ROW 60）|
| PPL 修正 | 空白補 `mobility`（ROW 55-57）；Snatch 補加 `push`（ROW 60）|
| 別名規範化 | 移除斜線"/"格式（ROW 55-56）；省略單雙側/交替（ROW 45-53）；補充中英文別名（全面修正 ~20 筆）|
| is_explosive 確認 | power 動作維持 TRUE（ROW 58-60 已正確標記）|

#### delts (肩) 審核摘要

| 類別 | 修正內容 |
|------|----------|
| 主動肌細化 | shoulders → front_delts / side_delts / rear_delts（34 筆）|
| PPL 規範變更 | side_delts 雙標 `push, pull`（19 筆）— 力學為拉但常排 Push Day |
| 動作模式 | 側平舉 `isolation_push` → `isolation_pull`（11 筆）|
| SEE 命名 | 去多餘站姿（4 筆）、加單手（1 筆）、加器材名（6 筆）|
| 別名規範化 | 省略交替/單雙側/姿勢、補充中英文別名（12 筆）|
| 協同肌 | 直立划船統一 +front_delts（6 筆）、側平舉去 front_delts（1 筆）|
| 其他 | 重複 TGU 合併（-1 筆）、弓箭步命名區分、跨體肩部伸展主動肌→rear_delts |

### 5.3 審核完成標準

- [x] 所有動作模式都符合 `ref_movement_patterns.json` 的有效值
- [x] 所有主動肌都符合 `ref_muscle_groups.json` 的 25 個有效值
- [x] 所有爆發力動作都標記 `is_explosive = TRUE`（88 筆）
- [x] PPL 標籤與動作邏輯一致（無 upper/lower，全部有值）
- [x] 中英文命名符合 SEE 格式
- [x] 所有別名都有中英文版本

### 5.4 批量修正項目

| # | 項目 | 說明 |
|---|------|------|
| 1 | **動作模式轉換** | 見 Section 2.2.1 轉換對照表 |
| 2 | **主動肌細化** | 見 Section 2.4 細化對照表 |
| 3 | **is_explosive 確認** | 原 power/plyometric 動作已標記，需確認並補漏 |

---

## 6. 實作計劃 (Implementation Plan)

### Phase 1: 資料庫準備 ✅
- [x] 1.1 定義動作模式階層 (Ref Data)
- [x] 1.2 定義肌肉群清單 (Ref Data)
- [x] 1.3 定義器材清單 (Ref Data)

### Phase 2: 資料審計與工具開發 ✅
- [x] 2.1 匯出現有動作資料
- [x] 2.2 開發 `generate_review_csv.py` 自動推斷初步標籤
- [x] 2.3 產出審核用 CSV 模板

### Phase 3: 人工重命名與標籤化 ✅ (已完成 — 20/20 檔案)
針對每個動作執行以下 SOP（欄位順序與 CSV 一致）：

| 順序 | 欄位 | 說明 |
|------|------|------|
| 1 | **建議中文名** | SEE 格式（如：上斜啞鈴臥推）|
| 2 | **建議英文名** | SEE 格式（如：Incline Dumbbell Bench Press）|
| 3 | **別名** | 俚語/縮寫/舊名稱（逗號分隔）|
| 4 | **動作模式** | 可複選（如：horizontal_push）|
| 5 | **PPL 標籤** | 可複選（如：push, upper）|
| 6 | **主動肌** | 唯一一個 Primary muscle（不可多選）|
| 7 | **協同肌** | Secondary muscles（逗號分隔）|
| 8 | **器材** | 單選（如：dumbbell, cable）|
| 9 | **複合/孤立** | compound / isolation |
| 10 | **單邊** | true / false |
| 11 | **難度** | beginner / intermediate / advanced |

### Phase 4: 驗證與匯入 (待執行 📋)
- [ ] 4.1 建立 UUID 映射 (Legacy ID -> New UUID)
- [ ] 4.2 匯入清洗後的資料至新 Schema
- [ ] 4.3 App 端搜尋邏輯更新 (支援 Alias 搜尋)
- [ ] 4.4 實作動態篩選器 UI

---

## 7. 搜尋系統設計

### 7.1 設計原則

> **關鍵洞察**：模糊搜尋只需針對「名稱相關欄位」設計，其他欄位（movement_patterns、ppl_tags、equipment 等）作為「精確篩選條件」，不納入模糊搜尋。

### 7.2 模糊搜尋欄位（僅 5 個）

| 欄位 | 說明 | 權重 | 搜尋策略 |
|------|------|------|----------|
| `name` | 中文名 | 0.30 | Jaro-Winkler 前綴匹配 |
| `name_en` | 英文名 | 0.25 | Jaro-Winkler 前綴匹配 |
| `canonical_name` | SEE 標準中文名 | 0.20 | Jaro-Winkler |
| `canonical_name_en` | SEE 標準英文名 | 0.15 | Jaro-Winkler |
| `aliases` | 別名陣列 | 0.10 | Trigram 重疊 |

### 7.3 Hive 離線搜尋架構

**目標**：動作資料快取到本地 Hive 後，用戶離線時仍能進行模糊搜尋

**存儲策略**：

```
exercises_cache Box（現有）：
├── all_exercises            → 完整動作物件列表（含 v2 欄位）
├── cache_version            → 快取版本號
└── last_update              → 上次更新時間

exercises_search_index Box（新增）：
├── trigram_index            → Map<String, Set<String>>
│   └── {"squ": ["id1","id2"], "qua": ["id1"], ...}
├── pinyin_full_index        → Map<String, Set<String>>
│   └── {"shenqun": ["id1"], "wotui": ["id2"], ...}
├── pinyin_initials_index    → Map<String, Set<String>>
│   └── {"sq": ["id1"], "wt": ["id2"], ...}
└── index_version            → 索引版本號
```

**v2 欄位儲存**：

```dart
// saveExercises 新增欄位
{
  // ... 現有欄位
  'canonical_name': e.canonicalName,
  'canonical_name_en': e.canonicalNameEn,
  'movement_patterns': e.movementPatterns,
  'ppl_tags': e.pplTags,
  'primary_muscle': e.primaryMuscle,
  'synergist_muscles': e.synergistMuscles,
  'mechanics_type': e.mechanicsType,
  'is_unilateral': e.isUnilateral,
  'difficulty_level': e.difficultyLevel,
  'is_explosive': e.isExplosive,
  'aliases': e.aliases,
}
```

**索引建構時機**：
- App 首次啟動時從 Supabase 同步
- 快取版本升級時重建索引
- 使用 `compute()` 在 Isolate 中處理避免 UI 卡頓

### 7.4 相關度排序演算法

```dart
// 權重得分公式：S = Σ(wi × si)
double _calculateRelevanceScore(Exercise e, String query) {
  // 完全匹配（精確比對）→ 100 分
  if (e.name.toLowerCase() == query) return 100.0;
  if (e.nameEn.toLowerCase() == query) return 95.0;
  if (e.canonicalName?.toLowerCase() == query) return 90.0;

  // 開頭匹配（前綴比對）→ 80 分
  if (e.name.toLowerCase().startsWith(query)) return 80.0;
  if (e.nameEn.toLowerCase().startsWith(query)) return 75.0;

  // 別名匹配 → 70 分
  for (final alias in e.aliases) {
    if (alias.toLowerCase() == query) return 70.0;
    if (alias.toLowerCase().startsWith(query)) return 65.0;
  }

  // 部分匹配（包含）→ 50 分
  if (e.name.toLowerCase().contains(query)) return 50.0;
  if (e.nameEn.toLowerCase().contains(query)) return 45.0;

  return 40.0; // 其他匹配
}
```

### 7.5 進階篩選 vs 文字搜尋

| 功能 | 用途 | 實現方式 |
|------|------|----------|
| **文字搜尋** | 找特定動作 | 名稱/別名模糊匹配（5 欄位）|
| **進階篩選** | 縮小範圍 | 精確屬性匹配（movement_patterns、ppl_tags 等）|

**組合使用範例**：
```
搜尋「臥推」+ 篩選 [equipment=dumbbell] + 篩選 [ppl=push]
→ 只顯示啞鈴推類臥推動作
```

### 7.6 效能優化策略

| 技術 | 用途 | 實作方式 |
|------|------|----------|
| **Isolate 並行** | 避免 UI 卡頓 | `compute()` 處理相似度計算 |
| **防抖動** | 減少計算次數 | 300-500ms debounce |
| **Trigram 索引** | 加速模糊匹配 | 預建構 N-Gram 索引 |
| **長度啟發式** | 過濾候選 | 僅比對長度差 ≤2 的字串 |

### 7.7 中英混合搜尋

| 輸入類型 | 處理方式 |
|---------|---------|
| 中文 | 直接匹配 + 分詞（可選：結巴分詞）|
| 英文 | 小寫正規化 + Trigram |
| 拼音 | 全拼/首字母索引（索引預建構）|

### 7.8 v5.0 完整實作範圍

| 模組 | 實作內容 |
|------|---------|
| **Hive 持久化** | 動作資料本地快取 + 搜尋索引 Box |
| **Trigram 索引** | 預建構 N-Gram 索引支援模糊匹配 |
| **Isolate 並行** | `compute()` 處理相似度計算 |
| **權重排序** | 5 欄位加權評分演算法 |
| **拼音索引** | 全拼/首字母搜尋支援 |

**不分版本，v5.0 一次實作完整離線模糊搜尋功能。**

---

## 8. 結論

本次重設計從根本上改變了健身數據的組織方式。透過引入 **多維度關聯架構** 與 **SEE 命名標準**，我們不僅解決了當前的搜尋痛點，更為未來的高級功能（如智慧課表生成、動作推薦）奠定了堅實的基礎。雖然人工介入成本較高，但這是建立高品質 Dataset 的必要投資。

---

## 附錄 A：檔案路徑與工具說明

### A.1 關鍵檔案位置

| 用途 | 路徑 |
|------|------|
| **本文件** | `docs/planning/EXERCISE_CLASSIFICATION_ANALYSIS.md` |
| **CSV 產出腳本** | `scripts/generate_review_csv.py` |
| **動作模式參照表** | `scripts/reference_data/ref_movement_patterns.json` |
| **肌肉群參照表** | `scripts/reference_data/ref_muscle_groups.json` |
| **器材參照表** | `scripts/reference_data/ref_equipment.json` |
| **產出的待審核 CSV** | `scripts/review_data/exercises_review.csv` |

### A.2 腳本使用方式

```bash
cd scripts
python generate_review_csv.py
```

執行後會：
1. 載入現有動作資料
2. 自動推斷初步分類標籤
3. 輸出 `exercises_review.csv` 供人工審核

---

## 附錄 B：相關文件

| 文件 | 說明 |
|------|------|
| `EXERCISE_CLASSIFICATION_DISCUSSIONS.md` | 討論紀錄、分析報告、研究資料 |
| `scripts/review_data/exercises_review.csv` | 待審核 CSV 主檔 |
| `scripts/review_data/by_muscle_grouped/*.csv` | 按肌群分割的審核檔案 |
| `scripts/reference_data/ref_muscle_groups.json` | 肌群參照表 |
| `scripts/reference_data/ref_movement_patterns.json` | 動作模式參照表 |
