# Project Context - StrengthWise

## 📋 專案資訊

| 項目 | 內容 |
|------|------|
| **專案名稱** | StrengthWise |
| **當前版本** | v4.2（2026-01-20 完成 - 效能優化）|
| **專案類型** | 跨平台健身訓練追蹤應用 |
| **目標平台** | Android / iOS / Windows / Web |

## 🛠️ 技術棧

```
Frontend:
├── Flutter 3.16+ / Dart 3.1+
├── 狀態管理：Provider (ChangeNotifier)
├── 依賴注入：GetIt (Service Locator)
├── 圖表：fl_chart
└── 設計：Material 3 + Kinetic Design

Backend:
├── Supabase (PostgreSQL 14+)
├── Authentication：Supabase Auth + Google Sign-In
├── Storage：Supabase Storage
├── 安全性：Row Level Security (RLS)
└── 時間類型：TIMESTAMPTZ / TSTZRANGE
```

## 🏗️ 架構模式

**MVVM + Clean Architecture**（100% 實施）

```
View Layer (UI)          → lib/views/
    ↓ Provider
Controller Layer         → lib/controllers/
    ↓ Interface
Service Layer            → lib/services/
    ↓
Model Layer              → lib/models/
```

## ✅ 已完成功能

### v1.0 單機版
- 訓練計劃管理、模板系統
- 794 個專業動作資料庫
- 統計分析系統（秒開）
- 身體數據追蹤
- Google Sign-In

### v2.0-v2.9 教練學員平台
- Phase 1：教練學員系統（邀請、綁定、狀態管理）
- Phase 2：預約系統（TSTZRANGE、GiST 排除約束）
- Phase 3：視覺化筆記（SOAP、照片、手繪板）
- Phase 4：統一行事曆、多學員統計
- v2.3-v2.7：資料庫修復、登入驗證、UI 重構
- v2.8：健康評估系統（PAR-Q+ 問卷）
- v2.8.1-v2.8.4：教練評估備註、文檔重構、PR 修復、角色修復
- v2.9：教練公開檔案 + 訓練權限系統
- v2.9.1：訓練 UX 優化（狀態機、休息計時器、權限阻止）
- v3.0：預約系統優化 + Session Mode + 響應式 UI ✅
- v3.1：Session Mode 完善 + Realtime 同步 ✅
- v3.2：Coach Mark + TrackingMode + Web PWA ✅
- v3.3：TrackingMode 統計適配 + PR 修復 ✅
- v3.4：傷病教練備註顯示 + 模板儲存優化 ✅
- v3.5：MVVM CUD 事件修復（Controller 統一發布事件）✅
- v3.6：MVVM 純架構重構（View 完全透過 Controller）✅
- v3.7：快取架構統一 + DI 優化 + Bug 修復 ✅
- v3.8：時間輸入 UX 優化 + 訓練執行計時器 ✅
- v3.9：跨用戶即時同步 + FCM 完善 + BookingPage 優化 ✅
- v4.0：架構優化 + Controller Interface 統一 ✅
- v4.1：Service 單元測試（24 個 Service，370 測試）✅
- v4.2：效能優化（UI 渲染 + 啟動/網路）✅

## 📊 專案規模

```
總代碼量：~70,000 行
├── Flutter/Dart：~66,000 行
├── SQL/Migrations：~4,200 行（32 個檔案）
└── Python 腳本：~1,800 行

核心組件：
├── Pages：65+
├── Controllers：29（含 70+ 子模組）
├── Services：60+（含 Realtime、Notification）
├── Interfaces：25 Controller + 20+ Service
├── Models：73+
├── Widgets：234+（含 Coach Mark）
└── Tests：370+（Service 單元測試）
```

## 🔗 關鍵文檔

- **開發狀態**：`docs/DEVELOPMENT_STATUS.md` ⭐⭐⭐
- **資料庫設計**：`docs/DATABASE_SUPABASE.md`
- **專案架構**：`docs/PROJECT_OVERVIEW.md`
- **開發規範**：`AGENTS.md`
