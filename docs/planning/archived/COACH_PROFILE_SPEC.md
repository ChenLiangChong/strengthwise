# 教練公開檔案規劃 (v2.9)

> 臨時規劃文檔 - 基於雙邊市集架構分析報告

**建立日期**：2026-01-04  
**目標**：讓擁有教練身份的用戶填寫專業資料  
**設計原則**：所有欄位一次建立，v2.9 只實作文字部分

---

## 📐 1:1 關聯說明

```
users 表                       coaches 表
┌────────────────────┐        ┌────────────────────┐
│ id: ABC-123        │───1:1──│ id: ABC-123        │ ← 共用同一個 UUID
│ display_name       │        │ display_name       │
│ bio (個人自介)      │        │ bio (專業介紹)      │
│ is_coach: true     │        │ headline           │
└────────────────────┘        └────────────────────┘

• 一個 user 最多對應一個 coach 記錄
• 一個 coach 必定對應一個 user
• 不是所有 user 都有 coach（只有教練才有）
```

**兩個 Bio 的區別**：

| 欄位 | 位置 | 用途 | 範例 |
|------|------|------|------|
| `users.bio` | 個人資料 | 自我介紹（所有用戶） | 「喜歡健身和閱讀」 |
| `coaches.bio` | 教練檔案 | 專業背景介紹 | 「10 年健身產業經驗，專精產後恢復...」 |

---

## 🗄️ 資料庫設計

### SQL Schema（完整版，含未來欄位）

```sql
-- migrations/025_coaches_table.sql

-- 未來：啟用 PostGIS 地理位置搜尋
-- CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE public.coaches (
  -- ========== 主鍵（1:1 關聯） ==========
  id uuid REFERENCES public.users(id) ON DELETE CASCADE PRIMARY KEY,
  
  -- ========== v2.9 實作：身份與品牌 ==========
  display_name text,                    -- 顯示名稱（可與真名不同）
  headline text,                        -- 專業頭銜（max 160 chars）
  bio text,                             -- 專業介紹
  
  -- ========== v2.9 實作：專長標籤 ==========
  specialties jsonb DEFAULT '[]'::jsonb,
  -- 範例：["weight_loss", "strength_conditioning", "senior_fitness"]
  
  -- ========== v2.9 實作：證照 ==========
  certifications jsonb DEFAULT '[]'::jsonb,
  -- 範例：[{"org": "NASM", "name": "CPT", "year": 2020}]
  
  -- ========== v2.9 實作：經歷 ==========
  years_experience int DEFAULT 0,
  
  -- ========== v2.9 實作：語言能力 ==========
  languages jsonb DEFAULT '["zh-TW"]'::jsonb,
  -- 範例：["zh-TW", "en"]
  
  -- ========== 未來計劃：服務資訊 ==========
  service_types jsonb DEFAULT '[]'::jsonb,
  -- 範例：["in_person", "online", "hybrid", "group_class"]
  
  hourly_rate_min int,                  -- 最低時薪
  hourly_rate_max int,                  -- 最高時薪
  currency text DEFAULT 'TWD',          -- 幣別
  offers_free_consultation boolean DEFAULT false,  -- 免費諮詢
  
  weekly_availability jsonb DEFAULT '{}'::jsonb,
  -- 範例：{"mon": ["morning", "evening"], "sat": ["morning"]}
  
  -- ========== 未來計劃：地理位置（PostGIS） ==========
  -- location geography(POINT),         -- 需先啟用 PostGIS
  location_lat double precision,        -- 暫用：緯度
  location_lng double precision,        -- 暫用：經度
  service_radius_km int,                -- 服務半徑
  gym_access text,                      -- 合作健身房
  
  -- ========== 未來計劃：審核機制 ==========
  verified_status text DEFAULT 'pending',  -- pending, verified, rejected
  slug text UNIQUE,                     -- URL slug: /coach/unique-slug
  
  -- ========== 未來計劃：評價統計（快取） ==========
  average_rating numeric(3,2) DEFAULT 0,
  review_count int DEFAULT 0,
  
  -- ========== 未來計劃：媒體 ==========
  gallery_images jsonb DEFAULT '[]'::jsonb,  -- 教學案例照片
  social_links jsonb DEFAULT '{}'::jsonb,    -- 社群連結
  
  -- ========== 時間戳 ==========
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ========== RLS 政策 ==========
ALTER TABLE public.coaches ENABLE ROW LEVEL SECURITY;

-- v2.9：教練可以讀取自己的資料
CREATE POLICY "Coaches can view own profile"
  ON public.coaches FOR SELECT
  USING (auth.uid() = id);

-- v2.9：教練可以更新自己的資料
CREATE POLICY "Coaches can update own profile"
  ON public.coaches FOR UPDATE
  USING (auth.uid() = id);

-- v2.9：教練可以建立自己的資料
CREATE POLICY "Coaches can insert own profile"
  ON public.coaches FOR INSERT
  WITH CHECK (auth.uid() = id);

-- 未來計劃：公開搜尋（需先有審核機制）
-- CREATE POLICY "Public profiles are viewable"
--   ON public.coaches FOR SELECT
--   USING (verified_status = 'verified');

-- ========== 未來計劃：搜尋索引 ==========
-- CREATE INDEX idx_coaches_specialties ON public.coaches USING GIN (specialties);
-- CREATE INDEX idx_coaches_location ON public.coaches USING GIST (location);
-- CREATE INDEX idx_coaches_fts ON public.coaches USING GIN (fts);

-- ========== updated_at 觸發器 ==========
CREATE TRIGGER set_coaches_updated_at
  BEFORE UPDATE ON public.coaches
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();
```

