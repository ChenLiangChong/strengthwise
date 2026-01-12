# StrengthWise - 開發狀態

> 下一步計劃、當前版本、未來規劃

**當前版本**：v3.4（2026-01-12 完成）  
**上一版本**：v3.3（2026-01-12 完成）  
**維護者**：StrengthWise 開發團隊

---

## 📋 目錄

- [v3.4 已完成](#v34-已完成)
- [未來計劃](#未來計劃)
- [已完成功能](#已完成功能)

---

## v3.4 已完成

> 傷病教練備註顯示修復 + 模板儲存優化

### 完成項目

| 項目 | 說明 |
|------|------|
| ✅ 傷病教練備註顯示 | 學員端健康評估摘要卡片正確顯示教練備註 |
| ✅ 訓練計畫類型統一 | 新增「綜合訓練」，統一 11 種計畫類型 |
| ✅ 模板儲存 TrackingMode | 儲存模板時保留動作的 TrackingMode |
| ✅ 教練動作匯入 | 儲存模板時自動替換為用戶自建動作 ID |

### 修改檔案

| 檔案 | 說明 |
|------|------|
| `health_assessment_tab.dart` | Session Mode 健康評估 Tab 載入傷病備註 |
| `my_health_assessment_page.dart` | 學員健康評估頁面載入傷病備註 |
| `workout_execution_content.dart` | 儲存模板時保留 TrackingMode |
| `plan_type_enum.dart` | 新增 `mixed` 類型，統一 uiOptions |
| `template_editor_page.dart` | 動態顯示各 TrackingMode 動作摘要 |

---

## 未來計劃

### Phase 5+: 進階功能

| 優先級 | 項目 | 說明 |
|--------|------|------|
| 高 | Beta 測試準備 | 招募測試用戶、生產環境配置、性能驗證（perf-2~6）|
| 中 | 訓練計劃模板市場 | 教練分享、學員訂閱 |
| 低 | 社群功能 | 動態分享、排行榜 |
| 低 | AI 功能 | 語音筆記（Whisper）、智能建議（GPT-4）|

### 教練公開檔案未來擴展

PostGIS 地理搜尋、審核狀態機、評價系統、圖片上傳

### 延後項目

| 原編號 | 項目 | 說明 |
|--------|------|------|
| T-17 | 訓練動作卡 PREV | 顯示歷史重量/次數 |
| T-18 | 動作歷史彈窗 | 顯示完整歷史記錄 |
| WG-1~3 | Widget | Android/iOS 桌面小工具 |

---

## 已完成功能

| 版本 | 功能 |
|------|------|
| v1.0 | 單機版（訓練記錄、統計、794 動作）|
| v2.0 | 教練學員系統（Phase 1-4）|
| v2.1-v2.7 | 時區統一、登入驗證、UI 重構 |
| v2.8-v2.8.4 | 健康評估系統、教練評估備註、文檔重構 |
| v2.9-v2.9.1 | 教練公開檔案、訓練權限系統、UX 優化 |
| v3.0 | 預約系統優化、Session Mode、響應式 UI、FCM 推播 |
| v3.1 | Session Mode 完善、性能優化、首頁 UX、離線提示 |
| v3.2 | Coach Mark Onboarding、TrackingMode 擴充、Web PWA |
| v3.3 | TrackingMode 統計適配、PR 修復、Migrations 整理 |
| **v3.4** | **傷病教練備註顯示、模板儲存優化** |

**詳細版本歷史**：[archived/VERSION_HISTORY.md](archived/VERSION_HISTORY.md)  
**技術架構**：[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)  
**規格書**：[planning/](planning/)

---

## 📊 專案狀態摘要

| 項目 | 狀態 |
|------|------|
| v1.0-v3.4 | ✅ 100% |
| 代碼品質 | ✅ 0 linter errors |

**下一步重點**：
1. Beta 測試準備
2. 生產環境性能驗證

---

> ✅ **v3.4 完成**（2026-01-12）：傷病教練備註顯示 + 模板儲存優化
>
> 📱 **Google Play**：內部測試已發布（v1.0.0），等待 Google 審核
>
> 🤖 **CI/CD**：GitHub Actions 已配置（analyze + test + build）
