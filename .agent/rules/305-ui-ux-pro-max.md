---
description: "UI/UX Pro Max 技能整合：AI 設計智慧資料庫的使用規範。"
globs: lib/views/**/*.dart
alwaysApply: false
---

# UI/UX Pro Max 整合規範

> 本規則與現有 `300-ui-ux-design.md` 分層運作

## 🎯 優先級說明

```
優先級順序：
1. .cursor/rules/*.md        → 硬性規定（禁止、必須）⭐⭐⭐
2. docs/UI_DEVELOPER_GUIDE.md → StrengthWise 設計規範 ⭐⭐
3. ui-ux-pro-max 搜尋結果     → 設計建議與靈感 ⭐
```

<critical>
1. StrengthWise 現有規範優先於 ui-ux-pro-max 建議
2. 顏色必須使用 `Theme.of(context).colorScheme`，不能硬編碼
3. 間距必須遵守 8 點網格系統
</critical>

---

## 🔍 使用方式

### 觸發條件

當需要 UI/UX 設計靈感時，使用 `/ui-ux-pro-max` 指令：

```
/ui-ux-pro-max 設計一個教練公開檔案頁面，健身產業風格
```

### 搜尋語法

```bash
# 搜尋產品類型
python .shared/ui-ux-pro-max/scripts/search.py "fitness health" --domain product

# 搜尋視覺風格
python .shared/ui-ux-pro-max/scripts/search.py "professional minimal" --domain style

# 搜尋 Flutter 最佳實踐
python .shared/ui-ux-pro-max/scripts/search.py "cards theming" --stack flutter
```

---

## 📋 StrengthWise 設計 DNA

| 屬性 | 值 |
|-----|-----|
| **產業** | Fitness / Health |
| **風格** | Professional, Minimal, High-contrast |
| **主色** | `#2563EB` (Titanium Blue) |
| **字體** | Inter (標題)、JetBrains Mono (數據) |
| **深色模式** | `#0F172A` (Deep Slate) |

---

## ⚠️ 整合注意事項

### 當 ui-ux-pro-max 建議與現有規範衝突時

1. **顏色**：使用 `UI_DEVELOPER_GUIDE.md` 的色彩表
2. **間距**：遵守 8 點網格（4, 8, 12, 16, 24, 32, 48）
3. **圓角**：卡片使用 12dp，按鈕使用 8dp
4. **字體**：數據顯示使用 JetBrains Mono

### 可以採用 ui-ux-pro-max 建議的情況

1. 頁面佈局結構
2. 動畫與轉場效果
3. 卡片/組件的設計模式
4. UX 最佳實踐

---

## 📚 相關文檔

- `docs/UI_DEVELOPER_GUIDE.md` - StrengthWise 色彩/字體/間距速查
- `docs/UI_DESIGN_SYSTEM.md` - 設計理念說明
- `.shared/ui-ux-pro-max/data/stacks/flutter.csv` - Flutter 最佳實踐