---

## 📋 欄位分類總覽

### ✅ v2.9 實作（純文字）

| 欄位 | 類型 | 說明 | 必填 |
|------|------|------|------|
| `display_name` | text | 顯示名稱/品牌名 | ✅ |
| `headline` | text(160) | 專業頭銜（一句話描述） | ❌ |
| `bio` | text | 專業介紹（詳細背景） | ✅ |
| `specialties` | jsonb | 專長標籤（預定義 + 自定義，最多 8 個） | ✅ |
| `certifications` | jsonb | 證照列表（一次新增一個） | ❌ |
| `years_experience` | int | 從業年資 | ❌ |
| `languages` | jsonb | 語言能力 | ❌ |

### 📺 顯示場景

| 場景 | 頁面 | 權限 |
|------|------|------|
| 學員查看教練 | 學員中心 → 教練詳情頁 | 只讀 |
| 教練查看自己 | 個人頁面 → 教練檔案 | 可編輯 |

### ⏳ 未來計劃：服務資訊

| 欄位 | 類型 | 說明 |
|------|------|------|
| `service_types` | jsonb | 服務模式（線上/線下/混合） |
| `hourly_rate_min` | int | 最低時薪 |
| `hourly_rate_max` | int | 最高時薪 |
| `currency` | text | 幣別 |
| `offers_free_consultation` | boolean | 是否提供免費諮詢 |
| `weekly_availability` | jsonb | 每週可預約時段 |

### ⏳ 未來計劃：地理位置

| 欄位 | 類型 | 說明 |
|------|------|------|
| `location_lat` | double | 緯度（暫用，未來改 PostGIS） |
| `location_lng` | double | 經度 |
| `service_radius_km` | int | 服務半徑 |
| `gym_access` | text | 合作健身房 |

### ⏳ 未來計劃：審核與市集

| 欄位 | 類型 | 說明 |
|------|------|------|
| `verified_status` | text | 審核狀態（pending/verified/rejected） |
| `slug` | text | URL 專屬連結 |
| `average_rating` | numeric | 平均評分（快取） |
| `review_count` | int | 評價數量（快取） |

### ⏳ 未來計劃：媒體

| 欄位 | 類型 | 說明 |
|------|------|------|
| `gallery_images` | jsonb | 教學案例照片 |
| `social_links` | jsonb | 社群連結（IG、FB、YouTube） |

---

## 📝 專長標籤系統

### 設計邏輯

- **預定義標籤**：從清單選擇（快速、一致）
- **自定義標籤**：教練可新增自己的專長（靈活）
- **上限**：最多 8 個標籤（預定義 + 自定義合計）

### 儲存格式（JSONB）

```json
// 預定義標籤用 key，自定義標籤用 "custom:" 前綴
["weight_loss", "strength_conditioning", "custom:TRX懸吊訓練", "custom:孕婦瑜伽"]
```

### 預定義標籤清單

