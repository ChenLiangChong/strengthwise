---
description: "健康評估系統文檔規範：HEALTH_ASSESSMENT_SYSTEM.md 的結構與維護。"
globs: docs/HEALTH_ASSESSMENT_SYSTEM.md
alwaysApply: false
---

# 健康評估系統文檔規範

## 📄 HEALTH_ASSESSMENT_SYSTEM.md 結構

```
HEALTH_ASSESSMENT_SYSTEM.md
├── 系統概述（目的、功能列表）
├── 資料庫設計（表結構、列舉）
├── PAR-Q+ 問卷（7 題說明、判定邏輯）
├── 資料模型（Model 欄位列表）
├── Service 層（Interface 定義）
├── 權限控制（RLS 政策）
└── 使用流程（操作步驟）
```

---

## ✅ 必須包含

- PAR-Q+ 7 題完整說明
- 表結構（`health_assessments`、`coach_assessment_notes`）
- RLS 策略概念
- 使用流程

---

## ❌ 禁止內容

<critical>
1. 開發進度追蹤（應在 DEVELOPMENT_STATUS.md）
2. 完成度百分比
3. 待完成項目清單
4. 詳細代碼實作（只保留結構）
</critical>

---

## 🔄 更新時機

| 變更類型 | 更新內容 |
|---------|---------|
| 新增表格/欄位 | 資料庫設計區塊 |
| 新增問卷題目 | PAR-Q+ 問卷區塊 |
| RLS 政策變更 | 權限控制區塊 |
| 流程變更 | 使用流程區塊 |

