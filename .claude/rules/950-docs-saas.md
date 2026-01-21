# SaaS 路線圖文檔規範

## 📄 SAAS_PLATFORM_ROADMAP.md 結構

```
SAAS_PLATFORM_ROADMAP.md
├── 轉型概述（設計哲學、版本對照）
├── 已完成功能（簡短清單，無細節）
├── 未來計劃（待完成項目）
└── 成功指標（KPI）
```

## ✅ 內容規範

**已完成功能**：
- 每個 Phase 只保留功能清單
- 不包含實作細節
- 不包含檔案數量、行數

**未來計劃**：
- 只保留標題和待辦項目
- 要做時再擴展細節

## ❌ 禁止內容

<critical>
SAAS_PLATFORM_ROADMAP.md 禁止包含：
- 詳細 SQL 代碼（migrations 裡有）
- 已完成功能的實作細節
- 已捨棄的規劃功能
- 測試步驟、Bug 修復記錄
</critical>

---

## 🗃️ SAAS_HISTORY.md 結構

```
SAAS_HISTORY.md（歸檔）
├── Phase 完成記錄（按時間順序）
└── 每個 Phase：核心成果 + 技術亮點（~10 行）
```

## 📝 歸檔時機

| 狀態 | 位置 |
|------|------|
| 進行中 | SAAS_PLATFORM_ROADMAP.md（未來計劃區） |
| 已完成 | SAAS_HISTORY.md（歸檔）+ ROADMAP 已完成清單 |

## 📋 歸檔格式

```markdown
## Phase X：標題（日期）

**核心成果**：
- 功能 1
- 功能 2

**技術亮點**：
- 創新做法
```
