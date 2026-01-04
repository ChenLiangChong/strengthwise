# StrengthWise - 開發狀態

> 下一步計劃、當前版本、未來規劃

**當前版本**：v2.9.1（2026-01-05 進行中）  
**訓練 UX 優化**：TRN-1 ~ TRN-6 完成 ✅  
**維護者**：StrengthWise 開發團隊

---

## 📋 目錄

- [下一步計劃（v2.9.1）](#下一步計劃v291)
- [未來計劃](#未來計劃)
- [已完成功能](#已完成功能)

---

## 下一步計劃（v2.9.1）

### 🎯 v2.9.1 總覽

| 模組 | 說明 | 狀態 |
|------|------|------|
| **訓練 UX 優化** | 訓練記錄頁面改進 | ✅ 6/7 |
| **性能監控** | 驗證應用效能指標 | ⏳ 0/6 |
| **UX 優化** | 改善使用者體驗 | ⏳ 0/7 |
| **Bug 檢查** | 跨平台 UI 測試 | ⏳ 0/3 |

---

### 🏋️ 訓練 UX 優化（7 項）

| # | 項目 | 說明 | 狀態 |
|---|------|------|------|
| TRN-1 | 訓練頁面雙模式 | pending→in_progress→paused→completed 狀態機；離開時保存 elapsed_seconds | ✅ |
| TRN-2 | 非創建者權限阻止 | 學員無法刪除教練計畫/動作/減少組數；App 層面提前阻止 | ✅ |
| TRN-3 | 訓練卡片來源標識 | 行事曆卡片顯示「自主訓練」或「教練計畫」標籤 | ✅ |
| TRN-4 | 訓練時長正確記錄 | 新增欄位 actual_start_time/actual_end_time/elapsed_seconds/training_status | ✅ |
| TRN-5 | 休息倒數計時器 | 內建計時器幫助使用者倒數休息時間（打勾後彈出選擇）| ✅ |
| TRN-6 | 右上角時鐘移除 | 無意義的時鐘功能已移除 | ✅ |
| TRN-7 | 預約標籤用途釐清 | 釐清預約標籤的使用場景（教練上課用？待討論）| ⏳ |

#### 📦 TRN-4 資料庫 Migration

```sql
-- 027_add_training_status_fields.sql
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS actual_start_time TIMESTAMPTZ;
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS actual_end_time TIMESTAMPTZ;
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS elapsed_seconds INTEGER DEFAULT 0;
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS training_status TEXT DEFAULT 'pending';
-- training_status: pending | in_progress | paused | completed

COMMENT ON COLUMN workout_plans.actual_start_time IS '實際開始訓練的時間';
COMMENT ON COLUMN workout_plans.actual_end_time IS '實際結束訓練的時間';
COMMENT ON COLUMN workout_plans.elapsed_seconds IS '累計訓練秒數（不含暫停時間）';
COMMENT ON COLUMN workout_plans.training_status IS '訓練狀態：pending/in_progress/paused/completed';
```

---

### 📊 性能監控（6 項）

| # | 項目 | 目標 | 狀態 |
|---|------|------|------|
| perf-1 | 應用啟動時間 | 冷啟動 <200ms | ⏳ |
| perf-2 | 主線程 Frames Skip | <30，FPS >55 | ⏳ |
| perf-3 | 統計頁面載入 | 快取 <5ms | ⏳ |
| perf-4 | 記憶體使用 | 增長 <50MB | ⏳ |
| perf-5 | 網路查詢延遲 | 95% <50ms | ⏳ |
| perf-6 | Storage 上傳 | 5MB <3 秒 | ⏳ |

---

### 🎨 UX 優化（7 項）

| # | 項目 | 說明 | 狀態 |
|---|------|------|------|
| UX-1 | 照片上傳 Loading | 進度條 + 百分比 | ⏳ |
| UX-2 | 資料載入 Shimmer | 骨架屏佔位符 | ⏳ |
| UX-3 | 網路錯誤提示 | 友善提示 + 重試機制 | ⏳ |
| UX-4 | 離線模式提示 | 頂部 Banner | ⏳ |
| UX-5 | 無學員引導頁面 | 空狀態 + 邀請按鈕 | ⏳ |
| UX-6 | 無訓練引導頁面 | 空狀態 + 創建按鈕 | ⏳ |
| UX-7 | 無筆記引導頁面 | 空狀態 + 新增按鈕 | ⏳ |

---

### 🐛 Bug 檢查（3 項）

| # | 項目 | 檢查重點 | 狀態 |
|---|------|---------|------|
| Bug-1 | 不同屏幕尺寸 | UI 不溢出、文字自適應 | ⏳ |
| Bug-2 | 深色模式 | 對比度、陰影 | ⏳ |
| Bug-3 | 淺色模式 | 文字清晰、按鈕狀態 | ⏳ |

---

### ✅ v2.9.1 完成標準

- [x] 訓練 UX 優化完成（6/7）⭐ 2026-01-05
- [ ] 性能指標達標（6/6）
- [ ] UX 優化完成（7/7）
- [ ] 0 個 Critical Bugs（3/3）

---

### 📝 v2.9.1 完成後需更新的文檔

| 文檔 | 更新內容 |
|------|---------|
| `VERSION_HISTORY.md` | 歸檔 v2.9.1 |

---

## 未來計劃

### Phase 5+: 進階功能

| 優先級 | 項目 | 說明 |
|--------|------|------|
| 高 | Onboarding 流程 | 首次使用引導頁面 |
| 高 | Beta 測試準備 | 招募測試用戶、生產環境配置 |
| 中 | 訓練計劃模板市場 | 教練分享、學員訂閱 |
| 低 | 社群功能 | 動態分享、排行榜 |
| 低 | 語音筆記 | 語音轉文字（Whisper API）|
| 低 | AI 功能 | 智能筆記建議（GPT-4）|

### 教練公開檔案未來擴展

| 項目 | 說明 |
|------|------|
| PostGIS 地理搜尋 | 搜尋附近教練 |
| 審核狀態機 | pending → verified |
| Edge Functions | 權限提升流程 |
| 公開搜尋 | RLS 政策開放 |
| 圖片上傳 | gallery_images |
| 評價系統 | 學員評價教練 |

---

## 已完成功能

| 版本 | 功能 |
|------|------|
| v1.0 | 單機版（訓練記錄、統計、794 動作）|
| v2.0 | 教練學員系統（Phase 1-4）|
| v2.1-v2.7 | 時區統一、登入驗證、UI 重構 |
| v2.8 | 健康評估系統 |
| v2.8.1 | 教練評估備註 |
| v2.8.2 | 文檔架構重構 |
| v2.8.3 | PR 觸發器修復 |
| v2.8.4 | 用戶角色修復 |
| v2.9 | 教練公開檔案 + 訓練權限系統 |

**詳細版本歷史**：[archived/VERSION_HISTORY.md](archived/VERSION_HISTORY.md)  
**技術架構**：[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)

---

## 📊 專案狀態摘要

| 項目 | 狀態 |
|------|------|
| v1.0 單機版 | ✅ 100% |
| v2.0-v2.8.4 教練學員系統 | ✅ 100% |
| v2.9 教練公開檔案 | ✅ 100% |
| 代碼品質 | ✅ 0 linter errors |

**下一步重點**：訓練 UX 優化 → 性能監控 → UX 優化 → Bug 檢查
