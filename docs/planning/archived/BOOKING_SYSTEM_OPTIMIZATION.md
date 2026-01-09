# 預約系統優化規劃 (v3.0)

> 基於「StrengthWise 平台架構優化與交互流程深度研究報告」制定

**建立日期**：2026-01-05  
**目標版本**：v3.0（預約系統大改版 + v2.9.1 合併）  
**設計原則**：資料庫層級剛性約束 + 前端層級彈性預測  
**平台策略**：Android 優先，iOS 預留接口

---

## 📋 目錄

1. [現況分析](#1-現況分析)
2. [Gap 分析：現有 vs 建議架構](#2-gap-分析現有-vs-建議架構)
3. [Phase 規劃](#3-phase-規劃)
4. [資料庫改造方案](#4-資料庫改造方案)
5. [UX 優化方案](#5-ux-優化方案)
6. [併發控制方案](#6-併發控制方案)
7. [即時通知架構](#7-即時通知架構)
8. [Widget 策略](#8-widget-策略)
9. [待討論事項](#9-待討論事項)
10. [開發任務清單](#10-開發任務清單)

---

## 1. 現況分析

### 1.1 現有預約相關表格

```
appointments（預約記錄）
├── id, coach_id, client_id
├── time_range (tstzrange) ✅ 已使用時間範圍
├── status (enum: requested/confirmed/cancelled/completed)
├── workout_plan_id（關聯訓練計畫）
├── notes, client_notes, coach_notes
└── cancellation_reason, cancelled_by, cancelled_at

availability_slots（教練可用時段 - 時段驅動）
├── id, coach_id
├── time_range (tstzrange)
├── recurrence_rule（RRULE 格式）
├── is_override
└── notes

client_availability（學員可用時段）
├── id, client_id
├── time_range (tstzrange)
├── recurrence_rule
├── priority
└── notes

coaches（教練檔案 - v2.9 已建立）
├── weekly_availability (jsonb) - 目前為空 '{}'
└── ...其他欄位
```

### 1.2 現有功能狀態

| 功能 | 狀態 | 說明 |
|------|------|------|
| 基本預約流程 | ✅ 已實作 | 教練開放時段 → 學員預約 → 確認 |
| 時間範圍衝突檢查 | ⚠️ 應用層 | 在 Service 層檢查，非 DB 層約束 |
| 緩衝時間 | ❌ 未實作 | 課前課後無休息時間 |
| 最大課程數限制 | ❌ 未實作 | 教練可能過度安排 |
| 提前預約限制 | ❌ 未實作 | 學員可突襲預約 |
| 推播通知 | ❌ 未實作 | 無即時通知 |
| 智慧推薦 | ❌ 未實作 | 無一鍵續約功能 |

---

## 2. Gap 分析：現有 vs 建議架構

### 2.1 架構模式差異

| 維度 | 現有架構 | 建議架構 | 說明 |
|------|----------|----------|------|
| **時段生成** | 時段驅動（Slot-Based） | 規則驅動（Rule-Based） | 現有儲存具體時段，建議儲存生成規則 |
| **衝突檢查** | 應用層 (Service) | 資料庫層 (EXCLUDE) | 建議用 PostgreSQL 原生約束 |
| **緩衝機制** | 無 | buffer_before/after | 需新增欄位 |
| **容量控制** | 僅一對一 | 支援小班制 | 需考慮是否需要 |

### 2.2 表格結構差異

```
現有架構                              建議架構
────────────────────                  ────────────────────
availability_slots                    availability_templates（新）
├── 儲存具體時段                        ├── 儲存週期規則
├── recurrence_rule（選用）             ├── day_of_week（0-6）
└── is_override                        └── start_time/end_time

                                      coach_booking_settings（新）
                                      ├── buffer_before/after
                                      ├── min_booking_notice
                                      ├── max_sessions_per_day
                                      └── slot_increment

                                      availability_overrides（新/改造）
                                      ├── override_date
                                      ├── type (BLOCKED/CUSTOM)
                                      └── custom_slots
```

### 2.3 決策點：改造 vs 新建

**方案 A：改造現有表格**
- 優點：保留現有資料、減少遷移成本
- 缺點：可能有相容性問題

**方案 B：新建表格 + 資料遷移**
- 優點：乾淨的架構設計
- 缺點：需要遷移腳本、可能影響現有功能

**建議**：採用 **漸進式改造（方案 A+）**
1. 新增 `coach_booking_settings` 表（新功能）
2. 保留 `availability_slots`，新增欄位
3. 可選：未來再考慮拆分為 templates + overrides

---

## 3. Phase 規劃

### Phase 3.0-A：v2.9.1 收尾 + 基礎設施（2 週）

| 週次 | 任務 |
|------|------|
| Week 1 | v2.9.1 剩餘：TRN-7、性能監控、Bug 檢查 |
| Week 2 | DB Migration（`coach_booking_settings` + EXCLUDE 約束） |

**合併自 v2.9.1 的任務**：
- TRN-7：預約標籤用途釐清
- 性能監控（6 項）
- UX 優化（7 項：Loading、Shimmer、空狀態引導）
- Bug 檢查（3 項：屏幕尺寸、深淺色模式）

**新增任務**：
- 新增 `coach_booking_settings` 表（緩衝時間參數）
- 在 `appointments` 表新增 EXCLUDE 約束（防止時間重疊）
- 啟用 `btree_gist` 擴充

### Phase 3.0-B：UX 優化（2 週）

| 週次 | 任務 |
|------|------|
| Week 3 | 智慧推薦卡片 + 一鍵續約 |
| Week 4 | 視覺化排程器 + 水平日曆 |

**目標**：
- 預約路徑從 4 步縮減至 1-2 步
- 骨架屏載入體驗

### Phase 3.0-C：即時通訊 ✅

| 週次 | 任務 | 狀態 |
|------|------|------|
| Week 5 | Edge Functions + FCM 整合（Android 優先） | ✅ 完成 |

**完成內容**：
- ✅ 預約通知（`push-notify` Edge Function）
- ✅ 課前提醒（`session-reminder` Edge Function + pg_cron）
- ✅ 問卷通知（`readiness-notify` Edge Function）
- 📅 iOS APNs：延後至 v3.1

### Phase 3.0-D：增值功能（1 週，可選）

| 週次 | 任務 |
|------|------|
| Week 6 | Home Screen Widget（Android only） |

**目標**：
- 「下堂課」AppWidget
- iOS WidgetKit 延後至 v3.1

---

## 4. 資料庫改造方案

### 4.1 新增表格：coach_booking_settings（完整版）

> ✅ **已實作**：`migrations/028_coach_booking_settings.sql`

```sql
CREATE TABLE public.coach_booking_settings (
  -- 1:1 關聯至 coaches（教練必須先填寫公開檔案）
  coach_id UUID PRIMARY KEY REFERENCES public.coaches(id) ON DELETE CASCADE,
  
  -- 緩衝機制（未來擴展）
  buffer_before INTERVAL DEFAULT '00:15:00'::interval,
  buffer_after INTERVAL DEFAULT '00:15:00'::interval,
  
  -- 預約限制（目前使用 min_booking_notice）
  min_booking_notice INTERVAL NOT NULL DEFAULT '02:00:00'::interval,
  max_booking_window INTERVAL DEFAULT '60 days'::interval,
  
  -- 顆粒度與容量（未來擴展）
  slot_increment INTERVAL DEFAULT '00:30:00'::interval,
  default_session_duration INTERVAL DEFAULT '01:00:00'::interval,
  max_sessions_per_day INTEGER DEFAULT 8,
  
  -- 時區
  timezone TEXT NOT NULL DEFAULT 'Asia/Taipei',
  
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

**欄位使用狀態**：
- ✅ `min_booking_notice` - 目前使用（防止臨時預約）
- ⏳ `buffer_before/after` - 未來擴展（課前課後緩衝）
- ⏳ `max_sessions_per_day` - 未來擴展（每日上限）
- ⏳ `slot_increment` - 未來擴展（規則驅動時使用）

<details>
<summary>欄位詳細說明</summary>

```sql
-- 原始設計參考
CREATE TABLE public.coach_booking_settings (
  coach_id UUID REFERENCES public.coaches(id) ON DELETE CASCADE PRIMARY KEY,
  
  -- ========== 緩衝機制 ==========
  buffer_before INTERVAL DEFAULT '15 minutes',   -- 課前準備時間
  buffer_after INTERVAL DEFAULT '15 minutes',    -- 課後休息時間
  
  -- ========== 預約限制 ==========
  min_booking_notice INTERVAL DEFAULT '24 hours', -- 最少提前預約時間
  max_booking_window INTERVAL DEFAULT '60 days',  -- 最遠可預約天數
  
  -- ========== 顆粒度與容量 ==========
  slot_increment INTERVAL DEFAULT '30 minutes',  -- 時段步進單位
  default_session_duration INTERVAL DEFAULT '60 minutes', -- 預設課程長度
  max_sessions_per_day INT DEFAULT 8,            -- 每日最大課程數
  
  -- ========== 時區 ==========
  timezone TEXT DEFAULT 'Asia/Taipei',
  
  -- ========== 時間戳 ==========
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE public.coach_booking_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Coaches can manage own settings"
  ON public.coach_booking_settings
  FOR ALL
  USING (auth.uid() = coach_id);

-- Trigger
CREATE TRIGGER set_coach_booking_settings_updated_at
  BEFORE UPDATE ON public.coach_booking_settings
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();
```

</details>

### 4.2 EXCLUDE 約束：已存在

> ✅ **已存在**：`migrations/006_v2_phase2_appointments.sql` 已定義 `no_coach_overlap` 約束

```sql
-- 006_v2_phase2_appointments.sql（第 111-116 行）
ALTER TABLE public.appointments
ADD CONSTRAINT no_coach_overlap
EXCLUDE USING GIST (
  coach_id WITH =,
  time_range WITH &&
) WHERE (status IN ('requested', 'confirmed'));
```

**不需要新增**，現有約束已滿足需求。

### 4.3 新增狀態：rejected

> ✅ **已實作**：`migrations/029_add_rejected_status.sql`

```sql
ALTER TYPE appointment_status ADD VALUE IF NOT EXISTS 'rejected';
```

**預約狀態現有 5 種**：
| 狀態 | 說明 | 觸發者 |
|------|------|--------|
| `requested` | 待確認 | 學員 |
| `confirmed` | 已確認 | 教練 |
| `rejected` | 教練拒絕 ⭐ | 教練 |
| `completed` | 上課結束 | 系統/教練 |
| `cancelled` | 取消 | 雙方 |

<details>
<summary>原始設計（已棄用）</summary>

```sql
-- migrations/029_appointments_exclude_constraint.sql

-- 啟用 btree_gist 擴充（支援 UUID + tsrange 的混合索引）
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- 新增排他約束：同一教練同一時間不能有重疊的有效預約
-- 注意：僅對 status 不是 'cancelled' 的預約生效
ALTER TABLE public.appointments
ADD CONSTRAINT appointments_no_overlap
EXCLUDE USING GIST (
  coach_id WITH =,
  time_range WITH &&
)
WHERE (status != 'cancelled');

-- 說明：
-- coach_id WITH = : 同一教練
-- time_range WITH && : 時間範圍重疊
-- WHERE (status != 'cancelled') : 僅限有效預約
```

</details>

### 4.4 改造表格：availability_slots 新增欄位（延後）

```sql
-- migrations/030_availability_slots_enhancement.sql

-- 新增欄位
ALTER TABLE public.availability_slots
ADD COLUMN IF NOT EXISTS location_type TEXT DEFAULT 'in_person',
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS capacity INT DEFAULT 1;  -- 容量（1=一對一，>1=小班制）

-- 欄位說明
COMMENT ON COLUMN availability_slots.location_type IS '上課地點類型：in_person, online, hybrid';
COMMENT ON COLUMN availability_slots.is_active IS '是否啟用此時段規則';
COMMENT ON COLUMN availability_slots.capacity IS '容量：1=一對一，>1=小班制';
```

### 4.4 資料庫架構圖

```
┌─────────────────────────────────┐
│           coaches               │
│ (教練公開檔案)                    │
└─────────────┬───────────────────┘
              │ 1:1
              ▼
┌─────────────────────────────────┐
│    coach_booking_settings       │
│ (預約參數：緩衝、限制、顆粒度)     │
└─────────────────────────────────┘
              │ 1:N
              ▼
┌─────────────────────────────────┐
│      availability_slots         │
│ (可用時段規則)                    │
│ ├── 週期性時段                   │
│ └── 覆蓋/例外                    │
└─────────────┬───────────────────┘
              │ 動態計算
              ▼
┌─────────────────────────────────┐
│       appointments              │
│ (預約記錄)                       │
│ ├── EXCLUDE 約束防重疊           │
│ └── 狀態機管理                   │
└─────────────────────────────────┘
```

---

## 5. UX 優化方案

### 5.1 一鍵續約卡片

**位置**：學員首頁頂部

**觸發條件**：
- 用戶過去 30 天有預約紀錄
- 存在已綁定的教練關係

**UI 設計**：
```
┌────────────────────────────────────┐
│ 繼續與 Mike 教練訓練？              │
│                                    │
│ [明天 19:00] [週五 18:00] [週一 19:00] │
│                                    │
│ 💡 根據您的習慣推薦                  │
└────────────────────────────────────┘
```

**推薦邏輯**：
1. 分析用戶歷史預約的時段偏好（如「平日晚上」）
2. 查詢教練可用時段
3. 匹配最近 3 個符合偏好的空檔

### 5.2 視覺化排程器

**現有設計**：傳統月曆 + 下拉選單

**優化設計**：
```
┌────────────────────────────────────┐
│ [← 週一] [週二] [週三] [週四] [週五 →] │  ← 水平日期條
│   1/6     1/7    1/8    1/9   1/10  │
└────────────────────────────────────┘

┌────────────────────────────────────┐
│  09:00  │████████████████│ 已預約   │
│  10:00  │                │ 可預約   │  ← 時間網格
│  11:00  │                │ 可預約 ⭐│  ← 推薦標記
│  12:00  │▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│ 休息中   │
└────────────────────────────────────┘
```

### 5.3 Flutter 套件選擇

| 功能 | 建議套件 | 說明 |
|------|----------|------|
| 水平日期選擇 | `easy_date_timeline` | 輕量、可自訂樣式 |
| 時間網格 | 自建 Widget | 基於 `ListView` + `Container` |
| 骨架屏 | `skeletonizer` | 自動生成骨架 |
| 底部彈窗 | `showModalBottomSheet` | Flutter 內建 |

---

## 6. 併發控制方案

### 6.1 一對一預約：EXCLUDE 約束

已在 4.2 節說明，利用 PostgreSQL 的 `EXCLUDE` 約束在資料庫層級防止衝突。

**錯誤處理**：
```dart
try {
  await supabase.from('appointments').insert({...});
} on PostgrestException catch (e) {
  if (e.code == '23P01') { // exclusion_violation
    throw BookingConflictException('該時段已被預約');
  }
  rethrow;
}
```

### 6.2 小班制預約：RPC 函數（未來）

```sql
-- 未來計劃：小班制預約函數
CREATE OR REPLACE FUNCTION book_group_session(
  p_coach_id UUID,
  p_user_id UUID,
  p_slot_id UUID,
  p_start_time TIMESTAMPTZ,
  p_end_time TIMESTAMPTZ
) RETURNS JSONB AS $$
DECLARE
  v_capacity INT;
  v_current_count INT;
BEGIN
  -- 獲取時段容量
  SELECT capacity INTO v_capacity
  FROM availability_slots WHERE id = p_slot_id;
  
  -- 鎖定並計算當前預約數
  PERFORM pg_advisory_xact_lock(hashtext(p_slot_id::text));
  
  SELECT COUNT(*) INTO v_current_count
  FROM appointments
  WHERE coach_id = p_coach_id
    AND time_range && tsrange(p_start_time, p_end_time)
    AND status != 'cancelled';
  
  -- 容量檢查
  IF v_current_count >= v_capacity THEN
    RETURN jsonb_build_object('success', false, 'error', '課程已額滿');
  END IF;
  
  -- 寫入
  INSERT INTO appointments (coach_id, client_id, time_range, status)
  VALUES (p_coach_id, p_user_id, tsrange(p_start_time, p_end_time), 'confirmed');
  
  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql;
```

---

## 7. 即時通知架構

### 7.1 架構圖

```
┌──────────────┐     INSERT      ┌──────────────┐
│  Flutter App │ ─────────────▶  │ appointments │
└──────────────┘                 └──────┬───────┘
                                        │
                                        │ Database Webhook
                                        ▼
                                 ┌──────────────┐
                                 │ Edge Function│
                                 │ push-notify  │
                                 └──────┬───────┘
                                        │
                                        │ HTTP POST
                                        ▼
                                 ┌──────────────┐
                                 │   FCM API    │
                                 └──────┬───────┘
                                        │
                                        ▼
                                 ┌──────────────┐
                                 │  教練手機    │
                                 └──────────────┘
```

### 7.2 通知類型

| 事件 | 接收者 | 內容 |
|------|--------|------|
| 學員預約 | 教練 | 「Amy 預約了 1/10 19:00 的課程」 |
| 教練確認 | 學員 | 「Mike 教練已確認您的預約」 |
| 教練拒絕 | 學員 | 「Mike 教練無法在此時段上課」 |
| 學員取消 | 教練 | 「Amy 取消了 1/10 的課程」 |
| 教練取消 | 學員 | 「Mike 教練取消了 1/10 的課程」 |
| 課前提醒 | 雙方 | 「1 小時後有課程」 |

### 7.3 課前問卷（後續討論）

```
課前 1 小時提醒
      ↓
學員填寫問卷（身體狀況、疲勞程度、特殊情況）
      ↓
教練上課前查看，調整課程內容
```

📝 可能與 `session_notes` 整合，或設計獨立問卷系統。

### 7.3 FCM Token 儲存

需要在 `users` 表新增欄位：

```sql
-- migrations/031_users_fcm_token.sql
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS fcm_tokens TEXT[] DEFAULT '{}';

COMMENT ON COLUMN users.fcm_tokens IS 'FCM 推播 Token 陣列（支援多設備）';
```

### 7.4 Edge Function 範例

```typescript
// supabase/functions/push-notify/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
  const payload = await req.json();
  const { record, type } = payload;
  
  if (type === 'INSERT' && record.status === 'requested') {
    // 獲取教練的 FCM Token
    const { data: coach } = await supabase
      .from('users')
      .select('fcm_tokens, display_name')
      .eq('id', record.coach_id)
      .single();
    
    // 發送推播
    await sendFCM(coach.fcm_tokens, {
      title: '新預約請求',
      body: `學員預約了課程`,
      data: { appointment_id: record.id }
    });
  }
  
  return new Response('OK');
});
```

---

## 8. Widget 策略

### 8.1 「下堂課」Widget

**設計**：
```
┌────────────────────────────┐
│ 💪 StrengthWise            │
│                            │
│ 距離 背部訓練 還有          │
│     14:32:15               │
│                            │
│ Mike 教練 · 19:00          │
│                            │
│ [───────────▓▓▓]  72%      │  ← 進度條
└────────────────────────────┘
```

### 8.2 技術實作

**套件**：`home_widget`

**資料同步**：
1. App 啟動時計算下一堂課資訊
2. 寫入 SharedPreferences / UserDefaults
3. 調用 `HomeWidget.updateWidget()`

**限制**：
- Widget 不直接連線資料庫
- 依賴 App 主動推送資料
- 使用 `workmanager` 定時喚醒更新

---

## 9. 已確認決策

### 9.1 架構決策（已確認）

| # | 議題 | 決策 | 說明 |
|---|------|------|------|
| D-1 | 時段架構 | ✅ **時段驅動** | 保留現有 `availability_slots`，只新增參數表 |
| D-2 | 小班制 | ✅ **延後** | 專注一對一，小班制延後至 v3.1+ |
| D-3 | 緩衝時間 | ✅ **全域設定** | 存於 `coach_booking_settings`，簡化邏輯 |
| D-4 | 平台策略 | ✅ **Android 優先** | iOS 預留接口（FCM Token 欄位），暫不配置 APNs |
| D-5 | 版本合併 | ✅ **v2.9.1 → v3.0** | 剩餘任務併入 Phase 3.0-A |

### 9.2 技術問題

| # | 問題 | 狀態 | 解決方案 |
|---|------|------|----------|
| T-1 | btree_gist 擴充 | ✅ 已啟用 | 版本 1.7 |
| T-2 | Edge Functions | 待學習 | 用於「資料庫事件 → 發送推播」的後端邏輯，免架伺服器 |
| T-3 | FCM 整合 | Android 優先 | iOS APNs 配置延後 |
| T-4 | Widget 開發 | Android only | iOS WidgetKit 延後至 v3.1 |

### 9.3 名詞解釋

#### 時段驅動 vs 規則驅動

| 模式 | 儲存方式 | 優點 | 缺點 |
|------|----------|------|------|
| **時段驅動**（現有） | 儲存每個具體時段 | 查詢簡單 | 資料量大 |
| **規則驅動**（報告建議） | 儲存週期規則，動態計算 | 資料量小 | 計算複雜 |

**決策**：保持時段驅動，現有 `availability_slots` 已有 `recurrence_rule` 可處理重複規則。

#### 緩衝時間

```
沒有緩衝：
09:00-10:00 │ 學員 A
10:00-11:00 │ 學員 B  ← 教練沒時間休息

有緩衝（buffer_after = 15 分鐘）：
09:00-10:00 │ 學員 A
10:00-10:15 │ ████ 休息（不可預約）
10:15-11:15 │ 學員 B
```

#### Edge Function

```
傳統做法（需要自己的伺服器）：
App → 你的 Node.js 伺服器 → FCM → 用戶手機

Edge Function 做法（Supabase 提供）：
App → Supabase → Edge Function → FCM → 用戶手機
                      ↑
                雲端執行的 JS 程式碼
                不需自己架設伺服器
```

---

## 10. 開發任務清單

### Phase 3.0-A：v2.9.1 收尾 + 基礎設施

#### v2.9.1 剩餘任務

| # | 類型 | 任務 | 優先級 | 狀態 |
|---|------|------|--------|------|
| TRN-7 | 討論 | 預約標籤用途釐清 | P1 | ⏳ |
| perf-1~6 | 驗證 | 性能監控（6 項） | P1 | ⏳ |
| UX-1~7 | UI | Loading/Shimmer/空狀態引導 | P1 | ⏳ |
| Bug-1~3 | 測試 | 跨屏幕/深淺色模式 | P1 | ⏳ |

#### 預約系統基礎設施

| # | 類型 | 任務 | 優先級 | 狀態 |
|---|------|------|--------|------|
| DB-0 | SQL | `CREATE EXTENSION btree_gist;` | P0 | ✅ 已啟用 |
| DB-1 | Migration | `028_coach_booking_settings.sql`（完整版） | P0 | ✅ 已建立 |
| DB-2 | Migration | `029_add_rejected_status.sql` | P0 | ✅ 已建立 |
| DB-3 | Migration | `030_daily_readiness.sql` | P0 | ✅ 已建立 |
| DB-4 | Migration | `031_session_auto_create.sql` | P0 | ✅ 已建立 |
| M-1 | Model | `coach_booking_settings_model.dart` | P0 | ⏳ |
| S-1 | Service | 緩衝時間計算邏輯 | P0 | ⏳ |
| S-2 | Service | EXCLUDE 約束錯誤處理 | P0 | ⏳ |

### Phase 3.0-B：UX 優化

#### 預約相關

| # | 類型 | 任務 | 優先級 | 狀態 |
|---|------|------|--------|------|
| UI-1 | Widget | 一鍵續約卡片 | P0 | ⏳ |
| UI-2 | Widget | 水平日期選擇器 | P0 | ⏳ |
| UI-3 | Widget | 時間網格視圖 | P0 | ⏳ |
| UI-4 | Page | 預約確認底部彈窗 | P1 | ⏳ |
| UI-5 | 整合 | 骨架屏載入 | P1 | ⏳ |

#### Session Mode（教練上課模式）⭐ 新增

詳細規格：[SESSION_MODE_SPEC.md](SESSION_MODE_SPEC.md)

| # | 類型 | 任務 | 優先級 | 狀態 |
|---|------|------|--------|------|
| SM-1 | Page | `session_mode_page.dart` 主框架 | P0 | ⏳ |
| SM-2 | Widget | 訓練動作卡（含 PREV 幽靈數據） | P0 | ⏳ |
| SM-3 | Service | 動作歷史查詢邏輯 | P0 | ⏳ |
| SM-4 | Widget | 動作歷史彈窗 | P1 | ⏳ |
| SM-5 | Widget | 學員狀態卡（課前問卷） | P1 | ⏳ |
| SM-6 | Widget | 課程筆記區塊 | P1 | ⏳ |
| SM-7 | Tab | 近期統計 Tab | P2 | ⏳ |
| SM-8 | 整合 | 手繪 FAB | P2 | ⏳ |

#### 課前問卷系統（Pre-Session Readiness）

| # | 類型 | 任務 | 優先級 | 狀態 |
|---|------|------|--------|------|
| RQ-1 | Migration | `032_daily_readiness.sql` 新表 | P0 | ⏳ |
| RQ-2 | Model | `daily_readiness_model.dart` | P0 | ⏳ |
| RQ-3 | Widget | 表情滑桿組件 `emoji_slider.dart` | P0 | ⏳ |
| RQ-4 | Page | 學員問卷頁面 `readiness_form_page.dart` | P0 | ⏳ |
| RQ-5 | 通知 | 課前提醒 + 學員填完通知教練 | P1 | ⏳ |

### Phase 3.0-C：即時通訊（Android 優先）

| # | 類型 | 任務 | 優先級 | 狀態 |
|---|------|------|--------|------|
| DB-3 | Migration | `032_users_fcm_tokens.sql` | P0 | ✅ |
| BE-1 | Edge Function | `push-notify` 函數 | P0 | ✅ |
| BE-2 | Webhook | Database Webhook 配置 | P0 | ✅ |
| FL-1 | Flutter | FCM 整合（Android） | P0 | ✅ `NotificationService` |
| FL-2 | Edge Function | 課前提醒（pg_cron） | P1 | ✅ `session-reminder` |
| FL-3 | 預留 | iOS APNs 配置（延後） | P3 | 📅 v3.1 |

### Phase 3.0-D：Widget（Android only，可選）

| # | 類型 | 任務 | 優先級 | 狀態 |
|---|------|------|--------|------|
| W-1 | Flutter | `home_widget` 整合 | P2 | ⏳ |
| W-2 | Android | AppWidget 開發 | P2 | ⏳ |
| W-3 | iOS | WidgetKit（延後至 v3.1） | P4 | 🔜 |

---

## 📎 參考資料

- 原始研究報告：用戶提供的「StrengthWise 平台架構優化與交互流程深度研究報告」
- 現有資料庫結構：`dbStructure.json`
- PostgreSQL EXCLUDE 文檔：https://www.postgresql.org/docs/current/ddl-constraints.html
- Supabase Edge Functions：https://supabase.com/docs/guides/functions

---

## ⚠️ 風險評估

| 風險 | 影響 | 緩解措施 |
|------|------|----------|
| EXCLUDE 約束影響現有資料 | 高 | 先檢查現有 appointments 是否有重疊 |
| Edge Functions 學習曲線 | 中 | 提供範例程式碼，可逐步學習 |
| Widget 開發複雜度 | 中 | Android only，降低複雜度 |
| FCM iOS 配置 | 低 | 已決策延後，暫不處理 |

---

## 📎 下一步行動

1. **確認 btree_gist**：在 Supabase SQL Editor 執行 `SELECT * FROM pg_extension WHERE extname = 'btree_gist';`
2. **檢查現有預約**：確認 `appointments` 表沒有時間重疊的記錄（否則 EXCLUDE 約束會失敗）
3. **開始 Phase 3.0-A**：執行 DB-0 ~ DB-2 的 Migration

---

## 11. 預約流程最終確認

### 11.1 狀態機

```
┌───────────┐     學員預約      ┌───────────┐
│  (空)     │ ────────────────▶ │ requested │
└───────────┘                   └─────┬─────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
              教練確認           教練拒絕           學員取消
                    │                 │                 │
                    ▼                 ▼                 ▼
             ┌───────────┐     ┌───────────┐     ┌───────────┐
             │ confirmed │     │ rejected  │     │ cancelled │
             └─────┬─────┘     └───────────┘     └───────────┘
                   │
         ┌─────────┴─────────┐
         │                   │
    任一方取消            課程完成
         │                   │
         ▼                   ▼
   ┌───────────┐       ┌───────────┐
   │ cancelled │       │ completed │
   └───────────┘       └───────────┘
```

### 11.2 衝突處理：先搶先贏

```
學員 A 預約 10:00 → ✅ 成功（狀態：requested，時段已被佔用）
學員 B 預約 10:00 → ❌ DB 拒絕「此時段已被預約」

※ EXCLUDE 約束在 DB 層處理
※ 即使教練還沒確認，時段也已被「佔用」
```

### 11.3 取消規則

| 誰取消 | 需要原因 | 通知對象 |
|--------|----------|----------|
| 學員 | ✅ 填寫 `cancellation_reason` | 教練 |
| 教練 | ✅ 填寫 `cancellation_reason` | 學員 |

### 11.4 後續討論項目

| 項目 | 說明 |
|------|------|
| 課前問卷 | 學員填寫身體狀況，教練調整課程 |
| session_notes 整合 | 問卷內容可能寫入 session_notes 主觀部分 |

---

## 📎 下一步行動

1. ✅ **btree_gist 已確認啟用**（版本 1.7）
2. **檢查現有預約重疊**：執行 SQL 確認無衝突
3. **開始 Phase 3.0-A**：
   - DB-1：新增 `coach_booking_settings` 表（預留欄位）
   - DB-2：新增 `appointments` EXCLUDE 約束

---

**文檔狀態**：✅ Phase 3.0-A/B/C 開發完成（2026-01-05）

