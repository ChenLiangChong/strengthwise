# StrengthWise - SaaS 平台路線圖

> 從單機應用至教練-學員雙端 SaaS 平台

**最後更新**：2026-01-05（v2.8.1）  
**當前狀態**：✅ Phase 4 全部完成 + v2.3-v2.8 功能增強

---

## 📊 轉型概述

### 設計哲學

**資料庫優先（Database-First）**：
- Row Level Security (RLS) 確保數據隔離
- PostgreSQL Exclusion Constraints 防止重疊預約
- Materialized Views 預先計算統計指標

### 版本對照

| 版本 | 類型 | 說明 |
|------|------|------|
| v1.0 | 單機版 | 個人健身記錄應用 |
| v2.0+ | SaaS | 教練-學員雲端平台 |

---

## ✅ 已完成功能

### Phase 1：教練學員系統
- 教練學員綁定（coaching_relationships）
- RLS 雙向權限保護
- UUID 直接綁定

### Phase 2：預約系統
- TSTZRANGE + GiST 排除約束（防止雙重預約）
- 狀態機（pending → confirmed → completed）
- iCal RRULE 週期性時段

### Phase 3：視覺化筆記
- SOAP 專業筆記
- 照片上傳（Supabase Storage + RLS）
- 學員時間偏好設定

### Phase 4A：完整手繪板
- 向量繪圖系統（JSONB 儲存）
- 4 種底圖模板 + 4 種繪圖工具
- 底圖保護（擦除不影響底圖）

### Phase 4B-4D：整合與優化
- 教練多學員統計視圖
- 統一行事曆系統（Layer-based Composition）
- Migrations 優化（19 → 7 檔案）

### v2.3-v2.8 增強功能
- 邀請碼系統（遠端綁定）
- QR Code 雙向掃描
- 帳號刪除保留歷史數據
- 健康評估系統（PAR-Q+ 問卷）
- 教練評估備註

---

## 🔄 未來計劃

### Phase 5：上線準備
- [ ] 生產環境 Supabase 配置（RLS 審查）
- [ ] Edge Functions 部署與監控
- [ ] 數據備份策略
- [ ] 錯誤追蹤（Sentry）
- [ ] Beta 測試（5-10 組教練-學員）

### 長期規劃
- [ ] 用戶引導流程（Onboarding）
- [ ] 隱私政策更新（雙端數據條款）
- [ ] 定價策略

---

## 🎯 成功指標

### 技術指標
- 數據安全：0 起數據洩露事件
- 查詢性能：儀表板載入 < 500ms
- 預約成功率：> 99.9%
- RLS 覆蓋率：100%

### 業務指標
- 教練註冊數：Phase 5 結束前達到 20 位
- 學員活躍度：每週至少 3 次訓練記錄

---

## 📚 相關文檔

- [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) - 當前開發狀態
- [DATABASE_SUPABASE.md](DATABASE_SUPABASE.md) - 資料庫設計
- [migrations/README.md](../migrations/README.md) - Migration 執行順序
- [archived/SAAS_HISTORY.md](archived/SAAS_HISTORY.md) - 開發歷史記錄
