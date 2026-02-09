# StrengthWise - 開發狀態

> 下一步計劃、當前版本、未來規劃

**當前版本**：v5.2（2026-02-09 完成 - 全面安全加固）
**上一版本**：v5.1（2026-02-09 完成 - App 版本檢查）
**維護者**：StrengthWise 開發團隊

---

## 📋 目錄

- [下一步計劃](#下一步計劃)
- [已完成版本](#已完成版本)
- [未來計劃](#未來計劃)
- [已完成功能](#已完成功能)

---

## 下一步計劃

### v5.2 全面安全加固（✅ 完成）

**目標**：安全審計後修復 11 項問題（4 HIGH + 4 MEDIUM + 3 LOW）

| # | 項目 | 嚴重度 | 狀態 |
|---|------|--------|------|
| 1 | 邀請碼 DELETE RLS 修復（Migration 35） | HIGH | ✅ 完成 |
| 2 | 密碼驗證強化（6→8 字元 + 字母數字） | HIGH | ✅ 完成 |
| 3 | 頭像上傳驗證（5MB + 副檔名 + magic bytes） | HIGH | ✅ 完成 |
| 4 | Edge Function 錯誤回應加固 | HIGH | ✅ 完成 |
| 5 | Edge Function CORS 限制 | MEDIUM | ✅ 完成 |
| 6 | Edge Function Payload 日誌精簡 | MEDIUM | ✅ 完成 |
| 7 | Hive 快取 AES-256 加密 | MEDIUM | ✅ 完成 |
| 8 | AndroidManifest allowBackup=false | MEDIUM | ✅ 完成 |
| 9 | Google Client ID 移至 .env | LOW | ✅ 完成 |
| 10 | Edge Function HSTS Header | LOW | ✅ 完成 |
| 11 | Release 建置混淆文件化 | LOW | ✅ 完成 |

**技術決策**：
- Hive 加密金鑰存於 `flutter_secure_storage`，升級後舊快取自動重建
- Edge Function 為內部 webhook 通訊，移除 CORS `*`
- 頭像驗證三重檢查：檔案大小 → 副檔名白名單 → magic bytes

---

### v5.1 App 版本檢查（✅ 完成）

**目標**：在「我的」頁面底部顯示版本號，並從 Supabase 遠端檢查是否有新版本

| # | 任務 | 類型 | 狀態 |
|---|------|------|------|
| 1 | Migration 34：app_config 表（key-value，公開讀取）| SQL | ✅ 完成 |
| 2 | AppVersionConfig Model | Dart | ✅ 完成 |
| 3 | VersionUtils 語意版本比較 | Dart | ✅ 完成 |
| 4 | IAppConfigService 介面 + AppConfigService 實作 | Dart | ✅ 完成 |
| 5 | Service 註冊（LazySingleton）| Dart | ✅ 完成 |
| 6 | AppVersionInfo Widget（純文字提示）| UI | ✅ 完成 |
| 7 | 單元測試（20 測試案例）| 測試 | ✅ 完成 |

**技術決策**：
- `app_config` 表採 key-value 設計，可擴展其他配置（不限版本）
- 公開讀取 RLS，僅 service_role 可寫入（透過 Supabase Dashboard）
- SharedPreferences 離線快取 + 忽略版本記憶
- `package_info_plus` 取得執行時版本號
- 純 `Text.rich()` + `TapGestureRecognizer` 行內提示（不使用 Card/Dialog）

---

### Beta 測試前（高優先級）

| 項目 | 工作量 | 狀態 |
|------|--------|------|
| 核心 Service 單元測試補充 | 3-5 天 | ✅ 完成 |
| 執行測試驗證 | 1 天 | ✅ 完成 |

**測試完成**：24 個 Service Interface 已建立完整測試（370 測試案例全部通過）

### Beta 測試後（低優先級）

| 項目 | 工作量 | 說明 |
|------|--------|------|
| RLS 策略完整性驗證 | 1 天 | ✅ v5.2 已完成安全審計 |
| LocalCacheManager 統一 | — | ✅ 評估後保留現狀（並行初始化 + 獨立版本控制 + 各自特殊邏輯）|
| 離線寫入佇列機制 | 評估中 | Write-Through Queue + 網路恢復自動重試 |

---

## 已完成版本

> 詳細版本歷史：[archived/VERSION_HISTORY.md](archived/VERSION_HISTORY.md)

---

## 未來計劃

### Phase 5+: 進階功能

| 優先級 | 項目 | 說明 |
|--------|------|------|
| 高 | Beta 測試準備 | 招募測試用戶、生產環境配置、性能驗證（perf-2~6）|
| ✅ | App 版本檢查 | ✅ v5.1 完成（「我的」頁面版本號 + 遠端更新提示）|
| 中 | 訓練計劃模板市場 | 教練分享、學員訂閱 |
| 低 | 社群功能 | 動態分享、排行榜 |
| 低 | AI 功能 | 語音筆記（Whisper）、智能建議（GPT-4）|

### 架構優化（非緊急）

| 優先級 | 項目 | 說明 |
|--------|------|------|
| ✅ | 統一 LocalCacheManager | 評估後保留 5 個獨立 Service（並行初始化、獨立版本控制、各自特殊邏輯）|
| ✅ | Controller 接口統一 | 已完成 25/29（86%），詳見 v4.0 架構優化 |
| ✅ | 強制解包優化 | 已完成 42→8 處（↓81%），剩餘皆有前置 null 檢查 |
| ✅ | dynamic 使用優化 | P0 完成（3 個檔案），剩餘為序列化邊界 |

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
| v1.0 | 單機版（訓練記錄、統計、775 動作）|
| v2.0 | 教練學員系統（Phase 1-4）|
| v2.1-v2.7 | 時區統一、登入驗證、UI 重構 |
| v2.8-v2.8.4 | 健康評估系統、教練評估備註、文檔重構 |
| v2.9-v2.9.1 | 教練公開檔案、訓練權限系統、UX 優化 |
| v3.0 | 預約系統優化、Session Mode、響應式 UI、FCM 推播 |
| v3.1 | Session Mode 完善、性能優化、首頁 UX、離線提示 |
| v3.2 | Coach Mark Onboarding、TrackingMode 擴充、Web PWA |
| v3.3 | TrackingMode 統計適配、PR 修復、Migrations 整理 |
| v3.4 | 傷病教練備註顯示、模板儲存優化 |
| v3.5 | MVVM CUD 事件修復（Controller 統一發布事件）|
| v3.6 | MVVM 純架構重構（View 完全透過 Controller）|
| v3.7 | 快取架構統一 + DI 優化 + Bug 修復 |
| v3.8 | 時間輸入 UX 優化 + 訓練執行計時器 |
| v3.9 | 跨用戶即時同步 + FCM 完善 + BookingPage 優化 |
| v4.0 | 架構優化 + Controller Interface 統一 |
| v4.1 | Service 單元測試（24 個 Service，370 測試）|
| v4.2 | 效能優化（UI 渲染 + 啟動/網路）|
| v4.3 | UI/UX 微調（TIME 佈局 + 背景計時器）|
| v5.0 | 動作分類系統 v2（775 動作 + 2344 別名 + Hive 離線搜尋 + 統計遷移）|
| v5.1 | App 版本檢查（遠端版本配置 + 行內更新提示） |
| **v5.2** | **全面安全加固（RLS + 密碼 + 上傳驗證 + Hive 加密 + Edge Function）** |

**詳細版本歷史**：[archived/VERSION_HISTORY.md](archived/VERSION_HISTORY.md)  
**技術架構**：[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)  
**規格書**：[planning/](planning/)

---

## 📊 專案狀態摘要

| 項目 | 狀態 |
|------|------|
| v1.0-v5.2 | ✅ 100% |
| 代碼品質 | ✅ 0 issues（517→0，含 deprecated API 處理）|
| MVVM 架構 | ✅ 100% 合規 |
| 快取架構 | ✅ Service 層統一管理 |
| Realtime 同步 | ✅ 跨用戶即時同步 |
| Controller Interface | ✅ 86% 覆蓋（25/29） |
| ErrorService 注入 | ✅ 全部 Service 已注入 |
| dynamic 型別安全 | ✅ P0 完成（剩餘為序列化邊界） |
| Service 單元測試 | ✅ 24 個 Service（370 測試案例） |

**下一步重點**：
1. Beta 測試準備（招募、生產環境配置）
2. 實機效能驗證

---

> ✅ **v5.2 完成**（2026-02-09）：全面安全加固（RLS + 密碼 + 上傳驗證 + Hive 加密 + Edge Function）
>
> ✅ **v5.1 完成**（2026-02-09）：App 版本檢查（遠端版本配置 + 行內更新提示）
>
> ✅ **v5.0 完成**（2026-02-08）：動作分類系統 v2（775 動作 + 2344 別名 + Hive 離線搜尋 + 統計遷移）
>
> ✅ **v4.3 完成**（2026-01-22）：UI/UX 微調（TIME 佈局優化 + 背景計時器修復）
>
> ✅ **v4.2 完成**（2026-01-20）：效能優化（UI 渲染 + 啟動/網路優化）
>
> ✅ **v4.1 完成**（2026-01-20）：Service 單元測試（24 個 Service，370 測試案例全部通過）
>
> ✅ **v4.0 完成**（2026-01-19）：架構優化 + Controller Interface 統一（25/29 = 86%）
>
> 📱 **Google Play**：v1.2.0+17（2026-02-10 公測版本）
>
> 🌐 **Web**：v1.1.0（2026-01-17 發布）
>
> 🤖 **CI/CD**：GitHub Actions 已配置（analyze + test + build）
