---
description: "專案總覽文檔規範：PROJECT_OVERVIEW.md 的結構與維護。"
globs: docs/PROJECT_OVERVIEW.md
alwaysApply: false
---

# 專案總覽文檔規範

## 📄 PROJECT_OVERVIEW.md 定位

**架構參考文件** - 技術棧、目錄結構、開發流程

---

## ✅ 結構

```
PROJECT_OVERVIEW.md
├── 專案簡介（版本、規模）
├── 技術棧（前端、後端）
├── 架構設計（MVVM + Clean Architecture）
├── 目錄結構（lib/ 完整結構）
├── 開發流程（標準 7 步驟）
└── 相關文檔連結
```

---

## ❌ 禁止內容

<critical>
1. 開發進度（應在 DEVELOPMENT_STATUS.md）
2. 版本歷史（應在 VERSION_HISTORY.md）
3. 遷移歷史（應在 DATABASE_HISTORY.md）
4. 詳細開發規範代碼範例（應在 rules）
</critical>

---

## 🔄 更新時機

| 變更 | 動作 |
|------|------|
| 新增技術依賴 | 更新技術棧區塊 |
| 目錄結構變更 | 更新目錄結構區塊 |
| 架構變更 | 更新架構設計區塊 |
| 版本號更新 | 更新專案簡介表格 |
