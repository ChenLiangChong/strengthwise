# 文檔維護通用規則

<critical>
1. **規則權威來源**：`.claude/rules/*.md` 是硬性規定的唯一來源
2. **文檔定位**：`docs/*.md` 是說明文檔，提供背景和範例
3. **不重複**：規則檔只包含規定，詳細說明指向 docs
</critical>

## 📐 分工原則

```
.claude/rules/*.md              docs/*.md
─────────────────              ─────────────
硬性規定（禁止、必須）           詳細說明、範例
Glob 觸發條件                  歷史背景、決策原因
簡短代碼範例                   完整使用案例
更新頻率：低                   更新頻率：高
```

## 📝 何時更新什麼

| 變更類型 | 更新位置 |
|---------|---------|
| 新增功能 | `docs/DEVELOPMENT_STATUS.md` |
| 新增/修改表格 | DATABASE_SUPABASE.md + migrations/README.md |
| UI 設計變更 | UI_DESIGN_SYSTEM.md → UI_DEVELOPER_GUIDE.md → app_theme.dart |
| 版本歸檔 | VERSION_HISTORY.md |
| 新功能規劃 | `docs/planning/*.md`（完成後移 archived/）|
| Edge Function 變更 | FCM_SETUP_GUIDE.md |
| 新增禁止/必須規定 | `.claude/rules/*.md` |

---

## 📚 各領域文檔維護規範

### 資料庫（DATABASE_SUPABASE.md + DATABASE_HISTORY.md）

<critical>
文檔必須維持區塊順序：架構總覽 → 表格 Schema → RLS → Storage → 查詢實踐 → 效能 → Migrations
</critical>

**新增表格必須包含**：CREATE TABLE、欄位說明、索引、RLS、migrations/README.md 更新

**禁止**：詳細查詢代碼、即時數據統計、歷史修復細節（放 DATABASE_HISTORY.md）

**DATABASE_HISTORY.md**：遷移歷史 + 版本修復記錄 + 架構變更記錄

### 開發狀態（DEVELOPMENT_STATUS.md + VERSION_HISTORY.md）

**結構**：下一步計劃 ⭐ → 當前版本 → 未來計劃 → 已完成功能

**歸檔流程**：完成 → 測試通過 → 詳細移至 VERSION_HISTORY.md → 主文檔保留簡短清單

**歸檔保留**：版本號+日期、功能列表、技術亮點、架構決策
**歸檔不保留**：測試步驟、檔案列表、時間估算、Bug 修復步驟

### SaaS 路線圖（SAAS_PLATFORM_ROADMAP.md + SAAS_HISTORY.md）

**禁止**：詳細 SQL、已完成功能實作細節、已捨棄規劃、測試/Bug 記錄

### 健康評估（HEALTH_ASSESSMENT_SYSTEM.md）

**必須**：PAR-Q+ 7 題完整說明、表結構、RLS 策略、使用流程
**禁止**：開發進度、完成度百分比、待完成清單

### 文檔索引（docs/README.md）

**純索引文件**，只包含連結。**禁止**：進度說明、Phase 列表、代碼範例

### 專案總覽（PROJECT_OVERVIEW.md）

**架構參考文件**。**禁止**：開發進度、版本歷史、遷移歷史

### UI/UX（UI_DESIGN_SYSTEM.md + UI_DEVELOPER_GUIDE.md）

更新鏈：UI_DESIGN_SYSTEM.md（理念）→ UI_DEVELOPER_GUIDE.md（數值）→ app_theme.dart（代碼）

---

## ✅ 完成功能後檢查清單

```
□ docs/DEVELOPMENT_STATUS.md - 更新版本號
□ 相關功能文檔 - 如需要
□ .claude/rules/*.md - 只有「規則變更」時才更新
□ 測試完成後 - 歸檔到 VERSION_HISTORY.md
```

---

## 🔄 更新文檔時的檢查流程

<critical>
1. **回顧本次對話**：列出所有代碼/SQL/UI 變更
2. **判斷影響範圍**：根據變更類型確定需要同步的文檔
3. **列出清單**：請用戶確認是否有遺漏
4. **一次性更新**：更新所有相關文檔
5. **列出清單**：告知用戶更新了哪些文檔
</critical>

### 變更類型對應

| 變更類型 | 需要同步 |
|---------|---------|
| 新增 SQL migration | migrations/README.md |
| 新增/修改表格 | DATABASE_SUPABASE.md |
| UI 組件變更 | UI_DEVELOPER_GUIDE.md |
| 版本號變更 | PROJECT_OVERVIEW.md、CLAUDE.md |
| 功能測試完成 | VERSION_HISTORY.md（歸檔）|
| Edge Function 變更 | FCM_SETUP_GUIDE.md |
