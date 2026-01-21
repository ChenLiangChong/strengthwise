# 資料庫文檔更新規範

## 🗄️ DATABASE_SUPABASE.md 結構

<critical>
資料庫文檔必須維持以下區塊順序，禁止任意調整：
</critical>

```
DATABASE_SUPABASE.md
├── 1. 架構總覽（表格清單）
├── 2. 表格 Schema（完整欄位定義）
├── 3. RLS 策略
├── 4. Storage 配置
├── 5. 查詢最佳實踐
├── 6. 效能優化
└── 7. Migrations 說明
```

## ✅ 新增表格時必須包含

```
□ CREATE TABLE 語句（完整欄位）
□ 欄位說明（中文）
□ 索引定義
□ RLS 策略
□ migrations/README.md 更新
```

## ❌ 禁止內容

<critical>
DATABASE_SUPABASE.md 禁止包含：
- 詳細查詢代碼列表（Service 層有）
- 即時數據統計（用腳本查詢）
- 歷史修復細節（放 DATABASE_HISTORY.md）
- 未實作的規劃功能
</critical>

---

## 🗃️ DATABASE_HISTORY.md 結構

```
DATABASE_HISTORY.md
├── 遷移歷史（Firestore → Supabase）
├── 版本修復記錄（按版本分組）
└── 架構變更記錄
```

## 📝 何時更新

| 事件 | 動作 |
|-----|------|
| 資料庫修復 | 新增修復記錄（問題、解決方案、Migration 檔案）|
| 表格結構變更 | 記錄變更原因和影響 |
| 重大架構決策 | 記錄決策背景和理由 |

## 📋 記錄格式

```markdown
## vX.Y: 修復標題（日期）

**問題**：簡述問題

**解決方案**：
- 修復方式
- Migration 檔案：`XXX.sql`

**影響**：受影響的表格/功能
```
