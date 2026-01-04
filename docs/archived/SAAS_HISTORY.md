# StrengthWise - SaaS 開發歷史

> Phase 1-4 完成記錄

**歸檔日期**：2026-01-05

---

## Phase 1：基礎設施與身份認證（2024-12-28）

**核心成果**：
- 教練學員綁定機制（coaching_relationships 表）
- RLS 策略（雙向權限保護）
- 邀請學員 Dialog（UUID 直接綁定）

**技術亮點**：
- 完全解耦架構（Model + Service + Controller + UI）

---

## Phase 2：核心訓練業務（2024-12-28）

**核心成果**：
- TSTZRANGE + GiST 排除約束（防止雙重預約）
- 狀態機（pending → confirmed → completed）

**技術亮點**：
- PostgreSQL 原生 Range Types + Exclusion Constraints
- 物理層面禁止重疊預約

---

## Phase 3：視覺化筆記與雙向時間管理（2024-12-30）

**核心成果**：
- SOAP 專業筆記（S.O.A.P 四欄位）
- 照片上傳（Supabase Storage + RLS 學員隔離）
- 學員時間偏好設定（TSTZRANGE + 優先級）

**技術亮點**：
- Signed URL 機制（24 小時有效）
- Private/Shared 切換（RLS 保護）

---

## Phase 4A：完整手繪板（2024-12-31）

**核心成果**：
- 向量繪圖系統（JSONB 儲存，可編輯）
- 4 種底圖模板 + 4 種繪圖工具
- 底圖保護（擦除不影響底圖）

**技術亮點**：
- 向量繪圖（可編輯、輕量）
- JSONB 儲存（無需 Storage）

---

## Phase 4B：教練多學員統計視圖（2025-01-01）

**核心成果**：
- StatisticsPageV2 支援 userId 參數
- 複用全部 16 個統計模組

**技術亮點**：
- 只需 +22 行代碼（遠低於預估 2-3 天）

---

## Phase 4C：教練學員頁面整合（2025-01-01）

**核心成果**：
- ClientManagementController（教練端 - 17 個方法）
- CoachManagementController（學員端 - 12 個方法）
- 統一行事曆（時間偏好 + 預約 + 訓練計畫）

**技術亮點**：
- 100% 解耦架構（所有操作透過 Interface）
- 資料庫無需變動（trainee_id 和 creator_id 已存在）

---

## Phase 4D：統一行事曆系統（2025-01-01）

**核心成果**：
- Layer-based Composition 架構
- 7 個行事曆 → 1 個統一組件
- 刪除 218+ 行重複代碼

**技術亮點**：
- 維護成本 -80%，開發時間 -70%

---

## Migrations 優化（2025-01-01）

**核心成果**：
- 從 19 個檔案合併為 7 個（-63%）
- 清晰的版本劃分（v1.0 vs v2.0）

**技術亮點**：
- Python 自動化合併工具
- 11 個核心文檔全面更新

---

## 相關文檔

- [SAAS_PLATFORM_ROADMAP.md](../SAAS_PLATFORM_ROADMAP.md) - 當前路線圖
- [VERSION_HISTORY.md](VERSION_HISTORY.md) - 版本歷史

