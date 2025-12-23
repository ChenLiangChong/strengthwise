# StrengthWise 文檔

> 專案完整文檔導航

**最後更新**：2024年12月23日

---

## 📖 核心文檔

### 1. [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)
**專案架構和技術棧總覽**

包含：
- 專案簡介和目標
- 技術架構（MVVM + Clean Architecture）
- 技術棧（Flutter、Firebase、GetIt）
- 專案結構說明
- 開發環境設置

**適合對象**：新加入的開發者、需要了解整體架構的人

---

### 2. [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)
**當前開發進度和計劃**

包含：
- 已完成功能清單
- 當前開發任務（統計系統、UI 美化）
- 下一步計劃（力量進步收藏功能）
- Bug 修復記錄

**適合對象**：需要了解專案進度、規劃開發任務的人

---

### 3. [DATABASE_DESIGN.md](DATABASE_DESIGN.md)
**Firestore 資料庫設計**

包含：
- 所有集合的結構說明
- 欄位定義和約定
- 5 層動作分類系統
- 查詢模式和索引策略

**適合對象**：需要操作資料庫、設計新功能的開發者

---

### 4. [STATISTICS_IMPLEMENTATION.md](STATISTICS_IMPLEMENTATION.md)
**統計功能實作指南**

包含：
- 基礎統計功能（頻率、趨勢、分布、PR）
- 專業統計功能（力量進步、肌群平衡、訓練日曆、完成率）
- 技術實作細節（~5,180 行代碼）
- UI 設計和圖表（fl_chart）

**適合對象**：實作或維護統計功能的開發者

---

### 5. [TODO_STRENGTH_PROGRESS_FAVORITES.md](TODO_STRENGTH_PROGRESS_FAVORITES.md)
**力量進步收藏功能設計**

包含：
- 功能需求和使用者故事
- UI 設計草圖（3 種情境）
- 技術實作方案
- 分階段實作步驟
- 數據儲存方案對比

**適合對象**：實作力量進步收藏功能的開發者

---

## 🚧 任務文檔

### [cursor_tasks/](cursor_tasks/)
**雙邊平台（教練-學員）功能開發任務**

⚠️ **狀態**：暫停開發（專注單機版功能）

包含：
- 資料庫重構計劃
- 關係管理設計
- 預約系統設計
- 教學功能設計

**適合對象**：未來開發雙邊平台功能時參考

---

## 🎯 快速導航

### 我想要...

**了解專案** → [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)

**開始開發** → [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) + [DATABASE_DESIGN.md](DATABASE_DESIGN.md)

**實作統計功能** → [STATISTICS_IMPLEMENTATION.md](STATISTICS_IMPLEMENTATION.md)

**實作收藏功能** → [TODO_STRENGTH_PROGRESS_FAVORITES.md](TODO_STRENGTH_PROGRESS_FAVORITES.md)

**修改資料庫** → [DATABASE_DESIGN.md](DATABASE_DESIGN.md)

**查看進度** → [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)

---

## 📂 文檔結構

```
docs/
├── README.md                              # 📖 本文檔（導航）
├── PROJECT_OVERVIEW.md                    # 🏗️ 專案架構總覽
├── DEVELOPMENT_STATUS.md                  # 📊 開發狀態和進度
├── DATABASE_DESIGN.md                     # 🗄️ 資料庫設計
├── STATISTICS_IMPLEMENTATION.md           # 📈 統計功能實作
├── TODO_STRENGTH_PROGRESS_FAVORITES.md    # 📝 待辦：收藏功能
└── cursor_tasks/                          # 🚧 雙邊平台任務（暫停）
    ├── 00_PROJECT_CONTEXT.md
    ├── 01_TASK_DB_REFACTOR.md
    ├── 02_TASK_RELATIONSHIPS.md
    ├── 03_TASK_BOOKING.md
    ├── 04_TASK_TEACHING.md
    └── README.md
```

---

## 📌 文檔維護規範

### 更新頻率
- `DEVELOPMENT_STATUS.md`：每完成一個功能後更新
- `DATABASE_DESIGN.md`：資料庫結構變更後立即更新
- `PROJECT_OVERVIEW.md`：架構重大變更時更新
- `TODO_*.md`：功能完成後刪除或歸檔
- 其他文檔：按需更新

### 文檔格式
- 使用 Markdown 格式
- 使用繁體中文
- 包含目錄（對於長文檔）
- 使用清晰的標題層級
- 包含程式碼範例（如適用）

### 清理原則
- 定期刪除重複文檔
- 整合相似內容
- 只保留核心文檔（見上方結構）
- 臨時文檔完成後立即刪除

---

## 🔗 外部資源

### 開發相關
- [Flutter 官方文檔](https://flutter.dev/docs)
- [Firebase 官方文檔](https://firebase.google.com/docs)
- [Provider 套件](https://pub.dev/packages/provider)
- [GetIt 套件](https://pub.dev/packages/get_it)

### UI/圖表相關
- [fl_chart 文檔](https://pub.dev/packages/fl_chart)
- [Material Design](https://material.io/design)

---

## 🎉 最近更新（2024-12-23）

### ✅ 文檔整合完成
- 刪除重複的統計系統總結文檔（3 個）
- 刪除基礎設置文檔（3 個）
- 簡化文檔結構，只保留 7 個核心文檔
- 所有詳細資訊都在核心文檔中可查

### ✅ 專業級統計系統
- **階段 1**：動作分類系統升級（794 個動作）
- **階段 2**：專業統計功能（~5,180 行代碼）
- **階段 3**：UI 美化（趨勢圖、力量進步、個人記錄）
- **階段 4**：測試數據生成（6 次訓練記錄）

### ⏳ 下一步
- 實作力量進步收藏功能
- 詳見 `TODO_STRENGTH_PROGRESS_FAVORITES.md`

---

**開始開發前，建議先閱讀 `PROJECT_OVERVIEW.md` 和 `DEVELOPMENT_STATUS.md`！**
