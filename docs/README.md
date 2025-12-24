# StrengthWise 文檔

> 專案完整文檔導航

**最後更新**：2024年12月25日

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
**當前開發進度和已知問題**

包含：
- 已完成功能清單（階段 1-10）
- 已知 UI/UX 問題和待優化項目
- 下一步計劃
- 開發歷史和里程碑

**適合對象**：需要了解專案進度、規劃開發任務的人

---

### 3. [DATABASE_DESIGN.md](DATABASE_DESIGN.md)
**Firestore 資料庫設計**

包含：
- 所有集合的結構說明
- 欄位定義和約定
- 5 層動作分類系統（794 個動作）
- 查詢模式和索引策略

**適合對象**：需要操作資料庫、設計新功能的開發者

---

### 4. [UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md) ⭐ 新增
**UI/UX 設計規範**

包含：
- Kinetic 設計系統（字體、間距、圖標）
- 語意化色彩系統（深色/淺色模式）
- 核心視圖重塑方案（Dashboard、Logger、Library、Settings）
- 技術實作指南（ThemeData、狀態管理）
- 互動設計與微動畫（Haptics、Transitions）
- 無障礙設計（對比度、動態字級）
- 執行路徑圖（4 週計劃）
- **附錄 A**：HTML 原型到 Flutter 實作指南（完整的 Widget 範例）

**相關文件**：[ui_prototype.html](ui_prototype.html) - 互動式 UI 原型

**適合對象**：實作 UI/UX 改版、建立設計系統的開發者

---

### 5. [STATISTICS_IMPLEMENTATION.md](STATISTICS_IMPLEMENTATION.md)
**統計功能實作指南**

包含：
- 基礎統計功能（頻率、趨勢、分布、PR）
- 專業統計功能（力量進步、肌群平衡、訓練日曆、完成率）
- 技術實作細節（~5,180 行代碼）
- UI 設計和圖表（fl_chart）

**適合對象**：實作或維護統計功能的開發者

---

## 🛠️ 操作指南

### 6. [BUILD_RELEASE.md](BUILD_RELEASE.md)
**Release APK 構建和安裝指南**

包含：
- 快速構建流程
- APK 位置和安裝方法
- 簽名 APK 配置
- 構建選項說明
- 常見問題排除

**適合對象**：需要構建和發布應用的開發者

---

### 7. [GOOGLE_SIGNIN_COMPLETE_SETUP.md](GOOGLE_SIGNIN_COMPLETE_SETUP.md)
**Google Sign-In 完整配置指南**

包含：
- 獲取 SHA-1 指紋步驟
- Firebase Console 配置
- google-services.json 更新
- 故障排除和檢查清單

**適合對象**：配置 Google 登入功能的開發者

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

**設計 UI/UX** → [UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md) ⭐ 新增

**實作統計功能** → [STATISTICS_IMPLEMENTATION.md](STATISTICS_IMPLEMENTATION.md)

**構建 APK** → [BUILD_RELEASE.md](BUILD_RELEASE.md)

**配置 Google 登入** → [GOOGLE_SIGNIN_COMPLETE_SETUP.md](GOOGLE_SIGNIN_COMPLETE_SETUP.md)

**修改資料庫** → [DATABASE_DESIGN.md](DATABASE_DESIGN.md)

**查看進度和問題** → [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)

---

## 📂 文檔結構

```
docs/
├── README.md                              # 📖 本文檔（導航）
│
├── 核心文檔/
│   ├── PROJECT_OVERVIEW.md                # 🏗️ 專案架構總覽
│   ├── DEVELOPMENT_STATUS.md              # 📊 開發狀態和已知問題
│   ├── DATABASE_DESIGN.md                 # 🗄️ 資料庫設計
│   ├── UI_UX_GUIDELINES.md                # 🎨 UI/UX 設計規範（⭐ 新增）
│   └── STATISTICS_IMPLEMENTATION.md       # 📈 統計功能實作
│
├── 操作指南/
│   ├── BUILD_RELEASE.md                   # 📦 Release APK 構建指南
│   └── GOOGLE_SIGNIN_COMPLETE_SETUP.md    # 🔐 Google Sign-In 配置
│
└── 任務文檔/
    └── cursor_tasks/                      # 🚧 雙邊平台任務（暫停）
        ├── README.md
        ├── 00_PROJECT_CONTEXT.md
        ├── 01_TASK_DB_REFACTOR.md
        ├── 02_TASK_RELATIONSHIPS.md
        ├── 03_TASK_BOOKING.md
        └── 04_TASK_TEACHING.md
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

## 🎉 最近更新（2024-12-25）

### ⭐ UI/UX 設計規範發布（2024-12-25）
- **新增文檔**：創建完整的 UI/UX 設計規範（UI_UX_GUIDELINES.md）
- **設計系統**：定義 Kinetic 設計系統（字體、間距、圖標）
- **雙模主題**：深色/淺色模式配色方案（Titanium Blue）
- **技術實作**：ThemeData 架構、狀態管理、響應式佈局
- **執行路徑**：4 週實施計劃，從基礎建設到細節打磨

### ✅ Google 登入 & 新用戶默認模板（2024-12-24 深夜）
- **Google 登入修復**：修復類型轉換錯誤，在真實設備測試成功
- **新用戶默認模板**：自動創建 5 天專業訓練模板（胸背腿肩手）
- **Release APK 構建**：創建穩定版（55.8 MB），安裝到真實設備測試
- **文檔完善**：新增 BUILD_RELEASE.md 和 GOOGLE_SIGNIN_COMPLETE_SETUP.md

### ✅ 訓練模板系統完善（2024-12-24 晚上）
- **模板編輯器簡化**：移除複雜功能，保留核心設定
- **緩存刷新機制**：解決編輯後列表不更新的問題
- **訓練頁面功能**：添加編輯選項、修正導航按鈕

### ✅ 時間權限控制（2024-12-24 晚上）
- **過去的訓練**：只能查看，不能編輯/刪除
- **未來的訓練**：可以編輯，不能勾選完成
- **今天的訓練**：完整權限

### 🐛 已知問題（2024-12-25）
詳見 [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) 的「已知問題和待優化項目」章節：
- FloatingActionButton 擋住內容（P0）
- 手機返回鍵導航問題（P0）
- 通知欄位置問題（P0）
- 力量進步頁面優化（P1）
- 自訂動作錯誤處理（P1）

---

**開始開發前，建議先閱讀 `PROJECT_OVERVIEW.md` 和 `DEVELOPMENT_STATUS.md`！**