```dart
enum CoachSpecialty {
  // 體態管理
  weightLoss,           // 減重
  hypertrophy,          // 增肌
  bodyRecomposition,    // 體態雕塑
  bodybuildingPrep,     // 健美備賽
  
  // 運動表現
  strengthConditioning, // 肌力與體能
  olympicLifting,       // 舉重
  powerlifting,         // 力量舉
  marathonTraining,     // 馬拉松訓練
  golfFitness,          // 高爾夫體能
  
  // 特殊族群
  seniorFitness,        // 銀髮族體適能
  prePostNatal,         // 產前/產後訓練
  youthFitness,         // 青少年體適能
  
  // 健康矯正
  correctiveExercise,   // 矯正運動
  lowerBackPain,        // 下背痛管理
  postRehab,            // 傷後回歸
  diabetesManagement,   // 糖尿病運動管理
  
  // 身心靈
  yoga,                 // 瑜伽
  pilates,              // 彼拉提斯
  functionalTraining,   // 功能性訓練
  kettlebell,           // 壺鈴
}
```

### 證照列表結構（JSONB）

```json
// 一次新增一個證照，結構化儲存
[
  {"org": "NASM", "name": "CPT", "year": 2020},
  {"org": "ACE", "name": "健身教練", "year": 2018},
  {"org": "其他", "name": "紅十字會急救證", "year": 2022}
]
```

---

## 🎨 UI 設計（v2.9）

### 填寫流程（Stepper - 2 步驟）

```
Step 1: 基本資料
├── 顯示名稱（品牌名）  ← 必填
├── 專業介紹            ← 必填（詳細背景）
└── 專業頭銜            ← 選填（一句話描述）

Step 2: 專業背景
├── 專長選擇            ← 必填（預定義 + 自定義，1-8 個）
├── 證照列表            ← 選填（一次新增一個）
├── 從業年資            ← 選填
└── 語言能力            ← 選填

→ 確認送出
```

### 入口點

- 教練首次開通時：強制引導填寫
- 設定頁面：「編輯教練檔案」按鈕

---

## 📁 檔案規劃

```
lib/
├── models/
│   ├── coach_profile_model.dart
│   └── coach_specialty.dart          # Enum
├── services/
│   ├── interfaces/
│   │   └── coach_profile_service_interface.dart
│   └── supabase/
│       └── coach_profile_service_supabase.dart
├── controllers/
│   └── coach_profile_controller.dart
└── views/
    └── pages/
        └── profile/
            └── coach_profile_form_page.dart   # 多步驟表單
    └── widgets/
        └── coach/
            ├── specialty_tag_selector.dart    # 標籤選擇器
            └── certification_form.dart        # 證照表單
```

---

## 📋 開發任務清單

### v2.9 實作

| # | 類型 | 任務 | 狀態 |
|---|------|------|------|
| DB-1 | Migration | `025_coaches_table.sql`（含所有欄位） | ⏳ |
| M-1 | Model | `coach_profile_model.dart` | ⏳ |
| M-2 | Model | `coach_specialty.dart` Enum（20 項） | ⏳ |
| S-1 | Service | `coach_profile_service_interface.dart` | ⏳ |
| S-2 | Service | `coach_profile_service_supabase.dart` | ⏳ |
| C-1 | Controller | `coach_profile_controller.dart` | ⏳ |
| UI-1 | Page | `coach_profile_form_page.dart`（2 步驟） | ⏳ |
| UI-2 | Widget | `specialty_tag_selector.dart` | ⏳ |
| UI-3 | Widget | `certification_form.dart` | ⏳ |
| INT-1 | 整合 | 教練開通時引導填寫 | ⏳ |
| INT-2 | 整合 | 設定頁面新增入口 | ⏳ |

### 未來計劃

| # | 類型 | 任務 |
|---|------|------|
| FUT-1 | DB | 啟用 PostGIS + location 欄位 |
| FUT-2 | DB | 建立 GIN/GIST 搜尋索引 |
| FUT-3 | Backend | Edge Functions 審核流程 |
| FUT-4 | UI | 服務資訊表單 |
| FUT-5 | UI | 圖片上傳（gallery_images） |
| FUT-6 | Feature | 公開搜尋頁面 |
| FUT-7 | Feature | 評價系統 |

---

## ⚠️ 注意事項

1. **與現有 `users` 的關係**
   - `coaches.id` = `users.id`（1:1 關聯）
   - 不修改現有 `users` 表結構

2. **角色判斷**
   - 仍使用 `users.is_coach` 判斷是否為教練
   - `coaches` 表存在記錄 = 已填寫教練檔案

3. **RLS 政策**
   - v2.9：僅教練自己可見/編輯
   - 未來：verified 的教練可被公開搜尋
