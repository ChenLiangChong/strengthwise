# 文檔索引

## 📚 文檔地圖

### 核心開發文檔

| 主題 | 檔案路徑 | 何時使用 |
|---|----|----|
| **開發狀態** | `docs/DEVELOPMENT_STATUS.md` | 查詢當前進度、待完成任務 |
| **專案架構** | `docs/PROJECT_OVERVIEW.md` | 了解技術棧、目錄結構 |
| **開發規範** | `AGENTS.md` | 核心規則總覽 |

### 資料庫文檔

| 主題 | 檔案路徑 | 何時使用 |
|---|----|----|
| **完整 Schema** | `docs/DATABASE_SUPABASE.md` | 表格結構、RLS、查詢規範 |
| **時間處理** | `docs/DATETIME_UTILS_GUIDE.md` | 時間解析、格式化 |
| **Migration** | `migrations/README.md` | 執行順序、版本對應 |

### 功能模組文檔

| 主題 | 檔案路徑 | 何時使用 |
|---|----|----|
| **同步架構** | `docs/planning/SYNC_ARCHITECTURE_SPEC.md` | EventBus、Realtime、FCM 決策 ⭐ v4.0 |
| **首頁 + 行事曆** | `docs/planning/HOME_BOOKING_UX_SPEC.md` | 首頁改造、行事曆 Tab、快捷按鈕 |
| **Beta 招募** | `docs/planning/BETA_RECRUITMENT_DESIGN.md` | Beta 測試招募設計 |
| **測試策略** | `docs/planning/TESTING_STRATEGY.md` | Google Play 上架測試計劃 |
| **生產發布** | `docs/planning/PRODUCTION_LAUNCH_GUIDE.md` | 生產環境發布準備 |
| **虛擬學員** | `docs/planning/VIRTUAL_CLIENT_SPEC.md` | 虛擬學員測試功能 |
| **健康評估** | `docs/HEALTH_ASSESSMENT_SYSTEM.md` | PAR-Q+ 問卷、風險評估 |
| **SaaS 路線圖** | `docs/SAAS_PLATFORM_ROADMAP.md` | 未來計劃 |
| **功能規劃（歸檔）** | `docs/planning/archived/*.md` | 已完成的功能規格書 |
| **架構評審 v4.0** | `docs/planning/archived/ARCHITECTURE_REVIEW_V4.md` | 架構優化報告 ✅ |
| **自訂動作改進** | `docs/planning/archived/CUSTOM_EXERCISE_IMPROVEMENTS.md` | 自訂動作功能 ✅ |
| **運動分類分析** | `docs/planning/EXERCISE_CLASSIFICATION_ANALYSIS.md` | 運動分類系統（775 筆審核完成）✅ |
| **v5.0 影響分析** | `docs/planning/V5_IMPACT_ANALYSIS.md` | v5.0 對各層影響盤點 + 向後兼容架構 ✅ |
| **TrackingMode** | `docs/planning/archived/TRACKING_MODE_SPEC.md` | 多追蹤模式適配 ✅ |
| **Session Mode** | `docs/planning/archived/SESSION_MODE_SPEC.md` | 教練上課模式 ✅ |
| **訓練權限** | `docs/planning/archived/TRAINING_PERMISSION_MATRIX.md` | 訓練權限矩陣 ✅ |
| **性能優化** | `docs/planning/archived/DATA_FLOW_ANALYSIS.md` | 快取策略、Isolate ✅ |
| **快取策略** | `docs/planning/archived/LOCAL_CACHE_STRATEGY.md` | 本地快取設計 ✅ |

### UI/UX 文檔

| 主題 | 檔案路徑 | 何時使用 |
|---|----|----|
| **設計系統** | `docs/UI_DESIGN_SYSTEM.md` | 設計理念、決策 |
| **開發指南** | `docs/UI_DEVELOPER_GUIDE.md` | 色彩、字體、間距速查 |

### 部署與工具

| 主題 | 檔案路徑 | 何時使用 |
|---|----|----|
| **部署指南** | `docs/DEPLOYMENT_GUIDE.md` | APK 建置、OAuth 配置 |
| **FCM 推播** | `docs/FCM_SETUP_GUIDE.md` | 推播通知、Edge Functions |
| **Python 腳本** | `scripts/README.md` | 測試資料生成、統計重置 |

---

## 📋 快速查找

| 我想了解... | 查閱文檔 |
|---|----|
| 專案當前狀態 | `DEVELOPMENT_STATUS.md` |
| 資料庫設計 | `DATABASE_SUPABASE.md` |
| 時間處理方式 | `DATETIME_UTILS_GUIDE.md` |
| UI 設計規範 | `UI_DEVELOPER_GUIDE.md` |
| 同步機制（EventBus/Realtime/FCM） | `docs/planning/SYNC_ARCHITECTURE_SPEC.md` |
| 首頁 + 行事曆 UX | `docs/planning/HOME_BOOKING_UX_SPEC.md` |
| 部署流程 | `DEPLOYMENT_GUIDE.md` |
| 推播通知配置 | `FCM_SETUP_GUIDE.md` |
| Python 工具 | `scripts/README.md` |
| Migration 順序 | `migrations/README.md` |
| 健康評估系統 | `HEALTH_ASSESSMENT_SYSTEM.md` |
| TrackingMode 規格 | `docs/planning/archived/TRACKING_MODE_SPEC.md` |
| Session Mode（上課模式） | `docs/planning/archived/SESSION_MODE_SPEC.md` |
| 訓練權限邏輯 | `docs/planning/archived/TRAINING_PERMISSION_MATRIX.md` |
| 性能優化/快取策略 | `docs/planning/archived/DATA_FLOW_ANALYSIS.md` |
| 本地快取設計 | `docs/planning/archived/LOCAL_CACHE_STRATEGY.md` |

---

## 🔍 使用規則

<critical>
1. **主動檢索**：當使用者詢問特定功能時，先讀取相關文檔
2. **衝突檢測**：如果代碼與文檔描述衝突，明確告知
3. **文檔更新**：如果修改代碼導致文檔過時，建議更新
</critical>
