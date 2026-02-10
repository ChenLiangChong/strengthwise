# 工作室管理系統規劃（Studio Management）

> 讓工作室老闆追蹤旗下教練的教學狀況、學員進度與營運指標

**建立日期**：2026-02-10
**目標版本**：v6.0+
**狀態**：規劃中
**平台**：Web 管理後台（獨立於手機 App）

---

## 目錄

1. [功能概述](#1-功能概述)
2. [分階段規劃](#2-分階段規劃)
3. [資料庫設計](#3-資料庫設計)
4. [架構設計](#4-架構設計)
5. [遷移策略](#5-遷移策略)
6. [風險評估](#6-風險評估)
7. [已確認決策](#7-已確認決策)
8. [延後項目](#8-延後項目)

---

## 1. 功能概述

### 核心需求

工作室老闆（Studio Owner）需要：

| 需求 | 說明 |
|------|------|
| 教練管理 | 邀請/移除教練、查看教練名冊 |
| 教學監控 | 查看教練的排課率、SOAP 筆記完成率 |
| 學員概覽 | 查看工作室所有學員名單與活躍狀態 |
| 營運指標 | 排課率、學員留存率、教學合規率 |

### Server 需求分析

**結論：Phase 1-2 不需要獨立 Server。**

| 功能 | 技術方案 | 是否需要 Server |
|------|----------|----------------|
| 新增表 + RLS | PostgreSQL 原生 | ❌ |
| KPI 聚合統計 | SQL RPC 函數 | ❌ |
| 定時任務 | pg_cron | ❌ |
| 即時通知 | Realtime + Edge Functions | ❌ |
| 自動化提醒 | Edge Functions（FCM） | ❌ |
| PDF 報表生成 | Edge Function 有 50MB 記憶體限制 | ⚠️ Phase 3+ 再評估 |
| CRM 整合 | Webhook | ⚠️ Phase 3+ 再評估 |

Supabase 現有基礎設施（PostgreSQL + Edge Functions + Realtime + pg_cron）完全足以支撐 Phase 1-2。

### 平台定位

```
手機 App（Flutter）                Web 管理後台（技術待定）
───────────────────              ─────────────────────────
教練：訓練計劃、上課模式、筆記     工作室 Owner/Admin：
學員：預約、記錄、統計              教練管理、KPI 儀表板、學員概覽
                                   營運指標、報表

           ↓ 共用 ↓                          ↓ 共用 ↓
        Supabase（PostgreSQL + RLS + RPC + Realtime）
```

- **手機 App 不改動**：教練和學員繼續用現有 App，完全不受影響
- **Web 後台獨立開發**：工作室管理功能在獨立的 Web 前端實作
- **共用資料庫**：同一個 Supabase 專案，透過 RLS 和 RPC 存取

Web 前端技術（Next.js / Vue / Flutter Web 等）待後續決定，**本規劃聚焦資料庫 + API 層設計**。

### 與現有架構的關係

```
現有架構（v5.2）              新增工作室層
─────────────────            ────────────────
users (is_coach/is_student)  → 不改動
coaching_relationships       → 不改動（間接關聯學員）
appointments                 → 不改動
session_notes                → 不改動
availability_slots           → 不改動

                             + studios（新表）
                             + studio_members（新表）
                             + studio_invitations（新表）
                             + RPC 函數（聚合統計）
```

**關鍵原則：不修改任何現有表格，零破壞風險。**

---

## 2. 分階段規劃

### Phase 1：基礎架構（MVP）

**目標**：建立工作室資料模型、權限控制、基礎 API

| # | 類型 | 任務 | 優先級 | 狀態 |
|---|------|------|--------|------|
| S1-1 | SQL | Migration：studios + studio_members + studio_invitations | P0 | ⏳ |
| S1-2 | SQL | RLS 策略（3 張新表） | P0 | ⏳ |
| S1-3 | SQL | RPC：get_studio_coaches()、get_studio_clients() | P0 | ⏳ |
| S1-4 | SQL | RPC：accept_studio_invitation()（接受邀請加入） | P0 | ⏳ |
| S1-5 | SQL | RPC：transfer_coach_clients()（教練離職轉移學員） | P1 | ⏳ |
| S1-6 | Web | 決定 Web 前端技術（Next.js / Vue / 其他） | P0 | ⏳ |
| S1-7 | Web | 建立工作室 + 成員管理頁面 | P1 | ⏳ |
| S1-8 | Web | 邀請教練流程（邀請碼 / Email） | P1 | ⏳ |

### Phase 2：教學監控儀表板

**目標**：工作室管理員能查看教練 KPI、學員活躍度、異常預警

| # | 類型 | 任務 | 優先級 | 狀態 |
|---|------|------|--------|------|
| S2-1 | SQL | RPC：get_coach_kpi_summary()（排課率 + SOAP 完成率） | P0 | ⏳ |
| S2-2 | SQL | RPC：get_studio_client_overview()（學員活躍度） | P0 | ⏳ |
| S2-3 | SQL | RPC：get_studio_alerts()（異常預警） | P1 | ⏳ |
| S2-4 | Web | 儀表板首頁（KPI 卡片 + 圖表） | P0 | ⏳ |
| S2-5 | Web | 教練績效詳情頁 | P1 | ⏳ |
| S2-6 | Web | 學員概覽列表頁 | P1 | ⏳ |
| S2-7 | Edge | 自動提醒：教練未填 SOAP 筆記 | P2 | ⏳ |
| S2-8 | SQL | Studio-level Realtime 訂閱 | P2 | ⏳ |

### Phase 3+：進階功能（需再評估）

| 項目 | 說明 | 前置條件 |
|------|------|----------|
| 財務追蹤 | 課酬結算、收入統計 | 確認計費模式 |
| 自動化報告 | 週報/月報 PDF 或 Email | 評估 Edge Function 限制 |
| 場地管理 | 教室/器材排程 | 確認工作室有場地需求 |
| 多工作室 | 一個教練屬於多個工作室 | Phase 1 已支援（M2M） |
| 訓練計畫審核 | 初級教練計畫需主管核准 | 確認工作室有此流程 |
| CRM 整合 | 學員續費提醒、行銷自動化 | 確認使用的 CRM |

---

## 3. 資料庫設計

### 3.1 studios 表

```sql
CREATE TABLE public.studios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,                    -- 工作室名稱
  description TEXT,                      -- 簡介
  logo_url TEXT,                         -- Logo 圖片
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  timezone TEXT DEFAULT 'Asia/Taipei',   -- 工作室時區
  settings JSONB DEFAULT '{}'::jsonb,    -- 擴展設定
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_studios_owner_id ON studios(owner_id);
```

### 3.2 studio_members 表

```sql
CREATE TABLE public.studio_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'coach',    -- owner / admin / coach
  display_name TEXT,                     -- 在工作室內的顯示名稱
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(studio_id, user_id)
);

CREATE INDEX idx_studio_members_studio_id ON studio_members(studio_id);
CREATE INDEX idx_studio_members_user_id ON studio_members(user_id);
```

**角色定義**：

| 角色 | 權限 |
|------|------|
| `owner` | 完整管理權（刪除工作室、轉移擁有權） |
| `admin` | 管理成員、查看所有 KPI、發送通知 |
| `coach` | 查看自己的 KPI、被管理員查看教學數據 |

### 3.3 studio_invitations 表

```sql
CREATE TABLE public.studio_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  invited_by UUID NOT NULL REFERENCES users(id),
  invite_code TEXT UNIQUE NOT NULL,      -- 一次性邀請碼
  target_email TEXT,                     -- 指定邀請（可選）
  role TEXT NOT NULL DEFAULT 'coach',    -- 被邀請的角色
  status TEXT NOT NULL DEFAULT 'pending', -- pending / accepted / expired
  expires_at TIMESTAMPTZ NOT NULL,
  accepted_by UUID REFERENCES users(id),
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_studio_invitations_code ON studio_invitations(invite_code);
CREATE INDEX idx_studio_invitations_studio ON studio_invitations(studio_id);
```

### 3.4 RLS 策略

```sql
-- === studios ===
-- 成員可讀取
CREATE POLICY "studio_member_read" ON studios FOR SELECT
  USING (id IN (SELECT studio_id FROM studio_members WHERE user_id = auth.uid()));

-- 只有 owner 可修改
CREATE POLICY "studio_owner_update" ON studios FOR UPDATE
  USING (owner_id = auth.uid());

-- 認證用戶可建立
CREATE POLICY "authenticated_create" ON studios FOR INSERT
  WITH CHECK (owner_id = auth.uid());

-- 只有 owner 可刪除
CREATE POLICY "studio_owner_delete" ON studios FOR DELETE
  USING (owner_id = auth.uid());

-- === studio_members ===
-- 同工作室成員可讀
CREATE POLICY "studio_member_read" ON studio_members FOR SELECT
  USING (studio_id IN (SELECT studio_id FROM studio_members WHERE user_id = auth.uid()));

-- owner/admin 可管理成員
CREATE POLICY "studio_admin_manage" ON studio_members FOR INSERT
  WITH CHECK (studio_id IN (
    SELECT studio_id FROM studio_members
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
  ));

-- owner/admin 可移除成員（不能移除 owner）
CREATE POLICY "studio_admin_delete" ON studio_members FOR DELETE
  USING (
    studio_id IN (
      SELECT studio_id FROM studio_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
    AND role != 'owner'
  );

-- === studio_invitations ===
-- 同工作室成員可讀
CREATE POLICY "studio_member_read_invitations" ON studio_invitations FOR SELECT
  USING (studio_id IN (SELECT studio_id FROM studio_members WHERE user_id = auth.uid()));

-- owner/admin 可建立邀請
CREATE POLICY "studio_admin_create_invitation" ON studio_invitations FOR INSERT
  WITH CHECK (studio_id IN (
    SELECT studio_id FROM studio_members
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
  ));
```

### 3.5 RPC 函數

#### get_studio_clients()：取得工作室所有學員（間接關聯）

```sql
CREATE OR REPLACE FUNCTION get_studio_clients(p_studio_id UUID)
RETURNS TABLE (
  client_id UUID,
  client_name TEXT,
  coach_id UUID,
  coach_name TEXT,
  relationship_status TEXT,
  last_appointment TIMESTAMPTZ
) SECURITY DEFINER AS $$
BEGIN
  -- 驗證呼叫者是工作室 admin/owner
  IF NOT EXISTS (
    SELECT 1 FROM studio_members
    WHERE studio_id = p_studio_id
      AND user_id = auth.uid()
      AND role IN ('owner', 'admin')
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  SELECT
    cr.client_id,
    COALESCE(u.display_name, cr.client_name) AS client_name,
    cr.coach_id,
    COALESCE(cu.display_name, cr.coach_name) AS coach_name,
    cr.status AS relationship_status,
    (SELECT MAX(a.time_range) FROM appointments a
     WHERE a.client_id = cr.client_id AND a.status = 'completed'
    ) AS last_appointment
  FROM coaching_relationships cr
  JOIN studio_members sm ON sm.user_id = cr.coach_id AND sm.studio_id = p_studio_id
  LEFT JOIN users u ON u.id = cr.client_id
  LEFT JOIN users cu ON cu.id = cr.coach_id
  WHERE cr.status = 'active';
END;
$$ LANGUAGE plpgsql;
```

#### get_coach_kpi_summary()：教練 KPI 摘要（Phase 2）

```sql
-- 概念設計，Phase 2 實作時細化
CREATE OR REPLACE FUNCTION get_coach_kpi_summary(
  p_studio_id UUID,
  p_date_from DATE,
  p_date_to DATE
)
RETURNS TABLE (
  coach_id UUID,
  coach_name TEXT,
  total_slots INT,           -- 開放時段數
  total_appointments INT,    -- 已預約數
  completed_sessions INT,    -- 已完成課程數
  notes_completed INT,       -- 已填寫 SOAP 筆記數
  utilization_rate FLOAT,    -- 排課率
  notes_compliance_rate FLOAT, -- 筆記完成率
  active_clients INT         -- 活躍學員數
) SECURITY DEFINER AS $$
  -- 驗證權限 → 聚合 availability_slots、appointments、session_notes
  -- 透過 studio_members 關聯教練 UUID
$$ LANGUAGE plpgsql;
```

### 3.6 Migration 規劃

| Migration | 內容 | Phase |
|-----------|------|-------|
| `37_studio_management.sql` | studios + studio_members + studio_invitations + RLS + 索引 | Phase 1 |
| `38_studio_rpc_functions.sql` | get_studio_clients() + get_coach_kpi_summary() | Phase 1-2 |

---

## 4. 架構設計

### 4.1 不改現有表的策略（向後相容）

```
查詢工作室學員：
  studios
    → studio_members (role = 'coach')
      → coaching_relationships (coach_id = studio_members.user_id)
        → users (client_id)

查詢教練排課率：
  studio_members (role = 'coach')
    → availability_slots (coach_id)
    → appointments (coach_id)
    → 計算比率

查詢 SOAP 完成率：
  studio_members (role = 'coach')
    → appointments (coach_id, status = 'completed')
    → session_notes (appointment_id)
    → 計算比率
```

所有聚合透過 RPC 函數在 PostgreSQL 內完成，Web 前端只呼叫 RPC，不做跨表 Join。

### 4.2 API 層設計（Supabase RPC）

Web 前端透過 Supabase Client SDK 直接呼叫，不需額外 API Server。

#### Phase 1 API

| RPC 函數 | 參數 | 回傳 | 用途 |
|----------|------|------|------|
| `create_studio()` | name, description | studio_id | 建立工作室（自動加入 owner） |
| `get_my_studios()` | — | studios[] | 查詢我的工作室列表 |
| `get_studio_coaches()` | studio_id | members[] | 取得工作室教練名冊 |
| `get_studio_clients()` | studio_id | clients[] | 取得工作室所有學員（間接） |
| `create_studio_invitation()` | studio_id, role, email? | invite_code | 建立邀請碼 |
| `accept_studio_invitation()` | invite_code | member_id | 接受邀請加入 |
| `remove_studio_member()` | studio_id, user_id | success | 移除成員 |
| `transfer_coach_clients()` | from_coach, to_coach, studio_id | count | 批量轉移學員 |

#### Phase 2 API

| RPC 函數 | 參數 | 回傳 | 用途 |
|----------|------|------|------|
| `get_coach_kpi_summary()` | studio_id, date_from, date_to | kpi[] | 教練 KPI 摘要 |
| `get_studio_client_overview()` | studio_id | overview[] | 學員活躍度 |
| `get_studio_alerts()` | studio_id | alerts[] | 異常預警 |
| `get_coach_detail_stats()` | studio_id, coach_id, date_from, date_to | detail | 單一教練詳細績效 |

### 4.3 Web 前端頁面規劃

| 頁面 | Phase | 說明 |
|------|-------|------|
| 登入（Supabase Auth） | 1 | 共用現有 Supabase Auth |
| 工作室建立/設定 | 1 | 名稱、Logo、簡介 |
| 成員管理 | 1 | 教練列表、邀請、移除 |
| 儀表板首頁 | 2 | KPI 卡片 + 圖表 |
| 教練績效詳情 | 2 | 單一教練的排課率、筆記率、學員列表 |
| 學員概覽 | 2 | 全工作室學員、活躍狀態、所屬教練 |

### 4.4 Realtime 頻道規劃（Phase 2）

| 頻道 | 表格 | 事件 | 用途 |
|------|------|------|------|
| `studio_{id}_members` | studio_members | INSERT, DELETE | 成員變動即時通知 |
| `studio_{id}_appointments` | appointments | UPDATE | 管理員看到課程狀態變更 |

### 4.5 手機 App 影響

手機 App（Flutter）**不需要改動**。教練在 App 內：
- 繼續使用現有功能（訓練計劃、上課模式、筆記等）
- 不需要知道自己屬於哪個工作室
- 教練的教學數據自動被工作室後台讀取（透過 RPC + RLS）

唯一可能的 App 變更（Phase 2+）：
- 教練在「我的」頁面看到「所屬工作室」資訊（可選）

---

## 5. 遷移策略

### 現有教練建立工作室

```
情境：教練 A 目前已有 5 個學員，想建立工作室

步驟：
1. 教練 A 建立工作室 → 自動成為 owner
2. 教練 A 的現有 coaching_relationships 不受影響
3. 工作室透過 studio_members(user_id = A) 間接看到 A 的學員

無需遷移資料，零風險。
```

### 多教練加入

```
情境：工作室已有教練 A，想邀請教練 B 加入

步驟：
1. Owner 建立邀請碼
2. 教練 B 輸入邀請碼 → 加入 studio_members
3. 教練 B 的現有學員自動歸屬工作室視角
```

### 教練離職處理

```
情境：教練 B 離開工作室

步驟：
1. Owner 從 studio_members 移除教練 B
2. 教練 B 與其學員的 coaching_relationships 不受影響
3. 工作室儀表板不再顯示教練 B 的數據
4. 如需將學員轉移給其他教練 → 手動操作（或 RPC 函數批量轉移）
```

### 漸進式推出

- 工作室功能為**可選功能**，不強制現有教練使用
- 獨立教練的使用體驗完全不變
- `users` 表不新增欄位（工作室角色透過 `studio_members` 查詢）

---

## 6. 風險評估

| 風險 | 影響 | 機率 | 緩解措施 |
|------|------|------|----------|
| RPC 函數效能（大量跨表 Join） | 儀表板載入慢 | 中 | 初期用 RPC，大規模時改物化視圖 |
| RLS 子查詢效能 | 所有新表查詢變慢 | 低 | studio_members 已建索引，子查詢簡單 |
| 間接關聯查詢複雜度 | 開發成本增加 | 中 | RPC 封裝，前端只呼叫 RPC |
| 教練離職學員歸屬 | 學員無法被工作室追蹤 | 低 | 提供批量轉移 RPC 函數 |
| 現有 App 被影響 | 用戶流失 | 極低 | 不改任何現有表，App 不改動 |
| Web 前端技術選型 | 開發效率 | 中 | 先確定 DB 層，前端技術可後續決定 |
| 維護兩套前端 | 維護成本增加 | 中 | Web 後台功能獨立，與 App 無耦合 |

---

## 7. 已確認決策

| 決策 | 選項 | 結論 | 原因 |
|------|------|------|------|
| 平台 | App 內 vs 獨立 Web | **獨立 Web 後台** | 管理後台適合桌面操作（表格、圖表） |
| 學員歸屬模式 | 直接 vs 間接 | **間接關聯** | 不改現有表，零破壞風險 |
| Server 需求 | 獨立 Server vs Supabase | **Supabase** | Phase 1-2 完全足夠 |
| 角色層級 | 遞迴 vs 扁平 | **扁平（3 角色）** | 初期不需複雜層級 |
| KPI 計算 | 物化視圖 vs RPC | **先 RPC，後物化視圖** | 漸進式優化 |
| Web 前端技術 | Next.js / Vue / Flutter Web | **待定** | 先完成 DB + API 設計再選 |

---

## 8. 延後項目

以下為分析報告中提及但評估後延後的項目：

| 項目 | 延後原因 |
|------|----------|
| 遞迴 CTE 層級權限 | 初期只有 owner/admin/coach 三層，不需遞迴 |
| Table Partitioning | 百萬筆資料前不需要，目前遠未達到 |
| HIPAA/GDPR 審計日誌 | 台灣市場暫無強制法規要求 |
| CRM 整合（HubSpot/Salesforce） | Beta 階段無此需求 |
| PDF 週報生成 | Edge Function 有 50MB 記憶體限制，需評估替代方案 |
| 訓練計畫審核流程 | 目前教練自主性高，暫不需核准機制 |
| 場地/器材排除約束 | 初期不管場地排程 |
| 評價系統 | 需確認工作室是否需要教練互評 |
| 多幣別支援 | 目前僅台灣市場 |

---

> 📝 本文件為規劃階段，實作細節（具體代碼、完整 SQL）在開發時確定。
