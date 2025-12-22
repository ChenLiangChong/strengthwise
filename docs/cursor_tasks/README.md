# Cursor 任務文檔使用指南

> 這些文檔專為 Cursor（特別是 Composer 模式）設計，將任務拆解成明確的步驟，讓 AI 更專注，寫出的程式碼品質會大幅提升。

---

## 📋 文檔結構

```
docs/cursor_tasks/
├── README.md                    # 本文件（使用指南）
├── 00_PROJECT_CONTEXT.md       # 專案全貌與規則（必須先讀）
├── 01_TASK_DB_REFACTOR.md      # 任務一：使用者資料庫重構
├── 02_TASK_RELATIONSHIPS.md    # 任務二：教練學員綁定
├── 03_TASK_BOOKING.md          # 任務三：預約系統核心
└── 04_TASK_TEACHING.md         # 任務四：教學筆記整合
```

---

## 🚀 使用方式

### 方式 1：使用 Cursor Composer（推薦）

1. **開啟 Cursor Composer**
   - 按 `Ctrl+I`（Windows）或 `Cmd+I`（Mac）
   - 或點擊 Cursor 介面上的 Composer 按鈕

2. **讀取專案全貌**
   ```
   請先閱讀 docs/cursor_tasks/00_PROJECT_CONTEXT.md
   理解專案架構、技術棧和開發規範
   ```

3. **執行任務**
   ```
   請閱讀 docs/cursor_tasks/01_TASK_DB_REFACTOR.md
   並按照文件中的步驟執行任務
   ```

4. **依序執行**
   - 完成任務一後，再執行任務二
   - 每個任務都有明確的前置任務要求

### 方式 2：使用 Cursor Chat

直接在對話中引用文檔：

```
請參考 docs/cursor_tasks/01_TASK_DB_REFACTOR.md
幫我實作使用者資料庫重構功能
```

---

## 📝 任務執行順序

### ✅ 必須按順序執行

1. **00_PROJECT_CONTEXT.md** - 理解專案全貌（必須先讀）
2. **01_TASK_DB_REFACTOR.md** - 使用者資料庫重構（優先級最高）
3. **02_TASK_RELATIONSHIPS.md** - 教練學員綁定（需要任務一完成）
4. **03_TASK_BOOKING.md** - 預約系統核心（需要任務二完成）
5. **04_TASK_TEACHING.md** - 教學筆記整合（需要任務三完成）

---

## 🎯 每個任務的結構

每個任務文檔都包含：

1. **目標** - 任務要達成的目標
2. **資料庫設計** - 需要的資料結構
3. **Model 實作** - 資料模型定義
4. **Service 實作** - 業務邏輯層
5. **UI 實作需求** - 用戶介面要求
6. **執行步驟** - 具體的實作步驟
7. **注意事項** - 重要的提醒
8. **驗證標準** - 完成標準檢查清單

---

## 💡 使用技巧

### 1. 一次只執行一個任務

不要同時執行多個任務，確保每個任務完成後再進行下一個。

### 2. 先理解再實作

在執行任務前，先讓 Cursor 閱讀相關文檔，確保理解需求。

### 3. 小步提交

每個步驟完成後，確保應用可以編譯通過，再進行下一步。

### 4. 參考實際資料庫

執行任務前，可以參考 `docs/02_FIRESTORE_ANALYSIS.md` 了解實際資料庫結構。

---

## 🔍 相關文檔

- **`.cursorrules`** - 核心開發規範（AI 必須遵守）
- **`AGENTS.md`** - 完整開發指南
- **`docs/02_FIRESTORE_ANALYSIS.md`** - 實際資料庫分析報告
- **`docs/01_TASK_DB_REFACTOR.md`** - 資料庫重構任務詳情

---

## ⚠️ 重要提醒

1. **繁體中文**：所有代碼註解、變數命名、用戶介面文字都必須使用繁體中文
2. **不破壞現有功能**：修改代碼時，確保個人的健身紀錄功能不受影響
3. **型別安全**：所有 Firestore 操作必須透過 Model Class 進行
4. **小步提交**：每個任務完成後，確保 App 可以編譯通過

---

## 📞 遇到問題？

如果執行任務時遇到問題：

1. 檢查是否已完成前置任務
2. 確認是否已閱讀 `00_PROJECT_CONTEXT.md`
3. 參考 `AGENTS.md` 中的開發規範
4. 查看 `docs/02_FIRESTORE_ANALYSIS.md` 了解實際資料庫結構

---

**最後更新**：2025-12-22

