---
description: "健康評估系統業務邏輯：PAR-Q+ 問卷、風險評估、教練備註。適用於健康評估相關代碼。"
globs: lib/**/health_assessment/**/*.dart,lib/views/pages/relationships/role_coach/health_assessment_page.dart
alwaysApply: false
---

# 健康評估系統（v2.8）

<critical>
1. 教練備註必須 RLS 隔離（學員不可見）
2. 高風險學員必須簽署免責聲明
3. PAR-Q+ 標準：7 個核心問題
</critical>

## 🔄 5 步驟表單

| 步驟 | 內容 |
|------|------|
| 1 | PAR-Q+ 篩檢（7 個是/否問題）|
| 2 | 傷病史 |
| 3 | 生活型態 |
| 4 | 訓練目標 |
| 5 | 緊急聯絡人 |

## ⚠️ 風險評估

| 等級 | 條件 |
|------|------|
| 🟢 低風險 | PAR-Q+ 全部「否」|
| 🟡 中風險 | 有「是」但非關鍵 |
| 🔴 高風險 | 心臟病史、暈眩 |

## 🔐 RLS 原則

```sql
-- 學員只能看自己的評估
-- 教練只能看自己學員的評估
-- 教練備註對學員完全不可見
```

詳見：`@docs/HEALTH_ASSESSMENT_SYSTEM.md`
