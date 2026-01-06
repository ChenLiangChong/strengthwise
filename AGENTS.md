# StrengthWise - AI Agent 開發指南

> AI 程式碼助手開發規範索引

**最後更新**：2026年1月7日 - v3.1（Session Mode 完善 + 功能測試）

---

## 📌 文檔說明

本文檔是 **規則索引**，指向具體規則和詳細文檔。

| 類型 | 位置 | 用途 |
|------|------|------|
| **硬性規則** | `.cursor/rules/*.mdc` | AI 必須遵守的規定 |
| **詳細說明** | `docs/*.md` | 背景、範例、參考 |

---

## 🚨 核心禁令

<critical>
1. **不破壞現有功能** - 修改前先測試
2. **不使用 dynamic** - 除非絕對必要
3. **不直接操作 Supabase** - 必須透過 Service Interface
4. **不硬編碼** - 顏色、尺寸使用主題系統
</critical>

---

## 📋 規則檔案索引

### 核心規則（Always Apply）

| 檔案 | 用途 |
|------|------|
| `000-core-persona.mdc` | AI 人格、認知立場、溝通協議 |
| `001-project-context.mdc` | 專案資訊、技術棧、版本狀態 |
| `900-documentation-index.mdc` | 文檔索引與查閱指南 |
| `999-documentation-maintenance.mdc` | 文檔維護規則 |

### Flutter/Dart 規則

| 檔案 | Glob | 用途 |
|------|------|------|
| `100-flutter-dart-standards.mdc` | `**/*.dart` | 編碼標準、命名規範 |
| `110-flutter-architecture.mdc` | `lib/**/*.dart` | Clean Architecture、依賴注入 |
| `120-flutter-state-management.mdc` | `lib/controllers/**` | Provider、ChangeNotifier |
| `130-flutter-ui-widgets.mdc` | `lib/views/**` | UI 組件、主題系統 |

### 資料庫規則

| 檔案 | Glob | 用途 |
|------|------|------|
| `200-database-supabase.mdc` | `lib/models/**`, `lib/services/**` | Supabase 操作規範 |
| `210-datetime-utils.mdc` | `**/*.dart` | 時間處理統一規範 |
| `220-query-optimization.mdc` | `lib/services/**` | 查詢效能優化 |
| `230-migrations-guide.mdc` | `migrations/**` | Migration 執行順序 |

### UI/UX 規則

| 檔案 | Glob | 用途 |
|------|------|------|
| `300-ui-ux-design.mdc` | `lib/views/**`, `lib/themes/**` | Kinetic 設計系統 |
| `305-ui-ux-pro-max.mdc` | `lib/views/**` | AI 設計智慧資料庫整合 |

### 工作流程規則

| 檔案 | Glob | 用途 |
|------|------|------|
| `800-testing-workflow.mdc` | `test/**` | 測試策略、驗收標準 |
| `810-python-scripts.mdc` | `scripts/**` | Python 工具使用 |
| `820-deployment.mdc` | `android/**`, `ios/**` | 部署流程 |

### 業務邏輯規則

| 檔案 | Glob | 用途 |
|------|------|------|
| `910-domain-health-assessment.mdc` | `lib/**/health_assessment/**` | 健康評估系統 |

### 文檔維護規則

| 檔案 | 用途 |
|------|------|
| `920-docs-database.mdc` | DATABASE_SUPABASE.md 維護 |
| `930-docs-ui.mdc` | UI 文檔維護 |
| `940-docs-development.mdc` | DEVELOPMENT_STATUS.md 維護 |
| `950-docs-saas.mdc` | SAAS_PLATFORM_ROADMAP.md 維護 |
| `960-docs-health-assessment.mdc` | HEALTH_ASSESSMENT_SYSTEM.md 維護 |
| `965-docs-fcm-setup.mdc` | FCM_SETUP_GUIDE.md 維護 |
| `970-docs-readme.mdc` | docs/README.md 維護 |
| `980-docs-project-overview.mdc` | PROJECT_OVERVIEW.md 維護 |

---

## 📚 詳細文檔索引

### 核心文檔

| 文檔 | 用途 |
|------|------|
| `docs/DEVELOPMENT_STATUS.md` ⭐ | 開發狀態、版本記錄、下一步計劃 |
| `docs/PROJECT_OVERVIEW.md` | 專案架構、技術棧 |
| `docs/DATABASE_SUPABASE.md` | 資料庫 Schema、RLS 策略 |

### 技術文檔

| 文檔 | 用途 |
|------|------|
| `docs/DATETIME_UTILS_GUIDE.md` | DateTimeUtils API 完整說明 |
| `docs/UI_DESIGN_SYSTEM.md` | 設計理念、決策 |
| `docs/UI_DEVELOPER_GUIDE.md` | 色彩、字體、間距速查 |

### 功能文檔

| 文檔 | 用途 |
|------|------|
| `docs/HEALTH_ASSESSMENT_SYSTEM.md` | 健康評估系統詳細規格 |
| `docs/SAAS_PLATFORM_ROADMAP.md` | SaaS 平台 Phase 1-5 計劃 |

### 部署與工具

| 文檔 | 用途 |
|------|------|
| `docs/DEPLOYMENT_GUIDE.md` | APK 建置、OAuth 配置 |
| `scripts/README.md` | Python 工具腳本使用 |
| `migrations/README.md` | Migration 執行順序與版本對應 |

### AI 設計工具

| 資源 | 用途 |
|------|------|
| `.shared/ui-ux-pro-max/` | UI/UX 設計智慧資料庫 |
| `.cursor/commands/ui-ux-pro-max.md` | Cursor 指令入口 |

**使用方式**：在 Cursor 中輸入 `/ui-ux-pro-max` 開始使用

---

## 🎯 當前開發狀態

**版本**：v3.1（功能測試 + Widget）🔄 待測試

詳細進度請查看：**[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)**

---

## 🔄 文檔維護原則

| 變更類型 | 更新位置 |
|---------|---------|
| 新增硬性規定 | `.cursor/rules/*.mdc` |
| 功能說明/範例 | `docs/*.md` |
| 版本記錄 | `docs/DEVELOPMENT_STATUS.md` |

詳見：`.cursor/rules/999-documentation-maintenance.mdc`
