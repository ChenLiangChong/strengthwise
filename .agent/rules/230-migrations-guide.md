---
description: "資料庫 Migration 執行規範：版本順序、合併策略、注意事項。適用於 SQL 遷移檔案。"
globs: migrations/**/*.sql,migrations/README.md
alwaysApply: false
---

# Migration 規範

<critical>
1. 必須按編號順序執行（001 → 021）
2. 不可跳過（v2.0 依賴 v1.0 的 users 表）
3. 所有 SQL 使用 `IF NOT EXISTS`（冪等性）
4. 需先啟用 Supabase Auth
</critical>

## 📋 新增 Migration 命名

```
0XX_功能名稱.sql

範例：
022_new_feature.sql
023_fix_something.sql
```

---

## 📝 README.md 更新規則

### 新增 Migration 時

1. **執行順序區塊**：加入新檔案
2. **版本對應表**：更新版本範圍

### 每個檔案說明格式

```markdown
0XX_檔案名.sql  # 一句話說明
```

### 禁止內容

<critical>
- 詳細 SQL 程式碼（看檔案本身）
- 「合併自」來源說明
- 開發歷史
</critical>

---

## 📊 版本對應

| Migration | 版本 |
|-----------|------|
| 001-004 | v1.0 單機版 |
| 005-007 | v2.0 教練學員系統 |
| 008-013 | v2.1-v2.4 修復增強 |
| 016-021 | v2.8 健康評估 |

詳見：`migrations/README.md`

