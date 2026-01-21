# 規劃文檔規範

## 📁 目錄定位

```
docs/planning/
├── SYNC_ARCHITECTURE_SPEC.md       ← v4.0 同步架構規格 ⭐
├── HOME_BOOKING_UX_SPEC.md         ← v3.1-B 首頁+行事曆 UX 🔄 開發中
├── BETA_RECRUITMENT_DESIGN.md      ← Beta 招募設計 🔄 活躍
├── TESTING_STRATEGY.md             ← 測試策略 🔄 活躍
├── PRODUCTION_LAUNCH_GUIDE.md      ← 生產環境發布 🔄 活躍
├── VIRTUAL_CLIENT_SPEC.md          ← 虛擬學員功能 📋 規劃
└── archived/                       ← 📦 已完成的規格書（11 個）
    ├── ARCHITECTURE_REVIEW_V4.md   ← v4.0 架構評審 ✅
    ├── CUSTOM_EXERCISE_IMPROVEMENTS.md ← 自訂動作改進 ✅
    ├── EXERCISE_CLASSIFICATION_ANALYSIS.md ← 運動分類分析 ✅
    ├── TRACKING_MODE_SPEC.md       ← v3.3 TrackingMode 適配 ✅
    ├── DATA_FLOW_ANALYSIS.md       ← v3.1-E 性能優化 ✅
    ├── SESSION_MODE_SPEC.md        ← v3.1-SM 教練上課模式 ✅
    ├── TRAINING_PERMISSION_MATRIX.md ← v3.1 訓練權限矩陣 ✅
    ├── LOCAL_CACHE_STRATEGY.md     ← v3.1 快取策略 ✅
    ├── BOOKING_SYSTEM_OPTIMIZATION.md ← v3.0 預約系統優化 ✅
    ├── RESPONSIVE_ARCHITECTURE_DESIGN.md ← v3.0 響應式架構 ✅
    └── COACH_PROFILE_SPEC.md       ← v2.9 教練公開檔案 ✅
```

**定位**：功能規劃階段的詳細規格書，完成後移至 `archived/`

---

## 📝 文檔結構（建議）

```markdown
# [功能名稱]規劃

> 一句話描述

**建立日期**：YYYY-MM-DD
**目標版本**：vX.X
**狀態**：規劃中 / 開發中 / 已完成

---

## 目錄
1. 功能概述
2. 頁面結構 / UI 設計
3. 功能模組
4. 資料流程
5. 檔案規劃
6. 開發任務
7. 特殊規則
8. 待確認事項 / 已確認事項

---

## 開發任務（表格格式）

| # | 類型 | 任務 | 優先級 | 狀態 |
|---|------|------|--------|------|
| XX-1 | Page | 任務說明 | P0 | ⏳ |
```

---

## 🔄 生命週期

| 階段 | 狀態 | 說明 |
|------|------|------|
| 規劃中 | 📝 | 正在討論、設計 |
| 開發中 | 🚧 | 開始實作 |
| 已完成 | ✅ | 功能上線，可歸檔或保留 |
| 已歸檔 | 📦 | 移至 archived/ 或刪除 |

---

## 📋 與其他文檔的關係

| 文檔 | 關係 |
|------|------|
| `DEVELOPMENT_STATUS.md` | 任務清單摘要 + 連結到規劃文檔 |
| `VERSION_HISTORY.md` | 完成後歸檔 |
| `DATABASE_SUPABASE.md` | 新表結構同步 |
| `migrations/README.md` | 新 Migration 同步 |

---

## ✅ 更新時機

| 情況 | 動作 |
|------|------|
| 新功能開始規劃 | 創建新的 `*_SPEC.md` |
| 討論確認決策 | 更新「已確認事項」區塊 |
| 開始開發 | 更新任務狀態 ⏳ → 🚧 |
| 任務完成 | 更新任務狀態 → ✅ |
| 功能上線 | 同步更新 `DEVELOPMENT_STATUS.md` |
| 功能歸檔 | 決定保留或移至 archived/ |

---

## ⚠️ 注意事項

<critical>
1. 規劃文檔是**詳細規格**，不是簡短任務清單
2. 任務清單應同步到 `DEVELOPMENT_STATUS.md`（摘要版）
3. 開發完成後，規劃文檔可保留作為設計參考
4. 不要在規劃文檔寫代碼實作細節（那是 commit 的工作）
</critical>
