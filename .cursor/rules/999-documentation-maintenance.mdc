# 文檔維護通用規則

<critical>
1. **規則權威來源**：`.cursor/rules/*.mdc` 是硬性規定的唯一來源
2. **文檔定位**：`docs/*.md` 是說明文檔，提供背景和範例
3. **不重複**：規則檔只包含規定，詳細說明指向 docs
</critical>

## 📐 分工原則

```
.cursor/rules/*.mdc          docs/*.md
─────────────────           ─────────────
硬性規定（禁止、必須）        詳細說明、範例
Glob 觸發條件               歷史背景、決策原因
簡短代碼範例                完整使用案例
更新頻率：低                更新頻率：高
```

## 📝 何時更新什麼

| 變更類型 | 更新位置 |
|---------|---------|
| 新增功能 | `docs/DEVELOPMENT_STATUS.md` |
| 新增/修改表格 | → `920-docs-database.mdc` 規範 |
| UI 設計變更 | → `930-docs-ui.mdc` 規範 |
| 版本歸檔 | → `940-docs-development.mdc` 規範 |
| 新增禁止/必須規定 | `.cursor/rules/*.mdc` |
| 功能說明/範例擴充 | `docs/*.md` |
| **新功能規劃** | → `990-docs-planning.mdc` 規範 |

## 📚 各領域文檔規則索引

| 領域 | 規則檔案 | 相關文檔 |
|------|---------|---------|
| 資料庫 | `920-docs-database.mdc` | DATABASE_SUPABASE.md, DATABASE_HISTORY.md |
| UI/UX | `930-docs-ui.mdc` | UI_DESIGN_SYSTEM.md, UI_DEVELOPER_GUIDE.md |
| 開發狀態 | `940-docs-development.mdc` | DEVELOPMENT_STATUS.md, VERSION_HISTORY.md |
| SaaS 路線圖 | `950-docs-saas.mdc` | SAAS_PLATFORM_ROADMAP.md, SAAS_HISTORY.md |
| 健康評估 | `960-docs-health-assessment.mdc` | HEALTH_ASSESSMENT_SYSTEM.md |
| **FCM 推播** | `965-docs-fcm-setup.mdc` | FCM_SETUP_GUIDE.md, supabase/functions/ |
| 文檔索引 | `970-docs-readme.mdc` | docs/README.md |
| 專案總覽 | `980-docs-project-overview.mdc` | PROJECT_OVERVIEW.md |
| **規劃文檔** | `990-docs-planning.mdc` | docs/planning/*.md |

---

## ✅ 完成功能後檢查清單

```
□ docs/DEVELOPMENT_STATUS.md - 更新版本號
□ 相關功能文檔 - 如需要
□ .cursor/rules/*.mdc - 只有「規則變更」時才更新
□ 測試完成後 - 歸檔到 VERSION_HISTORY.md
```

---

## 🔄 更新文檔時的檢查流程

當用戶要求更新 `DEVELOPMENT_STATUS.md` 時：

<critical>
1. **回顧本次對話**：列出所有代碼/SQL/UI 變更
2. **判斷影響範圍**：根據變更類型確定需要同步的文檔
3. **列出清單**：請用戶確認是否有遺漏
3. **一次性更新**：更新所有相關文檔
4. **列出清單**：告知用戶更新了哪些文檔
</critical>

### 變更類型對應

| 變更類型 | 需要同步 |
|---------|---------|
| 新增 SQL migration | migrations/README.md |
| 新增/修改表格 | DATABASE_SUPABASE.md |
| UI 組件變更 | UI_DEVELOPER_GUIDE.md |
| 版本號變更 | PROJECT_OVERVIEW.md、AGENTS.md |
| 功能測試完成 | VERSION_HISTORY.md（歸檔）|
| Edge Function 變更 | FCM_SETUP_GUIDE.md |
